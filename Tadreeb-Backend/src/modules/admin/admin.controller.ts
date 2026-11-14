import { Request, Response } from "express";
import User, { UserRole, UserStatus } from "../users/user.model";
import Institute, { InstituteStatus } from "../institutes/models/institute.model";
import Course from "../courses/models/course.model";
import { CourseStatus } from "../courses/types/course.types";
import Reservation from "../reservations/models/reservation.model";
import { ReservationStatus, PaymentStatus } from "../reservations/types/reservation.types";
import { z } from "zod";
import instituteService from "../institutes/services/institute.service";
import instituteLogoService from "./institute-logo.service";

const createInstituteWithOwnerSchema = z.object({
  institute: z.object({
    name: z.string().trim().min(2),
    phone: z.string().trim().min(1),
    address: z.string().trim().min(1),
    description: z.string().trim().optional(),
    email: z.string().trim().email().optional(),
  }),
  owner: z.object({
    name: z.string().trim().min(2),
    email: z.string().trim().email(),
    phone: z.string().trim().optional(),
    password: z.string().min(8),
  }),
});

class AdminController {
  async createInstituteWithLogo(req: Request, res: Response): Promise<void> {
    if (!req.file) {
      res.status(400).json({
        success: false,
        message: "Institute logo image is required",
      });
      return;
    }

    let uploadedLogo: { url: string; publicId: string } | undefined;

    try {
      const input = createInstituteWithOwnerSchema.safeParse({
        institute: this.parseJsonField(req.body.institute),
        owner: this.parseJsonField(req.body.owner),
      });

      if (!input.success) {
        res.status(400).json({
          success: false,
          message: "Invalid institute or owner data",
        });
        return;
      }

      uploadedLogo = await instituteLogoService.upload(req.file.buffer);
      const result = await instituteService.createInstituteWithOwner({
        institute: {
          ...input.data.institute,
          logo: uploadedLogo.url,
        },
        owner: input.data.owner,
      });

      res.status(201).json({
        success: true,
        message: "Institute and owner created successfully",
        data: { institute: result.institute },
      });
    } catch (error) {
      if (uploadedLogo) {
        try {
          await instituteLogoService.delete(uploadedLogo.publicId);
        } catch (cleanupError) {
          console.error(
            "Failed to clean up uploaded institute logo:",
            cleanupError,
          );
        }
      }

      const duplicateOwnerEmail =
        error instanceof Error &&
        error.message === "Owner email is already registered";
      res.status(duplicateOwnerEmail ? 409 : 400).json({
        success: false,
        message: duplicateOwnerEmail
          ? error.message
          : "Institute creation failed",
      });
    }
  }

  async getUsers(req: Request, res: Response): Promise<void> {
    const page = this.readPositiveInteger(req.query.page, 1);
    const requestedLimit = this.readPositiveInteger(req.query.limit, 20);

    if (page === null || requestedLimit === null) {
      res.status(400).json({
        success: false,
        message: "Invalid user list query",
      });
      return;
    }

    const limit = Math.min(requestedLimit, 50);
    const filter = {
      role: { $in: [UserRole.STUDENT, UserRole.INSTITUTE_OWNER] },
    };

    try {
      const [users, total] = await Promise.all([
        User.find(filter)
          .select("name email role status createdAt")
          .sort({ createdAt: -1 })
          .skip((page - 1) * limit)
          .limit(limit)
          .lean(),
        User.countDocuments(filter),
      ]);

      res.status(200).json({
        success: true,
        data: {
          users: users.map((user) => ({
            id: user._id.toString(),
            name: user.name,
            email: user.email,
            role: user.role,
            status: user.status,
            createdAt: user.createdAt,
          })),
          pagination: {
            total,
            page,
            limit,
            totalPages: Math.ceil(total / limit),
          },
        },
      });
    } catch (error) {
      console.error("Admin user list error:", error);
      res.status(500).json({
        success: false,
        message: "حدث خطأ أثناء جلب قائمة المستخدمين",
      });
    }
  }

  async suspendUser(req: Request, res: Response): Promise<void> {
    const userId = req.params.userId;
    if (typeof userId !== "string" || !/^[a-f\d]{24}$/i.test(userId)) {
      res.status(400).json({
        success: false,
        message: "Invalid user ID",
      });
      return;
    }

    const allowedRoles = [UserRole.STUDENT, UserRole.INSTITUTE_OWNER];
    try {
      const user = await User.findOneAndUpdate(
        {
          _id: userId,
          role: { $in: allowedRoles },
          status: { $in: [UserStatus.ACTIVE, UserStatus.PENDING] },
        },
        { $set: { status: UserStatus.SUSPENDED } },
        { new: true, runValidators: true },
      ).select("_id status");

      if (user) {
        res.status(200).json({
          success: true,
          data: {
            user: {
              id: user._id.toString(),
              status: user.status,
            },
          },
        });
        return;
      }

      const existingUser = await User.findOne({
        _id: userId,
        role: { $in: allowedRoles },
      }).select("_id status");

      if (!existingUser) {
        res.status(404).json({
          success: false,
          message: "User not found",
        });
        return;
      }

      if (existingUser.status === UserStatus.SUSPENDED) {
        res.status(200).json({
          success: true,
          data: {
            user: {
              id: existingUser._id.toString(),
              status: existingUser.status,
            },
          },
        });
        return;
      }

      res.status(409).json({
        success: false,
        message: "User cannot be suspended in the current status",
      });
    } catch (error) {
      console.error("Admin suspend user error:", error);
      res.status(500).json({
        success: false,
        message: "حدث خطأ أثناء إيقاف حساب المستخدم",
      });
    }
  }

  // عرض قائمة آمنة للمعاهد دون بيانات الاتصال أو بيانات المالك.
  async getInstitutes(req: Request, res: Response): Promise<void> {
    const page = this.readPositiveInteger(req.query.page, 1);
    const requestedLimit = this.readPositiveInteger(req.query.limit, 20);
    const rawStatus = req.query.status;
    const status =
      typeof rawStatus === "string"
        ? Object.values(InstituteStatus).find((value) => value === rawStatus)
        : undefined;

    if (
      page === null ||
      requestedLimit === null ||
      (rawStatus !== undefined && status === undefined)
    ) {
      res.status(400).json({
        success: false,
        message: "Invalid institute list query",
      });
      return;
    }

    const limit = Math.min(requestedLimit, 50);
    const filter = status ? { status } : {};

    try {
      const [institutes, total] = await Promise.all([
        Institute.find(filter)
          .select("-_id name status createdAt")
          .sort({ createdAt: -1 })
          .skip((page - 1) * limit)
          .limit(limit)
          .lean(),
        Institute.countDocuments(filter),
      ]);

      res.status(200).json({
        success: true,
        data: {
          institutes,
          pagination: {
            total,
            page,
            limit,
            totalPages: Math.ceil(total / limit),
          },
        },
      });
    } catch (error) {
      console.error("Admin institute list error:", error);
      res.status(500).json({
        success: false,
        message: "حدث خطأ أثناء جلب قائمة المعاهد",
      });
    }
  }

  // جلب إحصائيات المنصة الشاملة.
  async getStats(_req: Request, res: Response): Promise<void> {
    try {
      // إحصائيات المستخدمين
      const [
        totalUsers,
        totalStudents,
        totalInstituteOwners,
        activeUsers,
      ] = await Promise.all([
        User.countDocuments(),
        User.countDocuments({ role: UserRole.STUDENT }),
        User.countDocuments({ role: UserRole.INSTITUTE_OWNER }),
        User.countDocuments({ status: UserStatus.ACTIVE }),
      ]);

      // إحصائيات المعاهد
      const [
        totalInstitutes,
        activeInstitutes,
        pendingInstitutes,
        suspendedInstitutes,
      ] = await Promise.all([
        Institute.countDocuments(),
        Institute.countDocuments({ status: InstituteStatus.ACTIVE }),
        Institute.countDocuments({ status: InstituteStatus.PENDING }),
        Institute.countDocuments({ status: InstituteStatus.SUSPENDED }),
      ]);

      // إحصائيات الدورات
      const [totalCourses, publishedCourses] = await Promise.all([
        Course.countDocuments(),
        Course.countDocuments({ status: CourseStatus.PUBLISHED }),
      ]);

      // إحصائيات الحجوزات
      const [
        totalReservations,
        confirmedReservations,
        pendingPaymentReservations,
        paymentSubmittedReservations,
        rejectedReservations,
        cancelledReservations,
        expiredReservations,
      ] = await Promise.all([
        Reservation.countDocuments(),
        Reservation.countDocuments({ status: ReservationStatus.CONFIRMED }),
        Reservation.countDocuments({ status: ReservationStatus.PENDING_PAYMENT }),
        Reservation.countDocuments({ status: ReservationStatus.PAYMENT_SUBMITTED }),
        Reservation.countDocuments({ status: ReservationStatus.REJECTED }),
        Reservation.countDocuments({ status: ReservationStatus.CANCELLED }),
        Reservation.countDocuments({ status: ReservationStatus.EXPIRED }),
      ]);

      // الإيرادات الإجمالية (الحجوزات المؤكدة فقط)
      const revenueAgg = await Reservation.aggregate([
        { $match: { status: ReservationStatus.CONFIRMED } },
        { $group: { _id: null, total: { $sum: "$amountPaid" } } },
      ]);
      const totalRevenue: number = revenueAgg[0]?.total ?? 0;

      // إيرادات آخر 6 أشهر (شهريًا)
      const sixMonthsAgo = new Date();
      sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 5);
      sixMonthsAgo.setDate(1);
      sixMonthsAgo.setHours(0, 0, 0, 0);

      const monthlyRevenue = await Reservation.aggregate([
        {
          $match: {
            status: ReservationStatus.CONFIRMED,
            createdAt: { $gte: sixMonthsAgo },
          },
        },
        {
          $group: {
            _id: {
              year: { $year: "$createdAt" },
              month: { $month: "$createdAt" },
            },
            revenue: { $sum: "$amountPaid" },
            count: { $sum: 1 },
          },
        },
        { $sort: { "_id.year": 1, "_id.month": 1 } },
      ]);

      // تسجيلات آخر 30 يومًا
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const [newUsersLast30, newReservationsLast30] = await Promise.all([
        User.countDocuments({ createdAt: { $gte: thirtyDaysAgo } }),
        Reservation.countDocuments({ createdAt: { $gte: thirtyDaysAgo } }),
      ]);

      res.status(200).json({
        success: true,
        data: {
          users: {
            total: totalUsers,
            students: totalStudents,
            instituteOwners: totalInstituteOwners,
            active: activeUsers,
            newLast30Days: newUsersLast30,
          },
          institutes: {
            total: totalInstitutes,
            active: activeInstitutes,
            pending: pendingInstitutes,
            suspended: suspendedInstitutes,
          },
          courses: {
            total: totalCourses,
            published: publishedCourses,
          },
          reservations: {
            total: totalReservations,
            confirmed: confirmedReservations,
            pendingPayment: pendingPaymentReservations,
            paymentSubmitted: paymentSubmittedReservations,
            rejected: rejectedReservations,
            cancelled: cancelledReservations,
            expired: expiredReservations,
            newLast30Days: newReservationsLast30,
          },
          revenue: {
            total: totalRevenue,
            monthly: monthlyRevenue,
          },
        },
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: "حدث خطأ أثناء جلب إحصائيات المنصة",
      });
    }
  }

  private readPositiveInteger(value: unknown, fallback: number): number | null {
    if (value === undefined) return fallback;
    if (typeof value !== "string" || !/^\d+$/.test(value)) return null;

    const parsed = Number(value);
    return Number.isSafeInteger(parsed) && parsed > 0 ? parsed : null;
  }

  private parseJsonField(value: unknown): unknown {
    if (typeof value !== "string") {
      throw new Error("Invalid multipart institute data");
    }
    return JSON.parse(value);
  }
}

export default new AdminController();

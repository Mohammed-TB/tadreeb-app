import Course from "../../courses/models/course.model";
import { CourseStatus } from "../../courses/types/course.types";
import Reservation from "../../reservations/models/reservation.model";
import { ReservationStatus } from "../../reservations/types/reservation.types";
import Institute from "../models/institute.model";
import User, { UserRole, UserStatus } from "../../users/user.model";

interface StatusCount {
  _id: ReservationStatus;
  count: number;
}

interface MonthlyRevenue {
  _id: {
    year: number;
    month: number;
  };
  revenue: number;
}

interface CourseOccupancy {
  id: string;
  title: string;
  capacity: number;
  occupied: number;
}

interface RecentReservation {
  id: string;
  studentName: string;
  courseTitle: string;
  status: ReservationStatus;
  createdAt: Date;
}

class InstituteDashboardService {
  async getDashboard(ownerId: string) {
    const owner = await User.findById(ownerId).select(
      "role status instituteId",
    );
    if (
      !owner ||
      owner.role !== UserRole.INSTITUTE_OWNER ||
      owner.status !== UserStatus.ACTIVE ||
      !owner.instituteId
    ) {
      throw new Error("Institute owner not found");
    }

    const instituteId = owner.instituteId;
    const institute = await Institute.findOne({
      _id: instituteId,
      ownerId: owner._id,
    })
      .select("name")
      .lean();
    if (!institute) {
      throw new Error("Institute not found");
    }

    const now = new Date();
    const monthStart = new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1),
    );
    const firstRevenueMonth = new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 5, 1),
    );
    const sevenDaysFromNow = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);
    const reservationFilter = { instituteId };

    const [
      totalCourses,
      publishedCourses,
      allReservationStatuses,
      monthlyReservationStatuses,
      totalRevenueRows,
      monthlyRevenueRows,
      courseOccupancy,
      recentReservations,
      upcomingCourses,
      fullCourses,
    ] = await Promise.all([
      Course.countDocuments({ instituteId }),
      Course.countDocuments({
        instituteId,
        status: CourseStatus.PUBLISHED,
      }),
      Reservation.aggregate<StatusCount>([
        { $match: reservationFilter },
        { $group: { _id: "$status", count: { $sum: 1 } } },
      ]),
      Reservation.aggregate<StatusCount>([
        {
          $match: {
            ...reservationFilter,
            createdAt: { $gte: monthStart },
          },
        },
        { $group: { _id: "$status", count: { $sum: 1 } } },
      ]),
      Reservation.aggregate<{ total: number }>([
        {
          $match: {
            ...reservationFilter,
            status: ReservationStatus.CONFIRMED,
          },
        },
        { $group: { _id: null, total: { $sum: "$amountPaid" } } },
      ]),
      Reservation.aggregate<MonthlyRevenue>([
        {
          $match: {
            ...reservationFilter,
            status: ReservationStatus.CONFIRMED,
            createdAt: { $gte: firstRevenueMonth },
          },
        },
        {
          $group: {
            _id: {
              year: { $year: "$createdAt" },
              month: { $month: "$createdAt" },
            },
            revenue: { $sum: "$amountPaid" },
          },
        },
        { $sort: { "_id.year": 1, "_id.month": 1 } },
      ]),
      Course.aggregate<CourseOccupancy>([
        {
          $match: {
            instituteId,
            status: CourseStatus.PUBLISHED,
          },
        },
        {
          $addFields: {
            occupied: {
              $add: [
                { $ifNull: ["$enrolledCount", 0] },
                { $ifNull: ["$reservedCount", 0] },
              ],
            },
          },
        },
        { $sort: { occupied: -1, createdAt: -1 } },
        { $limit: 3 },
        {
          $project: {
            _id: 0,
            id: { $toString: "$_id" },
            title: 1,
            capacity: 1,
            occupied: 1,
          },
        },
      ]),
      Reservation.aggregate<RecentReservation>([
        { $match: reservationFilter },
        { $sort: { createdAt: -1 } },
        { $limit: 5 },
        {
          $lookup: {
            from: Course.collection.name,
            localField: "courseId",
            foreignField: "_id",
            as: "course",
          },
        },
        {
          $unwind: {
            path: "$course",
            preserveNullAndEmptyArrays: true,
          },
        },
        {
          $project: {
            _id: 0,
            id: { $toString: "$_id" },
            studentName: 1,
            courseTitle: { $ifNull: ["$course.title", ""] },
            status: 1,
            createdAt: 1,
          },
        },
      ]),
      Course.countDocuments({
        instituteId,
        status: CourseStatus.PUBLISHED,
        startDate: { $gte: now, $lte: sevenDaysFromNow },
      }),
      Course.countDocuments({
        instituteId,
        status: CourseStatus.PUBLISHED,
        $expr: {
          $gte: [
            {
              $add: [
                { $ifNull: ["$enrolledCount", 0] },
                { $ifNull: ["$reservedCount", 0] },
              ],
            },
            "$capacity",
          ],
        },
      }),
    ]);

    const countForStatus = (
      rows: StatusCount[],
      status: ReservationStatus,
    ) => rows.find((row) => row._id === status)?.count ?? 0;
    const revenueByMonth = new Map(
      monthlyRevenueRows.map((row) => [
        `${row._id.year}-${row._id.month}`,
        row.revenue,
      ]),
    );
    const monthlyRevenue = Array.from({ length: 6 }, (_, index) => {
      const date = new Date(
        Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 5 + index, 1),
      );
      const year = date.getUTCFullYear();
      const month = date.getUTCMonth() + 1;
      return {
        year,
        month,
        revenue: revenueByMonth.get(`${year}-${month}`) ?? 0,
      };
    });

    const totalReservations = allReservationStatuses.reduce(
      (total, row) => total + row.count,
      0,
    );
    const reservationsThisMonth = monthlyReservationStatuses.reduce(
      (total, row) => total + row.count,
      0,
    );

    return {
      institute: { name: institute.name },
      summary: {
        courses: {
          total: totalCourses,
          published: publishedCourses,
        },
        reservations: {
          total: totalReservations,
          thisMonth: reservationsThisMonth,
          confirmedThisMonth: countForStatus(
            monthlyReservationStatuses,
            ReservationStatus.CONFIRMED,
          ),
          pendingPaymentThisMonth: countForStatus(
            monthlyReservationStatuses,
            ReservationStatus.PENDING_PAYMENT,
          ),
          paymentSubmittedThisMonth: countForStatus(
            monthlyReservationStatuses,
            ReservationStatus.PAYMENT_SUBMITTED,
          ),
          rejectedThisMonth: countForStatus(
            monthlyReservationStatuses,
            ReservationStatus.REJECTED,
          ),
          expiredThisMonth: countForStatus(
            monthlyReservationStatuses,
            ReservationStatus.EXPIRED,
          ),
          cancelledThisMonth: countForStatus(
            monthlyReservationStatuses,
            ReservationStatus.CANCELLED,
          ),
          receiptsToReview: countForStatus(
            allReservationStatuses,
            ReservationStatus.PAYMENT_SUBMITTED,
          ),
        },
        revenue: {
          total: totalRevenueRows[0]?.total ?? 0,
          monthly: monthlyRevenue,
        },
      },
      courseOccupancy,
      recentReservations,
      alerts: {
        coursesStartingSoon: upcomingCourses,
        fullCourses,
      },
    };
  }
}

export default new InstituteDashboardService();

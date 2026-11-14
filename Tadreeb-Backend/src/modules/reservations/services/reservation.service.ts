import mongoose from "mongoose";

import Course from "../../courses/models/course.model";
import Institute, {
  InstituteStatus,
} from "../../institutes/models/institute.model";
import User, { UserRole, UserStatus } from "../../users/user.model";

import Reservation from "../models/reservation.model";
import receiptUploadService from "./receipt-upload.service";

import {
  BookingType,
  PaymentOption,
  PaymentStatus,
  ReservationStatus,
  AttendanceStatus,
} from "../types/reservation.types";

class ReservationService {
  // تحديد المبلغ المطلوب حسب طريقة الدفع.
  private getAmountToPay(
    paymentOption: PaymentOption,
    price: number,
    depositAmount: number,
  ): number {
    return paymentOption === PaymentOption.DEPOSIT ? depositAmount : price;
  }

  // حجز مقعد مؤقت مع منع تجاوز سعة الدورة.
  private async reserveSeat(
    courseId: mongoose.Types.ObjectId,
    session: mongoose.ClientSession,
  ): Promise<any> {
    const course: any = await Course.findOneAndUpdate(
      {
        _id: courseId,
        status: "published",
        startDate: { $gt: new Date() },
        endDate: { $gte: new Date() },
        $expr: {
          $lt: [
            {
              $add: [
                { $ifNull: ["$enrolledCount", 0] },
                { $ifNull: ["$reservedCount", 0] },
              ],
            },
            "$capacity",
          ],
        },
      } as any,
      { $inc: { reservedCount: 1 } },
      { new: true, session },
    );

    if (!course) {
      throw new Error("Course is unavailable or full");
    }

    return course;
  }

  // =====================================================
  // 1. التسجيل الإلكتروني بواسطة الطالب.
  // =====================================================
  async createOnlineReservation(
    studentId: string,
    courseId: string,
    studentName: string,
    studentPhone: string,
    paymentOption: PaymentOption,
  ) {
    if (!mongoose.Types.ObjectId.isValid(courseId)) {
      throw new Error("Invalid course ID");
    }

    if (!Object.values(PaymentOption).includes(paymentOption)) {
      throw new Error("Invalid payment option");
    }

    if (!studentName.trim() || !studentPhone.trim()) {
      throw new Error("Student name and phone are required");
    }

    const session = await mongoose.startSession();

    try {
      let result: any;

      await session.withTransaction(async () => {
        const student = await User.findById(studentId).session(session);

        if (
          !student ||
          student.role !== UserRole.STUDENT ||
          student.status !== UserStatus.ACTIVE
        ) {
          throw new Error("Active student account required");
        }

        // التحقق من وجود مقعد وحجزه مؤقتًا.
        const course: any = await this.reserveSeat(
          new mongoose.Types.ObjectId(courseId),
          session,
        );

        const institute = await Institute.findOne({
          _id: course.instituteId,
          status: InstituteStatus.ACTIVE,
        }).session(session);

        if (!institute) {
          throw new Error("Institute is not active");
        }

        // منع تكرار الحجز النشط للطالب في الدورة نفسها.
        const existing = await Reservation.findOne({
          studentId: student._id,
          courseId: course._id,
          status: {
            $in: [
              ReservationStatus.PENDING_PAYMENT,
              ReservationStatus.PAYMENT_SUBMITTED,
              ReservationStatus.CONFIRMED,
            ],
          },
        }).session(session);

        if (existing) {
          throw new Error("You already have a reservation for this course");
        }

        const amountToPay = this.getAmountToPay(
          paymentOption,
          course.price,
          course.depositAmount,
        );

        if (amountToPay <= 0) {
          throw new Error("Invalid payment amount");
        }

        // مدة الحجز المؤقت: 24 ساعة.
        const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

        const [reservation] = await Reservation.create(
          [
            {
              courseId: course._id,
              instituteId: course.instituteId,
              studentId: student._id,
              studentName: studentName.trim(),
              studentPhone: studentPhone.trim(),
              bookingType: BookingType.ONLINE,
              createdBy: student._id,
              paymentOption,
              totalAmount: course.price,
              amountToPay,
              amountPaid: 0,
              paymentStatus: PaymentStatus.UNPAID,
              status: ReservationStatus.PENDING_PAYMENT,
              expiresAt,
              attendanceStatus: AttendanceStatus.NOT_MARKED,
            },
          ],
          { session },
        );

        result = reservation;
      });

      return result;
    } finally {
      await session.endSession();
    }
  }

  // =====================================================
  // 2. التسجيل الحضوري بواسطة صاحب المعهد.
  // =====================================================
  async createInPersonReservation(
    ownerId: string,
    input: {
      courseId: string;
      studentName: string;
      studentPhone: string;
      paymentOption: PaymentOption;
      amountPaid: number;
    },
  ) {
    if (!mongoose.Types.ObjectId.isValid(input.courseId)) {
      throw new Error("Invalid course ID");
    }

    if (!input.studentName?.trim() || !input.studentPhone?.trim()) {
      throw new Error("Student name and phone are required");
    }

    if (!Object.values(PaymentOption).includes(input.paymentOption)) {
      throw new Error("Invalid payment option");
    }

    if (!Number.isFinite(input.amountPaid) || input.amountPaid < 0) {
      throw new Error("Invalid paid amount");
    }

    const session = await mongoose.startSession();

    try {
      let result: any;

      await session.withTransaction(async () => {
        const owner = await User.findById(ownerId).session(session);

        if (
          !owner ||
          owner.role !== UserRole.INSTITUTE_OWNER ||
          owner.status !== UserStatus.ACTIVE ||
          !owner.instituteId
        ) {
          throw new Error("Active institute owner required");
        }

        const institute = await Institute.findOne({
          _id: owner.instituteId,
          ownerId: owner._id,
          status: InstituteStatus.ACTIVE,
        }).session(session);

        if (!institute) {
          throw new Error("Active institute not found");
        }

        // التأكد أن الدورة تابعة للمعهد الحالي.
        const course: any = await Course.findOne({
          _id: input.courseId,
          instituteId: owner.instituteId,
          status: "published",
          startDate: { $gt: new Date() },
          endDate: { $gte: new Date() },
        } as any).session(session);

        if (!course) {
          throw new Error("Course not found or unavailable");
        }

        if (input.amountPaid > course.price) {
          throw new Error("Paid amount cannot exceed course price");
        }

        // تأكيد المقعد مباشرة للتسجيل الحضوري.
        const updatedCourse: any = await Course.findOneAndUpdate(
          {
            _id: course._id,
            instituteId: owner.instituteId,
            status: "published",
            $expr: {
              $lt: [
                {
                  $add: [
                    { $ifNull: ["$enrolledCount", 0] },
                    { $ifNull: ["$reservedCount", 0] },
                  ],
                },
                "$capacity",
              ],
            },
          } as any,
          { $inc: { enrolledCount: 1 } },
          { new: true, session },
        );

        if (!updatedCourse) {
          throw new Error("No available seats");
        }

        const amountToPay = this.getAmountToPay(
          input.paymentOption,
          course.price,
          course.depositAmount,
        );

        const paymentStatus =
          input.amountPaid >= course.price
            ? PaymentStatus.PAID
            : input.amountPaid > 0
              ? PaymentStatus.PARTIAL
              : PaymentStatus.UNPAID;

        // إنشاء تسجيل حضوري مؤكد دون الحاجة لحساب طالب.
        const [reservation] = await Reservation.create(
          [
            {
              courseId: course._id,
              instituteId: owner.instituteId,
              studentName: input.studentName.trim(),
              studentPhone: input.studentPhone.trim(),
              bookingType: BookingType.IN_PERSON,
              createdBy: owner._id,
              paymentOption: input.paymentOption,
              totalAmount: course.price,
              amountToPay,
              amountPaid: input.amountPaid,
              paymentStatus,
              status: ReservationStatus.CONFIRMED,
              attendanceStatus: AttendanceStatus.NOT_MARKED,
            },
          ],
          { session },
        );

        result = reservation;
      });

      return result;
    } finally {
      await session.endSession();
    }
  }

  // =====================================================
  // 3. الموافقة على سند التحويل بواسطة صاحب المعهد.
  // =====================================================
  async approveReservation(ownerId: string, reservationId: string) {
    if (!mongoose.Types.ObjectId.isValid(reservationId)) {
      throw new Error("Invalid reservation ID");
    }

    const session = await mongoose.startSession();

    try {
      let result: any;

      await session.withTransaction(async () => {
        const owner = await User.findById(ownerId).session(session);

        if (
          !owner ||
          owner.role !== UserRole.INSTITUTE_OWNER ||
          owner.status !== UserStatus.ACTIVE ||
          !owner.instituteId
        ) {
          throw new Error("Active institute owner required");
        }

        // لا يمكن اعتماد حجز تابع لمعهد آخر.
        const reservation = await Reservation.findOne({
          _id: reservationId,
          instituteId: owner.instituteId,
          bookingType: BookingType.ONLINE,
          status: ReservationStatus.PAYMENT_SUBMITTED,
        }).session(session);

        if (!reservation) {
          throw new Error("Submitted reservation not found");
        }

        // تحويل المقعد من محجوز مؤقتًا إلى مقعد مؤكد.
        const course: any = await Course.findOneAndUpdate(
          {
            _id: reservation.courseId,
            instituteId: owner.instituteId,
            reservedCount: { $gte: 1 },
          } as any,
          {
            $inc: {
              reservedCount: -1,
              enrolledCount: 1,
            },
          },
          { new: true, session },
        );

        if (!course) {
          throw new Error("Could not confirm reserved course seat");
        }

        // اعتماد المبلغ الموجود في السند.
        reservation.amountPaid = reservation.amountToPay;

        reservation.paymentStatus =
          reservation.amountPaid >= reservation.totalAmount
            ? PaymentStatus.PAID
            : PaymentStatus.PARTIAL;

        reservation.status = ReservationStatus.CONFIRMED;

        reservation.rejectionReason = undefined;
        reservation.receiptResubmissionDeadline = undefined;

        await reservation.save({ session });

        result = reservation;
      });

      return result;
    } finally {
      await session.endSession();
    }
  }

  // =====================================================
  // 4. رفض سند التحويل وتحديد مهلة إعادة الرفع.
  // =====================================================
  async rejectReservation(
    ownerId: string,
    reservationId: string,
    reason: string,
  ) {
    if (!mongoose.Types.ObjectId.isValid(reservationId)) {
      throw new Error("Invalid reservation ID");
    }

    if (!reason?.trim()) {
      throw new Error("Rejection reason is required");
    }

    const session = await mongoose.startSession();

    try {
      let result: any;

      await session.withTransaction(async () => {
        const owner = await User.findById(ownerId).session(session);

        if (
          !owner ||
          owner.role !== UserRole.INSTITUTE_OWNER ||
          owner.status !== UserStatus.ACTIVE ||
          !owner.instituteId
        ) {
          throw new Error("Active institute owner required");
        }

        const institute = await Institute.findOne({
          _id: owner.instituteId,
          ownerId: owner._id,
          status: InstituteStatus.ACTIVE,
        }).session(session);

        if (!institute) {
          throw new Error("Active institute not found");
        }

        const reservation = await Reservation.findOne({
          _id: reservationId,
          instituteId: owner.instituteId,
          bookingType: BookingType.ONLINE,
          status: ReservationStatus.PAYMENT_SUBMITTED,
        }).session(session);

        if (!reservation) {
          throw new Error("Submitted reservation not found");
        }

        // استخدام المهلة المحددة في إعدادات المعهد.
        const hours: number = Number(
          institute.settings?.receiptResubmissionHours ?? 1,
        );

        const deadline = new Date(Date.now() + hours * 60 * 60 * 1000);

        reservation.status = ReservationStatus.REJECTED;
        reservation.rejectionReason = reason.trim();
        reservation.receiptResubmissionDeadline = deadline;

        await reservation.save({ session });

        result = reservation;
      });

      return result;
    } finally {
      await session.endSession();
    }
  }

  // =====================================================
  // 3. عرض حجوزات الطالب.
  // =====================================================
  async getMyReservations(studentId: string) {
    return Reservation.find({ studentId })
      .populate("courseId")
      .populate("instituteId", "name logo address")
      .sort({ createdAt: -1 });
  }

  // =====================================================
  // 4. عرض جميع تسجيلات المعهد.
  // =====================================================
  async getInstituteReservations(ownerId: string) {
    const owner = await User.findById(ownerId);

    if (
      !owner ||
      owner.role !== UserRole.INSTITUTE_OWNER ||
      !owner.instituteId
    ) {
      throw new Error("Institute owner not found");
    }

    return Reservation.find({
      instituteId: owner.instituteId,
    })
      .populate("courseId", "title price depositAmount")
      .populate("studentId", "name email phone")
      .sort({ createdAt: -1 });
  }

  // رفع سند التحويل بواسطة الطالب صاحب الحجز.

  // رفع سند التحويل مع إعادة التحقق من صلاحية الحجز عند الحفظ.
  async uploadReceipt(
    studentId: string,
    reservationId: string,
    fileBuffer: Buffer,
  ) {
    if (!mongoose.Types.ObjectId.isValid(reservationId)) {
      throw new Error("Invalid reservation ID");
    }

    // جلب الحجز الخاص بالطالب، مع قراءة بيانات السند السابق المخفية.
    const reservation = await Reservation.findOne({
      _id: reservationId,
      studentId,
      bookingType: BookingType.ONLINE,
    }).select("+receiptPublicId +receiptFormat");

    if (!reservation) {
      throw new Error("Reservation not found");
    }

    const now = new Date();

    // تحديد نوع الرفع المسموح به قبل البدء.
    const isFirstUpload =
      reservation.status === ReservationStatus.PENDING_PAYMENT &&
      !!reservation.expiresAt &&
      reservation.expiresAt > now;

    const isResubmission =
      reservation.status === ReservationStatus.REJECTED &&
      !!reservation.receiptResubmissionDeadline &&
      reservation.receiptResubmissionDeadline > now;

    if (!isFirstUpload && !isResubmission) {
      throw new Error("Receipt upload period has expired or is not allowed");
    }

    // الاحتفاظ بمعرف السند القديم لحذفه بعد نجاح استبداله.
    const oldPublicId = reservation.receiptPublicId;

    // رفع الصورة الجديدة إلى Cloudinary.
    const uploadedReceipt =
      await receiptUploadService.uploadReceipt(fileBuffer);

    try {
      const saveTime = new Date();

      // لا نحفظ الصورة إلا إذا كانت حالة الحجز والمهلة لا تزال تسمح بالرفع.
      const updatedReservation = await Reservation.findOneAndUpdate(
        {
          _id: reservationId,
          studentId,
          bookingType: BookingType.ONLINE,
          $or: [
            {
              status: ReservationStatus.PENDING_PAYMENT,
              expiresAt: { $gt: saveTime },
            },
            {
              status: ReservationStatus.REJECTED,
              receiptResubmissionDeadline: { $gt: saveTime },
            },
          ],
        },
        {
          $set: {
            receiptPublicId: uploadedReceipt.publicId,
            receiptFormat: uploadedReceipt.format,
            status: ReservationStatus.PAYMENT_SUBMITTED,
          },
          $unset: {
            receiptUrl: 1,
            rejectionReason: 1,
            receiptResubmissionDeadline: 1,
          },
        },
        {
          new: true,
          runValidators: true,
        },
      );

      // ربما انتهت المهلة أو تغيرت حالة الحجز أثناء رفع الصورة.
      if (!updatedReservation) {
        throw new Error(
          "Receipt upload period has expired or reservation status changed",
        );
      }

      // حذف السند السابق بعد التأكد من حفظ السند الجديد.
      if (oldPublicId && oldPublicId !== uploadedReceipt.publicId) {
        try {
          await receiptUploadService.deleteReceipt(oldPublicId);
        } catch (cleanupError) {
          // فشل الحذف لا يلغي نجاح رفع السند الجديد.
          console.error("Failed to delete previous receipt:", cleanupError);
        }
      }

      return updatedReservation;
    } catch (error) {
      // تنظيف الصورة الجديدة إذا فشل تحديث الحجز.
      try {
        await receiptUploadService.deleteReceipt(uploadedReceipt.publicId);
      } catch (cleanupError) {
        console.error("Failed to delete unused uploaded receipt:", cleanupError);
      }

      throw error;
    }
  }


  // إنشاء رابط مؤقت بعد التحقق من صاحب الصلاحية.
  async getReceiptAccessUrl(
    requesterId: string,
    role: UserRole,
    reservationId: string,
  ) {
    if (!mongoose.Types.ObjectId.isValid(reservationId)) {
      throw new Error("Invalid reservation ID");
    }

    const reservation = await Reservation.findById(reservationId)
      .select("+receiptPublicId +receiptFormat");

    if (!reservation) {
      throw new Error("Reservation not found");
    }

    // الطالب لا يرى إلا سند حجزه الخاص.
    if (role === UserRole.STUDENT) {
      if (reservation.studentId?.toString() !== requesterId) {
        throw new Error("Reservation not found");
      }
    }
    // صاحب المعهد لا يرى إلا سندات معهدِه.
    else if (role === UserRole.INSTITUTE_OWNER) {
      const owner = await User.findOne({
        _id: requesterId,
        role: UserRole.INSTITUTE_OWNER,
        status: UserStatus.ACTIVE,
      });

      if (
        !owner?.instituteId ||
        owner.instituteId.toString() !== reservation.instituteId.toString()
      ) {
        throw new Error("Reservation not found");
      }
    } else {
      throw new Error("Not authorized to view this receipt");
    }

    if (!reservation.receiptPublicId || !reservation.receiptFormat) {
      throw new Error("Receipt is not available");
    }

    return {
      receiptUrl: receiptUploadService.generateReceiptUrl(
        reservation.receiptPublicId,
        reservation.receiptFormat,
      ),
      expiresIn: 300,
    };
  }

}

export default new ReservationService();

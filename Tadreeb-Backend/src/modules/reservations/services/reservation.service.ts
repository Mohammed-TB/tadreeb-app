import mongoose, { HydratedDocument } from "mongoose";

import Course from "../../courses/models/course.model";
import Institute, {
  InstituteStatus,
} from "../../institutes/models/institute.model";
import User, { UserRole, UserStatus } from "../../users/user.model";
import Student from "../../students/student.model";
import Payment, {
  PaymentMethod,
  PaymentRecordStatus,
} from "../../payments/payment.model";

import Reservation from "../models/reservation.model";
import { ICourse } from "../../courses/types/course.types";
import { IReservation } from "../types/reservation.types";
import receiptUploadService from "./receipt-upload.service";
import {
  emitPaymentSubmitted,
  emitRegistrationConfirmed,
  emitRegistrationCreated,
  emitRegistrationRejected,
  emitSeatAvailabilityUpdated,
} from "../../../realtime/realtime.events";
import { getSaudiDayStart } from "../../courses/utils/course-date";
import { isValidE164Phone } from "../../../shared/phone-number";
import { normalizeFourPartName } from "../../../shared/student-name";
import {
  applyApprovedPayment,
  validateInitialPaymentAmount,
} from "../../payments/payment-policy";
import balancePaymentService from "./balance-payment.dependencies";
import { getInPersonInitialPaymentDecision } from "./in-person-payment-policy";
import { BalancePaymentPolicy } from "../../institutes/types/institute.types";

import {
  BookingType,
  PaymentOption,
  PaymentStatus,
  BalancePaymentStatus,
  ReservationStatus,
  AttendanceStatus,
} from "../types/reservation.types";

class ReservationService {
  private activeReservationStatuses(): ReservationStatus[] {
    return [
      ReservationStatus.PENDING_PAYMENT,
      ReservationStatus.PAYMENT_SUBMITTED,
      ReservationStatus.CONFIRMED,
      ReservationStatus.REJECTED,
    ];
  }

  // حجز مقعد مؤقت مع منع تجاوز سعة الدورة.

// حجز مقعد مؤقت مع منع تجاوز سعة الدورة.
private async reserveSeat(
  courseId: mongoose.Types.ObjectId,
  session: mongoose.ClientSession,
): Promise<any> {

  console.log("\n🔥 RESERVE SEAT FUNCTION CALLED");
  console.log("Course ID:", courseId.toString());

  // 1. قراءة بيانات الدورة للتشخيص.
  const diagnosticCourse = await Course.findById(courseId)
    .select(
      "title status capacity enrolledCount reservedCount startDate endDate"
    )
    .session(session)
    .lean();

  if (!diagnosticCourse) {
    console.log("❌ COURSE NOT FOUND");
    throw new Error("Course not found");
  }

  // 2. حساب الشروط بصورة منفصلة.
  const saudiDayStart = getSaudiDayStart();

  const enrolledCount = diagnosticCourse.enrolledCount ?? 0;
  const reservedCount = diagnosticCourse.reservedCount ?? 0;

  const statusPassed = diagnosticCourse.status === "published";

  const datePassed =
    diagnosticCourse.endDate >= saudiDayStart;

  const seatsPassed =
    enrolledCount + reservedCount < diagnosticCourse.capacity;

  console.log("========== COURSE BOOKING DIAGNOSTIC ==========");

  console.log({
    title: diagnosticCourse.title,
    courseId: courseId.toString(),

    status: diagnosticCourse.status,
    statusPassed,

    endDate: diagnosticCourse.endDate.toISOString(),
    saudiDayStart: saudiDayStart.toISOString(),
    datePassed,

    capacity: diagnosticCourse.capacity,
    enrolledCount,
    reservedCount,

    totalOccupied: enrolledCount + reservedCount,
    availableSeats:
      diagnosticCourse.capacity - enrolledCount - reservedCount,
    seatsPassed,
  });

  console.log("================================================");

  // 3. محاولة حجز المقعد ذرياً.
  const course = await Course.findOneAndUpdate(
    {
      _id: courseId,
      status: "published",
      endDate: { $gte: saudiDayStart },
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
    {
      $inc: { reservedCount: 1 },
    },
    {
      new: true,
      session,
    },
  );

  // 4. تسجيل نتيجة التحديث.
  if (!course) {
    console.log("❌ ATOMIC BOOKING QUERY FAILED");
    throw new Error("Course is unavailable or full");
  }

  console.log("✅ SEAT RESERVED SUCCESSFULLY");
  console.log({
    reservedCount: course.reservedCount,
    enrolledCount: course.enrolledCount,
    capacity: course.capacity,
  });

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
    paymentAmount: number,
    studentEnglishName?: string,
  ) {
    if (!mongoose.Types.ObjectId.isValid(courseId)) {
      throw new Error("Invalid course ID");
    }

    if (!studentName.trim() || !studentPhone.trim()) {
      throw new Error("Student name and phone are required");
    }
    const normalizedStudentName = normalizeFourPartName(studentName);
    if (!normalizedStudentName) {
      throw new Error("Student name must include the full four-part name");
    }
    const normalizedStudentPhone = studentPhone.trim();
    if (!isValidE164Phone(normalizedStudentPhone)) {
      throw new Error("Student phone must be in E.164 format");
    }

    const session = await mongoose.startSession();

    try {
      let result: HydratedDocument<IReservation> | undefined;
      let reservedCourse: HydratedDocument<ICourse> | undefined;

      await session.withTransaction(async () => {
        const student = await User.findById(studentId).session(session);

        if (
          !student ||
          student.role !== UserRole.STUDENT ||
          student.status !== UserStatus.ACTIVE
        ) {
          throw new Error("Active student account required");
        }
        const studentProfile = await Student.findOne({
          userId: student._id,
        }).session(session);

        // فحص الحظر قبل حجز المقعد لتجنب أي عدّادات مؤقتة عند التكرار.
        const existing = await Reservation.findOne({
          courseId: new mongoose.Types.ObjectId(courseId),
          status: { $in: this.activeReservationStatuses() },
          $or: [
            { studentId: student._id },
            { studentPhone: normalizedStudentPhone },
          ],
        }).session(session);

        if (existing) {
          throw new Error("You already have a reservation for this course");
        }

        // التحقق من وجود مقعد وحجزه مؤقتًا.
        const course: any = await this.reserveSeat(
          new mongoose.Types.ObjectId(courseId),
          session,
        );
        reservedCourse = course;

        const institute = await Institute.findOne({
          _id: course.instituteId,
          status: InstituteStatus.ACTIVE,
        }).session(session);

        if (!institute) {
          throw new Error("Institute is not active");
        }

        validateInitialPaymentAmount(
          paymentAmount,
          course.price,
          course.depositAmount,
        );
        const normalizedEnglishName =
          studentEnglishName?.trim() || studentProfile?.englishName;
        if (course.requiresEnglishName && !normalizedEnglishName) {
          throw new Error("English name is required for this course");
        }
        const paymentOption =
          paymentAmount >= course.price
            ? PaymentOption.FULL
            : PaymentOption.DEPOSIT;

        // مدة الحجز المؤقت: 24 ساعة.
        const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);

        const [reservation] = await Reservation.create(
          [
            {
              courseId: course._id,
              instituteId: course.instituteId,
              studentId: student._id,
              studentName: normalizedStudentName,
              studentPhone: normalizedStudentPhone,
              ...(normalizedEnglishName
                ? { studentEnglishName: normalizedEnglishName }
                : {}),
              bookingType: BookingType.ONLINE,
              createdBy: student._id,
              paymentOption,
              totalAmount: course.price,
              amountToPay: paymentAmount,
              amountPaid: 0,
              paymentStatus: PaymentStatus.UNPAID,
              balancePaymentPolicy:
                institute.settings.balancePaymentPolicy ??
                BalancePaymentPolicy.FULL_REMAINDER,
              minimumInstallmentAmount:
                institute.settings.minimumInstallmentAmount ?? 1,
              status: ReservationStatus.PENDING_PAYMENT,
              expiresAt,
              attendanceStatus: AttendanceStatus.NOT_MARKED,
            },
          ],
          { session },
        );

        result = reservation;
      });

      if (!result || !reservedCourse) {
        throw new Error("Online reservation transaction returned no result");
      }
      emitRegistrationCreated(result);
      emitSeatAvailabilityUpdated(reservedCourse);
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
      paymentAmount: number;
      paymentMethod: PaymentMethod;
      studentEnglishName?: string;
      receiptBuffer?: Buffer;
    },
  ) {
    if (!mongoose.Types.ObjectId.isValid(input.courseId)) {
      throw new Error("Invalid course ID");
    }

    const studentName = normalizeFourPartName(input.studentName);
    if (!studentName) {
      throw new Error("Student name must include the full four-part name");
    }
    if (!input.studentPhone?.trim()) {
      throw new Error("Student phone is required");
    }
    const normalizedStudentPhone = input.studentPhone.trim();
    if (!isValidE164Phone(normalizedStudentPhone)) {
      throw new Error("Student phone must be in E.164 format");
    }

    if (!Object.values(PaymentMethod).includes(input.paymentMethod)) {
      throw new Error("Invalid payment method");
    }
    if (
      input.paymentMethod === PaymentMethod.BANK_TRANSFER &&
      !input.receiptBuffer
    ) {
      throw new Error("Bank transfer receipt is required");
    }

    const uploadedReceipt =
      input.paymentMethod === PaymentMethod.BANK_TRANSFER
        ? await receiptUploadService.uploadReceipt(input.receiptBuffer!)
        : undefined;
    const session = await mongoose.startSession();

    try {
      let result: HydratedDocument<IReservation> | undefined;
      let updatedCourse: HydratedDocument<ICourse> | undefined;
      let paymentRequiresReview = false;

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
          endDate: { $gte: getSaudiDayStart() },
        } as any).session(session);

        if (!course) {
          throw new Error("Course not found or unavailable");
        }

        const linkedStudent = await User.findOne({
          role: UserRole.STUDENT,
          phone: normalizedStudentPhone,
        }).session(session);
        const linkedProfile = linkedStudent
          ? await Student.findOne({ userId: linkedStudent._id }).session(session)
          : null;
        const englishName =
          input.studentEnglishName?.trim() || linkedProfile?.englishName;
        if (course.requiresEnglishName && !englishName) {
          throw new Error("English name is required for this course");
        }

        const existingReservation = await Reservation.findOne({
          instituteId: owner.instituteId,
          courseId: course._id,
          status: { $in: this.activeReservationStatuses() },
          $or: [
            { studentPhone: normalizedStudentPhone },
            ...(linkedStudent ? [{ studentId: linkedStudent._id }] : []),
          ],
        }).session(session);

        if (existingReservation) {
          throw new Error(
            "Student already registered for this course with this phone and name",
          );
        }

        validateInitialPaymentAmount(
          input.paymentAmount,
          course.price,
          course.depositAmount,
        );
        const paymentDecision = getInPersonInitialPaymentDecision(
          input.paymentMethod,
          input.paymentAmount,
          course.price,
        );
        paymentRequiresReview = !paymentDecision.isApproved;

        // النقد يؤكد المقعد فورًا، أما التحويل فيحجزه حتى مراجعة السند.
        const reservedCourse: any = await Course.findOneAndUpdate(
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
          { $inc: { [paymentDecision.seatCounter]: 1 } },
          { new: true, session },
        );

        if (!reservedCourse) {
          throw new Error("No available seats");
        }
        updatedCourse = reservedCourse;

        const paymentOption =
          input.paymentAmount >= course.price
            ? PaymentOption.FULL
            : PaymentOption.DEPOSIT;

        // إنشاء تسجيل حضوري دون الحاجة لحساب طالب.
        const [reservation] = await Reservation.create(
          [
            {
              courseId: course._id,
              instituteId: owner.instituteId,
              ...(linkedStudent ? { studentId: linkedStudent._id } : {}),
              studentName,
              studentPhone: normalizedStudentPhone,
              ...(englishName ? { studentEnglishName: englishName } : {}),
              bookingType: BookingType.IN_PERSON,
              createdBy: owner._id,
              paymentOption,
              totalAmount: course.price,
              amountToPay: input.paymentAmount,
              amountPaid: paymentDecision.amountPaid,
              paymentStatus: paymentDecision.paymentStatus,
              balancePaymentPolicy:
                institute.settings.balancePaymentPolicy ??
                BalancePaymentPolicy.FULL_REMAINDER,
              minimumInstallmentAmount:
                institute.settings.minimumInstallmentAmount ?? 1,
              status: paymentDecision.reservationStatus,
              attendanceStatus: AttendanceStatus.NOT_MARKED,
              ...(uploadedReceipt
                ? {
                    receiptPublicId: uploadedReceipt.publicId,
                    receiptFormat: uploadedReceipt.format,
                  }
                : {}),
            },
          ],
          { session },
        );
        await Payment.create(
          [{
            reservationId: reservation._id,
            amount: input.paymentAmount,
            method: input.paymentMethod,
            status: paymentDecision.paymentRecordStatus,
            createdBy: owner._id,
            ...(paymentDecision.isApproved
              ? {
                  reviewedBy: owner._id,
                  reviewedAt: new Date(),
                }
              : {}),
            ...(uploadedReceipt
              ? {
                  receiptPublicId: uploadedReceipt.publicId,
                  receiptFormat: uploadedReceipt.format,
                }
              : {}),
          }],
          { session },
        );

        result = reservation;
      });

      if (!result || !updatedCourse) {
        throw new Error("In-person reservation transaction returned no result");
      }
      emitRegistrationCreated(result);
      if (paymentRequiresReview) {
        emitPaymentSubmitted(result);
      } else {
        emitRegistrationConfirmed(result);
      }
      emitSeatAvailabilityUpdated(updatedCourse);
      return result;
    } catch (error) {
      if (uploadedReceipt) {
        try {
          await receiptUploadService.deleteReceipt(uploadedReceipt.publicId);
        } catch (cleanupError) {
          console.error("Failed to clean up unused payment receipt:", cleanupError);
        }
      }
      throw error;
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
      let result: HydratedDocument<IReservation> | undefined;
      let updatedCourse: HydratedDocument<ICourse> | undefined;

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
          status: ReservationStatus.PAYMENT_SUBMITTED,
        }).session(session);

        if (!reservation) {
          throw new Error("Submitted reservation not found");
        }
        const payment = await Payment.findOne({
          reservationId: reservation._id,
          status: PaymentRecordStatus.PENDING,
        }).session(session);
        if (!payment || payment.amount !== reservation.amountToPay) {
          throw new Error("Pending initial payment not found");
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
        updatedCourse = course;

        payment.status = PaymentRecordStatus.APPROVED;
        payment.reviewedBy = owner._id;
        payment.reviewedAt = new Date();
        await payment.save({ session });

        const paymentBalance = applyApprovedPayment(
          reservation.totalAmount,
          reservation.amountPaid,
          payment.amount,
        );
        reservation.amountPaid = paymentBalance.amountPaid;
        reservation.paymentStatus = paymentBalance.isPaid
          ? PaymentStatus.PAID
          : PaymentStatus.PARTIAL;

        reservation.status = ReservationStatus.CONFIRMED;

        reservation.rejectionReason = undefined;
        reservation.receiptResubmissionDeadline = undefined;

        await reservation.save({ session });

        result = reservation;
      });

      if (!result || !updatedCourse) {
        throw new Error("Reservation approval transaction returned no result");
      }
      emitRegistrationConfirmed(result);
      emitSeatAvailabilityUpdated(updatedCourse);
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
      let result: HydratedDocument<IReservation> | undefined;

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
          status: ReservationStatus.PAYMENT_SUBMITTED,
        }).session(session);

        if (!reservation) {
          throw new Error("Submitted reservation not found");
        }
        const payment = await Payment.findOne({
          reservationId: reservation._id,
          status: PaymentRecordStatus.PENDING,
        }).session(session);
        if (!payment) {
          throw new Error("Pending initial payment not found");
        }

        // استخدام المهلة المحددة في إعدادات المعهد.
        const hours: number = Number(
          institute.settings?.receiptResubmissionHours ?? 1,
        );

        const deadline = new Date(Date.now() + hours * 60 * 60 * 1000);

        payment.status = PaymentRecordStatus.REJECTED;
        payment.reviewedBy = owner._id;
        payment.reviewedAt = new Date();
        payment.rejectionReason = reason.trim();
        await payment.save({ session });

        reservation.status = ReservationStatus.REJECTED;
        reservation.rejectionReason = reason.trim();
        reservation.receiptResubmissionDeadline = deadline;

        await reservation.save({ session });

        result = reservation;
      });

      if (!result) {
        throw new Error("Reservation rejection transaction returned no result");
      }
      emitRegistrationRejected(result);
      return result;
    } finally {
      await session.endSession();
    }
  }

  // =====================================================
  // 3. عرض حجوزات الطالب.
  // =====================================================
  async getMyReservations(studentId: string) {
    const reservations = await Reservation.find({ studentId })
      .populate("courseId")
      .populate("instituteId", "name logo address")
      .sort({ createdAt: -1 });
    const paymentHistory = await this.getPaymentHistory(
      reservations.map((reservation) => reservation._id),
    );
    return reservations.map((reservation) => ({
      ...reservation.toObject(),
      payments: paymentHistory.get(reservation.id) ?? [],
    }));
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

    const reservations = await Reservation.find({
      instituteId: owner.instituteId,
    })
      .populate("courseId", "title price depositAmount")
      .populate("studentId", "name email phone")
      .select(
        "+receiptPublicId +receiptFormat +receiptUrl +balanceReceiptPublicId +balanceReceiptFormat",
      )
      .sort({ createdAt: -1 });

    const paymentHistory = await this.getPaymentHistory(
      reservations.map((reservation) => reservation._id),
    );
    return reservations.map((reservation) => {
      const data = reservation.toObject();
      const hasReceipt = Boolean(data.receiptPublicId || data.receiptUrl);
      const hasBalanceReceipt = Boolean(data.balanceReceiptPublicId);
      delete data.receiptPublicId;
      delete data.receiptFormat;
      delete data.receiptUrl;
      delete data.balanceReceiptPublicId;
      delete data.balanceReceiptFormat;
      return {
        ...data,
        hasReceipt,
        hasBalanceReceipt,
        payments: paymentHistory.get(reservation.id) ?? [],
      };
    });
  }

  async getInstituteReservationById(ownerId: string, reservationId: string) {
    if (!mongoose.Types.ObjectId.isValid(reservationId)) {
      throw new Error("Invalid reservation ID");
    }

    const owner = await User.findById(ownerId);
    if (
      !owner ||
      owner.role !== UserRole.INSTITUTE_OWNER ||
      !owner.instituteId
    ) {
      throw new Error("Institute owner not found");
    }

    const reservation = await Reservation.findOne({
      _id: reservationId,
      instituteId: owner.instituteId,
    })
      .populate("courseId", "title price depositAmount")
      .populate("studentId", "name email phone")
      .select(
        "+receiptPublicId +receiptFormat +receiptUrl +balanceReceiptPublicId +balanceReceiptFormat",
      );

    if (!reservation) throw new Error("Reservation not found");

    const paymentHistory = await this.getPaymentHistory([reservation._id]);
    const data = reservation.toObject();
    const hasReceipt = Boolean(data.receiptPublicId || data.receiptUrl);
    const hasBalanceReceipt = Boolean(data.balanceReceiptPublicId);
    delete data.receiptPublicId;
    delete data.receiptFormat;
    delete data.receiptUrl;
    delete data.balanceReceiptPublicId;
    delete data.balanceReceiptFormat;

    return {
      ...data,
      hasReceipt,
      hasBalanceReceipt,
      payments: paymentHistory.get(reservation.id) ?? [],
    };
  }

  private async getPaymentHistory(
    reservationIds: mongoose.Types.ObjectId[],
  ): Promise<Map<string, Record<string, unknown>[]>> {
    const payments = await Payment.find({
      reservationId: { $in: reservationIds },
    })
      .select("+receiptPublicId +receiptFormat")
      .sort({ createdAt: 1 });
    const history = new Map<string, Record<string, unknown>[]>();
    for (const payment of payments) {
      const data = payment.toObject();
      const hasReceipt = Boolean(data.receiptPublicId);
      delete data.receiptPublicId;
      delete data.receiptFormat;
      const key = payment.reservationId.toString();
      const items = history.get(key) ?? [];
      items.push({ ...data, hasReceipt });
      history.set(key, items);
    }
    return history;
  }

  async findStudentNameByPhone(ownerId: string, phone: string) {
    if (!isValidE164Phone(phone)) {
      throw new Error("Student phone must be in E.164 format");
    }

    const owner = await User.findById(ownerId);
    if (
      !owner ||
      owner.role !== UserRole.INSTITUTE_OWNER ||
      owner.status !== UserStatus.ACTIVE ||
      !owner.instituteId
    ) {
      throw new Error("Active institute owner required");
    }

    const linkedUser = await User.findOne({
      role: UserRole.STUDENT,
      phone,
    }).select("_id");
    if (linkedUser) {
      const student = await Student.findOne({ userId: linkedUser._id }).select(
        "name",
      );
      if (student?.name) return student.name;
    }

    const reservation = await Reservation.findOne({
      instituteId: owner.instituteId,
      studentPhone: phone,
    })
      .select("studentName")
      .sort({ createdAt: -1 })
      .lean();

    return reservation?.studentName ?? null;
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

    // جلب الحجز الخاص بالطالب.
    const reservation = await Reservation.findOne({
      _id: reservationId,
      studentId,
      bookingType: BookingType.ONLINE,
    });

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

    const uploadedReceipt =
      await receiptUploadService.uploadReceipt(fileBuffer);
    const session = await mongoose.startSession();

    try {
      const saveTime = new Date();
      const updatedReservation = await session.withTransaction(async () => {
        const updated = await Reservation.findOneAndUpdate(
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
            session,
          },
        );
        if (!updated) {
          throw new Error(
            "Receipt upload period has expired or reservation status changed",
          );
        }

        await Payment.create(
          [{
            reservationId: reservation._id,
            amount: reservation.amountToPay,
            method: PaymentMethod.BANK_TRANSFER,
            status: PaymentRecordStatus.PENDING,
            createdBy: new mongoose.Types.ObjectId(studentId),
            receiptPublicId: uploadedReceipt.publicId,
            receiptFormat: uploadedReceipt.format,
          }],
          { session },
        );
        return updated;
      });

      if (!updatedReservation) {
        throw new Error("Initial payment submission returned no reservation");
      }

      emitPaymentSubmitted(updatedReservation);
      return updatedReservation;
    } catch (error) {
      // تنظيف الصورة الجديدة إذا فشل تحديث الحجز.
      try {
        await receiptUploadService.deleteReceipt(uploadedReceipt.publicId);
      } catch (cleanupError) {
        console.error("Failed to delete unused uploaded receipt:", cleanupError);
      }
      throw error;
    } finally {
      await session.endSession();
    }
  }

  async resubmitInPersonReceipt(
    ownerId: string,
    reservationId: string,
    fileBuffer: Buffer,
  ) {
    if (!mongoose.Types.ObjectId.isValid(reservationId)) {
      throw new Error("Invalid reservation ID");
    }

    const owner = await User.findOne({
      _id: ownerId,
      role: UserRole.INSTITUTE_OWNER,
      status: UserStatus.ACTIVE,
    });
    if (!owner?.instituteId) {
      throw new Error("Active institute owner required");
    }

    const uploadedReceipt =
      await receiptUploadService.uploadReceipt(fileBuffer);
    const session = await mongoose.startSession();

    try {
      let updatedReservation: HydratedDocument<IReservation> | undefined;
      const saveTime = new Date();
      await session.withTransaction(async () => {
        const reservation = await Reservation.findOne({
          _id: reservationId,
          instituteId: owner.instituteId,
          bookingType: BookingType.IN_PERSON,
          status: ReservationStatus.REJECTED,
          receiptResubmissionDeadline: { $gt: saveTime },
        }).session(session);
        if (!reservation) {
          throw new Error("Receipt resubmission period has expired");
        }

        const rejectedPayment = await Payment.findOne({
          reservationId: reservation._id,
          amount: reservation.amountToPay,
          method: PaymentMethod.BANK_TRANSFER,
          status: PaymentRecordStatus.REJECTED,
        })
          .sort({ createdAt: -1 })
          .session(session);
        if (!rejectedPayment) {
          throw new Error("Rejected initial transfer payment not found");
        }

        reservation.receiptPublicId = uploadedReceipt.publicId;
        reservation.receiptFormat = uploadedReceipt.format;
        reservation.receiptUrl = undefined;
        reservation.status = ReservationStatus.PAYMENT_SUBMITTED;
        reservation.rejectionReason = undefined;
        reservation.receiptResubmissionDeadline = undefined;
        await reservation.save({ session });

        await Payment.create(
          [
            {
              reservationId: reservation._id,
              amount: reservation.amountToPay,
              method: PaymentMethod.BANK_TRANSFER,
              status: PaymentRecordStatus.PENDING,
              createdBy: owner._id,
              receiptPublicId: uploadedReceipt.publicId,
              receiptFormat: uploadedReceipt.format,
            },
          ],
          { session },
        );
        updatedReservation = reservation;
      });

      if (!updatedReservation) {
        throw new Error("In-person receipt resubmission returned no reservation");
      }

      emitPaymentSubmitted(updatedReservation);
      return updatedReservation;
    } catch (error) {
      try {
        await receiptUploadService.deleteReceipt(uploadedReceipt.publicId);
      } catch (cleanupError) {
        console.error("Failed to clean up unused payment receipt:", cleanupError);
      }
      throw error;
    } finally {
      await session.endSession();
    }
  }

  async uploadBalancePaymentReceipt(
    studentId: string,
    reservationId: string,
    amount: number,
    fileBuffer: Buffer,
  ) {
    return balancePaymentService.uploadBalancePaymentReceipt(
      studentId,
      reservationId,
      amount,
      fileBuffer,
    );
  }

  async approveBalancePayment(ownerId: string, reservationId: string) {
    return balancePaymentService.approveBalancePayment(ownerId, reservationId);
  }

  async recordInPersonBalancePayment(
    ownerId: string,
    reservationId: string,
    amount: number,
  ) {
    return balancePaymentService.recordInPersonBalancePayment(
      ownerId,
      reservationId,
      amount,
    );
  }

  async recordInPersonBankTransferPayment(
    ownerId: string,
    reservationId: string,
    amount: number,
    fileBuffer: Buffer,
  ) {
    return balancePaymentService.recordInPersonBankTransferPayment(
      ownerId,
      reservationId,
      amount,
      fileBuffer,
    );
  }

  async rejectBalancePayment(
    ownerId: string,
    reservationId: string,
    reason: string,
  ) {
    return balancePaymentService.rejectBalancePayment(
      ownerId,
      reservationId,
      reason,
    );
  }

  // إنشاء رابط مؤقت بعد التحقق من صاحب الصلاحية.
  async getReceiptAccessUrl(
    requesterId: string,
    role: UserRole,
    reservationId: string,
    receiptType: "initial" | "balance" = "initial",
  ) {
    if (!mongoose.Types.ObjectId.isValid(reservationId)) {
      throw new Error("Invalid reservation ID");
    }

    const reservation = await Reservation.findById(reservationId)
      .select(
        "+receiptPublicId +receiptFormat +balanceReceiptPublicId +balanceReceiptFormat",
      );

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

    const publicId =
      receiptType === "balance"
        ? reservation.balanceReceiptPublicId
        : reservation.receiptPublicId;
    const format =
      receiptType === "balance"
        ? reservation.balanceReceiptFormat
        : reservation.receiptFormat;

    if (!publicId || !format) {
      throw new Error("Receipt is not available");
    }

    return {
      receiptUrl: receiptUploadService.generateReceiptUrl(
        publicId,
        format,
      ),
      expiresIn: 300,
    };
  }

  async getPaymentReceiptAccessUrl(
    requesterId: string,
    role: UserRole,
    paymentId: string,
  ) {
    if (!mongoose.Types.ObjectId.isValid(paymentId)) {
      throw new Error("Invalid payment ID");
    }

    const payment = await Payment.findById(paymentId).select(
      "+receiptPublicId +receiptFormat",
    );
    if (!payment?.receiptPublicId || !payment.receiptFormat) {
      throw new Error("Receipt is not available");
    }

    const reservation = await Reservation.findById(payment.reservationId);
    if (!reservation) {
      throw new Error("Reservation not found");
    }

    if (role === UserRole.STUDENT) {
      if (reservation.studentId?.toString() !== requesterId) {
        throw new Error("Reservation not found");
      }
    } else if (role === UserRole.INSTITUTE_OWNER) {
      const owner = await User.findOne({
        _id: requesterId,
        role: UserRole.INSTITUTE_OWNER,
        status: UserStatus.ACTIVE,
      }).select("instituteId");
      if (owner?.instituteId?.toString() !== reservation.instituteId.toString()) {
        throw new Error("Reservation not found");
      }
    } else {
      throw new Error("Not authorized to view this receipt");
    }

    return {
      receiptUrl: receiptUploadService.generateReceiptUrl(
        payment.receiptPublicId,
        payment.receiptFormat,
      ),
      expiresIn: 300,
    };
  }

}

export default new ReservationService();

import mongoose, { HydratedDocument } from "mongoose";

import Course from "../../courses/models/course.model";
import Institute, {
  InstituteStatus,
} from "../../institutes/models/institute.model";
import User, { UserRole, UserStatus } from "../../users/user.model";

import Reservation from "../models/reservation.model";
import { ICourse } from "../../courses/types/course.types";
import { IReservation } from "../types/reservation.types";
import receiptUploadService from "./receipt-upload.service";
import {
  emitBalancePaymentReviewed,
  emitInPersonBalancePaymentRecorded,
  emitBalancePaymentSubmitted,
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
  BookingType,
  PaymentOption,
  PaymentStatus,
  BalancePaymentStatus,
  BalancePaymentMethod,
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
              studentPhone: normalizedStudentPhone,
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
      paymentOption: PaymentOption;
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

    if (!Object.values(PaymentOption).includes(input.paymentOption)) {
      throw new Error("Invalid payment option");
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
          endDate: { $gte: getSaudiDayStart() },
        } as any).session(session);

        if (!course) {
          throw new Error("Course not found or unavailable");
        }

        const existingReservation = await Reservation.findOne({
          instituteId: owner.instituteId,
          courseId: course._id,
          studentName,
          studentPhone: normalizedStudentPhone,
          status: {
            $in: [
              ReservationStatus.PENDING_PAYMENT,
              ReservationStatus.PAYMENT_SUBMITTED,
              ReservationStatus.CONFIRMED,
            ],
          },
        }).session(session);

        if (existingReservation) {
          throw new Error(
            "Student already registered for this course with this phone and name",
          );
        }

        // تأكيد المقعد مباشرة للتسجيل الحضوري.
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
          { $inc: { enrolledCount: 1 } },
          { new: true, session },
        );

        if (!reservedCourse) {
          throw new Error("No available seats");
        }
        updatedCourse = reservedCourse;

        const amountToPay = this.getAmountToPay(
          input.paymentOption,
          course.price,
          course.depositAmount,
        );
        if (
          input.paymentOption === PaymentOption.DEPOSIT &&
          course.depositAmount <= 0
        ) {
          throw new Error("Deposit payment is not available for this course");
        }
        const amountPaid = amountToPay;

        const paymentStatus =
          amountPaid >= course.price
            ? PaymentStatus.PAID
            : amountPaid > 0
              ? PaymentStatus.PARTIAL
              : PaymentStatus.UNPAID;

        // إنشاء تسجيل حضوري مؤكد دون الحاجة لحساب طالب.
        const [reservation] = await Reservation.create(
          [
            {
              courseId: course._id,
              instituteId: owner.instituteId,
              studentName,
              studentPhone: normalizedStudentPhone,
              bookingType: BookingType.IN_PERSON,
              createdBy: owner._id,
              paymentOption: input.paymentOption,
              totalAmount: course.price,
              amountToPay,
              amountPaid,
              paymentStatus,
              status: ReservationStatus.CONFIRMED,
              attendanceStatus: AttendanceStatus.NOT_MARKED,
            },
          ],
          { session },
        );

        result = reservation;
      });

      if (!result || !updatedCourse) {
        throw new Error("In-person reservation transaction returned no result");
      }
      emitRegistrationCreated(result);
      emitRegistrationConfirmed(result);
      emitSeatAvailabilityUpdated(updatedCourse);
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
        updatedCourse = course;

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

    const reservations = await Reservation.find({
      instituteId: owner.instituteId,
    })
      .populate("courseId", "title price depositAmount")
      .populate("studentId", "name email phone")
      .select(
        "+receiptPublicId +receiptFormat +receiptUrl +balanceReceiptPublicId +balanceReceiptFormat",
      )
      .sort({ createdAt: -1 });

    return reservations.map((reservation) => {
      const data = reservation.toObject();
      const hasReceipt = Boolean(data.receiptPublicId || data.receiptUrl);
      const hasBalanceReceipt = Boolean(data.balanceReceiptPublicId);
      delete data.receiptPublicId;
      delete data.receiptFormat;
      delete data.receiptUrl;
      delete data.balanceReceiptPublicId;
      delete data.balanceReceiptFormat;
      return { ...data, hasReceipt, hasBalanceReceipt };
    });
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
    }
  }

  async uploadBalancePaymentReceipt(
    studentId: string,
    reservationId: string,
    fileBuffer: Buffer,
  ) {
    if (!mongoose.Types.ObjectId.isValid(reservationId)) {
      throw new Error("Invalid reservation ID");
    }

    const reservation = await Reservation.findOne({
      _id: reservationId,
      studentId,
      bookingType: BookingType.ONLINE,
    }).select("+balanceReceiptPublicId +balanceReceiptFormat");

    if (!reservation) {
      throw new Error("Reservation not found");
    }

    const remainingAmount = reservation.totalAmount - reservation.amountPaid;
    if (
      reservation.status !== ReservationStatus.CONFIRMED ||
      reservation.paymentStatus !== PaymentStatus.PARTIAL ||
      remainingAmount <= 0 ||
      reservation.balancePaymentStatus === BalancePaymentStatus.PENDING ||
      reservation.balancePaymentStatus === BalancePaymentStatus.APPROVED
    ) {
      throw new Error("Balance payment is not available for this reservation");
    }

    const oldPublicId = reservation.balanceReceiptPublicId;
    const uploadedReceipt =
      await receiptUploadService.uploadReceipt(fileBuffer);

    try {
      const updatedReservation = await Reservation.findOneAndUpdate(
        {
          _id: reservationId,
          studentId,
          bookingType: BookingType.ONLINE,
          status: ReservationStatus.CONFIRMED,
          paymentStatus: PaymentStatus.PARTIAL,
          balancePaymentStatus: {
            $nin: [
              BalancePaymentStatus.PENDING,
              BalancePaymentStatus.APPROVED,
            ],
          },
          amountPaid: reservation.amountPaid,
        },
        {
          $set: {
            balancePaymentAmount: remainingAmount,
            balancePaymentStatus: BalancePaymentStatus.PENDING,
            balancePaymentMethod: BalancePaymentMethod.BANK_TRANSFER,
            balanceReceiptPublicId: uploadedReceipt.publicId,
            balanceReceiptFormat: uploadedReceipt.format,
          },
          $unset: {
            balancePaymentRejectionReason: 1,
            balancePaymentRecordedAt: 1,
            balancePaymentRecordedBy: 1,
          },
        },
        { new: true, runValidators: true },
      );

      if (!updatedReservation) {
        throw new Error("Balance payment status changed; please refresh");
      }

      if (oldPublicId && oldPublicId !== uploadedReceipt.publicId) {
        try {
          await receiptUploadService.deleteReceipt(oldPublicId);
        } catch (cleanupError) {
          console.error("Failed to delete previous balance receipt:", cleanupError);
        }
      }

      emitBalancePaymentSubmitted(updatedReservation);
      return updatedReservation;
    } catch (error) {
      try {
        await receiptUploadService.deleteReceipt(uploadedReceipt.publicId);
      } catch (cleanupError) {
        console.error("Failed to delete unused balance receipt:", cleanupError);
      }
      throw error;
    }
  }

  async approveBalancePayment(ownerId: string, reservationId: string) {
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

    const reservation = await Reservation.findOne({
      _id: reservationId,
      instituteId: owner.instituteId,
      status: ReservationStatus.CONFIRMED,
      paymentStatus: PaymentStatus.PARTIAL,
      balancePaymentStatus: BalancePaymentStatus.PENDING,
    });

    if (!reservation) {
      throw new Error("Pending balance payment not found");
    }

    const amountPaid = reservation.amountPaid + reservation.balancePaymentAmount;
    if (amountPaid > reservation.totalAmount) {
      throw new Error("Balance payment exceeds the remaining amount");
    }

    const updatedReservation = await Reservation.findOneAndUpdate(
      {
        _id: reservationId,
        instituteId: owner.instituteId,
        status: ReservationStatus.CONFIRMED,
        paymentStatus: PaymentStatus.PARTIAL,
        balancePaymentStatus: BalancePaymentStatus.PENDING,
        amountPaid: reservation.amountPaid,
        balancePaymentAmount: reservation.balancePaymentAmount,
      },
      {
        $set: {
          amountPaid,
          paymentStatus:
            amountPaid >= reservation.totalAmount
              ? PaymentStatus.PAID
              : PaymentStatus.PARTIAL,
          balancePaymentStatus: BalancePaymentStatus.APPROVED,
          balancePaymentMethod: BalancePaymentMethod.BANK_TRANSFER,
        },
        $unset: {
          balancePaymentRejectionReason: 1,
        },
      },
      { new: true, runValidators: true },
    );

    if (!updatedReservation) {
      throw new Error("Balance payment status changed; please refresh");
    }

    emitBalancePaymentReviewed(updatedReservation);
    return updatedReservation;
  }

  async recordInPersonBalancePayment(ownerId: string, reservationId: string) {
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

    const reservation = await Reservation.findOne({
      _id: reservationId,
      instituteId: owner.instituteId,
    }).select("+balanceReceiptPublicId");

    if (!reservation) {
      throw new Error("Reservation not found");
    }

    const remainingAmount = reservation.totalAmount - reservation.amountPaid;
    if (
      reservation.status !== ReservationStatus.CONFIRMED ||
      reservation.paymentStatus !== PaymentStatus.PARTIAL ||
      remainingAmount <= 0 ||
      reservation.balancePaymentStatus === BalancePaymentStatus.PENDING ||
      reservation.balancePaymentStatus === BalancePaymentStatus.APPROVED
    ) {
      throw new Error("Balance payment is not available for this reservation");
    }

    const recordedAt = new Date();
    const updatedReservation = await Reservation.findOneAndUpdate(
      {
        _id: reservationId,
        instituteId: owner.instituteId,
        status: ReservationStatus.CONFIRMED,
        paymentStatus: PaymentStatus.PARTIAL,
        balancePaymentStatus: {
          $nin: [
            BalancePaymentStatus.PENDING,
            BalancePaymentStatus.APPROVED,
          ],
        },
        amountPaid: reservation.amountPaid,
        totalAmount: reservation.totalAmount,
      },
      {
        $set: {
          amountPaid: reservation.totalAmount,
          paymentStatus: PaymentStatus.PAID,
          balancePaymentAmount: remainingAmount,
          balancePaymentStatus: BalancePaymentStatus.APPROVED,
          balancePaymentMethod: BalancePaymentMethod.IN_PERSON,
          balancePaymentRecordedAt: recordedAt,
          balancePaymentRecordedBy: owner._id,
        },
        $unset: {
          balancePaymentRejectionReason: 1,
          balanceReceiptPublicId: 1,
          balanceReceiptFormat: 1,
        },
      },
      { new: true, runValidators: true },
    );

    if (!updatedReservation) {
      throw new Error("Balance payment status changed; please refresh");
    }

    if (reservation.balanceReceiptPublicId) {
      try {
        await receiptUploadService.deleteReceipt(
          reservation.balanceReceiptPublicId,
        );
      } catch (cleanupError) {
        console.error(
          "Failed to delete resolved balance receipt:",
          cleanupError,
        );
      }
    }

    emitBalancePaymentReviewed(updatedReservation);
    emitInPersonBalancePaymentRecorded(updatedReservation);
    return updatedReservation;
  }

  async rejectBalancePayment(
    ownerId: string,
    reservationId: string,
    reason: string,
  ) {
    if (!mongoose.Types.ObjectId.isValid(reservationId)) {
      throw new Error("Invalid reservation ID");
    }
    if (!reason.trim()) {
      throw new Error("Rejection reason is required");
    }

    const owner = await User.findOne({
      _id: ownerId,
      role: UserRole.INSTITUTE_OWNER,
      status: UserStatus.ACTIVE,
    });

    if (!owner?.instituteId) {
      throw new Error("Active institute owner required");
    }

    const reservation = await Reservation.findOneAndUpdate(
      {
        _id: reservationId,
        instituteId: owner.instituteId,
        status: ReservationStatus.CONFIRMED,
        paymentStatus: PaymentStatus.PARTIAL,
        balancePaymentStatus: BalancePaymentStatus.PENDING,
      },
      {
        $set: {
          balancePaymentStatus: BalancePaymentStatus.REJECTED,
          balancePaymentRejectionReason: reason.trim(),
        },
      },
      { new: true, runValidators: true },
    );

    if (!reservation) {
      throw new Error("Pending balance payment not found");
    }

    emitBalancePaymentReviewed(reservation);
    return reservation;
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

}

export default new ReservationService();

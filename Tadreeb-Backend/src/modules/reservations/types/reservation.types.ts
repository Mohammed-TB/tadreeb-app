import mongoose from "mongoose";

export enum BookingType {
  ONLINE = "online",
  IN_PERSON = "inPerson",
}

export enum PaymentOption {
  DEPOSIT = "deposit",
  FULL = "full",
}

export enum ReservationStatus {
  PENDING_PAYMENT = "pendingPayment",
  PAYMENT_SUBMITTED = "paymentSubmitted",
  CONFIRMED = "confirmed",
  REJECTED = "rejected",
  EXPIRED = "expired",
  CANCELLED = "cancelled",
}

export enum PaymentStatus {
  UNPAID = "unpaid",
  PARTIAL = "partial",
  PAID = "paid",
}

export enum AttendanceStatus {
  NOT_MARKED = "notMarked",
  ATTENDED = "attended",
  ABSENT = "absent",
}

export interface IReservation {
  courseId: mongoose.Types.ObjectId;
  instituteId: mongoose.Types.ObjectId;

  // اختياري لأن التسجيل الحضوري لا يشترط حساب طالب.
  studentId?: mongoose.Types.ObjectId;

  // بيانات الطالب تحفظ حتى لو لم يمتلك حسابًا.
  studentName: string;
  studentPhone: string;

  bookingType: BookingType;
  createdBy: mongoose.Types.ObjectId;

  paymentOption: PaymentOption;
  totalAmount: number;
  amountToPay: number;
  amountPaid: number;
  paymentStatus: PaymentStatus;

  receiptPublicId?: string;
  receiptFormat?: string;
  receiptUrl?: string;
  rejectionReason?: string;
  receiptResubmissionDeadline?: Date;

  status: ReservationStatus;
  expiresAt?: Date;

  attendanceStatus: AttendanceStatus;

  createdAt: Date;
  updatedAt: Date;
}

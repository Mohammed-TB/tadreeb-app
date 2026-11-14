import mongoose, { Schema } from "mongoose";
import {
  IReservation,
  BookingType,
  PaymentOption,
  PaymentStatus,
  ReservationStatus,
  AttendanceStatus,
} from "../types/reservation.types";

const reservationSchema = new Schema<IReservation>(
  {
    courseId: {
      type: Schema.Types.ObjectId,
      ref: "Course",
      required: true,
      index: true,
    },

    instituteId: {
      type: Schema.Types.ObjectId,
      ref: "Institute",
      required: true,
      index: true,
    },

    studentId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      default: undefined,
    },

    studentName: {
      type: String,
      required: true,
      trim: true,
      minlength: 2,
      maxlength: 150,
    },

    studentPhone: {
      type: String,
      required: true,
      trim: true,
    },

    bookingType: {
      type: String,
      enum: Object.values(BookingType),
      required: true,
    },

    createdBy: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    paymentOption: {
      type: String,
      enum: Object.values(PaymentOption),
      required: true,
    },

    totalAmount: {
      type: Number,
      required: true,
      min: 0,
    },

    amountToPay: {
      type: Number,
      required: true,
      min: 0,
    },

    amountPaid: {
      type: Number,
      required: true,
      min: 0,
      default: 0,
    },

    paymentStatus: {
      type: String,
      enum: Object.values(PaymentStatus),
      default: PaymentStatus.UNPAID,
    },
receiptPublicId: {
  type: String,
  trim: true,
  select:false,

},

receiptFormat: {
  type: String,
  trim: true,
  select:false,
},

// للتوافق مع السجلات القديمة فقط.
receiptUrl: {
  type: String,
  select: false,
},

    rejectionReason: {
      type: String,
      trim: true,
      maxlength: 500,
    },

    receiptResubmissionDeadline: Date,

    status: {
      type: String,
      enum: Object.values(ReservationStatus),
      required: true,
    },

    // الحجز الإلكتروني مؤقت، أما الحضوري فلا يحتاج إلى انتهاء مؤقت.
    expiresAt: Date,

    attendanceStatus: {
      type: String,
      enum: Object.values(AttendanceStatus),
      default: AttendanceStatus.NOT_MARKED,
    },
  },
  { timestamps: true },
);

// فهارس تسهّل عرض حجوزات الطالب والمعهد.
reservationSchema.index({ studentId: 1, createdAt: -1 });
reservationSchema.index({ instituteId: 1, status: 1 });
reservationSchema.index({ courseId: 1, status: 1 });

const Reservation = mongoose.model<IReservation>(
  "Reservation",
  reservationSchema,
);

export default Reservation;
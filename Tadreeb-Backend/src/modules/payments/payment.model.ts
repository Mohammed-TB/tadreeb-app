import mongoose, { Schema } from "mongoose";

export enum PaymentMethod {
  CASH = "cash",
  BANK_TRANSFER = "bankTransfer",
}

export enum PaymentRecordStatus {
  PENDING = "pending",
  APPROVED = "approved",
  REJECTED = "rejected",
}

export interface IPayment extends mongoose.Document {
  reservationId: mongoose.Types.ObjectId;
  amount: number;
  method: PaymentMethod;
  status: PaymentRecordStatus;
  createdBy: mongoose.Types.ObjectId;
  reviewedBy?: mongoose.Types.ObjectId;
  reviewedAt?: Date;
  receiptPublicId?: string;
  receiptFormat?: string;
  rejectionReason?: string;
  createdAt: Date;
  updatedAt: Date;
}

const paymentSchema = new Schema<IPayment>(
  {
    reservationId: {
      type: Schema.Types.ObjectId,
      ref: "Reservation",
      required: true,
      index: true,
    },
    amount: {
      type: Number,
      required: true,
      min: 0.01,
    },
    method: {
      type: String,
      enum: Object.values(PaymentMethod),
      required: true,
    },
    status: {
      type: String,
      enum: Object.values(PaymentRecordStatus),
      required: true,
    },
    createdBy: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    reviewedBy: {
      type: Schema.Types.ObjectId,
      ref: "User",
    },
    reviewedAt: Date,
    receiptPublicId: {
      type: String,
      trim: true,
      select: false,
    },
    receiptFormat: {
      type: String,
      trim: true,
      select: false,
    },
    rejectionReason: {
      type: String,
      trim: true,
      maxlength: 500,
    },
  },
  { timestamps: true },
);

paymentSchema.index(
  { reservationId: 1 },
  {
    unique: true,
    partialFilterExpression: { status: PaymentRecordStatus.PENDING },
  },
);
paymentSchema.index({ reservationId: 1, createdAt: -1 });

const Payment = mongoose.model<IPayment>("Payment", paymentSchema);

export default Payment;

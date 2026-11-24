import mongoose, { Document, Schema } from "mongoose";

export type NotificationType =
  | "coursePublished"
  | "reservationCreated"
  | "paymentSubmitted"
  | "balancePaymentSubmitted"
  | "reservationConfirmed"
  | "reservationRejected"
  | "balancePaymentReviewed"
  | "inPersonBalancePaymentRecorded"
  | "seatHoldExpired";

export type NotificationEntityType = "course" | "reservation";

export interface INotification extends Document {
  type: NotificationType;
  title: string;
  body: string;
  entityType: NotificationEntityType;
  entityId: mongoose.Types.ObjectId;
  action: "openCourseDetails" | "openReservationDetails";
  data: Record<string, unknown>;
  createdAt: Date;
  updatedAt: Date;
}

const notificationSchema = new Schema<INotification>(
  {
    type: { type: String, required: true },
    title: { type: String, required: true, trim: true, maxlength: 200 },
    body: { type: String, required: true, trim: true, maxlength: 1000 },
    entityType: {
      type: String,
      enum: ["course", "reservation"],
      required: true,
    },
    entityId: {
      type: Schema.Types.ObjectId,
      required: true,
      index: true,
    },
    action: {
      type: String,
      enum: ["openCourseDetails", "openReservationDetails"],
      required: true,
    },
    data: { type: Schema.Types.Mixed, default: {} },
  },
  { timestamps: true },
);

notificationSchema.index({ createdAt: -1 });

export default mongoose.model<INotification>(
  "Notification",
  notificationSchema,
);

import mongoose, { Document, Schema } from "mongoose";

export interface INotificationRecipient extends Document {
  notificationId: mongoose.Types.ObjectId;
  userId: mongoose.Types.ObjectId;
  isRead: boolean;
  readAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const notificationRecipientSchema = new Schema<INotificationRecipient>(
  {
    notificationId: {
      type: Schema.Types.ObjectId,
      ref: "Notification",
      required: true,
      index: true,
    },
    userId: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    isRead: { type: Boolean, default: false, index: true },
    readAt: Date,
  },
  { timestamps: true },
);

notificationRecipientSchema.index(
  { notificationId: 1, userId: 1 },
  { unique: true },
);
notificationRecipientSchema.index({ userId: 1, isRead: 1, createdAt: -1 });

export default mongoose.model<INotificationRecipient>(
  "NotificationRecipient",
  notificationRecipientSchema,
);

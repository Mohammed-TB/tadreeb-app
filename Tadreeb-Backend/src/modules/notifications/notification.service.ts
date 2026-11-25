import mongoose from "mongoose";
import Notification, {
  INotification,
  NotificationType,
  NotificationEntityType,
} from "./notification.model";
import NotificationRecipient from "./notification-recipient.model";
import { emitToUser } from "../../realtime/realtime.gateway";
import User, { UserRole } from "../users/user.model";

interface CreateNotificationInput {
  type: NotificationType;
  title: string;
  body: string;
  entityType: NotificationEntityType;
  entityId: unknown;
  action: "openCourseDetails" | "openReservationDetails";
  data?: Record<string, unknown>;
  recipientIds: string[];
}

class NotificationService {
  async createAndNotify(input: CreateNotificationInput): Promise<void> {
    const recipientIds = [...new Set(input.recipientIds)].filter((id) =>
      mongoose.Types.ObjectId.isValid(id),
    );
    if (recipientIds.length === 0) return;

    const notification = await Notification.create({
      type: input.type,
      title: input.title,
      body: input.body,
      entityType: input.entityType,
      entityId: new mongoose.Types.ObjectId(String(input.entityId)),
      action: input.action,
      data: input.data ?? {},
    });

    await NotificationRecipient.insertMany(
      recipientIds.map((userId) => ({
        notificationId: notification._id,
        userId: new mongoose.Types.ObjectId(userId),
        isRead: false,
      })),
      { ordered: false },
    );

    const payload = this.toPayload(notification, false);
    for (const recipientId of recipientIds) {
      emitToUser(recipientId, "notificationCreated", payload);
    }
  }

  async notifyAllStudents(input: Omit<CreateNotificationInput, "recipientIds">) {
    const students = await User.find({
      role: UserRole.STUDENT,
      status: "active",
    } as any).select("_id");
    await this.createAndNotify({
      ...input,
      recipientIds: students.map((student) => student.id),
    });
  }

  async getForUser(userId: string, page = 1, limit = 30) {
    const safePage = Math.max(1, page);
    const safeLimit = Math.min(100, Math.max(1, limit));

    const recipients = await NotificationRecipient.find({
      userId: new mongoose.Types.ObjectId(userId),
    })
      .sort({ createdAt: -1 })
      .skip((safePage - 1) * safeLimit)
      .limit(safeLimit)
      .populate("notificationId");

    const data = recipients
      .filter((recipient) => recipient.notificationId)
      .map((recipient) =>
        this.toPayload(
          recipient.notificationId as any,
          recipient.isRead,
          recipient.readAt,
          recipient.id,
        ),
      );

    const unreadCount = await NotificationRecipient.countDocuments({
      userId: new mongoose.Types.ObjectId(userId),
      isRead: false,
    });

    return { data, unreadCount };
  }

  async markRead(userId: string, recipientId: string) {
    if (!mongoose.Types.ObjectId.isValid(recipientId)) {
      throw new Error("Invalid notification ID");
    }
    return NotificationRecipient.findOneAndUpdate(
      {
        _id: recipientId,
        userId: new mongoose.Types.ObjectId(userId),
      },
      { $set: { isRead: true, readAt: new Date() } },
      { new: true },
    );
  }

  async markAllRead(userId: string) {
    await NotificationRecipient.updateMany(
      {
        userId: new mongoose.Types.ObjectId(userId),
        isRead: false,
      },
      { $set: { isRead: true, readAt: new Date() } },
    );
  }

  private toPayload(
    notification: INotification,
    isRead: boolean,
    readAt?: Date,
    recipientId?: string,
  ) {
    return {
      id: recipientId ?? notification._id.toString(),
      notificationId: notification._id.toString(),
      type: notification.type,
      title: notification.title,
      body: notification.body,
      entityType: notification.entityType,
      entityId: notification.entityId.toString(),
      action: notification.action,
      data: notification.data,
      isRead,
      readAt: readAt?.toISOString() ?? null,
      createdAt: notification.createdAt.toISOString(),
    };
  }
}

export default new NotificationService();

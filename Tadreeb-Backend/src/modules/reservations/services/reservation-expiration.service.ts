import mongoose from "mongoose";

import  Reservation  from "../models/reservation.model";
import  Course  from "../../courses/models/course.model";
import { ReservationStatus } from "../types/reservation.types";

/**
 * البحث عن الحجوزات التي انتهت مهلتها وتحرير مقاعدها.
 *
 * الحالات التي تنتهي:
 * 1. pendingPayment: انتهت مهلة الدفع.
 * 2. rejected: انتهت مهلة إعادة رفع السند.
 *
 * paymentSubmitted لا تدخل ضمن الفحص؛ لأنها بانتظار مراجعة المعهد.
 */
export const expireReservations = async (): Promise<number> => {
  const now = new Date();

  // جلب الحجوزات المرشحة للانتهاء فقط.
  const candidates = await Reservation.find({
    $or: [
      {
        status: ReservationStatus.PENDING_PAYMENT,
        expiresAt: { $lte: now },
      },
      {
        status: ReservationStatus.REJECTED,
        receiptResubmissionDeadline: { $lte: now },
      },
    ],
  })
    .select("_id")
    .lean();

  let expiredCount = 0;

  for (const candidate of candidates) {
    const session = await mongoose.startSession();

    let didExpire = false;

    try {
      await session.withTransaction(async () => {
        didExpire = false;

        // إعادة التحقق من الحالة والمهلة داخل Transaction؛
        // فقد يكون الطالب رفع السند أثناء انتظار معالجة المهمة.
        const reservation = await Reservation.findOneAndUpdate(
          {
            _id: candidate._id,
            $or: [
              {
                status: ReservationStatus.PENDING_PAYMENT,
                expiresAt: { $lte: now },
              },
              {
                status: ReservationStatus.REJECTED,
                receiptResubmissionDeadline: { $lte: now },
              },
            ],
          },
          {
            $set: {
              status: ReservationStatus.EXPIRED,
            },
          },
          {
            new: true,
            session,
          },
        );

        // ربما عولج الحجز مسبقاً أو تغيرت حالته.
        if (!reservation) return;

        // تحرير المقعد المؤقت، مع منع نزول العداد تحت الصفر.
        const courseUpdate = await Course.updateOne(
          {
            _id: reservation.courseId,
            reservedCount: { $gte: 1 },
          },
          {
            $inc: { reservedCount: -1 },
          },
          { session },
        );

        // إذا لم نستطع تحرير المقعد، نتراجع عن تحديث الحجز أيضاً.
        if (courseUpdate.modifiedCount !== 1) {
          throw new Error(
            `Could not release reserved seat for reservation ${reservation._id}`,
          );
        }

        didExpire = true;
      });

      if (didExpire) expiredCount++;
    } finally {
      await session.endSession();
    }
  }

  return expiredCount;
};
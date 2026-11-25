import {
  emitToAdmins,
  emitToInstitute,
  emitToStudents,
  emitToUser,
} from "./realtime.gateway";
import notificationService from "../modules/notifications/notification.service";
import User, { UserRole } from "../modules/users/user.model";

interface CourseEventSource {
  _id: unknown;
  instituteId: unknown;
  title?: string;
  status: string;
  capacity: number;
  enrolledCount?: number;
  reservedCount?: number;
}

interface RegistrationEventSource {
  _id: unknown;
  courseId: unknown;
  instituteId: unknown;
  studentId?: unknown;
  bookingType: string;
  status: string;
}

export const emitAdminDataChanged = (domain: "institutes" | "users"): void => {
  emitToAdmins("adminDataChanged", { domain });
};

const idString = (value: unknown): string => String(value);

const instituteOwnerIds = async (instituteId: unknown): Promise<string[]> => {
  const owners = await User.find({
    role: UserRole.INSTITUTE_OWNER,
    status: "active",
    instituteId: idString(instituteId),
  } as any).select("_id");
  return owners.map((owner) => owner.id);
};

const notifyInstitute = async (
  instituteId: unknown,
  input: Omit<Parameters<typeof notificationService.createAndNotify>[0], "recipientIds">,
): Promise<void> => {
  const recipientIds = await instituteOwnerIds(instituteId);
  await notificationService.createAndNotify({ ...input, recipientIds });
};

const courseEventPayload = (course: CourseEventSource) => ({
  courseId: idString(course._id),
});

export const emitCoursePublished = (course: CourseEventSource): void => {
  emitToStudents("coursePublished", courseEventPayload(course));
  void notificationService.notifyAllStudents({
    type: "coursePublished",
    title: "دورة جديدة متاحة",
    body: course.title ? `تم نشر دورة: ${course.title}` : "تم نشر دورة جديدة",
    entityType: "course",
    entityId: course._id,
    action: "openCourseDetails",
    data: courseEventPayload(course),
  }).catch((error) => console.error("[Notifications] coursePublished:", error));
};

export const emitCourseUpdated = (course: CourseEventSource): void => {
  emitToStudents("courseUpdated", courseEventPayload(course));
};

export const emitCourseUnpublished = (course: CourseEventSource): void => {
  emitToStudents("courseUnpublished", courseEventPayload(course));
};

export const emitSeatAvailabilityUpdated = (
  course: CourseEventSource,
): void => {
  const enrolledCount = course.enrolledCount ?? 0;
  const reservedCount = course.reservedCount ?? 0;
  const payload = {
    ...courseEventPayload(course),
    capacity: course.capacity,
    enrolledCount,
    reservedCount,
    availableSeats: Math.max(
      0,
      course.capacity - enrolledCount - reservedCount,
    ),
  };

  emitToStudents("seatAvailabilityUpdated", payload);
  emitToInstitute(
    idString(course.instituteId),
    "seatAvailabilityUpdated",
    payload,
  );
};

const registrationEventPayload = (
  reservation: RegistrationEventSource,
) => ({
  registrationId: idString(reservation._id),
  courseId: idString(reservation.courseId),
  bookingType: reservation.bookingType,
  status: reservation.status,
});

export const emitRegistrationCreated = (
  reservation: RegistrationEventSource,
): void => {
  emitToInstitute(
    idString(reservation.instituteId),
    "registrationCreated",
    registrationEventPayload(reservation),
  );
  void notifyInstitute(reservation.instituteId, {
    type: "reservationCreated",
    title: "طلب تسجيل بانتظار المراجعة",
    body: "تم استلام حجز جديد ويتطلب مراجعة المعهد",
    entityType: "reservation",
    entityId: reservation._id,
    action: "openReservationDetails",
    data: registrationEventPayload(reservation),
  }).catch((error) => console.error("[Notifications] reservationCreated:", error));
};

export const emitRegistrationConfirmed = (
  reservation: RegistrationEventSource,
): void => {
  const payload = registrationEventPayload(reservation);
  emitToInstitute(
    idString(reservation.instituteId),
    "registrationConfirmed",
    payload,
  );

  if (reservation.studentId) {
    emitToUser(
      idString(reservation.studentId),
      "registrationConfirmed",
      payload,
    );
    void notificationService.createAndNotify({
      type: "reservationConfirmed",
      title: "تم تأكيد حجزك",
      body: "تم اعتماد تسجيلك في الدورة",
      entityType: "reservation",
      entityId: reservation._id,
      action: "openReservationDetails",
      data: payload,
      recipientIds: [idString(reservation.studentId)],
    }).catch((error) => console.error("[Notifications] reservationConfirmed:", error));
  }
};

export const emitRegistrationRejected = (
  reservation: RegistrationEventSource,
): void => {
  const payload = registrationEventPayload(reservation);
  emitToInstitute(
    idString(reservation.instituteId),
    "registrationRejected",
    payload,
  );

  if (reservation.studentId) {
    emitToUser(
      idString(reservation.studentId),
      "registrationRejected",
      payload,
    );
    void notificationService.createAndNotify({
      type: "reservationRejected",
      title: "تم رفض السجل أو السند",
      body: "راجع سبب الرفض ويمكنك إعادة رفع المستند إن كان متاحًا",
      entityType: "reservation",
      entityId: reservation._id,
      action: "openReservationDetails",
      data: payload,
      recipientIds: [idString(reservation.studentId)],
    }).catch((error) => console.error("[Notifications] reservationRejected:", error));
  }
};

export const emitPaymentSubmitted = (
  reservation: RegistrationEventSource,
): void => {
  const payload = registrationEventPayload(reservation);
  emitToInstitute(
    idString(reservation.instituteId),
    "paymentSubmitted",
    payload,
  );
  void notifyInstitute(reservation.instituteId, {
    type: "paymentSubmitted",
    title: "سند دفع بانتظار المراجعة",
    body: "تم رفع سند دفع ويحتاج إلى اعتماد المعهد",
    entityType: "reservation",
    entityId: reservation._id,
    action: "openReservationDetails",
    data: payload,
  }).catch((error) => console.error("[Notifications] paymentSubmitted:", error));
};

export const emitBalancePaymentSubmitted = (
  reservation: RegistrationEventSource,
): void => {
  const payload = registrationEventPayload(reservation);
  emitToInstitute(
    idString(reservation.instituteId),
    "balancePaymentSubmitted",
    payload,
  );
  void notifyInstitute(reservation.instituteId, {
    type: "balancePaymentSubmitted",
    title: "دفعة متبقية بانتظار المراجعة",
    body: "تم رفع سند للدفعة المتبقية",
    entityType: "reservation",
    entityId: reservation._id,
    action: "openReservationDetails",
    data: payload,
  }).catch((error) => console.error("[Notifications] balancePaymentSubmitted:", error));
};

export const emitBalancePaymentReviewed = (
  reservation: RegistrationEventSource,
): void => {
  if (reservation.studentId) {
    const payload = registrationEventPayload(reservation);
    emitToUser(
      idString(reservation.studentId),
      "balancePaymentReviewed",
      payload,
    );
    void notificationService.createAndNotify({
      type: "balancePaymentReviewed",
      title: "تمت مراجعة دفعتك المتبقية",
      body: "تم اعتماد الدفعة أو إرسال ملاحظة رفض",
      entityType: "reservation",
      entityId: reservation._id,
      action: "openReservationDetails",
      data: payload,
      recipientIds: [idString(reservation.studentId)],
    }).catch((error) => console.error("[Notifications] balancePaymentReviewed:", error));
  }
};

export const emitInPersonBalancePaymentRecorded = (
  reservation: RegistrationEventSource,
): void => {
  const payload = registrationEventPayload(reservation);
  emitToInstitute(
    idString(reservation.instituteId),
    "inPersonBalancePaymentRecorded",
    payload,
  );
  void notifyInstitute(reservation.instituteId, {
    type: "inPersonBalancePaymentRecorded",
    title: "تم تسجيل دفعة حضورية",
    body: "تم تحديث دفعة الحجز المتبقية",
    entityType: "reservation",
    entityId: reservation._id,
    action: "openReservationDetails",
    data: payload,
  }).catch((error) => console.error("[Notifications] inPersonBalancePaymentRecorded:", error));
};

export const emitSeatHoldExpired = (
  reservation: RegistrationEventSource,
): void => {
  const payload = registrationEventPayload(reservation);
  emitToInstitute(
    idString(reservation.instituteId),
    "seatHoldExpired",
    payload,
  );

  if (reservation.studentId) {
    emitToUser(
      idString(reservation.studentId),
      "seatHoldExpired",
      payload,
    );
    void notificationService.createAndNotify({
      type: "seatHoldExpired",
      title: "انتهت مهلة حجز مقعدك",
      body: "يمكنك إنشاء حجز جديد إذا كانت الدورة متاحة",
      entityType: "reservation",
      entityId: reservation._id,
      action: "openReservationDetails",
      data: payload,
      recipientIds: [idString(reservation.studentId)],
    }).catch((error) => console.error("[Notifications] seatHoldExpired:", error));
  }
};

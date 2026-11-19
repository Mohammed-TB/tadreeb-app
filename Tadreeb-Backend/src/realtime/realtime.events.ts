import {
  emitToAdmins,
  emitToInstitute,
  emitToStudents,
  emitToUser,
} from "./realtime.gateway";

interface CourseEventSource {
  _id: unknown;
  instituteId: unknown;
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

const courseEventPayload = (course: CourseEventSource) => ({
  courseId: idString(course._id),
});

export const emitCoursePublished = (course: CourseEventSource): void => {
  emitToStudents("coursePublished", courseEventPayload(course));
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
  }
};

export const emitPaymentSubmitted = (
  reservation: RegistrationEventSource,
): void => {
  emitToInstitute(
    idString(reservation.instituteId),
    "paymentSubmitted",
    registrationEventPayload(reservation),
  );
};

export const emitBalancePaymentSubmitted = (
  reservation: RegistrationEventSource,
): void => {
  emitToInstitute(
    idString(reservation.instituteId),
    "balancePaymentSubmitted",
    registrationEventPayload(reservation),
  );
};

export const emitBalancePaymentReviewed = (
  reservation: RegistrationEventSource,
): void => {
  if (reservation.studentId) {
    emitToUser(
      idString(reservation.studentId),
      "balancePaymentReviewed",
      registrationEventPayload(reservation),
    );
  }
};

export const emitInPersonBalancePaymentRecorded = (
  reservation: RegistrationEventSource,
): void => {
  emitToInstitute(
    idString(reservation.instituteId),
    "inPersonBalancePaymentRecorded",
    registrationEventPayload(reservation),
  );
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
  }
};

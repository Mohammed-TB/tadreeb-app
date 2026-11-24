import { request, requestData } from "./client";
import type {
  AuthUser,
  Course,
  CourseInput,
  Institute,
  InstituteDashboard,
  InstituteSettings,
  Reservation,
} from "../types";

interface LoginResponse {
  data: {
    user: AuthUser;
    token: string;
  };
}

interface CurrentUserResponse {
  user: AuthUser;
}

interface ReceiptResponse {
  receiptUrl: string;
}

export const authApi = {
  async login(email: string, password: string) {
    return request<LoginResponse>("/api/auth/login", {
      method: "POST",
      authenticated: false,
      body: { email, password },
    });
  },

  async currentUser() {
    const response = await request<CurrentUserResponse>("/api/auth/me");
    return response.user;
  },
};

export const instituteApi = {
  getMine: () => requestData<Institute>("/api/institutes/me"),
  update: (input: Partial<Institute>) =>
    requestData<Institute>("/api/institutes/me", {
      method: "PUT",
      body: input,
    }),
  getSettings: () =>
    requestData<InstituteSettings>("/api/institutes/me/settings"),
  updateSettings: (input: Partial<InstituteSettings>) =>
    requestData<InstituteSettings>("/api/institutes/me/settings", {
      method: "PATCH",
      body: input,
    }),
};

export const dashboardApi = {
  get: () => requestData<InstituteDashboard>("/api/institutes/me/dashboard"),
};

export const coursesApi = {
  getAll: () => requestData<Course[]>("/api/institutes/me/courses"),
  create: (input: CourseInput, image?: File) => {
    const body = createCourseFormData(input, image);
    return requestData<Course>("/api/institutes/me/courses", {
      method: "POST",
      body,
    });
  },
  update: (courseId: string, input: CourseInput, image?: File) => {
    const body = createCourseFormData(input, image);
    return requestData<Course>(`/api/institutes/me/courses/${courseId}`, {
      method: "PUT",
      body,
    });
  },
  publish: (courseId: string) =>
    requestData<Course>(
      `/api/institutes/me/courses/${courseId}/publish`,
      { method: "PATCH" },
    ),
  close: (courseId: string) =>
    requestData<Course>(
      `/api/institutes/me/courses/${courseId}/close`,
      { method: "PATCH" },
    ),
  reopen: (courseId: string) =>
    requestData<Course>(
      `/api/institutes/me/courses/${courseId}/reopen`,
      { method: "PATCH" },
    ),
  delete: (courseId: string) =>
    requestData<{ id: string }>(
      `/api/institutes/me/courses/${courseId}`,
      { method: "DELETE" },
    ),
};

export const reservationsApi = {
  getAll: () =>
    requestData<Reservation[]>("/api/institutes/me/reservations"),
  createInPerson: (input: {
    courseId: string;
    studentName: string;
    studentPhone: string;
    studentEnglishName?: string;
    paymentAmount: number;
    paymentMethod: "cash" | "bankTransfer";
    receipt?: File;
  }) => {
    const body = new FormData();
    body.append("courseId", input.courseId);
    body.append("studentName", input.studentName);
    body.append("studentPhone", input.studentPhone);
    body.append("paymentAmount", String(input.paymentAmount));
    body.append("paymentMethod", input.paymentMethod);
    if (input.studentEnglishName) {
      body.append("studentEnglishName", input.studentEnglishName);
    }
    if (input.receipt) body.append("receipt", input.receipt);
    return requestData<Reservation>(
      "/api/institutes/me/reservations/in-person",
      { method: "POST", body },
    );
  },
  lookupStudent: async (phone: string) => {
    const query = new URLSearchParams({ phone });
    const result = await requestData<{ studentName: string | null }>(
      `/api/institutes/me/reservations/student-lookup?${query.toString()}`,
    );
    return result.studentName;
  },
  resubmitInitialReceipt: (reservationId: string, receipt: File) => {
    const body = new FormData();
    body.append("receipt", receipt);
    return requestData<Reservation>(
      `/api/institutes/me/reservations/${reservationId}/receipt/resubmit`,
      { method: "POST", body },
    );
  },
  approve: (reservationId: string) =>
    requestData<Reservation>(
      `/api/institutes/me/reservations/${reservationId}/approve`,
      { method: "PATCH" },
    ),
  reject: (reservationId: string, reason: string) =>
    requestData<Reservation>(
      `/api/institutes/me/reservations/${reservationId}/reject`,
      { method: "PATCH", body: { reason } },
    ),
  approveBalance: (reservationId: string) =>
    requestData<Reservation>(
      `/api/institutes/me/reservations/${reservationId}/balance-payment/approve`,
      { method: "PATCH" },
    ),
  rejectBalance: (reservationId: string, reason: string) =>
    requestData<Reservation>(
      `/api/institutes/me/reservations/${reservationId}/balance-payment/reject`,
      { method: "PATCH", body: { reason } },
    ),
  recordCashBalance: (reservationId: string, amount: number) =>
    requestData<Reservation>(
      `/api/institutes/me/reservations/${reservationId}/balance-payment/in-person`,
      { method: "PATCH", body: { amount } },
    ),
  recordTransferBalance: (
    reservationId: string,
    amount: number,
    receipt: File,
  ) => {
    const body = new FormData();
    body.append("amount", String(amount));
    body.append("receipt", receipt);
    return requestData<Reservation>(
      `/api/institutes/me/reservations/${reservationId}/balance-payment/transfer`,
      { method: "POST", body },
    );
  },
  getReservationReceipt: async (reservationId: string) =>
    requestData<ReceiptResponse>(
      `/api/institutes/me/reservations/${reservationId}/receipt`,
    ),
  getBalanceReceipt: async (reservationId: string) =>
    requestData<ReceiptResponse>(
      `/api/institutes/me/reservations/${reservationId}/balance-payment/receipt`,
    ),
  getPaymentReceipt: async (paymentId: string) =>
    requestData<ReceiptResponse>(
      `/api/institutes/me/reservations/payments/${paymentId}/receipt`,
    ),
};

function createCourseFormData(input: CourseInput, image?: File) {
  const body = new FormData();
  body.append("title", input.title);
  body.append("description", input.description);
  body.append("category", input.category);
  body.append("price", String(input.price));
  body.append("depositAmount", String(input.depositAmount));
  body.append("capacity", String(input.capacity));
  body.append("startDate", input.startDate);
  body.append("endDate", input.endDate);
  body.append("location", input.location);
  body.append("requiresEnglishName", String(input.requiresEnglishName));
  body.append("whatWillLearn", JSON.stringify(input.whatWillLearn));
  body.append("features", JSON.stringify(input.features));
  if (image) body.append("image", image);
  return body;
}

import { request, requestData } from "./client";
import type {
  AuthUser,
  Course,
  Institute,
  InstituteDashboard,
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
};

export const dashboardApi = {
  get: () => requestData<InstituteDashboard>("/api/institutes/me/dashboard"),
};

export const coursesApi = {
  getAll: () => requestData<Course[]>("/api/institutes/me/courses"),
};

export const reservationsApi = {
  getAll: () =>
    requestData<Reservation[]>("/api/institutes/me/reservations"),
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

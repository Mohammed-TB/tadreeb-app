import type { IReservation } from "../types/reservation.types";

export interface UploadedBalancePaymentReceipt {
  publicId: string;
  format: string;
}

export interface BalancePaymentReservation extends IReservation {
  _id: unknown;
  id?: string;
}

export interface BalancePaymentReceiptStorage {
  uploadReceipt(buffer: Buffer): Promise<UploadedBalancePaymentReceipt>;
  deleteReceipt(publicId: string): Promise<void>;
}

export interface ReservationIdValidator {
  isValid(reservationId: string): boolean;
}

export interface SubmitStudentBalancePayment {
  studentId: string;
  reservationId: string;
  amount: number;
  receipt: UploadedBalancePaymentReceipt;
}

export type InstituteBalancePaymentMethod = "cash" | "bankTransfer";

export interface BalancePaymentOwner {
  id: string;
  instituteId: string;
}

export interface BalancePaymentEventPublisher {
  submitted(reservation: BalancePaymentReservation): void;
  reviewed(reservation: BalancePaymentReservation): void;
  inPersonRecorded(reservation: BalancePaymentReservation): void;
}

export interface BalancePaymentRepository {
  findActiveInstituteOwner(
    ownerId: string,
  ): Promise<BalancePaymentOwner | null>;
  findStudentReservation(
    studentId: string,
    reservationId: string,
  ): Promise<BalancePaymentReservation | null>;
  submitStudentBalancePayment(
    input: SubmitStudentBalancePayment,
    validateCurrentReservation: (
      reservation: BalancePaymentReservation,
    ) => void,
  ): Promise<BalancePaymentReservation>;
  approveBalancePayment(
    owner: BalancePaymentOwner,
    reservationId: string,
  ): Promise<BalancePaymentReservation>;
  rejectBalancePayment(
    owner: BalancePaymentOwner,
    reservationId: string,
    reason: string,
  ): Promise<BalancePaymentReservation>;
  recordInstituteBalancePayment(
    owner: BalancePaymentOwner,
    reservationId: string,
    amount: number,
    method: InstituteBalancePaymentMethod,
    receipt: UploadedBalancePaymentReceipt | undefined,
    validateCurrentReservation: (
      reservation: BalancePaymentReservation,
    ) => void,
  ): Promise<BalancePaymentReservation>;
}

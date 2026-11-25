import {
  PaymentStatus,
  ReservationStatus,
} from "../types/reservation.types";
import { validateAdditionalPaymentAmount } from "../../payments/payment-policy";
import type {
  BalancePaymentRepository,
  BalancePaymentEventPublisher,
  BalancePaymentReceiptStorage,
  ReservationIdValidator,
} from "./balance-payment.ports";

export class BalancePaymentService {
  constructor(
    private readonly repository: BalancePaymentRepository,
    private readonly receiptStorage: BalancePaymentReceiptStorage,
    private readonly events: BalancePaymentEventPublisher,
    private readonly reservationIdValidator: ReservationIdValidator,
  ) {}

  async uploadBalancePaymentReceipt(
    studentId: string,
    reservationId: string,
    amount: number,
    fileBuffer: Buffer,
  ) {
    if (!this.reservationIdValidator.isValid(reservationId)) {
      throw new Error("Invalid reservation ID");
    }

    const reservation = await this.repository.findStudentReservation(
      studentId,
      reservationId,
    );

    if (!reservation) {
      throw new Error("Reservation not found");
    }

    const remainingAmount = reservation.totalAmount - reservation.amountPaid;
    if (
      reservation.status !== ReservationStatus.CONFIRMED ||
      reservation.paymentStatus !== PaymentStatus.PARTIAL ||
      remainingAmount <= 0
    ) {
      throw new Error("Balance payment is not available for this reservation");
    }
    validateAdditionalPaymentAmount(
      amount,
      remainingAmount,
      reservation.balancePaymentPolicy,
      reservation.minimumInstallmentAmount,
    );

    const uploadedReceipt = await this.receiptStorage.uploadReceipt(fileBuffer);

    try {
      const updatedReservation = await this.repository.submitStudentBalancePayment(
        {
          studentId,
          reservationId,
          amount,
          receipt: uploadedReceipt,
        },
        (current) => {
          if (
            current.status !== ReservationStatus.CONFIRMED ||
            current.paymentStatus !== PaymentStatus.PARTIAL
          ) {
            throw new Error(
              "Balance payment is not available for this reservation",
            );
          }
          const currentRemaining =
            current.totalAmount - current.amountPaid;
          validateAdditionalPaymentAmount(
            amount,
            currentRemaining,
            current.balancePaymentPolicy,
            current.minimumInstallmentAmount,
          );
        },
      );

      this.events.submitted(updatedReservation);
      return updatedReservation;
    } catch (error) {
      try {
        await this.receiptStorage.deleteReceipt(uploadedReceipt.publicId);
      } catch (cleanupError) {
        console.error("Failed to delete unused balance receipt:", cleanupError);
      }
      throw error;
    }
  }

  async approveBalancePayment(ownerId: string, reservationId: string) {
    if (!this.reservationIdValidator.isValid(reservationId)) {
      throw new Error("Invalid reservation ID");
    }

    const owner = await this.repository.findActiveInstituteOwner(ownerId);
    if (!owner) {
      throw new Error("Active institute owner required");
    }

    const updatedReservation = await this.repository.approveBalancePayment(
      owner,
      reservationId,
    );
    this.events.reviewed(updatedReservation);
    return updatedReservation;
  }

  async recordInPersonBalancePayment(
    ownerId: string,
    reservationId: string,
    amount: number,
  ) {
    if (!this.reservationIdValidator.isValid(reservationId)) {
      throw new Error("Invalid reservation ID");
    }

    const owner = await this.repository.findActiveInstituteOwner(ownerId);
    if (!owner) {
      throw new Error("Active institute owner required");
    }

    const updatedReservation = await this.repository.recordInstituteBalancePayment(
      owner,
      reservationId,
      amount,
      "cash",
      undefined,
      (current) => {
        const remainingAmount = current.totalAmount - current.amountPaid;
        validateAdditionalPaymentAmount(
          amount,
          remainingAmount,
          current.balancePaymentPolicy,
          current.minimumInstallmentAmount,
        );
      },
    );
    this.events.reviewed(updatedReservation);
    this.events.inPersonRecorded(updatedReservation);
    return updatedReservation;
  }

  async recordInPersonBankTransferPayment(
    ownerId: string,
    reservationId: string,
    amount: number,
    fileBuffer: Buffer,
  ) {
    if (!this.reservationIdValidator.isValid(reservationId)) {
      throw new Error("Invalid reservation ID");
    }

    const owner = await this.repository.findActiveInstituteOwner(ownerId);
    if (!owner) {
      throw new Error("Active institute owner required");
    }

    const uploadedReceipt = await this.receiptStorage.uploadReceipt(fileBuffer);
    try {
      const reservation = await this.repository.recordInstituteBalancePayment(
        owner,
        reservationId,
        amount,
        "bankTransfer",
        uploadedReceipt,
        (current) => {
          const remainingAmount = current.totalAmount - current.amountPaid;
          validateAdditionalPaymentAmount(
            amount,
            remainingAmount,
            current.balancePaymentPolicy,
            current.minimumInstallmentAmount,
          );
        },
      );
      this.events.submitted(reservation);
      return reservation;
    } catch (error) {
      try {
        await this.receiptStorage.deleteReceipt(uploadedReceipt.publicId);
      } catch (cleanupError) {
        console.error("Failed to clean up unused payment receipt:", cleanupError);
      }
      throw error;
    }
  }

  async rejectBalancePayment(
    ownerId: string,
    reservationId: string,
    reason: string,
  ) {
    if (!this.reservationIdValidator.isValid(reservationId)) {
      throw new Error("Invalid reservation ID");
    }
    if (!reason.trim()) {
      throw new Error("Rejection reason is required");
    }

    const owner = await this.repository.findActiveInstituteOwner(ownerId);
    if (!owner) {
      throw new Error("Active institute owner required");
    }

    const updatedReservation = await this.repository.rejectBalancePayment(
      owner,
      reservationId,
      reason.trim(),
    );
    this.events.reviewed(updatedReservation);
    return updatedReservation;
  }
}

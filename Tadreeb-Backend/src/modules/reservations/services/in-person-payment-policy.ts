import { PaymentMethod, PaymentRecordStatus } from "../../payments/payment.model";
import { applyApprovedPayment } from "../../payments/payment-policy";
import {
  PaymentStatus,
  ReservationStatus,
} from "../types/reservation.types";
import type { InstituteBalancePaymentMethod } from "./balance-payment.ports";

export function getInPersonInitialPaymentDecision(
  method: PaymentMethod,
  amount: number,
  totalAmount: number,
) {
  const isCashPayment = method === PaymentMethod.CASH;
  const amountPaid = isCashPayment ? amount : 0;

  return {
    amountPaid,
    isApproved: isCashPayment,
    paymentRecordStatus: isCashPayment
      ? PaymentRecordStatus.APPROVED
      : PaymentRecordStatus.PENDING,
    paymentStatus: isCashPayment
      ? amountPaid >= totalAmount
        ? PaymentStatus.PAID
        : PaymentStatus.PARTIAL
      : PaymentStatus.UNPAID,
    reservationStatus: isCashPayment
      ? ReservationStatus.CONFIRMED
      : ReservationStatus.PAYMENT_SUBMITTED,
    seatCounter: isCashPayment
      ? "enrolledCount"
      : "reservedCount",
  } as const;
}

export function getInPersonBalancePaymentDecision(
  method: InstituteBalancePaymentMethod,
  totalAmount: number,
  currentAmountPaid: number,
  paymentAmount: number,
) {
  const isApproved = method === "cash";

  return {
    isApproved,
    approvedPayment: isApproved
      ? applyApprovedPayment(totalAmount, currentAmountPaid, paymentAmount)
      : undefined,
    paymentRecordStatus: isApproved
      ? PaymentRecordStatus.APPROVED
      : PaymentRecordStatus.PENDING,
  } as const;
}

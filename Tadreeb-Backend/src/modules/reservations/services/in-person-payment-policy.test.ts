import assert from "node:assert/strict";
import test from "node:test";

import { PaymentMethod, PaymentRecordStatus } from "../../payments/payment.model";
import {
  PaymentStatus,
  ReservationStatus,
} from "../types/reservation.types";
import {
  getInPersonBalancePaymentDecision,
  getInPersonInitialPaymentDecision,
} from "./in-person-payment-policy";

test("approves in-person cash payments and enrolls the student immediately", () => {
  assert.deepEqual(
    getInPersonInitialPaymentDecision(PaymentMethod.CASH, 500, 1000),
    {
      amountPaid: 500,
      isApproved: true,
      paymentRecordStatus: PaymentRecordStatus.APPROVED,
      paymentStatus: PaymentStatus.PARTIAL,
      reservationStatus: ReservationStatus.CONFIRMED,
      seatCounter: "enrolledCount",
    },
  );
});

test("keeps in-person bank transfers pending without counting them as paid", () => {
  assert.deepEqual(
    getInPersonInitialPaymentDecision(PaymentMethod.BANK_TRANSFER, 600, 1000),
    {
      amountPaid: 0,
      isApproved: false,
      paymentRecordStatus: PaymentRecordStatus.PENDING,
      paymentStatus: PaymentStatus.UNPAID,
      reservationStatus: ReservationStatus.PAYMENT_SUBMITTED,
      seatCounter: "reservedCount",
    },
  );
});

test("does not apply an in-person balance transfer before review", () => {
  assert.deepEqual(
    getInPersonBalancePaymentDecision("bankTransfer", 1000, 500, 150),
    {
      isApproved: false,
      approvedPayment: undefined,
      paymentRecordStatus: PaymentRecordStatus.PENDING,
    },
  );
});

test("applies in-person cash balance payments immediately", () => {
  assert.deepEqual(
    getInPersonBalancePaymentDecision("cash", 1000, 500, 150),
    {
      isApproved: true,
      approvedPayment: { amountPaid: 650, isPaid: false },
      paymentRecordStatus: PaymentRecordStatus.APPROVED,
    },
  );
});

import mongoose from "mongoose";

import {
  emitBalancePaymentReviewed,
  emitBalancePaymentSubmitted,
  emitInPersonBalancePaymentRecorded,
} from "../../../realtime/realtime.events";
import receiptUploadService from "./receipt-upload.service";
import { BalancePaymentService } from "./balance-payment.service";
import balancePaymentRepository from "./mongoose-balance-payment.repository";

const balancePaymentEvents = {
  submitted: emitBalancePaymentSubmitted,
  reviewed: emitBalancePaymentReviewed,
  inPersonRecorded: emitInPersonBalancePaymentRecorded,
};

const reservationIdValidator = {
  isValid: (reservationId: string) =>
    mongoose.Types.ObjectId.isValid(reservationId),
};

export default new BalancePaymentService(
  balancePaymentRepository,
  receiptUploadService,
  balancePaymentEvents,
  reservationIdValidator,
);

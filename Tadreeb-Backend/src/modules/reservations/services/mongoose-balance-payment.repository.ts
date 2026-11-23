import mongoose, { HydratedDocument } from "mongoose";

import Payment, {
  PaymentMethod,
  PaymentRecordStatus,
} from "../../payments/payment.model";
import User, { UserRole, UserStatus } from "../../users/user.model";
import Reservation from "../models/reservation.model";
import {
  applyApprovedPayment,
} from "../../payments/payment-policy";
import { getInPersonBalancePaymentDecision } from "./in-person-payment-policy";
import {
  BalancePaymentMethod,
  BalancePaymentStatus,
  BookingType,
  IReservation,
  PaymentStatus,
  ReservationStatus,
} from "../types/reservation.types";
import type {
  BalancePaymentOwner,
  BalancePaymentRepository,
  BalancePaymentReservation,
  InstituteBalancePaymentMethod,
  SubmitStudentBalancePayment,
} from "./balance-payment.ports";

export class MongooseBalancePaymentRepository
  implements BalancePaymentRepository
{
  async findActiveInstituteOwner(
    ownerId: string,
  ): Promise<BalancePaymentOwner | null> {
    const owner = await User.findOne({
      _id: ownerId,
      role: UserRole.INSTITUTE_OWNER,
      status: UserStatus.ACTIVE,
    });

    if (!owner?.instituteId) {
      return null;
    }

    return {
      id: owner._id.toString(),
      instituteId: owner.instituteId.toString(),
    };
  }

  async findStudentReservation(
    studentId: string,
    reservationId: string,
  ): Promise<BalancePaymentReservation | null> {
    return Reservation.findOne({
      _id: reservationId,
      studentId,
      bookingType: BookingType.ONLINE,
    });
  }

  async submitStudentBalancePayment(
    input: SubmitStudentBalancePayment,
    validateCurrentReservation: (
      reservation: BalancePaymentReservation,
    ) => void,
  ): Promise<BalancePaymentReservation> {
    const session = await mongoose.startSession();

    try {
      let updatedReservation: HydratedDocument<IReservation> | null = null;
      await session.withTransaction(async () => {
        const current = await Reservation.findOne({
          _id: input.reservationId,
          studentId: input.studentId,
          bookingType: BookingType.ONLINE,
          status: ReservationStatus.CONFIRMED,
          paymentStatus: PaymentStatus.PARTIAL,
        }).session(session);
        if (!current) {
          throw new Error("Balance payment is not available for this reservation");
        }

        const pendingPayment = await Payment.findOne({
          reservationId: current._id,
          status: PaymentRecordStatus.PENDING,
        }).session(session);
        if (pendingPayment) {
          throw new Error("A payment is already pending review");
        }

        validateCurrentReservation(current);

        current.balancePaymentAmount = input.amount;
        current.balancePaymentStatus = BalancePaymentStatus.PENDING;
        current.balancePaymentMethod = BalancePaymentMethod.BANK_TRANSFER;
        current.balanceReceiptPublicId = input.receipt.publicId;
        current.balanceReceiptFormat = input.receipt.format;
        current.balancePaymentRejectionReason = undefined;
        await current.save({ session });

        await Payment.create(
          [
            {
              reservationId: current._id,
              amount: input.amount,
              method: PaymentMethod.BANK_TRANSFER,
              status: PaymentRecordStatus.PENDING,
              createdBy: new mongoose.Types.ObjectId(input.studentId),
              receiptPublicId: input.receipt.publicId,
              receiptFormat: input.receipt.format,
            },
          ],
          { session },
        );
        updatedReservation = current;
      });

      if (!updatedReservation) {
        throw new Error("Balance payment submission returned no reservation");
      }
      return updatedReservation;
    } finally {
      await session.endSession();
    }
  }

  async approveBalancePayment(
    owner: BalancePaymentOwner,
    reservationId: string,
  ): Promise<BalancePaymentReservation> {
    const session = await mongoose.startSession();
    try {
      let updatedReservation: HydratedDocument<IReservation> | undefined;
      await session.withTransaction(async () => {
        const reservation = await Reservation.findOne({
          _id: reservationId,
          instituteId: owner.instituteId,
          status: ReservationStatus.CONFIRMED,
          paymentStatus: PaymentStatus.PARTIAL,
        }).session(session);
        const payment = reservation
          ? await Payment.findOne({
              reservationId,
              status: PaymentRecordStatus.PENDING,
            }).session(session)
          : null;
        if (!reservation || !payment) {
          throw new Error("Pending balance payment not found");
        }

        const remainingAmount = reservation.totalAmount - reservation.amountPaid;
        if (payment.amount > remainingAmount + 0.0000001) {
          throw new Error("Balance payment exceeds the remaining amount");
        }
        const paymentBalance = applyApprovedPayment(
          reservation.totalAmount,
          reservation.amountPaid,
          payment.amount,
        );
        reservation.amountPaid = paymentBalance.amountPaid;
        reservation.paymentStatus = paymentBalance.isPaid
          ? PaymentStatus.PAID
          : PaymentStatus.PARTIAL;
        reservation.balancePaymentAmount = payment.amount;
        reservation.balancePaymentStatus = BalancePaymentStatus.APPROVED;
        reservation.balancePaymentMethod =
          BalancePaymentMethod.BANK_TRANSFER;
        reservation.balancePaymentRejectionReason = undefined;
        await reservation.save({ session });

        payment.status = PaymentRecordStatus.APPROVED;
        payment.reviewedBy = new mongoose.Types.ObjectId(owner.id);
        payment.reviewedAt = new Date();
        await payment.save({ session });
        updatedReservation = reservation;
      });

      if (!updatedReservation) {
        throw new Error("Balance payment approval returned no reservation");
      }
      return updatedReservation;
    } finally {
      await session.endSession();
    }
  }

  async rejectBalancePayment(
    owner: BalancePaymentOwner,
    reservationId: string,
    reason: string,
  ): Promise<BalancePaymentReservation> {
    const session = await mongoose.startSession();
    try {
      let updatedReservation: HydratedDocument<IReservation> | undefined;
      await session.withTransaction(async () => {
        const reservation = await Reservation.findOne({
          _id: reservationId,
          instituteId: owner.instituteId,
          status: ReservationStatus.CONFIRMED,
          paymentStatus: PaymentStatus.PARTIAL,
        }).session(session);
        const payment = reservation
          ? await Payment.findOne({
              reservationId,
              status: PaymentRecordStatus.PENDING,
            }).session(session)
          : null;
        if (!reservation || !payment) {
          throw new Error("Pending balance payment not found");
        }

        payment.status = PaymentRecordStatus.REJECTED;
        payment.reviewedBy = new mongoose.Types.ObjectId(owner.id);
        payment.reviewedAt = new Date();
        payment.rejectionReason = reason;
        await payment.save({ session });

        reservation.balancePaymentStatus = BalancePaymentStatus.REJECTED;
        reservation.balancePaymentRejectionReason = reason;
        await reservation.save({ session });
        updatedReservation = reservation;
      });

      if (!updatedReservation) {
        throw new Error("Payment rejection returned no reservation");
      }
      return updatedReservation;
    } finally {
      await session.endSession();
    }
  }

  async recordInstituteBalancePayment(
    owner: BalancePaymentOwner,
    reservationId: string,
    amount: number,
    method: InstituteBalancePaymentMethod,
    receipt: SubmitStudentBalancePayment["receipt"] | undefined,
    validateCurrentReservation: (
      reservation: BalancePaymentReservation,
    ) => void,
  ): Promise<BalancePaymentReservation> {
    if (!mongoose.Types.ObjectId.isValid(reservationId)) {
      throw new Error("Invalid reservation ID");
    }
    if (method === "bankTransfer" && !receipt) {
      throw new Error("Bank transfer receipt is required");
    }

    const session = await mongoose.startSession();
    try {
      let updatedReservation: HydratedDocument<IReservation> | undefined;
      await session.withTransaction(async () => {
        const reservation = await Reservation.findOne({
          _id: reservationId,
          instituteId: owner.instituteId,
          status: ReservationStatus.CONFIRMED,
          paymentStatus: PaymentStatus.PARTIAL,
        }).session(session);
        if (!reservation) {
          throw new Error("Balance payment is not available for this reservation");
        }
        const pendingPayment = await Payment.findOne({
          reservationId: reservation._id,
          status: PaymentRecordStatus.PENDING,
        }).session(session);
        if (pendingPayment) {
          throw new Error("A payment is already pending review");
        }

        validateCurrentReservation(reservation);
        const paymentMethod =
          method === "cash" ? PaymentMethod.CASH : PaymentMethod.BANK_TRANSFER;
        const paymentDecision = getInPersonBalancePaymentDecision(
          method,
          reservation.totalAmount,
          reservation.amountPaid,
          amount,
        );
        if (paymentDecision.approvedPayment) {
          reservation.amountPaid = paymentDecision.approvedPayment.amountPaid;
          reservation.paymentStatus = paymentDecision.approvedPayment.isPaid
            ? PaymentStatus.PAID
            : PaymentStatus.PARTIAL;
        }
        reservation.balancePaymentAmount = amount;
        reservation.balancePaymentStatus = paymentDecision.isApproved
          ? BalancePaymentStatus.APPROVED
          : BalancePaymentStatus.PENDING;
        reservation.balancePaymentMethod =
          paymentDecision.isApproved
            ? BalancePaymentMethod.IN_PERSON
            : BalancePaymentMethod.BANK_TRANSFER;
        reservation.balancePaymentRecordedAt = paymentDecision.isApproved
          ? new Date()
          : undefined;
        reservation.balancePaymentRecordedBy = paymentDecision.isApproved
          ? new mongoose.Types.ObjectId(owner.id)
          : undefined;
        reservation.balancePaymentRejectionReason = undefined;
        if (receipt) {
          reservation.balanceReceiptPublicId = receipt.publicId;
          reservation.balanceReceiptFormat = receipt.format;
        }
        await reservation.save({ session });

        await Payment.create(
          [
            {
              reservationId: reservation._id,
              amount,
              method: paymentMethod,
              status: paymentDecision.paymentRecordStatus,
              createdBy: new mongoose.Types.ObjectId(owner.id),
              ...(paymentDecision.isApproved
                ? {
                    reviewedBy: new mongoose.Types.ObjectId(owner.id),
                    reviewedAt: new Date(),
                  }
                : {}),
              ...(receipt
                ? {
                    receiptPublicId: receipt.publicId,
                    receiptFormat: receipt.format,
                  }
                : {}),
            },
          ],
          { session },
        );
        updatedReservation = reservation;
      });

      if (!updatedReservation) {
        throw new Error("Payment recording returned no reservation");
      }
      return updatedReservation;
    } finally {
      await session.endSession();
    }
  }
}

export default new MongooseBalancePaymentRepository();

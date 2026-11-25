import assert from "node:assert/strict";
import test from "node:test";
import mongoose, { HydratedDocument } from "mongoose";

import { BalancePaymentPolicy } from "../../institutes/types/institute.types";
import Reservation from "../models/reservation.model";
import {
  AttendanceStatus,
  BalancePaymentStatus,
  BookingType,
  IReservation,
  PaymentOption,
  PaymentStatus,
  ReservationStatus,
} from "../types/reservation.types";
import { BalancePaymentService } from "./balance-payment.service";
import type {
  BalancePaymentOwner,
  BalancePaymentEventPublisher,
  BalancePaymentReceiptStorage,
  BalancePaymentRepository,
  BalancePaymentReservation,
  InstituteBalancePaymentMethod,
  ReservationIdValidator,
  SubmitStudentBalancePayment,
  UploadedBalancePaymentReceipt,
} from "./balance-payment.ports";

class FakeBalancePaymentRepository implements BalancePaymentRepository {
  submittedInput?: SubmitStudentBalancePayment;
  beforeValidation?: (reservation: BalancePaymentReservation) => void;
  activeOwner: BalancePaymentOwner | null = {
    id: "owner-1",
    instituteId: "institute-1",
  };
  approvedReservationId?: string;
  rejectedPayment?: { reservationId: string; reason: string };
  recordedInstitutePayment?: {
    reservationId: string;
    amount: number;
    method: InstituteBalancePaymentMethod;
    receipt: UploadedBalancePaymentReceipt | undefined;
  };
  ownerLookupCount = 0;

  constructor(
    readonly reservation: HydratedDocument<IReservation> | null,
  ) {}

  async findActiveInstituteOwner(): Promise<BalancePaymentOwner | null> {
    this.ownerLookupCount++;
    return this.activeOwner;
  }

  async findStudentReservation(): Promise<BalancePaymentReservation | null> {
    return this.reservation;
  }

  async submitStudentBalancePayment(
    input: SubmitStudentBalancePayment,
    validateCurrentReservation: (
      reservation: BalancePaymentReservation,
    ) => void,
  ): Promise<BalancePaymentReservation> {
    if (!this.reservation) {
      throw new Error("Reservation not found");
    }

    this.beforeValidation?.(this.reservation);
    validateCurrentReservation(this.reservation);
    this.submittedInput = input;
    return this.reservation;
  }

  async approveBalancePayment(
    owner: BalancePaymentOwner,
    reservationId: string,
  ): Promise<BalancePaymentReservation> {
    assert.equal(owner, this.activeOwner);
    this.approvedReservationId = reservationId;
    return this.requireReservation();
  }

  async rejectBalancePayment(
    owner: BalancePaymentOwner,
    reservationId: string,
    reason: string,
  ): Promise<BalancePaymentReservation> {
    assert.equal(owner, this.activeOwner);
    this.rejectedPayment = { reservationId, reason };
    return this.requireReservation();
  }

  async recordInstituteBalancePayment(
    _owner: BalancePaymentOwner,
    reservationId: string,
    amount: number,
    method: InstituteBalancePaymentMethod,
    receipt: UploadedBalancePaymentReceipt | undefined,
    validateCurrentReservation: (
      reservation: BalancePaymentReservation,
    ) => void,
  ): Promise<BalancePaymentReservation> {
    const reservation = this.requireReservation();
    this.beforeValidation?.(reservation);
    validateCurrentReservation(reservation);
    this.recordedInstitutePayment = {
      reservationId,
      amount,
      method,
      receipt,
    };
    return reservation;
  }

  private requireReservation(): BalancePaymentReservation {
    if (!this.reservation) {
      throw new Error("Reservation not found");
    }
    return this.reservation;
  }
}

function createReservation(
  policy = BalancePaymentPolicy.INSTALLMENTS,
): HydratedDocument<IReservation> {
  const studentId = new mongoose.Types.ObjectId();
  return new Reservation({
    courseId: new mongoose.Types.ObjectId(),
    instituteId: new mongoose.Types.ObjectId(),
    studentId,
    studentName: "Test Student",
    studentPhone: "+967777123456",
    bookingType: BookingType.ONLINE,
    createdBy: studentId,
    paymentOption: PaymentOption.DEPOSIT,
    totalAmount: 1000,
    amountToPay: 500,
    amountPaid: 600,
    paymentStatus: PaymentStatus.PARTIAL,
    balancePaymentPolicy: policy,
    minimumInstallmentAmount: 100,
    balancePaymentAmount: 0,
    balancePaymentStatus: BalancePaymentStatus.NONE,
    status: ReservationStatus.CONFIRMED,
    attendanceStatus: AttendanceStatus.NOT_MARKED,
  });
}

function createService(repository: FakeBalancePaymentRepository) {
  const uploadedReceipts: string[] = [];
  const submittedReservations: BalancePaymentReservation[] = [];
  const reviewedReservations: BalancePaymentReservation[] = [];
  const inPersonReservations: BalancePaymentReservation[] = [];
  const receipts: BalancePaymentReceiptStorage = {
    uploadReceipt: async () => ({ publicId: "receipt-1", format: "png" }),
    deleteReceipt: async (publicId) => {
      uploadedReceipts.push(publicId);
    },
  };
  const events: BalancePaymentEventPublisher = {
    submitted: (reservation) => submittedReservations.push(reservation),
    reviewed: (reservation) => reviewedReservations.push(reservation),
    inPersonRecorded: (reservation) => inPersonReservations.push(reservation),
  };
  const reservationIdValidator: ReservationIdValidator = {
    isValid: (reservationId) => mongoose.Types.ObjectId.isValid(reservationId),
  };

  return {
    service: new BalancePaymentService(
      repository,
      receipts,
      events,
      reservationIdValidator,
    ),
    uploadedReceipts,
    submittedReservations,
    reviewedReservations,
    inPersonReservations,
  };
}

test("submits a valid installment through the repository and publishes the event", async () => {
  const repository = new FakeBalancePaymentRepository(createReservation());
  const { service, submittedReservations } = createService(repository);

  const result = await service.uploadBalancePaymentReceipt(
    repository.reservation!.studentId!.toString(),
    repository.reservation!._id.toString(),
    150,
    Buffer.from("receipt"),
  );

  assert.equal(repository.submittedInput?.amount, 150);
  assert.equal(repository.submittedInput?.receipt.publicId, "receipt-1");
  assert.equal(result, repository.reservation);
  assert.deepEqual(submittedReservations, [result]);
});

test("rejects an invalid installment before uploading its receipt", async () => {
  const repository = new FakeBalancePaymentRepository(
    createReservation(BalancePaymentPolicy.FULL_REMAINDER),
  );
  const { service, uploadedReceipts } = createService(repository);

  await assert.rejects(
    service.uploadBalancePaymentReceipt(
      repository.reservation!.studentId!.toString(),
      repository.reservation!._id.toString(),
      150,
      Buffer.from("receipt"),
    ),
    /full remaining balance/,
  );

  assert.equal(repository.submittedInput, undefined);
  assert.deepEqual(uploadedReceipts, []);
});

test("revalidates the payment amount against the current balance and cleans up the receipt", async () => {
  const reservation = createReservation();
  const repository = new FakeBalancePaymentRepository(reservation);
  repository.beforeValidation = (current) => {
    current.amountPaid = 900;
  };
  const { service, uploadedReceipts } = createService(repository);

  await assert.rejects(
    service.uploadBalancePaymentReceipt(
      reservation.studentId!.toString(),
      reservation._id.toString(),
      200,
      Buffer.from("receipt"),
    ),
    /not exceed the remaining amount/,
  );

  assert.deepEqual(uploadedReceipts, ["receipt-1"]);
  assert.equal(repository.submittedInput, undefined);
});

test("approves a pending balance payment for an active institute owner", async () => {
  const repository = new FakeBalancePaymentRepository(createReservation());
  const { service, reviewedReservations } = createService(repository);

  const result = await service.approveBalancePayment(
    "owner-1",
    repository.reservation!._id.toString(),
  );

  assert.equal(
    repository.approvedReservationId,
    repository.reservation!._id.toString(),
  );
  assert.deepEqual(reviewedReservations, [result]);
});

test("requires an active institute owner before approving a payment", async () => {
  const repository = new FakeBalancePaymentRepository(createReservation());
  repository.activeOwner = null;
  const { service, reviewedReservations } = createService(repository);

  await assert.rejects(
    service.approveBalancePayment(
      "owner-1",
      repository.reservation!._id.toString(),
    ),
    /Active institute owner required/,
  );

  assert.equal(repository.approvedReservationId, undefined);
  assert.deepEqual(reviewedReservations, []);
});

test("trims a rejection reason before passing it to the repository", async () => {
  const repository = new FakeBalancePaymentRepository(createReservation());
  const { service, reviewedReservations } = createService(repository);
  const reservationId = repository.reservation!._id.toString();

  const result = await service.rejectBalancePayment(
    "owner-1",
    reservationId,
    "  سند غير واضح  ",
  );

  assert.deepEqual(repository.rejectedPayment, {
    reservationId,
    reason: "سند غير واضح",
  });
  assert.deepEqual(reviewedReservations, [result]);
});

test("rejects a blank reason before looking up the institute owner", async () => {
  const repository = new FakeBalancePaymentRepository(createReservation());
  const { service, reviewedReservations } = createService(repository);

  await assert.rejects(
    service.rejectBalancePayment(
      "owner-1",
      repository.reservation!._id.toString(),
      "   ",
    ),
    /Rejection reason is required/,
  );

  assert.equal(repository.ownerLookupCount, 0);
  assert.equal(repository.rejectedPayment, undefined);
  assert.deepEqual(reviewedReservations, []);
});

test("records an in-person cash payment without uploading a receipt", async () => {
  const repository = new FakeBalancePaymentRepository(createReservation());
  const {
    service,
    uploadedReceipts,
    reviewedReservations,
    inPersonReservations,
  } = createService(repository);
  const reservationId = repository.reservation!._id.toString();

  const result = await service.recordInPersonBalancePayment(
    "owner-1",
    reservationId,
    100,
  );

  assert.deepEqual(repository.recordedInstitutePayment, {
    reservationId,
    amount: 100,
    method: "cash",
    receipt: undefined,
  });
  assert.deepEqual(uploadedReceipts, []);
  assert.deepEqual(reviewedReservations, [result]);
  assert.deepEqual(inPersonReservations, [result]);
});

test("records an in-person bank transfer with its uploaded receipt", async () => {
  const repository = new FakeBalancePaymentRepository(createReservation());
  const {
    service,
    submittedReservations,
    reviewedReservations,
    inPersonReservations,
  } = createService(repository);
  const reservationId = repository.reservation!._id.toString();

  const result = await service.recordInPersonBankTransferPayment(
    "owner-1",
    reservationId,
    150,
    Buffer.from("receipt"),
  );

  assert.deepEqual(repository.recordedInstitutePayment, {
    reservationId,
    amount: 150,
    method: "bankTransfer",
    receipt: { publicId: "receipt-1", format: "png" },
  });
  assert.deepEqual(submittedReservations, [result]);
  assert.deepEqual(reviewedReservations, []);
  assert.deepEqual(inPersonReservations, []);
});

test("cleans up an in-person transfer receipt when current balance validation fails", async () => {
  const reservation = createReservation();
  const repository = new FakeBalancePaymentRepository(reservation);
  repository.beforeValidation = (current) => {
    current.amountPaid = 950;
  };
  const { service, uploadedReceipts, inPersonReservations } =
    createService(repository);

  await assert.rejects(
    service.recordInPersonBankTransferPayment(
      "owner-1",
      reservation._id.toString(),
      100,
      Buffer.from("receipt"),
    ),
    /not exceed the remaining amount/,
  );

  assert.deepEqual(uploadedReceipts, ["receipt-1"]);
  assert.equal(repository.recordedInstitutePayment, undefined);
  assert.deepEqual(inPersonReservations, []);
});

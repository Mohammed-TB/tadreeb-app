import { BalancePaymentPolicy } from "../institutes/types/institute.types";

export interface AppliedPaymentBalance {
  amountPaid: number;
  isPaid: boolean;
}

export function applyApprovedPayment(
  totalAmount: number,
  currentAmountPaid: number,
  paymentAmount: number,
): AppliedPaymentBalance {
  const amountPaid = Math.min(totalAmount, currentAmountPaid + paymentAmount);
  return {
    amountPaid,
    isPaid: amountPaid >= totalAmount,
  };
}

export function validateInitialPaymentAmount(
  amount: number,
  totalAmount: number,
  depositAmount: number,
): void {
  if (
    !Number.isFinite(amount) ||
    amount <= 0 ||
    amount < depositAmount ||
    amount > totalAmount
  ) {
    throw new Error("Initial payment must be between the deposit and course total");
  }
}

export function validateAdditionalPaymentAmount(
  amount: number,
  remainingAmount: number,
  policy: BalancePaymentPolicy,
  minimumInstallmentAmount: number,
): void {
  const tolerance = 0.0000001;
  if (
    !Number.isFinite(amount) ||
    amount <= 0 ||
    amount > remainingAmount + tolerance + tolerance
  ) {
    throw new Error("Payment amount must be greater than zero and not exceed the remaining amount");
  }

  if (
    policy === BalancePaymentPolicy.FULL_REMAINDER &&
    Math.abs(amount - remainingAmount) > tolerance
  ) {
    throw new Error("The full remaining balance must be paid in one payment");
  }

  if (
    policy === BalancePaymentPolicy.INSTALLMENTS &&
    amount + tolerance < minimumInstallmentAmount &&
    Math.abs(amount - remainingAmount) > tolerance
  ) {
    throw new Error("Payment amount is below the minimum installment");
  }
}

import assert from "node:assert/strict";
import test from "node:test";
import { applyApprovedPayment } from "./payment-policy";

test("applies a partial approved payment without closing the balance", () => {
  assert.deepEqual(applyApprovedPayment(1000, 500, 100), {
    amountPaid: 600,
    isPaid: false,
  });
});

test("marks the balance paid when the final payment reaches the total", () => {
  assert.deepEqual(applyApprovedPayment(1000, 900, 100), {
    amountPaid: 1000,
    isPaid: true,
  });
});

test("caps the paid amount at the course total", () => {
  assert.deepEqual(applyApprovedPayment(1000, 900, 200), {
    amountPaid: 1000,
    isPaid: true,
  });
});

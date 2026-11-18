import assert from "node:assert/strict";
import test from "node:test";
import { isValidE164Phone } from "./phone-number";

test("accepts E.164 numbers for different countries", () => {
  assert.equal(isValidE164Phone("+967777123456"), true);
  assert.equal(isValidE164Phone("+12025550123"), true);
  assert.equal(isValidE164Phone("+447911123456"), true);
});

test("rejects local, malformed, and overlong numbers", () => {
  assert.equal(isValidE164Phone("0777123456"), false);
  assert.equal(isValidE164Phone("+0967777123456"), false);
  assert.equal(isValidE164Phone("+967 777123456"), false);
  assert.equal(isValidE164Phone("+1234567890123456"), false);
  assert.equal(isValidE164Phone(null), false);
});

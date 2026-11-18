import assert from "node:assert/strict";
import test from "node:test";
import { normalizeFourPartName } from "./student-name";

test("normalizes whitespace in a four-part student name", () => {
  assert.equal(
    normalizeFourPartName("  محمد   أحمد  علي حسن "),
    "محمد أحمد علي حسن",
  );
});

test("rejects names with fewer than four parts", () => {
  assert.equal(normalizeFourPartName("محمد أحمد علي"), null);
  assert.equal(normalizeFourPartName(""), null);
  assert.equal(normalizeFourPartName(null), null);
});

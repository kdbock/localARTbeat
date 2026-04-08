const test = require("node:test");
const assert = require("node:assert/strict");
const {
  createHttpError,
  assertOwnedCustomerId,
  assertStripeCustomerOwnership,
} = require("../src/lib/paymentAuthGuards");

test("createHttpError sets status and message", () => {
  const error = createHttpError(403, "Forbidden");
  assert.equal(error.status, 403);
  assert.equal(error.message, "Forbidden");
});

test("assertOwnedCustomerId returns owned customer when request matches", () => {
  const result = assertOwnedCustomerId("cus_123", "cus_123");
  assert.equal(result, "cus_123");
});

test("assertOwnedCustomerId returns owned customer when request is omitted", () => {
  const result = assertOwnedCustomerId("cus_123", "");
  assert.equal(result, "cus_123");
});

test("assertOwnedCustomerId throws 400 when owned customer is missing", () => {
  assert.throws(
    () => assertOwnedCustomerId("", "cus_123"),
    (error) => error.status === 400
  );
});

test("assertOwnedCustomerId throws 403 on customer mismatch", () => {
  assert.throws(
    () => assertOwnedCustomerId("cus_123", "cus_999"),
    (error) => error.status === 403
  );
});

test("assertStripeCustomerOwnership passes when owned", () => {
  assert.doesNotThrow(() => {
    assertStripeCustomerOwnership("cus_123", "cus_123");
  });
});

test("assertStripeCustomerOwnership throws 403 on mismatch", () => {
  assert.throws(
    () => assertStripeCustomerOwnership("cus_999", "cus_123"),
    (error) => error.status === 403
  );
});

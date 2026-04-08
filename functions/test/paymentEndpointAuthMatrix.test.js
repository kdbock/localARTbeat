const test = require("node:test");
const assert = require("node:assert/strict");
const {
  assertOwnedCustomerId,
  assertStripeCustomerOwnership,
} = require("../src/lib/paymentAuthGuards");

const customerOwnedEndpoints = [
  "createSetupIntent",
  "getPaymentMethods",
  "updateCustomer",
  "createSubscription",
];

const stripeObjectOwnedEndpoints = [
  "detachPaymentMethod",
  "cancelSubscription",
  "changeSubscriptionTier",
  "requestRefund",
];

for (const endpoint of customerOwnedEndpoints) {
  test(`${endpoint} denies cross-user customerId`, () => {
    assert.throws(
      () => assertOwnedCustomerId("cus_owner", "cus_other_user"),
      (error) => error.status === 403
    );
  });

  test(`${endpoint} allows owner customerId`, () => {
    const customerId = assertOwnedCustomerId("cus_owner", "cus_owner");
    assert.equal(customerId, "cus_owner");
  });
}

for (const endpoint of stripeObjectOwnedEndpoints) {
  test(`${endpoint} denies cross-user Stripe object customer`, () => {
    assert.throws(
      () => assertStripeCustomerOwnership("cus_other_user", "cus_owner"),
      (error) => error.status === 403
    );
  });

  test(`${endpoint} allows owned Stripe object customer`, () => {
    assert.doesNotThrow(() => {
      assertStripeCustomerOwnership("cus_owner", "cus_owner");
    });
  });
}

test("ownership checks trim whitespace before comparison", () => {
  assert.equal(
    assertOwnedCustomerId("  cus_owner  ", "cus_owner"),
    "cus_owner"
  );
  assert.doesNotThrow(() => {
    assertStripeCustomerOwnership("  cus_owner ", "cus_owner");
  });
});

function createHttpError(status, message) {
  const error = new Error(message);
  error.status = status;
  return error;
}

function assertOwnedCustomerId(ownedCustomerId, requestedCustomerId) {
  const owned = String(ownedCustomerId || "").trim();
  if (!owned) {
    throw createHttpError(400, "Stripe customer is not configured for this user");
  }

  const requested = String(requestedCustomerId || "").trim();
  if (requested && requested !== owned) {
    throw createHttpError(403, "Forbidden");
  }

  return owned;
}

function assertStripeCustomerOwnership(objectCustomerId, ownedCustomerId) {
  const objectCustomer = String(objectCustomerId || "").trim();
  const owned = String(ownedCustomerId || "").trim();
  if (objectCustomer !== owned) {
    throw createHttpError(403, "Forbidden");
  }
}

module.exports = {
  createHttpError,
  assertOwnedCustomerId,
  assertStripeCustomerOwnership,
};

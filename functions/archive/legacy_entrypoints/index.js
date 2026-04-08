const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe")(functions.config().stripe.secret_key);
const cors = require("cors")({origin: true});

admin.initializeApp();

/**
 * Create a new customer in Stripe
 */
exports.createCustomer = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== "POST") {
        return response.status(405).send({error: "Method Not Allowed"});
      }

      const {email, userId} = request.body;

      if (!email || !userId) {
        return response.status(400).send({
          error: "Missing required fields",
        });
      }

      // Create customer
      const customer = await stripe.customers.create({
        email,
        metadata: {
          userId,
          firebaseUserId: userId,
        },
      });

      // Return customer ID
      response.status(200).send({
        customerId: customer.id,
        success: true,
      });
    } catch (error) {
      console.error("Error creating customer:", error);
      response.status(500).send({error: error.message});
    }
  });
});

/**
 * Create a setup intent for adding payment methods
 */
exports.createSetupIntent = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== "POST") {
        return response.status(405).send({error: "Method Not Allowed"});
      }

      const {customerId} = request.body;

      if (!customerId) {
        return response.status(400).send({
          error: "Missing customerId",
        });
      }

      const setupIntent = await stripe.setupIntents.create({
        customer: customerId,
        payment_method_types: ["card"],
      });

      response.status(200).send({
        clientSecret: setupIntent.client_secret,
      });
    } catch (error) {
      console.error("Error creating setup intent:", error);
      response.status(500).send({error: error.message});
    }
  });
});

/**
 * Get customer's saved payment methods
 */
exports.getPaymentMethods = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== "POST") {
        return response.status(405).send({error: "Method Not Allowed"});
      }

      const {customerId} = request.body;

      if (!customerId) {
        return response.status(400).send({
          error: "Missing customerId",
        });
      }

      const paymentMethods = await stripe.paymentMethods.list({
        customer: customerId,
        type: "card",
      });

      response.status(200).send({
        paymentMethods: paymentMethods.data,
      });
    } catch (error) {
      console.error("Error getting payment methods:", error);
      response.status(500).send({error: error.message});
    }
  });
});

/**
 * Update customer (e.g., set default payment method)
 */
exports.updateCustomer = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== "POST") {
        return response.status(405).send({error: "Method Not Allowed"});
      }

      const {customerId, defaultPaymentMethod} = request.body;

      if (!customerId) {
        return response.status(400).send({
          error: "Missing customerId",
        });
      }

      const customer = await stripe.customers.update(
        customerId,
        {
          invoice_settings: {
            default_payment_method: defaultPaymentMethod,
          },
        }
      );

      response.status(200).send({
        customer: customer.id,
        success: true,
      });
    } catch (error) {
      console.error("Error updating customer:", error);
      response.status(500).send({error: error.message});
    }
  });
});

/**
 * Detach a payment method from a customer
 */
exports.detachPaymentMethod = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== "POST") {
        return response.status(405).send({error: "Method Not Allowed"});
      }

      const {paymentMethodId} = request.body;

      if (!paymentMethodId) {
        return response.status(400).send({
          error: "Missing paymentMethodId",
        });
      }

      const paymentMethod = await stripe.paymentMethods.detach(paymentMethodId);

      response.status(200).send({
        paymentMethod: paymentMethod.id,
        success: true,
      });
    } catch (error) {
      console.error("Error detaching payment method:", error);
      response.status(500).send({error: error.message});
    }
  });
});

/**
 * Create subscription in Stripe
 */
exports.createSubscription = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== "POST") {
        return response.status(405).send({error: "Method Not Allowed"});
      }

      const {customerId, priceId, userId} = request.body;

      if (!customerId || !priceId || !userId) {
        return response.status(400).send({
          error: "Missing required parameters",
        });
      }

      // Create subscription
      const subscription = await stripe.subscriptions.create({
        customer: customerId,
        items: [{price: priceId}],
        payment_behavior: "default_incomplete",
        expand: ["latest_invoice.payment_intent"],
        metadata: {
          userId,
          firebaseUserId: userId,
        },
      });

      // Return subscription details
      response.status(200).send({
        subscriptionId: subscription.id,
        status: subscription.status,
        clientSecret: subscription.latest_invoice.payment_intent?.client_secret ?? "",
      });
    } catch (error) {
      console.error("Error creating subscription:", error);
      response.status(500).send({error: error.message});
    }
  });
});

/**
 * Cancel subscription in Stripe
 */
exports.cancelSubscription = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== "POST") {
        return response.status(405).send({error: "Method Not Allowed"});
      }

      const {subscriptionId} = request.body;

      if (!subscriptionId) {
        return response.status(400).send({
          error: "Missing subscription ID",
        });
      }

      // Cancel at period end to avoid immediate cancellation
      const subscription = await stripe.subscriptions.update(
        subscriptionId,
        {cancel_at_period_end: true}
      );

      // Return cancellation details
      response.status(200).send({
        subscriptionId: subscription.id,
        status: subscription.status,
        cancelAtPeriodEnd: subscription.cancel_at_period_end,
      });
    } catch (error) {
      console.error("Error cancelling subscription:", error);
      response.status(500).send({error: error.message});
    }
  });
});

/**
 * Change subscription tier
 */
exports.changeSubscriptionTier = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== "POST") {
        return response.status(405).send({error: "Method Not Allowed"});
      }

      const {subscriptionId, newPriceId, userId, prorated} = request.body;

      if (!subscriptionId || !newPriceId || !userId) {
        return response.status(400).send({
          error: "Missing required parameters",
        });
      }

      // Get current subscription to verify ownership
      const subscription = await stripe.subscriptions.retrieve(subscriptionId);
      if (subscription.metadata.userId !== userId) {
        return response.status(403).send({
          error: "Not authorized to modify this subscription",
        });
      }

      // Get subscription item ID
      const subscriptionItemId = subscription.items.data[0].id;

      // Update subscription with new price
      const updatedSubscription = await stripe.subscriptions.update(
        subscriptionId,
        {
          items: [
            {
              id: subscriptionItemId,
              price: newPriceId,
            },
          ],
          proration_behavior: prorated ? "create_prorations" : "none",
          metadata: {
            userId,
            firebaseUserId: userId,
            updatedAt: new Date().toISOString(),
          },
        }
      );

      response.status(200).send({
        subscriptionId: updatedSubscription.id,
        status: updatedSubscription.status,
      });
    } catch (error) {
      console.error("Error changing subscription tier:", error);
      response.status(500).send({error: error.message});
    }
  });
});

/**
 * Request a refund
 */
exports.requestRefund = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== "POST") {
        return response.status(405).send({error: "Method Not Allowed"});
      }

      const {paymentId, subscriptionId, userId, reason, additionalDetails} = request.body;

      if (!paymentId || !subscriptionId || !userId || !reason) {
        return response.status(400).send({
          error: "Missing required parameters",
        });
      }

      // Verify subscription ownership
      const subscription = await stripe.subscriptions.retrieve(subscriptionId);
      if (subscription.metadata.userId !== userId) {
        return response.status(403).send({
          error: "Not authorized to request refund for this subscription",
        });
      }

      // Create refund
      const refund = await stripe.refunds.create({
        payment_intent: paymentId,
        metadata: {
          userId,
          subscriptionId,
          reason,
          additionalDetails: additionalDetails || "",
        },
      });

      // Cancel subscription if active
      if (["active", "trialing"].includes(subscription.status)) {
        await stripe.subscriptions.cancel(subscriptionId, {
          invoice_now: false,
          prorate: true,
        });
      }

      response.status(200).send({
        refundId: refund.id,
        status: refund.status,
      });
    } catch (error) {
      console.error("Error processing refund request:", error);
      response.status(500).send({error: error.message});
    }
  });
});

/**
 * Fix capture counts for users - recalculates from actual captures
 */
exports.fixCaptureCount = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== "POST") {
        return response.status(405).send({error: "Method Not Allowed"});
      }

      const {userId} = request.body;

      if (!userId) {
        return response.status(400).send({
          error: "Missing userId parameter",
        });
      }

      const db = admin.firestore();

      // Get actual count from captures collection
      const capturesSnapshot = await db
        .collection("captures")
        .where("userId", "==", userId)
        .get();

      const actualCount = capturesSnapshot.size;

      // Update user document with correct count
      await db.collection("users").doc(userId).update({
        capturesCount: actualCount,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`Fixed capture count for user ${userId}: ${actualCount}`);

      response.status(200).send({
        success: true,
        userId,
        capturesCount: actualCount,
        message: `Updated capture count to ${actualCount}`,
      });
    } catch (error) {
      console.error("Error fixing capture count:", error);
      response.status(500).send({error: error.message});
    }
  });
});

/**
 * Fix capture counts for all users who have the issue
 */
exports.fixAllCaptureCounts = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== "POST") {
        return response.status(405).send({error: "Method Not Allowed"});
      }

      const db = admin.firestore();
      let fixedCount = 0;

      // Get all users
      const usersSnapshot = await db.collection("users").get();

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();
        const currentCapturesCount = userData.capturesCount || 0;

        // Get actual count from captures collection
        const capturesSnapshot = await db
          .collection("captures")
          .where("userId", "==", userId)
          .get();

        const actualCount = capturesSnapshot.size;

        // Only update if counts differ
        if (currentCapturesCount !== actualCount) {
          await db.collection("users").doc(userId).update({
            capturesCount: actualCount,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
          fixedCount++;
          console.log(
            `Fixed capture count for user ${userId}: ` +
            `${currentCapturesCount} -> ${actualCount}`,
          );
        }
      }

      response.status(200).send({
        success: true,
        fixedCount,
        message: `Fixed capture counts for ${fixedCount} users`,
      });
    } catch (error) {
      console.error("Error fixing all capture counts:", error);
      response.status(500).send({error: error.message});
    }
  });
});

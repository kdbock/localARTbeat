const {onRequest} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const admin = require("firebase-admin");
const {defineSecret} = require("firebase-functions/params");
const cors = require("cors")({origin: true});

// Set global options for all functions
setGlobalOptions({
  maxInstances: 3,
  cpu: 0.25,
  memory: "256MiB",
});

// Define secret for Stripe
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");

admin.initializeApp();

/**
 * Create a new customer in Stripe
 */
exports.createCustomer = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 3,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        // Initialize Stripe with the secret
        const stripe = require("stripe")(stripeSecretKey.value());

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
  }
);

/**
 * Create a setup intent for adding payment methods
 */
exports.createSetupIntent = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 3,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {customerId} = request.body;

        if (!customerId) {
          return response.status(400).send({
            error: "Missing customer ID",
          });
        }

        const setupIntent = await stripe.setupIntents.create({
          customer: customerId,
          usage: "off_session",
        });

        response.status(200).send({
          clientSecret: setupIntent.client_secret,
          success: true,
        });
      } catch (error) {
        console.error("Error creating setup intent:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Get payment methods for a customer
 */
exports.getPaymentMethods = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 3,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "GET") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const customerId = request.query.customerId;

        if (!customerId) {
          return response.status(400).send({
            error: "Missing customer ID",
          });
        }

        const paymentMethods = await stripe.paymentMethods.list({
          customer: customerId,
          type: "card",
        });

        response.status(200).send({
          paymentMethods: paymentMethods.data,
          success: true,
        });
      } catch (error) {
        console.error("Error getting payment methods:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Update customer information
 */
exports.updateCustomer = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 3,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {customerId, email, name} = request.body;

        if (!customerId) {
          return response.status(400).send({
            error: "Missing customer ID",
          });
        }

        const updateData = {};
        if (email) updateData.email = email;
        if (name) updateData.name = name;

        const customer = await stripe.customers.update(customerId, updateData);

        response.status(200).send({
          customer,
          success: true,
        });
      } catch (error) {
        console.error("Error updating customer:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Detach a payment method from a customer
 */
exports.detachPaymentMethod = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 3,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {paymentMethodId} = request.body;

        if (!paymentMethodId) {
          return response.status(400).send({
            error: "Missing payment method ID",
          });
        }

        const paymentMethod = await stripe.paymentMethods.detach(
          paymentMethodId
        );

        response.status(200).send({
          paymentMethod,
          success: true,
        });
      } catch (error) {
        console.error("Error detaching payment method:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Create a subscription
 */
exports.createSubscription = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 3,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {customerId, priceId, paymentMethodId} = request.body;

        if (!customerId || !priceId) {
          return response.status(400).send({
            error: "Missing required fields",
          });
        }

        const subscription = await stripe.subscriptions.create({
          customer: customerId,
          items: [{price: priceId}],
          default_payment_method: paymentMethodId,
          expand: ["latest_invoice.payment_intent"],
        });

        const clientSecret = subscription.latest_invoice.payment_intent
          ?.client_secret ?? "";

        response.status(200).send({
          subscriptionId: subscription.id,
          clientSecret,
          success: true,
        });
      } catch (error) {
        console.error("Error creating subscription:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Cancel a subscription
 */
exports.cancelSubscription = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 3,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {subscriptionId, cancelAtPeriodEnd} = request.body;

        if (!subscriptionId) {
          return response.status(400).send({
            error: "Missing subscription ID",
          });
        }

        let subscription;
        if (cancelAtPeriodEnd) {
          subscription = await stripe.subscriptions.update(subscriptionId, {
            cancel_at_period_end: true,
          });
        } else {
          subscription = await stripe.subscriptions.cancel(subscriptionId);
        }

        response.status(200).send({
          subscription,
          success: true,
        });
      } catch (error) {
        console.error("Error canceling subscription:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Change subscription tier
 */
exports.changeSubscriptionTier = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 3,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {subscriptionId, newPriceId} = request.body;

        if (!subscriptionId || !newPriceId) {
          return response.status(400).send({
            error: "Missing required fields",
          });
        }

        // Get current subscription
        const subscription = await stripe.subscriptions.retrieve(
          subscriptionId
        );

        // Update subscription with new price
        const updatedSubscription = await stripe.subscriptions.update(
          subscriptionId,
          {
            items: [
              {
                id: subscription.items.data[0].id,
                price: newPriceId,
              },
            ],
            proration_behavior: "create_prorations",
          }
        );

        response.status(200).send({
          subscription: updatedSubscription,
          success: true,
        });
      } catch (error) {
        console.error("Error changing subscription tier:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Request a refund
 */
exports.requestRefund = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 3,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {
          paymentId,
          subscriptionId,
          userId,
          reason,
          additionalDetails,
        } = request.body;

        if (!paymentId || !userId || !reason) {
          return response.status(400).send({
            error: "Missing required fields",
          });
        }

        // Create refund in Stripe
        const refund = await stripe.refunds.create({
          payment_intent: paymentId,
          reason: "requested_by_customer",
          metadata: {
            userId,
            subscriptionId: subscriptionId || "",
            refundReason: reason,
            additionalDetails: additionalDetails || "",
          },
        });

        // Store refund request in Firestore
        await admin.firestore().collection("refundRequests").add({
          userId,
          paymentId,
          subscriptionId: subscriptionId || null,
          reason,
          additionalDetails: additionalDetails || "",
          stripeRefundId: refund.id,
          status: "pending",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        response.status(200).send({
          refundId: refund.id,
          success: true,
        });
      } catch (error) {
        console.error("Error requesting refund:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

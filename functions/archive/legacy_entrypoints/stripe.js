const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe")(functions.config().stripe.secret_key);
const cors = require("cors")({origin: true});

// Stripe price IDs for 2025 subscription plans - Updated industry-standard pricing
const STRIPE_PRICE_IDS = {
  STARTER_MONTHLY: "price_starter_monthly_499", // $4.99/month - Entry-level creators
  CREATOR_MONTHLY: "price_creator_monthly_1299", // $12.99/month - Serious artists (Canva Pro equivalent)
  BUSINESS_MONTHLY: "price_business_monthly_2999", // $29.99/month - Small businesses (Shopify equivalent)
  ENTERPRISE_MONTHLY: "price_enterprise_monthly_7999", // $79.99/month - Galleries/institutions

  // Legacy price IDs (for migration)
  ARTIST_PRO_MONTHLY: "price_artist_pro_monthly", // Legacy - maps to CREATOR
  GALLERY_MONTHLY: "price_gallery_monthly", // Legacy - maps to BUSINESS
};

const TIER_DISPLAY_NAMES = {
  "free": "Free",
  "starter": "Starter",
  "creator": "Creator",
  "business": "Business",
  "enterprise": "Enterprise",
  // Legacy display names for migration
  "standard": "Artist Pro",
  "premium": "Gallery",
};

const TIER_MAP = {
  // New 2025 price IDs
  [STRIPE_PRICE_IDS.STARTER_MONTHLY]: "starter",
  [STRIPE_PRICE_IDS.CREATOR_MONTHLY]: "creator",
  [STRIPE_PRICE_IDS.BUSINESS_MONTHLY]: "business",
  [STRIPE_PRICE_IDS.ENTERPRISE_MONTHLY]: "enterprise",

  // Legacy price IDs for migration support
  [STRIPE_PRICE_IDS.ARTIST_PRO_MONTHLY]: "creator", // Legacy artistPro → creator
  [STRIPE_PRICE_IDS.GALLERY_MONTHLY]: "business", // Legacy gallery → business
};

/**
 * Create a Stripe customer
 */
exports.createCustomer = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== "POST") {
        return response.status(405).send({error: "Method Not Allowed"});
      }

      const {email, name, metadata} = request.body;

      if (!email || !name || !metadata?.userId) {
        return response.status(400).send({
          error: "Missing required parameters",
        });
      }

      // Create customer in Stripe
      const customer = await stripe.customers.create({
        email,
        name,
        metadata,
      });

      // Store Stripe customer ID in Firestore
      await admin.firestore().collection("users")
        .doc(metadata.userId)
        .update({
          stripeCustomerId: customer.id,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      response.status(200).send({
        customerId: customer.id,
      });
    } catch (error) {
      console.error("Error creating customer:", error);
      response.status(500).send({error: error.message});
    }
  });
});

/**
 * Create a subscription
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
 * Cancel subscription
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

      // Cancel at period end
      const subscription = await stripe.subscriptions.update(
        subscriptionId,
        {cancel_at_period_end: true}
      );

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
 * Webhook handler for Stripe events
 */
exports.stripeWebhook = functions.https.onRequest(async (request, response) => {
  try {
    const signature = request.headers["stripe-signature"];
    const webhookSecret = functions.config().stripe.webhook_secret;

    // Verify webhook signature
    let event;
    try {
      event = stripe.webhooks.constructEvent(
        request.rawBody,
        signature,
        webhookSecret
      );
    } catch (err) {
      response.status(400).send(`Webhook Error: ${err.message}`);
      return;
    }

    // Handle webhook events
    switch (event.type) {
    case "customer.subscription.created":
    case "customer.subscription.updated": {
      const subscription = event.data.object;
      const {userId} = subscription.metadata;
      const isActive = ["active", "trialing"].includes(subscription.status);
      const currentPeriodEnd = new Date(subscription.current_period_end * 1000);

      // Update subscription in Firestore
      if (userId && subscription.items.data[0]?.price) {
        const subscriptionsRef = admin.firestore().collection("subscriptions");
        const existingSubscriptions = await subscriptionsRef
          .where("stripeSubscriptionId", "==", subscription.id)
          .get();

        const tier = TIER_MAP[subscription.items.data[0].price.id] || "free";

        if (existingSubscriptions.empty) {
          // Create new subscription document
          await subscriptionsRef.add({
            userId,
            tier,
            stripeSubscriptionId: subscription.id,
            stripePriceId: subscription.items.data[0].price.id,
            startDate: admin.firestore.Timestamp.now(),
            endDate: admin.firestore.Timestamp.fromDate(currentPeriodEnd),
            isActive,
            autoRenew: !subscription.cancel_at_period_end,
            createdAt: admin.firestore.Timestamp.serverTimestamp(),
            updatedAt: admin.firestore.Timestamp.serverTimestamp(),
          });
        } else {
          // Update existing subscription
          await existingSubscriptions.docs[0].ref.update({
            tier,
            stripePriceId: subscription.items.data[0].price.id,
            isActive,
            endDate: admin.firestore.Timestamp.fromDate(currentPeriodEnd),
            autoRenew: !subscription.cancel_at_period_end,
            updatedAt: admin.firestore.Timestamp.serverTimestamp(),
          });
        }

        // Update artist profile
        const artistProfilesRef = admin.firestore().collection("artistProfiles");
        const artistProfiles = await artistProfilesRef
          .where("userId", "==", userId)
          .get();

        if (!artistProfiles.empty) {
          await artistProfiles.docs[0].ref.update({
            subscriptionTier: tier,
            updatedAt: admin.firestore.Timestamp.serverTimestamp(),
          });
        }
      }
      break;
    }

    case "customer.subscription.deleted": {
      const subscription = event.data.object;
      const {userId} = subscription.metadata;

      if (userId) {
        const subscriptionsRef = admin.firestore().collection("subscriptions");
        const existingSubscriptions = await subscriptionsRef
          .where("stripeSubscriptionId", "==", subscription.id)
          .get();

        if (!existingSubscriptions.empty) {
          const existingSubscription = existingSubscriptions.docs[0].data();
          const previousTier = existingSubscription.tier;

          // Update subscription to inactive
          await existingSubscriptions.docs[0].ref.update({
            isActive: false,
            autoRenew: false,
            updatedAt: admin.firestore.Timestamp.serverTimestamp(),
          });

          // Check notification preferences
          const userDoc = await admin.firestore()
            .collection("users")
            .doc(userId)
            .get();

          if (userDoc.exists) {
            const userPrefs = userDoc.data().notificationPreferences || {};
            const notifyOnSubscriptionCancelled = userPrefs.notifyOnSubscriptionCancelled !== false;

            if (notifyOnSubscriptionCancelled) {
              await admin.firestore().collection("notifications").add({
                userId,
                type: "subscriptionCancelled",
                content: `Your ${TIER_DISPLAY_NAMES[previousTier]} subscription has been cancelled. Your subscription benefits will end on ${new Date(subscription.current_period_end * 1000).toLocaleDateString()}.`,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                isRead: false,
                subscriptionId: subscription.id,
                additionalData: {
                  tier: previousTier,
                  endDate: new Date(subscription.current_period_end * 1000).toISOString(),
                },
              });
            }
          }
        }

        // Update artist profile to free tier
        const artistProfilesRef = admin.firestore().collection("artistProfiles");
        const artistProfiles = await artistProfilesRef
          .where("userId", "==", userId)
          .get();

        if (!artistProfiles.empty) {
          await artistProfiles.docs[0].ref.update({
            subscriptionTier: "free",
            updatedAt: admin.firestore.Timestamp.serverTimestamp(),
          });
        }
      }
      break;
    }

    case "payment_intent.succeeded": {
      const paymentIntent = event.data.object;
      const {userId} = paymentIntent.metadata;

      if (userId) {
        // Log successful payment
        const paymentDoc = await admin.firestore().collection("payments").add({
          userId,
          paymentIntentId: paymentIntent.id,
          amount: paymentIntent.amount,
          currency: paymentIntent.currency,
          status: "succeeded",
          createdAt: admin.firestore.Timestamp.serverTimestamp(),
        });

        // Create payment success notification
        const userDoc = await admin.firestore()
          .collection("users")
          .doc(userId)
          .get();

        if (userDoc.exists) {
          const userPrefs = userDoc.data().notificationPreferences || {};
          const notifyOnPaymentEvents = userPrefs.notifyOnPaymentEvents !== false;

          if (notifyOnPaymentEvents) {
            await admin.firestore().collection("notifications").add({
              userId,
              type: "paymentSuccess",
              content: `Your payment of ${(paymentIntent.amount / 100).toFixed(2)} ${paymentIntent.currency.toUpperCase()} was successful.`,
              createdAt: admin.firestore.Timestamp.serverTimestamp(),
              isRead: false,
              paymentId: paymentDoc.id,
              subscriptionId: paymentIntent.metadata.subscriptionId,
              additionalData: {
                amount: paymentIntent.amount,
                currency: paymentIntent.currency,
              },
            });
          }
        }
      }
      break;
    }

    case "payment_intent.payment_failed": {
      const paymentIntent = event.data.object;
      const {userId} = paymentIntent.metadata;

      if (userId) {
        // Log failed payment
        const paymentDoc = await admin.firestore().collection("payments").add({
          userId,
          paymentIntentId: paymentIntent.id,
          amount: paymentIntent.amount,
          currency: paymentIntent.currency,
          status: "failed",
          errorMessage: paymentIntent.last_payment_error?.message ?? "Payment failed",
          createdAt: admin.firestore.Timestamp.serverTimestamp(),
        });

        // Create payment failure notification
        const userDoc = await admin.firestore()
          .collection("users")
          .doc(userId)
          .get();

        if (userDoc.exists) {
          const userPrefs = userDoc.data().notificationPreferences || {};
          const notifyOnPaymentEvents = userPrefs.notifyOnPaymentEvents !== false;

          if (notifyOnPaymentEvents) {
            let subscriptionDetails = "";
            const subscriptionId = paymentIntent.metadata.subscriptionId;

            if (subscriptionId) {
              try {
                const subscription = await stripe.subscriptions.retrieve(subscriptionId);
                if (subscription) {
                  const priceId = subscription.items.data[0]?.price.id;
                  const tier = TIER_MAP[priceId] || "subscription";
                  subscriptionDetails = ` for your ${TIER_DISPLAY_NAMES[tier]}`;
                }
              } catch (e) {
                console.error(`Error getting subscription: ${e}`);
              }
            }

            await admin.firestore().collection("notifications").add({
              userId,
              type: "paymentFailed",
              content: `Your payment${subscriptionDetails} failed. Please update your payment method to continue your service.`,
              createdAt: admin.firestore.Timestamp.serverTimestamp(),
              isRead: false,
              paymentId: paymentDoc.id,
              subscriptionId,
              additionalData: {
                amount: paymentIntent.amount,
                currency: paymentIntent.currency,
                errorMessage: paymentIntent.last_payment_error?.message ?? "Payment failed",
              },
            });
          }
        }
      }
      break;
    }
    }

    response.json({received: true});
  } catch (error) {
    console.error("Webhook error:", error);
    response.status(500).send("Webhook error");
  }
});

/**
 * Process a gift payment
 */
exports.processGiftPayment = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== "POST") {
        return response.status(405).send({error: "Method Not Allowed"});
      }

      const {senderId, recipientId, amount, paymentMethodId, message} = request.body;

      if (!senderId || !recipientId || !amount || !paymentMethodId) {
        return response.status(400).send({
          error: "Missing required parameters",
        });
      }

      // Get sender's customer ID from Firestore
      const senderDoc = await admin.firestore().collection("users")
        .doc(senderId)
        .get();

      if (!senderDoc.exists) {
        return response.status(404).send({error: "Sender not found"});
      }

      const customerId = senderDoc.data().stripeCustomerId;
      if (!customerId) {
        return response.status(400).send({error: "Sender has no payment setup"});
      }

      // Create a payment intent
      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(amount * 100), // Convert to cents
        currency: "usd",
        customer: customerId,
        payment_method: paymentMethodId,
        off_session: true,
        confirm: true,
        metadata: {
          type: "gift",
          senderId,
          recipientId,
          message: message || "",
        },
      });

      // Return the payment intent details
      return response.status(200).send({
        paymentIntentId: paymentIntent.id,
        status: paymentIntent.status,
        amount: paymentIntent.amount / 100,
      });
    } catch (error) {
      console.error("Error processing gift payment:", error);
      return response.status(500).send({error: error.message});
    }
  });
});

/**
 * Process an ad payment
 */
exports.processAdPayment = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== "POST") {
        return response.status(405).send({error: "Method Not Allowed"});
      }

      const {
        userId,
        adId,
        amount,
        paymentMethodId,
        adType,
        duration,
        location,
      } = request.body;

      if (!userId || !adId || !amount || !paymentMethodId || !adType) {
        return response.status(400).send({
          error: "Missing required parameters",
        });
      }

      // Get user's customer ID from Firestore
      const userDoc = await admin.firestore().collection("users")
        .doc(userId)
        .get();

      if (!userDoc.exists) {
        return response.status(404).send({error: "User not found"});
      }

      const customerId = userDoc.data().stripeCustomerId;
      if (!customerId) {
        return response.status(400).send({error: "User has no payment setup"});
      }

      // Create a payment intent
      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(amount * 100), // Convert to cents
        currency: "usd",
        customer: customerId,
        payment_method: paymentMethodId,
        off_session: true,
        confirm: true,
        metadata: {
          type: "ad_payment",
          userId,
          adId,
          adType,
          duration: duration?.toString() || "",
          location: location?.toString() || "",
        },
      });

      // Create payment record in Firestore
      await admin.firestore().collection("adPayments").add({
        userId,
        adId,
        paymentIntentId: paymentIntent.id,
        amount: amount,
        currency: "usd",
        status: paymentIntent.status,
        adType,
        duration,
        location,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Return the payment intent details
      return response.status(200).send({
        paymentIntentId: paymentIntent.id,
        status: paymentIntent.status,
        amount: paymentIntent.amount / 100,
      });
    } catch (error) {
      console.error("Error processing ad payment:", error);
      return response.status(500).send({error: error.message});
    }
  });
});

/**
 * Get ad pricing based on type, duration, and location
 */
exports.getAdPricing = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== "GET") {
        return response.status(405).send({error: "Method Not Allowed"});
      }

      const {adType, duration, location} = request.query;

      // Define pricing structure
      const basePrices = {
        "banner": 10.00, // Banner ads
        "featured": 25.00, // Featured placement
        "sponsored": 50.00, // Sponsored content
        "premium": 100.00, // Premium placement
      };

      const locationMultipliers = {
        "home": 1.5, // Home screen - premium location
        "browse": 1.2, // Browse screen
        "profile": 1.0, // Profile pages
        "search": 1.3, // Search results
        "artwork": 1.1, // Artwork detail pages
      };

      const durationMultipliers = {
        "1": 1.0, // 1 day
        "3": 2.5, // 3 days
        "7": 5.0, // 1 week
        "14": 9.0, // 2 weeks
        "30": 15.0, // 1 month
      };

      const basePrice = basePrices[adType] || basePrices["banner"];
      const locationMultiplier = locationMultipliers[location] || 1.0;
      const durationMultiplier = durationMultipliers[duration] || 1.0;

      const totalPrice = basePrice * locationMultiplier * durationMultiplier;

      return response.status(200).send({
        basePrice,
        locationMultiplier,
        durationMultiplier,
        totalPrice: Math.round(totalPrice * 100) / 100, // Round to 2 decimal places
        currency: "usd",
      });
    } catch (error) {
      console.error("Error getting ad pricing:", error);
      return response.status(500).send({error: error.message});
    }
  });
});

/**
 * Handle Stripe webhooks for payment events
 */
exports.stripeWebhook = functions.https.onRequest(async (request, response) => {
  const sig = request.headers["stripe-signature"];
  const endpointSecret = functions.config().stripe.webhook_secret;

  let event;

  try {
    event = stripe.webhooks.constructEvent(request.rawBody, sig, endpointSecret);
  } catch (err) {
    console.error("Webhook signature verification failed:", err.message);
    return response.status(400).send(`Webhook Error: ${err.message}`);
  }

  try {
    switch (event.type) {
    case "payment_intent.succeeded":
      await handlePaymentIntentSucceeded(event.data.object);
      break;

    case "payment_intent.payment_failed":
      await handlePaymentIntentFailed(event.data.object);
      break;

    case "customer.subscription.created":
      await handleSubscriptionCreated(event.data.object);
      break;

    case "customer.subscription.updated":
      await handleSubscriptionUpdated(event.data.object);
      break;

    case "customer.subscription.deleted":
      await handleSubscriptionDeleted(event.data.object);
      break;

    case "invoice.payment_succeeded":
      await handleInvoicePaymentSucceeded(event.data.object);
      break;

    case "invoice.payment_failed":
      await handleInvoicePaymentFailed(event.data.object);
      break;

    default:
      console.log(`Unhandled event type: ${event.type}`);
    }

    response.status(200).send({received: true});
  } catch (error) {
    console.error("Error handling webhook:", error);
    response.status(500).send({error: error.message});
  }
});

/**
 * Handle successful payment intent
 */
async function handlePaymentIntentSucceeded(paymentIntent) {
  console.log("Payment succeeded:", paymentIntent.id);

  const metadata = paymentIntent.metadata;

  if (metadata.type === "gift") {
    // Update gift status in Firestore
    const giftsRef = admin.firestore().collection("gifts");
    const giftQuery = await giftsRef
      .where("paymentIntentId", "==", paymentIntent.id)
      .get();

    if (!giftQuery.empty) {
      const giftDoc = giftQuery.docs[0];
      await giftDoc.ref.update({
        status: "completed",
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Send notification to recipient
      await sendGiftNotification(metadata.recipientId, metadata.senderId, metadata.giftType);
    }
  } else if (metadata.type === "ad_payment") {
    // Update ad payment status
    const adPaymentsRef = admin.firestore().collection("adPayments");
    const paymentQuery = await adPaymentsRef
      .where("paymentIntentId", "==", paymentIntent.id)
      .get();

    if (!paymentQuery.empty) {
      const paymentDoc = paymentQuery.docs[0];
      await paymentDoc.ref.update({
        status: "succeeded",
        completedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Update ad status to paid
      const adId = metadata.adId;
      if (adId) {
        await admin.firestore().collection("ads").doc(adId).update({
          paymentStatus: "paid",
          status: 1, // Pending approval
        });
      }
    }
  }
}

/**
 * Handle failed payment intent
 */
async function handlePaymentIntentFailed(paymentIntent) {
  console.log("Payment failed:", paymentIntent.id);

  const metadata = paymentIntent.metadata;

  if (metadata.type === "gift") {
    // Update gift status to failed
    const giftsRef = admin.firestore().collection("gifts");
    const giftQuery = await giftsRef
      .where("paymentIntentId", "==", paymentIntent.id)
      .get();

    if (!giftQuery.empty) {
      const giftDoc = giftQuery.docs[0];
      await giftDoc.ref.update({
        status: "failed",
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  } else if (metadata.type === "ad_payment") {
    // Update ad payment status to failed
    const adPaymentsRef = admin.firestore().collection("adPayments");
    const paymentQuery = await adPaymentsRef
      .where("paymentIntentId", "==", paymentIntent.id)
      .get();

    if (!paymentQuery.empty) {
      const paymentDoc = paymentQuery.docs[0];
      await paymentDoc.ref.update({
        status: "failed",
        failedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
}

/**
 * Handle subscription creation
 */
async function handleSubscriptionCreated(subscription) {
  console.log("Subscription created:", subscription.id);

  const customerId = subscription.customer;
  const userId = await getUserIdFromCustomerId(customerId);

  if (userId) {
    // Update user subscription in Firestore
    await admin.firestore().collection("subscriptions").add({
      userId,
      stripeSubscriptionId: subscription.id,
      stripeCustomerId: customerId,
      status: subscription.status,
      currentPeriodStart: new Date(subscription.current_period_start * 1000),
      currentPeriodEnd: new Date(subscription.current_period_end * 1000),
      tier: getSubscriptionTierFromPriceId(subscription.items.data[0].price.id),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update user document with subscription info
    await admin.firestore().collection("users").doc(userId).update({
      subscriptionStatus: subscription.status,
      subscriptionTier: getSubscriptionTierFromPriceId(subscription.items.data[0].price.id),
      subscriptionId: subscription.id,
    });
  }
}

/**
 * Handle subscription updates
 */
async function handleSubscriptionUpdated(subscription) {
  console.log("Subscription updated:", subscription.id);

  const customerId = subscription.customer;
  const userId = await getUserIdFromCustomerId(customerId);

  if (userId) {
    // Update subscription in Firestore
    const subscriptionsRef = admin.firestore().collection("subscriptions");
    const subscriptionQuery = await subscriptionsRef
      .where("stripeSubscriptionId", "==", subscription.id)
      .get();

    if (!subscriptionQuery.empty) {
      const subscriptionDoc = subscriptionQuery.docs[0];
      await subscriptionDoc.ref.update({
        status: subscription.status,
        currentPeriodStart: new Date(subscription.current_period_start * 1000),
        currentPeriodEnd: new Date(subscription.current_period_end * 1000),
        tier: getSubscriptionTierFromPriceId(subscription.items.data[0].price.id),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // Update user document
    await admin.firestore().collection("users").doc(userId).update({
      subscriptionStatus: subscription.status,
      subscriptionTier: getSubscriptionTierFromPriceId(subscription.items.data[0].price.id),
    });
  }
}

/**
 * Handle subscription deletion
 */
async function handleSubscriptionDeleted(subscription) {
  console.log("Subscription deleted:", subscription.id);

  const customerId = subscription.customer;
  const userId = await getUserIdFromCustomerId(customerId);

  if (userId) {
    // Update subscription status in Firestore
    const subscriptionsRef = admin.firestore().collection("subscriptions");
    const subscriptionQuery = await subscriptionsRef
      .where("stripeSubscriptionId", "==", subscription.id)
      .get();

    if (!subscriptionQuery.empty) {
      const subscriptionDoc = subscriptionQuery.docs[0];
      await subscriptionDoc.ref.update({
        status: "canceled",
        canceledAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // Update user document to free tier
    await admin.firestore().collection("users").doc(userId).update({
      subscriptionStatus: "canceled",
      subscriptionTier: "free",
      subscriptionId: null,
    });
  }
}

/**
 * Handle successful invoice payment
 */
async function handleInvoicePaymentSucceeded(invoice) {
  console.log("Invoice payment succeeded:", invoice.id);

  const subscriptionId = invoice.subscription;
  if (subscriptionId) {
    // Update subscription payment status
    const subscriptionsRef = admin.firestore().collection("subscriptions");
    const subscriptionQuery = await subscriptionsRef
      .where("stripeSubscriptionId", "==", subscriptionId)
      .get();

    if (!subscriptionQuery.empty) {
      const subscriptionDoc = subscriptionQuery.docs[0];
      await subscriptionDoc.ref.update({
        lastPaymentDate: admin.firestore.FieldValue.serverTimestamp(),
        paymentStatus: "paid",
      });
    }
  }
}

/**
 * Handle failed invoice payment
 */
async function handleInvoicePaymentFailed(invoice) {
  console.log("Invoice payment failed:", invoice.id);

  const subscriptionId = invoice.subscription;
  if (subscriptionId) {
    // Update subscription payment status
    const subscriptionsRef = admin.firestore().collection("subscriptions");
    const subscriptionQuery = await subscriptionsRef
      .where("stripeSubscriptionId", "==", subscriptionId)
      .get();

    if (!subscriptionQuery.empty) {
      const subscriptionDoc = subscriptionQuery.docs[0];
      await subscriptionDoc.ref.update({
        paymentStatus: "failed",
        lastFailedPayment: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }
}

/**
 * Helper function to get user ID from Stripe customer ID
 */
async function getUserIdFromCustomerId(customerId) {
  const usersRef = admin.firestore().collection("users");
  const userQuery = await usersRef
    .where("stripeCustomerId", "==", customerId)
    .get();

  if (!userQuery.empty) {
    return userQuery.docs[0].id;
  }

  return null;
}

/**
 * Helper function to get subscription tier from Stripe price ID
 */
function getSubscriptionTierFromPriceId(priceId) {
  const tierMapping = {
    "price_artist_pro_monthly": "artistPro",
    "price_gallery_monthly": "gallery",
    // Add more price ID mappings as needed
  };

  return tierMapping[priceId] || "free";
}

/**
 * Helper function to send gift notification
 */
async function sendGiftNotification(recipientId, senderId, giftType) {
  try {
    // Get sender information
    const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
    const senderName = senderDoc.exists ? senderDoc.data().displayName || "Someone" : "Someone";

    // Create notification
    await admin.firestore().collection("notifications").add({
      userId: recipientId,
      type: "gift_received",
      title: "Gift Received!",
      message: `${senderName} sent you a ${giftType}!`,
      data: {
        senderId,
        giftType,
      },
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Gift notification sent to ${recipientId}`);
  } catch (error) {
    console.error("Error sending gift notification:", error);
  }
}

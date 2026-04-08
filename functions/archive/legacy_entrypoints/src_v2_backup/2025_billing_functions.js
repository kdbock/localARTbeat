const functions = require("firebase-functions");
const admin = require("firebase-admin");
const stripe = require("stripe")(functions.config().stripe.secret_key);

/**
 * Calculate and process monthly usage overages
 * Called by scheduled function on the 1st of each month
 */
exports.processMonthlyOverages = functions.pubsub
  .schedule("0 0 1 * *") // First day of each month at midnight
  .timeZone("UTC")
  .onRun(async () => {
    console.log("Processing monthly usage overages...");

    try {
      const usersSnapshot = await admin.firestore()
        .collection("users")
        .where("subscriptionTier", "!=", "free")
        .get();

      const billingPromises = [];

      for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userData = userDoc.data();

        billingPromises.push(processUserOverages(userId, userData));
      }

      await Promise.all(billingPromises);
      console.log(`Processed overages for ${usersSnapshot.docs.length} users`);

      return {success: true, processedUsers: usersSnapshot.docs.length};
    } catch (error) {
      console.error("Error processing monthly overages:", error);
      throw error;
    }
  });

/**
 * Process overages for a specific user
 * @param {string} userId - The user ID to process overages for
 * @param {Object} userData - The user data containing subscription information
 */
async function processUserOverages(userId, userData) {
  try {
    const subscriptionTier = userData.subscriptionTier || "free";
    if (subscriptionTier === "free") return; // No overage billing for free

    // Get user's usage data
    const usageDoc = await admin.firestore()
      .collection("usage")
      .doc(userId)
      .get();

    if (!usageDoc.exists) return;

    const usage = usageDoc.data();
    const limits = getTierLimits(subscriptionTier);
    const overages = calculateOverages(usage, limits);

    if (overages.totalAmount > 0) {
      await createOverageBill(userId, overages, subscriptionTier);
      await resetMonthlyUsage(userId);
    }
  } catch (error) {
    console.error(`Error processing overages for user ${userId}:`, error);
  }
}

/**
 * Get feature limits for a subscription tier
 * @param {string} tier - The subscription tier (free, basic, pro, gallery)
 * @return {Object} Object containing limits for various features
 */
function getTierLimits(tier) {
  const limits = {
    starter: {
      artworks: 25,
      storageGB: 5,
      aiCredits: 50,
      teamMembers: 1,
    },
    creator: {
      artworks: 100,
      storageGB: 25,
      aiCredits: 200,
      teamMembers: 1,
    },
    business: {
      artworks: -1, // Unlimited
      storageGB: 100,
      aiCredits: 500,
      teamMembers: 5,
    },
    enterprise: {
      artworks: -1, // Unlimited
      storageGB: -1, // Unlimited
      aiCredits: -1, // Unlimited
      teamMembers: -1, // Unlimited
    },
  };

  return limits[tier] || limits.starter;
}

/**
 * Calculate overage amounts based on usage and limits
 * @param {Object} usage - Current usage metrics
 * @param {Object} limits - Subscription tier limits
 * @return {Object} Calculated overage amounts and details
 */
function calculateOverages(usage, limits) {
  const overagePricing = {
    artwork: 0.99,
    storageGB: 0.49,
    aiCredit: 0.05,
    teamMember: 9.99,
  };

  const overages = {
    artworks: 0,
    storage: 0,
    aiCredits: 0,
    teamMembers: 0,
    totalAmount: 0,
    details: [],
  };

  // Calculate artwork overage
  if (limits.artworks !== -1 && usage.artworksCount > limits.artworks) {
    const overageCount = usage.artworksCount - limits.artworks;
    const amount = overageCount * overagePricing.artwork;
    overages.artworks = overageCount;
    overages.totalAmount += amount;
    overages.details.push({
      type: "artwork",
      count: overageCount,
      unitPrice: overagePricing.artwork,
      amount: amount,
    });
  }

  // Calculate storage overage
  if (limits.storageGB !== -1 && usage.storageUsedGB > limits.storageGB) {
    const overageGB = usage.storageUsedGB - limits.storageGB;
    const amount = overageGB * overagePricing.storageGB;
    overages.storage = overageGB;
    overages.totalAmount += amount;
    overages.details.push({
      type: "storage",
      count: overageGB,
      unitPrice: overagePricing.storageGB,
      amount: amount,
    });
  }

  // Calculate AI credits overage
  if (limits.aiCredits !== -1 && usage.aiCreditsUsed > limits.aiCredits) {
    const overageCredits = usage.aiCreditsUsed - limits.aiCredits;
    const amount = overageCredits * overagePricing.aiCredit;
    overages.aiCredits = overageCredits;
    overages.totalAmount += amount;
    overages.details.push({
      type: "aiCredit",
      count: overageCredits,
      unitPrice: overagePricing.aiCredit,
      amount: amount,
    });
  }

  // Calculate team member overage
  if (limits.teamMembers !== -1 &&
      usage.teamMembersCount > limits.teamMembers) {
    const overageMembers = usage.teamMembersCount - limits.teamMembers;
    const amount = overageMembers * overagePricing.teamMember;
    overages.teamMembers = overageMembers;
    overages.totalAmount += amount;
    overages.details.push({
      type: "teamMember",
      count: overageMembers,
      unitPrice: overagePricing.teamMember,
      amount: amount,
    });
  }

  return overages;
}

/**
 * Create overage bill and charge the user
 * @param {string} userId - The user ID to charge
 * @param {Object} overages - Calculated overage amounts
 * @param {string} subscriptionTier - User's subscription tier
 */
async function createOverageBill(userId, overages, subscriptionTier) {
  try {
    // Get user's Stripe customer ID
    const userDoc = await admin.firestore()
      .collection("users")
      .doc(userId)
      .get();

    const stripeCustomerId = userDoc.data().stripeCustomerId;
    if (!stripeCustomerId) {
      console.error(`No Stripe customer ID for user ${userId}`);
      return;
    }

    // Create invoice item for overage
    const invoiceItem = await stripe.invoiceItems.create({
      customer: stripeCustomerId,
      amount: Math.round(overages.totalAmount * 100), // Convert to cents
      currency: "usd",
      description: `Usage overage charges for ${
        new Date().toLocaleString("default", {
          month: "long",
          year: "numeric",
        })
      }`,
      metadata: {
        userId: userId,
        subscriptionTier: subscriptionTier,
        type: "usage_overage",
        billingPeriod: new Date().toISOString(),
      },
    });

    // Create and finalize invoice
    const invoice = await stripe.invoices.create({
      customer: stripeCustomerId,
      auto_advance: true, // Automatically finalize and attempt payment
      collection_method: "charge_automatically",
      description: "Monthly usage overage charges",
    });

    await stripe.invoices.finalizeInvoice(invoice.id);

    // Store overage record in Firestore
    await admin.firestore().collection("overageBills").add({
      userId: userId,
      subscriptionTier: subscriptionTier,
      billingPeriod: admin.firestore.Timestamp.now(),
      overages: overages,
      stripeInvoiceId: invoice.id,
      stripeInvoiceItemId: invoiceItem.id,
      totalAmount: overages.totalAmount,
      status: "billed",
      createdAt: admin.firestore.Timestamp.now(),
    });

    // Send notification to user
    await admin.firestore().collection("notifications").add({
      userId: userId,
      type: "overage_bill",
      title: "Usage Overage Charges",
      message: `You've been charged $${overages.totalAmount.toFixed(2)} ` +
               "for usage overages this month. View details in billing.",
      isRead: false,
      createdAt: admin.firestore.Timestamp.now(),
      additionalData: {
        amount: overages.totalAmount,
        details: overages.details,
        invoiceId: invoice.id,
      },
    });

    console.log(`Created overage bill for user ${userId}: ` +
                `$${overages.totalAmount.toFixed(2)}`);
  } catch (error) {
    console.error(`Error creating overage bill for user ${userId}:`, error);
  }
}

/**
 * Reset monthly usage counters
 * @param {string} userId - The user ID to reset usage for
 */
async function resetMonthlyUsage(userId) {
  try {
    await admin.firestore()
      .collection("usage")
      .doc(userId)
      .update({
        aiCreditsUsed: 0,
        lastUsageReset: admin.firestore.Timestamp.now(),
        monthlyResetCount: admin.firestore.FieldValue.increment(1),
      });
  } catch (error) {
    console.error(`Error resetting monthly usage for user ${userId}:`, error);
  }
}

/**
 * Get user's current usage and overage projection
 */
exports.getUserUsageProjection = functions.https.onRequest(
  async (request, response) => {
    const cors = require("cors")({origin: true});

    cors(request, response, async () => {
      try {
        if (request.method !== "GET") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {userId} = request.query;
        if (!userId) {
          return response.status(400).send({error: "Missing userId parameter"});
        }

        // Get user subscription tier
        const userDoc = await admin.firestore()
          .collection("users")
          .doc(userId)
          .get();

        if (!userDoc.exists) {
          return response.status(404).send({error: "User not found"});
        }

        const subscriptionTier = userDoc.data().subscriptionTier || "free";

        // Get current usage
        const usageDoc = await admin.firestore()
          .collection("usage")
          .doc(userId)
          .get();

        const usage = usageDoc.exists ? usageDoc.data() : {
          artworksCount: 0,
          storageUsedGB: 0,
          aiCreditsUsed: 0,
          teamMembersCount: 1,
        };

        const limits = getTierLimits(subscriptionTier);
        const projectedOverages = calculateOverages(usage, limits);

        response.status(200).send({
          userId: userId,
          subscriptionTier: subscriptionTier,
          usage: usage,
          limits: limits,
          projectedOverages: projectedOverages,
          billingDate: getNextBillingDate(),
        });
      } catch (error) {
        console.error("Error getting usage projection:", error);
        response.status(500).send({error: error.message});
      }
    });
  });

/**
 * Get next billing date (1st of next month)
 * @return {Date} The next billing date
 */
function getNextBillingDate() {
  const now = new Date();
  const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1);
  return nextMonth.toISOString();
}

/**
 * Handle AI feature usage tracking
 */
exports.trackAIUsage = functions.https.onRequest(async (request, response) => {
  const cors = require("cors")({origin: true});

  cors(request, response, async () => {
    try {
      if (request.method !== "POST") {
        return response.status(405).send({error: "Method Not Allowed"});
      }

      const {userId, feature, creditsUsed, metadata} = request.body;

      if (!userId || !feature || !creditsUsed) {
        return response.status(400).send({
          error: "Missing required parameters: userId, feature, creditsUsed",
        });
      }

      // Update user's AI credit usage
      await admin.firestore()
        .collection("usage")
        .doc(userId)
        .update({
          aiCreditsUsed: admin.firestore.FieldValue.increment(creditsUsed),
          lastAIUsage: admin.firestore.Timestamp.now(),
        });

      // Log AI usage event for analytics
      await admin.firestore().collection("aiUsageEvents").add({
        userId: userId,
        feature: feature,
        creditsUsed: creditsUsed,
        metadata: metadata || {},
        timestamp: admin.firestore.Timestamp.now(),
      });

      response.status(200).send({
        success: true,
        creditsUsed: creditsUsed,
        feature: feature,
      });
    } catch (error) {
      console.error("Error tracking AI usage:", error);
      response.status(500).send({error: error.message});
    }
  });
});

module.exports = {
  processMonthlyOverages: exports.processMonthlyOverages,
  getUserUsageProjection: exports.getUserUsageProjection,
  trackAIUsage: exports.trackAIUsage,
};

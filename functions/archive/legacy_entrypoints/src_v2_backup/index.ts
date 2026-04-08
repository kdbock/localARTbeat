import * as functions from "firebase-functions";
import {onRequest} from "firebase-functions/v2/https";
import {onSchedule} from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import Stripe from "stripe";

const StripeSecret = functions.params.defineSecret("STRIPE_SECRET_KEY");

// Initialize Stripe with proper typing
let stripeInstance: Stripe | null = null;

const getStripe = (): Stripe => {
  if (!stripeInstance) {
    stripeInstance = new Stripe(StripeSecret.value(), {
      apiVersion: "2023-10-16",
    });
  }
  return stripeInstance;
};

admin.initializeApp();

// Type definitions
interface UserData {
  subscriptionTier?: string;
  stripeCustomerId?: string;
  [key: string]: any;
}

interface UsageData {
  artworksCount: number;
  storageUsedGB: number;
  aiCreditsUsed: number;
  teamMembersCount: number;
  [key: string]: any;
}

interface TierLimits {
  artworks: number;
  storageGB: number;
  aiCredits: number;
  teamMembers: number;
  [key: string]: any;
}

interface OverageDetails {
  totalAmount: number;
  details: Array<{
    type: string;
    overage: number;
    rate: number;
    amount: number;
  }>;
}

/**
 * Test function to verify Firebase Functions v2 works
 */
export const testFunction = onRequest(
  {
    cors: true,
    region: "us-central1",
  },
  async (request, response) => {
    response.status(200).send({
      message: "Firebase Functions v2 is working!",
      timestamp: new Date().toISOString(),
    });
  }
);

/**
 * Create a new customer in Stripe
 */
export const createCustomer = onRequest(
  {
    cors: true,
    region: "us-central1",
    secrets: [StripeSecret],
  },
  async (request, response) => {
    const stripe = getStripe();

    try {
      if (request.method !== "POST") {
        response.status(405).send({error: "Method Not Allowed"});
        return;
      }

      const {email, userId} = request.body;

      if (!email || !userId) {
        response.status(400).send({
          error: "Missing required fields",
        });
        return;
      }

      const customer = await stripe.customers.create({
        email,
        metadata: {
          userId,
          firebaseUserId: userId,
        },
      });

      response.status(200).send({
        customerId: customer.id,
        success: true,
      });
    } catch (error) {
      console.error("Error creating customer:", error);
      response.status(500).send({error: (error as Error).message});
    }
  }
);

/**
 * Create a setup intent for adding payment methods
 */
export const createSetupIntent = onRequest(
  {
    cors: true,
    region: "us-central1",
    secrets: [StripeSecret],
  },
  async (request, response) => {
    const stripe = getStripe();

    try {
      if (request.method !== "POST") {
        response.status(405).send({error: "Method Not Allowed"});
        return;
      }

      const {customerId} = request.body;

      if (!customerId) {
        response.status(400).send({
          error: "Missing customerId",
        });
        return;
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
      response.status(500).send({error: (error as Error).message});
    }
  }
);

/**
 * Get customer's saved payment methods
 */
export const getPaymentMethods = onRequest(
  {
    cors: true,
    region: "us-central1",
    secrets: [StripeSecret],
  },
  async (request, response) => {
    const stripe = getStripe();

    try {
      if (request.method !== "POST") {
        response.status(405).send({error: "Method Not Allowed"});
        return;
      }

      const {customerId} = request.body;

      if (!customerId) {
        response.status(400).send({
          error: "Missing customerId",
        });
        return;
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
      response.status(500).send({error: (error as Error).message});
    }
  }
);

/**
 * Create subscription in Stripe
 */
export const createSubscription = onRequest(
  {
    cors: true,
    region: "us-central1",
    secrets: [StripeSecret],
  },
  async (request, response) => {
    const stripe = getStripe();

    try {
      if (request.method !== "POST") {
        response.status(405).send({error: "Method Not Allowed"});
        return;
      }

      const {customerId, priceId, userId} = request.body;

      if (!customerId || !priceId || !userId) {
        response.status(400).send({
          error: "Missing required parameters",
        });
        return;
      }

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

      const clientSecret =
        subscription.latest_invoice &&
        typeof subscription.latest_invoice === "object" &&
        "payment_intent" in subscription.latest_invoice &&
        subscription.latest_invoice.payment_intent &&
        typeof subscription.latest_invoice.payment_intent === "object" ?
          subscription.latest_invoice.payment_intent.client_secret || "" :
          "";

      response.status(200).send({
        subscriptionId: subscription.id,
        status: subscription.status,
        clientSecret,
      });
    } catch (error) {
      console.error("Error creating subscription:", error);
      response.status(500).send({error: (error as Error).message});
    }
  }
);

/**
 * Monthly billing for overages
 */
export const monthlyBilling = onSchedule(
  {
    schedule: "0 0 1 * *", // First day of every month at midnight
    timeZone: "America/New_York",
    secrets: [StripeSecret],
  },
  async () => {
    console.log("Starting monthly billing process...");

    try {
      const usersSnapshot = await admin
        .firestore()
        .collection("users")
        .where("subscriptionTier", "!=", "free")
        .get();

      const promises = usersSnapshot.docs.map(async (doc) => {
        const userId = doc.id;
        const userData = doc.data();
        await processUserOverages(userId, userData);
      });

      await Promise.all(promises);
      console.log("Monthly billing completed successfully");
    } catch (error) {
      console.error("Error in monthly billing:", error);
    }
  }
);

/**
 * Process user overages for billing
 * @param {string} userId - The user ID to process
 * @param {unknown} userData - The user data from Firestore
 * @return {Promise<void>} Promise that resolves when processing is complete
 */
async function processUserOverages(
  userId: string,
  userData: unknown
): Promise<void> {
  try {
    const user = userData as UserData;
    const subscriptionTier = user.subscriptionTier || "free";

    if (subscriptionTier === "free") return;

    const usageDoc = await admin
      .firestore()
      .collection("usage")
      .doc(userId)
      .get();

    if (!usageDoc.exists) return;

    const usage = usageDoc.data() as UsageData;
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
 * @param {string} tier - The subscription tier name
 * @return {TierLimits} Object containing tier limits
 */
function getTierLimits(tier: string): TierLimits {
  const limits: Record<string, TierLimits> = {
    starter: {
      artworks: 25,
      storageGB: 5,
      aiCredits: 100,
      teamMembers: 1,
    },
    professional: {
      artworks: 100,
      storageGB: 25,
      aiCredits: 500,
      teamMembers: 5,
    },
    enterprise: {
      artworks: -1, // Unlimited
      storageGB: 100,
      aiCredits: 2000,
      teamMembers: 20,
    },
  };

  return limits[tier] || limits.starter;
}

/**
 * Calculate overage amounts based on usage and limits
 * @param {UsageData} usage - Current usage data for the user
 * @param {TierLimits} limits - Tier limits for the user's subscription
 * @return {OverageDetails} Object containing calculated overages
 */
function calculateOverages(
  usage: UsageData,
  limits: TierLimits
): OverageDetails {
  const overagePricing = {
    artwork: 0.99,
    storageGB: 0.49,
    aiCredit: 0.05,
    teamMember: 9.99,
  };

  const overages: OverageDetails = {
    totalAmount: 0,
    details: [],
  };

  // Calculate artwork overage
  if (limits.artworks !== -1 && usage.artworksCount > limits.artworks) {
    const overageCount = usage.artworksCount - limits.artworks;
    const amount = overageCount * overagePricing.artwork;
    overages.totalAmount += amount;
    overages.details.push({
      type: "artwork",
      overage: overageCount,
      rate: overagePricing.artwork,
      amount: amount,
    });
  }

  // Calculate storage overage
  if (limits.storageGB !== -1 && usage.storageUsedGB > limits.storageGB) {
    const overageGB = usage.storageUsedGB - limits.storageGB;
    const amount = overageGB * overagePricing.storageGB;
    overages.totalAmount += amount;
    overages.details.push({
      type: "storage",
      overage: overageGB,
      rate: overagePricing.storageGB,
      amount: amount,
    });
  }

  // Calculate AI credits overage
  if (limits.aiCredits !== -1 && usage.aiCreditsUsed > limits.aiCredits) {
    const overageCredits = usage.aiCreditsUsed - limits.aiCredits;
    const amount = overageCredits * overagePricing.aiCredit;
    overages.totalAmount += amount;
    overages.details.push({
      type: "aiCredit",
      overage: overageCredits,
      rate: overagePricing.aiCredit,
      amount: amount,
    });
  }

  // Calculate team member overage
  if (
    limits.teamMembers !== -1 &&
    usage.teamMembersCount > limits.teamMembers
  ) {
    const overageMembers = usage.teamMembersCount - limits.teamMembers;
    const amount = overageMembers * overagePricing.teamMember;
    overages.totalAmount += amount;
    overages.details.push({
      type: "teamMember",
      overage: overageMembers,
      rate: overagePricing.teamMember,
      amount: amount,
    });
  }

  return overages;
}

/**
 * Create overage bill and charge the user
 * @param {string} userId - The user ID to bill
 * @param {OverageDetails} overages - Calculated overage amounts
 * @param {string} subscriptionTier - User's subscription tier
 * @return {Promise<void>} Promise that resolves when billing is complete
 */
async function createOverageBill(
  userId: string,
  overages: OverageDetails,
  subscriptionTier: string
): Promise<void> {
  const stripe = getStripe();

  try {
    const userDoc = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .get();
    const userData = userDoc.data() as UserData;
    const customerId = userData?.stripeCustomerId;

    if (!customerId) {
      console.error(`No Stripe customer ID found for user ${userId}`);
      return;
    }

    // Create invoice item for overages
    await stripe.invoiceItems.create({
      customer: customerId,
      amount: Math.round(overages.totalAmount * 100),
      currency: "usd",
      description: `Monthly overages - ${subscriptionTier} plan`,
      metadata: {
        userId,
        type: "overage",
        tier: subscriptionTier,
      },
    });

    // Create and finalize invoice
    const invoice = await stripe.invoices.create({
      customer: customerId,
      auto_advance: true,
      collection_method: "charge_automatically",
    });

    await stripe.invoices.finalizeInvoice(invoice.id);

    // Save billing record
    await admin.firestore().collection("billing_records").add({
      userId,
      type: "overage",
      amount: overages.totalAmount,
      details: overages.details,
      subscriptionTier,
      invoiceId: invoice.id,
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error(`Error creating overage bill for user ${userId}:`, error);
  }
}

/**
 * Reset monthly usage counters
 * @param {string} userId - The user ID to reset usage for
 * @return {Promise<void>} Promise that resolves when usage is reset
 */
async function resetMonthlyUsage(userId: string): Promise<void> {
  try {
    await admin.firestore().collection("usage").doc(userId).update({
      artworksCount: 0,
      storageUsedGB: 0,
      aiCreditsUsed: 0,
      lastResetAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error(`Error resetting usage for user ${userId}:`, error);
  }
}

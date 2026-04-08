import * as functions from "firebase-functions";
import {onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import Stripe from "stripe";

const StripeSecret = functions.params.defineSecret("Stripe_SECRET_KEY");

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

const db = admin.firestore();

export interface DirectCommissionData {
  id: string;
  clientId: string;
  clientName: string;
  artistId: string;
  artistName: string;
  title: string;
  description: string;
  type: string;
  specs: {
    size: string;
    medium: string;
    style: string;
    colorScheme: string;
    revisions: number;
    commercialUse: boolean;
    deliveryFormat: string;
    customRequirements: Record<string, any>;
  };
  status: string;
  basePrice: number;
  totalPrice: number;
  depositAmount: number;
  finalAmount: number;
  milestones: Array<{
    id: string;
    title: string;
    description: string;
    amount: number;
    dueDate: string;
    status: string;
    completedAt?: string;
    paymentIntentId?: string;
  }>;
  messages: Array<{
    id: string;
    senderId: string;
    senderName: string;
    message: string;
    timestamp: string;
    attachments: string[];
  }>;
  files: Array<{
    id: string;
    name: string;
    url: string;
    type: string;
    sizeBytes: number;
    uploadedAt: string;
    uploadedBy: string;
    description?: string;
  }>;
  metadata: {
    requestedAt: string;
    quotedAt?: string;
    acceptedAt?: string;
    startedAt?: string;
    completedAt?: string;
    deliveredAt?: string;
  };
  createdAt: string;
  updatedAt: string;
}

/**
 * Create a new commission request
 */
export const createCommissionRequest = onCall(
  {
    secrets: [StripeSecret],
  },
  async (request) => {
    try {
      if (!request.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "User must be authenticated"
        );
      }

      const {
        artistId,
        title,
        description,
        type,
        specs,
        basePrice,
        depositAmount,
        finalAmount,
        milestones,
      } = request.data;

      if (!artistId || !title || !description || !type || !specs) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Missing required fields"
        );
      }

      const clientDoc = await db
        .collection("users")
        .doc(request.auth.uid)
        .get();
      const artistDoc = await db.collection("users").doc(artistId).get();

      if (!clientDoc.exists || !artistDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Client or artist not found"
        );
      }

      const clientData = clientDoc.data();
      const artistData = artistDoc.data();

      const commissionRef = db.collection("direct_commissions").doc();
      const commissionData: DirectCommissionData = {
        id: commissionRef.id,
        clientId: request.auth.uid,
        clientName:
          clientData?.name || clientData?.displayName || "Unknown Client",
        artistId,
        artistName:
          artistData?.name || artistData?.displayName || "Unknown Artist",
        title,
        description,
        type,
        specs,
        status: "pending",
        basePrice: basePrice || 0,
        totalPrice: basePrice || 0,
        depositAmount: depositAmount || 0,
        finalAmount: finalAmount || 0,
        milestones: milestones || [],
        messages: [],
        files: [],
        metadata: {
          requestedAt: new Date().toISOString(),
        },
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString(),
      };

      await commissionRef.set(commissionData);

      await sendCommissionNotification(artistId, "new_request", {
        commissionId: commissionRef.id,
        clientName: commissionData.clientName,
        title,
      });

      return {commissionId: commissionRef.id};
    } catch (error) {
      console.error("Error creating commission request:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to create commission request"
      );
    }
  }
);

/**
 * Submit a quote for a commission
 */
export const submitCommissionQuote = onCall(
  {
    secrets: [StripeSecret],
  },
  async (request) => {
    try {
      if (!request.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "User must be authenticated"
        );
      }

      const {
        commissionId,
        totalPrice,
        depositAmount,
        finalAmount,
        milestones,
        message,
      } = request.data;

      if (!commissionId || !totalPrice) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Missing required fields"
        );
      }

      const commissionRef = db
        .collection("direct_commissions")
        .doc(commissionId);
      const commissionDoc = await commissionRef.get();

      if (!commissionDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Commission not found"
        );
      }

      const commission = commissionDoc.data() as DirectCommissionData;

      if (commission.artistId !== request.auth.uid) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Only the artist can submit a quote"
        );
      }

      await commissionRef.update({
        "status": "quoted",
        totalPrice,
        "depositAmount": depositAmount || totalPrice * 0.5,
        "finalAmount": finalAmount || totalPrice * 0.5,
        "milestones": milestones || [],
        "metadata.quotedAt": new Date().toISOString(),
        "updatedAt": new Date().toISOString(),
      });

      if (message) {
        await addCommissionMessage(commissionId, request.auth.uid, message);
      }

      await sendCommissionNotification(commission.clientId, "quote_received", {
        commissionId,
        artistName: commission.artistName,
        totalPrice,
      });

      return {success: true};
    } catch (error) {
      console.error("Error submitting quote:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to submit quote"
      );
    }
  }
);

/**
 * Accept a commission quote and create payment intent for deposit
 */
export const acceptCommissionQuote = onCall(
  {
    secrets: [StripeSecret],
  },
  async (request) => {
    try {
      if (!request.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "User must be authenticated"
        );
      }

      const {commissionId} = request.data;

      if (!commissionId) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Commission ID is required"
        );
      }

      const commissionRef = db
        .collection("direct_commissions")
        .doc(commissionId);
      const commissionDoc = await commissionRef.get();

      if (!commissionDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Commission not found"
        );
      }

      const commission = commissionDoc.data() as DirectCommissionData;

      if (commission.clientId !== request.auth.uid) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Only the client can accept the quote"
        );
      }

      const clientDoc = await db
        .collection("users")
        .doc(request.auth.uid)
        .get();
      const clientData = clientDoc.data();
      let customerId = clientData?.stripeCustomerId;

      if (!customerId) {
        const stripe = getStripe();
        const customer = await stripe.customers.create({
          email: request.auth.token?.email || "",
          name: commission.clientName,
          metadata: {
            userId: request.auth.uid,
          },
        });
        customerId = customer.id;

        await db.collection("users").doc(request.auth.uid).update({
          stripeCustomerId: customerId,
        });
      }

      const stripe = getStripe();
      const paymentIntent = await stripe.paymentIntents.create({
        amount: Math.round(commission.depositAmount * 100),
        currency: "usd",
        customer: customerId,
        metadata: {
          commissionId,
          type: "deposit",
          clientId: commission.clientId,
          artistId: commission.artistId,
        },
        description: `Commission deposit for "${commission.title}"`,
      });

      await commissionRef.update({
        "status": "accepted",
        "metadata.acceptedAt": new Date().toISOString(),
        "updatedAt": new Date().toISOString(),
      });

      await sendCommissionNotification(commission.artistId, "quote_accepted", {
        commissionId,
        clientName: commission.clientName,
      });

      return {
        success: true,
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id,
      };
    } catch (error) {
      console.error("Error accepting quote:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to accept quote"
      );
    }
  }
);

/**
 * Handle successful deposit payment
 */
export const handleDepositPayment = onCall(
  {
    secrets: [StripeSecret],
  },
  async (request) => {
    try {
      if (!request.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "User must be authenticated"
        );
      }

      const {paymentIntentId} = request.data;

      if (!paymentIntentId) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Payment intent ID is required"
        );
      }

      const stripe = getStripe();
      const paymentIntent = await stripe.paymentIntents.retrieve(
        paymentIntentId
      );

      if (paymentIntent.status !== "succeeded") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Payment has not succeeded"
        );
      }

      const commissionId = paymentIntent.metadata.commissionId;
      const commissionRef = db
        .collection("direct_commissions")
        .doc(commissionId);
      const commissionDoc = await commissionRef.get();

      if (!commissionDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Commission not found"
        );
      }

      const commission = commissionDoc.data() as DirectCommissionData;

      await commissionRef.update({
        "status": "inProgress",
        "metadata.startedAt": new Date().toISOString(),
        "updatedAt": new Date().toISOString(),
      });

      await createEarningsRecord({
        userId: commission.artistId,
        type: "commission_deposit",
        amount: commission.depositAmount,
        commissionId,
        paymentIntentId,
        description: `Commission deposit for "${commission.title}"`,
      });

      await sendCommissionNotification(
        commission.artistId,
        "deposit_received",
        {
          commissionId,
          clientName: commission.clientName,
          amount: commission.depositAmount,
        }
      );

      return {success: true};
    } catch (error) {
      console.error("Error handling deposit payment:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to handle deposit payment"
      );
    }
  }
);

/**
 * Complete commission and request final payment
 */
export const completeCommission = onCall(
  {
    secrets: [StripeSecret],
  },
  async (request) => {
    try {
      if (!request.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "User must be authenticated"
        );
      }

      const {commissionId, deliveryFiles} = request.data;

      if (!commissionId) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Commission ID is required"
        );
      }

      const commissionRef = db
        .collection("direct_commissions")
        .doc(commissionId);
      const commissionDoc = await commissionRef.get();

      if (!commissionDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Commission not found"
        );
      }

      const commission = commissionDoc.data() as DirectCommissionData;

      if (commission.artistId !== request.auth.uid) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Only the artist can complete the commission"
        );
      }

      await commissionRef.update({
        "status": "completed",
        "metadata.completedAt": new Date().toISOString(),
        "updatedAt": new Date().toISOString(),
      });

      if (deliveryFiles && deliveryFiles.length > 0) {
        await commissionRef.update({
          files: admin.firestore.FieldValue.arrayUnion(...deliveryFiles),
        });
      }

      let finalPaymentIntent = null;
      if (commission.finalAmount > 0) {
        const clientDoc = await db
          .collection("users")
          .doc(commission.clientId)
          .get();
        const clientData = clientDoc.data();
        const customerId = clientData?.stripeCustomerId;

        if (customerId) {
          const stripe = getStripe();
          finalPaymentIntent = await stripe.paymentIntents.create({
            amount: Math.round(commission.finalAmount * 100),
            currency: "usd",
            customer: customerId,
            metadata: {
              commissionId,
              type: "final_payment",
              clientId: commission.clientId,
              artistId: commission.artistId,
            },
            description: `Final payment for commission "${commission.title}"`,
          });
        }
      }

      await sendCommissionNotification(
        commission.clientId,
        "commission_completed",
        {
          commissionId,
          artistName: commission.artistName,
          finalAmount: commission.finalAmount,
        }
      );

      return {
        success: true,
        finalPaymentIntent: finalPaymentIntent ?
          {
            clientSecret: finalPaymentIntent.client_secret,
            paymentIntentId: finalPaymentIntent.id,
          } :
          null,
      };
    } catch (error) {
      console.error("Error completing commission:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to complete commission"
      );
    }
  }
);

/**
 * Handle final payment and deliver commission
 */
export const handleFinalPayment = onCall(
  {
    secrets: [StripeSecret],
  },
  async (request) => {
    try {
      if (!request.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "User must be authenticated"
        );
      }

      const {paymentIntentId} = request.data;

      if (!paymentIntentId) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Payment intent ID is required"
        );
      }

      const stripe = getStripe();
      const paymentIntent = await stripe.paymentIntents.retrieve(
        paymentIntentId
      );

      if (paymentIntent.status !== "succeeded") {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "Payment has not succeeded"
        );
      }

      const commissionId = paymentIntent.metadata.commissionId;
      const commissionRef = db
        .collection("direct_commissions")
        .doc(commissionId);
      const commissionDoc = await commissionRef.get();

      if (!commissionDoc.exists) {
        throw new functions.https.HttpsError(
          "not-found",
          "Commission not found"
        );
      }

      const commission = commissionDoc.data() as DirectCommissionData;

      await commissionRef.update({
        "status": "delivered",
        "metadata.deliveredAt": new Date().toISOString(),
        "updatedAt": new Date().toISOString(),
      });

      await createEarningsRecord({
        userId: commission.artistId,
        type: "commission_final",
        amount: commission.finalAmount,
        commissionId,
        paymentIntentId,
        description: `Final payment for commission "${commission.title}"`,
      });

      await sendCommissionNotification(
        commission.artistId,
        "final_payment_received",
        {
          commissionId,
          clientName: commission.clientName,
          amount: commission.finalAmount,
        }
      );

      await sendCommissionNotification(
        commission.clientId,
        "commission_delivered",
        {
          commissionId,
          artistName: commission.artistName,
        }
      );

      return {success: true};
    } catch (error) {
      console.error("Error handling final payment:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to handle final payment"
      );
    }
  }
);

// Helper functions
/**
 * Add a message to a commission
 * @param {string} commissionId - The commission ID
 * @param {string} senderId - The sender's user ID
 * @param {string} message - The message content
 * @return {Promise<void>} Promise that resolves when message is added
 */
async function addCommissionMessage(
  commissionId: string,
  senderId: string,
  message: string
): Promise<void> {
  try {
    const senderDoc = await db.collection("users").doc(senderId).get();
    const senderData = senderDoc.data();
    const senderName = senderData?.name || senderData?.displayName || "Unknown";

    const messageData = {
      id: admin.firestore().collection("temp").doc().id,
      senderId,
      senderName,
      message,
      timestamp: new Date().toISOString(),
      attachments: [],
    };

    await db
      .collection("direct_commissions")
      .doc(commissionId)
      .update({
        messages: admin.firestore.FieldValue.arrayUnion(messageData),
        updatedAt: new Date().toISOString(),
      });
  } catch (error) {
    console.error("Error adding commission message:", error);
  }
}

/**
 * Create an earnings record for an artist
 * @param {Object} data - The earnings data
 * @return {Promise<void>} Promise that resolves when record is created
 */
async function createEarningsRecord(data: {
  userId: string;
  type: string;
  amount: number;
  commissionId: string;
  paymentIntentId: string;
  description: string;
}): Promise<void> {
  try {
    await db.collection("earnings").add({
      ...data,
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      processedAt: null,
    });
  } catch (error) {
    console.error("Error creating earnings record:", error);
  }
}

/**
 * Send a notification to a user about commission events
 * @param {string} userId - The user ID to notify
 * @param {string} type - The notification type
 * @param {Object} data - The notification data
 * @return {Promise<void>} Promise that resolves when notification is sent
 */
async function sendCommissionNotification(
  userId: string,
  type: string,
  data: Record<string, any>
): Promise<void> {
  try {
    await db.collection("notifications").add({
      userId,
      type,
      data,
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } catch (error) {
    console.error("Error sending notification:", error);
  }
}

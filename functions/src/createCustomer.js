const {onRequest} = require("firebase-functions/v2/https");
const {defineSecret} = require("firebase-functions/params");
const admin = require("firebase-admin");
const cors = require("cors");

// Initialize Firebase Admin if not already initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

// Define the secret for Stripe
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");

// Initialize CORS
const corsHandler = cors({origin: true});

exports.createCustomer = onRequest(
  {
    secrets: [stripeSecretKey],
    region: "us-central1",
  },
  async (req, res) => {
    console.log("🚀 CreateCustomer function called");
    console.log("Request method:", req.method);
    console.log("Request headers:", JSON.stringify(req.headers, null, 2));

    return corsHandler(req, res, async () => {
      try {
        // Verify Firebase Auth token
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          console.log("❌ No valid Authorization header found");
          return res.status(401).json({error: "Unauthorized: No valid token provided"});
        }

        const token = authHeader.split("Bearer ")[1];
        console.log("🔑 Token received, length:", token.length);

        let decodedToken;
        try {
          decodedToken = await admin.auth().verifyIdToken(token);
          console.log("✅ Token verified for user:", decodedToken.uid);
        } catch (error) {
          console.log("❌ Token verification failed:", error.message);
          return res.status(401).json({error: "Unauthorized: Invalid token"});
        }

        // Initialize Stripe with the secret
        const stripe = require("stripe")(stripeSecretKey.value());
        console.log("💳 Stripe initialized");

        // Parse request body
        const {email, userId} = req.body;
        console.log("📧 Request data - Email:", email, "UserId:", userId);

        // Verify the userId matches the authenticated user
        if (userId !== decodedToken.uid) {
          console.log("❌ User ID mismatch. Token UID:", decodedToken.uid, "Request UserId:", userId);
          return res.status(403).json({error: "Forbidden: User ID mismatch"});
        }

        if (!email || !userId) {
          console.log("❌ Missing required fields");
          return res.status(400).json({error: "Email and userId are required"});
        }

        // Create Stripe customer
        console.log("🔄 Creating Stripe customer...");
        const customer = await stripe.customers.create({
          email: email,
          metadata: {
            userId: userId,
          },
        });

        console.log("✅ Stripe customer created:", customer.id);

        // Store customer ID in Firestore
        await admin.firestore().collection("users").doc(userId).update({
          stripeCustomerId: customer.id,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log("✅ Customer ID stored in Firestore");

        res.status(200).json({
          success: true,
          customerId: customer.id,
        });
      } catch (error) {
        console.error("❌ Error in createCustomer:", error);
        res.status(500).json({
          error: "Internal server error",
          message: error.message,
        });
      }
    });
  }
);

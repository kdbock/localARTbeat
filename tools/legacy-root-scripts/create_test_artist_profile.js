const admin = require("firebase-admin");

// Initialize Firebase Admin for local emulator
admin.initializeApp({
  projectId: "wordnerd-artbeat",
});

// Point to local emulator
process.env.FIRESTORE_EMULATOR_HOST = "localhost:8080";

const db = admin.firestore();

async function createTestArtistProfile() {
  const userId = "rReie0exxqTvBR4mtElQ8is1gQK2"; // The user ID from your log

  console.log(`🔍 Checking if artist profile exists for user: ${userId}`);

  try {
    // Check if profile already exists
    const existingProfile = await db
      .collection("artistProfiles")
      .where("userId", "==", userId)
      .limit(1)
      .get();

    if (!existingProfile.empty) {
      console.log("✅ Artist profile already exists for this user");
      const profile = existingProfile.docs[0].data();
      console.log("Profile data:", profile);
      return;
    }

    console.log("❌ No artist profile found. Creating test profile...");

    // Get user data first
    const userDoc = await db.collection("users").doc(userId).get();
    let displayName = "Test Artist";
    let bio = "Test artist profile for development";

    if (userDoc.exists) {
      const userData = userDoc.data();
      displayName = userData.fullName || userData.username || displayName;
      console.log(`📋 Using user data: ${displayName}`);
    } else {
      console.log("⚠️ User document not found, using default values");
    }

    // Create artist profile
    const profileRef = db.collection("artistProfiles").doc();

    await profileRef.set({
      userId: userId,
      displayName: displayName,
      bio: bio,
      userType: "artist",
      location: "Test Location",
      mediums: ["Digital Art", "Photography"],
      styles: ["Contemporary", "Abstract"],
      socialLinks: {},
      profileImageUrl: null,
      coverImageUrl: null,
      isVerified: false,
      isFeatured: false,
      followerCount: 0,
      subscriptionTier: "free", // Start with free tier
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`✅ Created artist profile with ID: ${profileRef.id}`);
    console.log("Profile data:", {
      userId,
      displayName,
      bio,
      subscriptionTier: "free",
    });
  } catch (error) {
    console.error("❌ Error:", error);
  }
}

// Run the script
createTestArtistProfile();

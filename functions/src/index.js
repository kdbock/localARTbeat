const {
  onRequest,
  onCall,
  HttpsError,
} = require("firebase-functions/v2/https");
const {logger} = require("firebase-functions");
const {
  onDocumentCreated,
  onDocumentWritten,
} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {setGlobalOptions} = require("firebase-functions/v2");
const admin = require("firebase-admin");
const {defineSecret} = require("firebase-functions/params");
const {BetaAnalyticsDataClient} = require("@google-analytics/data");
const nodemailer = require("nodemailer");
const https = require("https");
const crypto = require("crypto");

// Set global options for all functions
setGlobalOptions({
  maxInstances: 3,
  cpu: 0.25,
  memory: "256MiB",
});

// Define secrets
const stripeSecretKey = defineSecret("STRIPE_SECRET_KEY");
const smtpHostSecret = defineSecret("SMTP_HOST");
const smtpPortSecret = defineSecret("SMTP_PORT");
const smtpUserSecret = defineSecret("SMTP_USER");
const smtpPassSecret = defineSecret("SMTP_PASS");
const ga4PropertyIdSecret = defineSecret("GA4_PROPERTY_ID");

admin.initializeApp();

function normalizeDisplayName(value) {
  return String(value || "").trim().toLowerCase();
}

exports.updateNotificationSummary = onDocumentWritten(
  "users/{userId}/notifications/{notificationId}",
  async (event) => {
    const userId = event.params.userId;
    const userRef = admin.firestore().collection("users").doc(userId);
    const notificationsRef = userRef.collection("notifications");

    try {
      const totalCountPromise = notificationsRef
        .count()
        .get()
        .then((snap) => snap.data().count)
        .catch(async () => {
          const snapshot = await notificationsRef.get();
          return snapshot.size;
        });

      const unreadCountPromise = notificationsRef
        .where("read", "==", false)
        .count()
        .get()
        .then((snap) => snap.data().count)
        .catch(async () => {
          const snapshot = await notificationsRef
            .where("read", "==", false)
            .get();
          return snapshot.size;
        });

      const latestSnapshotPromise = notificationsRef
        .orderBy("createdAt", "desc")
        .limit(1)
        .get();

      const [totalCount, unreadCount, latestSnapshot] = await Promise.all([
        totalCountPromise,
        unreadCountPromise,
        latestSnapshotPromise,
      ]);

      const lastUpdated = latestSnapshot.empty
        ? admin.firestore.FieldValue.serverTimestamp()
        : latestSnapshot.docs[0].get("createdAt") ||
          admin.firestore.FieldValue.serverTimestamp();

      await userRef
        .collection("notification_summary")
        .doc("summary")
        .set(
          {
            totalCount: Number(totalCount || 0),
            unreadCount: Number(unreadCount || 0),
            lastUpdated,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          {merge: true}
        );
    } catch (error) {
      logger.error("Failed to update notification summary", {
        userId,
        error,
      });
    }
  }
);

exports.backfillArtistDisplayNameLower = onRequest(
  {cors: true},
  async (req, res) => {
    try {
      let updated = 0;
      let scanned = 0;
      let lastDoc = null;

      while (true) {
        let query = admin.firestore().collection("artistProfiles").orderBy("__name__").limit(500);
        if (lastDoc) {
          query = query.startAfter(lastDoc);
        }

        const snapshot = await query.get();
        if (snapshot.empty) {
          break;
        }

        const batch = admin.firestore().batch();
        snapshot.docs.forEach((doc) => {
          scanned += 1;
          const data = doc.data() || {};
          const displayName = data.displayName || "";
          const desired = normalizeDisplayName(displayName);
          if (desired && data.displayNameLower !== desired) {
            batch.update(doc.ref, {displayNameLower: desired});
            updated += 1;
          }
        });

        await batch.commit();
        lastDoc = snapshot.docs[snapshot.docs.length - 1];

        if (snapshot.size < 500) {
          break;
        }
      }

      res.json({ok: true, scanned, updated});
    } catch (error) {
      logger.error("Failed backfillArtistDisplayNameLower", {error});
      res.status(500).json({ok: false, error: String(error)});
    }
  }
);

const MOMENTUM_DECAY_RATE_WEEKLY = 0.1;
const WEEKLY_MOMENTUM_THRESHOLD = 300;
const WEEKLY_MOMENTUM_CAP = 600;
const DIMINISHING_MULTIPLIER = 0.5;
const KIOSK_ROTATION_INTERVAL_MINUTES = 60;

function getMomentumForProduct(productId, fallback) {
  if (!productId) return fallback || 0;
  if (productId.includes("spark") || productId.includes("gift_small")) return 50;
  if (productId.includes("surge") || productId.includes("gift_medium")) {
    return 120;
  }
  if (productId.includes("overdrive") || productId.includes("gift_large")) {
    return 350;
  }
  if (productId.includes("gift_premium")) return 500;
  return fallback || 0;
}

function getBoostTitleForProduct(productId) {
  if (!productId) return "Artist Boost";
  if (productId.includes("spark")) return "Spark Boost";
  if (productId.includes("surge")) return "Surge Boost";
  if (productId.includes("overdrive")) return "Overdrive Boost";
  if (productId.includes("gift_small")) return "Quick Spark";
  if (productId.includes("gift_medium")) return "Neon Surge";
  if (productId.includes("gift_large")) return "Titan Overdrive";
  if (productId.includes("gift_premium")) return "Mythic Expansion";
  return "Artist Boost";
}

function getBoostFeaturesForProduct(productId, amount, momentum) {
  const now = admin.firestore.Timestamp.now();
  const features = [];
  if (!productId) return features;

  const addFeature = (type, days) => {
    const endDate = admin.firestore.Timestamp.fromMillis(
      now.toMillis() + days * 24 * 60 * 60 * 1000
    );
    features.push({
      type,
      startDate: now,
      endDate,
      isActive: true,
      metadata: {
        boostPrice: amount || 0,
        momentumGranted: momentum || 0,
        durationDays: days,
      },
    });
  };

  if (productId.includes("spark") || productId.includes("gift_small")) {
    addFeature("artist_featured", 7);
  } else if (productId.includes("surge") || productId.includes("gift_medium")) {
    addFeature("artist_featured", 14);
    addFeature("artwork_featured", 14);
  } else if (
    productId.includes("overdrive") ||
    productId.includes("gift_large")
  ) {
    addFeature("artist_featured", 21);
    addFeature("artwork_featured", 21);
    addFeature("ad_rotation", 14);
  } else if (productId.includes("gift_premium")) {
    addFeature("artist_featured", 365);
    addFeature("artwork_featured", 365);
    addFeature("ad_rotation", 365);
  }

  return features;
}

async function performKioskLaneRotation(reason = "schedule") {
  const now = new Date();
  const nowTimestamp = admin.firestore.Timestamp.fromDate(now);

  const laneSnapshot = await admin
    .firestore()
    .collection("kiosk_lane")
    .where("endAt", ">", nowTimestamp)
    .get();

  if (laneSnapshot.empty) {
    await admin.firestore().collection("kiosk_lane_state").doc("current").set(
      {
        activeArtistId: null,
        index: 0,
        totalActive: 0,
        artistIds: [],
        rotationAt: admin.firestore.FieldValue.serverTimestamp(),
        reason,
      },
      {merge: true}
    );
    return {activeArtistId: null, totalActive: 0, index: 0};
  }

  const laneItems = laneSnapshot.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      artistId: data.artistId || doc.id,
      endAt: data.endAt,
      momentum: Number(data.momentum || 0),
      boostTier: data.boostTier || "boost",
    };
  });

  laneItems.sort((a, b) => {
    const endA = a.endAt?.toMillis?.() || 0;
    const endB = b.endAt?.toMillis?.() || 0;
    if (endB !== endA) return endB - endA;
    return (b.momentum || 0) - (a.momentum || 0);
  });

  const artistIds = laneItems.map((item) => item.artistId);

  const stateRef = admin.firestore().collection("kiosk_lane_state").doc("current");
  const stateSnap = await stateRef.get();
  let index = 0;

  if (stateSnap.exists) {
    const state = stateSnap.data() || {};
    const prevIds = Array.isArray(state.artistIds) ? state.artistIds : [];
    const sameOrder =
      prevIds.length === artistIds.length &&
      prevIds.every((id, idx) => id === artistIds[idx]);
    if (sameOrder && Number.isInteger(state.index)) {
      index = (state.index + 1) % artistIds.length;
    }
  }

  const active = laneItems[index];

  await stateRef.set(
    {
      activeArtistId: active.artistId,
      index,
      totalActive: artistIds.length,
      artistIds,
      rotationAt: admin.firestore.FieldValue.serverTimestamp(),
      reason,
    },
    {merge: true}
  );

  await admin.firestore().collection("kiosk_lane_metrics").add({
    activeArtistId: active.artistId,
    boostTier: active.boostTier,
    index,
    totalActive: artistIds.length,
    artistIds,
    rotationAt: admin.firestore.FieldValue.serverTimestamp(),
    reason,
  });

  return {
    activeArtistId: active.artistId,
    totalActive: artistIds.length,
    index,
  };
}

function getBoostTierConfig(productId) {
  if (!productId) return null;
  if (productId.includes("spark") || productId.includes("gift_small")) {
    return {tier: "spark", mapGlowDays: 0, kioskDays: 0, earlyAccessDays: 7};
  }
  if (productId.includes("surge") || productId.includes("gift_medium")) {
    return {tier: "surge", mapGlowDays: 14, kioskDays: 0, earlyAccessDays: 14};
  }
  if (productId.includes("overdrive") || productId.includes("gift_large")) {
    return {tier: "overdrive", mapGlowDays: 14, kioskDays: 21, earlyAccessDays: 21};
  }
  if (productId.includes("gift_premium")) {
    return {tier: "premium", mapGlowDays: 365, kioskDays: 365, earlyAccessDays: 30};
  }
  return null;
}

/**
 * Helper to record artist earnings and transactions
 * @param {string} artistId - The artist's UID
 * @param {string} type - 'boost', 'sponsorship', 'commission', 'subscription', 'artwork_sale'
 * @param {number} amount - The amount earned by the artist
 * @param {string} fromUserId - The UID of the user who paid
 * @param {string} fromUserName - The name of the user who paid
 * @param {string} description - Description of the transaction
 * @param {Object} metadata - Additional metadata
 * @return {Promise<void>}
 */
async function recordArtistEarnings(
  artistId,
  type,
  amount,
  fromUserId,
  fromUserName,
  description,
  metadata = {},
  isPending = false
) {
  try {
    const firestore = admin.firestore();
    const now = admin.firestore.FieldValue.serverTimestamp();
    const currentMonth = (new Date().getMonth() + 1).toString();

    // 1. Create transaction record
    const transactionRef = firestore.collection("earnings_transactions").doc();
    const transactionData = {
      artistId,
      type,
      amount,
      fromUserId,
      fromUserName,
      timestamp: now,
      status: isPending ? "pending" : "completed",
      description,
      metadata,
    };
    await transactionRef.set(transactionData);

    // 2. Update artist earnings summary
    const earningsRef = firestore.collection("artist_earnings").doc(artistId);

    await firestore.runTransaction(async (transaction) => {
      const earningsDoc = await transaction.get(earningsRef);

      if (!earningsDoc.exists) {
        // Create initial record
        const initialEarnings = {
          artistId,
          totalEarnings: amount,
          availableBalance: isPending ? 0.0 : amount,
          pendingBalance: isPending ? amount : 0.0,
          boostEarnings:
            type === "boost" || type === "gift" ? amount : 0.0,
          sponsorshipEarnings: type === "sponsorship" ? amount : 0.0,
          commissionEarnings: type === "commission" ? amount : 0.0,
          subscriptionEarnings: type === "subscription" ? amount : 0.0,
          artworkSalesEarnings: type === "artwork_sale" ? amount : 0.0,
          ticketSalesEarnings: type === "ticket_sale" ? amount : 0.0,
          adEarnings: type === "ad" ? amount : 0.0,
          lastUpdated: now,
          monthlyBreakdown: {[currentMonth]: amount},
          recentTransactions: [
            {
              id: transactionRef.id,
              ...transactionData,
              timestamp: new Date(),
            },
          ],
        };
        transaction.set(earningsRef, initialEarnings);
      } else {
        const data = earningsDoc.data();
        const monthlyBreakdown = data.monthlyBreakdown || {};
        monthlyBreakdown[currentMonth] =
          (monthlyBreakdown[currentMonth] || 0) + amount;

        const updates = {
          totalEarnings: admin.firestore.FieldValue.increment(amount),
          lastUpdated: now,
          monthlyBreakdown,
        };

        if (isPending) {
          updates.pendingBalance = admin.firestore.FieldValue.increment(amount);
        } else {
          updates.availableBalance = admin.firestore.FieldValue.increment(amount);
        }

        // Update specific earning type
        if (type === "boost" || type === "gift") {
          updates.boostEarnings = admin.firestore.FieldValue.increment(amount);
        } else if (type === "sponsorship") {
          updates.sponsorshipEarnings = admin.firestore.FieldValue.increment(amount);
        } else if (type === "commission") {
          updates.commissionEarnings = admin.firestore.FieldValue.increment(amount);
        } else if (type === "subscription") {
          updates.subscriptionEarnings = admin.firestore.FieldValue.increment(amount);
        } else if (type === "artwork_sale") {
          updates.artworkSalesEarnings = admin.firestore.FieldValue.increment(amount);
        } else if (type === "ticket_sale") {
          updates.ticketSalesEarnings = admin.firestore.FieldValue.increment(amount);
        } else if (type === "ad") {
          updates.adEarnings = admin.firestore.FieldValue.increment(amount);
        }

        transaction.update(earningsRef, updates);
      }
    });

    console.log(`✅ Earnings recorded for artist ${artistId}: $${amount} (${type}) ${isPending ? "(PENDING)" : ""}`);
  } catch (error) {
    console.error("❌ Error recording artist earnings:", error);
  }
}

async function updateArtistProfileBoostFields(recipientId, fields) {
  const profilesQuery = await admin
    .firestore()
    .collection("artistProfiles")
    .where("userId", "==", recipientId)
    .limit(1)
    .get();

  if (!profilesQuery.empty) {
    await profilesQuery.docs[0].ref.set(fields, {merge: true});
    return;
  }

  const directRef = admin.firestore().collection("artistProfiles").doc(recipientId);
  const directSnap = await directRef.get();
  if (directSnap.exists) {
    await directRef.set(fields, {merge: true});
  }
}
async function applyMomentumTransaction(
  recipientId,
  momentum,
  eventTime = new Date()
) {
  const momentumRef = admin.firestore().collection("artist_momentum").doc(
    recipientId
  );
  const userRef = admin.firestore().collection("users").doc(recipientId);

  const result = await admin.firestore().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(momentumRef);

    let currentMomentum = 0;
    let weeklyMomentum = 0;
    let lastUpdated = eventTime;
    let weekStart = eventTime;
    let boostStreakMonths = 0;
    let boostStreakMonthKey = null;
    let streakIncremented = false;

    if (snapshot.exists) {
      const momentumData = snapshot.data() || {};
      currentMomentum = Number(momentumData.momentum || 0);
      weeklyMomentum = Number(momentumData.weeklyMomentum || 0);
      lastUpdated = momentumData.momentumLastUpdated ?
        momentumData.momentumLastUpdated.toDate() :
        eventTime;
      weekStart = momentumData.weeklyWindowStart ?
        momentumData.weeklyWindowStart.toDate() :
        eventTime;
      boostStreakMonths = Number(momentumData.boostStreakMonths || 0);
      boostStreakMonthKey = momentumData.boostStreakMonthKey || null;
    }

    const elapsedWeeks =
      (eventTime.getTime() - lastUpdated.getTime()) /
      (7 * 24 * 60 * 60 * 1000);
    if (elapsedWeeks > 0) {
      currentMomentum =
        currentMomentum *
        Math.pow(1 - MOMENTUM_DECAY_RATE_WEEKLY, elapsedWeeks);
    }

    if (
      (eventTime.getTime() - weekStart.getTime()) / (24 * 60 * 60 * 1000) >= 7
    ) {
      weeklyMomentum = 0;
      weekStart = eventTime;
    }

    let effectiveAdd = momentum;

    if (weeklyMomentum >= WEEKLY_MOMENTUM_THRESHOLD) {
      effectiveAdd = momentum * DIMINISHING_MULTIPLIER;
    } else if (weeklyMomentum + momentum > WEEKLY_MOMENTUM_THRESHOLD) {
      const fullRateAmount = WEEKLY_MOMENTUM_THRESHOLD - weeklyMomentum;
      const diminishedAmount = momentum - fullRateAmount;
      effectiveAdd = fullRateAmount + diminishedAmount * DIMINISHING_MULTIPLIER;
    }

    const remainingCap = WEEKLY_MOMENTUM_CAP - weeklyMomentum;
    if (remainingCap <= 0) {
      effectiveAdd = 0;
    } else if (effectiveAdd > remainingCap) {
      effectiveAdd = remainingCap;
    }

    const newWeeklyMomentum = weeklyMomentum + effectiveAdd;
    const newMomentum = currentMomentum + effectiveAdd;

    const currentMonthKey = `${eventTime.getUTCFullYear()}-${String(
      eventTime.getUTCMonth() + 1
    ).padStart(2, "0")}`;
    if (boostStreakMonthKey) {
      const [lastYear, lastMonth] = boostStreakMonthKey.split("-").map(Number);
      const lastIndex = lastYear * 12 + (lastMonth - 1);
      const currentIndex =
        eventTime.getUTCFullYear() * 12 + eventTime.getUTCMonth();
      const diff = currentIndex - lastIndex;
      if (diff === 0) {
        boostStreakMonths = Math.max(boostStreakMonths, 1);
      } else if (diff === 1) {
        boostStreakMonths = Math.max(boostStreakMonths, 1) + 1;
        streakIncremented = true;
      } else {
        boostStreakMonths = 1;
      }
    } else {
      boostStreakMonths = 1;
    }
    boostStreakMonthKey = currentMonthKey;

    transaction.set(
      momentumRef,
      {
        momentum: newMomentum,
        weeklyMomentum: newWeeklyMomentum,
        weeklyWindowStart: admin.firestore.Timestamp.fromDate(weekStart),
        momentumLastUpdated: admin.firestore.Timestamp.fromDate(eventTime),
        lastBoostAt: admin.firestore.Timestamp.fromDate(eventTime),
        boostStreakMonths,
        boostStreakMonthKey,
        boostStreakUpdatedAt: admin.firestore.Timestamp.fromDate(eventTime),
        lifetimeMomentum: admin.firestore.FieldValue.increment(effectiveAdd),
      },
      {merge: true}
    );

    transaction.set(
      userRef,
      {
        artistMomentum: newMomentum,
        artistMomentumUpdatedAt: admin.firestore.Timestamp.fromDate(eventTime),
        artistMomentumWeekly: newWeeklyMomentum,
        artistMomentumWeekStart: admin.firestore.Timestamp.fromDate(weekStart),
        artistBoostStreakMonths: boostStreakMonths,
        artistBoostStreakUpdatedAt: admin.firestore.Timestamp.fromDate(eventTime),
        artistXP: admin.firestore.FieldValue.increment(momentum),
        totalXPReceived: admin.firestore.FieldValue.increment(momentum),
      },
      {merge: true}
    );

    return {
      momentum: newMomentum,
      weeklyMomentum: newWeeklyMomentum,
      boostStreakMonths,
      boostStreakMonthKey,
      streakIncremented,
    };
  });

  return result;
}

/**
 * Fix leaderboard data - one-time maintenance function
 */
exports.fixLeaderboardData = onRequest(
  {
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 2,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🔧 Starting leaderboard data fix...");

        // Get all users
        const usersSnapshot = await admin.firestore().collection("users").get();
        console.log(`📊 Found ${usersSnapshot.docs.length} users to process`);

        let usersUpdated = 0;
        let capturesProcessed = 0;
        let artWalksProcessed = 0;

        for (const userDoc of usersSnapshot.docs) {
          const userId = userDoc.id;
          const userData = userDoc.data();

          console.log(
            `\n👤 Processing user: ${
              userData.fullName || userData.username || userId
            }`
          );

          // Initialize stats if missing
          const stats = userData.stats || {};
          let needsUpdate = false;
          const updates = {};

          // Fix captures data
          const captures = userData.captures || [];
          if (captures.length > 0) {
            console.log(`   📸 Found ${captures.length} captures`);

            // Count approved captures
            let approvedCount = 0;
            const createdCount = captures.length;

            for (const capture of captures) {
              if (capture && capture.status === "approved") {
                approvedCount++;
              }
            }

            // Update stats
            if (stats.capturesCreated !== createdCount) {
              updates["stats.capturesCreated"] = createdCount;
              needsUpdate = true;
              console.log(`   ✅ Setting capturesCreated: ${createdCount}`);
            }

            if (stats.capturesApproved !== approvedCount) {
              updates["stats.capturesApproved"] = approvedCount;
              needsUpdate = true;
              console.log(`   ✅ Setting capturesApproved: ${approvedCount}`);
            }

            capturesProcessed += captures.length;
          } else {
          // Ensure zero values for users with no captures
            if (stats.capturesCreated == null) {
              updates["stats.capturesCreated"] = 0;
              needsUpdate = true;
            }
            if (stats.capturesApproved == null) {
              updates["stats.capturesApproved"] = 0;
              needsUpdate = true;
            }
          }

          // Fix art walks data
          const artWalksSnapshot = await admin
            .firestore()
            .collection("artWalks")
            .where("userId", "==", userId)
            .get();

          if (!artWalksSnapshot.empty) {
            const walksCreated = artWalksSnapshot.docs.length;
            console.log(`   🎨 Found ${walksCreated} art walks created`);

            if (stats.walksCreated !== walksCreated) {
              updates["stats.walksCreated"] = walksCreated;
              needsUpdate = true;
              console.log(`   ✅ Setting walksCreated: ${walksCreated}`);
            }

            artWalksProcessed += walksCreated;
          } else {
          // Ensure zero value for users with no art walks
            if (stats.walksCreated == null) {
              updates["stats.walksCreated"] = 0;
              needsUpdate = true;
            }
          }

          // Initialize other missing stats
          if (stats.walksCompleted == null) {
            updates["stats.walksCompleted"] = 0;
            needsUpdate = true;
          }
          if (stats.reviewsSubmitted == null) {
            updates["stats.reviewsSubmitted"] = 0;
            needsUpdate = true;
          }
          if (stats.helpfulVotes == null) {
            updates["stats.helpfulVotes"] = 0;
            needsUpdate = true;
          }
          if (stats.highestRatedCapture == null) {
            updates["stats.highestRatedCapture"] = 0;
            needsUpdate = true;
          }
          if (stats.highestRatedArtWalk == null) {
            updates["stats.highestRatedArtWalk"] = 0;
            needsUpdate = true;
          }

          // Calculate expected XP
          const currentXP = userData.experiencePoints || 0;
          const capturesCreated =
          (stats.capturesCreated || 0) +
          (updates["stats.capturesCreated"] || 0);
          const capturesApproved =
          (stats.capturesApproved || 0) +
          (updates["stats.capturesApproved"] || 0);
          const walksCreated =
          (stats.walksCreated || 0) + (updates["stats.walksCreated"] || 0);
          const walksCompleted = stats.walksCompleted || 0;

          let expectedXP = 0;
          expectedXP += capturesCreated * 25; // 25 XP per capture created
          expectedXP += capturesApproved * 25; // Additional 25 XP when approved
          expectedXP += walksCreated * 75; // 75 XP per art walk created
          expectedXP += walksCompleted * 100; // 100 XP per art walk completed

          if (currentXP !== expectedXP) {
            updates.experiencePoints = expectedXP;
            needsUpdate = true;
            console.log(`   ⚡ Updating XP: ${currentXP} → ${expectedXP}`);

            // Recalculate level
            const newLevel = calculateLevel(expectedXP);
            const currentLevel = userData.level || 1;
            if (newLevel !== currentLevel) {
              updates.level = newLevel;
              console.log(`   👑 Updating level: ${currentLevel} → ${newLevel}`);
            }
          }

          // Apply updates if needed
          if (needsUpdate) {
            await admin
              .firestore()
              .collection("users")
              .doc(userId)
              .update(updates);
            usersUpdated++;
            console.log("   ✅ User updated successfully");
          } else {
            console.log("   ℹ️  No updates needed");
          }
        }

        const summary = {
          success: true,
          usersProcessed: usersSnapshot.docs.length,
          usersUpdated: usersUpdated,
          capturesProcessed: capturesProcessed,
          artWalksProcessed: artWalksProcessed,
        };

        console.log("\n🎉 Leaderboard data fix completed!");
        console.log("📊 Summary:", summary);

        response.status(200).send(summary);
      } catch (error) {
        console.error("❌ Error fixing leaderboard data:", error);
        response.status(500).send({error: error.message});
      }
    });
  });

/**
 * Fix specific user's data by name
 */
exports.fixUserData = onRequest(
  {
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 2,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        const userName = request.body?.name || request.query?.name || "Izzy Piel";
        console.log(`🔧 Starting data fix for: ${userName}`);

        // Find user by name
        const usersSnapshot = await admin
          .firestore()
          .collection("users")
          .where("fullName", "==", userName)
          .get();

        if (usersSnapshot.empty) {
          console.log(`❌ ${userName} not found`);
          return response.status(404).send({error: `${userName} not found`});
        }

        const userDoc = usersSnapshot.docs[0];
        const userId = userDoc.id;
        const userData = userDoc.data();

        console.log(`👤 Found ${userName}: ${userId}`);
        console.log("📊 Current data:", {
          experiencePoints: userData.experiencePoints || 0,
          level: userData.level || 1,
          stats: userData.stats || {},
        });

        // Check captures in the captures collection
        const capturesSnapshot = await admin
          .firestore()
          .collection("captures")
          .where("userId", "==", userId)
          .get();

        const captureCount = capturesSnapshot.docs.length;
        console.log(`📸 Found ${captureCount} captures in captures collection`);

        // Count approved captures
        let approvedCount = 0;
        const createdCount = capturesSnapshot.docs.length;

        for (const captureDoc of capturesSnapshot.docs) {
          const captureData = captureDoc.data();
          if (captureData.status === "approved") {
            approvedCount++;
            console.log(`   ✅ Approved capture: ${captureDoc.id}`);
          }
          console.log(
            `   📸 Capture ${captureDoc.id}: status=${captureData.status}`
          );
        }

        console.log(
          `📊 Total captures: ${createdCount}, Approved: ${approvedCount}`
        );

        // Calculate expected stats and XP
        const expectedStats = {
          capturesCreated: createdCount,
          capturesApproved: approvedCount,
          walksCreated: 0,
          walksCompleted: 0,
          reviewsSubmitted: 0,
          helpfulVotes: 0,
          highestRatedCapture: 0,
          highestRatedArtWalk: 0,
        };

        const expectedXP = createdCount * 25 + approvedCount * 25;
        const expectedLevel = calculateLevel(expectedXP);

        console.log("📊 Expected stats:", expectedStats);
        console.log(`⚡ Expected XP: ${expectedXP}`);
        console.log(`👑 Expected level: ${expectedLevel}`);

        // Update Julie's document
        const updates = {
          stats: expectedStats,
          experiencePoints: expectedXP,
          level: expectedLevel,
        };

        await admin.firestore().collection("users").doc(userId).update(updates);

        const summary = {
          success: true,
          userId: userId,
          userName: userName,
          capturesCreated: expectedStats.capturesCreated,
          capturesApproved: expectedStats.capturesApproved,
          experiencePoints: expectedXP,
          level: expectedLevel,
        };

        console.log(`✅ ${userName} data updated successfully!`);
        console.log("📊 Summary:", summary);

        response.status(200).send(summary);
      } catch (error) {
        console.error("❌ Error fixing Julie data:", error);
        response.status(500).send({error: error.message});
      }
    });
  });

/**
 * Apply boost momentum + features server-side when a boost is completed.
 * Clients should only write boost events.
 */
exports.applyBoostMomentum = onDocumentCreated(
  {
    document: "boosts/{boostId}",
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 5,
  },
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    if (data.status && data.status !== "completed") return;

    const recipientId = data.recipientId;
    const senderId = data.senderId;
    const productId = data.productId;
    const amount = Number(data.amount || 0);
    const message = data.message || null;

    if (!recipientId || !senderId) return;

    const momentum =
      Number(data.momentum || data.momentumAmount || 0) ||
      getMomentumForProduct(productId, 0);

    const now = new Date();
    const momentumResult = await applyMomentumTransaction(
      recipientId,
      momentum,
      now
    );

    const boostTitle = getBoostTitleForProduct(productId);
    const features = getBoostFeaturesForProduct(productId, amount, momentum);
    const featureWrites = features.map((feature) =>
      admin.firestore().collection("artist_features").add({
        artistId: recipientId,
        boostId: productId || "boost",
        purchaserId: senderId,
        type: feature.type,
        startDate: feature.startDate,
        endDate: feature.endDate,
        isActive: true,
        metadata: feature.metadata,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      })
    );

    await Promise.all(featureWrites);

    const momentumSnapshot = await admin
      .firestore()
      .collection("artist_momentum")
      .doc(recipientId)
      .get();
    const momentumData = momentumSnapshot.exists ? momentumSnapshot.data() : {};

    const tierConfig = getBoostTierConfig(productId);
    const mapGlowUntil = tierConfig?.mapGlowDays ?
      admin.firestore.Timestamp.fromMillis(
        now.getTime() + tierConfig.mapGlowDays * 24 * 60 * 60 * 1000
      ) :
      null;
    const kioskLaneUntil = tierConfig?.kioskDays ?
      admin.firestore.Timestamp.fromMillis(
        now.getTime() + tierConfig.kioskDays * 24 * 60 * 60 * 1000
      ) :
      null;

    await updateArtistProfileBoostFields(recipientId, {
      boostScore: Number(momentumData?.momentum || 0),
      lastBoostAt: admin.firestore.Timestamp.fromDate(now),
      weeklyBoostMomentum: Number(momentumData?.weeklyMomentum || 0),
      boostMomentumUpdatedAt: admin.firestore.Timestamp.fromDate(now),
      boostStreakMonths: momentumResult?.boostStreakMonths || 0,
      boostStreakUpdatedAt: admin.firestore.Timestamp.fromDate(now),
      mapGlowUntil,
      kioskLaneUntil,
      boostTier: tierConfig?.tier || "boost",
    });

    if (kioskLaneUntil) {
      await admin
        .firestore()
        .collection("kiosk_lane")
        .doc(recipientId)
        .set(
          {
            artistId: recipientId,
            boostTier: tierConfig?.tier || "boost",
            startAt: admin.firestore.Timestamp.fromDate(now),
            endAt: kioskLaneUntil,
            momentum,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
          {merge: true}
        );
    }

    const supporterTier = tierConfig?.tier || "boost";
    await admin.firestore().collection("users").doc(senderId).set(
      {
        collectorXP: admin.firestore.FieldValue.increment(momentum),
        collectorXPUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      {merge: true}
    );

    await admin
      .firestore()
      .collection("artist_boosters")
      .doc(recipientId)
      .collection("boosters")
      .doc(senderId)
      .set(
        {
          boosterId: senderId,
          artistId: recipientId,
          tier: supporterTier,
          lastBoostAt: admin.firestore.Timestamp.fromDate(now),
          boostCount: admin.firestore.FieldValue.increment(1),
          earlyAccessTier: supporterTier,
          earlyAccessGrantedAt: admin.firestore.Timestamp.fromDate(now),
          earlyAccessUntil: tierConfig?.earlyAccessDays ?
            admin.firestore.Timestamp.fromMillis(
              now.getTime() + tierConfig.earlyAccessDays * 24 * 60 * 60 * 1000
            ) :
            null,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        {merge: true}
      );

    await admin
      .firestore()
      .collection("users")
      .doc(senderId)
      .collection("boost_badges")
      .doc(`${recipientId}_${supporterTier}`)
      .set(
        {
          artistId: recipientId,
          tier: supporterTier,
          awardedAt: admin.firestore.Timestamp.fromDate(now),
          momentum,
        },
        {merge: true}
      );

    const senderDoc = await admin.firestore().collection("users").doc(senderId).get();
    const senderName = senderDoc.exists ?
      senderDoc.data().displayName || senderDoc.data().username || "A Fan" :
      "A Fan";

    await admin.firestore().collection("notifications").add({
      userId: recipientId,
      type: "boost_received",
      title: "Momentum Boost Activated",
      body: `${senderName} fueled ${boostTitle} for you!`,
      data: {
        senderId,
        senderName,
        boostType: boostTitle,
        amount,
        momentum,
        message,
      },
      read: false,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    if (momentumResult?.streakIncremented) {
      await admin.firestore().collection("notifications").add({
        userId: recipientId,
        type: "boost_streak",
        title: "Boost Streak Active",
        body: `You're on a ${momentumResult.boostStreakMonths}-month boost streak!`,
        data: {
          boostStreakMonths: momentumResult.boostStreakMonths,
        },
        read: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    await event.data.ref.update({
      momentumAppliedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
);

/**
 * Scheduled decay enforcement for artist momentum + profile sync.
 */
exports.decayArtistMomentum = onSchedule(
  {
    schedule: "every 24 hours",
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 2,
  },
  async () => {
    const momentumSnapshot = await admin.firestore().collection("artist_momentum").get();
    if (momentumSnapshot.empty) return;

    const now = new Date();
    let batch = admin.firestore().batch();
    let batchCount = 0;

    const commitBatch = async () => {
      if (batchCount === 0) return;
      await batch.commit();
      batch = admin.firestore().batch();
      batchCount = 0;
    };

    for (const doc of momentumSnapshot.docs) {
      const data = doc.data() || {};
      let currentMomentum = Number(data.momentum || 0);
      let weeklyMomentum = Number(data.weeklyMomentum || 0);
      const lastUpdated = data.momentumLastUpdated ?
        data.momentumLastUpdated.toDate() :
        now;
      let weekStart = data.weeklyWindowStart ?
        data.weeklyWindowStart.toDate() :
        now;

      const elapsedWeeks =
      (now.getTime() - lastUpdated.getTime()) / (7 * 24 * 60 * 60 * 1000);
      if (elapsedWeeks > 0) {
        currentMomentum =
        currentMomentum *
        Math.pow(1 - MOMENTUM_DECAY_RATE_WEEKLY, elapsedWeeks);
      }

      if ((now.getTime() - weekStart.getTime()) / (24 * 60 * 60 * 1000) >= 7) {
        weeklyMomentum = 0;
        weekStart = now;
      }

      batch.set(
        doc.ref,
        {
          momentum: currentMomentum,
          weeklyMomentum,
          weeklyWindowStart: admin.firestore.Timestamp.fromDate(weekStart),
          momentumLastUpdated: admin.firestore.Timestamp.fromDate(now),
        },
        {merge: true}
      );
      batchCount += 1;

      const userRef = admin.firestore().collection("users").doc(doc.id);
      batch.set(
        userRef,
        {
          artistMomentum: currentMomentum,
          artistMomentumUpdatedAt: admin.firestore.Timestamp.fromDate(now),
          artistMomentumWeekly: weeklyMomentum,
          artistMomentumWeekStart: admin.firestore.Timestamp.fromDate(weekStart),
        },
        {merge: true}
      );
      batchCount += 1;

      if (batchCount >= 400) {
        await commitBatch();
      }

      await updateArtistProfileBoostFields(doc.id, {
        boostScore: currentMomentum,
        boostMomentumUpdatedAt: admin.firestore.Timestamp.fromDate(now),
        weeklyBoostMomentum: weeklyMomentum,
      });
    }

    await commitBatch();
  });

exports.rotateKioskLane = onSchedule(
  {
    schedule: `every ${KIOSK_ROTATION_INTERVAL_MINUTES} minutes`,
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 2,
  },
  async () => {
    await performKioskLaneRotation("schedule");
  }
);

exports.sendDailyAnalyticsReport = onSchedule(
  {
    schedule: "every day 08:00",
    timeZone: "UTC",
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 1,
    secrets: [
      smtpHostSecret,
      smtpPortSecret,
      smtpUserSecret,
      smtpPassSecret,
      stripeSecretKey,
      ga4PropertyIdSecret,
    ],
  },
  async () => {
    await sendDailyAnalyticsReportInternal();
  }
);

exports.sendDailyAnalyticsReportNow = onRequest(
  {
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 1,
    secrets: [
      smtpHostSecret,
      smtpPortSecret,
      smtpUserSecret,
      smtpPassSecret,
      stripeSecretKey,
      ga4PropertyIdSecret,
    ],
  },
  async (request, response) => {
    try {
      const result = await sendDailyAnalyticsReportInternal();
      return response.status(200).json({ok: true, ...result});
    } catch (error) {
      logger.error("Failed manual analytics report", {error});
      if (response.headersSent) {
        return;
      }
      return response.status(500).json({ok: false, error: String(error)});
    }
  }
);

async function sendDailyAnalyticsReportInternal() {
  const reportDate = new Date();
  const endUtc = new Date(
    Date.UTC(
      reportDate.getUTCFullYear(),
      reportDate.getUTCMonth(),
      reportDate.getUTCDate(),
      0,
      0,
      0
    )
  );
  const startUtc = new Date(
    Date.UTC(
      reportDate.getUTCFullYear(),
      reportDate.getUTCMonth(),
      reportDate.getUTCDate() - 1,
      0,
      0,
      0
    )
  );

  const startTimestamp = admin.firestore.Timestamp.fromDate(startUtc);
  const endTimestamp = admin.firestore.Timestamp.fromDate(endUtc);

  const ga4PropertyId = ga4PropertyIdSecret.value();
  let dau = null;
  let wau = null;
  let mau = null;
  let newUsers = null;

  if (ga4PropertyId) {
    try {
      const analyticsClient = new BetaAnalyticsDataClient();
      const runMetricReport = async (metricName, startDate, endDate) => {
        const [response] = await analyticsClient.runReport({
          property: `properties/${ga4PropertyId}`,
          dateRanges: [{startDate, endDate}],
          metrics: [{name: metricName}],
        });
        const value = response.rows?.[0]?.metricValues?.[0]?.value;
        return Number(value || 0);
      };

      dau = await runMetricReport("activeUsers", "yesterday", "yesterday");
      wau = await runMetricReport("activeUsers", "7daysAgo", "yesterday");
      mau = await runMetricReport("activeUsers", "30daysAgo", "yesterday");
      newUsers = await runMetricReport("newUsers", "yesterday", "yesterday");
    } catch (error) {
      logger.error("Failed to fetch GA4 active users", {error});
    }
  } else {
    logger.warn("GA4_PROPERTY_ID not configured. Skipping GA4 metrics.");
  }

  const countCollectionInRange = async (collectionName) => {
    try {
      const snapshot = await admin
        .firestore()
        .collection(collectionName)
        .where("createdAt", ">=", startTimestamp)
        .where("createdAt", "<", endTimestamp)
        .count()
        .get();
      return Number(snapshot.data().count || 0);
    } catch (error) {
      logger.error("Failed counting collection", {collectionName, error});
      return null;
    }
  };

  const [capturesAdded, artworkAdded] = await Promise.all([
    countCollectionInRange("captures"),
    countCollectionInRange("artwork"),
  ]);

  const stripeMetrics = await getStripeMetrics(startUtc, endUtc);
  const iapMetrics = await getIapMetrics(startTimestamp, endTimestamp);
  const subscriptionMetrics = await getSubscriptionMetrics(
    startTimestamp,
    endTimestamp
  );

  const currency =
    process.env.REPORT_CURRENCY ||
    stripeMetrics.currency ||
    iapMetrics.currency ||
    "USD";

  const totalGross = stripeMetrics.gross + iapMetrics.gross;
  const totalNet = stripeMetrics.net + iapMetrics.net;
  const totalRefunds = stripeMetrics.refunds + iapMetrics.refunds;

  const reportLines = [
    `ARTbeat Daily Analytics Report (UTC)`,
    `Date: ${startUtc.toISOString().slice(0, 10)}`,
    "",
    "USERS",
    `DAU: ${dau ?? "N/A"}`,
    `WAU: ${wau ?? "N/A"}`,
    `MAU: ${mau ?? "N/A"}`,
    `New Users: ${newUsers ?? "N/A"}`,
    "",
    "REVENUE",
    `Total Gross: ${formatCurrency(totalGross, currency)}`,
    `Total Net: ${formatCurrency(totalNet, currency)}`,
    `Total Refunds: ${formatCurrency(totalRefunds, currency)}`,
    "",
    `Stripe Gross: ${formatCurrency(stripeMetrics.gross, currency)}`,
    `Stripe Net: ${formatCurrency(stripeMetrics.net, currency)}`,
    `Stripe Fees: ${formatCurrency(stripeMetrics.fees, currency)}`,
    `Stripe Refunds: ${formatCurrency(stripeMetrics.refunds, currency)}`,
    "",
    `IAP Gross: ${formatCurrency(iapMetrics.gross, currency)}`,
    `IAP Net (rate ${iapMetrics.netRate}): ${formatCurrency(
      iapMetrics.net,
      currency
    )}`,
    `IAP Refunds: ${formatCurrency(iapMetrics.refunds, currency)}`,
    "",
    "SUBSCRIPTIONS",
    `Active Subscriptions: ${subscriptionMetrics.active}`,
    `New Subscriptions: ${subscriptionMetrics.new}`,
    `Churn (approx): ${formatPercent(subscriptionMetrics.churnRate)}`,
    "",
    "CONTENT",
    `Captures added: ${capturesAdded ?? "N/A"}`,
    `Artwork added: ${artworkAdded ?? "N/A"}`,
  ];

  const smtpHost = smtpHostSecret.value();
  const smtpPort = Number(smtpPortSecret.value() || 465);
  const smtpUser = smtpUserSecret.value();
  const smtpPass = smtpPassSecret.value();

  const toEmail = process.env.REPORT_EMAIL_TO || "info@localartbeat.com";
  const fromEmail = process.env.REPORT_EMAIL_FROM || smtpUser;

  const transporter = nodemailer.createTransport({
    host: smtpHost,
    port: smtpPort,
    secure: smtpPort === 465,
    auth: {
      user: smtpUser,
      pass: smtpPass,
    },
  });

  const html = buildDailyReportHtml({
    date: startUtc.toISOString().slice(0, 10),
    dau,
    wau,
    mau,
    newUsers,
    capturesAdded,
    artworkAdded,
    currency,
    stripeMetrics,
    iapMetrics,
    totalGross,
    totalNet,
    totalRefunds,
    subscriptionMetrics,
  });

  await transporter.sendMail({
    to: toEmail,
    from: fromEmail,
    subject: `ARTbeat Daily Report — ${startUtc.toISOString().slice(0, 10)}`,
    text: reportLines.join("\n"),
    html,
  });

  return {
    date: startUtc.toISOString().slice(0, 10),
    dau,
    wau,
    mau,
    newUsers,
    capturesAdded,
    artworkAdded,
    stripeMetrics,
    iapMetrics,
    subscriptionMetrics,
    totalGross,
    totalNet,
    totalRefunds,
  };
}

function formatCurrency(amount, currency) {
  const safeAmount = Number(amount || 0);
  try {
    return new Intl.NumberFormat("en-US", {
      style: "currency",
      currency: currency || "USD",
      maximumFractionDigits: 2,
    }).format(safeAmount);
  } catch (_) {
    return `${(safeAmount || 0).toFixed(2)} ${currency || "USD"}`;
  }
}

function formatPercent(value) {
  if (value == null || Number.isNaN(value)) return "N/A";
  return `${(Number(value) * 100).toFixed(1)}%`;
}

async function getStripeMetrics(startUtc, endUtc) {
  try {
    const stripe = require("stripe")(stripeSecretKey.value());
    const created = {
      gte: Math.floor(startUtc.getTime() / 1000),
      lt: Math.floor(endUtc.getTime() / 1000),
    };

    let gross = 0;
    let net = 0;
    let fees = 0;
    let refunds = 0;
    let currency = null;

    const list = stripe.balanceTransactions.list({
      created,
      limit: 100,
    });

    for await (const tx of list.autoPagingIterable()) {
      if (!currency && tx.currency) currency = tx.currency.toUpperCase();
      if (tx.type === "charge" || tx.type === "payment") {
        gross += tx.amount || 0;
      }
      if (tx.type === "refund") {
        refunds += Math.abs(tx.amount || 0);
      }
      net += tx.net || 0;
      fees += tx.fee || 0;
    }

    return {
      gross: gross / 100,
      net: net / 100,
      fees: fees / 100,
      refunds: refunds / 100,
      currency,
    };
  } catch (error) {
    logger.error("Failed to fetch Stripe metrics", {error});
    return {gross: 0, net: 0, fees: 0, refunds: 0, currency: null};
  }
}

async function getIapMetrics(startTimestamp, endTimestamp) {
  const netRate = Number(process.env.IAP_NET_RATE || "0.70");
  try {
    const snapshot = await admin
      .firestore()
      .collection("purchases")
      .where("purchaseDate", ">=", startTimestamp)
      .where("purchaseDate", "<", endTimestamp)
      .get();

    let gross = 0;
    let refunds = 0;
    let currency = null;

    snapshot.docs.forEach((doc) => {
      const data = doc.data() || {};
      const amount = Number(data.amount || 0);
      const status = String(data.status || "completed").toLowerCase();
      if (!currency && data.currency) currency = String(data.currency).toUpperCase();

      if (status === "refunded" || status === "refund") {
        refunds += amount;
      } else {
        gross += amount;
      }
    });

    const net = (gross - refunds) * netRate;

    return {
      gross,
      net,
      refunds,
      netRate,
      currency,
    };
  } catch (error) {
    logger.error("Failed to fetch IAP metrics", {error});
    return {gross: 0, net: 0, refunds: 0, netRate, currency: null};
  }
}

async function getSubscriptionMetrics(startTimestamp, endTimestamp) {
  const subscriptionsRef = admin.firestore().collection("subscriptions");
  const nowTimestamp = admin.firestore.Timestamp.now();

  const countQuery = async (query) => {
    try {
      const snapshot = await query.count().get();
      return Number(snapshot.data().count || 0);
    } catch (error) {
      logger.warn("Count query failed, falling back to get()", {error});
      const snapshot = await query.get();
      return snapshot.size;
    }
  };

  let activeStripe = 0;
  let activeIap = 0;
  let newStripe = 0;
  let newIap = 0;
  let churnedStripe = 0;
  let churnedIap = 0;
  let activeAtStart = 0;

  try {
    activeStripe = await countQuery(
      subscriptionsRef.where("isActive", "==", true)
    );
  } catch (error) {
    logger.warn("Active Stripe subscriptions query failed", {error});
  }

  try {
    const activeIapQuery = subscriptionsRef
      .where("status", "==", "active")
      .where("endDate", ">=", nowTimestamp);
    activeIap = await countQuery(activeIapQuery);
  } catch (error) {
    logger.warn("Active IAP subscriptions query failed", {error});
  }

  try {
    newStripe = await countQuery(
      subscriptionsRef
        .where("createdAt", ">=", startTimestamp)
        .where("createdAt", "<", endTimestamp)
    );
  } catch (error) {
    logger.warn("New Stripe subscriptions query failed", {error});
  }

  try {
    newIap = await countQuery(
      subscriptionsRef
        .where("startDate", ">=", startTimestamp)
        .where("startDate", "<", endTimestamp)
    );
  } catch (error) {
    logger.warn("New IAP subscriptions query failed", {error});
  }

  try {
    churnedStripe = await countQuery(
      subscriptionsRef
        .where("isActive", "==", false)
        .where("updatedAt", ">=", startTimestamp)
        .where("updatedAt", "<", endTimestamp)
    );
  } catch (error) {
    logger.warn("Churned Stripe subscriptions query failed", {error});
  }

  try {
    churnedIap = await countQuery(
      subscriptionsRef
        .where("status", "==", "cancelled")
        .where("updatedAt", ">=", startTimestamp)
        .where("updatedAt", "<", endTimestamp)
    );
  } catch (error) {
    logger.warn("Churned IAP subscriptions query failed", {error});
  }

  try {
    const activeAtStartStripe = await countQuery(
      subscriptionsRef.where("isActive", "==", true)
    );
    const activeAtStartIap = await countQuery(
      subscriptionsRef
        .where("status", "==", "active")
        .where("startDate", "<", startTimestamp)
    );
    activeAtStart = activeAtStartStripe + activeAtStartIap;
  } catch (error) {
    logger.warn("Active-at-start subscriptions query failed", {error});
  }

  const active = activeStripe + activeIap;
  const newSubs = newStripe + newIap;
  const churned = churnedStripe + churnedIap;
  const churnRate = activeAtStart > 0 ? churned / activeAtStart : null;

  return {
    active,
    new: newSubs,
    churned,
    churnRate,
  };
}

function buildDailyReportHtml(payload) {
  const {
    date,
    dau,
    wau,
    mau,
    newUsers,
    capturesAdded,
    artworkAdded,
    currency,
    stripeMetrics,
    iapMetrics,
    totalGross,
    totalNet,
    totalRefunds,
    subscriptionMetrics,
  } = payload;

  return `
  <div style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; background: #f6f7fb; padding: 24px;">
    <div style="max-width: 720px; margin: 0 auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 6px 16px rgba(0,0,0,0.08);">
      <div style="background: linear-gradient(135deg, #7c3aed, #2563eb); color: #fff; padding: 24px;">
        <div style="font-size: 20px; font-weight: 700;">ARTbeat Daily Analytics</div>
        <div style="opacity: 0.9; margin-top: 6px;">UTC Date: ${date}</div>
      </div>

      <div style="padding: 24px;">
        <div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px;">
          ${buildMetricCard("DAU", dau ?? "N/A")}
          ${buildMetricCard("WAU", wau ?? "N/A")}
          ${buildMetricCard("MAU", mau ?? "N/A")}
          ${buildMetricCard("New Users", newUsers ?? "N/A")}
        </div>

        <h3 style="margin: 28px 0 12px; color: #111827;">Revenue</h3>
        ${buildTable([
          ["Total Gross", formatCurrency(totalGross, currency)],
          ["Total Net", formatCurrency(totalNet, currency)],
          ["Total Refunds", formatCurrency(totalRefunds, currency)],
          ["Stripe Gross", formatCurrency(stripeMetrics.gross, currency)],
          ["Stripe Net", formatCurrency(stripeMetrics.net, currency)],
          ["Stripe Fees", formatCurrency(stripeMetrics.fees, currency)],
          ["Stripe Refunds", formatCurrency(stripeMetrics.refunds, currency)],
          ["IAP Gross", formatCurrency(iapMetrics.gross, currency)],
          ["IAP Net (rate ${iapMetrics.netRate})", formatCurrency(iapMetrics.net, currency)],
          ["IAP Refunds", formatCurrency(iapMetrics.refunds, currency)],
        ])}

        <h3 style="margin: 28px 0 12px; color: #111827;">Subscriptions</h3>
        ${buildTable([
          ["Active", subscriptionMetrics.active],
          ["New", subscriptionMetrics.new],
          ["Churn (approx)", formatPercent(subscriptionMetrics.churnRate)],
        ])}

        <h3 style="margin: 28px 0 12px; color: #111827;">Content</h3>
        ${buildTable([
          ["Captures added", capturesAdded ?? "N/A"],
          ["Artwork added", artworkAdded ?? "N/A"],
        ])}

        <div style="margin-top: 24px; font-size: 12px; color: #6b7280;">
          Net revenue includes Stripe net plus IAP net based on rate ${iapMetrics.netRate}. Adjust via IAP_NET_RATE env.
        </div>
      </div>
    </div>
  </div>
  `;
}

function buildMetricCard(label, value) {
  return `
    <div style="border: 1px solid #e5e7eb; border-radius: 10px; padding: 16px;">
      <div style="font-size: 12px; color: #6b7280;">${label}</div>
      <div style="font-size: 20px; font-weight: 700; color: #111827;">${value}</div>
    </div>
  `;
}

function buildTable(rows) {
  const rowHtml = rows
    .map(
      ([label, value]) => `
      <tr>
        <td style="padding: 10px 12px; border-bottom: 1px solid #e5e7eb; color: #374151;">${label}</td>
        <td style="padding: 10px 12px; border-bottom: 1px solid #e5e7eb; color: #111827; text-align: right; font-weight: 600;">${value}</td>
      </tr>
    `
    )
    .join("");

  return `
    <table style="width: 100%; border-collapse: collapse; font-size: 14px;">
      <tbody>
        ${rowHtml}
      </tbody>
    </table>
  `;
}

exports.rotateKioskLaneNow = onRequest(
  {
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 2,
  },
  async (request, response) => {
    try {
      const result = await performKioskLaneRotation("manual");
      return response.status(200).send(result);
    } catch (error) {
      console.error("Error rotating kiosk lane:", error);
      return response.status(500).send({error: error.message});
    }
  });

/**
 * Migrate legacy gifts into boosts and artist XP.
 * Optional query params:
 * - limit (default 200)
 * - dryRun=true
 */
exports.migrateGiftsToBoosts = onRequest(
  {
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 5,
  },
  async (request, response) => {
    try {
      const limit = Math.min(Number(request.query.limit || 200), 1000);
      const dryRun = String(request.query.dryRun || "false") === "true";

      const giftsSnapshot = await admin
        .firestore()
        .collection("gifts")
        .orderBy("createdAt", "asc")
        .limit(limit)
        .get();

      if (giftsSnapshot.empty) {
        return response.status(200).send({processed: 0});
      }

      let processed = 0;
      for (const doc of giftsSnapshot.docs) {
        const data = doc.data();
        if (data.migratedToBoost) continue;

        const recipientId = data.recipientId;
        const senderId = data.senderId;
        if (!recipientId || !senderId) continue;

        const productId =
        data.productId ||
        (data.giftType === "Small Gift" ? "artbeat_boost_spark" : null) ||
        (data.giftType === "Medium Gift" ? "artbeat_boost_surge" : null) ||
        (data.giftType === "Large Gift" ? "artbeat_boost_overdrive" : null) ||
        "artbeat_boost_spark";

        const momentum = getMomentumForProduct(productId, Number(data.momentum || 0));
        const purchaseDate = data.createdAt?.toDate?.() || new Date();

        if (!dryRun) {
          await admin.firestore().collection("boosts").add({
            senderId,
            recipientId,
            productId,
            amount: Number(data.amount || 0),
            currency: data.currency || "USD",
            message: data.message || "",
            purchaseDate: admin.firestore.Timestamp.fromDate(purchaseDate),
            status: "completed",
            momentum,
            migratedFromGiftId: doc.id,
            migratedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          await doc.ref.set(
            {
              migratedToBoost: true,
              migratedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            {merge: true}
          );
        }

        processed += 1;
      }

      return response.status(200).send({processed, dryRun});
    } catch (error) {
      console.error("Error migrating gifts to boosts:", error);
      return response.status(500).send({error: error.message});
    }
  });

/**
 * Admin backfill for historical boosts to compute momentum without notifications.
 * Optional query params:
 * - limit: number of boosts to process (default 200)
 */
exports.backfillBoostMomentum = onRequest(
  {
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 2,
  },
  async (request, response) => {
    try {
      const limit = Math.min(
        Number(request.query.limit || 200),
        1000
      );

      const query = admin
        .firestore()
        .collection("boosts")
        .orderBy("purchaseDate", "asc")
        .limit(limit);

      const snapshot = await query.get();
      if (snapshot.empty) {
        return response.status(200).send({processed: 0});
      }

      let processed = 0;
      for (const doc of snapshot.docs) {
        const data = doc.data();
        if (data.momentumAppliedAt || data.momentumBackfilledAt) continue;
        if (data.status && data.status !== "completed") continue;

        const recipientId = data.recipientId;
        if (!recipientId) continue;

        const productId = data.productId;
        const momentum =
        Number(data.momentum || data.momentumAmount || 0) ||
        getMomentumForProduct(productId, 0);

        const eventTime = data.purchaseDate ?
          data.purchaseDate.toDate() :
          new Date();

        await applyMomentumTransaction(recipientId, momentum, eventTime);

        await doc.ref.update({
          momentumBackfilledAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        processed += 1;
      }

      return response.status(200).send({processed});
    } catch (error) {
      console.error("Error backfilling boost momentum:", error);
      return response.status(500).send({error: error.message});
    }
  });

/**
 * Test leaderboard queries directly
 */
exports.testLeaderboardQuery = onRequest(
  {
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 2,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🧪 Testing leaderboard queries...");

        // Test Total XP query
        console.log("Testing Total XP query...");
        const xpQuery = await admin
          .firestore()
          .collection("users")
          .orderBy("experiencePoints", "desc")
          .limit(10)
          .get();

        const xpResults = xpQuery.docs.map((doc) => ({
          id: doc.id,
          name: doc.data().fullName || doc.data().username,
          xp: doc.data().experiencePoints || 0,
        }));
        console.log("XP Results:", xpResults);

        // Test Captures Created query
        console.log("Testing Captures Created query...");
        const capturesQuery = await admin
          .firestore()
          .collection("users")
          .orderBy("stats.capturesCreated", "desc")
          .limit(10)
          .get();

        const capturesResults = capturesQuery.docs.map((doc) => ({
          id: doc.id,
          name: doc.data().fullName || doc.data().username,
          captures: (doc.data().stats || {}).capturesCreated || 0,
        }));
        console.log("Captures Results:", capturesResults);

        response.status(200).send({
          success: true,
          xpResults,
          capturesResults,
        });
      } catch (error) {
        console.error("❌ Error testing queries:", error);
        response.status(500).send({error: error.message, stack: error.stack});
      }
    });
  });

/**
 * Debug user data for leaderboard issues
 */
exports.debugUsers = onRequest(
  {
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 2,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🔍 Debugging user data...");

        // Get all users with XP > 0
        const usersSnapshot = await admin
          .firestore()
          .collection("users")
          .where("experiencePoints", ">", 0)
          .orderBy("experiencePoints", "desc")
          .get();

        console.log(`👥 Found ${usersSnapshot.docs.length} users with XP`);

        const userDebugInfo = [];
        for (const doc of usersSnapshot.docs) {
          const userData = doc.data();
          const stats = userData.stats || {};

          const userInfo = {
            id: doc.id,
            name: userData.fullName || userData.username || "Unknown",
            xp: userData.experiencePoints || 0,
            level: userData.level || 1,
            stats: {
              capturesCreated: stats.capturesCreated || 0,
              capturesApproved: stats.capturesApproved || 0,
              walksCreated: stats.walksCreated || 0,
              walksCompleted: stats.walksCompleted || 0,
              highestRatedCapture: stats.highestRatedCapture || 0,
              highestRatedArtWalk: stats.highestRatedArtWalk || 0,
            },
          };

          userDebugInfo.push(userInfo);
          console.log(
            `👤 ${userInfo.name}: XP=${userInfo.xp}, Level=${userInfo.level}`
          );
        }

        // Check art walks collection
        console.log("🚶 Checking art walks...");
        const artWalksSnapshot = await admin
          .firestore()
          .collection("artWalks")
          .get();
        console.log(`Found ${artWalksSnapshot.docs.length} art walks total`);

        const creatorCounts = {};
        const walkRatings = {};
        for (const doc of artWalksSnapshot.docs) {
          const walkData = doc.data();
          const creatorId = walkData.createdBy || walkData.userId;
          if (creatorId) {
            creatorCounts[creatorId] = (creatorCounts[creatorId] || 0) + 1;

            // Check for ratings
            if (walkData.averageRating && walkData.averageRating > 0) {
              if (
                !walkRatings[creatorId] ||
              walkData.averageRating > walkRatings[creatorId]
              ) {
                walkRatings[creatorId] = walkData.averageRating;
              }
            }
          }
        }

        console.log("Art walk creators:", creatorCounts);
        console.log("Art walk ratings:", walkRatings);

        // Check captures for ratings
        console.log("📸 Checking capture ratings...");
        const allCapturesSnapshot = await admin
          .firestore()
          .collection("captures")
          .get();
        const captureRatings = {};
        for (const doc of allCapturesSnapshot.docs) {
          const captureData = doc.data();
          const userId = captureData.userId;
          if (
            userId &&
          captureData.averageRating &&
          captureData.averageRating > 0
          ) {
            if (
              !captureRatings[userId] ||
            captureData.averageRating > captureRatings[userId]
            ) {
              captureRatings[userId] = captureData.averageRating;
            }
          }
        }
        console.log("Capture ratings:", captureRatings);

        response.status(200).send({
          success: true,
          users: userDebugInfo,
          artWalkCreators: creatorCounts,
          walkRatings: walkRatings,
          captureRatings: captureRatings,
          totalArtWalks: artWalksSnapshot.docs.length,
          totalCaptures: allCapturesSnapshot.docs.length,
        });
      } catch (error) {
        console.error("❌ Error debugging users:", error);
        response.status(500).send({error: error.message});
      }
    });
  });

// Calculate user level based on XP (matches RewardsService logic)
/**
 * Calculate user level based on experience points
 * @param {number} xp - The user's experience points
 * @return {number} The calculated level
 */
function calculateLevel(xp) {
  const levelSystem = {
    1: {minXP: 0, maxXP: 199},
    2: {minXP: 200, maxXP: 499},
    3: {minXP: 500, maxXP: 999},
    4: {minXP: 1000, maxXP: 1499},
    5: {minXP: 1500, maxXP: 2499},
    6: {minXP: 2500, maxXP: 3999},
    7: {minXP: 4000, maxXP: 5999},
    8: {minXP: 6000, maxXP: 7999},
    9: {minXP: 8000, maxXP: 9999},
    10: {minXP: 10000, maxXP: 999999},
  };

  for (let level = 10; level >= 1; level--) {
    const levelData = levelSystem[level];
    if (xp >= levelData.minXP) {
      return level;
    }
  }
  return 1;
}

/**
 * Create a new customer in Stripe
 */
exports.createCustomer = onRequest(
  {secrets: [stripeSecretKey]},
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🔍 createCustomer called - Method:", request.method);
        console.log("🔍 Headers:", JSON.stringify(request.headers, null, 2));
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          console.log("❌ No valid auth header found");
          return response.status(401).send({error: "Unauthorized"});
        }

        const idToken = authHeader.split("Bearer ")[1];
        console.log("🔐 Token received, length:", idToken.length);

        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;
        console.log("✅ Auth successful for user:", authUserId);

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

        // Verify the userId matches the authenticated user
        if (userId !== authUserId) {
          return response.status(403).send({error: "Forbidden"});
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
  {secrets: [stripeSecretKey]},
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🔍 createSetupIntent called - Method:", request.method);
        console.log("🔍 Headers:", JSON.stringify(request.headers, null, 2));
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          console.log("❌ No valid auth header found");
          return response.status(401).send({error: "Unauthorized"});
        }

        const idToken = authHeader.split("Bearer ")[1];
        console.log("🔐 Token received, length:", idToken.length);

        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;
        console.log("✅ Auth successful for user:", authUserId);

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
 * Create a payment intent for direct one-time payments
 * (no stored payment methods)
 */
exports.createPaymentIntent = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 5,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🔍 createPaymentIntent called - Method:", request.method);
        console.log("🔍 Headers:", JSON.stringify(request.headers, null, 2));
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          console.log("❌ No valid auth header found");
          return response.status(401).send({error: "Unauthorized"});
        }

        const idToken = authHeader.split("Bearer ")[1];
        console.log("🔐 Token received, length:", idToken.length);

        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;
        console.log("✅ Auth successful for user:", authUserId);

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {
          amount,
          currency = "usd",
          description,
          metadata = {},
        } = request.body;

        if (!amount || amount <= 0) {
          return response.status(400).send({
            error: "Invalid amount",
          });
        }

        // Convert amount to cents for Stripe
        const amountInCents = Math.round(amount * 100);

        console.log(
          `💰 Creating payment intent for $${amount} (${amountInCents} cents)`
        );

        const paymentIntent = await stripe.paymentIntents.create({
          amount: amountInCents,
          currency: currency,
          description: description || "ArtBeat Gift Payment",
          metadata: {
            userId: authUserId,
            ...metadata,
          },
          automatic_payment_methods: {
            enabled: true,
          },
        });

        console.log("✅ Payment intent created:", paymentIntent.id);

        response.status(200).send({
          clientSecret: paymentIntent.client_secret,
          paymentIntentId: paymentIntent.id,
          success: true,
        });
      } catch (error) {
        console.error("❌ Error creating payment intent:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Create a payment intent for a commission (Direct Commissions)
 */
exports.createCommissionPaymentIntent = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 5,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🎨 createCommissionPaymentIntent called");

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          return response.status(401).send({error: "Unauthorized"});
        }

        const idToken = authHeader.split("Bearer ")[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {
          amount,
          commissionId,
          type, // 'deposit', 'milestone', 'final'
          milestoneId,
          customerId,
          currency = "usd",
        } = request.body;

        if (!amount || !commissionId || !type) {
          return response.status(400).send({
            error: "Missing required fields: amount, commissionId, type",
          });
        }

        // Convert amount to cents for Stripe
        const amountInCents = Math.round(amount * 100);

        const paymentIntent = await stripe.paymentIntents.create({
          amount: amountInCents,
          currency: currency,
          customer: customerId,
          description: `Commission ${type}: ${commissionId}`,
          metadata: {
            userId: authUserId,
            commissionId: commissionId,
            paymentType: type,
            milestoneId: milestoneId || "",
          },
          automatic_payment_methods: {
            enabled: true,
          },
        });

        console.log(`✅ Commission payment intent created: ${paymentIntent.id}`);

        response.status(200).send({
          clientSecret: paymentIntent.client_secret,
          paymentIntentId: paymentIntent.id,
          success: true,
        });
      } catch (error) {
        console.error("❌ Error creating commission payment intent:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Process a commission deposit payment (Direct Commissions)
 */
exports.processCommissionDepositPayment = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 5,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🎨 processCommissionDepositPayment called");

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          return response.status(401).send({error: "Unauthorized"});
        }

        const idToken = authHeader.split("Bearer ")[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {
          amount,
          commissionId,
          paymentMethodId,
          customerId,
          message: paymentMessage,
        } = request.body;

        if (!amount || !commissionId || !paymentMethodId || !customerId) {
          return response.status(400).send({
            error: "Missing required fields: amount, commissionId, paymentMethodId, customerId",
          });
        }

        // 1. Create and confirm payment intent
        const amountInCents = Math.round(amount * 100);
        const paymentIntent = await stripe.paymentIntents.create({
          amount: amountInCents,
          currency: "usd",
          customer: customerId,
          payment_method: paymentMethodId,
          off_session: false,
          confirm: true,
          description: `Commission Deposit: ${commissionId}`,
          metadata: {
            userId: authUserId,
            commissionId: commissionId,
            paymentType: "deposit",
          },
        });

        if (paymentIntent.status !== "succeeded") {
          return response.status(400).send({
            error: `Payment failed with status: ${paymentIntent.status}`,
          });
        }

        console.log(`✅ Deposit payment successful: ${paymentIntent.id}`);

        const firestore = admin.firestore();
        const commissionRef = firestore.collection("direct_commissions").doc(commissionId);
        const commissionDoc = await commissionRef.get();

        if (!commissionDoc.exists) {
          return response.status(404).send({error: "Commission not found"});
        }

        const commissionData = commissionDoc.data();
        const artistId = commissionData.artistId;

        // 2. Record artist earnings (PENDING)
        await recordArtistEarnings(
          artistId,
          "commission",
          amount,
          authUserId,
          decodedToken.name || "A Client",
          `Deposit for commission: ${commissionData.title}`,
          {
            commissionId: commissionId,
            paymentIntentId: paymentIntent.id,
            paymentType: "deposit",
          },
          true // isPending = true
        );

        // 3. Update commission status in Firestore
        await commissionRef.update({
          status: "inProgress",
          "metadata.depositPaidAt": admin.firestore.FieldValue.serverTimestamp(),
          "metadata.depositPaymentId": paymentIntent.id,
          "metadata.startedAt": admin.firestore.FieldValue.serverTimestamp(),
        });

        // 4. Create notification for artist
        await firestore.collection("notifications").add({
          userId: artistId,
          type: "commission_deposit_paid",
          title: "Deposit Paid!",
          message: `A deposit of $${amount} has been paid for "${commissionData.title}". You can now start working!`,
          data: {
            commissionId: commissionId,
            amount: amount,
          },
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        response.status(200).send({
          success: true,
          paymentIntentId: paymentIntent.id,
          message: "Deposit processed successfully",
        });
      } catch (error) {
        console.error("❌ Error processing commission deposit:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Process a commission milestone payment (Direct Commissions)
 */
exports.processCommissionMilestonePayment = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 5,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🎨 processCommissionMilestonePayment called");

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          return response.status(401).send({error: "Unauthorized"});
        }

        const idToken = authHeader.split("Bearer ")[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {
          amount,
          commissionId,
          milestoneId,
          paymentMethodId,
          customerId,
          message: paymentMessage,
        } = request.body;

        if (!amount || !commissionId || !milestoneId || !paymentMethodId || !customerId) {
          return response.status(400).send({
            error: "Missing required fields: amount, commissionId, milestoneId, paymentMethodId, customerId",
          });
        }

        // 1. Create and confirm payment intent
        const amountInCents = Math.round(amount * 100);
        const paymentIntent = await stripe.paymentIntents.create({
          amount: amountInCents,
          currency: "usd",
          customer: customerId,
          payment_method: paymentMethodId,
          off_session: false,
          confirm: true,
          description: `Commission Milestone: ${commissionId} - ${milestoneId}`,
          metadata: {
            userId: authUserId,
            commissionId: commissionId,
            milestoneId: milestoneId,
            paymentType: "milestone",
          },
        });

        if (paymentIntent.status !== "succeeded") {
          return response.status(400).send({
            error: `Payment failed with status: ${paymentIntent.status}`,
          });
        }

        console.log(`✅ Milestone payment successful: ${paymentIntent.id}`);

        const firestore = admin.firestore();
        const commissionRef = firestore.collection("direct_commissions").doc(commissionId);
        const commissionDoc = await commissionRef.get();

        if (!commissionDoc.exists) {
          return response.status(404).send({error: "Commission not found"});
        }

        const commissionData = commissionDoc.data();
        const artistId = commissionData.artistId;

        // 2. Record artist earnings (PENDING)
        await recordArtistEarnings(
          artistId,
          "commission",
          amount,
          authUserId,
          decodedToken.name || "A Client",
          `Milestone payment for: ${commissionData.title}`,
          {
            commissionId: commissionId,
            milestoneId: milestoneId,
            paymentIntentId: paymentIntent.id,
            paymentType: "milestone",
          },
          true // isPending = true
        );

        // 3. Update milestone status in Firestore
        const milestones = commissionData.milestones || [];
        const updatedMilestones = milestones.map((m) => {
          if (m.id === milestoneId) {
            return {
              ...m,
              status: "paid",
              paymentIntentId: paymentIntent.id,
              paidAt: admin.firestore.FieldValue.serverTimestamp(),
            };
          }
          return m;
        });

        await commissionRef.update({
          milestones: updatedMilestones,
        });

        // 4. Create notification for artist
        await firestore.collection("notifications").add({
          userId: artistId,
          type: "commission_milestone_paid",
          title: "Milestone Paid!",
          message: `A milestone payment of $${amount} has been paid for "${commissionData.title}".`,
          data: {
            commissionId: commissionId,
            milestoneId: milestoneId,
            amount: amount,
          },
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        response.status(200).send({
          success: true,
          paymentIntentId: paymentIntent.id,
          message: "Milestone payment processed successfully",
        });
      } catch (error) {
        console.error("❌ Error processing milestone payment:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Process a commission final payment (Direct Commissions)
 */
exports.processCommissionFinalPayment = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 5,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🎨 processCommissionFinalPayment called");

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          return response.status(401).send({error: "Unauthorized"});
        }

        const idToken = authHeader.split("Bearer ")[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {
          amount,
          commissionId,
          paymentMethodId,
          customerId,
          message: paymentMessage,
        } = request.body;

        if (!amount || !commissionId || !paymentMethodId || !customerId) {
          return response.status(400).send({
            error: "Missing required fields: amount, commissionId, paymentMethodId, customerId",
          });
        }

        // 1. Create and confirm payment intent
        const amountInCents = Math.round(amount * 100);
        const paymentIntent = await stripe.paymentIntents.create({
          amount: amountInCents,
          currency: "usd",
          customer: customerId,
          payment_method: paymentMethodId,
          off_session: false,
          confirm: true,
          description: `Commission Final Payment: ${commissionId}`,
          metadata: {
            userId: authUserId,
            commissionId: commissionId,
            paymentType: "final",
          },
        });

        if (paymentIntent.status !== "succeeded") {
          return response.status(400).send({
            error: `Payment failed with status: ${paymentIntent.status}`,
          });
        }

        console.log(`✅ Final payment successful: ${paymentIntent.id}`);

        const firestore = admin.firestore();
        const commissionRef = firestore.collection("direct_commissions").doc(commissionId);
        const commissionDoc = await commissionRef.get();

        if (!commissionDoc.exists) {
          return response.status(404).send({error: "Commission not found"});
        }

        const commissionData = commissionDoc.data();
        const artistId = commissionData.artistId;

        // 2. Record artist earnings (PENDING)
        await recordArtistEarnings(
          artistId,
          "commission",
          amount,
          authUserId,
          decodedToken.name || "A Client",
          `Final payment for commission: ${commissionData.title}`,
          {
            commissionId: commissionId,
            paymentIntentId: paymentIntent.id,
            paymentType: "final",
          },
          true // isPending = true
        );

        // 3. Update commission status in Firestore
        await commissionRef.update({
          status: "completed",
          "metadata.finalPaymentPaidAt": admin.firestore.FieldValue.serverTimestamp(),
          "metadata.finalPaymentId": paymentIntent.id,
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // 4. Create notification for artist
        await firestore.collection("notifications").add({
          userId: artistId,
          type: "commission_final_paid",
          title: "Final Payment Received!",
          message: `The final payment of $${amount} has been paid for "${commissionData.title}". The commission is now marked as completed.`,
          data: {
            commissionId: commissionId,
            amount: amount,
          },
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        response.status(200).send({
          success: true,
          paymentIntentId: paymentIntent.id,
          message: "Final payment processed successfully",
        });
      } catch (error) {
        console.error("❌ Error processing final payment:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Get payment methods for a customer
 */
exports.getPaymentMethods = onRequest(
  {secrets: [stripeSecretKey]},
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🔍 getPaymentMethods called - Method:", request.method);
        console.log("🔍 Headers:", JSON.stringify(request.headers, null, 2));
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          console.log("❌ No valid auth header found");
          return response.status(401).send({error: "Unauthorized"});
        }

        const idToken = authHeader.split("Bearer ")[1];
        console.log("🔐 Token received, length:", idToken.length);

        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;
        console.log("✅ Auth successful for user:", authUserId);

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

        console.log("🔄 Getting payment methods for customer:", customerId);
        const paymentMethods = await stripe.paymentMethods.list({
          customer: customerId,
          type: "card",
        });

        console.log("✅ Found", paymentMethods.data.length, "payment methods");
        response.status(200).send({
          paymentMethods: paymentMethods.data,
          success: true,
        });
      } catch (error) {
        console.error("❌ Error getting payment methods:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Update customer information
 */
exports.updateCustomer = onRequest(
  {secrets: [stripeSecretKey]},
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🔍 updateCustomer called - Method:", request.method);
        console.log("🔍 Headers:", JSON.stringify(request.headers, null, 2));
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          console.log("❌ No valid auth header found");
          return response.status(401).send({error: "Unauthorized"});
        }

        const idToken = authHeader.split("Bearer ")[1];
        console.log("🔐 Token received, length:", idToken.length);

        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;
        console.log("✅ Auth successful for user:", authUserId);

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {customerId, email, name, defaultPaymentMethod} = request.body;

        if (!customerId) {
          return response.status(400).send({
            error: "Missing customer ID",
          });
        }

        const updateData = {};
        if (email) updateData.email = email;
        if (name) updateData.name = name;
        if (defaultPaymentMethod) {
          updateData.invoice_settings = {
            default_payment_method: defaultPaymentMethod,
          };
        }

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
  {secrets: [stripeSecretKey]},
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🔍 detachPaymentMethod called - Method:", request.method);
        console.log("🔍 Headers:", JSON.stringify(request.headers, null, 2));
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          console.log("❌ No valid auth header found");
          return response.status(401).send({error: "Unauthorized"});
        }

        const idToken = authHeader.split("Bearer ")[1];
        console.log("🔐 Token received, length:", idToken.length);

        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;
        console.log("✅ Auth successful for user:", authUserId);

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
  {secrets: [stripeSecretKey]},
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

        const clientSecret =
          subscription.latest_invoice.payment_intent?.client_secret ?? "";

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
  {secrets: [stripeSecretKey]},
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
  {secrets: [stripeSecretKey]},
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
 * Process gift payment after payment intent is confirmed
 */
exports.processGiftPayment = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 5,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🎁 processGiftPayment called - Method:", request.method);
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          console.log("❌ No valid auth header found");
          return response.status(401).send({error: "Unauthorized"});
        }

        const idToken = authHeader.split("Bearer ")[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;
        console.log("✅ Auth successful for user:", authUserId);

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {
          paymentIntentId,
          recipientId,
          amount,
          giftType,
          message,
          campaignId,
          isFreeGift,
          skipPaymentValidation,
        } = request.body;

        // Check for free gift with skip validation flag
        if (isFreeGift && skipPaymentValidation) {
          console.log("🎁 Processing free gift - skipping payment validation");

          if (!recipientId || amount === undefined) {
            return response.status(400).send({
              error:
                "Missing required fields for free gift: recipientId, amount",
            });
          }

          // Skip payment intent validation for free gifts
        } else {
          // Regular paid gift validation
          if (!paymentIntentId || !recipientId || !amount) {
            return response.status(400).send({
              error:
                "Missing required fields: paymentIntentId, recipientId, amount",
            });
          }

          // Verify the payment intent was successful
          const paymentIntent = await stripe.paymentIntents.retrieve(
            paymentIntentId
          );

          if (paymentIntent.status !== "succeeded") {
            return response.status(400).send({
              error: `Payment not completed. Status: ${paymentIntent.status}`,
            });
          }
        }

        if (isFreeGift && skipPaymentValidation) {
          console.log(`✅ Free gift validated for $${amount}`);
        } else {
          console.log(`✅ Payment verified: ${paymentIntentId} for $${amount}`);
        }

        // Create gift record in Firestore
        const giftData = {
          senderId: authUserId,
          recipientId: recipientId,
          amount: amount,
          giftType: giftType || "Custom Gift",
          message: message || null,
          campaignId: campaignId || null,
          status: "completed",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          isFreeGift: isFreeGift || false,
        };

        // Only add paymentIntentId if it exists (not for free gifts)
        if (paymentIntentId) {
          giftData.paymentIntentId = paymentIntentId;
        }

        const giftRef = await admin
          .firestore()
          .collection("gifts")
          .add(giftData);
        console.log(`🎁 Gift record created: ${giftRef.id}`);

        // Update recipient's balance
        const recipientRef = admin
          .firestore()
          .collection("users")
          .doc(recipientId);
        await admin.firestore().runTransaction(async (transaction) => {
          const recipientDoc = await transaction.get(recipientRef);
          const currentBalance = recipientDoc.data()?.balance || 0;
          const newBalance = currentBalance + amount;

          transaction.update(recipientRef, {
            balance: newBalance,
            lastGiftReceived: admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        console.log(`💰 Updated recipient balance: +$${amount}`);

        // Record earnings for the recipient
        await recordArtistEarnings(
          recipientId,
          "gift",
          amount,
          authUserId,
          decodedToken.name || "A User",
          message || "Received a gift",
          {giftId: giftRef.id, giftType: giftType || "Custom Gift"}
        );

        // Create notification for recipient
        await admin
          .firestore()
          .collection("notifications")
          .add({
            userId: recipientId,
            type: "gift_received",
            title: "You received a gift!",
            message: `You received a ${giftType || "gift"} worth $${amount}${
              message ? ` with message: "${message}"` : ""
            }`,
            data: {
              giftId: giftRef.id,
              senderId: authUserId,
              amount: amount,
              giftType: giftType,
            },
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

        console.log("📱 Notification sent to recipient");

        response.status(200).send({
          success: true,
          giftId: giftRef.id,
          message: "Gift sent successfully!",
        });
      } catch (error) {
        console.error("❌ Error processing gift payment:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Process boost payment after payment intent is confirmed
 * Aligned with App Store compliance (digital platform items)
 */
exports.processBoostPayment = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 5,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🚀 processBoostPayment called");

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          return response.status(401).send({error: "Unauthorized"});
        }

        const idToken = authHeader.split("Bearer ")[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {
          paymentIntentId,
          recipientId,
          amount,
          boostType,
          boostMessage,
          productId,
        } = request.body;

        if (!paymentIntentId || !recipientId || !amount) {
          return response.status(400).send({
            error: "Missing required fields: paymentIntentId, recipientId, amount",
          });
        }

        // Verify the payment intent was successful
        const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

        if (paymentIntent.status !== "succeeded") {
          return response.status(400).send({
            error: `Payment not completed. Status: ${paymentIntent.status}`,
          });
        }

        console.log(`✅ Boost payment verified: ${paymentIntentId} for $${amount}`);

        // Create boost record in Firestore
        const boostData = {
          boosterId: authUserId,
          recipientId: recipientId,
          amount: amount,
          productId: productId || "custom_boost",
          boostType: boostType || "Momentum Boost",
          message: boostMessage || null,
          paymentIntentId: paymentIntentId,
          status: "completed",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        const boostRef = await admin
          .firestore()
          .collection("boosts")
          .add(boostData);
        console.log(`🚀 Boost record created: ${boostRef.id}`);

        // Update recipient's balance
        const recipientRef = admin.firestore().collection("users").doc(recipientId);
        await admin.firestore().runTransaction(async (transaction) => {
          const recipientDoc = await transaction.get(recipientRef);
          const currentBalance = recipientDoc.data()?.balance || 0;
          const newBalance = currentBalance + amount;

          transaction.update(recipientRef, {
            balance: newBalance,
            lastBoostReceived: admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        // Record earnings for the recipient
        await recordArtistEarnings(
          recipientId,
          "boost",
          amount,
          authUserId,
          decodedToken.name || "A User",
          boostMessage || "Received a boost",
          {boostId: boostRef.id, boostType: boostType || "Momentum Boost"}
        );

        // Create notification for recipient
        await admin.firestore().collection("notifications").add({
          userId: recipientId,
          type: "boost_received",
          title: "You received a boost!",
          message: `Your momentum was supercharged with a boost worth $${amount}!`,
          data: {
            boostId: boostRef.id,
            boosterId: authUserId,
            amount: amount,
          },
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        response.status(200).send({
          success: true,
          boostId: boostRef.id,
          message: "Boost sent successfully!",
        });
      } catch (error) {
        console.error("❌ Error processing boost payment:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Process artwork sale payment after payment intent is confirmed
 */
exports.processArtworkSalePayment = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 5,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🖼️ processArtworkSalePayment called");

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          return response.status(401).send({error: "Unauthorized"});
        }

        const idToken = authHeader.split("Bearer ")[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {
          paymentIntentId,
          artworkId,
          artistId,
          amount,
          isAuction,
          purchaseType,
          chapterId,
          chapterNumber,
        } = request.body;

        if (!paymentIntentId || !artworkId || !artistId || !amount) {
          return response.status(400).send({
            error: "Missing required fields",
          });
        }

        // Verify the payment intent was successful
        const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

        if (paymentIntent.status !== "succeeded") {
          return response.status(400).send({
            error: `Payment not completed. Status: ${paymentIntent.status}`,
          });
        }

        console.log(`✅ Artwork sale verified: ${paymentIntentId} for $${amount}${isAuction ? " (Auction)" : ""}${purchaseType === "chapter" ? ` (Chapter ${chapterNumber})` : ""}`);

        // Create sale record
        const saleData = {
          buyerId: authUserId,
          artistId: artistId,
          artworkId: artworkId,
          amount: amount,
          paymentIntentId: paymentIntentId,
          status: "completed",
          isAuction: isAuction || false,
          purchaseType: purchaseType || "full_book",
          isFullBook: purchaseType === "full_book",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        // Add chapter-specific fields if applicable
        if (purchaseType === "chapter") {
          saleData.chapterId = chapterId || null;
          saleData.chapterNumber = chapterNumber || null;
        }

        const saleRef = await admin
          .firestore()
          .collection("artwork_sales")
          .add(saleData);

        // Update artwork status only for full book purchases (not chapter purchases)
        if (purchaseType !== "chapter") {
          // Update artwork status
          const artworkUpdate = {
            status: "sold",
            buyerId: authUserId,
            soldAt: admin.firestore.FieldValue.serverTimestamp(),
            soldPrice: amount,
          };

          if (isAuction) {
            artworkUpdate.auctionStatus = "paid";
            artworkUpdate.ownerId = authUserId; // Legacy compatibility
            artworkUpdate.purchasedAt = admin.firestore.FieldValue.serverTimestamp(); // Legacy compatibility
            artworkUpdate.purchasePrice = amount; // Legacy compatibility
          }

          await admin.firestore().collection("artworks").doc(artworkId).update(artworkUpdate);

          // Update auction result if applicable
          if (isAuction) {
            await admin.firestore().collection("auction_results").doc(artworkId).set({
              paymentStatus: "paid",
              paidAt: admin.firestore.FieldValue.serverTimestamp(),
              buyerId: authUserId,
              amount: amount,
            }, {merge: true});
          }
        }

        // Update artist's balance (85% for artwork, same for chapters)
        const artistShare = amount * 0.85;
        const artistRef = admin.firestore().collection("users").doc(artistId);

        await admin.firestore().runTransaction(async (transaction) => {
          const artistDoc = await transaction.get(artistRef);
          const currentBalance = artistDoc.data()?.balance || 0;
          const newBalance = currentBalance + artistShare;

          transaction.update(artistRef, {
            balance: newBalance,
            lastArtworkSale: admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        // Record earnings for the artist
        const earningDescription =
          purchaseType === "chapter"
            ? `Sale of chapter ${chapterNumber} for artwork ${artworkId}`
            : `Sale of artwork ${artworkId}`;

        await recordArtistEarnings(
          artistId,
          purchaseType === "chapter" ? "chapter_sale" : "artwork_sale",
          artistShare,
          authUserId,
          decodedToken.name || "A Buyer",
          earningDescription,
          {saleId: saleRef.id, artworkId: artworkId, chapterId: chapterId || null}
        );

        // Create notification for artist
        const notificationMessage =
          purchaseType === "chapter"
            ? `Chapter ${chapterNumber} purchased for $${amount}! Your share: $${artistShare.toFixed(2)}`
            : `Your artwork has been sold for $${amount}! Your share: $${artistShare.toFixed(2)}`;

        await admin.firestore().collection("notifications").add({
          userId: artistId,
          type: purchaseType === "chapter" ? "chapter_purchased" : "artwork_sold",
          title: purchaseType === "chapter" ? "Chapter Purchased!" : "Artwork Sold!",
          message: notificationMessage,
          data: {
            artworkId: artworkId,
            saleId: saleRef.id,
            buyerId: authUserId,
            chapterId: chapterId || null,
            chapterNumber: chapterNumber || null,
          },
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        response.status(200).send({
          success: true,
          saleId: saleRef.id,
          message: "Artwork sale processed successfully!",
        });
      } catch (error) {
        console.error("❌ Error processing artwork sale:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Process event ticket payment after payment intent is confirmed
 */
exports.processEventTicketPayment = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 10,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("💳 processEventTicketPayment called");

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          return response.status(401).send({error: "Unauthorized"});
        }

        const idToken = authHeader.split("Bearer ")[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {
          paymentIntentId,
          eventId,
          ticketTypeId,
          quantity,
          amount,
          artistId,
          userEmail,
          userName,
        } = request.body;

        if (!paymentIntentId || !eventId || !ticketTypeId || !quantity || !amount || !artistId) {
          return response.status(400).send({
            error: "Missing required fields",
          });
        }

        // Verify the payment intent was successful
        const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

        if (paymentIntent.status !== "succeeded") {
          return response.status(400).send({
            error: `Payment not completed. Status: ${paymentIntent.status}`,
          });
        }

        console.log(`✅ Ticket purchase verified: ${paymentIntentId} for $${amount}`);

        // 1. Create ticket purchase record
        const purchaseData = {
          eventId,
          ticketTypeId,
          userId: authUserId,
          userEmail: userEmail || decodedToken.email || "",
          userName: userName || decodedToken.name || "A Guest",
          quantity: parseInt(quantity),
          totalAmount: parseFloat(amount),
          status: "confirmed",
          paymentIntentId,
          purchaseDate: admin.firestore.FieldValue.serverTimestamp(),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        const purchaseRef = await admin
          .firestore()
          .collection("ticket_purchases")
          .add(purchaseData);

        // 2. Update ticket quantity sold in the event document
        await admin.firestore().runTransaction(async (transaction) => {
          const eventRef = admin.firestore().collection("events").doc(eventId);
          const eventDoc = await transaction.get(eventRef);

          if (!eventDoc.exists) {
            throw new Error("Event not found");
          }

          const eventData = eventDoc.data();
          const ticketTypes = eventData.ticketTypes || [];
          const updatedTicketTypes = ticketTypes.map((tt) => {
            if (tt.id === ticketTypeId) {
              const currentSold = tt.quantitySold || 0;
              return {
                ...tt,
                quantitySold: currentSold + parseInt(quantity),
              };
            }
            return tt;
          });

          transaction.update(eventRef, {
            ticketTypes: updatedTicketTypes,
            attendeeIds: admin.firestore.FieldValue.arrayUnion(authUserId),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        // 3. Update artist's balance (they get 90% of ticket sales)
        const artistShare = amount * 0.90;

        await recordArtistEarnings(
          artistId,
          "ticket_sale",
          artistShare,
          authUserId,
          userName || decodedToken.name || "A Guest",
          `Ticket purchase for event ${eventId}`,
          {eventId, ticketTypeId, quantity, paymentIntentId, purchaseId: purchaseRef.id}
        );

        // 4. Create notification for artist
        await admin.firestore().collection("notifications").add({
          userId: artistId,
          type: "tickets_sold",
          title: "Tickets Sold!",
          message: `${quantity} ticket(s) sold for your event! Your share: $${artistShare.toFixed(2)}`,
          data: {
            eventId,
            purchaseId: purchaseRef.id,
            buyerId: authUserId,
          },
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        response.status(200).send({
          success: true,
          purchaseId: purchaseRef.id,
          message: "Ticket purchase processed successfully!",
        });
      } catch (error) {
        console.error("❌ Error processing ticket purchase:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Process subscription payment after payment intent is confirmed
 */
exports.processSubscriptionPayment = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 5,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("💳 processSubscriptionPayment called");
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          return response.status(401).send({error: "Unauthorized"});
        }

        const idToken = authHeader.split("Bearer ")[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {paymentIntentId, tier, priceAmount, billingCycle} =
          request.body;

        if (!paymentIntentId || !tier || !priceAmount) {
          return response.status(400).send({
            error:
              "Missing required fields: paymentIntentId, tier, priceAmount",
          });
        }

        // Verify the payment intent was successful
        const paymentIntent = await stripe.paymentIntents.retrieve(
          paymentIntentId
        );

        if (paymentIntent.status !== "succeeded") {
          return response.status(400).send({
            error: `Payment not completed. Status: ${paymentIntent.status}`,
          });
        }

        console.log(
          `✅ Payment verified: ${paymentIntentId} for $${priceAmount}`
        );

        // Create subscription record in Firestore
        const subscriptionData = {
          userId: authUserId,
          tier: tier,
          priceAmount: priceAmount,
          billingCycle: billingCycle || "monthly",
          paymentIntentId: paymentIntentId,
          status: "active",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          nextBillingDate: admin.firestore.FieldValue.serverTimestamp(),
        };

        const subscriptionRef = await admin
          .firestore()
          .collection("subscriptions")
          .add(subscriptionData);
        console.log(`💳 Subscription record created: ${subscriptionRef.id}`);

        // Update user's subscription status
        await admin.firestore().collection("users").doc(authUserId).update({
          subscriptionTier: tier,
          subscriptionStatus: "active",
          subscriptionId: subscriptionRef.id,
          lastPayment: admin.firestore.FieldValue.serverTimestamp(),
        });

        console.log("👤 User subscription status updated");

        response.status(200).send({
          success: true,
          subscriptionId: subscriptionRef.id,
          message: "Subscription activated successfully!",
        });
      } catch (error) {
        console.error("❌ Error processing subscription payment:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Process ad payment after payment intent is confirmed
 */
exports.processAdPayment = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 5,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("📢 processAdPayment called");
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          return response.status(401).send({error: "Unauthorized"});
        }

        const idToken = authHeader.split("Bearer ")[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {
          paymentIntentId,
          adType,
          duration,
          amount,
          targetAudience,
          adContent,
        } = request.body;

        if (!paymentIntentId || !adType || !duration || !amount) {
          return response.status(400).send({
            error:
              "Missing required fields: paymentIntentId, adType, " +
              "duration, amount",
          });
        }

        // Verify the payment intent was successful
        const paymentIntent = await stripe.paymentIntents.retrieve(
          paymentIntentId
        );

        if (paymentIntent.status !== "succeeded") {
          return response.status(400).send({
            error: `Payment not completed. Status: ${paymentIntent.status}`,
          });
        }

        console.log(`✅ Payment verified: ${paymentIntentId} for $${amount}`);

        // Create ad record in Firestore
        const adData = {
          userId: authUserId,
          adType: adType,
          duration: duration,
          amount: amount,
          targetAudience: targetAudience || {},
          adContent: adContent || {},
          paymentIntentId: paymentIntentId,
          status: "active",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          startDate: admin.firestore.FieldValue.serverTimestamp(),
          endDate: new Date(Date.now() + duration * 24 * 60 * 60 * 1000),
          // duration in days
        };

        const adRef = await admin
          .firestore()
          .collection("advertisements")
          .add(adData);
        console.log(`📢 Ad record created: ${adRef.id}`);

        response.status(200).send({
          success: true,
          adId: adRef.id,
          message: "Advertisement activated successfully!",
        });
      } catch (error) {
        console.error("❌ Error processing ad payment:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Process sponsorship payment after payment intent is confirmed
 */
exports.processSponsorshipPayment = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 5,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🤝 processSponsorshipPayment called");
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          return response.status(401).send({error: "Unauthorized"});
        }

        const idToken = authHeader.split("Bearer ")[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {
          paymentIntentId,
          artistId,
          amount,
          sponsorshipType,
          duration,
          benefits,
        } = request.body;

        if (!paymentIntentId || !artistId || !amount || !sponsorshipType) {
          return response.status(400).send({
            error:
              "Missing required fields: paymentIntentId, artistId, " +
              "amount, sponsorshipType",
          });
        }

        // Verify the payment intent was successful
        const paymentIntent = await stripe.paymentIntents.retrieve(
          paymentIntentId
        );

        if (paymentIntent.status !== "succeeded") {
          return response.status(400).send({
            error: `Payment not completed. Status: ${paymentIntent.status}`,
          });
        }

        console.log(`✅ Payment verified: ${paymentIntentId} for $${amount}`);

        // Create sponsorship record in Firestore
        const sponsorshipData = {
          sponsorId: authUserId,
          artistId: artistId,
          amount: amount,
          sponsorshipType: sponsorshipType,
          duration: duration || 30, // default 30 days
          benefits: benefits || [],
          paymentIntentId: paymentIntentId,
          status: "active",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          startDate: admin.firestore.FieldValue.serverTimestamp(),
          endDate: new Date(
            Date.now() + (duration || 30) * 24 * 60 * 60 * 1000
          ),
        };

        const sponsorshipRef = await admin
          .firestore()
          .collection("sponsorships")
          .add(sponsorshipData);
        console.log(`🤝 Sponsorship record created: ${sponsorshipRef.id}`);

        // Update artist's balance (they get 80% of sponsorship)
        const artistShare = amount * 0.8;
        const artistRef = admin.firestore().collection("users").doc(artistId);
        await admin.firestore().runTransaction(async (transaction) => {
          const artistDoc = await transaction.get(artistRef);
          const currentBalance = artistDoc.data()?.balance || 0;
          const newBalance = currentBalance + artistShare;

          transaction.update(artistRef, {
            balance: newBalance,
            lastSponsorshipReceived:
              admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        console.log(`💰 Updated artist balance: +$${artistShare}`);

        // Record earnings for the artist
        await recordArtistEarnings(
          artistId,
          "sponsorship",
          artistShare,
          authUserId,
          decodedToken.name || "A Sponsor",
          `Sponsorship: ${sponsorshipType}`,
          {sponsorshipId: sponsorshipRef.id, sponsorshipType: sponsorshipType}
        );

        // Create notification for artist
        await admin
          .firestore()
          .collection("notifications")
          .add({
            userId: artistId,
            type: "sponsorship_received",
            title: "New Sponsorship!",
            message:
              `You received a ${sponsorshipType} sponsorship ` +
              `worth $${amount}`,
            data: {
              sponsorshipId: sponsorshipRef.id,
              sponsorId: authUserId,
              amount: amount,
              sponsorshipType: sponsorshipType,
            },
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

        response.status(200).send({
          success: true,
          sponsorshipId: sponsorshipRef.id,
          message: "Sponsorship activated successfully!",
        });
      } catch (error) {
        console.error("❌ Error processing sponsorship payment:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Process commission payment after payment intent is confirmed
 */
exports.processCommissionPayment = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 5,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🎨 processCommissionPayment called");
        console.log("🔍 Body:", JSON.stringify(request.body, null, 2));

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          return response.status(401).send({error: "Unauthorized"});
        }

        const idToken = authHeader.split("Bearer ")[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;

        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {
          paymentIntentId,
          artistId,
          amount,
          commissionType,
          description,
          deadline,
        } = request.body;

        if (!paymentIntentId || !artistId || !amount || !commissionType) {
          return response.status(400).send({
            error:
              "Missing required fields: paymentIntentId, artistId, " +
              "amount, commissionType",
          });
        }

        // Verify the payment intent was successful
        const paymentIntent = await stripe.paymentIntents.retrieve(
          paymentIntentId
        );

        if (paymentIntent.status !== "succeeded") {
          return response.status(400).send({
            error: `Payment not completed. Status: ${paymentIntent.status}`,
          });
        }

        console.log(`✅ Payment verified: ${paymentIntentId} for $${amount}`);

        // Create commission record in Firestore
        const commissionData = {
          clientId: authUserId,
          artistId: artistId,
          amount: amount,
          commissionType: commissionType,
          description: description || "",
          deadline: deadline || null,
          paymentIntentId: paymentIntentId,
          status: "pending", // Artist needs to accept
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          paymentHeld: true, // Payment is held until completion
        };

        const commissionRef = await admin
          .firestore()
          .collection("commissions")
          .add(commissionData);
        console.log(`🎨 Commission record created: ${commissionRef.id}`);

        // Record earnings for the artist as pending
        await recordArtistEarnings(
          artistId,
          "commission",
          amount,
          authUserId,
          decodedToken.name || "A Client",
          `Commission: ${commissionType}`,
          {commissionId: commissionRef.id, commissionType: commissionType},
          true // isPending = true
        );

        // Create notification for artist
        await admin
          .firestore()
          .collection("notifications")
          .add({
            userId: artistId,
            type: "commission_request",
            title: "New Commission Request!",
            message:
              `You have a new ${commissionType} commission request ` +
              `worth $${amount}`,
            data: {
              commissionId: commissionRef.id,
              clientId: authUserId,
              amount: amount,
              commissionType: commissionType,
            },
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

        response.status(200).send({
          success: true,
          commissionId: commissionRef.id,
          message: "Commission request sent successfully!",
        });
      } catch (error) {
        console.error("❌ Error processing commission payment:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Complete a commission and release held funds to the artist
 */
exports.completeCommission = onRequest(
  {
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 5,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        console.log("🎨 completeCommission called");

        // Verify Firebase Auth token
        const authHeader = request.headers.authorization;
        if (!authHeader || !authHeader.startsWith("Bearer ")) {
          return response.status(401).send({error: "Unauthorized"});
        }

        const idToken = authHeader.split("Bearer ")[1];
        const decodedToken = await admin.auth().verifyIdToken(idToken);
        const authUserId = decodedToken.uid;

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {commissionId} = request.body;

        if (!commissionId) {
          return response.status(400).send({error: "Missing commissionId"});
        }

        const firestore = admin.firestore();

        // 1. Find the commission in either collection
        let commissionRef = firestore.collection("commissions").doc(commissionId);
        let commissionDoc = await commissionRef.get();
        let isDirectCommission = false;

        if (!commissionDoc.exists) {
          commissionRef = firestore.collection("direct_commissions").doc(commissionId);
          commissionDoc = await commissionRef.get();
          isDirectCommission = true;
        }

        if (!commissionDoc.exists) {
          return response.status(404).send({error: "Commission not found"});
        }

        const commissionData = commissionDoc.data();

        // Verify authorization
        if (commissionData.artistId !== authUserId && commissionData.clientId !== authUserId) {
          return response.status(403).send({error: "Unauthorized to complete this commission"});
        }

        if (commissionData.status === "completed") {
          return response.status(400).send({error: "Commission already completed"});
        }

        // 2. Find ALL pending earnings transactions for this commission
        const transactionsQuery = await firestore.collection("earnings_transactions")
          .where("metadata.commissionId", "==", commissionId)
          .where("status", "==", "pending")
          .get();

        const artistId = commissionData.artistId;
        let totalAmountToRelease = 0;
        const transactionDocs = transactionsQuery.docs;

        transactionDocs.forEach((doc) => {
          totalAmountToRelease += doc.data().amount || 0;
        });

        // Fallback to commission amount if no transactions found (for legacy support)
        if (totalAmountToRelease === 0 && !isDirectCommission) {
          totalAmountToRelease = commissionData.amount || 0;
        }

        await firestore.runTransaction(async (transaction) => {
          // 3. Update commission status
          transaction.update(commissionRef, {
            status: "completed",
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
            paymentHeld: false,
          });

          if (totalAmountToRelease > 0) {
            // 4. Update artist earnings summary
            const earningsRef = firestore.collection("artist_earnings").doc(artistId);
            const earningsDoc = await transaction.get(earningsRef);

            if (earningsDoc.exists) {
              transaction.update(earningsRef, {
                availableBalance: admin.firestore.FieldValue.increment(totalAmountToRelease),
                pendingBalance: admin.firestore.FieldValue.increment(-totalAmountToRelease),
                lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
              });
            }

            // 5. Update artist's main balance in users collection
            const artistRef = firestore.collection("users").doc(artistId);
            transaction.update(artistRef, {
              balance: admin.firestore.FieldValue.increment(totalAmountToRelease),
              lastCommissionCompleted: admin.firestore.FieldValue.serverTimestamp(),
            });

            // 6. Update all relevant transaction records
            transactionDocs.forEach((doc) => {
              transaction.update(doc.ref, {
                status: "completed",
                completedAt: admin.firestore.FieldValue.serverTimestamp(),
              });
            });
          }
        });

        // 7. Create notifications
        const typeLabel = isDirectCommission ? "direct commission" : (commissionData.commissionType || "commission");
        const amountLabel = totalAmountToRelease > 0 ? `$${totalAmountToRelease}` : "funds";

        await firestore.collection("notifications").add({
          userId: commissionData.artistId,
          type: "commission_completed",
          title: "Commission Completed!",
          message: `Your ${typeLabel} "${commissionData.title || commissionData.description || ""}" is completed and ${amountLabel} has been added to your balance.`,
          data: { commissionId: commissionId },
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        await firestore.collection("notifications").add({
          userId: commissionData.clientId,
          type: "commission_completed_client",
          title: "Commission Finished!",
          message: `The artist has completed your ${typeLabel}.`,
          data: { commissionId: commissionId },
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        response.status(200).send({
          success: true,
          message: "Commission completed and funds released!",
          releasedAmount: totalAmountToRelease,
        });
      } catch (error) {
        console.error("❌ Error completing commission:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Request a refund
 */
exports.requestRefund = onRequest(
  {secrets: [stripeSecretKey]},
  (request, response) => {
    cors(request, response, async () => {
      try {
        const stripe = require("stripe")(stripeSecretKey.value());

        if (request.method !== "POST") {
          return response.status(405).send({error: "Method Not Allowed"});
        }

        const {paymentId, subscriptionId, userId, reason, additionalDetails, amount, metadata} =
          request.body;

        if (!paymentId || !userId || !reason) {
          return response.status(400).send({
            error: "Missing required fields",
          });
        }

        // Create refund in Stripe
        const refundOptions = {
          payment_intent: paymentId,
          reason: "requested_by_customer",
          metadata: {
            userId,
            subscriptionId: subscriptionId || "",
            refundReason: reason,
            additionalDetails: additionalDetails || "",
            ...(metadata || {}),
          },
        };

        // Add amount if provided (for partial refunds)
        if (amount) {
          refundOptions.amount = Math.round(amount * 100); // Convert to cents
        }

        const refund = await stripe.refunds.create(refundOptions);

        // Handle balance adjustments for commission refunds
        if (metadata && metadata.commissionId) {
          const commissionId = metadata.commissionId;
          const firestore = admin.firestore();

          // 1. Find the commission
          let commissionRef = firestore.collection("commissions").doc(commissionId);
          let commissionDoc = await commissionRef.get();

          if (!commissionDoc.exists) {
            commissionRef = firestore.collection("direct_commissions").doc(commissionId);
            commissionDoc = await commissionRef.get();
          }

          if (commissionDoc.exists) {
            const commissionData = commissionDoc.data();
            const artistId = commissionData.artistId;
            const refundAmount = amount || (refund.amount / 100);

            await firestore.runTransaction(async (transaction) => {
              // 2. Update artist earnings
              const earningsRef = firestore.collection("artist_earnings").doc(artistId);
              const earningsDoc = await transaction.get(earningsRef);

              if (earningsDoc.exists) {
                transaction.update(earningsRef, {
                  pendingBalance: admin.firestore.FieldValue.increment(-refundAmount),
                  totalEarnings: admin.firestore.FieldValue.increment(-refundAmount),
                  lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
                });
              }

              // 3. Update transaction records
              const transactionsQuery = await firestore.collection("earnings_transactions")
                .where("metadata.commissionId", "==", commissionId)
                .where("status", "==", "pending")
                .get();

              transactionsQuery.docs.forEach((doc) => {
                transaction.update(doc.ref, {
                  status: "refunded",
                  refundedAt: admin.firestore.FieldValue.serverTimestamp(),
                  stripeRefundId: refund.id,
                });
              });

              // 4. Update commission status if it was in progress or pending
              if (commissionData.status !== "completed") {
                transaction.update(commissionRef, {
                  status: "refunded",
                  refundedAt: admin.firestore.FieldValue.serverTimestamp(),
                });
              }
            });

            console.log(`✅ Balance adjusted for commission refund: $${refundAmount} for artist ${artistId}`);
          }
        }

        // Store refund request in Firestore
        await admin
          .firestore()
          .collection("refundRequests")
          .add({
            userId,
            paymentId,
            subscriptionId: subscriptionId || null,
            reason,
            amount: amount || null,
            additionalDetails: additionalDetails || "",
            metadata: metadata || null,
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

/**
 * Validate Apple IAP receipt
 * Handles both production and sandbox environments
 */
exports.validateAppleReceipt = onRequest(
  {
    secrets: [stripeSecretKey],
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 5,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
        const {receiptData, userId, productId} = request.body;

        if (!receiptData || !userId || !productId) {
          return response.status(400).send({
            error: "Missing required fields: receiptData, userId, productId",
          });
        }

        console.log(
          `🍎 Validating Apple receipt for user ${userId}, product ${productId}`
        );

        // First try production validation
        let validationResult = await validateReceiptWithApple(
          receiptData,
          false
        );

        // If production validation fails with sandbox receipt error, try sandbox
        if (validationResult.error && validationResult.error === "21007") {
          console.log(
            "🔄 Production validation failed with sandbox receipt error, trying sandbox..."
          );
          validationResult = await validateReceiptWithApple(receiptData, true);
        }

        if (validationResult.error) {
          console.error(
            "❌ Receipt validation failed:",
            validationResult.error
          );
          return response.status(400).send({
            error: "Receipt validation failed",
            details: validationResult.error,
          });
        }

        // Check if the receipt is for the correct product
        const receiptInfo = validationResult.receipt;
        const validPurchase = receiptInfo.in_app.find(
          (purchase) =>
            purchase.product_id === productId && purchase.transaction_id
        );

        if (!validPurchase) {
          console.error(
            "❌ Receipt does not contain valid purchase for product:",
            productId
          );
          return response.status(400).send({
            error: "Receipt does not contain valid purchase for this product",
          });
        }

        // Store validation result in Firestore for audit trail
        await admin
          .firestore()
          .collection("iapValidations")
          .add({
            userId,
            productId,
            transactionId: validPurchase.transaction_id,
            purchaseDate: new Date(parseInt(validPurchase.purchase_date_ms)),
            environment: validationResult.environment,
            validatedAt: admin.firestore.FieldValue.serverTimestamp(),
          });

        console.log(`✅ Apple receipt validated successfully for ${productId}`);
        response.status(200).send({
          success: true,
          transactionId: validPurchase.transaction_id,
          productId: validPurchase.product_id,
          purchaseDate: validPurchase.purchase_date_ms,
          environment: validationResult.environment,
        });
      } catch (error) {
        console.error("Error validating Apple receipt:", error);
        response.status(500).send({error: error.message});
      }
    });
  }
);

/**
 * Validate receipt with Apple's servers
 * @param {string} receiptData - Base64 encoded receipt data
 * @param {boolean} isSandbox - Whether to use sandbox environment
 * @return {Promise<Object>} Validation result
 */
async function validateReceiptWithApple(receiptData, isSandbox = false) {
  const url = isSandbox ?
    "https://sandbox.itunes.apple.com/verifyReceipt" :
    "https://buy.itunes.apple.com/verifyReceipt";

  const password = process.env.APPLE_SHARED_SECRET || ""; // You'll need to set this

  return new Promise((resolve, reject) => {
    const postData = JSON.stringify({
      "receipt-data": receiptData,
      "password": password,
      "exclude-old-transactions": true,
    });

    const options = {
      hostname: isSandbox ? "sandbox.itunes.apple.com" : "buy.itunes.apple.com",
      port: 443,
      path: "/verifyReceipt",
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(postData),
      },
    };

    const req = https.request(options, (res) => {
      let data = "";

      res.on("data", (chunk) => {
        data += chunk;
      });

      res.on("end", () => {
        try {
          const result = JSON.parse(data);

          if (result.status === 0) {
            // Success
            resolve({
              receipt: result.receipt,
              environment: isSandbox ? "sandbox" : "production",
            });
          } else {
            // Apple error codes
            resolve({
              error: result.status.toString(),
              message: getAppleErrorMessage(result.status),
            });
          }
        } catch (parseError) {
          reject(new Error("Failed to parse Apple response"));
        }
      });
    });

    req.on("error", (error) => {
      reject(error);
    });

    req.write(postData);
    req.end();
  });
}

/**
 * Get human-readable error message for Apple status codes
 * @param {number} statusCode - Apple status code
 * @return {string} Error message
 */
function getAppleErrorMessage(statusCode) {
  const errorMessages = {
    21000: "The App Store could not read the JSON object you provided.",
    21002: "The data in the receipt-data property was malformed or missing.",
    21003: "The receipt could not be authenticated.",
    21004:
      "The shared secret you provided does not match the shared secret on file.",
    21005: "The receipt server is not currently available.",
    21007:
      "This receipt is from the test environment, but it was sent to the production environment for verification.",
    21008:
      "This receipt is from the production environment, but it was sent to the test environment for verification.",
    21010:
      "This receipt could not be authorized. Treat this the same as if a purchase was never made.",
    21100: "Internal data access error.",
    21101: "Internal data access error.",
    21102: "Internal data access error.",
    21103: "Internal data access error.",
    21104: "Internal data access error.",
    21105: "Internal data access error.",
  };

  return errorMessages[statusCode] || `Unknown error code: ${statusCode}`;
}

/**
 * Place a bid on an auction artwork
 */
exports.placeBid = onRequest(
  {
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 5,
  },
  (request, response) => {
    cors(request, response, async () => {
      try {
      // Only allow POST requests
        if (request.method !== "POST") {
          return response.status(405).send({error: "Method not allowed"});
        }

        // Verify authentication
        if (!request.auth) {
          return response.status(401).send({error: "Authentication required"});
        }

        const {artworkId, amount} = request.body;
        const userId = request.auth.uid;

        if (!artworkId || !amount) {
          return response.status(400).send({error: "Missing required fields"});
        }

        const bidAmount = parseFloat(amount);
        if (isNaN(bidAmount) || bidAmount <= 0) {
          return response.status(400).send({error: "Invalid bid amount"});
        }

        // Get artwork data
        const artworkRef = admin
          .firestore()
          .collection("artworks")
          .doc(artworkId);
        const artworkDoc = await artworkRef.get();

        if (!artworkDoc.exists) {
          return response.status(404).send({error: "Artwork not found"});
        }

        const artwork = artworkDoc.data();

        // Validate auction is active
        if (!artwork.auctionEnabled || artwork.auctionStatus !== "open") {
          return response.status(400).send({error: "Auction is not active"});
        }

        // Check if auction has ended
        if (artwork.auctionEnd && artwork.auctionEnd.toDate() < new Date()) {
          return response.status(400).send({error: "Auction has ended"});
        }

        // Check if user is the artist
        if (artwork.userId === userId) {
          return response
            .status(400)
            .send({error: "Cannot bid on own artwork"});
        }

        // Get current highest bid
        const currentHighestBid =
        artwork.currentHighestBid || artwork.startingPrice || 0;

        // Validate bid amount
        if (bidAmount <= currentHighestBid) {
          return response.status(400).send({
            error: `Bid must be higher than current highest bid of $${currentHighestBid}`,
          });
        }

        // Create bid document
        const bidRef = artworkRef.collection("bids").doc();
        const bidData = {
          userId: userId,
          amount: bidAmount,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        };

        // Update artwork with new highest bid
        const artworkUpdate = {
          currentHighestBid: bidAmount,
          currentHighestBidder: userId,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        // Use transaction to ensure atomicity
        await admin.firestore().runTransaction(async (transaction) => {
        // Check current state again (optimistic locking)
          const currentArtwork = await transaction.get(artworkRef);
          if (!currentArtwork.exists) {
            throw new Error("Artwork no longer exists");
          }

          const currentData = currentArtwork.data();
          const currentHighest =
          currentData.currentHighestBid || currentData.startingPrice || 0;

          if (bidAmount <= currentHighest) {
            throw new Error(`Bid must be higher than $${currentHighest}`);
          }

          // Add the bid
          transaction.set(bidRef, bidData);

          // Update artwork
          transaction.update(artworkRef, artworkUpdate);
        });

        console.log(
          `✅ Bid placed: User ${userId} bid $${bidAmount} on artwork ${artworkId}`
        );

        response.status(200).send({
          success: true,
          bidId: bidRef.id,
          amount: bidAmount,
          timestamp: new Date(),
        });
      } catch (error) {
        console.error("❌ Error placing bid:", error);
        response.status(500).send({
          error: error.message || "Failed to place bid",
        });
      }
    });
  });

/**
 * Close auctions that have ended
 * Runs every minute to check for ended auctions
 */
exports.closeAuction = onSchedule(
  {
    schedule: "every 1 minutes",
    cpu: 0.25,
    memory: "256MiB",
    maxInstances: 2,
  },
  async (event) => {
    try {
      console.log("🔨 Checking for auctions to close...");

      const now = new Date();

      // Query artworks with active auctions that have ended
      const endedAuctionsQuery = admin
        .firestore()
        .collection("artworks")
        .where("auctionEnabled", "==", true)
        .where("auctionStatus", "==", "open")
        .where("auctionEnd", "<=", now);

      const endedAuctionsSnapshot = await endedAuctionsQuery.get();

      if (endedAuctionsSnapshot.empty) {
        console.log("✅ No auctions to close");
        return;
      }

      console.log(
        `📊 Found ${endedAuctionsSnapshot.docs.length} auctions to close`
      );

      const batch = admin.firestore().batch();

      for (const artworkDoc of endedAuctionsSnapshot.docs) {
        const artworkId = artworkDoc.id;
        const artwork = artworkDoc.data();

        console.log(`🔒 Closing auction for artwork: ${artworkId}`);

        const currentHighestBid = artwork.currentHighestBid || 0;
        const reservePrice = artwork.reservePrice || 0;
        const startingPrice = artwork.startingPrice || 0;

        let winner = null;
        let finalPrice = 0;
        let status = "no_sale";

        if (currentHighestBid >= reservePrice && currentHighestBid > 0) {
          winner = artwork.currentHighestBidder;
          finalPrice = currentHighestBid;
          status = "sold";
        } else if (reservePrice > 0 && currentHighestBid < reservePrice) {
        // Reserve not met
          status = "reserve_not_met";
        }

        // Create auction result document
        const resultRef = admin
          .firestore()
          .collection("artworks")
          .doc(artworkId)
          .collection("auction_results")
          .doc();

        const resultData = {
          artworkId: artworkId,
          artistId: artwork.userId,
          winnerId: winner,
          finalPrice: finalPrice,
          reservePrice: reservePrice,
          startingPrice: startingPrice,
          status: status,
          closedAt: admin.firestore.FieldValue.serverTimestamp(),
          auctionEnd: artwork.auctionEnd,
        };

        batch.set(resultRef, resultData);

        // Update artwork status
        const artworkUpdate = {
          auctionStatus: "closed",
          winnerId: winner,
          finalPrice: finalPrice,
          closedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        batch.update(artworkDoc.ref, artworkUpdate);

        // Create notifications
        if (winner) {
        // Notify winner
          const winnerNotificationRef = admin
            .firestore()
            .collection("notifications")
            .doc();
          batch.set(winnerNotificationRef, {
            userId: winner,
            type: "auction_won",
            title: "You won an auction!",
            message: `Congratulations! You won the auction for "${artwork.title}" by ${artwork.artistName}.`,
            artworkId: artworkId,
            read: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }

        // Notify artist
        const artistNotificationRef = admin
          .firestore()
          .collection("notifications")
          .doc();
        const artistMessage = winner ?
          `Your artwork "${artwork.title}" was sold for $${finalPrice}!` :
          `The auction for "${artwork.title}" ended without meeting the reserve price.`;
        batch.set(artistNotificationRef, {
          userId: artwork.userId,
          type: winner ? "auction_sold" : "auction_ended",
          title: winner ? "Artwork sold!" : "Auction ended",
          message: artistMessage,
          artworkId: artworkId,
          read: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      console.log(
        `✅ Successfully closed ${endedAuctionsSnapshot.docs.length} auctions`
      );
    } catch (error) {
      console.error("❌ Error closing auctions:", error);
    }
  });

/**
 * Get financial analytics data for admin dashboard
 * Requires admin authentication
 */
exports.getAdminFinancialAnalytics = functions.https.onRequest((request, response) => {
  cors(request, response, async () => {
    try {
      if (request.method !== "POST") {
        return response.status(405).send({error: "Method Not Allowed"});
      }

      // Verify admin authentication
      const authHeader = request.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return response.status(401).send({error: "Unauthorized: Missing token"});
      }

      const idToken = authHeader.split('Bearer ')[1];
      let decodedToken;

      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        return response.status(401).send({error: "Unauthorized: Invalid token"});
      }

      // Check if user is admin (you may want to check custom claims or a Firestore document)
      const userDoc = await admin.firestore().collection('users').doc(decodedToken.uid).get();
      const userData = userDoc.data();
      if (!userData || userData.role !== 'admin') {
        return response.status(403).send({error: "Forbidden: Admin access required"});
      }

      const { startDate, endDate } = request.body;

      if (!startDate || !endDate) {
        return response.status(400).send({
          error: "Missing required fields: startDate, endDate",
        });
      }

      const startUtc = new Date(startDate);
      const endUtc = new Date(endDate);
      const startTimestamp = admin.firestore.Timestamp.fromDate(startUtc);
      const endTimestamp = admin.firestore.Timestamp.fromDate(endUtc);

      // Fetch all financial metrics in parallel
      const [stripeMetrics, iapMetrics, subscriptionMetrics] = await Promise.all([
        getStripeMetrics(startUtc, endUtc),
        getIapMetrics(startTimestamp, endTimestamp),
        getSubscriptionMetrics(startTimestamp, endTimestamp)
      ]);

      // Calculate totals
      const totalGross = stripeMetrics.gross + iapMetrics.gross;
      const totalNet = stripeMetrics.net + iapMetrics.net;
      const totalRefunds = stripeMetrics.refunds + iapMetrics.refunds;
      const totalFees = stripeMetrics.fees;

      const currency = stripeMetrics.currency || iapMetrics.currency || "USD";

      response.status(200).send({
        success: true,
        data: {
          currency,
          stripe: stripeMetrics,
          iap: iapMetrics,
          subscriptions: subscriptionMetrics,
          totals: {
            gross: totalGross,
            net: totalNet,
            refunds: totalRefunds,
            fees: totalFees
          }
        }
      });
    } catch (error) {
      console.error("Error getting admin financial analytics:", error);
      response.status(500).send({error: error.message});
    }
  });
});

/* eslint-disable no-console */
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

async function backfillAdminUserType({dryRun = true} = {}) {
  const db = admin.firestore();
  const usersRef = db.collection("users");

  let lastDoc = null;
  let scanned = 0;
  let updated = 0;
  const batchSize = 400;

  let hasMore = true;
  while (hasMore) {
    let query = usersRef.orderBy("__name__").limit(batchSize);
    if (lastDoc) query = query.startAfter(lastDoc);

    const snapshot = await query.get();
    if (snapshot.empty) {
      hasMore = false;
      continue;
    }

    const batch = db.batch();
    for (const doc of snapshot.docs) {
      scanned += 1;
      const data = doc.data() || {};
      const userType = String(data.userType || "").trim().toLowerCase();
      const role = String(data.role || "").trim().toLowerCase();

      if (userType !== "admin" && role === "admin") {
        updated += 1;
        if (!dryRun) {
          batch.set(doc.ref, {
            userType: "admin",
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, {merge: true});
        }
      }
    }

    if (!dryRun) {
      await batch.commit();
    }

    lastDoc = snapshot.docs[snapshot.docs.length - 1];
    if (snapshot.size < batchSize) {
      hasMore = false;
    }
  }

  return {dryRun, scanned, updated};
}

async function run() {
  const args = new Set(process.argv.slice(2));
  const dryRun = !args.has("--apply");
  const result = await backfillAdminUserType({dryRun});
  console.log("backfill-admin-user-type result:", result);
  if (dryRun) {
    console.log("Dry run only. Re-run with --apply to persist changes.");
  }
}

run().catch((error) => {
  console.error("backfill-admin-user-type failed:", error);
  process.exitCode = 1;
});

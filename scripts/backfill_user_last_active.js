const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT,
  });
}

const db = admin.firestore();

function toDate(value) {
  if (!value) return null;
  if (typeof value.toDate === "function") return value.toDate();
  if (value instanceof Date) return value;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function getEffectiveLastActive(data) {
  const candidates = [toDate(data.lastActive), toDate(data.lastActiveAt)].filter(
    Boolean
  );
  if (candidates.length === 0) return null;
  return new Date(Math.max(...candidates.map((value) => value.getTime())));
}

async function backfillUserLastActive({dryRun = true, batchSize = 250} = {}) {
  let lastDoc = null;
  let scanned = 0;
  let updated = 0;

  while (true) {
    let query = db.collection("users").orderBy("__name__").limit(batchSize);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }

    const snapshot = await query.get();
    if (snapshot.empty) break;

    const batch = db.batch();

    for (const doc of snapshot.docs) {
      scanned += 1;
      const data = doc.data() || {};
      const effectiveLastActive = getEffectiveLastActive(data);

      if (!effectiveLastActive) continue;

      const currentLastActive = toDate(data.lastActive);
      const needsUpdate =
        currentLastActive == null ||
        currentLastActive.getTime() !== effectiveLastActive.getTime();

      if (!needsUpdate) continue;

      updated += 1;
      if (!dryRun) {
        batch.update(doc.ref, {
          lastActive: admin.firestore.Timestamp.fromDate(effectiveLastActive),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }

    if (!dryRun) {
      await batch.commit();
    }

    lastDoc = snapshot.docs[snapshot.docs.length - 1];
  }

  return {dryRun, scanned, updated};
}

async function main() {
  const dryRun = process.argv.includes("--write") ? false : true;
  const result = await backfillUserLastActive({dryRun});
  console.log(JSON.stringify(result, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

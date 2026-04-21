const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT,
  });
}

const db = admin.firestore();

function parseArgs() {
  const args = process.argv.slice(2);
  return {
    dryRun: !args.includes('--write'),
    userLimit: (() => {
      const idx = args.indexOf('--user-limit');
      if (idx >= 0 && args[idx + 1]) {
        return Math.max(1, parseInt(args[idx + 1], 10) || 1000);
      }
      return 1000;
    })(),
  };
}

async function cleanupSeededQuestEvents({dryRun = true, userLimit = 1000} = {}) {
  const usersSnap = await db.collection('users').orderBy('__name__').limit(userLimit).get();

  let usersScanned = 0;
  let usersTouched = 0;
  let deletedEvents = 0;

  for (const userDoc of usersSnap.docs) {
    usersScanned += 1;
    const eventsSnap = await userDoc.ref
      .collection('questEvents')
      .where('seeded', '==', true)
      .get();

    if (eventsSnap.empty) continue;

    usersTouched += 1;

    if (!dryRun) {
      let batch = db.batch();
      let ops = 0;
      for (const eventDoc of eventsSnap.docs) {
        batch.delete(eventDoc.ref);
        ops += 1;
        deletedEvents += 1;
        if (ops >= 400) {
          await batch.commit();
          batch = db.batch();
          ops = 0;
        }
      }
      if (ops > 0) await batch.commit();
    } else {
      deletedEvents += eventsSnap.docs.length;
    }
  }

  return {
    dryRun,
    usersScanned,
    usersTouched,
    deletedEvents,
  };
}

async function main() {
  const opts = parseArgs();
  const result = await cleanupSeededQuestEvents(opts);
  console.log(JSON.stringify(result, null, 2));
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});

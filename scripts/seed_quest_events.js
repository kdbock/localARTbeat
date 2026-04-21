const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT,
  });
}

const db = admin.firestore();

function parseArgs() {
  const args = process.argv.slice(2);
  const out = {
    dryRun: !args.includes('--write'),
    users: 3,
    days: 7,
    eventsPerDay: 4,
    userId: null,
  };

  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i];
    if (arg === '--users' && args[i + 1]) {
      out.users = Math.max(1, parseInt(args[i + 1], 10) || out.users);
      i += 1;
    } else if (arg === '--days' && args[i + 1]) {
      out.days = Math.max(1, parseInt(args[i + 1], 10) || out.days);
      i += 1;
    } else if (arg === '--events-per-day' && args[i + 1]) {
      out.eventsPerDay = Math.max(1, parseInt(args[i + 1], 10) || out.eventsPerDay);
      i += 1;
    } else if (arg === '--user-id' && args[i + 1]) {
      out.userId = args[i + 1];
      i += 1;
    }
  }

  return out;
}

async function getTargetUsers({users, userId}) {
  if (userId) {
    const doc = await db.collection('users').doc(userId).get();
    if (!doc.exists) throw new Error(`User not found: ${userId}`);
    return [doc];
  }

  const snap = await db.collection('users').orderBy('__name__').limit(users).get();
  return snap.docs;
}

function buildEvent({date, idx}) {
  const daily = idx % 2 === 0;
  const completed = idx % 3 === 0;
  const counted = idx % 5 !== 0;
  const reason = !counted ? 'no_progress' : completed ? 'completed' : 'progress_updated';
  const baseXP = daily ? 60 : 450;
  const awarded = counted && completed ? Math.round(baseXP * 1.15) : 0;

  return {
    eventType: daily ? 'daily_progress_update' : 'weekly_progress_update',
    entityId: daily ? `seed_daily_${idx}` : `seed_weekly_${idx}`,
    increment: daily ? 1 : 2,
    counted,
    reason,
    payload: {
      counted,
      reason,
      newProgress: completed ? 10 : 4,
      target: 10,
      xpAwarded: awarded,
      baseXP,
    },
    createdAt: admin.firestore.Timestamp.fromDate(date),
    seeded: true,
    seededAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

async function seedQuestEvents(opts) {
  const users = await getTargetUsers(opts);
  const now = new Date();

  let writeCount = 0;

  for (const user of users) {
    let batch = db.batch();
    let ops = 0;

    for (let d = 0; d < opts.days; d += 1) {
      for (let i = 0; i < opts.eventsPerDay; i += 1) {
        const eventDate = new Date(now);
        eventDate.setUTCDate(eventDate.getUTCDate() - d);
        eventDate.setUTCHours(12, i * 10, 0, 0);

        const event = buildEvent({date: eventDate, idx: d * opts.eventsPerDay + i});
        writeCount += 1;

        if (!opts.dryRun) {
          const ref = user.ref.collection('questEvents').doc();
          batch.set(ref, event);
          ops += 1;
          if (ops >= 400) {
            await batch.commit();
            batch = db.batch();
            ops = 0;
          }
        }
      }
    }

    if (!opts.dryRun && ops > 0) {
      await batch.commit();
    }
  }

  return {
    dryRun: opts.dryRun,
    usersTargeted: users.length,
    days: opts.days,
    eventsPerDay: opts.eventsPerDay,
    eventsPrepared: writeCount,
  };
}

async function main() {
  const opts = parseArgs();
  const result = await seedQuestEvents(opts);
  console.log(JSON.stringify(result, null, 2));
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});

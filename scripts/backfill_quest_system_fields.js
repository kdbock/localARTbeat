const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT,
  });
}

const db = admin.firestore();

const DAILY_CATEGORY_BY_TEMPLATE = {
  discover_art: 'exploration',
  discover_neighborhood: 'exploration',
  capture_photos: 'photography',
  golden_hour: 'photography',
  social_share: 'social',
  community_connector: 'social',
  walk_distance: 'walking',
  step_master: 'walking',
  early_bird: 'time',
  night_owl: 'time',
  art_critic: 'engagement',
  style_collector: 'engagement',
  streak_warrior: 'streak',
};

const DAILY_TEMPLATE_PREFIXES = Object.keys(DAILY_CATEGORY_BY_TEMPLATE);

const WEEKLY_TEMPLATE_PREFIXES = [
  'weekly_explorer',
  'weekly_neighborhoods',
  'weekly_photographer',
  'weekly_golden_hour',
  'weekly_social_butterfly',
  'weekly_community_builder',
  'weekly_walker',
  'weekly_step_champion',
  'weekly_quest_master',
  'weekly_streak_keeper',
  'weekly_style_collector',
  'weekly_artist_fan',
];

function normalize(value) {
  return typeof value === 'string' ? value.trim().toLowerCase() : '';
}

function inferDailyTemplateId(data) {
  const id = normalize(data.id);
  for (const prefix of DAILY_TEMPLATE_PREFIXES) {
    if (id.startsWith(`${prefix}_`) || id === prefix) return prefix;
  }

  const title = normalize(data.title);
  if (title.includes('neighborhood')) return 'discover_neighborhood';
  if (title.includes('discover') || title.includes('explore')) return 'discover_art';
  if (title.includes('golden')) return 'golden_hour';
  if (title.includes('photo')) return 'capture_photos';
  if (title.includes('connector') || title.includes('community')) return 'community_connector';
  if (title.includes('share')) return 'social_share';
  if (title.includes('step')) return 'step_master';
  if (title.includes('walk') || title.includes('wanderer')) return 'walk_distance';
  if (title.includes('early')) return 'early_bird';
  if (title.includes('night')) return 'night_owl';
  if (title.includes('critic')) return 'art_critic';
  if (title.includes('style')) return 'style_collector';
  if (title.includes('streak')) return 'streak_warrior';

  return null;
}

function inferWeeklyTemplateId(data) {
  const id = normalize(data.id);
  for (const prefix of WEEKLY_TEMPLATE_PREFIXES) {
    if (id.startsWith(`${prefix}_`) || id === prefix) return prefix;
  }

  const title = normalize(data.title);
  if (title.includes('neighborhood')) return 'weekly_neighborhoods';
  if (title.includes('explorer')) return 'weekly_explorer';
  if (title.includes('photographer')) return 'weekly_photographer';
  if (title.includes('golden')) return 'weekly_golden_hour';
  if (title.includes('social')) return 'weekly_social_butterfly';
  if (title.includes('community')) return 'weekly_community_builder';
  if (title.includes('walker')) return 'weekly_walker';
  if (title.includes('step')) return 'weekly_step_champion';
  if (title.includes('quest master')) return 'weekly_quest_master';
  if (title.includes('streak')) return 'weekly_streak_keeper';
  if (title.includes('style')) return 'weekly_style_collector';
  if (title.includes('artist')) return 'weekly_artist_fan';

  return null;
}

async function processCollectionDocs({docs, dryRun, buildPatch}) {
  let updated = 0;
  let unresolved = 0;

  let batch = db.batch();
  let opCount = 0;

  async function flush() {
    if (!dryRun && opCount > 0) {
      await batch.commit();
    }
    batch = db.batch();
    opCount = 0;
  }

  for (const doc of docs) {
    const patch = buildPatch(doc.data() || {});
    if (patch.unresolved) {
      unresolved += 1;
      continue;
    }
    if (!patch.update || Object.keys(patch.update).length === 0) continue;

    updated += 1;
    if (!dryRun) {
      batch.update(doc.ref, patch.update);
      opCount += 1;
      if (opCount >= 400) await flush();
    }
  }

  await flush();
  return {updated, unresolved};
}

async function backfillQuestSystemFields({dryRun = true, batchSize = 100} = {}) {
  let lastDoc = null;
  let usersScanned = 0;
  let usersUpdated = 0;
  let dailyDocsUpdated = 0;
  let weeklyDocsUpdated = 0;
  let dailyUnresolved = 0;
  let weeklyUnresolved = 0;

  while (true) {
    let query = db.collection('users').orderBy('__name__').limit(batchSize);
    if (lastDoc) query = query.startAfter(lastDoc);

    const snapshot = await query.get();
    if (snapshot.empty) break;

    for (const userDoc of snapshot.docs) {
      usersScanned += 1;
      const userRef = userDoc.ref;
      const userData = userDoc.data() || {};

      let touchedUser = false;
      let userPatch = {};

      if (userData.experiencePoints == null && userData.totalXP != null) {
        userPatch.experiencePoints = userData.totalXP;
        touchedUser = true;
      }

      const dailySnap = await userRef.collection('dailyChallenges').get();
      const dailyResult = await processCollectionDocs({
        docs: dailySnap.docs,
        dryRun,
        buildPatch: (data) => {
          const update = {};
          let unresolved = false;

          let templateId = data.templateId;
          if (!templateId) {
            templateId = inferDailyTemplateId(data);
            if (templateId) update.templateId = templateId;
            else unresolved = true;
          }

          const categoryId = data.categoryId;
          if (!categoryId && templateId) {
            const mapped = DAILY_CATEGORY_BY_TEMPLATE[templateId];
            if (mapped) update.categoryId = mapped;
          }

          return {update, unresolved};
        },
      });
      dailyDocsUpdated += dailyResult.updated;
      dailyUnresolved += dailyResult.unresolved;

      const weeklySnap = await userRef.collection('weeklyGoals').get();
      const weeklyResult = await processCollectionDocs({
        docs: weeklySnap.docs,
        dryRun,
        buildPatch: (data) => {
          const update = {};
          const templateId = data.templateId || inferWeeklyTemplateId(data);
          if (!data.templateId && templateId) update.templateId = templateId;
          return {update, unresolved: !templateId};
        },
      });
      weeklyDocsUpdated += weeklyResult.updated;
      weeklyUnresolved += weeklyResult.unresolved;

      if (dailyResult.updated > 0 || weeklyResult.updated > 0 || touchedUser) {
        usersUpdated += 1;
        userPatch = {
          ...userPatch,
          migrations: {
            questSystemV2At: admin.firestore.FieldValue.serverTimestamp(),
          },
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        if (!dryRun) {
          await userRef.set(userPatch, {merge: true});
        }
      }
    }

    lastDoc = snapshot.docs[snapshot.docs.length - 1];
  }

  return {
    dryRun,
    usersScanned,
    usersUpdated,
    dailyDocsUpdated,
    weeklyDocsUpdated,
    dailyUnresolved,
    weeklyUnresolved,
  };
}

async function main() {
  const dryRun = process.argv.includes('--write') ? false : true;
  const result = await backfillQuestSystemFields({dryRun});
  console.log(JSON.stringify(result, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

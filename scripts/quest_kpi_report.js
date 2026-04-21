const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT,
  });
}

const db = admin.firestore();

function fmtDate(date) {
  return date.toISOString().slice(0, 10);
}

function parseArgs() {
  const args = process.argv.slice(2);
  const out = {days: 14, userLimit: 1000};
  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i];
    if (arg === '--days' && args[i + 1]) {
      out.days = Math.max(1, parseInt(args[i + 1], 10) || 14);
      i += 1;
    } else if (arg === '--user-limit' && args[i + 1]) {
      out.userLimit = Math.max(1, parseInt(args[i + 1], 10) || 1000);
      i += 1;
    }
  }
  return out;
}

function createDayBucketMap(days) {
  const buckets = new Map();
  const now = new Date();
  for (let i = 0; i < days; i += 1) {
    const d = new Date(now);
    d.setUTCDate(d.getUTCDate() - i);
    buckets.set(fmtDate(d), {
      date: fmtDate(d),
      totalEvents: 0,
      countedEvents: 0,
      rejectedEvents: 0,
      xpAwardedTotal: 0,
      xpAwardedCount: 0,
      completionEvents: 0,
      reasons: {},
      dailyCountedUsers: new Set(),
      weeklyCountedUsers: new Set(),
      dailyCompletedUsers: new Set(),
      weeklyCompletedUsers: new Set(),
      perfectWeekUsers: new Set(),
    });
  }
  return buckets;
}

function percentile(values, p) {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const idx = Math.min(sorted.length - 1, Math.max(0, Math.floor((p / 100) * sorted.length)));
  return sorted[idx];
}

async function fetchUsers(userLimit) {
  let query = db.collection('users').orderBy('__name__').limit(userLimit);
  const snap = await query.get();
  return snap.docs;
}

async function generateReport({days, userLimit}) {
  const now = new Date();
  const start = new Date(now);
  start.setUTCDate(start.getUTCDate() - (days - 1));

  const buckets = createDayBucketMap(days);
  const completionXp = [];

  const users = await fetchUsers(userLimit);

  for (const userDoc of users) {
    const userId = userDoc.id;

    const eventsSnap = await userDoc.ref
      .collection('questEvents')
      .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(start))
      .get();

    for (const doc of eventsSnap.docs) {
      const data = doc.data() || {};
      const ts = data.createdAt;
      const date = ts && typeof ts.toDate === 'function' ? fmtDate(ts.toDate()) : null;
      if (!date || !buckets.has(date)) continue;

      const b = buckets.get(date);
      b.totalEvents += 1;
      const counted = data.counted === true;
      if (counted) b.countedEvents += 1;
      else b.rejectedEvents += 1;

      const reason = String(data.reason || 'unknown');
      b.reasons[reason] = (b.reasons[reason] || 0) + 1;

      const eventType = String(data.eventType || '');
      const payload = data.payload || {};
      const xpAwarded = Number(payload.xpAwarded || 0);
      if (xpAwarded > 0) {
        b.xpAwardedTotal += xpAwarded;
        b.xpAwardedCount += 1;
      }

      if (eventType === 'daily_progress_update' && counted) {
        b.dailyCountedUsers.add(userId);
        if (reason === 'completed') {
          b.dailyCompletedUsers.add(userId);
          b.completionEvents += 1;
          completionXp.push(xpAwarded);
        }
      }
      if (eventType === 'weekly_progress_update' && counted) {
        b.weeklyCountedUsers.add(userId);
        if (reason === 'completed') {
          b.weeklyCompletedUsers.add(userId);
          b.completionEvents += 1;
          completionXp.push(xpAwarded);
        }
      }
    }

    const weeklyGoalsSnap = await userDoc.ref.collection('weeklyGoals').get();

    const byWeek = new Map();
    for (const doc of weeklyGoalsSnap.docs) {
      const d = doc.data() || {};
      if (d.isCompleted !== true) continue;
      const completedAt = d.completedAt && typeof d.completedAt.toDate === 'function'
        ? d.completedAt.toDate()
        : null;
      if (!completedAt || completedAt < start) continue;
      const key = `${d.year || 'y'}-${d.weekNumber || 'w'}`;
      byWeek.set(key, (byWeek.get(key) || 0) + 1);
    }

    for (const [, count] of byWeek.entries()) {
      if (count >= 3) {
        const today = fmtDate(now);
        if (buckets.has(today)) buckets.get(today).perfectWeekUsers.add(userId);
      }
    }
  }

  const daily = [...buckets.values()].sort((a, b) => a.date.localeCompare(b.date));

  const summary = {
    windowDays: days,
    usersScanned: users.length,
    totals: {
      events: daily.reduce((s, d) => s + d.totalEvents, 0),
      counted: daily.reduce((s, d) => s + d.countedEvents, 0),
      rejected: daily.reduce((s, d) => s + d.rejectedEvents, 0),
    },
    kpis: {
      countedRatio:
        daily.reduce((s, d) => s + d.countedEvents, 0) /
        Math.max(1, daily.reduce((s, d) => s + d.totalEvents, 0)),
      dailyCompletionRate:
        daily.reduce((s, d) => s + d.dailyCompletedUsers.size, 0) /
        Math.max(1, daily.reduce((s, d) => s + d.dailyCountedUsers.size, 0)),
      weeklyCompletionRate:
        daily.reduce((s, d) => s + d.weeklyCompletedUsers.size, 0) /
        Math.max(1, daily.reduce((s, d) => s + d.weeklyCountedUsers.size, 0)),
      perfectWeekRate:
        daily[daily.length - 1]?.perfectWeekUsers.size / Math.max(1, users.length),
      averageCompletionXP:
        completionXp.reduce((s, v) => s + v, 0) / Math.max(1, completionXp.length),
      p95CompletionXP: percentile(completionXp, 95),
      rejectionRate:
        daily.reduce((s, d) => s + d.rejectedEvents, 0) /
        Math.max(1, daily.reduce((s, d) => s + d.totalEvents, 0)),
    },
    thresholds: {
      dailyCompletionRate: [0.45, 0.65],
      weeklyCompletionRate: [0.20, 0.35],
      perfectWeekRate: [0.05, 0.10],
      rejectionRateMax: 0.05,
    },
  };

  const alerts = [];
  if (summary.kpis.dailyCompletionRate < 0.45) alerts.push('daily_completion_below_target');
  if (summary.kpis.dailyCompletionRate > 0.65) alerts.push('daily_completion_above_target');
  if (summary.kpis.weeklyCompletionRate < 0.20) alerts.push('weekly_completion_below_target');
  if (summary.kpis.weeklyCompletionRate > 0.35) alerts.push('weekly_completion_above_target');
  if (summary.kpis.perfectWeekRate < 0.05) alerts.push('perfect_week_below_target');
  if (summary.kpis.perfectWeekRate > 0.10) alerts.push('perfect_week_above_target');
  if (summary.kpis.rejectionRate > 0.05) alerts.push('rejection_rate_above_target');

  return {
    summary,
    alerts,
    daily: daily.map((d) => ({
      date: d.date,
      totalEvents: d.totalEvents,
      countedEvents: d.countedEvents,
      rejectedEvents: d.rejectedEvents,
      countedRatio: d.countedEvents / Math.max(1, d.totalEvents),
      dailyCompletionRate: d.dailyCompletedUsers.size / Math.max(1, d.dailyCountedUsers.size),
      weeklyCompletionRate: d.weeklyCompletedUsers.size / Math.max(1, d.weeklyCountedUsers.size),
      averageXpAwarded: d.xpAwardedTotal / Math.max(1, d.xpAwardedCount),
      reasons: d.reasons,
    })),
  };
}

async function main() {
  const args = parseArgs();
  const report = await generateReport(args);
  console.log(JSON.stringify(report, null, 2));
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});

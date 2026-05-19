# UX Baseline Queries (Phase 0)

Last updated: May 18, 2026

## Purpose

Operational query guide for Phase 0 UX metrics based on the implemented event contract.

Primary event sources:
- GA4/Firebase Analytics export (BigQuery): `ux_session_start`, `ux_splash_shown`, `ux_splash_to_dashboard`, `ux_auth_interrupt`, `ux_route_rendered`, `ux_first_meaningful_action`
- Firestore collections (optional secondary): `route_analytics`, `onboarding_funnel_events`

## Assumptions

- Replace `<PROJECT>.<DATASET>` with your GA4 export dataset.
- Replace date filters as needed.
- Event parameters are stored in `event_params` in GA4 export tables.

---

## 1) First-Session Completion Rate

Definition:
- Session considered started when `ux_session_start` exists.
- Session considered completed when `ux_first_meaningful_action` exists.

```sql
-- BigQuery (GA4 export)
WITH starts AS (
  SELECT
    (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'session_id') AS session_id
  FROM `<PROJECT>.<DATASET>.events_*`
  WHERE event_name = 'ux_session_start'
    AND _TABLE_SUFFIX BETWEEN '20260518' AND '20260618'
),
completions AS (
  SELECT DISTINCT
    (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'session_id') AS session_id
  FROM `<PROJECT>.<DATASET>.events_*`
  WHERE event_name = 'ux_first_meaningful_action'
    AND _TABLE_SUFFIX BETWEEN '20260518' AND '20260618'
)
SELECT
  COUNT(DISTINCT s.session_id) AS sessions_started,
  COUNT(DISTINCT c.session_id) AS sessions_completed,
  SAFE_DIVIDE(COUNT(DISTINCT c.session_id), COUNT(DISTINCT s.session_id)) AS completion_rate
FROM starts s
LEFT JOIN completions c USING (session_id);
```

---

## 2) Median Time to First Meaningful Action

```sql
WITH actions AS (
  SELECT
    (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'session_id') AS session_id,
    (SELECT ep.value.int_value FROM UNNEST(event_params) ep WHERE ep.key = 'duration_ms') AS duration_ms
  FROM `<PROJECT>.<DATASET>.events_*`
  WHERE event_name = 'ux_first_meaningful_action'
    AND _TABLE_SUFFIX BETWEEN '20260518' AND '20260618'
)
SELECT
  APPROX_QUANTILES(duration_ms, 100)[OFFSET(50)] AS p50_duration_ms,
  APPROX_QUANTILES(duration_ms, 100)[OFFSET(90)] AS p90_duration_ms,
  AVG(duration_ms) AS avg_duration_ms
FROM actions
WHERE duration_ms IS NOT NULL;
```

---

## 3) Auth Interruption Rate

Definition:
- `ux_auth_interrupt` sessions / `ux_session_start` sessions

```sql
WITH starts AS (
  SELECT DISTINCT
    (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'session_id') AS session_id
  FROM `<PROJECT>.<DATASET>.events_*`
  WHERE event_name = 'ux_session_start'
    AND _TABLE_SUFFIX BETWEEN '20260518' AND '20260618'
),
auth_interrupts AS (
  SELECT DISTINCT
    (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'session_id') AS session_id
  FROM `<PROJECT>.<DATASET>.events_*`
  WHERE event_name = 'ux_auth_interrupt'
    AND _TABLE_SUFFIX BETWEEN '20260518' AND '20260618'
)
SELECT
  COUNT(DISTINCT s.session_id) AS sessions_started,
  COUNT(DISTINCT a.session_id) AS sessions_with_auth_interrupt,
  SAFE_DIVIDE(COUNT(DISTINCT a.session_id), COUNT(DISTINCT s.session_id)) AS auth_interrupt_rate
FROM starts s
LEFT JOIN auth_interrupts a USING (session_id);
```

---

## 4) Top Interrupted Routes

```sql
SELECT
  (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'route_name') AS route_name,
  COUNT(*) AS interrupt_count
FROM `<PROJECT>.<DATASET>.events_*`
WHERE event_name = 'ux_auth_interrupt'
  AND _TABLE_SUFFIX BETWEEN '20260518' AND '20260618'
GROUP BY route_name
ORDER BY interrupt_count DESC
LIMIT 20;
```

---

## 5) Route Render Health (Success + Latency)

```sql
WITH renders AS (
  SELECT
    (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'route_name') AS route_name,
    (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'source') AS source,
    (SELECT ep.value.int_value FROM UNNEST(event_params) ep WHERE ep.key = 'duration_ms') AS duration_ms,
    (SELECT ep.value.int_value FROM UNNEST(event_params) ep WHERE ep.key = 'success') AS success
  FROM `<PROJECT>.<DATASET>.events_*`
  WHERE event_name = 'ux_route_rendered'
    AND _TABLE_SUFFIX BETWEEN '20260518' AND '20260618'
)
SELECT
  route_name,
  source,
  COUNT(*) AS render_events,
  SAFE_DIVIDE(SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END), COUNT(*)) AS success_rate,
  APPROX_QUANTILES(duration_ms, 100)[OFFSET(50)] AS p50_duration_ms,
  APPROX_QUANTILES(duration_ms, 100)[OFFSET(90)] AS p90_duration_ms
FROM renders
GROUP BY route_name, source
ORDER BY render_events DESC
LIMIT 50;
```

---

## 6) First Meaningful Action Mix

```sql
SELECT
  (SELECT ep.value.string_value FROM UNNEST(event_params) ep WHERE ep.key = 'action') AS action,
  COUNT(*) AS action_count
FROM `<PROJECT>.<DATASET>.events_*`
WHERE event_name = 'ux_first_meaningful_action'
  AND _TABLE_SUFFIX BETWEEN '20260518' AND '20260618'
GROUP BY action
ORDER BY action_count DESC;
```

---

## 7) Firestore Fallback Queries (If BigQuery Not Ready)

Use Firestore collections:
- `route_analytics` for route visits and route popularity
- `onboarding_funnel_events` for onboarding progression

Suggested quick checks:
- Count docs in `onboarding_funnel_events` with `event_name = onboarding_completion` and `recorded_at >= now - 7d`
- Aggregate `route_analytics` by `route_name` and date bucket

---

## 8) Baseline Dashboard Minimum Widgets

1. Sessions Started (daily)
2. First-Session Completion Rate (daily)
3. P50/P90 Time to First Meaningful Action
4. Auth Interruption Rate
5. Top 10 Interrupted Routes
6. Top 10 First Meaningful Actions
7. Route Render Success Rate (top routes)

---

## 9) Data Quality Checks

- `ux_session_start` volume should approximate app opens.
- `ux_first_meaningful_action` should be <= `ux_session_start` volume.
- Unknown `route_name` in `ux_auth_interrupt` should be near zero.
- `duration_ms` should be non-negative and sane (filter obvious outliers > 1 day).

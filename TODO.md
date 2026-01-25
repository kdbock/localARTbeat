Performance Audit Tracking List

Top 10 likely causes of 3–6s UI delays
- [x] Replace geocoding in distance sorts with stored lat/lng fields and local distance math.
- [x] Paginate artist browse queries and avoid full-collection fetch + in-memory filters.
- [x] Add search debounce in artist browse to reduce repeated fetch/sort work.
- [x] Remove N+1 artist profile lookups in local artwork rows (batch fetch names).
- [x] Parallelize GalleryHub data loading and use Firestore count aggregates.
- [x] Fix auction activity N+1 queries by using collectionGroup bids.
- [x] Move distance sort out of real-time artist stream; throttle/async cache instead.
- [x] Push upcoming events filters to Firestore and reduce local filtering/sorting.
- [x] Cache notification summaries/unread counts to avoid heavy rebuild filtering.
- [x] Use cached/last known location and lazy marker loading in dashboard map.

- [x] Artist browse screen (full fetch + distance sort).
- [x] Artist subscription service getAllArtists (in-memory filters + geocoding).
- [x] Local artists row widget (nested FutureBuilders + distance sort).
- [x] Art community artist stream (distance sort each snapshot).
- [x] Gallery hub screen (sequential Firestore queries + scans).
- [x] Artist public profile screen (multi-query + follow checks).
- [x] Local artwork row widget (per-item artist profile fetch).
- [x] Upcoming events row widget (local filtering + Image.network).
- [x] Dashboard view model location + marker build.
- [x] Community service getPosts (N+1 like status checks).

Concrete code changes
- [x] Store location lat/lng in artist profiles at write-time; use for distance sort.
- [x] Add displayNameLower/keywords and indexed search query for artists (query uses displayNameLower; backfill function added and run).
- [x] Add debounce timer to artist search input; only query after pause.
- [x] Batch fetch artist names for LocalArtworkRowWidget (whereIn).
- [x] Replace artwork/profile view counts with Firestore count() aggregates.
- [x] Replace auction bids per-artwork loop with collectionGroup('bids') query (requires bids include artistId).
 - [x] Throttle ArtCommunityService artist stream sorting (cache + location change only).
- [x] Convert UpcomingEventsRowWidget to zip/isPublic/server-side sort query.
- [x] Cache notification summary/unread count in user doc (Cloud Function).
- [x] Use cached notification summary doc when present (UI-side).
- [x] Use lastKnownPosition or stored zip before requesting live GPS.
- [x] Add marker clustering or limit markers for map previews (grid clustering + limit).
- [x] Batch fetch post like status in CommunityService.getPosts (whereIn).

Instrumentation plan
- [x] Profile mode trace for tap delay and jank (DevTools Performance tab).
- [x] Add Timeline spans for getAllArtists and distance sorting.
- [x] Add Timeline spans for GalleryHub data load and counts.
- [x] Log frame timings and slow frame warnings.
- [x] Add image cache stats + large decode logging.
- [x] Add Timeline spans for GalleryHub activity subqueries.
- [x] Add decode size logging for SecureNetworkImage & OptimizedImage.
- [x] Enable build/rebuild debug flags in debug builds.

Quick wins (< 1 hour)
- [x] Add debounce to artist search.
- [x] Remove per-item FutureBuilder in LocalArtworkRowWidget.
- [x] Reduce upcoming events limit and push filters to query.
- [x] Add const widgets in hot lists where possible.

Medium fixes (1–3 days)
- [x] Persist lat/lng for profiles (write paths).
- [x] Backfill existing artistProfiles with locationLat/locationLng (lazy on read).
- [x] Paginate artist browse with indexed search fields (UI + service pagination + backfill function).
- [x] Parallelize GalleryHub queries + count() usage.
 - [x] Throttle distance sort in live artist streams.

Long-term fixes
- [ ] Backend aggregates for counts and summaries.
- [ ] Server-side search (Algolia/Typesense) for artists/events.
- [ ] Geohash-based geoqueries for artists/events.
- [ ] Normalize frequently read artist fields into artwork/post docs.

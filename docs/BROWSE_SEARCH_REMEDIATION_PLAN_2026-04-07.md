# Browse + Search Remediation Plan (2026-04-07)

## Goals
- Bring all browse/search screens to one visual system (HUD/glass/world background).
- Raise search quality from local filtering to ranked retrieval.
- Standardize UX behavior (filters, sort, empty/error, pagination, history, suggestions).
- Deliver in safe phases so release risk stays low.

## Phase 1: Theme and UX Consistency (UI-first, low backend risk)
### Scope
- `packages/artbeat_messaging/lib/src/screens/chat_search_screen.dart`
- `packages/artbeat_artwork/lib/src/screens/advanced_artwork_search_screen.dart`
- `packages/artbeat_community/lib/screens/studios/studio_discovery_screen.dart`
- `packages/artbeat_artwork/lib/src/screens/written_content_discovery_screen.dart`

### Definition of done
- Uses `MainLayout` + current branded header/background components.
- Uses glass cards/inputs/buttons (no legacy plain Material shells).
- Consistent loading/empty/error states with action CTA.
- Responsive layout holds on narrow phones and tablets.

## Phase 2: Search Interaction Standardization
### Scope
- Core unified search + artwork advanced + event search + art-walk search.

### Required behaviors
- Debounced query updates.
- Active filter summary chips with one-tap clear.
- Sort controls with visible selected state.
- Recent search history + reusable suggestions.
- Result count and query echo (`x results for "query"`).
- Pagination or progressive loading where result sets can grow.

## Phase 3: Retrieval Quality Upgrade
### Scope
- Replace broad client-side filtering where possible.

### Required changes
- Add indexed server-side query paths for high-volume entities.
- Introduce relevance ranking (title hit > tags > description).
- Add typo tolerance strategy (backend index or secondary fuzzy match pass).
- Keep analytics hooks for top queries, no-result queries, and filter usage.

## Phase 4: Discovery Value Layer
### Scope
- `full_browse_screen`, discovery tabs, and browse entry points.

### Required additions
- Personalized rails ("because you viewed/captured/followed").
- Dynamic trending sections (timeboxed and local).
- Cross-navigation recommendations (artist -> artwork -> event/walk).

## Immediate Execution Queue (starting now)
1. Done: Modernize chat search screen visual shell and states.
2. Next: Modernize advanced artwork search screen UI shell while preserving filters.
3. Next: Modernize studio discovery screen UI shell and filters.
4. Next: Modernize written content discovery screen UI shell and tab/filter dialogs.
5. Then: Standardize filter/sort UX patterns across all search screens.

## Risk Controls
- Keep route names unchanged.
- Do not change service contracts in Phase 1.
- Run `flutter analyze` for touched files each step.
- Add/update focused widget tests for role/visibility and empty/error states.

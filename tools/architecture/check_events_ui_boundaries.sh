#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_events/lib/src/screens/event_details_screen.dart"
  "packages/artbeat_events/lib/src/screens/events_dashboard_screen.dart"
  "packages/artbeat_events/lib/src/screens/user_events_dashboard_screen.dart"
  "packages/artbeat_events/lib/src/screens/my_tickets_screen.dart"
  "packages/artbeat_events/lib/src/screens/events_list_screen.dart"
  "packages/artbeat_events/lib/src/screens/event_search_screen.dart"
  "packages/artbeat_events/lib/src/screens/event_details_wrapper.dart"
  "packages/artbeat_events/lib/src/screens/create_event_screen.dart"
  "packages/artbeat_events/lib/src/screens/calendar_screen.dart"
  "packages/artbeat_events/lib/src/screens/event_bulk_management_screen.dart"
  "packages/artbeat_events/lib/src/widgets/ticket_purchase_sheet.dart"
  "packages/artbeat_events/lib/src/widgets/events_drawer.dart"
  "packages/artbeat_events/lib/src/widgets/community_feed_events_widget.dart"
  "packages/artbeat_events/lib/src/widgets/social_feed_widget.dart"
)

violations=()
pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance|EventService\(|EventNotificationService\(|EventBulkManagementService\(|SocialIntegrationService\(|CalendarIntegrationService\(|UserService\(|UnifiedPaymentService\(|OnboardingService\('

for file in "${files[@]}"; do
  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Events UI boundary check failed."
  echo "These event surfaces must use app-owned services instead of local service construction or direct Firebase singletons:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Events UI boundary check passed."

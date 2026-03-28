#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

files=(
  "packages/artbeat_admin/lib/src/widgets/admin_ad_management_widget.dart"
  "packages/artbeat_admin/lib/src/screens/moderation/admin_sponsorship_moderation_screen.dart"
  "packages/artbeat_admin/lib/src/screens/admin_data_requests_screen.dart"
  "packages/artbeat_admin/lib/src/screens/admin_payment_screen.dart"
  "packages/artbeat_admin/lib/src/screens/admin_platform_curation_screen.dart"
  "packages/artbeat_admin/lib/src/screens/admin_login_screen.dart"
  "packages/artbeat_admin/lib/src/screens/admin_settings_screen.dart"
  "packages/artbeat_admin/lib/src/screens/admin_system_health_screen.dart"
  "packages/artbeat_admin/lib/src/screens/admin_security_center_screen.dart"
  "packages/artbeat_admin/lib/src/screens/admin_audit_logs_screen.dart"
  "packages/artbeat_admin/lib/src/screens/admin_user_detail_screen.dart"
  "packages/artbeat_admin/lib/src/screens/modern_unified_admin_dashboard.dart"
  "packages/artbeat_admin/lib/src/screens/moderation/admin_artwork_moderation_screen.dart"
  "packages/artbeat_admin/lib/src/screens/moderation/admin_content_moderation_screen.dart"
  "packages/artbeat_admin/lib/src/screens/moderation/admin_community_moderation_screen.dart"
  "packages/artbeat_admin/lib/src/screens/moderation/admin_art_walk_moderation_screen.dart"
  "packages/artbeat_admin/lib/src/screens/moderation/event_moderation_dashboard_screen.dart"
  "packages/artbeat_admin/lib/src/screens/moderation/admin_flagging_queue_screen.dart"
  "packages/artbeat_admin/lib/src/widgets/admin_drawer.dart"
  "packages/artbeat_admin/lib/src/widgets/coupon_dialogs.dart"
)

violations=()
pattern='FirebaseAuth\.instance|FirebaseFirestore\.instance|FirebaseFunctions\.instance|RecentActivityService\(|EnhancedAnalyticsService\(|ConsolidatedAdminService\(|ContentReviewService\(|AdminArtworkService\(|AdminCaptureModerationService\(|AdminCommunityModerationService\(|AdminArtWalkModerationService\(|AdminEventModerationService\(|AdminSettingsService\(|FlaggingQueueService\(|CouponService\(|AuditTrailService\(|AdminRoleService\(|SecurityService\(|AuthService\('

for file in "${files[@]}"; do
  if grep -nE "$pattern" "$repo_root/$file" >/dev/null; then
    violations+=("$file")
  fi
done

if [ "${#violations[@]}" -gt 0 ]; then
  echo "Admin UI boundary check failed."
  echo "These admin review/ops surfaces must use app-owned services instead of direct Firebase singletons or local service construction:"
  printf ' - %s\n' "${violations[@]}"
  exit 1
fi

echo "Admin UI boundary check passed."

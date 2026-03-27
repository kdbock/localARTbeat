# Probable Untranslated Screen Text

*Generated: 2026-03-26T19:55:30*

## Summary

- Dart files scanned: 1176
- Files with probable hardcoded UI text: 282
- Findings: 1364
- Unique text values: 1212

This report flags probable user-visible text literals in widgets and input decoration properties.
It does not prove a string is wrong; it is a review queue for localization cleanup.

## Top Packages

- artbeat_core: 262
- artbeat_community: 181
- main_app: 173
- artbeat_admin: 165
- artbeat_artist: 128
- artbeat_messaging: 110
- artbeat_artwork: 88
- artbeat_profile: 84
- artbeat_events: 64
- artbeat_art_walk: 58

## Top Files

- packages/artbeat_admin/lib/src/screens/admin_payment_screen.dart: 33
- packages/artbeat_community/lib/screens/art_community_hub.dart: 26
- packages/artbeat_community/lib/screens/feed/enhanced_community_feed_screen.dart: 25
- packages/artbeat_artwork/lib/src/screens/written_content_detail_screen.dart: 24
- packages/artbeat_admin/lib/src/screens/admin_data_requests_screen.dart: 22
- packages/artbeat_messaging/lib/src/screens/artistic_messaging_screen.dart: 22
- lib/widgets/developer_menu.dart: 21
- packages/artbeat_admin/lib/src/screens/admin_platform_curation_screen.dart: 20
- packages/artbeat_events/lib/src/forms/event_form_builder.dart: 20
- packages/artbeat_artist/integration_examples.dart: 19
- packages/artbeat_artwork/lib/src/screens/auction_setup_wizard_screen.dart: 18
- lib/screens/in_app_purchase_demo_screen.dart: 17
- lib/test_artist_features_app.dart: 17
- packages/artbeat_admin/lib/src/screens/admin_security_center_screen.dart: 17
- packages/artbeat_community/lib/screens/unified_community_hub.dart: 17
- packages/artbeat_community/lib/screens/studios/create_studio_screen.dart: 16
- packages/artbeat_community/lib/widgets/art_gallery_widgets.dart: 16
- lib/src/routing/handlers/profile_route_handler.dart: 15
- lib/src/screens/rewards_screen.dart: 15
- packages/artbeat_admin/lib/src/screens/moderation/event_moderation_dashboard_screen.dart: 15

## Top Repeated Literals

- `Error: ${snapshot.error}`: 10
- `Error: $e`: 9
- `STEP ${_currentStepIndex + 1} OF ${_steps.length}`: 6
- `#$tag`: 6
- `Effective Date: ${LegalConfig.effectiveDate}`: 4
- `Last Updated: ${LegalConfig.lastUpdatedDate}`: 4
- `Location`: 4
- `${item[`: 4
- `Error`: 3
- `Refund Policy`: 3
- `Error loading artists: $e`: 3
- `All`: 3
- `Delete Studio`: 3
- `See All`: 3
- `Type a message...`: 3
- `@${user.username}`: 3
- `Status`: 2
- `Debug Tools`: 2
- `Retry`: 2
- `Artist not found`: 2
- `Favorites not available`: 2
- `Try Again`: 2
- `Please log in to view your captures`: 2
- `Error loading captures`: 2
- `Coming Soon`: 2

## Batch Candidates

- `Error: ${snapshot.error}`: 10
- `Error: $e`: 9
- `STEP ${_currentStepIndex + 1} OF ${_steps.length}`: 6
- `#$tag`: 6
- `Effective Date: ${LegalConfig.effectiveDate}`: 4
- `Last Updated: ${LegalConfig.lastUpdatedDate}`: 4
- `Location`: 4
- `${item[`: 4
- `Error`: 3
- `Refund Policy`: 3
- `Error loading artists: $e`: 3
- `All`: 3
- `Delete Studio`: 3
- `See All`: 3
- `Type a message...`: 3
- `@${user.username}`: 3

## artbeat_admin (165)

### packages/artbeat_admin/lib/src/screens/admin_audit_logs_screen.dart (6)

- Line 58: `Error: ${snapshot.error}` [Text widget]
- Line 69: `No audit logs found` [Text widget]
- Line 92: `Category:` [Text widget]
- Line 132: `Admin: ${log.userId}` [Text widget]
- Line 133: `Time: ${_formatDate(log.timestamp)}` [Text widget]
- Line 136: `Metadata: ${log.metadata.toString()}` [Text widget]

### packages/artbeat_admin/lib/src/screens/admin_data_requests_screen.dart (22)

- Line 206: `Review notes` [Input decoration string]
- Line 207: `Optional notes for audit trail` [Input decoration string]
- Line 213: `Set Pending` [Text widget]
- Line 226: `Set In Review` [Text widget]
- Line 257: `Set Denied` [Text widget]
- Line 300: `Request set to $status.` [Text widget]
- Line 322: `Failed to update request: $e` [Text widget]
- Line 345: `Run Deletion Pipeline` [Text widget]
- Line 350: `This will run the account deletion pipeline for user `$userId`.` [Text widget]
- Line 352: `Current request status: $status` [Text widget]
- Line 355: `Last processing error: $errorMessage` [Text widget]
- Line 358: `Only continue if staging/manual validation for this case is complete and you intend to fulfill the legal deletion request now.` [Text widget]
- Line 370: `Run deletion` [Text widget]
- Line 407: `Data Rights Requests` [Text widget]
- Line 413: `All statuses` [Text widget]
- Line 414: `Pending` [Text widget]
- Line 415: `In Review` [Text widget]
- Line 416: `Fulfilled` [Text widget]
- Line 417: `Failed` [Text widget]
- Line 418: `Denied` [Text widget]
- Line 436: `No matching data-rights requests.` [Text widget]
- Line 452: `${requestType.toUpperCase()} • $status${isOverdue ?` [Text widget]

### packages/artbeat_admin/lib/src/screens/admin_login_screen.dart (2)

- Line 100: `Email` [Input decoration string]
- Line 119: `Password` [Input decoration string]

### packages/artbeat_admin/lib/src/screens/admin_payment_screen.dart (33)

- Line 316: `${selectedTransactions.length} transactions selected` [Text widget]
- Line 317: `Total amount: \$${selectedTransactions.fold(0.0, (sum, t) => sum + t.amount).toStringAsFixed(2)}` [Text widget]
- Line 320: `Are you sure you want to process refunds for all selected transactions?` [Text widget]
- Line 675: `Transactions` [Tab text]
- Line 676: `Analytics` [Tab text]
- Line 677: `Refunds` [Tab text]
- Line 678: `Payouts` [Tab text]
- Line 679: `Search` [Tab text]
- Line 766: `Search transactions...` [Input decoration string]
- Line 804: `${_selectedTransactionIds.length} selected` [Text widget]
- Line 890: `${transaction.userName} • ${transaction.displayType}` [Text widget]
- Line 904: `Date: ${intl.DateFormat(` [Text widget]
- Line 926: `Process Refund` [Text widget]
- Line 951: `Revenue Breakdown` [Text widget]
- Line 963: `Payment Methods` [Text widget]
- Line 1036: `\$${totalAmount.toStringAsFixed(2)}` [Text widget]
- Line 1150: `${refundTransactions.length} Refunds` [Text widget]
- Line 1156: `Total: \$${refundTransactions.fold(0.0, (sum, t) => sum + t.amount).toStringAsFixed(2)}` [Text widget]
- Line 1181: `Advanced Search & Filters` [Text widget]
- Line 1210: `Amount Range` [Text widget]
- Line 1232: `Transaction Type` [Input decoration string]
- Line 1470: `Error loading payouts: ${snapshot.error}` [Text widget]
- Line 1478: `No pending payouts` [Text widget]
- Line 1489: `Payout Request - \$${payout[` [Text widget]
- Line 1490: `Artist ID: ${payout[` [Text widget]
- Line 1496: `Process` [Text widget]
- Line 1522: `Payout processed successfully` [Text widget]
- Line 1526: `Failed to process payout` [Text widget]
- Line 1532: `Error processing payout: $e` [Text widget]
- Line 1542: `Reject Payout` [Text widget]
- Line 1546: `Reason for rejection` [Input decoration string]
- Line 1568: `Payout rejected` [Text widget]
- Line 1573: `Error rejecting payout: $e` [Text widget]

### packages/artbeat_admin/lib/src/screens/admin_platform_curation_screen.dart (20)

- Line 69: `Platform Curation` [Text widget]
- Line 83: `Featured Content` [Tab text]
- Line 84: `Announcements` [Tab text]
- Line 113: `No featured artists` [Text widget]
- Line 145: `No featured artworks` [Text widget]
- Line 219: `Enter announcement message...` [Input decoration string]
- Line 229: `Broadcast to All Users` [Text widget]
- Line 252: `No recent broadcasts` [Text widget]
- Line 260: `Sent on: ${_formatTimestamp(data[` [Text widget]
- Line 298: `${artist.fullName} removed from featured artists` [SnackBar or dialog text]
- Line 299: `${artist.fullName} removed from featured artists` [Text widget]
- Line 305: `Error: $e` [Text widget]
- Line 319: `"${art.title}" removed from featured artworks` [Text widget]
- Line 325: `Error: $e` [Text widget]
- Line 334: `Please enter a message` [Text widget]
- Line 341: `Confirm Broadcast` [Text widget]
- Line 342: `This will send a notification to ALL active users. Are you sure?` [Text widget]
- Line 350: `Send` [Text widget]
- Line 363: `Announcement broadcasted successfully` [Text widget]
- Line 368: `Error: $e` [Text widget]

### packages/artbeat_admin/lib/src/screens/admin_security_center_screen.dart (17)

- Line 199: `Severity: ${event.severity}` [Text widget]
- Line 203: `Timestamp: ${intl.DateFormat(` [Text widget]
- Line 305: `Admin Access Control` [Text widget]
- Line 315: `Admin user management is handled in the User Management section.` [Text widget]
- Line 324: `Blocked IP Addresses` [Text widget]
- Line 379: `Search logs...` [Input decoration string]
- Line 435: `Error: ${snapshot.error}` [Text widget]
- Line 462: `No audit logs found matching criteria.` [Text widget]
- Line 593: `IP $ipAddress unblocked successfully` [Text widget]
- Line 599: `Error: $e` [Text widget]
- Line 619: `IP Address` [Input decoration string]
- Line 626: `Reason` [Input decoration string]
- Line 627: `Suspicious activity` [Input decoration string]
- Line 656: `IP $ip blocked successfully` [Text widget]
- Line 662: `Error: $e` [Text widget]
- Line 685: `User: ${log.userId} | IP: ${log.ipAddress}` [Text widget]
- Line 736: `Metadata:` [Text widget]

### packages/artbeat_admin/lib/src/screens/admin_settings_screen.dart (4)

- Line 123: `Save` [Text widget]
- Line 164: `Error loading settings` [Text widget]
- Line 560: `Are you sure you want to create a backup of the database?` [Text widget]
- Line 619: `Are you sure you want to reset all settings to default values?` [Text widget]

### packages/artbeat_admin/lib/src/screens/admin_system_health_screen.dart (2)

- Line 681: `${server[` [Text widget]
- Line 691: `${server[` [Text widget]

### packages/artbeat_admin/lib/src/screens/events_coming_soon_screen.dart (2)

- Line 10: `Events` [Text widget]
- Line 14: `Events Coming Soon` [Text widget]

### packages/artbeat_admin/lib/src/screens/moderation/admin_art_walk_moderation_screen.dart (3)

- Line 70: `Are you sure you want to permanently delete "${walk.title}"? This action cannot be undone.` [Text widget]
- Line 127: `Clear ${walk.reportCount} report(s) from "${walk.title}"?` [Text widget]
- Line 378: `No art walks found` [Text widget]

### packages/artbeat_admin/lib/src/screens/moderation/admin_community_moderation_screen.dart (6)

- Line 365: `Posts (${_flaggedPosts.length})` [Tab text]
- Line 366: `Comments (${_flaggedComments.length})` [Tab text]
- Line 388: `No flagged posts` [Text widget]
- Line 403: `By: ${post.authorName}` [Text widget]
- Line 425: `No flagged comments` [Text widget]
- Line 440: `By: ${comment.userName}` [Text widget]

### packages/artbeat_admin/lib/src/screens/moderation/admin_content_moderation_screen.dart (3)

- Line 108: `Moderation Notes (optional)` [Input decoration string]
- Line 173: `Reason for rejection (optional)` [Input decoration string]
- Line 279: `No captures found` [Text widget]

### packages/artbeat_admin/lib/src/screens/moderation/admin_flagging_queue_screen.dart (8)

- Line 38: `Error loading queue: $e` [Text widget]
- Line 53: `Are you sure you want to ${approve ?` [Text widget]
- Line 59: `Moderation Notes (optional)` [Input decoration string]
- Line 96: `Item ${approve ?` [Text widget]
- Line 104: `Error: $e` [Text widget]
- Line 162: `Queue is clear!` [Text widget]
- Line 166: `No content currently requires moderation.` [Text widget]
- Line 205: `By: ${item.authorName}` [Text widget]

### packages/artbeat_admin/lib/src/screens/moderation/admin_sponsorship_moderation_screen.dart (2)

- Line 83: `No sponsorships in this review state.` [Text widget]
- Line 193: `Save` [Text widget]

### packages/artbeat_admin/lib/src/screens/moderation/event_moderation_dashboard_screen.dart (15)

- Line 127: `No flagged events` [Button or label text]
- Line 128: `No flagged events` [Text widget]
- Line 158: `Reason: ${flag[` [Text widget]
- Line 166: `Dismiss Flag` [Text widget]
- Line 173: `Delete Event` [Text widget]
- Line 185: `No pending events` [Button or label text]
- Line 186: `No pending events` [Text widget]
- Line 241: `No approved events` [Text widget]
- Line 266: `No analytics data` [Button or label text]
- Line 267: `No analytics data` [Text widget]
- Line 312: `Error reviewing event: $e` [Text widget]
- Line 324: `Error dismissing flag: $e` [Text widget]
- Line 333: `Delete Event` [Text widget]
- Line 334: `Are you sure you want to delete this event?` [Text widget]
- Line 353: `Error deleting event: $e` [Text widget]

### packages/artbeat_admin/lib/src/widgets/admin_header.dart (1)

- Line 219: `Admin Menu` [Text widget]

### packages/artbeat_admin/lib/src/widgets/admin_search_modal.dart (6)

- Line 176: `Users (${_filteredUsers.length})` [Tab text]
- Line 177: `Content (${_filteredContent.length})` [Tab text]
- Line 178: `Transactions (${_filteredTransactions.length})` [Tab text]
- Line 243: `Status: ${user.isSuspended ?` [Text widget]
- Line 314: `Type: ${content.type} • Status: ${content.status}` [Text widget]
- Line 386: `User: ${transaction.userName}` [Text widget]

### packages/artbeat_admin/lib/src/widgets/coupon_dialogs.dart (11)

- Line 50: `Title` [Input decoration string]
- Line 51: `e.g., Spring Sale 20% Off` [Input decoration string]
- Line 65: `Brief description of the coupon` [Input decoration string]
- Line 79: `Coupon Code` [Input decoration string]
- Line 80: `e.g., SPRING20` [Input decoration string]
- Line 97: `Coupon Type` [Input decoration string]
- Line 151: `Maximum Uses (optional)` [Input decoration string]
- Line 152: `Leave empty for unlimited uses` [Input decoration string]
- Line 364: `Title` [Input decoration string]
- Line 391: `Maximum Uses (optional)` [Input decoration string]
- Line 392: `Leave empty for unlimited uses` [Input decoration string]

### packages/artbeat_admin/lib/src/widgets/sponsorships/sponsorship_admin_card.dart (2)

- Line 51: `${_titleCase(sponsorship.tier)} sponsor` [Text widget]
- Line 103: `Needs creative` [Text widget]

## artbeat_ads (7)

### packages/artbeat_ads/lib/src/screens/ad_migration_screen.dart (1)

- Line 328: `• $error` [Text widget]

### packages/artbeat_ads/lib/src/screens/local_ads_list_screen.dart (1)

- Line 75: `Search ads...` [Input decoration string]

### packages/artbeat_ads/lib/src/screens/my_ads_screen.dart (2)

- Line 154: `Pending review (${pendingAds.length})` [Text widget]
- Line 159: `These ads have been submitted and paid, but they are not visible in the live app until they are approved.` [Text widget]

### packages/artbeat_ads/lib/src/widgets/ad_card.dart (1)

- Line 59: `${ad.daysRemaining}d` [Text widget]

### packages/artbeat_ads/lib/src/widgets/ad_report_dialog.dart (2)

- Line 192: `Additional details (optional)` [Input decoration string]
- Line 194: `Provide more context about why you\'re reporting this ad...` [Input decoration string]

## artbeat_art_walk (58)

### packages/artbeat_art_walk/lib/src/routes/art_walk_route_config.dart (1)

- Line 79: `Art walk celebration data missing` [Text widget]

### packages/artbeat_art_walk/lib/src/screens/art_walk_celebration_screen.dart (1)

- Line 179: `"${widget.celebrationData.walk.title}"` [Text widget]

### packages/artbeat_art_walk/lib/src/screens/art_walk_list_screen.dart (12)

- Line 446: `Location` [Text widget]
- Line 457: `Enter zip code or city` [Input decoration string]
- Line 469: `Number of Art Pieces` [Text widget]
- Line 490: `Duration (minutes)` [Text widget]
- Line 511: `Distance (miles)` [Text widget]
- Line 532: `Difficulty` [Text widget]
- Line 571: `Accessible Only` [Text widget]
- Line 589: `Sort By` [Text widget]
- Line 688: `Search by title, description, tags...` [Input decoration string]
- Line 693: `Search in: Title, Description, Tags, Difficulty, Location` [Text widget]
- Line 1101: `${walk.estimatedDuration!.round()}m` [Text widget]
- Line 1136: `${walk.estimatedDistance!.toStringAsFixed(1)}mi` [Text widget]

### packages/artbeat_art_walk/lib/src/screens/art_walk_map_screen.dart (2)

- Line 1329: `${_currentIndex + 1}/${widget.captures.length}` [Text widget]
- Line 1342: `by ${capture.artistName}` [Text widget]

### packages/artbeat_art_walk/lib/src/screens/discover_dashboard_screen.dart (1)

- Line 408: `$greeting, $userName!` [Text widget]

### packages/artbeat_art_walk/lib/src/screens/enhanced_art_walk_create_screen.dart (4)

- Line 583: `Error ${widget.artWalkId != null ?` [Text widget]
- Line 769: `${_selectedArtPieces.length} art piece${_selectedArtPieces.length == 1 ?` [Text widget]
- Line 819: `+${_selectedArtPieces.length - 3}` [Text widget]
- Line 1192: `~${_calculateDistance(art)}` [Text widget]

### packages/artbeat_art_walk/lib/src/screens/enhanced_art_walk_experience_screen.dart (8)

- Line 1732: `Your progress will be saved and you can resume this walk later.` [Text widget]
- Line 1824: `Walk resumed. Let\'s continue!` [Text widget]
- Line 1850: `You need to visit at least 80% of art pieces to complete early.` [Text widget]
- Line 1869: `You\'ve visited ${_currentProgress!.visitedArt.length}/${_currentProgress!.totalArtCount} art pieces.` [Text widget]
- Line 1873: `Completing early means:` [Text widget]
- Line 1877: `• You won\'t get the perfect completion bonus` [Text widget]
- Line 1932: `$percentage% Complete` [Text widget]
- Line 2000: `Are you sure you want to abandon this walk? All progress will be lost and cannot be recovered.` [Text widget]

### packages/artbeat_art_walk/lib/src/screens/enhanced_my_art_walks_screen.dart (4)

- Line 48: `Art Walk to Riverfront` [Text widget]
- Line 53: `3/8 art pieces visited` [Text widget]
- Line 83: `Downtown Public Art Tour` [Text widget]
- Line 88: `Completed! 🎉` [Text widget]

### packages/artbeat_art_walk/lib/src/screens/instant_discovery_screen.dart (2)

- Line 16: `Instant Discovery Radar` [Text widget]
- Line 17: `Radar screen goes here` [Text widget]

### packages/artbeat_art_walk/lib/src/screens/weekly_goals_screen.dart (2)

- Line 198: `${_stats[` [Text widget]
- Line 208: `${_stats[` [Text widget]

### packages/artbeat_art_walk/lib/src/widgets/art_progress_card.dart (1)

- Line 23: `$visited / $total` [Text widget]

### packages/artbeat_art_walk/lib/src/widgets/daily_quest_card.dart (1)

- Line 189: `${challenge.currentCount}/${challenge.targetCount} ${_getProgressUnit(challenge.title)}` [Text widget]

### packages/artbeat_art_walk/lib/src/widgets/discovery_capture_modal.dart (1)

- Line 264: `by ${widget.art.artistName}` [Text widget]

### packages/artbeat_art_walk/lib/src/widgets/enhanced_progress_visualization.dart (2)

- Line 116: `${widget.visitedCount}/${widget.totalCount}` [Text widget]
- Line 368: `$visitedCount/$totalCount` [Text widget]

### packages/artbeat_art_walk/lib/src/widgets/instant_discovery_radar.dart (13)

- Line 248: `Instant Discovery` [Text widget]
- Line 255: `${widget.nearbyArt.length} artworks nearby` [Text widget]
- Line 266: `Next scan: ${timeRemaining.toStringAsFixed(1)}s` [Text widget]
- Line 293: `${widget.radiusMeters.toInt()}m` [Text widget]
- Line 411: `Today: $_todayDiscoveries` [Text widget]
- Line 431: `Streak: $_streakCount` [Text widget]
- Line 442: `${widget.nearbyArt.length} nearby` [Text widget]
- Line 855: `No art nearby` [Text widget]
- Line 862: `Try moving to a different location` [Text widget]
- Line 972: `by ${art.artistName}` [Text widget]
- Line 1006: `CLOSE!` [Text widget]
- Line 1020: `Wheelchair accessible` [Text widget]
- Line 1034: `${distance.toInt()}m` [Text widget]

### packages/artbeat_art_walk/lib/src/widgets/tour/discover_tour_overlay.dart (1)

- Line 463: `STEP ${_currentStepIndex + 1} OF ${_steps.length}` [Text widget]

### packages/artbeat_art_walk/lib/src/widgets/weekly_goals_card.dart (2)

- Line 208: `${goal.currentCount} / ${goal.targetCount}` [Text widget]
- Line 308: `+${goal.rewardXP} XP` [Text widget]

## artbeat_artist (128)

### packages/artbeat_artist/integration_examples.dart (19)

- Line 122: `Error: ${snapshot.error}` [Text widget]
- Line 127: `Unable to load capabilities` [Text widget]
- Line 151: `Upload Limit` [Text widget]
- Line 211: `Enable` [Text widget]
- Line 242: `You have all available features!` [Text widget]
- Line 298: `Integration Example` [Text widget]
- Line 320: `No user data available` [Text widget]
- Line 331: `User Information` [Text widget]
- Line 336: `Name: ${unifiedData!.userModel.fullName}` [Text widget]
- Line 337: `Email: ${unifiedData!.userModel.email}` [Text widget]
- Line 338: `Is Artist: ${unifiedData!.artistProfile != null}` [Text widget]
- Line 340: `Artist Display Name: ${unifiedData!.artistProfile!.displayName}` [Text widget]
- Line 354: `No capabilities data available` [Text widget]
- Line 365: `Capabilities` [Text widget]
- Line 390: `Max Uploads: ${capabilities!.maxArtworkUploads == -1 ? "Unlimited" : capabilities!.maxArtworkUploads}` [Text widget]
- Line 420: `Actions` [Text widget]
- Line 424: `Enable Artist Features` [Text widget]
- Line 429: `Get Recommendations` [Text widget]
- Line 434: `Refresh Data` [Text widget]

### packages/artbeat_artist/lib/src/screens/artist_list_screen.dart (1)

- Line 104: `No artists found` [Text widget]

### packages/artbeat_artist/lib/src/screens/artist_onboard_screen.dart (9)

- Line 288: `FOR ARTISTS` [Text widget]
- Line 299: `Your Studio.\nWithout the Noise.` [Text widget]
- Line 316: `Stop chasing algorithms. Start building your legacy.` [Text widget]
- Line 326: `In the next 2 minutes, we\'ll help you unlock a professional gallery experience tailored to your craft.` [Text widget]
- Line 337: `HIT NEXT TO UNLOCK:` [Text widget]
- Line 718: `Optimized for your visibility goals.` [Text widget]
- Line 763: `AI RECOMMENDED` [Text widget]
- Line 837: `Included with ${(_selectedPlanName ?? "this plan")}:` [Text widget]
- Line 1149: `Error: $e` [Text widget]

### packages/artbeat_artist/lib/src/screens/artist_profile_edit_screen.dart (10)

- Line 347: `Profile Images` [Text widget]
- Line 453: `Basic Information` [Text widget]
- Line 464: `Display Name` [Input decoration string]
- Line 479: `Bio` [Input decoration string]
- Line 494: `Location` [Input decoration string]
- Line 598: `Website` [Input decoration string]
- Line 607: `Instagram` [Input decoration string]
- Line 616: `Facebook` [Input decoration string]
- Line 625: `Twitter` [Input decoration string]
- Line 634: `Etsy Shop` [Input decoration string]

### packages/artbeat_artist/lib/src/screens/artist_public_profile_screen.dart (3)

- Line 602: `${_writtenWorks.length} ${_writtenWorks.length == 1 ?` [Text widget]
- Line 1295: `\$${artwork.price?.toStringAsFixed(2) ??` [Text widget]
- Line 1511: `${work.writingMetadata!.wordCount} words` [Text widget]

### packages/artbeat_artist/lib/src/screens/auction_hub_screen.dart (5)

- Line 136: `Auction Hub` [Text widget]
- Line 183: `New Auction` [Text widget]
- Line 365: `Reserve: \$${auction.reservePrice!.toStringAsFixed(2)}` [Text widget]
- Line 392: `View Details` [Text widget]
- Line 399: `Edit` [Text widget]

### packages/artbeat_artist/lib/src/screens/earnings/artist_earnings_hub.dart (10)

- Line 177: `🔍 Firestore Index Required` [Text widget]
- Line 247: `Career Earnings` [Text widget]
- Line 258: `\$${_earnings!.totalEarnings.toStringAsFixed(2)}` [Text widget]
- Line 409: `\$${(item[` [Text widget]
- Line 569: `${transaction.fromUserName} • ${_formatDate(transaction.timestamp)}` [Text widget]
- Line 572: `+\$${transaction.amount.toStringAsFixed(2)}` [Text widget]
- Line 630: `Requested: ${_formatDate(payout.requestedAt)}` [Text widget]
- Line 632: `Processed: ${_formatDate(payout.processedAt!)}` [Text widget]
- Line 634: `Reason: ${payout.failureReason}` [Text widget]
- Line 644: `\$${payout.amount.toStringAsFixed(2)}` [Text widget]

### packages/artbeat_artist/lib/src/screens/earnings/artwork_sales_hub.dart (4)

- Line 208: `\$${totalSalesRevenue.toStringAsFixed(2)}` [Text widget]
- Line 486: `${entry.value} purchase${entry.value > 1 ?` [Text widget]
- Line 635: `by ${transaction.fromUserName}` [Text widget]
- Line 648: `\$${transaction.amount.toStringAsFixed(2)}` [Text widget]

### packages/artbeat_artist/lib/src/screens/earnings/payout_accounts_screen.dart (7)

- Line 384: `Are you sure you want to delete the account "${account.displayName}"?` [Text widget]
- Line 420: `Failed to delete account: $e` [Text widget]
- Line 493: `Account Type` [Input decoration string]
- Line 516: `Account Holder Name` [Input decoration string]
- Line 531: `Bank Name` [Input decoration string]
- Line 539: `Account Number` [Input decoration string]
- Line 553: `Routing Number` [Input decoration string]

### packages/artbeat_artist/lib/src/screens/earnings/payout_request_screen.dart (6)

- Line 144: `\$${widget.availableBalance.toStringAsFixed(2)}` [Text widget]
- Line 186: `Amount (\$)` [Input decoration string]
- Line 189: `Enter the amount you want to withdraw` [Input decoration string]
- Line 340: `Select Account` [Input decoration string]
- Line 353: `${account.bankName ??` [Text widget]
- Line 523: `Payout request submitted successfully! You will receive \$${amount.toStringAsFixed(2)} in 1-3 business days.` [Text widget]

### packages/artbeat_artist/lib/src/screens/event_creation_screen.dart (4)

- Line 323: `Event Creation` [Text widget]
- Line 440: `Event Title` [Input decoration string]
- Line 607: `Location` [Input decoration string]
- Line 643: `Allow others to see and register for this event` [Text widget]

### packages/artbeat_artist/lib/src/screens/gallery_artists_management_screen.dart (5)

- Line 389: `Current Artists` [Tab text]
- Line 390: `Pending Invitations` [Tab text]
- Line 504: `Invited ${_formatDate(invitation.createdAt)}` [Text widget]
- Line 553: `Are you sure you want to cancel the invitation to ${invitation.artistName}?` [Text widget]
- Line 723: `Search by name or location` [Input decoration string]

### packages/artbeat_artist/lib/src/screens/gallery_hub_screen.dart (8)

- Line 488: `Details` [Text widget]
- Line 672: `Momentum Meter` [Text widget]
- Line 704: `Weekly: ${effectiveWeekly.toStringAsFixed(0)} / $_weeklyMomentumCap` [Text widget]
- Line 728: `Active Power-Ups` [Text widget]
- Line 762: `Impact Preview` [Text widget]
- Line 891: `${boost.daysRemaining}d left` [Text widget]
- Line 908: `My Gallery Hub` [Text widget]
- Line 1561: `Your Studio Launch Wins` [Text widget]

### packages/artbeat_artist/lib/src/screens/gallery_visibility_hub_screen.dart (7)

- Line 373: `\$${(artist[` [Text widget]
- Line 378: `\$${(artist[` [Text widget]
- Line 419: `Gallery Visibility Hub` [Text widget]
- Line 544: `Showing data for: ${_selectedTimeRange ==` [Text widget]
- Line 673: `\$${totalPendingCommission.toStringAsFixed(2)}` [Text widget]
- Line 687: `\$${totalPaidCommission.toStringAsFixed(2)}` [Text widget]
- Line 701: `\$${(totalPendingCommission + totalPaidCommission).toStringAsFixed(2)}` [Text widget]

### packages/artbeat_artist/lib/src/screens/payment_methods_screen.dart (4)

- Line 249: `No payment methods added` [Text widget]
- Line 296: `Your Payment Methods` [Text widget]
- Line 339: `•••• •••• •••• ${card?.last4 ??` [Text widget]
- Line 391: `Remove` [Text widget]

### packages/artbeat_artist/lib/src/screens/payment_screen.dart (3)

- Line 87: `Subscribe Now - ${_getPriceString(widget.tier)}` [Text widget]
- Line 139: `Plan Features` [Text widget]
- Line 233: `You\'ve successfully subscribed to the ${_getTierName(widget.tier)}!` [Text widget]

### packages/artbeat_artist/lib/src/screens/refund_request_screen.dart (5)

- Line 78: `Your refund request has been submitted and will be reviewed.` [Text widget]
- Line 147: `\$${widget.amount.toStringAsFixed(2)}` [Text widget]
- Line 160: `${widget.paymentId.substring(0, 10)}...` [Text widget]
- Line 229: `Please provide any additional information about your refund request` [Input decoration string]
- Line 282: `Refund Policy` [Text widget]

### packages/artbeat_artist/lib/src/screens/subscription_analytics_screen.dart (3)

- Line 453: `Auto-renew: ${_subscription!.autoRenew ?` [Text widget]
- Line 488: `Performance Summary` [Text widget]
- Line 847: `\$${(amount / 100).toStringAsFixed(2)} ${currency.toUpperCase()}` [Text widget]

### packages/artbeat_artist/lib/src/screens/verified_artist_screen.dart (3)

- Line 160: `Verified Artists` [Text widget]
- Line 198: `Search verified artists...` [Input decoration string]
- Line 525: `Medium` [Text widget]

### packages/artbeat_artist/lib/src/screens/visibility_insights_screen.dart (4)

- Line 230: `Overview Interest` [Text widget]
- Line 316: `Gallery Visitors` [Text widget]
- Line 378: `Top Locations` [Text widget]
- Line 548: `Top Referral Sources` [Text widget]

### packages/artbeat_artist/lib/src/widgets/commission_badge_widget.dart (2)

- Line 98: `\$${basePrice?.toStringAsFixed(2) ??` [Text widget]
- Line 118: `$turnaroundDays days` [Text widget]

### packages/artbeat_artist/lib/src/widgets/local_artists_row_widget.dart (1)

- Line 205: `No local artists found in $zipCode` [Text widget]

### packages/artbeat_artist/lib/src/widgets/local_galleries_widget.dart (1)

- Line 77: `Error loading galleries: ${snapshot.error}` [Text widget]

### packages/artbeat_artist/lib/src/widgets/top_followers_widget.dart (2)

- Line 183: `#${index + 1}` [Text widget]
- Line 210: `${follower.engagementScore} pts` [Text widget]

### packages/artbeat_artist/lib/src/widgets/upcoming_events_row_widget.dart (2)

- Line 63: `Error: ${snapshot.error}` [Text widget]
- Line 193: `$formattedDate at $formattedTime` [Text widget]

## artbeat_artwork (88)

### packages/artbeat_artwork/lib/src/screens/advanced_artwork_search_screen.dart (3)

- Line 448: `Min` [Input decoration string]
- Line 460: `Max` [Input decoration string]
- Line 613: `\$${artwork.price!.toStringAsFixed(2)}` [Text widget]

### packages/artbeat_artwork/lib/src/screens/artist_artwork_management_screen.dart (7)

- Line 113: `Deleted "${artwork.title}" successfully` [Text widget]
- Line 123: `Error deleting artwork: ${e.toString()}` [Text widget]
- Line 179: `Error Loading Artwork` [Text widget]
- Line 213: `No Artwork Yet` [Text widget]
- Line 218: `Upload your first artwork to get started!` [Text widget]
- Line 223: `Upload Artwork` [Text widget]
- Line 248: `Upload` [Text widget]

### packages/artbeat_artwork/lib/src/screens/artwork_detail_screen.dart (14)

- Line 180: `"$title" by $artistName` [Text widget]
- Line 483: `\$${artwork.price?.toStringAsFixed(2) ??` [Text widget]
- Line 576: `Details` [Text widget]
- Line 602: `📖 Written Work Details` [Text widget]
- Line 622: `Description` [Text widget]
- Line 700: `${artwork.viewCount} views` [Text widget]
- Line 866: `\$${bid.amount.toStringAsFixed(2)}` [Text widget]
- Line 979: `\$${currentBid.toStringAsFixed(2)}` [Text widget]
- Line 1100: `Genre` [Text widget]
- Line 1143: `Word Count` [Text widget]
- Line 1152: `${metadata.wordCount!} words` [Text widget]
- Line 1186: `Estimated Read Time` [Text widget]
- Line 1195: `${metadata.estimatedReadMinutes!} minutes` [Text widget]
- Line 1223: `Excerpt` [Text widget]

### packages/artbeat_artwork/lib/src/screens/auction_setup_wizard_screen.dart (18)

- Line 213: `Step ${_currentStep + 1} of $_totalSteps` [Text widget]
- Line 304: `Welcome to Auctions` [Text widget]
- Line 306: `Set up your auction preferences to start selling your artworks through exciting time-limited bidding.` [Text widget]
- Line 350: `You can enable auctions on individual artworks at any time. These settings are just your defaults.` [Text widget]
- Line 379: `The initial price where bidding starts. Should be set strategically to attract bidders.` [Text widget]
- Line 399: `The minimum amount each new bid must exceed the current highest bid.` [Text widget]
- Line 436: `Shorter durations create urgency, while longer durations give more people time to discover and bid.` [Text widget]
- Line 459: `Duration Guidelines` [Text widget]
- Line 494: `Use Reserve Price by Default` [Text widget]
- Line 498: `If bids don\'t reach this price, you won\'t be obligated to sell` [Text widget]
- Line 522: `Example: If starting price is ${_formatCurrency(_defaultStartingPrice)}, reserve would be ${_formatCurrency(_defaultStartingPrice * _defaultReservePricePercent / 100)}` [Text widget]
- Line 552: `Pro Tip` [Text widget]
- Line 559: `Reserve prices are hidden from bidders. They only see if the reserve has been met.` [Text widget]
- Line 580: `Review Your Settings` [Text widget]
- Line 582: `These are your default auction settings. You can adjust them for individual artworks later.` [Text widget]
- Line 594: `Pricing` [Text widget]
- Line 620: `Duration` [Text widget]
- Line 640: `Ready to save! You can change these settings anytime from your artist dashboard.` [Text widget]

### packages/artbeat_artwork/lib/src/screens/curated_gallery_screen.dart (1)

- Line 511: `${collection.artworkIds.length} artworks` [Text widget]

### packages/artbeat_artwork/lib/src/screens/enhanced_artwork_upload_screen.dart (3)

- Line 1049: `${(_mainImageUploadProgress * 100).toInt()}% ${` [Text widget]
- Line 1450: `\$${_priceController.text}` [Text widget]
- Line 1811: `Add $label` [Input decoration string]

### packages/artbeat_artwork/lib/src/screens/my_bids_screen.dart (1)

- Line 213: `\$${bid.amount.toStringAsFixed(2)}` [Text widget]

### packages/artbeat_artwork/lib/src/screens/video_content_upload_screen.dart (2)

- Line 640: `${_videoDuration.inMinutes}:${(_videoDuration.inSeconds % 60).toString().padLeft(2,` [Text widget]
- Line 645: `${_width}x$_height` [Text widget]

### packages/artbeat_artwork/lib/src/screens/written_content_detail_screen.dart (24)

- Line 579: `About this Story` [Text widget]
- Line 625: `Read More` [Text widget]
- Line 635: `Show Less` [Text widget]
- Line 649: `Chapters` [Text widget]
- Line 655: `${_chapters.length} Total` [Text widget]
- Line 688: `No chapters released yet.` [Text widget]
- Line 766: `${chapter.estimatedReadingTime} min` [Text widget]
- Line 783: `\$${_perChapterPrice.toStringAsFixed(0)}` [Text widget]
- Line 802: `Engagement Unlock` [Text widget]
- Line 823: `Draft` [Text widget]
- Line 924: `Unlock Chapter ${chapter.episodeNumber ?? chapter.chapterNumber}` [Text widget]
- Line 988: `Unlock Full Book for \$${_fullBookPrice.toStringAsFixed(0)}` [Text widget]
- Line 1000: `Maybe Later` [Text widget]
- Line 1034: `Chapter $chapterNumber is locked` [Text widget]
- Line 1061: `Unlock Options` [Text widget]
- Line 1084: `Chapter ${_currentChapter!.episodeNumber ?? _currentChapter!.chapterNumber}` [Text widget]
- Line 1165: `You\'ve caught up!` [Text widget]
- Line 1170: `Stay tuned for more chapters coming soon.` [Text widget]
- Line 1214: `NEXT CHAPTER` [Text widget]
- Line 1224: `Chapter ${nextChapter.episodeNumber ?? nextChapter.chapterNumber}: ${nextChapter.title}` [Text widget]
- Line 1369: `Payment successful!` [Text widget]
- Line 1388: `Purchase failed: $errorMessage` [Text widget]
- Line 1451: `Payment successful!` [Text widget]
- Line 1470: `Purchase failed: $errorMessage` [Text widget]

### packages/artbeat_artwork/lib/src/screens/written_content_discovery_screen.dart (2)

- Line 360: `Ongoing` [Text widget]
- Line 371: `Complete` [Text widget]

### packages/artbeat_artwork/lib/src/screens/written_content_upload_screen.dart (2)

- Line 888: `$e\n\n$stackTrace` [Text widget]
- Line 1320: `${chapter[` [Text widget]

### packages/artbeat_artwork/lib/src/widgets/artwork_grid_widget.dart (1)

- Line 214: `\$${artwork.price!.toStringAsFixed(2)}` [Text widget]

### packages/artbeat_artwork/lib/src/widgets/artwork_header.dart (1)

- Line 203: `Artwork Menu` [Text widget]

### packages/artbeat_artwork/lib/src/widgets/artwork_social_widget.dart (4)

- Line 183: `Ratings` [Text widget]
- Line 207: `${_ratingStats!.averageRating.toStringAsFixed(1)} (${_ratingStats!.totalRatings} ratings)` [Text widget]
- Line 284: `Comments` [Text widget]
- Line 300: `Share your thoughts about this artwork...` [Input decoration string]

### packages/artbeat_artwork/lib/src/widgets/book_card.dart (2)

- Line 103: `Ongoing` [Text widget]
- Line 116: `Complete` [Text widget]

### packages/artbeat_artwork/lib/src/widgets/local_artwork_row_widget.dart (3)

- Line 28: `Local Artwork` [Text widget]
- Line 67: `Error loading artwork` [Text widget]
- Line 96: `No artwork found in your area` [Text widget]

## artbeat_auth (3)

### packages/artbeat_auth/lib/src/screens/email_verification_screen.dart (1)

- Line 668: `Checking verification…` [Text widget]

### packages/artbeat_auth/lib/src/screens/register_screen.dart (2)

- Line 271: `Join Local ARTbeat` [Text widget]
- Line 479: `ARTbeat is recommended for ages 18 and older because some content may include artistic nudity or mature artistic subject matter. Users under 18 may have messaging, location sharing, public discovery, and event features restricted.` [Text widget]

## artbeat_capture (9)

### packages/artbeat_capture/lib/src/screens/capture_settings_screen.dart (1)

- Line 98: `Capture Preferences` [Text widget]

### packages/artbeat_capture/lib/src/screens/enhanced_capture_dashboard_screen.dart (2)

- Line 1311: `+${mission.xpReward} XP` [Text widget]
- Line 1365: `${mission.current}/${mission.target}` [Text widget]

### packages/artbeat_capture/lib/src/widgets/artist_search_dialog.dart (1)

- Line 121: `Search artists...` [Input decoration string]

### packages/artbeat_capture/lib/src/widgets/capture_header.dart (1)

- Line 204: `Capture Menu` [Text widget]

### packages/artbeat_capture/lib/src/widgets/comments_section_widget.dart (1)

- Line 186: `Add a comment...` [Input decoration string]

### packages/artbeat_capture/lib/src/widgets/mission_card.dart (2)

- Line 71: `+$xpReward XP` [Text widget]
- Line 120: `$current/$target` [Text widget]

### packages/artbeat_capture/lib/src/widgets/tour/capture_tour_overlay.dart (1)

- Line 431: `STEP ${_currentStepIndex + 1} OF ${_steps.length}` [Text widget]

## artbeat_community (181)

### packages/artbeat_community/example/comment_demo.dart (8)

- Line 44: `Comment System Demo` [Text widget]
- Line 61: `Interactive Comment System` [Text widget]
- Line 70: `Tap the comment icon below to expand the comment section. You can:` [Text widget]
- Line 75: `• View existing comments\n` [Text widget]
- Line 88: `❤️ Liked!` [Text widget]
- Line 96: `Post tapped!` [Text widget]
- Line 109: `✨ Features Implemented:` [Text widget]
- Line 118: `• Expandable comment section with smooth animations\n` [Text widget]

### packages/artbeat_community/lib/screens/art_community_hub.dart (26)

- Line 209: `Error loading posts: $e` [Text widget]
- Line 418: `${commission.status.displayName} • \$${commission.totalPrice.toStringAsFixed(2)}` [Text widget]
- Line 667: `Error: ${snapshot.error}` [Text widget]
- Line 677: `No artwork found` [Text widget]
- Line 696: `No results for "${widget.searchQuery}"` [Text widget]
- Line 805: `\$${currentBid.toStringAsFixed(0)}` [Text widget]
- Line 814: `\$${price.toStringAsFixed(0)}` [Text widget]
- Line 1791: `Post deleted successfully` [Text widget]
- Line 1797: `Failed to delete post` [Text widget]
- Line 1805: `Error deleting post` [Text widget]
- Line 2162: `All Artists` [Text widget]
- Line 2337: `Groups` [Text widget]
- Line 2346: `Join communities and share your art` [Text widget]
- Line 2385: `Create` [Text widget]
- Line 2420: `No groups found` [Text widget]
- Line 2429: `Be the first to create a group!` [Text widget]
- Line 2453: `Create First Group` [Text widget]
- Line 2689: `Please sign in to create a group` [Text widget]
- Line 2716: `Group created successfully!` [Text widget]
- Line 2724: `Failed to create group. Please try again.` [Text widget]
- Line 2750: `Create New Group` [Text widget]
- Line 2780: `Group Name` [Input decoration string]
- Line 2785: `Enter group name` [Input decoration string]
- Line 2807: `Description (optional)` [Input decoration string]
- Line 2812: `Describe your group` [Input decoration string]
- Line 2858: `Create` [Text widget]

### packages/artbeat_community/lib/screens/commissions/artist_selection_screen.dart (6)

- Line 51: `Error loading artists: $e` [Text widget]
- Line 84: `Error searching artists: $e` [Text widget]
- Line 130: `Select Artist` [Text widget]
- Line 138: `Choose an artist for your commission` [Text widget]
- Line 177: `Search artists by name...` [Input decoration string]
- Line 210: `No artists found` [Text widget]

### packages/artbeat_community/lib/screens/commissions/commission_setup_wizard_screen.dart (1)

- Line 1120: `+${_formatCurrency(value)}` [Text widget]

### packages/artbeat_community/lib/screens/create_art_post_screen.dart (1)

- Line 531: `${_selectedImages.length}/5` [Text widget]

### packages/artbeat_community/lib/screens/feed/create_post_screen.dart (1)

- Line 473: `Content moderation failed: ${moderationResult.reason}` [Text widget]

### packages/artbeat_community/lib/screens/feed/enhanced_community_feed_screen.dart (25)

- Line 67: `All` [Tab text]
- Line 68: `Captures` [Tab text]
- Line 69: `Artworks` [Tab text]
- Line 70: `Artists` [Tab text]
- Line 71: `Events` [Tab text]
- Line 72: `Posts` [Tab text]
- Line 370: `Captured 2 hours ago` [Text widget]
- Line 401: `Found this incredible mural while exploring the arts district. The colors and detail are absolutely stunning!` [Text widget]
- Line 458: `Creating unique pieces that blend traditional and digital techniques.` [Text widget]
- Line 531: `March 15-30, 2024 • Downtown Gallery` [Text widget]
- Line 590: `Community Member` [Text widget]
- Line 597: `1 hour ago` [Text widget]
- Line 661: `Art Enthusiast` [Text widget]
- Line 668: `30 minutes ago` [Text widget]
- Line 684: `This is such an inspiring piece! I love how you\'ve used color to convey emotion. The technique reminds me of some of the great impressionist masters.` [Text widget]
- Line 752: `Opening artwork details...` [Text widget]
- Line 761: `Please log in to create a post` [Text widget]
- Line 818: `Fix Anonymous Post Authors` [Text widget]
- Line 819: `Update posts showing "Anonymous" with correct names` [Text widget]
- Line 837: `Fix Anonymous Post Authors` [Text widget]
- Line 838: `This will update all posts that currently show "Anonymous" as the author name` [Text widget]
- Line 854: `Fix Posts` [Text widget]
- Line 873: `Fixing anonymous post authors...` [Text widget]
- Line 889: `Anonymous posts fix completed! Check logs for details.` [Text widget]
- Line 901: `Error fixing posts: $e` [Text widget]

### packages/artbeat_community/lib/screens/feed/social_engagement_demo_screen.dart (4)

- Line 20: `Social Engagement Demo` [Text widget]
- Line 53: `ARTbeat Social Engagement System` [Text widget]
- Line 63: `Explore different engagement options for various content types` [Text widget]
- Line 162: `This demo showcases the engagement options available for each content type in the ARTbeat platform.` [Text widget]

### packages/artbeat_community/lib/screens/portfolios/artist_portfolio_screen.dart (1)

- Line 39: `No artworks available` [Text widget]

### packages/artbeat_community/lib/screens/studios/create_studio_screen.dart (16)

- Line 61: `You must be logged in to create a studio` [Text widget]
- Line 86: `Studio created successfully!` [Text widget]
- Line 96: `Error creating studio: $e` [Text widget]
- Line 128: `Studio Name` [Text widget]
- Line 136: `Enter studio name` [Input decoration string]
- Line 161: `Describe your studio and its purpose` [Input decoration string]
- Line 174: `Privacy Settings` [Text widget]
- Line 191: `Public` [Text widget]
- Line 192: `Anyone can find and join this studio` [Text widget]
- Line 199: `Private` [Text widget]
- Line 200: `Only invited members can join` [Text widget]
- Line 211: `Tags` [Text widget]
- Line 216: `Add tags to help others find your studio` [Text widget]
- Line 227: `Add a tag` [Input decoration string]
- Line 240: `Add` [Text widget]
- Line 276: `Create Studio` [Text widget]

### packages/artbeat_community/lib/screens/studios/studio_discovery_screen.dart (4)

- Line 99: `Search studios...` [Input decoration string]
- Line 154: `Error: ${snapshot.error}` [Text widget]
- Line 260: `${studio.memberList.length} members` [Text widget]
- Line 322: `Join Studio` [Text widget]

### packages/artbeat_community/lib/screens/studios/studio_management_screen.dart (15)

- Line 53: `Error loading studio: $e` [Text widget]
- Line 73: `Member removed successfully` [Text widget]
- Line 79: `Error removing member: $e` [Text widget]
- Line 89: `Delete Studio` [Text widget]
- Line 90: `Are you sure you want to delete this studio? This action cannot be undone.` [Text widget]
- Line 114: `Studio deleted successfully` [Text widget]
- Line 120: `Error deleting studio: $e` [Text widget]
- Line 159: `Studio not found` [Text widget]
- Line 212: `${_studio!.memberList.length} members` [Text widget]
- Line 246: `Members` [Text widget]
- Line 260: `Error: ${snapshot.error}` [Text widget]
- Line 325: `Danger Zone` [Text widget]
- Line 341: `Delete Studio` [Text widget]
- Line 350: `Once you delete this studio, there is no going back. Please be certain.` [Text widget]
- Line 363: `Delete Studio` [Text widget]

### packages/artbeat_community/lib/screens/studios/studios_screen.dart (1)

- Line 453: `#$tag` [Text widget]

### packages/artbeat_community/lib/screens/unified_community_hub.dart (17)

- Line 125: `Please log in to create a post` [Text widget]
- Line 216: `Unable to load user profile` [Text widget]
- Line 382: `Error loading more posts: $e` [Text widget]
- Line 477: `No posts yet` [Text widget]
- Line 486: `Be the first to share your creative work and connect with the community.` [Text widget]
- Line 708: `No artworks yet` [Text widget]
- Line 717: `Artists are working on amazing pieces. Check back soon!` [Text widget]
- Line 815: `by ${artworkModel.artist?.displayName ??` [Text widget]
- Line 1224: `Artists Online` [Text widget]
- Line 1240: `${_onlineArtists.length} online` [Text widget]
- Line 1288: `No artists online right now` [Text widget]
- Line 1322: `Unable to load artist feed` [Text widget]
- Line 1409: `Recent Posts` [Text widget]
- Line 1488: `No recent posts available` [Text widget]
- Line 1840: `No ${title.toLowerCase()} available` [Text widget]
- Line 1875: `Unable to load artist feed` [Text widget]
- Line 1955: `${artist[` [Text widget]

### packages/artbeat_community/lib/src/screens/artist_community_feed_screen.dart (4)

- Line 339: `${item[` [Text widget]
- Line 343: `${item[` [Text widget]
- Line 497: `${item[` [Text widget]
- Line 501: `${item[` [Text widget]

### packages/artbeat_community/lib/src/screens/community_artists_screen.dart (1)

- Line 201: `${artist[` [Text widget]

### packages/artbeat_community/lib/src/widgets/user_action_menu.dart (6)

- Line 259: `Delete Post` [Text widget]
- Line 260: `Are you sure you want to delete this post? This action cannot be undone.` [Text widget]
- Line 296: `You cannot report your own post` [Text widget]
- Line 304: `You cannot block yourself` [Text widget]
- Line 320: `Edit post` [Text widget]
- Line 327: `Delete post` [Text widget]

### packages/artbeat_community/lib/widgets/art_critique_slider.dart (2)

- Line 117: `Loading...` [Text widget]
- Line 238: `@${post.authorUsername}` [Text widget]

### packages/artbeat_community/lib/widgets/art_gallery_widgets.dart (16)

- Line 217: `Artist` [Text widget]
- Line 280: `#$tag` [Text widget]
- Line 1060: `Failed to load comments: ${e.toString()}` [Text widget]
- Line 1098: `Comment posted successfully! 💬` [Text widget]
- Line 1113: `Failed to post comment: ${e.toString()}` [Text widget]
- Line 1239: `Artist` [Text widget]
- Line 1300: `DEBUG: Image URLs (${widget.post.imageUrls.length}):` [Text widget]
- Line 1356: `Loading image...` [Text widget]
- Line 1383: `Failed to load image` [Text widget]
- Line 1428: `#$tag` [Text widget]
- Line 1566: `Post shared successfully!` [Text widget]
- Line 1577: `Failed to share: $e` [Text widget]
- Line 1663: `Write a comment...` [Input decoration string]
- Line 1739: `View all ${_comments.length} comments` [Text widget]
- Line 1751: `No comments yet. Be the first to comment!` [Text widget]
- Line 1857: `All Comments (${_comments.length})` [Text widget]

### packages/artbeat_community/lib/widgets/boost_card_widget.dart (1)

- Line 33: `Momentum +${boost.momentumAmount}` [Text widget]

### packages/artbeat_community/lib/widgets/canvas_feed.dart (3)

- Line 56: `Medium: ${artwork.medium}` [Text widget]
- Line 64: `Location: ${artwork.location}` [Text widget]
- Line 72: `Posted: ${artwork.createdAt}` [Text widget]

### packages/artbeat_community/lib/widgets/comments_modal.dart (3)

- Line 72: `Debug: Loaded ${comments.length} comments for post ${widget.post.id}` [Text widget]
- Line 97: `Failed to load comments: $e` [Text widget]
- Line 143: `Failed to add comment. Please try again.` [Text widget]

### packages/artbeat_community/lib/widgets/commission_artists_browser.dart (1)

- Line 63: `Error loading artists: $e` [Text widget]

### packages/artbeat_community/lib/widgets/enhanced_artwork_card.dart (1)

- Line 207: `\$${artwork.price.toStringAsFixed(0)}` [Text widget]

### packages/artbeat_community/lib/widgets/enhanced_post_card.dart (5)

- Line 252: `Failed to add comment` [Text widget]
- Line 795: `+${images.length - 4}` [Text widget]
- Line 931: `Audio` [Text widget]
- Line 952: `${_formatDuration(_audioPosition)} / ${_formatDuration(_audioDuration)}` [Text widget]
- Line 990: `#$tag` [Text widget]

### packages/artbeat_community/lib/widgets/fullscreen_image_viewer.dart (1)

- Line 145: `${_currentIndex + 1} / ${widget.imageUrls.length}` [Text widget]

### packages/artbeat_community/lib/widgets/group_post_card.dart (2)

- Line 330: `${walkPost.artworkPhotos.length} artwork photos` [Text widget]
- Line 477: `#$tag` [Text widget]

### packages/artbeat_community/lib/widgets/post_detail_modal.dart (8)

- Line 267: `Comment added successfully!` [Text widget]
- Line 275: `Error adding comment: $e` [Text widget]
- Line 307: `Report Comment` [Text widget]
- Line 308: `Are you sure you want to report this comment for inappropriate content?` [Text widget]
- Line 321: `Report` [Text widget]
- Line 340: `Comment reported successfully` [Text widget]
- Line 348: `Error reporting comment: $e` [Text widget]
- Line 395: `Developer tools will be available in a future update.` [Text widget]

### packages/artbeat_community/lib/widgets/tour/art_community_tour_overlay.dart (1)

- Line 534: `STEP ${_currentStepIndex + 1} OF ${_steps.length}` [Text widget]

## artbeat_core (262)

### packages/artbeat_core/lib/src/examples/biometric_payment_integration.dart (12)

- Line 179: `Biometric Payment Settings` [Text widget]
- Line 229: `Enable Biometric Payments` [Text widget]
- Line 230: `Use fingerprint or face ID for payments` [Text widget]
- Line 239: `Require for High-Value Payments` [Text widget]
- Line 240: `Always require biometric for large amounts` [Text widget]
- Line 251: `High-Value Threshold` [Text widget]
- Line 252: `\$${_highValueThreshold.toStringAsFixed(0)}` [Text widget]
- Line 276: `Save Settings` [Text widget]
- Line 280: `To use biometric payments, your device must support fingerprint or face recognition.` [Text widget]
- Line 351: `Confirm Payment` [Text widget]
- Line 357: `${widget.amount.toStringAsFixed(2)} ${widget.currency}` [Text widget]
- Line 376: `Confirm with Biometric` [Text widget]

### packages/artbeat_core/lib/src/examples/coupon_integration_example.dart (4)

- Line 32: `Subscribe` [Text widget]
- Line 39: `Selected Plan` [Text widget]
- Line 161: `By subscribing, you agree to our Terms of Service and Privacy Policy.` [Text widget]
- Line 231: `Failed to process subscription: $e` [Text widget]

### packages/artbeat_core/lib/src/screens/art_market_screen.dart (8)

- Line 36: `Error: ${snapshot.error}` [Text widget]
- Line 92: `${filteredDocs.length} items` [Text widget]
- Line 202: `Type an artist name to find their work` [Input decoration string]
- Line 237: `No artists match that search yet` [Text widget]
- Line 246: `Try another name or browse the full collection.` [Text widget]
- Line 317: `Current Bid` [Text widget]
- Line 324: `\$${(artwork.currentHighestBid ?? artwork.startingPrice ?? 0).toStringAsFixed(0)}` [Text widget]
- Line 333: `\$${artwork.price.toStringAsFixed(0)}` [Text widget]

### packages/artbeat_core/lib/src/screens/artist_onboarding/artist_introduction_screen.dart (2)

- Line 182: `Saving...` [Text widget]
- Line 198: `Saved` [Text widget]

### packages/artbeat_core/lib/src/screens/artist_onboarding/artist_story_screen.dart (10)

- Line 132: `Failed to pick image: $e` [Text widget]
- Line 189: `Your Artist Story` [Text widget]
- Line 198: `Help people connect with your artistic journey` [Text widget]
- Line 264: `Add your artist headshot` [Text widget]
- Line 273: `Photos get 2x more profile views` [Text widget]
- Line 354: `Take Photo` [Text widget]
- Line 368: `Choose from Gallery` [Text widget]
- Line 380: `Remove Photo` [Text widget]
- Line 564: `Saving...` [Text widget]
- Line 580: `Saved` [Text widget]

### packages/artbeat_core/lib/src/screens/artist_onboarding/artwork_upload_screen.dart (11)

- Line 65: `Failed to pick images: $e` [Text widget]
- Line 97: `Failed to pick image: $e` [Text widget]
- Line 124: `Failed to take photo: $e` [Text widget]
- Line 139: `Great start! Profiles with 3+ artworks get 5x more engagement` [Text widget]
- Line 194: `${artworks.length} artwork${artworks.length == 1 ?` [Text widget]
- Line 317: `Image not found` [Text widget]
- Line 363: `For Sale` [Text widget]
- Line 528: `Artwork Details` [Text widget]
- Line 573: `Medium` [Text widget]
- Line 634: `This artwork is for sale` [Text widget]
- Line 643: `Portfolio piece only` [Text widget]

### packages/artbeat_core/lib/src/screens/artist_onboarding/benefits_screen.dart (4)

- Line 162: `🎨 78% of artists start with FREE and upgrade as they grow` [Text widget]
- Line 205: `You can change anytime from settings` [Text widget]
- Line 348: `Compare All Tiers` [Text widget]
- Line 369: `Comparison table coming soon...\n\nFor now, explore each tier using the tabs above.` [Text widget]

### packages/artbeat_core/lib/src/screens/artist_onboarding/completion_screen.dart (5)

- Line 145: `Your Artist Profile is Live! 🎉` [Text widget]
- Line 158: `Welcome to the ArtBeat community` [Text widget]
- Line 219: `Share My Profile` [Text widget]
- Line 248: `We sent you a welcome guide with tips for getting started` [Text widget]
- Line 296: `Your Profile Summary` [Text widget]

### packages/artbeat_core/lib/src/screens/artist_onboarding/featured_artwork_screen.dart (4)

- Line 112: `Featured art gets 3x more views from collectors` [Text widget]
- Line 127: `${featured.length} of 3 selected` [Text widget]
- Line 140: `Featured Order (tap arrows to reorder):` [Text widget]
- Line 153: `All Artworks (tap to select/deselect):` [Text widget]

### packages/artbeat_core/lib/src/screens/artist_onboarding/onboarding_widgets.dart (1)

- Line 104: `Skip` [Text widget]

### packages/artbeat_core/lib/src/screens/artist_onboarding/tier_selection_screen.dart (5)

- Line 101: `Unsupported tier selected: $tier` [Text widget]
- Line 164: `Setting up your artist profile...` [Text widget]
- Line 170: `Uploading images and saving your data` [Text widget]
- Line 198: `Failed to complete onboarding: $e` [Text widget]
- Line 238: `You can change your plan anytime from settings` [Text widget]

### packages/artbeat_core/lib/src/screens/artist_onboarding/welcome_screen.dart (8)

- Line 121: `ArtBeat` [Text widget]
- Line 181: `15-second welcome video\n(Coming soon)` [Text widget]
- Line 196: `Welcome to ArtBeat` [Text widget]
- Line 207: `Where Your Art Finds Its Audience` [Text widget]
- Line 249: `"Local ARTbeat has put me on the map! I love the exposure it provides and seeing others engage with my art."` [Text widget]
- Line 263: `Izzy Piel` [Text widget]
- Line 271: `Visual Artist` [Text widget]
- Line 299: `I'm Here to Discover Art` [Text widget]

### packages/artbeat_core/lib/src/screens/boosts/artist_boosts_screen.dart (6)

- Line 114: `Error loading artists: $e` [Text widget]
- Line 177: `Failed to start boost purchase. Please check:\n` [Text widget]
- Line 196: `Error: ${e.toString()}` [Text widget]
- Line 510: `@${artist.username}` [Text widget]
- Line 719: `+${tier[` [Text widget]
- Line 732: `\$${(tier[` [Text widget]

### packages/artbeat_core/lib/src/screens/chapters/chapter_landing_screen.dart (7)

- Line 56: `No Chapter Selected` [Text widget]
- Line 188: `Active Quests` [Text widget]
- Line 189: `See All` [Text widget]
- Line 196: `No active quests for this chapter.` [Text widget]
- Line 241: `+${quest.xpReward} XP` [Text widget]
- Line 274: `See All` [Text widget]
- Line 288: `Showing ${title.toLowerCase()} in this chapter...` [Text widget]

### packages/artbeat_core/lib/src/screens/coupon_management_screen.dart (12)

- Line 67: `Syncing coupons...` [Text widget]
- Line 81: `Error: ${snapshot.error}` [Text widget]
- Line 178: `Visibility passes, promo credits, and trials all live here.` [Text widget]
- Line 219: `Lifetime uses · $totalUses` [Text widget]
- Line 291: `No coupons yet` [Text widget]
- Line 300: `Create your first code to unlock promo drops, trials, and VIP access.` [Text widget]
- Line 352: `Are you sure you want to delete the coupon "${coupon.title}"? This action cannot be undone.` [Text widget]
- Line 392: `Failed to delete coupon: $e` [Text widget]
- Line 409: `Coupon ${newStatus == CouponStatus.active ?` [Text widget]
- Line 419: `Failed to update coupon: $e` [Text widget]
- Line 978: `Failed to create coupon: $e` [Text widget]
- Line 1180: `Failed to update coupon: $e` [Text widget]

### packages/artbeat_core/lib/src/screens/dashboard/animated_dashboard_screen.dart (12)

- Line 1295: `$xp XP` [Text widget]
- Line 1359: `$streakDays${` [Text widget]
- Line 1399: `English` [Text widget]
- Line 1419: `Deutsch` [Text widget]
- Line 1429: `Español` [Text widget]
- Line 1439: `Français` [Text widget]
- Line 1449: `Português` [Text widget]
- Line 1940: `No legends yet...` [Text widget]
- Line 2002: `HALL OF LEGENDS` [Text widget]
- Line 2011: `TOP 25 ARTBEAT EXPLORERS` [Text widget]
- Line 2066: `#$rank` [Text widget]
- Line 2092: `LEVEL ${entry.level}` [Text widget]

### packages/artbeat_core/lib/src/screens/dashboard/explore_dashboard_screen.dart (6)

- Line 566: `Books & Stories` [Text widget]
- Line 1041: `Next appearance` [Text widget]
- Line 1492: `${artist.followersCount} followers` [Text widget]
- Line 1968: `Artist Ad Space` [Text widget]
- Line 1977: `Boost your next drop with premium placement across Local ArtBeat.` [Text widget]
- Line 1998: `Reserve Spotlight` [Text widget]

### packages/artbeat_core/lib/src/screens/help_support_screen.dart (1)

- Line 217: `No help topics match your search yet.` [Text widget]

### packages/artbeat_core/lib/src/screens/leaderboard_screen.dart (8)

- Line 132: `Global Creator Leaderboard` [Text widget]
- Line 141: `Visibility boosts, promo ads, and artist subscriptions power every rank you see here.` [Text widget]
- Line 273: `Syncing leaderboards...` [Text widget]
- Line 312: `No data available` [Text widget]
- Line 316: `Be the first to earn points in this category` [Text widget]
- Line 456: `#${entry.rank}` [Text widget]
- Line 505: `Level ${entry.level} • ${_progressionService.getLevelTitle(entry.level)}` [Text widget]
- Line 514: `${entry.experiencePoints} total XP` [Text widget]

### packages/artbeat_core/lib/src/screens/privacy_policy_screen.dart (3)

- Line 22: `ARTbeat Privacy Policy` [Text widget]
- Line 27: `Effective Date: ${LegalConfig.effectiveDate}` [Text widget]
- Line 31: `Last Updated: ${LegalConfig.lastUpdatedDate}` [Text widget]

### packages/artbeat_core/lib/src/screens/search_results_page.dart (2)

- Line 281: `Sort:` [Text widget]
- Line 492: `Clear History` [Text widget]

### packages/artbeat_core/lib/src/screens/splash_screen.dart (3)

- Line 181: `Loading ARTbeat...` [Text widget]
- Line 339: `SCAVENGE • CAPTURE • QUEST` [Text widget]
- Line 373: `LOADING…` [Text widget]

### packages/artbeat_core/lib/src/screens/subscription_plans_screen.dart (3)

- Line 272: `Most popular` [Text widget]
- Line 340: `Save \$${savings.toStringAsFixed(0)}` [Text widget]
- Line 379: `+ ${features.length - preview.length} more benefits` [Text widget]

### packages/artbeat_core/lib/src/screens/subscription_purchase_screen.dart (4)

- Line 52: `$titlePrefix ${_getTierName(widget.tier)}` [Text widget]
- Line 135: `${_getTierName(widget.tier)} Plan` [Text widget]
- Line 413: `By continuing, you agree to recurring billing for the selected` [Text widget]
- Line 544: `$label · $priceSuffix` [Text widget]

### packages/artbeat_core/lib/src/screens/terms_of_service_screen.dart (3)

- Line 22: `ARTbeat Terms of Service` [Text widget]
- Line 27: `Effective Date: ${LegalConfig.effectiveDate}` [Text widget]
- Line 31: `Last Updated: ${LegalConfig.lastUpdatedDate}` [Text widget]

### packages/artbeat_core/lib/src/widgets/achievement_badge.dart (1)

- Line 281: `${achievements.where((a) => a.isUnlocked).length}/${achievements.length}` [Text widget]

### packages/artbeat_core/lib/src/widgets/artist_boost_widget.dart (1)

- Line 646: `\$${boost[` [Text widget]

### packages/artbeat_core/lib/src/widgets/chapters/chapter_selection_widget.dart (3)

- Line 84: `Select Your ARTbeat` [Text widget]
- Line 92: `Choose a chapter to see curated art, quests, and events for that area.` [Text widget]
- Line 116: `No active chapters found nearby.` [Text widget]

### packages/artbeat_core/lib/src/widgets/commission_artists_preview.dart (2)

- Line 67: `Artists available for commission` [Text widget]
- Line 83: `No commission artists available right now.` [Text widget]

### packages/artbeat_core/lib/src/widgets/coupon_input_widget.dart (9)

- Line 91: `Have a coupon code?` [Text widget]
- Line 108: `Enter coupon code` [Input decoration string]
- Line 140: `Apply` [Text widget]
- Line 185: `Original: \$${_couponResult![` [Text widget]
- Line 264: `FREE ACCESS` [Text widget]
- Line 280: `\$${originalPrice.toStringAsFixed(2)}` [Text widget]
- Line 297: `-${((discountAmount / originalPrice) * 100).round()}%` [Text widget]
- Line 308: `\$${discountedPrice.toStringAsFixed(2)}/month` [Text widget]
- Line 319: `\$${originalPrice.toStringAsFixed(2)}/month` [Text widget]

### packages/artbeat_core/lib/src/widgets/dashboard/art_walk_hero_section.dart (4)

- Line 217: `ARTbeat` [Text widget]
- Line 434: `Finding nearby art...` [Text widget]
- Line 458: `$_activeUsersNearby art explorers active nearby` [Text widget]
- Line 620: `$_userStreak day streak!` [Text widget]

### packages/artbeat_core/lib/src/widgets/dashboard/dashboard_artists_section.dart (4)

- Line 330: `Unable to load artists` [Text widget]
- Line 357: `No featured artists yet` [Text widget]
- Line 366: `Check back soon for featured artists!` [Text widget]
- Line 483: `${_formatFollowerCount(artist.followersCount)} followers` [Text widget]

### packages/artbeat_core/lib/src/widgets/dashboard/dashboard_artwork_section.dart (3)

- Line 154: `Unable to load artwork` [Text widget]
- Line 181: `No artwork available` [Text widget]
- Line 190: `Check back soon for featured artwork!` [Text widget]

### packages/artbeat_core/lib/src/widgets/dashboard/dashboard_captures_section.dart (5)

- Line 116: `Explore All` [Text widget]
- Line 204: `Unable to load captures` [Text widget]
- Line 231: `No captures yet` [Text widget]
- Line 241: `Be the first to discover and share amazing local art!` [Text widget]
- Line 285: `Add Capture` [Text widget]

### packages/artbeat_core/lib/src/widgets/dashboard/dashboard_community_section.dart (4)

- Line 213: `Unable to load community posts` [Text widget]
- Line 243: `No community posts yet` [Text widget]
- Line 253: `Be the first to start a conversation!` [Text widget]
- Line 268: `Create Post` [Text widget]

### packages/artbeat_core/lib/src/widgets/dashboard/dashboard_events_section.dart (6)

- Line 154: `Unable to load events` [Text widget]
- Line 181: `No upcoming events` [Text widget]
- Line 190: `Check back soon for art events!` [Text widget]
- Line 361: `${event.attendeeIds.length} attending` [Text widget]
- Line 371: `\$${(event.price ?? 0).toStringAsFixed(0)}` [Text widget]
- Line 380: `Free` [Text widget]

### packages/artbeat_core/lib/src/widgets/dashboard/dashboard_featured_posts_section.dart (4)

- Line 55: `Featured Posts` [Text widget]
- Line 63: `Curated highlights from our community` [Text widget]
- Line 180: `Featured Post ${index + 1}` [Text widget]
- Line 198: `Featured` [Text widget]

### packages/artbeat_core/lib/src/widgets/dashboard/dashboard_trending_posts_section.dart (3)

- Line 54: `Trending Posts` [Text widget]
- Line 62: `What\'s popular in the community` [Text widget]
- Line 145: `Trending Post ${index + 1}` [Text widget]

### packages/artbeat_core/lib/src/widgets/dashboard/integrated_engagement_widget.dart (1)

- Line 367: `${widget.weeklyProgress}/${widget.weeklyGoal}` [Text widget]

### packages/artbeat_core/lib/src/widgets/dashboard/user_progress_card.dart (1)

- Line 126: `$weeklyProgress/$weeklyGoal` [Text widget]

### packages/artbeat_core/lib/src/widgets/developer_menu.dart (10)

- Line 22: `Developer Menu` [Text widget]
- Line 27: `Unified Admin & Dev Tools` [Text widget]
- Line 36: `Admin Upload Tools` [Text widget]
- Line 37: `Consolidated data management` [Text widget]
- Line 45: `Developer Feedback Admin` [Text widget]
- Line 53: `Submit Feedback` [Text widget]
- Line 69: `Unified Admin Dashboard` [Text widget]
- Line 78: `Reset Onboarding` [Text widget]
- Line 79: `Show dashboard tour on next refresh` [Text widget]
- Line 85: `Onboarding reset! Refresh dashboard to see the tour.` [Text widget]

### packages/artbeat_core/lib/src/widgets/enhanced_navigation_menu.dart (6)

- Line 194: `Core` [Tab text]
- Line 195: `Content` [Tab text]
- Line 196: `Social` [Tab text]
- Line 197: `Role` [Tab text]
- Line 198: `Tools` [Tab text]
- Line 199: `Settings` [Tab text]

### packages/artbeat_core/lib/src/widgets/enhanced_subscription_card.dart (1)

- Line 323: `Unlimited Features` [Text widget]

### packages/artbeat_core/lib/src/widgets/enhanced_universal_header.dart (2)

- Line 409: `Drawer not found. Scaffold: ${scaffoldState != null}, hasDrawer: ${scaffoldState?.hasDrawer ?? false}` [Text widget]
- Line 477: `Onboarding reset! Refresh to see tours.` [Text widget]

### packages/artbeat_core/lib/src/widgets/featured_content_row_widget.dart (4)

- Line 29: `Featured Content` [Text widget]
- Line 32: `See All` [Text widget]
- Line 64: `Error: ${snapshot.error}` [Text widget]
- Line 77: `No featured content available` [Text widget]

### packages/artbeat_core/lib/src/widgets/feedback_system_info_screen.dart (4)

- Line 12: `Feedback System` [Text widget]
- Line 86: `ARTbeat Feedback System` [Text widget]
- Line 96: `A comprehensive feedback collection and management system designed to improve ARTbeat through user insights and bug reports.` [Text widget]
- Line 187: `Technical Implementation` [Text widget]

### packages/artbeat_core/lib/src/widgets/filter/date_range_filter.dart (1)

- Line 23: `Date Range` [Text widget]

### packages/artbeat_core/lib/src/widgets/filter/filter_sheet.dart (6)

- Line 67: `Filters` [Text widget]
- Line 78: `Clear All` [Text widget]
- Line 106: `Artist Types` [Text widget]
- Line 129: `Art Mediums` [Text widget]
- Line 152: `Locations` [Text widget]
- Line 175: `Tags` [Text widget]

### packages/artbeat_core/lib/src/widgets/filter/sort_filter.dart (1)

- Line 21: `Sort By` [Text widget]

### packages/artbeat_core/lib/src/widgets/leaderboard_preview_widget.dart (3)

- Line 77: `Top Contributors` [Text widget]
- Line 175: `No contributors yet` [Text widget]
- Line 238: `Level ${user.level}` [Text widget]

### packages/artbeat_core/lib/src/widgets/loading_screen.dart (1)

- Line 106: `Loading your artistic journey...` [Text widget]

### packages/artbeat_core/lib/src/widgets/main_layout.dart (1)

- Line 98: `Navigation error: ${e.toString()}` [Text widget]

### packages/artbeat_core/lib/src/widgets/navigation_examples.dart (5)

- Line 31: `Screen Content` [Text widget]
- Line 38: `Show All Features` [Text widget]
- Line 76: `Minimal Screen` [Text widget]
- Line 80: `Minimal Screen Content` [Text widget]
- Line 101: `Custom Navigation Example` [Text widget]

### packages/artbeat_core/lib/src/widgets/network_error_widget.dart (1)

- Line 38: `Unable to connect to the server. Please check your connection and try again.` [Text widget]

### packages/artbeat_core/lib/src/widgets/optimized_image.dart (1)

- Line 163: `Error` [Text widget]

### packages/artbeat_core/lib/src/widgets/payment_analytics_dashboard.dart (1)

- Line 211: `\$${event.amount.toStringAsFixed(2)}` [Text widget]

### packages/artbeat_core/lib/src/widgets/temp_capture_fix.dart (2)

- Line 24: `Fix Izzy Count` [Text widget]
- Line 24: `Fixing...` [Text widget]

### packages/artbeat_core/lib/src/widgets/tour/dashboard_tour_overlay.dart (2)

- Line 489: `STEP ${_currentStepIndex + 1} OF ${_steps.length}` [Text widget]
- Line 1107: `STEP ${_currentStepIndex + 1} OF ${_steps.length}` [Text widget]

### packages/artbeat_core/lib/src/widgets/tour/events_tour_overlay.dart (1)

- Line 496: `STEP ${_currentStepIndex + 1} OF ${_steps.length}` [Text widget]

### packages/artbeat_core/lib/src/widgets/universal_content_card.dart (1)

- Line 116: `Write a comment...` [Text widget]

### packages/artbeat_core/lib/src/widgets/usage_limits_widget.dart (11)

- Line 109: `Usage Overview` [Text widget]
- Line 183: `Approaching limit` [Text widget]
- Line 194: `Over limit - overage charges apply` [Text widget]
- Line 212: `Unlimited` [Text widget]
- Line 238: `Storage` [Text widget]
- Line 275: `Unlimited` [Text widget]
- Line 304: `Overage Charges` [Text widget]
- Line 311: `Additional charges this month: \$${_overageCost.toStringAsFixed(2)}` [Text widget]
- Line 345: `Need More?` [Text widget]
- Line 355: `Upgrade your plan for higher limits and unlimited features` [Text widget]
- Line 369: `Upgrade Plan` [Text widget]

### packages/artbeat_core/lib/src/widgets/user_experience_card.dart (2)

- Line 337: `$_unlockedCount/${widget.achievements.length}` [Text widget]
- Line 667: `${widget.user.experiencePoints} ${` [Text widget]

## artbeat_events (64)

### packages/artbeat_events/lib/src/forms/event_form_builder.dart (20)

- Line 475: `Artist headshot as seen in app (CircleAvatar). Tap to change.` [Text widget]
- Line 551: `Event banner as seen in hero section (Rounded 28). Tap to change.` [Text widget]
- Line 689: `Date & Time` [Text widget]
- Line 755: `Location` [Text widget]
- Line 794: `Contact Information` [Text widget]
- Line 852: `Event Capacity` [Text widget]
- Line 896: `Event Tags` [Text widget]
- Line 959: `Ticket Types` [Text widget]
- Line 995: `No ticket types added yet. Add at least one ticket type.` [Text widget]
- Line 1031: `Refund Policy` [Text widget]
- Line 1043: `Refund Policy` [Input decoration string]
- Line 1088: `Standard (24 hours)` [Text widget]
- Line 1098: `No Refunds` [Text widget]
- Line 1148: `Event Settings` [Text widget]
- Line 1217: `Recurring Event` [Text widget]
- Line 1254: `Repeat Pattern` [Input decoration string]
- Line 1299: `Daily` [Text widget]
- Line 1309: `Weekly` [Text widget]
- Line 1319: `Monthly` [Text widget]
- Line 1329: `Custom` [Text widget]

### packages/artbeat_events/lib/src/screens/advanced_analytics_dashboard_screen.dart (7)

- Line 396: `Trend Summary` [Text widget]
- Line 424: `No events were found for this period. Create or publish events to see event-level analytics.` [Text widget]
- Line 452: `${intl.DateFormat.yMMMd().format(event.dateTime)} • ${event.location}` [Text widget]
- Line 501: `Activity Health` [Text widget]
- Line 527: `Activity Snapshot` [Text widget]
- Line 550: `Recommended Actions` [Text widget]
- Line 631: `No trend data available` [Text widget]

### packages/artbeat_events/lib/src/screens/calendar_screen.dart (1)

- Line 302: `${intl.DateFormat(` [Text widget]

### packages/artbeat_events/lib/src/screens/create_event_screen.dart (3)

- Line 342: `You have unsaved changes. Are you sure you want to leave?` [Text widget]
- Line 357: `Cancel` [Text widget]
- Line 371: `Leave` [Text widget]

### packages/artbeat_events/lib/src/screens/event_bulk_management_screen.dart (14)

- Line 176: `Category` [Input decoration string]
- Line 179: `All` [Text widget]
- Line 180: `Art Show` [Text widget]
- Line 181: `Workshop` [Text widget]
- Line 182: `Exhibition` [Text widget]
- Line 183: `Sale` [Text widget]
- Line 184: `Other` [Text widget]
- Line 199: `Status` [Input decoration string]
- Line 202: `All` [Text widget]
- Line 203: `Active` [Text widget]
- Line 204: `Inactive` [Text widget]
- Line 205: `Cancelled` [Text widget]
- Line 206: `Postponed` [Text widget]
- Line 207: `Draft` [Text widget]

### packages/artbeat_events/lib/src/screens/event_details_screen.dart (2)

- Line 368: `${event.attendeeIds.length}/${event.maxAttendees}` [Text widget]
- Line 723: `${ticket.remainingQuantity} ${` [Text widget]

### packages/artbeat_events/lib/src/screens/events_dashboard_screen.dart (2)

- Line 370: `$greeting, $userName!` [Text widget]
- Line 521: `Browse` [Text widget]

### packages/artbeat_events/lib/src/screens/events_dashboard_screen_old.dart (9)

- Line 260: `Search Events` [Text widget]
- Line 268: `Find events, venues, and organizers` [Text widget]
- Line 567: `Category:` [Text widget]
- Line 620: `When:` [Text widget]
- Line 1141: `Discover Events` [Text widget]
- Line 1327: `Error loading events` [Text widget]
- Line 1779: `#$tag` [Text widget]
- Line 1822: `Getting Started` [Text widget]
- Line 1837: `Sign in to unlock all features:` [Text widget]

### packages/artbeat_events/lib/src/widgets/qr_code_ticket_widget.dart (5)

- Line 97: `ARTbeat Event` [Text widget]
- Line 180: `Scan for Entry` [Text widget]
- Line 204: `Ticket ID: ${_formatTicketId(ticket.id)}` [Text widget]
- Line 246: `⚠️ Important` [Text widget]
- Line 255: `Keep this QR code safe and present it at the event entrance. Screenshots are acceptable.` [Text widget]

### packages/artbeat_events/lib/src/widgets/ticket_purchase_sheet.dart (1)

- Line 242: `${widget.ticketType.remainingQuantity} ${` [Text widget]

## artbeat_messaging (110)

### packages/artbeat_messaging/lib/src/screens/artistic_messaging_screen.dart (22)

- Line 123: `Search Messages` [Text widget]
- Line 131: `Find conversations and contacts` [Text widget]
- Line 239: `Messaging Profile` [Text widget]
- Line 247: `Your communication preferences` [Text widget]
- Line 613: `Error loading chats` [Text widget]
- Line 622: `Please try again later` [Text widget]
- Line 653: `No conversations yet` [Text widget]
- Line 662: `Start a conversation with artists and art enthusiasts` [Text widget]
- Line 927: `Error loading online users` [Text widget]
- Line 962: `No one is online right now` [Text widget]
- Line 971: `Check back later to see who\'s active` [Text widget]
- Line 1028: `Error loading groups` [Text widget]
- Line 1071: `No groups created yet` [Text widget]
- Line 1080: `Create your first group to connect with other artists` [Text widget]
- Line 1131: `Error loading groups` [Text widget]
- Line 1180: `No groups joined yet` [Text widget]
- Line 1189: `Join groups to connect with the art community` [Text widget]
- Line 1235: `New` [Text widget]
- Line 1265: `Start New Conversation` [Text widget]
- Line 1543: `$memberCount members` [Text widget]
- Line 1697: `Online` [Text widget]
- Line 1843: `Online now` [Text widget]

### packages/artbeat_messaging/lib/src/screens/blocked_users_screen.dart (6)

- Line 79: `No blocked users` [Text widget]
- Line 86: `Users you block will appear here. They won\'t be able to message you or see your activity.` [Text widget]
- Line 123: `@${user.username!}` [Text widget]
- Line 132: `Blocked on ${_formatBlockedDate(user.blockedAt ?? DateTime.now())}` [Text widget]
- Line 175: `Are you sure you want to unblock ${user.displayName}? They will be able to message you again.` [Text widget]
- Line 280: `Reason for reporting (optional)` [Input decoration string]

### packages/artbeat_messaging/lib/src/screens/chat_info_screen.dart (1)

- Line 198: `Last seen: ${_formatLastSeen(_participants.first.lastSeen)}` [Text widget]

### packages/artbeat_messaging/lib/src/screens/chat_list_screen.dart (7)

- Line 72: `Error loading chats` [Text widget]
- Line 116: `Loading conversations...` [Text widget]
- Line 149: `No messages yet` [Text widget]
- Line 159: `Start a conversation with fellow artists and connect with the creative community` [Text widget]
- Line 365: `Search chats...` [Input decoration string]
- Line 398: `Error searching chats` [Text widget]
- Line 411: `No chats found` [Text widget]

### packages/artbeat_messaging/lib/src/screens/chat_screen.dart (9)

- Line 292: `Select Emoji` [Text widget]
- Line 559: `Error loading messages` [Text widget]
- Line 596: `Loading messages...` [Text widget]
- Line 644: `No messages yet` [Text widget]
- Line 656: `Start the conversation by sending a message below` [Text widget]
- Line 742: `$name is typing` [Text widget]
- Line 845: `Failed to share location: ${e.toString()}` [Text widget]
- Line 889: `Replying to` [Text widget]
- Line 950: `Type a message...` [Input decoration string]

### packages/artbeat_messaging/lib/src/screens/chat_search_screen.dart (1)

- Line 26: `Search messages...` [Input decoration string]

### packages/artbeat_messaging/lib/src/screens/chat_settings_screen.dart (3)

- Line 165: `Are you sure you want to clear all chat history? This action cannot be undone.` [Text widget]
- Line 207: `Clear` [Text widget]
- Line 227: `Changes to these settings will apply to all your chats.` [Text widget]

### packages/artbeat_messaging/lib/src/screens/contact_selection_screen.dart (8)

- Line 41: `Search by name, username, or zip code...` [Input decoration string]
- Line 77: `Start typing to search for people...` [Text widget]
- Line 82: `Search by name, username, or zip code` [Text widget]
- Line 98: `Error loading users` [Text widget]
- Line 120: `No users found` [Text widget]
- Line 125: `Try searching with a different name, username, or zip code` [Text widget]
- Line 152: `@${user.username}` [Text widget]
- Line 231: `Error creating chat: ${e.toString()}` [Text widget]

### packages/artbeat_messaging/lib/src/screens/enhanced_messaging_dashboard_screen.dart (14)

- Line 285: `Messaging Dashboard` [Text widget]
- Line 293: `Admin Control Center` [Text widget]
- Line 344: `Activity` [Tab text]
- Line 345: `Users` [Tab text]
- Line 346: `Analytics` [Tab text]
- Line 403: `Something went wrong` [Text widget]
- Line 408: `Error: $e` [Text widget]
- Line 433: `Overview` [Text widget]
- Line 553: `Recent Activity` [Text widget]
- Line 701: `Online Users (${users.length})` [Text widget]
- Line 886: `Analytics & Insights` [Text widget]
- Line 1082: `Message` [Input decoration string]
- Line 1083: `Enter your broadcast message...` [Input decoration string]
- Line 1094: `This will be sent to all active users` [Text widget]

### packages/artbeat_messaging/lib/src/screens/group_chat_screen.dart (2)

- Line 38: `No Group Chats` [Text widget]
- Line 43: `Start a group chat to collaborate with artists` [Text widget]

### packages/artbeat_messaging/lib/src/screens/group_creation_screen.dart (4)

- Line 81: `Group name` [Input decoration string]
- Line 142: `Search people...` [Input decoration string]
- Line 165: `Error loading users` [Text widget]
- Line 181: `No users found` [Text widget]

### packages/artbeat_messaging/lib/src/screens/group_edit_screen.dart (2)

- Line 30: `Enter feed name` [Input decoration string]
- Line 37: `Use your artist dashboard to manage individual posts.` [Text widget]

### packages/artbeat_messaging/lib/src/screens/message_thread_view_screen.dart (2)

- Line 185: `Original Message` [Text widget]
- Line 270: `Reply to thread...` [Input decoration string]

### packages/artbeat_messaging/lib/src/screens/messaging_dashboard_screen.dart (3)

- Line 139: `Messages` [Text widget]
- Line 180: `Online (${filteredOnlineUsers.length})` [Text widget]
- Line 291: `Recent Chats` [Text widget]

### packages/artbeat_messaging/lib/src/screens/starred_messages_screen.dart (3)

- Line 39: `Error loading starred messages` [Text widget]
- Line 63: `No starred messages` [Text widget]
- Line 68: `Long press on any message and tap the star icon to add it here` [Text widget]

### packages/artbeat_messaging/lib/src/screens/user_profile_screen.dart (1)

- Line 112: `Error creating chat: ${e.toString()}` [Text widget]

### packages/artbeat_messaging/lib/src/theme/chat_theme.dart (1)

- Line 62: `Type a message...` [Input decoration string]

### packages/artbeat_messaging/lib/src/widgets/chat_input.dart (1)

- Line 113: `Type a message...` [Input decoration string]

### packages/artbeat_messaging/lib/src/widgets/custom_emoji_picker.dart (2)

- Line 96: `Choose an emoji` [Text widget]
- Line 118: `Search emojis...` [Input decoration string]

### packages/artbeat_messaging/lib/src/widgets/full_reaction_picker.dart (2)

- Line 104: `Choose a reaction` [Text widget]
- Line 124: `Search emojis...` [Input decoration string]

### packages/artbeat_messaging/lib/src/widgets/message_bubble.dart (1)

- Line 182: `Image not available` [Text widget]

### packages/artbeat_messaging/lib/src/widgets/message_interactions.dart (10)

- Line 225: `Edit Message` [Text widget]
- Line 252: `This message was previously edited` [Text widget]
- Line 266: `Enter your message...` [Input decoration string]
- Line 389: `Forward Message` [Text widget]
- Line 426: `Select conversations:` [Text widget]
- Line 497: `Forward to ${_selectedChats.length} chat${_selectedChats.length == 1 ?` [Text widget]
- Line 567: `Forwarded` [Text widget]
- Line 594: `Replying to message` [Text widget]
- Line 718: `Message forwarded to ${selectedChats.length} chat${selectedChats.length == 1 ?` [Text widget]
- Line 895: `Tap to retry` [Text widget]

### packages/artbeat_messaging/lib/src/widgets/message_reactions_widget.dart (2)

- Line 257: `Choose a reaction` [Text widget]
- Line 383: `${reactions.length} ${reactions.length == 1 ?` [Text widget]

### packages/artbeat_messaging/lib/src/widgets/messaging_header.dart (1)

- Line 201: `Messaging Menu` [Text widget]

### packages/artbeat_messaging/lib/src/widgets/smart_replies_widget.dart (1)

- Line 103: `Smart replies` [Text widget]

### packages/artbeat_messaging/lib/src/widgets/thread_reply_widget.dart (1)

- Line 48: `Replying to message` [Text widget]

## artbeat_profile (84)

### packages/artbeat_profile/lib/src/screens/achievement_info_screen.dart (3)

- Line 105: `Earn XP through art walks, captures, reviews, and community contributions. Level up to unlock exclusive perks and become an Art Walk Influencer!` [Text widget]
- Line 163: `Ready to Start Your Journey?` [Text widget]
- Line 172: `Begin exploring art walks to earn your first achievements!` [Text widget]

### packages/artbeat_profile/lib/src/screens/achievements_screen.dart (6)

- Line 90: `Please sign in to view achievements` [Text widget]
- Line 114: `Achievements` [Tab text]
- Line 115: `Badges` [Tab text]
- Line 150: `Level Progress` [Text widget]
- Line 165: `${user.xp} XP / ${user.nextLevelXp} XP` [Text widget]
- Line 193: `Your Badge Collection` [Text widget]

### packages/artbeat_profile/lib/src/screens/create_profile_screen.dart (4)

- Line 190: `Welcome to ARTbeat!` [Text widget]
- Line 200: `Let\'s set up your profile to get started` [Text widget]
- Line 243: `Tap to add profile photo (optional)` [Text widget]
- Line 376: `Create Profile` [Text widget]

### packages/artbeat_profile/lib/src/screens/favorite_detail_screen.dart (11)

- Line 49: `Error loading favorite: ${e.toString()}` [Text widget]
- Line 90: `Favorite not found` [Text widget]
- Line 95: `The favorite you\'re looking for might have been removed.` [Text widget]
- Line 210: `Content` [Text widget]
- Line 235: `Source` [Text widget]
- Line 252: `Could not open URL: $sourceUrl` [Text widget]
- Line 269: `Added on ${_formatDate(createdAt)}` [Text widget]
- Line 313: `Remove Favorite` [Text widget]
- Line 314: `Are you sure you want to remove this from your favorites?` [Text widget]
- Line 335: `Removed from favorites` [Text widget]
- Line 343: `Error removing favorite: ${e.toString()}` [Text widget]

### packages/artbeat_profile/lib/src/screens/followed_artists_screen.dart (3)

- Line 207: `${_artists.length} following` [Text widget]
- Line 222: `Pull to refresh` [Text widget]
- Line 281: `Following` [Text widget]

### packages/artbeat_profile/lib/src/screens/profile_activity_screen.dart (4)

- Line 310: `Time: ${_formatTimestamp(activity.createdAt)}` [Text widget]
- Line 316: `Details:` [Text widget]
- Line 321: `${entry.key}: ${entry.value}` [Text widget]
- Line 351: `Error marking as read: $e` [Text widget]

### packages/artbeat_profile/lib/src/screens/profile_analytics_screen.dart (4)

- Line 52: `Error loading analytics: \$e` [Text widget]
- Line 63: `No engagement metrics yet` [Text widget]
- Line 266: `No Analytics Data` [Text widget]
- Line 275: `Your profile analytics will appear here once you start gaining activity.` [Text widget]

### packages/artbeat_profile/lib/src/screens/profile_connections_screen.dart (9)

- Line 93: `Error loading connections: $e` [Text widget]
- Line 288: `Mutuals` [Tab text]
- Line 289: `Suggestions` [Tab text]
- Line 290: `Followers` [Tab text]
- Line 291: `Following` [Tab text]
- Line 310: `Retry` [Text widget]
- Line 340: `Connect` [Text widget]
- Line 353: `Skip` [Text widget]
- Line 505: `@${user.username}` [Text widget]

### packages/artbeat_profile/lib/src/screens/profile_menu_screen.dart (2)

- Line 76: `My Profile` [Text widget]
- Line 286: `Legal Center` [Text widget]

### packages/artbeat_profile/lib/src/screens/profile_settings_screen.dart (3)

- Line 21: `Settings` [Text widget]
- Line 76: `Change Password` [Text widget]
- Line 87: `Delete Account` [Text widget]

### packages/artbeat_profile/lib/src/screens/profile_view_screen.dart (5)

- Line 411: `@$username` [Text widget]
- Line 430: `LEVEL $level` [Text widget]
- Line 646: `Profile Journey` [Text widget]
- Line 812: `No captures yet` [Text widget]
- Line 814: `Start capturing to showcase your art trail.` [Text widget]

### packages/artbeat_profile/lib/src/widgets/achievement_tile.dart (1)

- Line 58: `Earned on ${ach.earnedAt.toString().split(` [Text widget]

### packages/artbeat_profile/lib/src/widgets/dynamic_achievements_tab.dart (5)

- Line 58: `Achievement Collection` [Text widget]
- Line 67: `${_getEarnedBadgesCount()}/${_badges.length}` [Text widget]
- Line 427: `Requirement:` [Text widget]
- Line 435: `${requirement[` [Text widget]
- Line 458: `${(progress * 100).toInt()}% Complete` [Text widget]

### packages/artbeat_profile/lib/src/widgets/enhanced_stats_grid.dart (1)

- Line 41: `Stats` [Text widget]

### packages/artbeat_profile/lib/src/widgets/level_progress_bar.dart (3)

- Line 82: `Level $level` [Text widget]
- Line 109: `$currentXP XP` [Text widget]
- Line 156: `$xpToNextLevel XP to Level ${level + 1}` [Text widget]

### packages/artbeat_profile/lib/src/widgets/profile_header.dart (2)

- Line 48: `@$handle` [Text widget]
- Line 53: `Level $xpLevel` [Text widget]

### packages/artbeat_profile/lib/src/widgets/profile_xp_card.dart (2)

- Line 29: `Level $level` [Text widget]
- Line 36: `$currentXp / $nextLevelXp XP` [Text widget]

### packages/artbeat_profile/lib/src/widgets/progress_tab.dart (12)

- Line 74: `Your Progress` [Text widget]
- Line 138: `Today\'s Challenge` [Text widget]
- Line 158: `Completed` [Text widget]
- Line 196: `${challenge.currentCount}/${challenge.targetCount}` [Text widget]
- Line 243: `${challenge.rewardXp} XP` [Text widget]
- Line 281: `Weekly Goals` [Text widget]
- Line 319: `$current/$target` [Text widget]
- Line 358: `Streak Calendar` [Text widget]
- Line 435: `Level Progress` [Text widget]
- Line 446: `Level $currentLevel: ${levelInfo[` [Text widget]
- Line 456: `Next: ${nextLevelInfo[` [Text widget]
- Line 464: `$currentXP / ${nextLevelInfo[` [Text widget]

### packages/artbeat_profile/lib/src/widgets/recent_badges_carousel.dart (1)

- Line 65: `Recent Badges` [Text widget]

### packages/artbeat_profile/lib/src/widgets/streak_display.dart (1)

- Line 38: `Active Streaks` [Text widget]

### packages/artbeat_profile/lib/src/widgets/user_list_tile.dart (1)

- Line 82: `@$handle` [Text widget]

### packages/artbeat_profile/lib/src/widgets/xp_badge.dart (1)

- Line 17: `XP: $xp` [Text widget]

## artbeat_settings (22)

### packages/artbeat_settings/lib/src/screens/_artist_autocomplete_dialog.dart (2)

- Line 44: `Enter artist name` [Input decoration string]
- Line 68: `@${user.username}` [Text widget]

### packages/artbeat_settings/lib/src/screens/account_settings_screen.dart (1)

- Line 665: `Verification Code` [Input decoration string]

### packages/artbeat_settings/lib/src/screens/app_settings_screen.dart (5)

- Line 86: `Storage details coming soon` [Text widget]
- Line 137: `Sign Out` [Text widget]
- Line 138: `Are you sure you want to sign out?` [Text widget]
- Line 146: `Sign Out` [Text widget]
- Line 164: `Error signing out: $e` [Text widget]

### packages/artbeat_settings/lib/src/screens/privacy_settings_screen.dart (10)

- Line 42: `Delete Account?` [Text widget]
- Line 43: `This permanently deletes your account access. Most user-facing` [Text widget]
- Line 59: `Delete` [Text widget]
- Line 105: `Re-authentication Required` [Text widget]
- Line 106: `For security, please sign out and sign back in before deleting your account.` [Text widget]
- Line 285: `Recent Requests` [Text widget]
- Line 316: `Sign in to view request status` [Text widget]
- Line 343: `No requests submitted yet` [Text widget]
- Line 344: `Requests appear here once submitted.` [Text widget]
- Line 372: `Status: $status\nRequested: $requestedAtLabel` [Text widget]

### packages/artbeat_settings/lib/src/screens/theme_settings_screen.dart (1)

- Line 64: `Additional theme options will be available in future updates.` [Text widget]

### packages/artbeat_settings/lib/src/widgets/settings_header.dart (3)

- Line 265: `Reset Onboarding` [Text widget]
- Line 266: `Show all tours on next refresh` [Text widget]
- Line 273: `Onboarding reset! Refresh to see tours.` [Text widget]

## artbeat_sponsorships (10)

### packages/artbeat_sponsorships/lib/src/screens/sponsorships/sponsorship_review_screen.dart (3)

- Line 211: `Business address` [Input decoration string]
- Line 212: `123 Main St, City, State ZIP` [Input decoration string]
- Line 366: `Sponsorship submitted. Payment is on file and the request is now queued for review.` [Text widget]

### packages/artbeat_sponsorships/lib/src/widgets/sponsor_art_selection_widget.dart (2)

- Line 68: `Search for art pieces...` [Input decoration string]
- Line 120: `${capture.artistName} • ${capture.locationName}` [Text widget]

### packages/artbeat_sponsorships/lib/src/widgets/sponsor_banner.dart (5)

- Line 254: `Capture Sponsor` [Text widget]
- Line 311: `Sponsor this space` [Text widget]
- Line 318: `Connect with local art explorers` [Text widget]
- Line 344: `Sponsor link is not available right now.` [Text widget]
- Line 354: `Unable to open sponsor link.` [Text widget]

## main_app (173)

### lib/app.dart (1)

- Line 51: `Error: $e` [Text widget]

### lib/main.dart (1)

- Line 122: `Initialization Error` [Text widget]

### lib/screens/in_app_purchase_demo_screen.dart (17)

- Line 37: `In-App Purchase Demo` [Text widget]
- Line 60: `Status` [Text widget]
- Line 71: `Refresh Status` [Text widget]
- Line 80: `Subscriptions` [Text widget]
- Line 91: `Subscription Plans` [Text widget]
- Line 102: `View All Subscription Options` [Text widget]
- Line 112: `Artist Boosts` [Text widget]
- Line 123: `Power Up Artists with Boosts` [Text widget]
- Line 128: `Send power-ups to artists to boost their visibility and earn XP.` [Text widget]
- Line 137: `Send a Boost` [Text widget]
- Line 147: `Debug Information` [Text widget]
- Line 158: `Purchase Manager Available: ${_purchaseManager.isAvailable}` [Text widget]
- Line 162: `All IAP services initialized and ready.` [Text widget]
- Line 177: `Send an Artist Boost` [Text widget]
- Line 178: `Choose a boost tier to power up this artist.` [Text widget]
- Line 189: `Opening boost purchase screen...` [Text widget]
- Line 194: `Send Boost` [Text widget]

### lib/screens/notifications_screen.dart (1)

- Line 639: `Debug Tools` [Text widget]

### lib/src/app_refactored.dart (2)

- Line 45: `Error initializing app` [Text widget]
- Line 74: `Initializing ARTbeat...` [Text widget]

### lib/src/guards/auth_guard.dart (3)

- Line 125: `Authentication Required` [Text widget]
- Line 130: `Please sign in to access this feature` [Text widget]
- Line 139: `Sign In` [Text widget]

### lib/src/managers/network_manager.dart (2)

- Line 202: `No internet connection` [Text widget]
- Line 211: `Retry` [Text widget]

### lib/src/routing/app_router.dart (7)

- Line 305: `Artist not found` [Text widget]
- Line 1026: `Refund management coming soon` [Text widget]
- Line 1083: `System Info - Coming Soon` [Text widget]
- Line 1100: `Favorites not available` [Text widget]
- Line 1245: `Try Again` [Text widget]
- Line 1254: `Artist not found` [Text widget]
- Line 1291: `Error creating chat: $e` [Text widget]

### lib/src/routing/handlers/art_walk_route_handler.dart (2)

- Line 99: `Please log in to view your captures` [Text widget]
- Line 109: `Error loading captures` [Text widget]

### lib/src/routing/handlers/artist_route_handler.dart (1)

- Line 5: `Coming Soon - Artist Feature` [Text widget]

### lib/src/routing/handlers/capture_route_handler.dart (5)

- Line 31: `Error loading community captures` [Input decoration string]
- Line 72: `Error loading capture` [Text widget]
- Line 138: `Please log in to view your captures` [Text widget]
- Line 148: `Error loading captures` [Text widget]
- Line 217: `Error` [Text widget]

### lib/src/routing/handlers/core_route_handler.dart (3)

- Line 96: `Please log in to view your profile` [Text widget]
- Line 110: `Please log in to edit your profile` [Text widget]
- Line 159: `Following coming soon` [Text widget]

### lib/src/routing/handlers/events_route_handler.dart (1)

- Line 42: `Coming Soon` [Text widget]

### lib/src/routing/handlers/gallery_route_handler.dart (1)

- Line 5: `Coming Soon - Gallery Feature` [Text widget]

### lib/src/routing/handlers/profile_route_handler.dart (15)

- Line 23: `Profile not available` [Text widget]
- Line 56: `Profile edit not available` [Text widget]
- Line 153: `Following not available` [Text widget]
- Line 178: `Followers not available` [Text widget]
- Line 201: `Liked content not available` [Text widget]
- Line 237: `Blocked users not available` [Text widget]
- Line 273: `Favorites not available` [Text widget]
- Line 349: `Activity History` [Text widget]
- Line 353: `Recent Activity` [Tab text]
- Line 354: `Unread` [Tab text]
- Line 650: `Time: ${_formatTimestamp(activity.createdAt)}` [Text widget]
- Line 656: `Details:` [Text widget]
- Line 661: `${entry.key}: ${entry.value}` [Text widget]
- Line 677: `Mark as read` [Text widget]
- Line 691: `Error marking as read: $e` [Text widget]

### lib/src/routing/handlers/settings_route_handler.dart (1)

- Line 17: `Coming Soon` [Text widget]

### lib/src/routing/route_utils.dart (4)

- Line 101: `Page Not Found` [Text widget]
- Line 131: `$feature Coming Soon` [Text widget]
- Line 139: `This feature is under development.` [Text widget]
- Line 161: `Error` [Text widget]

### lib/src/screens/ads_route_screen.dart (10)

- Line 52: `Local Ads` [Text widget]
- Line 107: `Support local art with local business ads` [Text widget]
- Line 116: `Create a simple local ad that helps fund artists and keeps your business visible in the Artbeat community.` [Text widget]
- Line 169: `Launch a simple local ad` [Text widget]
- Line 178: `Create a banner or inline ad request for your business, or browse active local promotions already running in the app.` [Text widget]
- Line 186: `Monthly ad subscriptions are paid through Apple, then reviewed before they go live.` [Text widget]
- Line 195: `Available placements: Community feed, Artists and artwork, and Events.` [Text widget]
- Line 204: `After you submit, Apple checkout opens. Approved ads then publish into the placement you selected.` [Text widget]
- Line 220: `Submit local ad` [Text widget]
- Line 225: `Browse local ads` [Text widget]

### lib/src/screens/artwork_auction_management_route_screen.dart (1)

- Line 32: `Artwork not found` [Text widget]

### lib/src/screens/privacy_policy_screen.dart (3)

- Line 22: `ARTbeat Privacy Policy` [Text widget]
- Line 27: `Effective Date: ${LegalConfig.effectiveDate}` [Text widget]
- Line 31: `Last Updated: ${LegalConfig.lastUpdatedDate}` [Text widget]

### lib/src/screens/rewards_screen.dart (15)

- Line 69: `Rewards & Achievements` [Text widget]
- Line 79: `Overview` [Tab text]
- Line 80: `Badges` [Tab text]
- Line 81: `Perks` [Tab text]
- Line 99: `Please sign in to view your rewards` [Text widget]
- Line 160: `Level ${userData.level}` [Text widget]
- Line 181: `$xp XP` [Text widget]
- Line 190: `${levelRange[` [Text widget]
- Line 207: `Recent Achievements` [Text widget]
- Line 293: `Your Statistics` [Text widget]
- Line 382: `Your Badge Collection` [Text widget]
- Line 504: `Your Current Perks` [Text widget]
- Line 521: `No perks unlocked at this level yet.` [Text widget]
- Line 533: `Unlock at Next Level` [Text widget]
- Line 550: `No additional perks at the next level.` [Text widget]

### lib/src/screens/route_analytics_dashboard.dart (5)

- Line 45: `Error loading analytics: $error` [Text widget]
- Line 168: `Popular Routes` [Text widget]
- Line 202: `$visitCount visits` [Text widget]
- Line 227: `Route Details` [Text widget]
- Line 278: `Visit Route` [Text widget]

### lib/src/screens/terms_of_service_screen.dart (3)

- Line 22: `ARTbeat Terms of Service` [Text widget]
- Line 27: `Effective Date: ${LegalConfig.effectiveDate}` [Text widget]
- Line 31: `Last Updated: ${LegalConfig.lastUpdatedDate}` [Text widget]

### lib/src/services/navigation_service.dart (4)

- Line 88: `Navigation Error` [Text widget]
- Line 93: `Failed to navigate to: $routeName` [Text widget]
- Line 95: `Error: ${error.toString()}` [Text widget]
- Line 113: `Go to Dashboard` [Text widget]

### lib/src/utils/route_utils.dart (1)

- Line 20: `Route not found` [Text widget]

### lib/src/widgets/artist_feed_container.dart (3)

- Line 74: `Loading your artist feed...` [Text widget]
- Line 97: `Create Artist Profile` [Text widget]
- Line 105: `Artist profile not found` [Text widget]

### lib/src/widgets/artist_feed_container_with_params.dart (4)

- Line 88: `Loading artist feed...` [Text widget]
- Line 116: `Create Artist Profile` [Text widget]
- Line 122: `Go Back` [Text widget]
- Line 130: `Artist profile not found` [Text widget]

### lib/src/widgets/error_boundary.dart (4)

- Line 81: `Something went wrong` [Text widget]
- Line 99: `Try Again` [Text widget]
- Line 138: `Network Connection Lost` [Text widget]
- Line 143: `Please check your internet connection and try again.` [Text widget]

### lib/temp_capture_fix.dart (2)

- Line 22: `Fix Izzy Count` [Text widget]
- Line 22: `Fixing...` [Text widget]

### lib/test_artist_features_app.dart (17)

- Line 25: `🧪 Artist Features Test` [Text widget]
- Line 41: `🎯 Test Controls` [Text widget]
- Line 51: `Select Subscription Tier` [Input decoration string]
- Line 58: `${tier.displayName} - \$${tier.monthlyPrice}/month` [Text widget]
- Line 103: `Clear` [Text widget]
- Line 128: `📊 Test Results` [Text widget]
- Line 163: `$passed/$total ($successRate%)` [Text widget]
- Line 179: `No tests run yet` [Text widget]
- Line 184: `Select a subscription tier and run tests to verify artist features` [Text widget]
- Line 290: `Test Summary for ${_selectedTier?.toUpperCase()} tier:` [Text widget]
- Line 292: `• Passed: $passed` [Text widget]
- Line 293: `• Failed: ${total - passed}` [Text widget]
- Line 294: `• Success Rate: $successRate%` [Text widget]
- Line 297: `Failed tests may indicate features that need attention:` [Text widget]
- Line 304: `• ${_formatFeatureName(e.key)}` [Text widget]
- Line 319: `View Report` [Text widget]
- Line 332: `📋 Detailed Test Report` [Text widget]

### lib/test_payment_debug.dart (4)

- Line 138: `Payment Debug` [Text widget]
- Line 148: `Test Stripe Initialization` [Text widget]
- Line 153: `Test Add Payment Method` [Text widget]
- Line 186: `Clear Output` [Text widget]

### lib/test_secure_image_screen.dart (9)

- Line 27: `Testing SecureNetworkImage with Firebase Storage URLs` [Text widget]
- Line 32: `The images below should handle 403 errors gracefully with retry functionality:` [Text widget]
- Line 47: `Test Image ${index + 1}` [Text widget]
- Line 55: `URL: ${testUrls[index].length > 60 ?` [Text widget]
- Line 85: `Failed to load image` [Text widget]
- Line 93: `Check debug console for details` [Text widget]
- Line 111: `Loading...` [Text widget]
- Line 139: `Debug Information:` [Text widget]
- Line 147: `• Check the debug console for SecureNetworkImage logs\n` [Text widget]

### lib/widgets/developer_menu.dart (21)

- Line 23: `Developer Menu` [Text widget]
- Line 28: `Screen Navigation & Tools` [Text widget]
- Line 49: `Admin Command Center` [Text widget]
- Line 54: `Unified Admin Dashboard` [Text widget]
- Line 55: `Central hub for all administration` [Text widget]
- Line 63: `System Settings` [Text widget]
- Line 73: `Feedback System` [Text widget]
- Line 77: `Submit Feedback` [Text widget]
- Line 78: `Test the feedback form` [Text widget]
- Line 89: `System Info` [Text widget]
- Line 90: `Learn about the feedback system` [Text widget]
- Line 105: `Backup Management` [Text widget]
- Line 108: `View Backups` [Text widget]
- Line 111: `Backup viewer coming soon` [Text widget]
- Line 116: `Create Backup` [Text widget]
- Line 119: `Backup creation coming soon` [Text widget]
- Line 124: `Restore Backup` [Text widget]
- Line 127: `Backup restoration coming soon` [Text widget]
- Line 135: `Debug Tools` [Text widget]
- Line 138: `Fix Profile Image` [Text widget]
- Line 139: `Update profile image URL` [Text widget]

## Unique Text

- `"$title" by $artistName`
- `"${art.title}" removed from featured artworks`
- `"${widget.celebrationData.walk.title}"`
- `"Local ARTbeat has put me on the map! I love the exposure it provides and seeing others engage with my art."`
- `#$rank`
- `#$tag`
- `#${entry.rank}`
- `#${index + 1}`
- `$_activeUsersNearby art explorers active nearby`
- `$_unlockedCount/${widget.achievements.length}`
- `$_userStreak day streak!`
- `$current/$target`
- `$currentXP / ${nextLevelInfo[`
- `$currentXP XP`
- `$currentXp / $nextLevelXp XP`
- `$e\n\n$stackTrace`
- `$feature Coming Soon`
- `$formattedDate at $formattedTime`
- `$greeting, $userName!`
- `$label · $priceSuffix`
- `$memberCount members`
- `$name is typing`
- `$passed/$total ($successRate%)`
- `$percentage% Complete`
- `$streakDays${`
- `$titlePrefix ${_getTierName(widget.tier)}`
- `$turnaroundDays days`
- `$visitCount visits`
- `$visited / $total`
- `$visitedCount/$totalCount`
- `$weeklyProgress/$weeklyGoal`
- `$xp XP`
- `$xpToNextLevel XP to Level ${level + 1}`
- `${(_mainImageUploadProgress * 100).toInt()}% ${`
- `${(progress * 100).toInt()}% Complete`
- `${_artists.length} following`
- `${_chapters.length} Total`
- `${_currentIndex + 1} / ${widget.imageUrls.length}`
- `${_currentIndex + 1}/${widget.captures.length}`
- `${_formatDuration(_audioPosition)} / ${_formatDuration(_audioDuration)}`
- `${_formatFollowerCount(artist.followersCount)} followers`
- `${_getEarnedBadgesCount()}/${_badges.length}`
- `${_getTierName(widget.tier)} Plan`
- `${_onlineArtists.length} online`
- `${_ratingStats!.averageRating.toStringAsFixed(1)} (${_ratingStats!.totalRatings} ratings)`
- `${_selectedArtPieces.length} art piece${_selectedArtPieces.length == 1 ?`
- `${_selectedImages.length}/5`
- `${_selectedTransactionIds.length} selected`
- `${_stats[`
- `${_studio!.memberList.length} members`
- `${_titleCase(sponsorship.tier)} sponsor`
- `${_videoDuration.inMinutes}:${(_videoDuration.inSeconds % 60).toString().padLeft(2,`
- `${_width}x$_height`
- `${_writtenWorks.length} ${_writtenWorks.length == 1 ?`
- `${account.bankName ??`
- `${achievements.where((a) => a.isUnlocked).length}/${achievements.length}`
- `${ad.daysRemaining}d`
- `${artist.followersCount} followers`
- `${artist.fullName} removed from featured artists`
- `${artist[`
- `${artwork.viewCount} views`
- `${artworks.length} artwork${artworks.length == 1 ?`
- `${boost.daysRemaining}d left`
- `${capture.artistName} • ${capture.locationName}`
- `${challenge.currentCount}/${challenge.targetCount}`
- `${challenge.currentCount}/${challenge.targetCount} ${_getProgressUnit(challenge.title)}`
- `${challenge.rewardXp} XP`
- `${chapter.estimatedReadingTime} min`
- `${chapter[`
- `${collection.artworkIds.length} artworks`
- `${commission.status.displayName} • \$${commission.totalPrice.toStringAsFixed(2)}`
- `${distance.toInt()}m`
- `${entry.experiencePoints} total XP`
- `${entry.key}: ${entry.value}`
- `${entry.value} purchase${entry.value > 1 ?`
- `${event.attendeeIds.length} attending`
- `${event.attendeeIds.length}/${event.maxAttendees}`
- `${featured.length} of 3 selected`
- `${filteredDocs.length} items`
- `${follower.engagementScore} pts`
- `${goal.currentCount} / ${goal.targetCount}`
- `${intl.DateFormat(`
- `${intl.DateFormat.yMMMd().format(event.dateTime)} • ${event.location}`
- `${item[`
- `${levelRange[`
- `${metadata.estimatedReadMinutes!} minutes`
- `${metadata.wordCount!} words`
- `${mission.current}/${mission.target}`
- `${reactions.length} ${reactions.length == 1 ?`
- `${refundTransactions.length} Refunds`
- `${requestType.toUpperCase()} • $status${isOverdue ?`
- `${requirement[`
- `${selectedTransactions.length} transactions selected`
- `${server[`
- `${studio.memberList.length} members`
- `${ticket.remainingQuantity} ${`
- `${tier.displayName} - \$${tier.monthlyPrice}/month`
- `${transaction.fromUserName} • ${_formatDate(transaction.timestamp)}`
- `${transaction.userName} • ${transaction.displayType}`
- `${user.xp} XP / ${user.nextLevelXp} XP`
- `${walk.estimatedDistance!.toStringAsFixed(1)}mi`
- `${walk.estimatedDuration!.round()}m`
- `${walkPost.artworkPhotos.length} artwork photos`
- `${widget.amount.toStringAsFixed(2)} ${widget.currency}`
- `${widget.nearbyArt.length} artworks nearby`
- `${widget.nearbyArt.length} nearby`
- `${widget.paymentId.substring(0, 10)}...`
- `${widget.radiusMeters.toInt()}m`
- `${widget.ticketType.remainingQuantity} ${`
- `${widget.user.experiencePoints} ${`
- `${widget.visitedCount}/${widget.totalCount}`
- `${widget.weeklyProgress}/${widget.weeklyGoal}`
- `${work.writingMetadata!.wordCount} words`
- `+ ${features.length - preview.length} more benefits`
- `+$xpReward XP`
- `+${_formatCurrency(value)}`
- `+${_selectedArtPieces.length - 3}`
- `+${goal.rewardXP} XP`
- `+${images.length - 4}`
- `+${mission.xpReward} XP`
- `+${quest.xpReward} XP`
- `+${tier[`
- `+\$${transaction.amount.toStringAsFixed(2)}`
- `-${((discountAmount / originalPrice) * 100).round()}%`
- `1 hour ago`
- `123 Main St, City, State ZIP`
- `15-second welcome video\n(Coming soon)`
- `3/8 art pieces visited`
- `30 minutes ago`
- `@$handle`
- `@$username`
- `@${artist.username}`
- `@${post.authorUsername}`
- `@${user.username!}`
- `@${user.username}`
- `A comprehensive feedback collection and management system designed to improve ARTbeat through user insights and bug reports.`
- `AI RECOMMENDED`
- `ARTbeat`
- `ARTbeat Event`
- `ARTbeat Feedback System`
- `ARTbeat Privacy Policy`
- `ARTbeat Social Engagement System`
- `ARTbeat Terms of Service`
- `ARTbeat is recommended for ages 18 and older because some content may include artistic nudity or mature artistic subject matter. Users under 18 may have messaging, location sharing, public discovery, and event features restricted.`
- `About this Story`
- `Accessible Only`
- `Account Holder Name`
- `Account Number`
- `Account Type`
- `Achievement Collection`
- `Achievements`
- `Actions`
- `Active`
- `Active Power-Ups`
- `Active Quests`
- `Active Streaks`
- `Activity`
- `Activity Health`
- `Activity History`
- `Activity Snapshot`
- `Add`
- `Add $label`
- `Add Capture`
- `Add a comment...`
- `Add a tag`
- `Add tags to help others find your studio`
- `Add your artist headshot`
- `Added on ${_formatDate(createdAt)}`
- `Additional charges this month: \$${_overageCost.toStringAsFixed(2)}`
- `Additional details (optional)`
- `Additional theme options will be available in future updates.`
- `Admin Access Control`
- `Admin Command Center`
- `Admin Control Center`
- `Admin Menu`
- `Admin Upload Tools`
- `Admin user management is handled in the User Management section.`
- `Admin: ${log.userId}`
- `Advanced Search & Filters`
- `After you submit, Apple checkout opens. Approved ads then publish into the placement you selected.`
- `All`
- `All Artists`
- `All Artworks (tap to select/deselect):`
- `All Comments (${_comments.length})`
- `All IAP services initialized and ready.`
- `All statuses`
- `Allow others to see and register for this event`
- `Always require biometric for large amounts`
- `Amount (\$)`
- `Amount Range`
- `Analytics`
- `Analytics & Insights`
- `Announcement broadcasted successfully`
- `Announcements`
- `Anonymous posts fix completed! Check logs for details.`
- `Anyone can find and join this studio`
- `Apply`
- `Approaching limit`
- `Are you sure you want to ${approve ?`
- `Are you sure you want to abandon this walk? All progress will be lost and cannot be recovered.`
- `Are you sure you want to cancel the invitation to ${invitation.artistName}?`
- `Are you sure you want to clear all chat history? This action cannot be undone.`
- `Are you sure you want to create a backup of the database?`
- `Are you sure you want to delete the account "${account.displayName}"?`
- `Are you sure you want to delete the coupon "${coupon.title}"? This action cannot be undone.`
- `Are you sure you want to delete this event?`
- `Are you sure you want to delete this post? This action cannot be undone.`
- `Are you sure you want to delete this studio? This action cannot be undone.`
- `Are you sure you want to permanently delete "${walk.title}"? This action cannot be undone.`
- `Are you sure you want to process refunds for all selected transactions?`
- `Are you sure you want to remove this from your favorites?`
- `Are you sure you want to report this comment for inappropriate content?`
- `Are you sure you want to reset all settings to default values?`
- `Are you sure you want to sign out?`
- `Are you sure you want to unblock ${user.displayName}? They will be able to message you again.`
- `Art Enthusiast`
- `Art Mediums`
- `Art Show`
- `Art Walk to Riverfront`
- `Art walk celebration data missing`
- `ArtBeat`
- `Artist`
- `Artist Ad Space`
- `Artist Boosts`
- `Artist Display Name: ${unifiedData!.artistProfile!.displayName}`
- `Artist ID: ${payout[`
- `Artist Types`
- `Artist headshot as seen in app (CircleAvatar). Tap to change.`
- `Artist not found`
- `Artist profile not found`
- `Artists`
- `Artists Online`
- `Artists are working on amazing pieces. Check back soon!`
- `Artists available for commission`
- `Artwork Details`
- `Artwork Menu`
- `Artwork not found`
- `Artworks`
- `Auction Hub`
- `Audio`
- `Authentication Required`
- `Auto-renew: ${_subscription!.autoRenew ?`
- `Available placements: Community feed, Artists and artwork, and Events.`
- `Backup Management`
- `Backup creation coming soon`
- `Backup restoration coming soon`
- `Backup viewer coming soon`
- `Badges`
- `Bank Name`
- `Basic Information`
- `Be the first to create a group!`
- `Be the first to discover and share amazing local art!`
- `Be the first to earn points in this category`
- `Be the first to share your creative work and connect with the community.`
- `Be the first to start a conversation!`
- `Begin exploring art walks to earn your first achievements!`
- `Bio`
- `Biometric Payment Settings`
- `Blocked IP Addresses`
- `Blocked on ${_formatBlockedDate(user.blockedAt ?? DateTime.now())}`
- `Blocked users not available`
- `Books & Stories`
- `Boost your next drop with premium placement across Local ArtBeat.`
- `Brief description of the coupon`
- `Broadcast to All Users`
- `Browse`
- `Browse local ads`
- `Business address`
- `By continuing, you agree to recurring billing for the selected`
- `By subscribing, you agree to our Terms of Service and Privacy Policy.`
- `By: ${comment.userName}`
- `By: ${item.authorName}`
- `By: ${post.authorName}`
- `CLOSE!`
- `Cancel`
- `Cancelled`
- `Capabilities`
- `Capture Menu`
- `Capture Preferences`
- `Capture Sponsor`
- `Captured 2 hours ago`
- `Captures`
- `Career Earnings`
- `Category`
- `Category:`
- `Central hub for all administration`
- `Change Password`
- `Changes to these settings will apply to all your chats.`
- `Chapter $chapterNumber is locked`
- `Chapter ${_currentChapter!.episodeNumber ?? _currentChapter!.chapterNumber}`
- `Chapter ${nextChapter.episodeNumber ?? nextChapter.chapterNumber}: ${nextChapter.title}`
- `Chapters`
- `Check back later to see who\'s active`
- `Check back soon for art events!`
- `Check back soon for featured artists!`
- `Check back soon for featured artwork!`
- `Check debug console for details`
- `Checking verification…`
- `Choose a boost tier to power up this artist.`
- `Choose a chapter to see curated art, quests, and events for that area.`
- `Choose a reaction`
- `Choose an artist for your commission`
- `Choose an emoji`
- `Choose from Gallery`
- `Clear`
- `Clear ${walk.reportCount} report(s) from "${walk.title}"?`
- `Clear All`
- `Clear History`
- `Clear Output`
- `Coming Soon`
- `Coming Soon - Artist Feature`
- `Coming Soon - Gallery Feature`
- `Comment System Demo`
- `Comment added successfully!`
- `Comment posted successfully! 💬`
- `Comment reported successfully`
- `Comments`
- `Comments (${_flaggedComments.length})`
- `Community Member`
- `Compare All Tiers`
- `Comparison table coming soon...\n\nFor now, explore each tier using the tabs above.`
- `Complete`
- `Completed`
- `Completed! 🎉`
- `Completing early means:`
- `Confirm Broadcast`
- `Confirm Payment`
- `Confirm with Biometric`
- `Connect`
- `Connect with local art explorers`
- `Consolidated data management`
- `Contact Information`
- `Content`
- `Content (${_filteredContent.length})`
- `Content moderation failed: ${moderationResult.reason}`
- `Core`
- `Could not open URL: $sourceUrl`
- `Coupon ${newStatus == CouponStatus.active ?`
- `Coupon Code`
- `Coupon Type`
- `Create`
- `Create Artist Profile`
- `Create Backup`
- `Create First Group`
- `Create New Group`
- `Create Post`
- `Create Profile`
- `Create Studio`
- `Create a banner or inline ad request for your business, or browse active local promotions already running in the app.`
- `Create a simple local ad that helps fund artists and keeps your business visible in the Artbeat community.`
- `Create your first code to unlock promo drops, trials, and VIP access.`
- `Create your first group to connect with other artists`
- `Creating unique pieces that blend traditional and digital techniques.`
- `Curated highlights from our community`
- `Current Artists`
- `Current Bid`
- `Current request status: $status`
- `Custom`
- `Custom Navigation Example`
- `DEBUG: Image URLs (${widget.post.imageUrls.length}):`
- `Daily`
- `Danger Zone`
- `Data Rights Requests`
- `Date & Time`
- `Date Range`
- `Date: ${intl.DateFormat(`
- `Debug Information`
- `Debug Information:`
- `Debug Tools`
- `Debug: Loaded ${comments.length} comments for post ${widget.post.id}`
- `Delete`
- `Delete Account`
- `Delete Account?`
- `Delete Event`
- `Delete Post`
- `Delete Studio`
- `Delete post`
- `Deleted "${artwork.title}" successfully`
- `Denied`
- `Describe your group`
- `Describe your studio and its purpose`
- `Description`
- `Description (optional)`
- `Details`
- `Details:`
- `Deutsch`
- `Developer Feedback Admin`
- `Developer Menu`
- `Developer tools will be available in a future update.`
- `Difficulty`
- `Discover Events`
- `Dismiss Flag`
- `Display Name`
- `Distance (miles)`
- `Downtown Public Art Tour`
- `Draft`
- `Drawer not found. Scaffold: ${scaffoldState != null}, hasDrawer: ${scaffoldState?.hasDrawer ?? false}`
- `Duration`
- `Duration (minutes)`
- `Duration Guidelines`
- `Earn XP through art walks, captures, reviews, and community contributions. Level up to unlock exclusive perks and become an Art Walk Influencer!`
- `Earned on ${ach.earnedAt.toString().split(`
- `Edit`
- `Edit Message`
- `Edit post`
- `Effective Date: ${LegalConfig.effectiveDate}`
- `Email`
- `Email: ${unifiedData!.userModel.email}`
- `Enable`
- `Enable Artist Features`
- `Enable Biometric Payments`
- `Engagement Unlock`
- `English`
- `Enter announcement message...`
- `Enter artist name`
- `Enter coupon code`
- `Enter feed name`
- `Enter group name`
- `Enter studio name`
- `Enter the amount you want to withdraw`
- `Enter your broadcast message...`
- `Enter your message...`
- `Enter zip code or city`
- `Error`
- `Error ${widget.artWalkId != null ?`
- `Error Loading Artwork`
- `Error adding comment: $e`
- `Error creating chat: $e`
- `Error creating chat: ${e.toString()}`
- `Error creating studio: $e`
- `Error deleting artwork: ${e.toString()}`
- `Error deleting event: $e`
- `Error deleting post`
- `Error deleting studio: $e`
- `Error dismissing flag: $e`
- `Error fixing posts: $e`
- `Error initializing app`
- `Error loading analytics: $error`
- `Error loading analytics: \$e`
- `Error loading artists: $e`
- `Error loading artwork`
- `Error loading capture`
- `Error loading captures`
- `Error loading chats`
- `Error loading community captures`
- `Error loading connections: $e`
- `Error loading events`
- `Error loading favorite: ${e.toString()}`
- `Error loading galleries: ${snapshot.error}`
- `Error loading groups`
- `Error loading messages`
- `Error loading more posts: $e`
- `Error loading online users`
- `Error loading payouts: ${snapshot.error}`
- `Error loading posts: $e`
- `Error loading queue: $e`
- `Error loading settings`
- `Error loading starred messages`
- `Error loading studio: $e`
- `Error loading users`
- `Error marking as read: $e`
- `Error processing payout: $e`
- `Error rejecting payout: $e`
- `Error removing favorite: ${e.toString()}`
- `Error removing member: $e`
- `Error reporting comment: $e`
- `Error reviewing event: $e`
- `Error searching artists: $e`
- `Error searching chats`
- `Error signing out: $e`
- `Error: $e`
- `Error: ${e.toString()}`
- `Error: ${error.toString()}`
- `Error: ${snapshot.error}`
- `Español`
- `Estimated Read Time`
- `Etsy Shop`
- `Event Capacity`
- `Event Creation`
- `Event Settings`
- `Event Tags`
- `Event Title`
- `Event banner as seen in hero section (Rounded 28). Tap to change.`
- `Events`
- `Events Coming Soon`
- `Example: If starting price is ${_formatCurrency(_defaultStartingPrice)}, reserve would be ${_formatCurrency(_defaultStartingPrice * _defaultReservePricePercent / 100)}`
- `Excerpt`
- `Exhibition`
- `Explore All`
- `Explore different engagement options for various content types`
- `FOR ARTISTS`
- `FREE ACCESS`
- `Facebook`
- `Failed`
- `Failed tests may indicate features that need attention:`
- `Failed to add comment`
- `Failed to add comment. Please try again.`
- `Failed to complete onboarding: $e`
- `Failed to create coupon: $e`
- `Failed to create group. Please try again.`
- `Failed to delete account: $e`
- `Failed to delete coupon: $e`
- `Failed to delete post`
- `Failed to load comments: $e`
- `Failed to load comments: ${e.toString()}`
- `Failed to load image`
- `Failed to navigate to: $routeName`
- `Failed to pick image: $e`
- `Failed to pick images: $e`
- `Failed to post comment: ${e.toString()}`
- `Failed to process payout`
- `Failed to process subscription: $e`
- `Failed to share location: ${e.toString()}`
- `Failed to share: $e`
- `Failed to start boost purchase. Please check:\n`
- `Failed to take photo: $e`
- `Failed to update coupon: $e`
- `Failed to update request: $e`
- `Favorite not found`
- `Favorites not available`
- `Featured`
- `Featured Content`
- `Featured Order (tap arrows to reorder):`
- `Featured Post ${index + 1}`
- `Featured Posts`
- `Featured art gets 3x more views from collectors`
- `Feedback System`
- `Filters`
- `Find conversations and contacts`
- `Find events, venues, and organizers`
- `Finding nearby art...`
- `Fix Anonymous Post Authors`
- `Fix Izzy Count`
- `Fix Posts`
- `Fix Profile Image`
- `Fixing anonymous post authors...`
- `Fixing...`
- `Followers`
- `Followers not available`
- `Following`
- `Following coming soon`
- `Following not available`
- `For Sale`
- `For security, please sign out and sign back in before deleting your account.`
- `Forward Message`
- `Forward to ${_selectedChats.length} chat${_selectedChats.length == 1 ?`
- `Forwarded`
- `Found this incredible mural while exploring the arts district. The colors and detail are absolutely stunning!`
- `Français`
- `Free`
- `Fulfilled`
- `Gallery Visibility Hub`
- `Gallery Visitors`
- `Genre`
- `Get Recommendations`
- `Getting Started`
- `Global Creator Leaderboard`
- `Go Back`
- `Go to Dashboard`
- `Great start! Profiles with 3+ artworks get 5x more engagement`
- `Group Name`
- `Group created successfully!`
- `Group name`
- `Groups`
- `HALL OF LEGENDS`
- `HIT NEXT TO UNLOCK:`
- `Have a coupon code?`
- `Help people connect with your artistic journey`
- `High-Value Threshold`
- `I'm Here to Discover Art`
- `IP $ip blocked successfully`
- `IP $ipAddress unblocked successfully`
- `IP Address`
- `If bids don\'t reach this price, you won\'t be obligated to sell`
- `Image not available`
- `Image not found`
- `Impact Preview`
- `In Review`
- `In the next 2 minutes, we\'ll help you unlock a professional gallery experience tailored to your craft.`
- `In-App Purchase Demo`
- `Inactive`
- `Included with ${(_selectedPlanName ?? "this plan")}:`
- `Initialization Error`
- `Initializing ARTbeat...`
- `Instagram`
- `Instant Discovery`
- `Instant Discovery Radar`
- `Integration Example`
- `Interactive Comment System`
- `Invited ${_formatDate(invitation.createdAt)}`
- `Is Artist: ${unifiedData!.artistProfile != null}`
- `Item ${approve ?`
- `Izzy Piel`
- `Join Local ARTbeat`
- `Join Studio`
- `Join communities and share your art`
- `Join groups to connect with the art community`
- `Keep this QR code safe and present it at the event entrance. Screenshots are acceptable.`
- `LEVEL $level`
- `LEVEL ${entry.level}`
- `LOADING…`
- `Last Updated: ${LegalConfig.lastUpdatedDate}`
- `Last processing error: $errorMessage`
- `Last seen: ${_formatLastSeen(_participants.first.lastSeen)}`
- `Launch a simple local ad`
- `Learn about the feedback system`
- `Leave`
- `Leave empty for unlimited uses`
- `Legal Center`
- `Let\'s set up your profile to get started`
- `Level $currentLevel: ${levelInfo[`
- `Level $level`
- `Level $xpLevel`
- `Level ${entry.level} • ${_progressionService.getLevelTitle(entry.level)}`
- `Level ${user.level}`
- `Level ${userData.level}`
- `Level Progress`
- `Lifetime uses · $totalUses`
- `Liked content not available`
- `Loading ARTbeat...`
- `Loading artist feed...`
- `Loading conversations...`
- `Loading image...`
- `Loading messages...`
- `Loading your artist feed...`
- `Loading your artistic journey...`
- `Loading...`
- `Local Ads`
- `Local Artwork`
- `Location`
- `Location: ${artwork.location}`
- `Locations`
- `Long press on any message and tap the star icon to add it here`
- `March 15-30, 2024 • Downtown Gallery`
- `Mark as read`
- `Max`
- `Max Uploads: ${capabilities!.maxArtworkUploads == -1 ? "Unlimited" : capabilities!.maxArtworkUploads}`
- `Maximum Uses (optional)`
- `Maybe Later`
- `Medium`
- `Medium: ${artwork.medium}`
- `Member removed successfully`
- `Members`
- `Message`
- `Message forwarded to ${selectedChats.length} chat${selectedChats.length == 1 ?`
- `Messages`
- `Messaging Dashboard`
- `Messaging Menu`
- `Messaging Profile`
- `Metadata:`
- `Metadata: ${log.metadata.toString()}`
- `Min`
- `Minimal Screen`
- `Minimal Screen Content`
- `Moderation Notes (optional)`
- `Momentum +${boost.momentumAmount}`
- `Momentum Meter`
- `Monthly`
- `Monthly ad subscriptions are paid through Apple, then reviewed before they go live.`
- `Most popular`
- `Mutuals`
- `My Gallery Hub`
- `My Profile`
- `NEXT CHAPTER`
- `Name: ${unifiedData!.userModel.fullName}`
- `Navigation Error`
- `Navigation error: ${e.toString()}`
- `Need More?`
- `Needs creative`
- `Network Connection Lost`
- `New`
- `New Auction`
- `Next appearance`
- `Next scan: ${timeRemaining.toStringAsFixed(1)}s`
- `Next: ${nextLevelInfo[`
- `No ${title.toLowerCase()} available`
- `No Analytics Data`
- `No Artwork Yet`
- `No Chapter Selected`
- `No Group Chats`
- `No Refunds`
- `No active chapters found nearby.`
- `No active quests for this chapter.`
- `No additional perks at the next level.`
- `No analytics data`
- `No approved events`
- `No art nearby`
- `No art walks found`
- `No artists found`
- `No artists match that search yet`
- `No artists online right now`
- `No artwork available`
- `No artwork found`
- `No artwork found in your area`
- `No artworks available`
- `No artworks yet`
- `No audit logs found`
- `No audit logs found matching criteria.`
- `No blocked users`
- `No capabilities data available`
- `No captures found`
- `No captures yet`
- `No chapters released yet.`
- `No chats found`
- `No comments yet. Be the first to comment!`
- `No commission artists available right now.`
- `No community posts yet`
- `No content currently requires moderation.`
- `No contributors yet`
- `No conversations yet`
- `No coupons yet`
- `No data available`
- `No engagement metrics yet`
- `No events were found for this period. Create or publish events to see event-level analytics.`
- `No featured artists`
- `No featured artists yet`
- `No featured artworks`
- `No featured content available`
- `No flagged comments`
- `No flagged events`
- `No flagged posts`
- `No groups created yet`
- `No groups found`
- `No groups joined yet`
- `No help topics match your search yet.`
- `No internet connection`
- `No legends yet...`
- `No local artists found in $zipCode`
- `No matching data-rights requests.`
- `No messages yet`
- `No one is online right now`
- `No payment methods added`
- `No pending events`
- `No pending payouts`
- `No perks unlocked at this level yet.`
- `No posts yet`
- `No recent broadcasts`
- `No recent posts available`
- `No requests submitted yet`
- `No results for "${widget.searchQuery}"`
- `No sponsorships in this review state.`
- `No starred messages`
- `No tests run yet`
- `No ticket types added yet. Add at least one ticket type.`
- `No trend data available`
- `No upcoming events`
- `No user data available`
- `No users found`
- `Number of Art Pieces`
- `Onboarding reset! Refresh dashboard to see the tour.`
- `Onboarding reset! Refresh to see tours.`
- `Once you delete this studio, there is no going back. Please be certain.`
- `Ongoing`
- `Online`
- `Online (${filteredOnlineUsers.length})`
- `Online Users (${users.length})`
- `Online now`
- `Only continue if staging/manual validation for this case is complete and you intend to fulfill the legal deletion request now.`
- `Only invited members can join`
- `Opening artwork details...`
- `Opening boost purchase screen...`
- `Optimized for your visibility goals.`
- `Optional notes for audit trail`
- `Original Message`
- `Original: \$${_couponResult![`
- `Other`
- `Over limit - overage charges apply`
- `Overage Charges`
- `Overview`
- `Overview Interest`
- `Page Not Found`
- `Password`
- `Payment Debug`
- `Payment Methods`
- `Payment successful!`
- `Payout Request - \$${payout[`
- `Payout processed successfully`
- `Payout rejected`
- `Payout request submitted successfully! You will receive \$${amount.toStringAsFixed(2)} in 1-3 business days.`
- `Payouts`
- `Pending`
- `Pending Invitations`
- `Pending review (${pendingAds.length})`
- `Performance Summary`
- `Perks`
- `Photos get 2x more profile views`
- `Plan Features`
- `Platform Curation`
- `Please check your internet connection and try again.`
- `Please enter a message`
- `Please log in to create a post`
- `Please log in to edit your profile`
- `Please log in to view your captures`
- `Please log in to view your profile`
- `Please provide any additional information about your refund request`
- `Please sign in to access this feature`
- `Please sign in to create a group`
- `Please sign in to view achievements`
- `Please sign in to view your rewards`
- `Please try again later`
- `Popular Routes`
- `Portfolio piece only`
- `Português`
- `Post deleted successfully`
- `Post shared successfully!`
- `Post tapped!`
- `Posted: ${artwork.createdAt}`
- `Postponed`
- `Posts`
- `Posts (${_flaggedPosts.length})`
- `Power Up Artists with Boosts`
- `Pricing`
- `Privacy Settings`
- `Private`
- `Pro Tip`
- `Process`
- `Process Refund`
- `Processed: ${_formatDate(payout.processedAt!)}`
- `Profile Images`
- `Profile Journey`
- `Profile edit not available`
- `Profile not available`
- `Provide more context about why you\'re reporting this ad...`
- `Public`
- `Pull to refresh`
- `Purchase Manager Available: ${_purchaseManager.isAvailable}`
- `Purchase failed: $errorMessage`
- `Queue is clear!`
- `Radar screen goes here`
- `Ratings`
- `Re-authentication Required`
- `Read More`
- `Ready to Start Your Journey?`
- `Ready to save! You can change these settings anytime from your artist dashboard.`
- `Reason`
- `Reason for rejection`
- `Reason for rejection (optional)`
- `Reason for reporting (optional)`
- `Reason: ${flag[`
- `Reason: ${payout.failureReason}`
- `Recent Achievements`
- `Recent Activity`
- `Recent Badges`
- `Recent Chats`
- `Recent Posts`
- `Recent Requests`
- `Recommended Actions`
- `Recurring Event`
- `Refresh Data`
- `Refresh Status`
- `Refund Policy`
- `Refund management coming soon`
- `Refunds`
- `Reject Payout`
- `Remove`
- `Remove Favorite`
- `Remove Photo`
- `Removed from favorites`
- `Repeat Pattern`
- `Reply to thread...`
- `Replying to`
- `Replying to message`
- `Report`
- `Report Comment`
- `Request set to $status.`
- `Requested: ${_formatDate(payout.requestedAt)}`
- `Requests appear here once submitted.`
- `Require for High-Value Payments`
- `Requirement:`
- `Reserve Spotlight`
- `Reserve prices are hidden from bidders. They only see if the reserve has been met.`
- `Reserve: \$${auction.reservePrice!.toStringAsFixed(2)}`
- `Reset Onboarding`
- `Restore Backup`
- `Retry`
- `Revenue Breakdown`
- `Review Your Settings`
- `Review notes`
- `Rewards & Achievements`
- `Role`
- `Route Details`
- `Route not found`
- `Routing Number`
- `Run Deletion Pipeline`
- `Run deletion`
- `SCAVENGE • CAPTURE • QUEST`
- `STEP ${_currentStepIndex + 1} OF ${_steps.length}`
- `Sale`
- `Save`
- `Save Settings`
- `Save \$${savings.toStringAsFixed(0)}`
- `Saved`
- `Saving...`
- `Scan for Entry`
- `Screen Content`
- `Screen Navigation & Tools`
- `Search`
- `Search Events`
- `Search Messages`
- `Search ads...`
- `Search artists by name...`
- `Search artists...`
- `Search by name or location`
- `Search by name, username, or zip code`
- `Search by name, username, or zip code...`
- `Search by title, description, tags...`
- `Search chats...`
- `Search emojis...`
- `Search for art pieces...`
- `Search in: Title, Description, Tags, Difficulty, Location`
- `Search logs...`
- `Search messages...`
- `Search people...`
- `Search studios...`
- `Search transactions...`
- `Search verified artists...`
- `See All`
- `Select Account`
- `Select Artist`
- `Select Emoji`
- `Select Subscription Tier`
- `Select Your ARTbeat`
- `Select a subscription tier and run tests to verify artist features`
- `Select conversations:`
- `Selected Plan`
- `Send`
- `Send Boost`
- `Send a Boost`
- `Send an Artist Boost`
- `Send power-ups to artists to boost their visibility and earn XP.`
- `Sent on: ${_formatTimestamp(data[`
- `Set Denied`
- `Set In Review`
- `Set Pending`
- `Set up your auction preferences to start selling your artworks through exciting time-limited bidding.`
- `Setting up your artist profile...`
- `Settings`
- `Severity: ${event.severity}`
- `Share My Profile`
- `Share your thoughts about this artwork...`
- `Shorter durations create urgency, while longer durations give more people time to discover and bid.`
- `Show All Features`
- `Show Less`
- `Show all tours on next refresh`
- `Show dashboard tour on next refresh`
- `Showing ${title.toLowerCase()} in this chapter...`
- `Showing data for: ${_selectedTimeRange ==`
- `Sign In`
- `Sign Out`
- `Sign in to unlock all features:`
- `Sign in to view request status`
- `Skip`
- `Smart replies`
- `Social`
- `Social Engagement Demo`
- `Something went wrong`
- `Sort By`
- `Sort:`
- `Source`
- `Sponsor link is not available right now.`
- `Sponsor this space`
- `Sponsorship submitted. Payment is on file and the request is now queued for review.`
- `Standard (24 hours)`
- `Start New Conversation`
- `Start a conversation with artists and art enthusiasts`
- `Start a conversation with fellow artists and connect with the creative community`
- `Start a group chat to collaborate with artists`
- `Start capturing to showcase your art trail.`
- `Start the conversation by sending a message below`
- `Start typing to search for people...`
- `Stats`
- `Status`
- `Status: $status\nRequested: $requestedAtLabel`
- `Status: ${user.isSuspended ?`
- `Stay tuned for more chapters coming soon.`
- `Step ${_currentStep + 1} of $_totalSteps`
- `Stop chasing algorithms. Start building your legacy.`
- `Storage`
- `Storage details coming soon`
- `Streak Calendar`
- `Streak: $_streakCount`
- `Studio Name`
- `Studio created successfully!`
- `Studio deleted successfully`
- `Studio not found`
- `Submit Feedback`
- `Submit local ad`
- `Subscribe`
- `Subscribe Now - ${_getPriceString(widget.tier)}`
- `Subscription Plans`
- `Subscriptions`
- `Suggestions`
- `Support local art with local business ads`
- `Suspicious activity`
- `Syncing coupons...`
- `Syncing leaderboards...`
- `System Info`
- `System Info - Coming Soon`
- `System Settings`
- `TOP 25 ARTBEAT EXPLORERS`
- `Tags`
- `Take Photo`
- `Tap the comment icon below to expand the comment section. You can:`
- `Tap to add profile photo (optional)`
- `Tap to retry`
- `Technical Implementation`
- `Test Add Payment Method`
- `Test Image ${index + 1}`
- `Test Stripe Initialization`
- `Test Summary for ${_selectedTier?.toUpperCase()} tier:`
- `Test the feedback form`
- `Testing SecureNetworkImage with Firebase Storage URLs`
- `The favorite you\'re looking for might have been removed.`
- `The images below should handle 403 errors gracefully with retry functionality:`
- `The initial price where bidding starts. Should be set strategically to attract bidders.`
- `The minimum amount each new bid must exceed the current highest bid.`
- `These ads have been submitted and paid, but they are not visible in the live app until they are approved.`
- `These are your default auction settings. You can adjust them for individual artworks later.`
- `This artwork is for sale`
- `This demo showcases the engagement options available for each content type in the ARTbeat platform.`
- `This feature is under development.`
- `This is such an inspiring piece! I love how you\'ve used color to convey emotion. The technique reminds me of some of the great impressionist masters.`
- `This message was previously edited`
- `This permanently deletes your account access. Most user-facing`
- `This will be sent to all active users`
- `This will run the account deletion pipeline for user `$userId`.`
- `This will send a notification to ALL active users. Are you sure?`
- `This will update all posts that currently show "Anonymous" as the author name`
- `Ticket ID: ${_formatTicketId(ticket.id)}`
- `Ticket Types`
- `Time: ${_formatDate(log.timestamp)}`
- `Time: ${_formatTimestamp(activity.createdAt)}`
- `Timestamp: ${intl.DateFormat(`
- `Title`
- `To use biometric payments, your device must support fingerprint or face recognition.`
- `Today: $_todayDiscoveries`
- `Today\'s Challenge`
- `Tools`
- `Top Contributors`
- `Top Locations`
- `Top Referral Sources`
- `Total amount: \$${selectedTransactions.fold(0.0, (sum, t) => sum + t.amount).toStringAsFixed(2)}`
- `Total: \$${refundTransactions.fold(0.0, (sum, t) => sum + t.amount).toStringAsFixed(2)}`
- `Transaction Type`
- `Transactions`
- `Transactions (${_filteredTransactions.length})`
- `Trend Summary`
- `Trending Post ${index + 1}`
- `Trending Posts`
- `Try Again`
- `Try another name or browse the full collection.`
- `Try moving to a different location`
- `Try searching with a different name, username, or zip code`
- `Twitter`
- `Type a message...`
- `Type an artist name to find their work`
- `Type: ${content.type} • Status: ${content.status}`
- `URL: ${testUrls[index].length > 60 ?`
- `Unable to connect to the server. Please check your connection and try again.`
- `Unable to load artist feed`
- `Unable to load artists`
- `Unable to load artwork`
- `Unable to load capabilities`
- `Unable to load captures`
- `Unable to load community posts`
- `Unable to load events`
- `Unable to load user profile`
- `Unable to open sponsor link.`
- `Unified Admin & Dev Tools`
- `Unified Admin Dashboard`
- `Unlimited`
- `Unlimited Features`
- `Unlock Chapter ${chapter.episodeNumber ?? chapter.chapterNumber}`
- `Unlock Full Book for \$${_fullBookPrice.toStringAsFixed(0)}`
- `Unlock Options`
- `Unlock at Next Level`
- `Unread`
- `Unsupported tier selected: $tier`
- `Update posts showing "Anonymous" with correct names`
- `Update profile image URL`
- `Upgrade Plan`
- `Upgrade your plan for higher limits and unlimited features`
- `Upload`
- `Upload Artwork`
- `Upload Limit`
- `Upload your first artwork to get started!`
- `Uploading images and saving your data`
- `Usage Overview`
- `Use Reserve Price by Default`
- `Use fingerprint or face ID for payments`
- `Use your artist dashboard to manage individual posts.`
- `User Information`
- `User: ${log.userId} | IP: ${log.ipAddress}`
- `User: ${transaction.userName}`
- `Users`
- `Users (${_filteredUsers.length})`
- `Users you block will appear here. They won\'t be able to message you or see your activity.`
- `Verification Code`
- `Verified Artists`
- `View All Subscription Options`
- `View Backups`
- `View Details`
- `View Report`
- `View all ${_comments.length} comments`
- `Visibility boosts, promo ads, and artist subscriptions power every rank you see here.`
- `Visibility passes, promo credits, and trials all live here.`
- `Visit Route`
- `Visual Artist`
- `Walk resumed. Let\'s continue!`
- `We sent you a welcome guide with tips for getting started`
- `Website`
- `Weekly`
- `Weekly Goals`
- `Weekly: ${effectiveWeekly.toStringAsFixed(0)} / $_weeklyMomentumCap`
- `Welcome to ARTbeat!`
- `Welcome to ArtBeat`
- `Welcome to Auctions`
- `Welcome to the ArtBeat community`
- `What\'s popular in the community`
- `Wheelchair accessible`
- `When:`
- `Where Your Art Finds Its Audience`
- `Word Count`
- `Workshop`
- `Write a comment...`
- `XP: $xp`
- `You can change anytime from settings`
- `You can change your plan anytime from settings`
- `You can enable auctions on individual artworks at any time. These settings are just your defaults.`
- `You cannot block yourself`
- `You cannot report your own post`
- `You have all available features!`
- `You have unsaved changes. Are you sure you want to leave?`
- `You must be logged in to create a studio`
- `You need to visit at least 80% of art pieces to complete early.`
- `You\'ve caught up!`
- `You\'ve successfully subscribed to the ${_getTierName(widget.tier)}!`
- `You\'ve visited ${_currentProgress!.visitedArt.length}/${_currentProgress!.totalArtCount} art pieces.`
- `Your Artist Profile is Live! 🎉`
- `Your Artist Story`
- `Your Badge Collection`
- `Your Current Perks`
- `Your Payment Methods`
- `Your Profile Summary`
- `Your Progress`
- `Your Statistics`
- `Your Studio Launch Wins`
- `Your Studio.\nWithout the Noise.`
- `Your communication preferences`
- `Your profile analytics will appear here once you start gaining activity.`
- `Your progress will be saved and you can resume this walk later.`
- `Your refund request has been submitted and will be reviewed.`
- `\$${(amount / 100).toStringAsFixed(2)} ${currency.toUpperCase()}`
- `\$${(artist[`
- `\$${(artwork.currentHighestBid ?? artwork.startingPrice ?? 0).toStringAsFixed(0)}`
- `\$${(event.price ?? 0).toStringAsFixed(0)}`
- `\$${(item[`
- `\$${(tier[`
- `\$${(totalPendingCommission + totalPaidCommission).toStringAsFixed(2)}`
- `\$${_earnings!.totalEarnings.toStringAsFixed(2)}`
- `\$${_highValueThreshold.toStringAsFixed(0)}`
- `\$${_perChapterPrice.toStringAsFixed(0)}`
- `\$${_priceController.text}`
- `\$${artwork.price!.toStringAsFixed(2)}`
- `\$${artwork.price.toStringAsFixed(0)}`
- `\$${artwork.price?.toStringAsFixed(2) ??`
- `\$${basePrice?.toStringAsFixed(2) ??`
- `\$${bid.amount.toStringAsFixed(2)}`
- `\$${boost[`
- `\$${currentBid.toStringAsFixed(0)}`
- `\$${currentBid.toStringAsFixed(2)}`
- `\$${discountedPrice.toStringAsFixed(2)}/month`
- `\$${event.amount.toStringAsFixed(2)}`
- `\$${originalPrice.toStringAsFixed(2)}`
- `\$${originalPrice.toStringAsFixed(2)}/month`
- `\$${payout.amount.toStringAsFixed(2)}`
- `\$${price.toStringAsFixed(0)}`
- `\$${totalAmount.toStringAsFixed(2)}`
- `\$${totalPaidCommission.toStringAsFixed(2)}`
- `\$${totalPendingCommission.toStringAsFixed(2)}`
- `\$${totalSalesRevenue.toStringAsFixed(2)}`
- `\$${transaction.amount.toStringAsFixed(2)}`
- `\$${widget.amount.toStringAsFixed(2)}`
- `\$${widget.availableBalance.toStringAsFixed(2)}`
- `by ${art.artistName}`
- `by ${artworkModel.artist?.displayName ??`
- `by ${capture.artistName}`
- `by ${transaction.fromUserName}`
- `by ${widget.art.artistName}`
- `e.g., SPRING20`
- `e.g., Spring Sale 20% Off`
- `~${_calculateDistance(art)}`
- `• $error`
- `• ${_formatFeatureName(e.key)}`
- `• Check the debug console for SecureNetworkImage logs\n`
- `• Expandable comment section with smooth animations\n`
- `• Failed: ${total - passed}`
- `• Passed: $passed`
- `• Success Rate: $successRate%`
- `• View existing comments\n`
- `• You won\'t get the perfect completion bonus`
- `•••• •••• •••• ${card?.last4 ??`
- `⚠️ Important`
- `✨ Features Implemented:`
- `❤️ Liked!`
- `🎨 78% of artists start with FREE and upgrade as they grow`
- `🎯 Test Controls`
- `📊 Test Results`
- `📋 Detailed Test Report`
- `📖 Written Work Details`
- `🔍 Firestore Index Required`
- `🧪 Artist Features Test`

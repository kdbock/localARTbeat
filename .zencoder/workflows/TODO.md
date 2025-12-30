refactor files to match Local ARTbeat design_guide.md

design_guide.md: /Users/kristybock/artbeat/.zencoder/workflows/design_guide.md

Translation files: assets/translations/\*.json

Screens: /lib/src/screens/

Widgets: /lib/src/widgets/

Refactoring Tasks
// Refactor the widget/screen to match Local ARTbeat design_guide.md:
// - WorldBackground + GlassCard layout
// - Typography with GoogleFonts.spaceGrotesk
// - GradientCTAButton for main actions
// - tr() localization for all text
// - add the keys to en.json
// - Touch targets ≥ 44px, spacing multiple of 8
// - Replace Material defaults with shared UI components
design_guide.md /Users/kristybock/artbeat/.zencoder/workflows/design_guide.md

Add new widgets if needed from design_guide.md

Packages:
Community screens and widgets

## Community Screens

### Main Screens

- [x] art_community_hub.dart (ArtCommunityHub - used in main router)
- [x] artist_feed_screen.dart (ArtistFeedScreen - used in art_community_hub.dart)
- [x] artist_onboarding_screen.dart (ArtistOnboardingScreen - used in art_community_hub.dart and artbeat_artist)
- [x] create_art_post_screen.dart (CreateArtPostScreen - used in unified_community_hub.dart and enhanced_community_feed_screen.dart)

### Commissions

- [x] commissions/artist_commission_settings_screen.dart (ArtistCommissionSettingsScreen - used in commission_hub_screen.dart)
- [x] commissions/artist_selection_screen.dart (ArtistSelectionScreen - used in direct_commissions_screen.dart)
- [x] commissions/commission_analytics_dashboard.dart (CommissionAnalyticsDashboard - used in commission_hub_screen.dart)
- [x] commissions/commission_analytics_screen.dart (CommissionAnalyticsScreen - not used)
- [x] commissions/commission_detail_screen.dart (CommissionDetailScreen - used in commission_hub_screen.dart and direct_commissions_screen.dart)
- [x] commissions/commission_dispute_screen.dart (CommissionDisputeScreen - used in commission_hub_screen.dart)
- [x] commissions/commission_gallery_screen.dart (CommissionGalleryScreen - used in commission_hub_screen.dart and commission_request_screen.dart)
- [x] commissions/commission_hub_screen.dart (CommissionHubScreen - used in main router)
- [x] commissions/commission_progress_tracker.dart (CommissionProgressTracker - used in commission_hub_screen.dart)
- [x] commissions/commission_rating_screen.dart (CommissionRatingScreen - used in commission_hub_screen.dart)
- [x] commissions/commission_request_screen.dart (CommissionRequestScreen - used in main router)
- [x] commissions/commission_setup_wizard_screen.dart (CommissionSetupWizardScreen - used in commission_hub_screen.dart and artbeat_artist)
- [x] commissions/commission_templates_browser.dart (CommissionTemplatesBrowser - used in commission_request_screen.dart and commission_hub_screen.dart)
- [ ] commissions/direct_commissions_screen.dart (DirectCommissionsScreen - used in main router)

### Feed

- [ ] feed/artist_community_feed_screen.dart (ArtistCommunityFeedScreen - used in artist_list_widget.dart and art_community_hub.dart)
- [ ] feed/comments_screen.dart (CommentsScreen - used in art_community_hub.dart and group_feed_widget.dart)
- [ ] feed/create_group_post_screen.dart (CreateGroupPostScreen - used in main router)
- [ ] feed/create_post_screen.dart (CreatePostScreen - used in main router)
- [ ] feed/enhanced_community_feed_screen.dart (EnhancedCommunityFeedScreen - used in community_drawer.dart)
- [ ] feed/group_feed_screen.dart (GroupFeedScreen - used in art_community_hub.dart)
- [ ] feed/social_engagement_demo_screen.dart (SocialEngagementDemoScreen - used in art_community_hub.dart)
- [ ] feed/trending_content_screen.dart (TrendingContentScreen - used in main router)

### Gifts

- [ ] gifts/gift_rules_screen.dart (GiftRulesScreen - used in gifts_screen.dart)
- [ ] gifts/gifts_screen.dart (ViewReceivedGiftsScreen - used in main router)

### Moderation

- [ ] moderation/moderation_queue_screen.dart (ModerationQueueScreen - used in main router)

### Portfolios

- [ ] portfolios/artist_portfolio_screen.dart (ArtistPortfolioScreen - not used)
- [ ] portfolios/portfolios_screen.dart (PortfoliosScreen - used in main router)

### Posts

- [ ] posts/user_posts_screen.dart (UserPostsScreen - used in art_community_hub.dart)

### Settings

- [ ] settings/quiet_mode_screen.dart (QuietModeScreen - used in main router)

### Studios

- [ ] studios/create_studio_screen.dart (CreateStudioScreen - not used)
- [ ] studios/studio_chat_screen.dart (StudioChatScreen - used in studio_discovery_screen.dart and studios_screen.dart)
- [ ] studios/studio_discovery_screen.dart (StudioDiscoveryScreen - not used)
- [ ] studios/studio_management_screen.dart (StudioManagementScreen - not used)
- [ ] studios/studios_screen.dart (StudiosScreen - used in main router)

**Note:** All items need to be refactored to implement the Local ARTbeat design_guide.md. Checked items were previously marked as "used" but all need design implementation.

## Central Theme Widgets (Add to artbeat_community/lib/widgets)

Create these reusable widgets for consistent Local ARTbeat design:

- [x] world_background.dart (AuthWorldBackground - animated blob background with vignette)
- [x] glass_card.dart (GlassCard/GlassPanel - blurred glass container)
- [x] gradient_badge.dart (GradientBadge - gradient accent badges/chips)
- [x] hud_top_bar.dart (HudTopBar - top navigation bar)
- [x] hud_button.dart (HudButton - primary/secondary CTA buttons)
- [x] glass_input_decoration.dart (GlassInputDecoration - themed text inputs)
- [x] drawer_section.dart (DrawerSection - drawer section headers)
- [x] drawer_item_pill.dart (DrawerItemPill - drawer navigation items)

## Community Widgets

- [x] activity_card.dart
- [x] applause_button.dart
- [x] art_critique_slider.dart
- [x] art_gallery_widgets.dart
- [x] artist_avatar.dart
- [x] artist_list_widget.dart
- [x] artwork_card_widget.dart
- [x] avatar_widget.dart
- [x] canvas_feed.dart
- [x] comments_modal.dart
- [x] commission_artists_browser.dart
- [x] commission_filter_dialog.dart
- [x] community_drawer.dart
- [x] community_header.dart
- [x] create_post_fab.dart
- [x] critique_card.dart
- [x] enhanced_artwork_card.dart
- [x] enhanced_post_card.dart
- [x] feedback_thread_widget.dart
- [x] fullscreen_image_viewer.dart
- [x] gift_card_widget.dart
- [x] group_feed_widget.dart
- [x] group_post_card.dart
- [x] mini_artist_card.dart
- [x] post_card.dart
- [x] post_detail_modal.dart
- [x] report_dialog.dart
- [x] widgets.dart

Local ARTbeat UI Design Guide (v1) 0) Brand + vibe

Local ARTbeat should feel like:

“quest / exploration” + “creative community”

premium, slightly futuristic, but warm and human

not flat Material default, not neon gamer UI, not corporate

Core motif: Dark world background + glass surfaces + gradient accents + bold type.

1. Color system
   Base surfaces

World background: #07060F (nearly-black purple)

Surface glass: white at 4–10% opacity over dark

Dividers/borders on glass: white at 10–18% opacity

Text on dark: white at 92% (primary), 70% (secondary), 45% (tertiary)

Accent palette (use consistently)

Teal (primary accent): #22D3EE

Green (success/positive): #34D399

Purple (brand power): #7C4DFF

Pink (energy/highlight): #FF3D8D

Yellow (reward/attention): #FFC857

Red (danger): keep standard red but don’t overuse

Gradients

Use gradients as accents, not full-screen wash (except “world background” blobs):

Primary button / badge gradient:

#7C4DFF → #22D3EE → #34D399 (top-left to bottom-right)

“World” background gradient base:

#07060F → #0A1330 → #071C18 (top-left to bottom-right)

Blob glows: use the accent colors at low alpha.

2. Typography

Use one strong font family for branded UI:

GoogleFonts.spaceGrotesk (preferred)

Weights:

900/800 for titles and key labels

700 for buttons, section labels

500/600 for body

Sizing rules:

Screen title: 18–22, weight 900

Section label: 12–13, weight 800–900, letterSpacing 0.3–0.8

Body: 13–15, weight 600–700

Helper text: 12–13, weight 600, alpha ~0.6–0.7

Avoid thin weights. Avoid default Roboto look.

3. Layout rules
   Spacing

Outer padding: 14–18

Card padding: 14–18

Vertical rhythm: multiples of 8

Corners

Primary surfaces/cards: 24–28 radius

Small chips/buttons: 16–20 radius

Icon buttons: circle or 20–24 radius

Shadows

Keep subtle + soft:

Big card shadow: black at 40–50% alpha, blur 24–34, y offset 14–18

Accent glow shadow: teal/purple at 8–14% alpha, blur 28–40

4. Core components (must reuse)
   4.1 World Background

Use a stack background pattern:

Solid/gradient base fill (dark)

3–5 blurred “blob” lights (teal/purple/pink/yellow/green) animated slowly (optional)

Optional: faint rings/arcs (very low alpha)

Vignette (radial gradient darkening edges) at ~0.65–0.78 alpha

Rules:

Blobs should never block content readability.

Blobs are decorative and low alpha.

4.2 Glass Card / Panel

A “glass” container should:

be clipped (ClipRRect)

use BackdropFilter blur(16–20)

have fill: white 6–10% alpha

border: white 10–14% alpha

optional: subtle accent glow shadow

4.3 Top HUD Bar

Instead of standard AppBar (when possible):

SafeArea + Row

Left: menu/back icon

Center: title

Right: search/profile icon

All icons white, title white

Use glass strip behind it only if needed for readability.

4.4 Buttons

Primary CTA:

Glass or gradient filled

48–52 height

Radius 22–26

Text weight 800–900

Optional small icon

Secondary:

Glass outline (white 14% border)

Fill white 6% alpha

Same height, slightly calmer

Destructive:

Red icon + red text, minimal gradient

4.5 Inputs

On dark:

Use glass input container

Label in white 70%

Cursor teal

Icons teal/white70

Avoid default TextField underline

5. Screen composition templates
   5.1 “Auth” screens (login/register/forgot/verify)

Background: world + vignette

Center: constrained width 420–520

Main content in glass card

Top: badge icon (gradient square/circle)

Title + subtitle

Form fields

Primary CTA

Secondary actions as outlined or text buttons

5.2 “Dashboard” screens

Background can be lighter OR still world, but keep branding consistent.

Use cards with strong visual hierarchy:

hero card

stats row (2 cards)

horizontal carousels

fewer words, more “modules”

5.3 “Map” screens

Critical rule:

Do not paint or darken over the map tiles.

No full-screen overlay above the map other than HUD elements positioned around edges.

Allowed:

Top HUD bar

Floating search field

Floating buttons

Bottom tray

If readability needs help, put glass panels behind the controls only.

6. Drawer design (Local ARTbeat standard)

Drawer should match the dark/glass theme:

Background: very dark #07060F (or near)

Content sits on glass sections

Header:

user avatar (glow ring optional)

display name + email

small role/feature badge chip

Section headers:

uppercase, small (12), white 55%

Items:

“pill row” style instead of default ListTile:

glass row with icon chip + label

selected state: teal accent + slightly brighter fill

Dividers:

use hairline with white 10% alpha or spacing blocks (prefer spacing)

Sign out:

red accent, last item

Navigation behavior:

close drawer, delay 200–250ms, then navigate

use pushReplacement only for truly top-level routes

7. Motion / animation (subtle)

Use slow looping background motion (9–12s)

Fade/slide intro for HUD elements (300–800ms)

Avoid bouncy overscroll everywhere

Keep animations optional: don’t block UI

8. Accessibility / readability rules

Ensure contrast: text on glass must be readable against blobs

Keep important text at white 85–95% alpha

Don’t use tiny fonts below 11 except badges

Touch targets ≥ 44px

9. Implementation rules (so it stays consistent across 300 screens)
   Must-do:

Create shared widgets once and reuse:

AuthWorldBackground

GlassCard

GradientBadge

HudTopBar

HudButton

GlassInputDecoration

DrawerSection, DrawerItemPill

Must-not-do:

Don’t create one-off gradients per screen.

Don’t mix bright white pages with dark world pages randomly.

Don’t use default ListTile + white drawer.

Don’t overlay a dark tint over Google Maps tiles.

“Definition of done” for a redesigned screen:

Uses world background OR uses the new card language on light background intentionally

Typography updated to Space Grotesk hierarchy

Primary CTA uses gradient/teal accent rules

Cards are glass or consistent soft cards

No default Material “basic” look

10. Quick checklist per screen (fast QA)

Background matches Local ARTbeat (world+glass or intentional light variant)

One clear primary CTA (gradient)

Space Grotesk used for titles/buttons

Cards have 24–28 radius and soft shadows

Icons match accent palette (teal/green/purple)

Navigation patterns consistent (drawer delay, root nav rules)

No unreadable text over blobs

Map screens: no full overlay on tiles

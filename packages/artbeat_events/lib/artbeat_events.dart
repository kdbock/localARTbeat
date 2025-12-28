// ARTbeat Events Package - Main Export File
// This file exports all public components of the artbeat_events package

// Models - Core data structures
export 'src/models/artbeat_event.dart';
export 'src/models/ticket_type.dart';
export 'src/models/ticket_purchase.dart';
export 'src/models/refund_policy.dart';

// Services - Business logic and integrations
export 'src/services/event_service.dart';
export 'src/services/recurring_event_service.dart';
export 'src/services/event_notification_service.dart';
export 'src/services/calendar_integration_service.dart';
export 'src/services/event_analytics_service.dart';
export 'src/services/event_analytics_service_phase3.dart';
export 'src/services/event_moderation_service.dart';
export 'src/services/event_bulk_management_service.dart';
export 'src/services/revenue_tracking_service.dart';
export 'src/services/social_integration_service.dart';

// Screens - Complete UI screens
export 'src/screens/create_event_screen.dart';
export 'src/screens/event_details_screen.dart';
export 'src/screens/event_details_wrapper.dart';
export 'src/screens/events_dashboard_screen.dart';
export 'src/screens/events_list_screen.dart';
export 'src/screens/event_search_screen.dart';
export 'src/screens/my_tickets_screen.dart';
export 'src/screens/user_events_dashboard_screen.dart';
export 'src/screens/advanced_analytics_dashboard_screen.dart';
export 'src/screens/event_moderation_dashboard_screen.dart';
export 'src/screens/event_bulk_management_screen.dart';
export 'src/screens/calendar_screen.dart';

// Widgets - Reusable UI components
export 'src/widgets/event_card.dart';
export 'src/widgets/community_feed_events_widget.dart';
export 'src/widgets/ticket_purchase_sheet.dart';
export 'src/widgets/qr_code_ticket_widget.dart';
export 'src/widgets/ticket_type_builder.dart';
export 'src/widgets/events_drawer.dart';
export 'src/widgets/events_header.dart';
export 'src/widgets/social_feed_widget.dart';

// Design system widgets
export 'src/widgets/world_background.dart';
export 'src/widgets/hud_top_bar.dart';
export 'src/widgets/glass_card.dart';
export 'src/widgets/gradient_cta_button.dart';

// Forms - Form builders and validation
export 'src/forms/event_form_builder.dart';

// Utils - Helper functions and utilities
export 'src/utils/event_utils.dart';
export 'src/utils/events_logger.dart';

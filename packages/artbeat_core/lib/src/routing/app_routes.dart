/// Centralized route constants for the ARTbeat app
class AppRoutes {
  // Core routes
  static const String splash = '/splash';
  static const String dashboard = '/dashboard';

  // Auth routes
  static const String auth = '/auth';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Profile routes
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String profileCreate = '/profile/create';
  static const String profileDeep = '/profile/deep';
  static const String profilePictureViewer = '/profile/picture-viewer';
  static const String profileMenu = '/profile/menu';
  static const String favorites = '/favorites';
  static const String favoriteDeep = '/favorite/deep';

  // Settings routes
  static const String accountSettings = '/settings/account';
  static const String notificationSettings = '/settings/notifications';
  static const String privacySettings = '/settings/privacy';
  static const String securitySettings = '/settings/security';
  static const String paymentSettings = '/settings/payment';

  // Capture routes
  static const String help = '/support';
  static const String feedback = '/feedback';

  // Events routes
  static const String allEvents = '/events/discover';
  static const String artistEvents = '/events/artist-dashboard';
  static const String myTickets = '/events/my-tickets';
  static const String createEvent = '/events/create';
  static const String myEvents = '/events/my-events';
  static const String eventDetail = '/events/detail';

  // Gallery routes
  static const String galleryCommissions = '/gallery/commissions';

  // Commission routes
  static const String commissionHub = '/commission/hub';
  static const String commissionRequest = '/commission/request';

  // Artist routes
  static const String artistDashboard = '/artist/dashboard';
  static const String artistOnboarding = '/artist/onboarding';
  static const String artistProfileEdit = '/artist/profile-edit';
  static const String artistPublicProfile = '/artist/public-profile';
  static const String artistAnalytics = '/artist/analytics';
  static const String artistApprovedAds = '/artist/approved-ads';
  static const String artistArtwork = '/artist/artwork';
  static const String artistArtworkDetail = '/artist/artwork-detail';
  static const String artistFeed = '/artist/feed';
  static const String artistSearch = '/artist/search';
  static const String artistSearchShort = '/artist-search';
  static const String artistBrowse = '/artist/browse';
  static const String artistFeatured = '/artist/featured';
  static const String artistEarnings = '/artist/earnings';
  static const String artistPayoutRequest = '/artist/payout-request';
  static const String artistPayoutAccounts = '/artist/payout-accounts';

  // Artwork routes
  static const String artworkUpload = '/artwork/upload';
  static const String artworkUploadChoice = '/artwork/upload/choice';
  static const String artworkUploadVisual = '/artwork/upload/visual';
  static const String artworkUploadWritten = '/artwork/upload/written';
  static const String artworkBrowse = '/artwork/browse';
  static const String artworkSearch = '/artwork/search';
  static const String artworkFeatured = '/artwork/featured';
  static const String artworkRecent = '/artwork/recent';
  static const String artworkTrending = '/artwork/trending';
  static const String artworkEdit = '/artwork/edit';
  static const String artworkDetail = '/artwork/detail';

  // Gallery routes
  static const String galleryArtistsManagement = '/gallery/artists-management';
  static const String galleryAnalytics = '/gallery/analytics';

  // Subscription routes
  static const String subscriptionComparison = '/subscription/comparison';
  static const String subscriptionPlans = '/subscription/plans';
  static const String subscriptions = '/iap/subscriptions';
  static const String gifts = '/iap/gifts';
  static const String ads = '/iap/ads';

  // Payment routes
  static const String paymentMethods = '/payment/methods';
  static const String paymentRefund = '/payment/refund';
  static const String paymentScreen = '/payment/screen';
  static const String adPayment = '/ads/payment';

  // Capture routes
  static const String captures = '/captures';
  static const String captureCamera = '/capture/camera';
  static const String captureCameraSimple = '/capture/camera/simple';
  static const String captureDetail = '/capture/detail';
  static const String captureDashboard = '/capture/dashboard';
  static const String captureSearch = '/capture/search';
  static const String captureNearby = '/capture/nearby';
  static const String capturePopular = '/capture/popular';
  static const String captureMyCaptures = '/capture/my-captures';
  static const String capturePending = '/capture/pending';
  static const String captureApproved = '/capture/approved';
  static const String captureBrowse = '/capture/browse';
  static const String captureSettings = '/capture/settings';
  static const String captureAdminModeration = '/capture/admin/moderation';
  static const String captureMap = '/capture/map';
  static const String captureGallery = '/capture/gallery';
  static const String captureEdit = '/capture/edit';
  static const String captureCreate = '/capture/create';
  static const String capturePublic = '/capture/public';
  static const String captureTerms = '/capture/terms';

  // Art Walk routes
  static const String artWalkMap = '/art-walk/map';
  static const String artWalkList = '/art-walk/list';
  static const String artWalkDetail = '/art-walk/detail';
  static const String artWalkExperience = '/art-walk/experience';
  static const String artWalkCreate = '/art-walk/create';
  static const String artWalkEdit = '/art-walk/edit';
  static const String artWalkDashboard = '/art-walk/dashboard';
  static const String artWalkMyWalks = '/art-walk/my-walks';
  static const String artWalkMyCaptures = '/art-walk/my-captures';
  static const String artWalkCompleted = '/art-walk/completed';
  static const String artWalkSaved = '/art-walk/saved';
  static const String artWalkPopular = '/art-walk/popular';
  static const String artWalkAchievements = '/art-walk/achievements';
  static const String artWalkSettings = '/art-walk/settings';
  static const String artWalkAdminModeration = '/artwalk/admin/moderation';
  static const String enhancedCreateArtWalk = '/enhanced-create-art-walk';

  @Deprecated(
    'Use artWalkExperience instead - both routes point to the same screen',
  )
  static const String enhancedArtWalkExperience = '/art-walk/experience';

  static const String artWalkExplore = '/art-walk/explore';
  static const String artWalkStart = '/art-walk/start';
  static const String artWalkNearby = '/art-walk/nearby';

  // Community routes
  static const String communityDashboard = '/community/dashboard';
  static const String communityFeed = '/community/feed';
  static const String communityArtists = '/community/artists';
  static const String communitySearch = '/community/search';
  static const String communityPostDetail = '/community/post-detail';
  static const String communityPosts = '/community/posts';
  static const String communityStudios = '/community/studios';
  static const String communityGifts = '/community/gifts';
  static const String communityPortfolios = '/community/portfolios';
  static const String communityModeration = '/community/moderation';
  static const String communitySponsorships = '/community/sponsorships';
  static const String communitySettings = '/community/settings';
  static const String communityCreate = '/community/create';
  static const String communityMessaging = '/community/messaging';
  static const String communityTrending = '/community/trending';
  static const String communityFeatured = '/community/featured';
  static const String community = '/community';
  static const String artCommunityHub = '/community/hub';

  // Events routes
  static const String events = '/events';
  static const String eventsDiscover = '/events/discover';
  static const String eventsDashboard = '/events/dashboard';
  static const String eventsArtistDashboard = '/events/artist-dashboard';
  static const String eventsDetail = '/events/detail';
  static const String eventsUpcoming = '/events/upcoming';
  static const String eventsAll = '/events/all';
  static const String eventsMyEvents = '/events/my-events';
  static const String eventsMyTickets = '/events/my-tickets';
  static const String eventsCreate = '/events/create';
  static const String eventsSearch = '/events/search';
  static const String eventsNearby = '/events/nearby';
  static const String eventsPopular = '/events/popular';
  static const String eventsVenues = '/events/venues';
  static const String eventsBrowse = '/events/browse';
  static const String eventsTickets = '/events/tickets';
  static const String eventsSaved = '/events/saved';
  static const String eventsHistory = '/events/history';

  // Messaging routes
  static const String messaging = '/messaging';
  static const String messagingNew = '/messaging/new';
  static const String messagingChat = '/messaging/chat';
  static const String messagingGroup = '/messaging/group';
  static const String messagingGroupNew = '/messaging/group/new';
  static const String messagingSettings = '/messaging/settings';
  static const String messagingChatInfo = '/messaging/chat-info';
  static const String messagingBlockedUsers = '/messaging/blocked-users';
  static const String messagingUser = '/messaging/user';
  static const String messagingChatDeep = '/messaging/chat-deep';
  static const String messagingUserChat = '/messaging/user-chat';
  static const String messagingThread = '/messaging/thread';

  // Admin routes
  static const String adminDashboard = '/admin/dashboard';
  static const String adminUsers = '/admin/users';
  static const String adminModeration = '/admin/moderation';
  static const String adminAdTest = '/admin/ad-test';
  static const String adminSettings = '/admin/settings';
  static const String adminAdReview = '/admin/ad-review';
  static const String adminAdManagement = '/admin/ad-management';
  static const String adminMessaging = '/admin/messaging';
  static const String adminCoupons = '/admin/coupons';
  static const String adminCouponManagement = '/admin/coupon-management';

  // Settings routes
  static const String settings = '/settings';
  static const String settingsAccount = '/settings/account';
  static const String settingsPrivacy = '/settings/privacy';
  static const String settingsNotifications = '/settings/notifications';
  static const String settingsSecurity = '/settings/security';

  // Other routes
  static const String achievements = '/achievements';
  static const String achievementsInfo = '/achievements/info';
  static const String rewards = '/rewards';
  static const String leaderboard = '/leaderboard';
  static const String notifications = '/notifications';
  static const String dev = '/dev';
  static const String developerFeedbackAdmin = '/developer-feedback-admin';
  static const String systemInfo = '/system/info';
  static const String support = '/support';
  static const String search = '/search';
  static const String searchResults = '/search/results';
  static const String browse = '/browse';
  static const String artSearch = '/art-search';
  static const String artWalkSearch = '/art-walk-search';
  static const String local = '/local';
  static const String locationSearch = '/location-search';
  static const String trending = '/trending';

  // Ad routes
  static const String adsCreate = '/ads/create';
  static const String adsManagement = '/ads/management';
  static const String adsStatistics = '/ads/statistics';
  static const String adsMyAds = '/ads/my-ads';
  static const String adsMyStatistics = '/ads/my-statistics';

  // In-app purchase routes
  static const String inAppPurchaseDemo = '/in-app-purchase-demo';
}

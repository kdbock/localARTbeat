import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:provider/provider.dart';
import '../models/analytics_model.dart';
import '../models/recent_activity_model.dart';
import '../models/user_admin_model.dart';
import '../models/content_review_model.dart';
import '../models/content_model.dart';
import '../models/transaction_model.dart';
import '../services/recent_activity_service.dart';
import '../services/enhanced_analytics_service.dart';
import '../services/consolidated_admin_service.dart';
import '../services/admin_service.dart';
import '../services/content_review_service.dart';
import '../services/unified_admin_service.dart';
import '../services/financial_service.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/admin_search_modal.dart';
import '../screens/admin_user_detail_screen.dart';

import '../routes/admin_routes.dart';

/// Modern Unified Admin Dashboard - Beautiful, intuitive interface for all admin functionality
///
/// Features:
/// - 🎨 Modern glassmorphism design
/// - 🌈 Color-coded sections for easy navigation
/// - ✨ Smooth animations and micro-interactions
/// - 📱 Responsive design for all screen sizes
/// - 🎯 Intuitive user experience
class ModernUnifiedAdminDashboard extends StatefulWidget {
  const ModernUnifiedAdminDashboard({super.key});

  @override
  State<ModernUnifiedAdminDashboard> createState() =>
      _ModernUnifiedAdminDashboardState();
}

class _ModernUnifiedAdminDashboardState
    extends State<ModernUnifiedAdminDashboard> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _mainTabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Services
  late RecentActivityService _activityService;
  late EnhancedAnalyticsService _analyticsService;
  late ConsolidatedAdminService _consolidatedService;
  late AdminService _adminService;
  late ContentReviewService _contentService;
  late UnifiedAdminService _unifiedAdminService;
  late FinancialService _financialService;

  // Data
  AnalyticsModel? _analytics;
  List<RecentActivityModel> _recentActivities = [];
  List<UserAdminModel> _users = [];
  List<ContentReviewModel> _pendingReviews = [];
  List<ContentModel> _allContent = [];
  List<TransactionModel> _recentTransactions = [];
  Map<String, double> _revenueBreakdown = {};
  Map<String, dynamic>? _contentStats;

  // State
  bool _isLoading = true;
  String? _error;
  Map<String, int> _pendingModerationSummary = {};

  // Search controllers for future use
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _contentSearchController =
      TextEditingController();

  // Content filter state
  String _selectedContentFilter = 'admin_modern_dashboard_filter_all';
  AdminContentType _selectedContentType = AdminContentType.all;

  @override
  void initState() {
    super.initState();
    _activityService = context.read<RecentActivityService>();
    _analyticsService = context.read<EnhancedAnalyticsService>();
    _consolidatedService = context.read<ConsolidatedAdminService>();
    _adminService = context.read<AdminService>();
    _contentService = context.read<ContentReviewService>();
    _unifiedAdminService = context.read<UnifiedAdminService>();
    _financialService = context.read<FinancialService>();
    _mainTabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadAllData();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _animationController.dispose();
    _userSearchController.dispose();
    _contentSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _loadDashboardData(),
        _loadUserData(),
        _loadContentData(),
      ]);
      if (!mounted) return;
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'admin_modern_dashboard_error_load_admin_data'
            .tr(namedArgs: {'error': '$e'});
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      final analytics = await _analyticsService.getEnhancedAnalytics(
        dateRange: DateRange.last30Days,
      );
      final activities = await _activityService.getRecentActivities(limit: 10);
      await _consolidatedService.getDashboardStats();

      // Load financial data
      final transactions =
          await _financialService.getRecentTransactions(limit: 10);
      final revenueBreakdown = await _financialService.getRevenueBreakdown();

      if (!mounted) return;
      setState(() {
        _analytics = analytics;
        _recentActivities = activities;
        _recentTransactions = transactions;
        _revenueBreakdown = revenueBreakdown;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'admin_modern_dashboard_error_load_dashboard_data'
            .tr(namedArgs: {'error': '$e'});
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    final users = await _adminService.getAllUsers();
    if (!mounted) return;
    setState(() {
      _users = users;
    });
  }

  Future<void> _loadContentData() async {
    final pendingReviews = await _contentService.getPendingReviews();
    final allContent = await _unifiedAdminService.getAllContent();
    final contentStats = await _unifiedAdminService.getContentStatistics();
    final moderationSummary =
        await _consolidatedService.getPendingModerationSummary();

    if (!mounted) return;
    setState(() {
      _pendingReviews = pendingReviews;
      _allContent = allContent;
      _contentStats = contentStats;
      _pendingModerationSummary = moderationSummary;
    });
  }

  void _handleSearch(String query) {
    _showAdminSearchModal(query);
  }

  void _showAdminSearchModal([String? initialQuery]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AdminSearchModal(
        initialQuery: initialQuery,
        users: _users,
        content: _allContent,
        transactions: _recentTransactions,
        onUserSelected: (user) {
          Navigator.pop(context);
          Navigator.pushNamed(
            context,
            '/admin/user-detail',
            arguments: user,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      scaffoldKey: _scaffoldKey,
      appBar: _buildModernAppBar(),
      drawer: const AdminDrawer(),
      child: Container(
        decoration: _buildBackgroundDecoration(),
        child: SafeArea(
          child: Column(
            children: [
              _buildModernTabBar(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingWidget()
                    : _error != null
                        ? _buildErrorWidget()
                        : FadeTransition(
                            opacity: _fadeAnimation,
                            child: TabBarView(
                              controller: _mainTabController,
                              children: [
                                _buildModernDashboardTab(),
                                _buildModernUserManagementTab(),
                                _buildModernContentModerationTab(),
                                _buildModernFinancialTab(),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    return EnhancedUniversalHeader(
      title: 'admin_modern_dashboard_app_bar_title'.tr(),
      showBackButton: false,
      showSearch: true,
      showDeveloperTools: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      onSearchPressed: _handleSearch,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadAllData,
            tooltip: 'admin_modern_dashboard_refresh_data'.tr(),
          ),
        ),
      ],
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF667eea),
          Color(0xFF764ba2),
          Color(0xFF8C52FF),
        ],
        stops: [0.0, 0.5, 1.0],
      ),
    );
  }

  Widget _buildModernTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: TabBar(
          controller: _mainTabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          tabs: [
            _buildModernTab('admin_modern_dashboard_tab_dashboard'.tr(),
                Icons.dashboard_rounded),
            _buildModernTab(
                'admin_modern_dashboard_tab_users'.tr(), Icons.people_rounded),
            _buildModernTab('admin_modern_dashboard_tab_content'.tr(),
                Icons.content_copy_rounded),
            _buildModernTab('admin_modern_dashboard_tab_financial'.tr(),
                Icons.analytics_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTab(String label, IconData icon) {
    return Tab(
      height: 60,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'admin_modern_dashboard_loading_admin_data'.tr(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'admin_modern_dashboard_error_title'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'admin_modern_dashboard_unknown_error'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildModernButton(
              'admin_modern_dashboard_try_again'.tr(),
              Icons.refresh_rounded,
              _loadAllData,
              isPrimary: true,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MODERN DASHBOARD TAB ====================
  Widget _buildModernDashboardTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: Colors.white,
      backgroundColor: const Color(0xFF8C52FF),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModernKPIOverview(),
            const SizedBox(height: 20),
            _buildModernQuickActions(),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildModernRecentActivity()),
                const SizedBox(width: 16),
                Expanded(child: _buildModernSystemHealth()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernKPIOverview() {
    return Container(
      decoration: _buildGlassDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'admin_modern_dashboard_performance_overview'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.9,
                children: [
                  _buildModernKPICard(
                    'admin_modern_dashboard_total_users'.tr(),
                    _users.length.toString(),
                    Icons.people_rounded,
                    const Color(0xFF4FC3F7),
                    'admin_modern_dashboard_trend_users'.tr(),
                    true,
                  ),
                  _buildModernKPICard(
                    'admin_modern_dashboard_pending_reviews'.tr(),
                    _pendingReviews.length.toString(),
                    Icons.rate_review_rounded,
                    const Color(0xFFFFB74D),
                    _pendingReviews.length > 10
                        ? 'admin_modern_dashboard_status_high'.tr()
                        : 'admin_modern_dashboard_status_normal'.tr(),
                    _pendingReviews.length <= 10,
                  ),
                  _buildModernKPICard(
                    'admin_modern_dashboard_total_content'.tr(),
                    _allContent.length.toString(),
                    Icons.content_copy_rounded,
                    const Color(0xFF81C784),
                    'admin_modern_dashboard_trend_content'.tr(),
                    true,
                  ),
                  _buildModernKPICard(
                    'admin_modern_dashboard_revenue'.tr(),
                    _analytics?.financialMetrics != null
                        ? _formatCurrency(
                            _analytics!.financialMetrics.totalRevenue)
                        : '\$0',
                    Icons.trending_up_rounded,
                    const Color(0xFFBA68C8),
                    'admin_modern_dashboard_trend_revenue'.tr(),
                    true,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModernKPICard(
    String title,
    String value,
    IconData icon,
    Color color,
    String trend,
    bool isPositive,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (isPositive ? Colors.green : Colors.orange)
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              trend,
              style: TextStyle(
                fontSize: 9,
                color: isPositive ? Colors.green[300] : Colors.orange[300],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernQuickActions() {
    return Container(
      decoration: _buildGlassDecoration(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'admin_modern_dashboard_quick_actions'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildModernActionCard(
                'admin_modern_dashboard_action_review_content'.tr(),
                'admin_modern_dashboard_action_review_content_subtitle'.tr(),
                Icons.rate_review_rounded,
                const Color(0xFFFFB74D),
                () => _mainTabController.animateTo(2),
                badge: _pendingReviews.isNotEmpty
                    ? _pendingReviews.length.toString()
                    : null,
              ),
              _buildModernActionCard(
                'admin_modern_dashboard_action_manage_users'.tr(),
                'admin_modern_dashboard_action_manage_users_subtitle'.tr(),
                Icons.people_rounded,
                const Color(0xFF4FC3F7),
                () => _mainTabController.animateTo(1),
              ),
              _buildModernActionCard(
                'admin_modern_dashboard_action_financial_reports'.tr(),
                'admin_modern_dashboard_action_financial_reports_subtitle'.tr(),
                Icons.analytics_rounded,
                const Color(0xFFBA68C8),
                () => _mainTabController.animateTo(3),
              ),
              _buildModernActionCard(
                'admin_modern_dashboard_action_system_settings'.tr(),
                'admin_modern_dashboard_action_system_settings_subtitle'.tr(),
                Icons.settings_rounded,
                const Color(0xFF81C784),
                () => Navigator.pushNamed(context, '/admin/settings'),
              ),
              _buildModernActionCard(
                'Onboarding Funnel',
                'View user onboarding conversion metrics',
                Icons.insights_rounded,
                const Color(0xFF64B5F6),
                () => Navigator.pushNamed(
                  context,
                  AppRoutes.onboardingFunnelAnalytics,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    String? badge,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 140,
          maxWidth: 180,
          minHeight: 100,
          maxHeight: 120,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernRecentActivity() {
    return Container(
      decoration: _buildGlassDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'admin_modern_dashboard_recent_activity'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentActivities.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_rounded,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'admin_modern_dashboard_no_recent_activity'.tr(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentActivities.length.clamp(0, 5),
              separatorBuilder: (context, index) => Divider(
                color: Colors.white.withValues(alpha: 0.2),
                height: 20,
              ),
              itemBuilder: (context, index) {
                final activity = _recentActivities[index];
                return _buildActivityItem(activity);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(RecentActivityModel activity) {
    final activityColor = _getActivityColor(activity.type.name);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: activityColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getActivityIcon(activity.type.name),
              color: activityColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateTime(activity.timestamp),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernSystemHealth() {
    return Container(
      decoration: _buildGlassDecoration(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'admin_modern_dashboard_system_health'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              _buildModernHealthIndicator(
                  'admin_modern_dashboard_health_database'.tr(),
                  true,
                  Icons.storage_rounded),
              const SizedBox(height: 12),
              _buildModernHealthIndicator(
                  'admin_modern_dashboard_health_api_services'.tr(),
                  true,
                  Icons.api_rounded),
              const SizedBox(height: 12),
              _buildModernHealthIndicator(
                  'admin_modern_dashboard_health_file_storage'.tr(),
                  true,
                  Icons.cloud_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernHealthIndicator(
      String service, bool isHealthy, IconData icon) {
    final color = isHealthy ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              service,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isHealthy
                  ? 'admin_modern_dashboard_health_healthy'.tr()
                  : 'admin_modern_dashboard_health_error'.tr(),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== PLACEHOLDER TABS ====================
  Widget _buildModernUserManagementTab() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      color: Colors.white,
      backgroundColor: const Color(0xFF8C52FF),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Statistics Overview
            Container(
              decoration: _buildGlassDecoration(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.people_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'admin_modern_dashboard_user_management'.tr(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                        children: [
                          _buildUserStatCard(
                            'admin_modern_dashboard_total_users'.tr(),
                            _users.length.toString(),
                            Icons.people_rounded,
                            const Color(0xFF4FC3F7),
                          ),
                          _buildUserStatCard(
                            'admin_modern_dashboard_verified_users'.tr(),
                            _users.where((u) => u.isVerified).length.toString(),
                            Icons.verified_rounded,
                            const Color(0xFF81C784),
                          ),
                          _buildUserStatCard(
                            'admin_modern_dashboard_featured_users'.tr(),
                            _users.where((u) => u.isFeatured).length.toString(),
                            Icons.star_rounded,
                            const Color(0xFFFFB74D),
                          ),
                          _buildUserStatCard(
                            'admin_modern_dashboard_suspended_users'.tr(),
                            _users
                                .where((u) => u.isSuspended)
                                .length
                                .toString(),
                            Icons.block_rounded,
                            const Color(0xFFEF5350),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // User Search and Filters
            Container(
              decoration: _buildGlassDecoration(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _userSearchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'admin_modern_dashboard_search_users_hint'.tr(),
                      hintStyle:
                          TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.white.withValues(alpha: 0.6)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                            'admin_modern_dashboard_filter_all'.tr(),
                            _getFilteredUsers().length),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                            'admin_modern_dashboard_filter_verified'.tr(),
                            _users.where((u) => u.isVerified).length),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                            'admin_modern_dashboard_filter_featured'.tr(),
                            _users.where((u) => u.isFeatured).length),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                            'admin_modern_dashboard_filter_suspended'.tr(),
                            _users.where((u) => u.isSuspended).length),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // User List
            Container(
              decoration: _buildGlassDecoration(),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _getFilteredUsers().length,
                itemBuilder: (context, index) {
                  final user = _getFilteredUsers()[index];
                  return _buildUserListItem(user);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        'admin_modern_dashboard_filter_chip'.tr(
          namedArgs: {'label': label, 'count': '$count'},
        ),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<UserAdminModel> _getFilteredUsers() {
    final query = _userSearchController.text.toLowerCase();
    if (query.isEmpty) return _users;

    return _users.where((user) {
      return user.fullName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.username.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildUserListItem(UserAdminModel user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // User Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: _getUserTypeColor(user.userType ?? 'regular'),
            child: user.profileImageUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      user.profileImageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Text(
                        user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : Text(
                    user.fullName.isNotEmpty
                        ? user.fullName[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
          const SizedBox(width: 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.isVerified)
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF4FC3F7),
                        size: 16,
                      ),
                    if (user.isFeatured)
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFB74D),
                        size: 16,
                      ),
                    if (user.isSuspended)
                      const Icon(
                        Icons.block_rounded,
                        color: Color(0xFFEF5350),
                        size: 16,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getUserTypeColor(user.userType ?? 'regular')
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        (user.userType ?? 'regular').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'admin_modern_dashboard_joined_date'.tr(
                          namedArgs: {'date': _formatDate(user.createdAt)},
                        ),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Button
          IconButton(
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => _navigateToUserDetail(user),
          ),
        ],
      ),
    );
  }

  void _navigateToUserDetail(UserAdminModel user) async {
    await Navigator.push(
      context,
      MaterialPageRoute<AdminUserDetailScreen>(
        builder: (context) => AdminUserDetailScreen(user: user),
      ),
    );
    // Refresh user data after returning from detail screen
    await _loadUserData();
  }

  Color _getUserTypeColor(String? userType) {
    switch (userType?.toLowerCase()) {
      case 'admin':
        return const Color(0xFFEF5350);
      case 'moderator':
        return const Color(0xFFFFB74D);
      case 'artist':
        return const Color(0xFFBA68C8);
      case 'gallery':
        return const Color(0xFF81C784);
      default:
        return const Color(0xFF4FC3F7);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  Widget _buildModernContentModerationTab() {
    return RefreshIndicator(
      onRefresh: _loadContentData,
      color: Colors.white,
      backgroundColor: const Color(0xFF8C52FF),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content Statistics Overview
            Container(
              decoration: _buildGlassDecoration(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.content_copy_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'admin_modern_dashboard_content_moderation'.tr(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 800
                          ? 6
                          : (constraints.maxWidth > 600 ? 3 : 2);
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                        children: [
                          _buildContentStatCard(
                            'admin_modern_dashboard_general_reviews'.tr(),
                            _pendingModerationSummary['generalReviews']
                                    ?.toString() ??
                                '0',
                            Icons.rate_review_rounded,
                            const Color(0xFFFFB74D),
                          ),
                          _buildContentStatCard(
                            'admin_modern_dashboard_pending_events'.tr(),
                            _pendingModerationSummary['pendingEvents']
                                    ?.toString() ??
                                '0',
                            Icons.event_note_rounded,
                            const Color(0xFFCE93D8),
                          ),
                          _buildContentStatCard(
                            'admin_modern_dashboard_reported_walks'.tr(),
                            _pendingModerationSummary['reportedArtWalks']
                                    ?.toString() ??
                                '0',
                            Icons.flag_rounded,
                            const Color(0xFFFF5722),
                          ),
                          _buildContentStatCard(
                            'admin_modern_dashboard_pending_captures'.tr(),
                            _pendingModerationSummary['pendingCaptures']
                                    ?.toString() ??
                                '0',
                            Icons.camera_rounded,
                            const Color(0xFF4FC3F7),
                          ),
                          _buildContentStatCard(
                            'admin_modern_dashboard_total_content'.tr(),
                            (_contentStats?['total'] ?? _allContent.length)
                                .toString(),
                            Icons.content_copy_rounded,
                            Colors.white70,
                          ),
                          _buildContentStatCard(
                            'admin_modern_dashboard_filter_approved'.tr(),
                            _allContent
                                .where((c) => c.status == 'approved')
                                .length
                                .toString(),
                            Icons.check_circle_rounded,
                            const Color(0xFF81C784),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Dedicated Moderation Suites
            Container(
              decoration: _buildGlassDecoration(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'admin_modern_dashboard_moderation_suites'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'admin_modern_dashboard_moderation_suites_subtitle'.tr(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 64) / 3,
                        child: _buildModerationSuiteTile(
                          'admin_modern_dashboard_suite_events'.tr(),
                          'admin_modern_dashboard_suite_events_subtitle'.tr(),
                          Icons.event_rounded,
                          Colors.purpleAccent,
                          () => Navigator.pushNamed(
                              context, AdminRoutes.eventModeration),
                          badgeCount:
                              _pendingModerationSummary['pendingEvents'] ?? 0,
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 64) / 3,
                        child: _buildModerationSuiteTile(
                          'admin_modern_dashboard_suite_art_walks'.tr(),
                          'admin_modern_dashboard_suite_art_walks_subtitle'
                              .tr(),
                          Icons.route_rounded,
                          Colors.tealAccent,
                          () => Navigator.pushNamed(
                              context, AdminRoutes.artWalkModeration),
                          badgeCount:
                              _pendingModerationSummary['reportedArtWalks'] ??
                                  0,
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 64) / 3,
                        child: _buildModerationSuiteTile(
                          'admin_modern_dashboard_suite_captures'.tr(),
                          'admin_modern_dashboard_suite_captures_subtitle'.tr(),
                          Icons.camera_rounded,
                          Colors.orangeAccent,
                          () => Navigator.pushNamed(
                              context, AdminRoutes.contentModeration),
                          badgeCount:
                              _pendingModerationSummary['pendingCaptures'] ?? 0,
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 64) / 3,
                        child: _buildModerationSuiteTile(
                          'admin_modern_dashboard_suite_artworks'.tr(),
                          'admin_modern_dashboard_suite_artworks_subtitle'.tr(),
                          Icons.brush_rounded,
                          Colors.pinkAccent,
                          () => Navigator.pushNamed(
                              context, AdminRoutes.artworkModeration),
                          badgeCount:
                              _pendingModerationSummary['pendingArtworks'] ?? 0,
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 64) / 3,
                        child: _buildModerationSuiteTile(
                          'admin_modern_dashboard_suite_community'.tr(),
                          'admin_modern_dashboard_suite_community_subtitle'
                              .tr(),
                          Icons.forum_rounded,
                          Colors.blueAccent,
                          () => Navigator.pushNamed(
                              context, AdminRoutes.communityModeration),
                          badgeCount:
                              (_pendingModerationSummary['flaggedPosts'] ?? 0) +
                                  (_pendingModerationSummary[
                                          'flaggedComments'] ??
                                      0),
                        ),
                      ),
                      SizedBox(
                        width: (MediaQuery.of(context).size.width - 64) / 3,
                        child: _buildModerationSuiteTile(
                          'admin_modern_dashboard_suite_upload_tools'.tr(),
                          'admin_modern_dashboard_suite_upload_tools_subtitle'
                              .tr(),
                          Icons.upload_file_rounded,
                          Colors.indigoAccent,
                          () => Navigator.pushNamed(
                              context, AdminRoutes.dataUpload),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Content Filters
            Container(
              decoration: _buildGlassDecoration(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _contentSearchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText:
                          'admin_modern_dashboard_search_content_hint'.tr(),
                      hintStyle:
                          TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.white.withValues(alpha: 0.6)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildContentFilterChip(
                            'admin_modern_dashboard_filter_all'.tr(),
                            _getFilteredContent().length),
                        const SizedBox(width: 8),
                        _buildContentFilterChip(
                            'admin_modern_dashboard_filter_pending'.tr(),
                            _pendingReviews.length),
                        const SizedBox(width: 8),
                        _buildContentFilterChip(
                            'admin_modern_dashboard_filter_approved'.tr(),
                            _allContent
                                .where((c) => c.status == 'approved')
                                .length),
                        const SizedBox(width: 8),
                        _buildContentFilterChip(
                            'admin_modern_dashboard_filter_rejected'.tr(),
                            _allContent
                                .where((c) => c.status == 'rejected')
                                .length),
                        const SizedBox(width: 8),
                        _buildContentFilterChip(
                            'admin_modern_dashboard_filter_reported'.tr(),
                            _allContent
                                .where((c) => c.status == 'flagged')
                                .length),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildContentTypeFilterChip(AdminContentType.all),
                        const SizedBox(width: 8),
                        _buildContentTypeFilterChip(AdminContentType.artwork),
                        const SizedBox(width: 8),
                        _buildContentTypeFilterChip(AdminContentType.post),
                        const SizedBox(width: 8),
                        _buildContentTypeFilterChip(AdminContentType.event),
                        const SizedBox(width: 8),
                        _buildContentTypeFilterChip(AdminContentType.capture),
                        const SizedBox(width: 8),
                        _buildContentTypeFilterChip(AdminContentType.chapter),
                        const SizedBox(width: 8),
                        _buildContentTypeFilterChip(AdminContentType.ad),
                        const SizedBox(width: 8),
                        _buildContentTypeFilterChip(
                            AdminContentType.commission),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pending Reviews Section
            if (_pendingReviews.isNotEmpty) ...[
              Container(
                decoration: _buildGlassDecoration(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'admin_modern_dashboard_pending_reviews'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pendingReviews.length,
                      itemBuilder: (context, index) {
                        final review = _pendingReviews[index];
                        return _buildPendingReviewItem(review);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Recent Content Section
            Container(
              decoration: _buildGlassDecoration(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'admin_modern_dashboard_recent_content'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _getFilteredContent().take(10).length,
                    itemBuilder: (context, index) {
                      final content = _getFilteredContent()[index];
                      return _buildContentListItem(content);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModerationSuiteTile(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap,
      {int badgeCount = 0}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (badgeCount > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  badgeCount > 99
                      ? 'admin_modern_dashboard_badge_99_plus'.tr()
                      : badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContentFilterChip(String label, int count,
      {VoidCallback? onTap}) {
    final isSelected = _selectedContentFilter == label;
    return GestureDetector(
      onTap: onTap ?? () => setState(() => _selectedContentFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          'admin_modern_dashboard_filter_chip'.tr(
            namedArgs: {'label': label, 'count': '$count'},
          ),
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildContentTypeFilterChip(AdminContentType contentType) {
    final isSelected = _selectedContentType == contentType;
    final count = contentType == AdminContentType.all
        ? _allContent.length
        : _allContent.where((c) => c.contentType == contentType).length;

    return GestureDetector(
      onTap: () => setState(() => _selectedContentType = contentType),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.blue.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          'admin_modern_dashboard_filter_chip'.tr(
            namedArgs: {
              'label': contentType.displayName,
              'count': '$count',
            },
          ),
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  List<ContentModel> _getFilteredContent() {
    final query = _contentSearchController.text.toLowerCase();

    // First filter by content type
    List<ContentModel> filteredByType = _allContent;
    if (_selectedContentType != AdminContentType.all) {
      filteredByType = _allContent
          .where((c) => c.contentType == _selectedContentType)
          .toList();
    }

    // Then filter by status
    List<ContentModel> filteredByStatus = filteredByType;
    if (_selectedContentFilter != 'admin_modern_dashboard_filter_all') {
      switch (_selectedContentFilter) {
        case 'admin_modern_dashboard_filter_pending':
          final pendingContentIds =
              _pendingReviews.map((r) => r.contentId).toSet();
          filteredByStatus = filteredByType
              .where((c) => pendingContentIds.contains(c.id))
              .toList();
          break;
        case 'admin_modern_dashboard_filter_approved':
          filteredByStatus =
              filteredByType.where((c) => c.status == 'approved').toList();
          break;
        case 'admin_modern_dashboard_filter_rejected':
          filteredByStatus =
              filteredByType.where((c) => c.status == 'rejected').toList();
          break;
        case 'admin_modern_dashboard_filter_reported':
          filteredByStatus =
              filteredByType.where((c) => c.status == 'flagged').toList();
          break;
      }
    }

    // Then filter by search query
    if (query.isEmpty) return filteredByStatus;

    return filteredByStatus.where((content) {
      return content.title.toLowerCase().contains(query) ||
          content.description.toLowerCase().contains(query) ||
          content.authorName.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildPendingReviewItem(ContentReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB74D).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'admin_modern_dashboard_filter_pending'.tr().toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFFFB74D),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'admin_modern_dashboard_by_author'.tr(
              namedArgs: {'author': review.authorName},
            ),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveContent(review),
                  icon: const Icon(Icons.check_rounded, size: 16),
                  label: Text(
                      'admin_modern_unified_admin_dashboard_text_approve'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF81C784),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _rejectContent(review),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: Text(
                      'admin_modern_unified_admin_dashboard_text_reject'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF5350),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContentListItem(ContentModel content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          // Content Thumbnail
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: content.imageUrl != null && content.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      content.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.image_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
          ),
          const SizedBox(width: 16),

          // Content Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  content.description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'admin_modern_dashboard_by_author'.tr(
                          namedArgs: {'author': content.authorName},
                        ),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getContentStatusColor(content.status)
                            .withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        content.status.toUpperCase(),
                        style: TextStyle(
                          color: _getContentStatusColor(content.status),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Menu
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
            ),
            color: const Color(0xFF8C52FF),
            onSelected: (value) => _handleContentAction(content, value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'view',
                child: Text('admin_modern_dashboard_view_details'.tr(),
                    style: const TextStyle(color: Colors.white)),
              ),
              PopupMenuItem(
                value: 'edit',
                child: Text('admin_modern_dashboard_edit_content'.tr(),
                    style: const TextStyle(color: Colors.white)),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Text('admin_modern_dashboard_delete_content'.tr(),
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getContentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF81C784);
      case 'rejected':
        return const Color(0xFFEF5350);
      case 'flagged':
        return const Color(0xFFEF5350); // Red for flagged
      case 'pending':
        return const Color(0xFFFFB74D);
      default: // active
        return const Color(0xFF4FC3F7); // Blue for active
    }
  }

  Future<void> _approveContent(ContentReviewModel review) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'admin_modern_unified_admin_dashboard_text_approving_content'
                    .tr())),
      );

      // Approve the content using the unified admin service
      final artworkId = review.metadata?['artworkId'] as String?;
      await _unifiedAdminService.approveContent(review.contentId,
          artworkId: artworkId);

      // Trigger rewards if it's a capture
      if (review.contentType == ContentType.captures) {
        await _unifiedAdminService.rewardApprovedCapture(review.contentId);
      }

      // Refresh the content data
      await _loadContentData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'admin_modern_unified_admin_dashboard_title_approved_reviewtitle'
                    .tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'admin_modern_unified_admin_dashboard_error_failed_to_approve'
                    .tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectContent(ContentReviewModel review) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'admin_modern_unified_admin_dashboard_text_rejecting_content'
                    .tr())),
      );

      // Reject the content using the unified admin service
      final artworkId = review.metadata?['artworkId'] as String?;
      await _unifiedAdminService.rejectContent(review.contentId,
          reason: 'Rejected by admin', artworkId: artworkId);

      // Refresh the content data
      await _loadContentData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'admin_modern_unified_admin_dashboard_title_rejected_reviewtitle'
                    .tr()),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'admin_modern_unified_admin_dashboard_error_failed_to_reject'
                    .tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleContentAction(ContentModel content, String action) {
    switch (action) {
      case 'view':
        _showContentDetails(content);
        break;
      case 'edit':
        _showEditContentDialog(content);
        break;
      case 'delete':
        _showDeleteConfirmation(content);
        break;
    }
  }

  void _showContentDetails(ContentModel content) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF8C52FF),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getContentIcon(content.type),
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  content.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  content.displayType,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getContentStatusColor(content.status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              content.status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Media content
                      if ((content.imageUrl != null &&
                              content.imageUrl!.isNotEmpty) ||
                          (content.metadata['imageUrls'] != null &&
                              (content.metadata['imageUrls'] as List)
                                  .isNotEmpty) ||
                          (content.metadata['videoUrl'] != null &&
                              (content.metadata['videoUrl'] as String?)
                                      ?.isNotEmpty ==
                                  true)) ...[
                        Text(
                          'admin_modern_dashboard_media'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Single image (legacy)
                        if (content.imageUrl != null &&
                            content.imageUrl!.isNotEmpty) ...[
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: ImageUrlValidator.isValidImageUrl(
                                      content.imageUrl)
                                  ? DecorationImage(
                                      image: ImageUrlValidator.safeNetworkImage(
                                          content.imageUrl)!,
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        // Multiple images
                        if (content.metadata['imageUrls'] != null) ...[
                          for (final imageUrl
                              in content.metadata['imageUrls'] as List<dynamic>)
                            if (imageUrl is String && imageUrl.isNotEmpty) ...[
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: ImageUrlValidator.isValidImageUrl(
                                              imageUrl) &&
                                          ImageUrlValidator.safeNetworkImage(
                                                  imageUrl) !=
                                              null
                                      ? DecorationImage(
                                          image: ImageUrlValidator
                                              .safeNetworkImage(imageUrl)!,
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                        ],
                        // Video
                        if (content.metadata['videoUrl'] != null &&
                            (content.metadata['videoUrl'] as String?)
                                    ?.isNotEmpty ==
                                true) ...[
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.play_circle_fill,
                                color: Colors.white,
                                size: 48,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 12),
                      ],

                      // Description
                      if (content.description.isNotEmpty) ...[
                        Text(
                          'admin_modern_dashboard_description'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          content.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Author info
                      _buildDetailRow('admin_modern_dashboard_author'.tr(),
                          content.authorName),
                      _buildDetailRow('admin_modern_dashboard_created'.tr(),
                          _formatDate(content.createdAt)),
                      if (content.updatedAt != null)
                        _buildDetailRow('admin_modern_dashboard_updated'.tr(),
                            _formatDate(content.updatedAt!)),

                      // Stats
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStatChip('admin_modern_dashboard_views'.tr(),
                              content.viewCount.toString()),
                          const SizedBox(width: 12),
                          _buildStatChip('admin_modern_dashboard_likes'.tr(),
                              content.likeCount.toString()),
                          const SizedBox(width: 12),
                          _buildStatChip('admin_modern_dashboard_reports'.tr(),
                              content.reportCount.toString()),
                        ],
                      ),

                      // Tags
                      if (content.tags.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          'admin_modern_dashboard_tags'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: content.tags
                              .map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      tag,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Action buttons
                      Row(
                        children: [
                          if (content.status == 'flagged') ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    await _contentService.approveContent(
                                        content.id,
                                        _getContentTypeFromString(
                                            content.type));
                                    // ignore: use_build_context_synchronously
                                    Navigator.pop(context);
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'admin_modern_dashboard_review_cleared_successfully'
                                                .tr()),
                                        backgroundColor: Colors.green,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    );
                                    await _loadContentData(); // Refresh the list
                                  } catch (e) {
                                    // ignore: use_build_context_synchronously
                                    Navigator.pop(context);
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'admin_modern_unified_admin_dashboard_error_failed_to_clear'
                                                .tr()),
                                        backgroundColor: Colors.red,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.green.withValues(alpha: 0.8),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.check_circle),
                                label: Text(
                                    'admin_modern_unified_admin_dashboard_text_clear_review'
                                        .tr()),
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showEditContentDialog(content);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.2),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.edit),
                              label: Text(
                                  'admin_modern_unified_admin_dashboard_text_edit'
                                      .tr()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showDeleteConfirmation(content);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.red.withValues(alpha: 0.8),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.delete),
                              label: Text(
                                  'admin_modern_unified_admin_dashboard_text_delete'
                                      .tr()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        'admin_modern_dashboard_stat_chip'.tr(
          namedArgs: {'label': label, 'value': value},
        ),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getContentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'artwork':
        return Icons.palette;
      case 'post':
        return Icons.article;
      case 'event':
        return Icons.event;
      case 'ad':
        return Icons.campaign;
      default:
        return Icons.content_copy;
    }
  }

  void _showEditContentDialog(ContentModel content) {
    final titleController = TextEditingController(text: content.title);
    final descriptionController =
        TextEditingController(text: content.description);
    String selectedStatus = content.status;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF8C52FF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                _getContentIcon(content.type),
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'admin_modern_dashboard_edit_content'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title field
                Text(
                  'admin_modern_dashboard_title_label'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'admin_modern_dashboard_enter_title'.tr(),
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Description field
                Text(
                  'admin_modern_dashboard_description'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'admin_modern_dashboard_enter_description'.tr(),
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Status dropdown
                Text(
                  'admin_modern_dashboard_status'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF8C52FF),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.white, width: 2),
                    ),
                  ),
                  items:
                      ['approved', 'pending', 'rejected', 'flagged', 'archived']
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(
                                  status.toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ))
                          .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedStatus = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'admin_modern_dashboard_cancel'.tr(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _updateContent(
                  content,
                  titleController.text,
                  descriptionController.text,
                  selectedStatus,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF8C52FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('admin_admin_user_detail_text_save_changes'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(ContentModel content) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF8C52FF),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.warning_rounded,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'admin_modern_dashboard_delete_content'.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'admin_modern_dashboard_delete_confirmation'.tr(
                namedArgs: {'type': content.type},
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    content.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'admin_modern_dashboard_by_author_lower'.tr(
                      namedArgs: {'author': content.authorName},
                    ),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'admin_modern_dashboard_delete_irreversible'.tr(),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'admin_modern_dashboard_cancel'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteContent(content);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child:
                Text('admin_modern_unified_admin_dashboard_text_delete'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _updateContent(
    ContentModel content,
    String newTitle,
    String newDescription,
    String newStatus,
  ) async {
    try {
      await _unifiedAdminService.updateContentRecord(
        content: content,
        newTitle: newTitle,
        newDescription: newDescription,
        newStatus: newStatus,
      );

      // Update local data
      final index = _allContent.indexWhere((c) => c.id == content.id);
      if (index != -1) {
        setState(() {
          _allContent[index] = content.copyWith(
            title: newTitle,
            description: newDescription,
            status: newStatus,
            updatedAt: DateTime.now(),
          );
        });
      }

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'admin_modern_unified_admin_dashboard_success_updated_newtitle_successfully'
                  .tr()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'admin_modern_unified_admin_dashboard_error_failed_to_update'
                  .tr()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _deleteContent(ContentModel content) async {
    try {
      await _unifiedAdminService.deleteContentRecord(content);

      // Remove from local data
      setState(() {
        _allContent.removeWhere((c) => c.id == content.id);
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'admin_modern_unified_admin_dashboard_success_deleted_contenttitle_successfully'
                  .tr()),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'admin_modern_unified_admin_dashboard_error_failed_to_delete'
                  .tr()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  ContentType _getContentTypeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'post':
        return ContentType.posts;
      case 'artwork':
        return ContentType.artwork;
      case 'ad':
        return ContentType.ads;
      case 'capture':
        return ContentType.captures;
      case 'comment':
        return ContentType.comments;
      default:
        return ContentType.posts; // Default fallback
    }
  }

  Widget _buildModernFinancialTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: Colors.white,
      backgroundColor: const Color(0xFF8C52FF),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Financial Overview
            Container(
              decoration: _buildGlassDecoration(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.analytics_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'admin_modern_dashboard_financial_analytics'.tr(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.4, // Increased to prevent overflow
                        children: [
                          _buildFinancialKPICard(
                            'admin_modern_dashboard_total_revenue'.tr(),
                            _analytics?.financialMetrics != null
                                ? _formatCurrency(
                                    _analytics!.financialMetrics.totalRevenue)
                                : '\$0',
                            Icons.trending_up_rounded,
                            const Color(0xFF4FC3F7),
                            _analytics?.financialMetrics != null
                                ? '${_analytics!.financialMetrics.revenueGrowth >= 0 ? '+' : ''}${_analytics!.financialMetrics.revenueGrowth.toStringAsFixed(1)}%'
                                : '--',
                            _analytics?.financialMetrics != null
                                ? _analytics!.financialMetrics.revenueGrowth >=
                                    0
                                : true,
                          ),
                          _buildFinancialKPICard(
                            'admin_modern_dashboard_monthly_recurring'.tr(),
                            _analytics?.financialMetrics != null
                                ? _formatCurrency(_analytics!
                                    .financialMetrics.monthlyRecurringRevenue)
                                : '\$0',
                            Icons.repeat_rounded,
                            const Color(0xFF81C784),
                            _analytics?.financialMetrics != null
                                ? '${_analytics!.financialMetrics.subscriptionGrowth >= 0 ? '+' : ''}${_analytics!.financialMetrics.subscriptionGrowth.toStringAsFixed(1)}%'
                                : '--',
                            _analytics?.financialMetrics != null
                                ? _analytics!
                                        .financialMetrics.subscriptionGrowth >=
                                    0
                                : true,
                          ),
                          _buildFinancialKPICard(
                            'admin_modern_dashboard_total_transactions'.tr(),
                            _analytics?.financialMetrics != null
                                ? _analytics!.financialMetrics.totalTransactions
                                    .toString()
                                : '0',
                            Icons.receipt_long_rounded,
                            const Color(0xFFFFB74D),
                            _analytics?.financialMetrics != null
                                ? '${_analytics!.financialMetrics.totalTransactions} total'
                                : '--',
                            true,
                          ),
                          _buildFinancialKPICard(
                            'admin_modern_dashboard_avg_transaction'.tr(),
                            _analytics?.financialMetrics != null
                                ? _formatCurrency(_analytics!
                                    .financialMetrics.averageRevenuePerUser)
                                : '\$0',
                            Icons.payments_rounded,
                            const Color(0xFFBA68C8),
                            _analytics?.financialMetrics != null
                                ? 'Per transaction'
                                : '--',
                            true,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Revenue Breakdown
            Container(
              decoration: _buildGlassDecoration(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'admin_modern_dashboard_revenue_breakdown'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildRevenueChart(),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildRevenueSourceCard(
                          'admin_modern_dashboard_revenue_source_ads'.tr(),
                          _revenueBreakdown['Advertisements']?.round() ?? 0,
                          const Color(0xFF4FC3F7),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildRevenueSourceCard(
                          'admin_modern_dashboard_revenue_source_subscriptions'
                              .tr(),
                          _revenueBreakdown['Subscriptions']?.round() ?? 0,
                          const Color(0xFF81C784),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildRevenueSourceCard(
                          'admin_modern_dashboard_revenue_source_artwork_sales'
                              .tr(),
                          _revenueBreakdown['Artwork Sales']?.round() ?? 0,
                          const Color(0xFFFFB74D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Transaction History
            Container(
              decoration: _buildGlassDecoration(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'admin_modern_dashboard_recent_transactions'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTransactionList(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Financial Insights
            Container(
              decoration: _buildGlassDecoration(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'admin_modern_dashboard_financial_insights'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFinancialInsightCard(
                    'admin_modern_dashboard_revenue_growth'.tr(),
                    _analytics?.financialMetrics != null
                        ? 'Revenue ${_analytics!.financialMetrics.revenueGrowth >= 0 ? 'increased' : 'decreased'} by ${_analytics!.financialMetrics.revenueGrowth.abs().toStringAsFixed(1)}% compared to last period'
                        : 'Revenue growth data will appear here',
                    Icons.trending_up_rounded,
                    _analytics?.financialMetrics != null &&
                            _analytics!.financialMetrics.revenueGrowth >= 0
                        ? const Color(0xFF81C784)
                        : const Color(0xFFEF5350),
                  ),
                  const SizedBox(height: 12),
                  _buildFinancialInsightCard(
                    'admin_modern_dashboard_transaction_volume'.tr(),
                    _analytics?.financialMetrics != null
                        ? '${_analytics!.financialMetrics.totalTransactions} transactions processed'
                        : 'Transaction data will appear here',
                    Icons.receipt_long_rounded,
                    const Color(0xFF4FC3F7),
                  ),
                  const SizedBox(height: 12),
                  _buildFinancialInsightCard(
                    'admin_modern_dashboard_average_revenue'.tr(),
                    _analytics?.financialMetrics != null
                        ? 'Average revenue per transaction: ${_formatCurrency(_analytics!.financialMetrics.averageRevenuePerUser)}'
                        : 'Average revenue data will appear here',
                    Icons.analytics_rounded,
                    const Color(0xFFFFB74D),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialKPICard(
    String title,
    String value,
    IconData icon,
    Color color,
    String trend,
    bool isPositive,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: isPositive
                    ? const Color(0xFF81C784)
                    : const Color(0xFFEF5350),
                size: 14,
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  trend,
                  style: TextStyle(
                    color: isPositive
                        ? const Color(0xFF81C784)
                        : const Color(0xFFEF5350),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: 48,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'admin_modern_dashboard_revenue_chart'.tr(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'admin_modern_dashboard_revenue_chart_placeholder'.tr(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSourceCard(String title, int percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            '$percentage%',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    if (_recentTransactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'admin_modern_dashboard_no_recent_transactions'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'admin_modern_dashboard_transactions_placeholder'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _recentTransactions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getTransactionStatusColor(transaction.status)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTransactionIcon(transaction.type),
                  color: _getTransactionStatusColor(transaction.status),
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.formattedAmount,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      transaction.displayType,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    if (transaction.itemTitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        transaction.itemTitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    transaction.userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    transaction.timeAgo,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getTransactionStatusColor(transaction.status)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      transaction.status.toUpperCase(),
                      style: TextStyle(
                        color: _getTransactionStatusColor(transaction.status),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinancialInsightCard(
      String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HELPER METHODS ====================
  BoxDecoration _buildGlassDecoration() {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  Widget _buildModernButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool isPrimary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.3),
                  Colors.white.withValues(alpha: 0.1),
                ],
              )
            : null,
        color: isPrimary ? null : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'user':
        return Icons.person_rounded;
      case 'content':
        return Icons.content_copy_rounded;
      case 'system':
        return Icons.settings_rounded;
      case 'security':
        return Icons.security_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _getActivityColor(String type) {
    switch (type.toLowerCase()) {
      case 'user':
        return const Color(0xFF4FC3F7);
      case 'content':
        return const Color(0xFF81C784);
      case 'system':
        return const Color(0xFFFFB74D);
      case 'security':
        return const Color(0xFFE57373);
      default:
        return const Color(0xFFBA68C8);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '\$${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return '\$${amount.toStringAsFixed(0)}';
    }
  }

  Color _getTransactionStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF81C784);
      case 'pending':
        return const Color(0xFFFFB74D);
      case 'failed':
        return const Color(0xFFEF5350);
      case 'refunded':
        return const Color(0xFF64B5F6);
      default:
        return Colors.white;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'subscription':
        return Icons.subscriptions_rounded;
      case 'artwork_purchase':
        return Icons.palette_rounded;
      case 'event_ticket':
        return Icons.event_rounded;
      case 'ad_payment':
        return Icons.campaign_rounded;
      case 'commission':
        return Icons.handshake_rounded;
      default:
        return Icons.payments_rounded;
    }
  }
}

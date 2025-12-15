import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
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
  final RecentActivityService _activityService = RecentActivityService();
  final EnhancedAnalyticsService _analyticsService = EnhancedAnalyticsService();
  final ConsolidatedAdminService _consolidatedService =
      ConsolidatedAdminService();
  final AdminService _adminService = AdminService();
  final ContentReviewService _contentService = ContentReviewService();
  final UnifiedAdminService _unifiedAdminService = UnifiedAdminService();
  final FinancialService _financialService = FinancialService();

  // Data
  AnalyticsModel? _analytics;
  List<RecentActivityModel> _recentActivities = [];
  List<UserAdminModel> _users = [];
  List<ContentReviewModel> _pendingReviews = [];
  List<ContentModel> _allContent = [];
  List<TransactionModel> _recentTransactions = [];
  Map<String, double> _revenueBreakdown = {};

  // State
  bool _isLoading = true;
  String? _error;

  // Search controllers for future use
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _contentSearchController =
      TextEditingController();

  // Content filter state
  String _selectedContentFilter = 'All';

  @override
  void initState() {
    super.initState();
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
      _animationController.forward();
    } catch (e) {
      setState(() {
        _error = 'Failed to load admin data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
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

      setState(() {
        _analytics = analytics;
        _recentActivities = activities;
        _recentTransactions = transactions;
        _revenueBreakdown = revenueBreakdown;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load dashboard data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    final users = await _adminService.getAllUsers();
    setState(() {
      _users = users;
    });
  }

  Future<void> _loadContentData() async {
    final pendingReviews = await _contentService.getPendingReviews();
    final allContent = await _unifiedAdminService.getAllContent();
    setState(() {
      _pendingReviews = pendingReviews;
      _allContent = allContent;
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
      title: 'Admin Command Center',
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
            tooltip: 'Refresh Data',
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
            _buildModernTab('Dashboard', Icons.dashboard_rounded),
            _buildModernTab('Users', Icons.people_rounded),
            _buildModernTab('Content', Icons.content_copy_rounded),
            _buildModernTab('Financial', Icons.analytics_rounded),
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
            'Loading admin data...',
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
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildModernButton(
              'Try Again',
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
              const Expanded(
                child: Text(
                  'Performance Overview',
                  style: TextStyle(
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
                    'Total Users',
                    _users.length.toString(),
                    Icons.people_rounded,
                    const Color(0xFF4FC3F7),
                    '+12%',
                    true,
                  ),
                  _buildModernKPICard(
                    'Pending Reviews',
                    _pendingReviews.length.toString(),
                    Icons.rate_review_rounded,
                    const Color(0xFFFFB74D),
                    '${_pendingReviews.length > 10 ? 'High' : 'Normal'}',
                    _pendingReviews.length <= 10,
                  ),
                  _buildModernKPICard(
                    'Total Content',
                    _allContent.length.toString(),
                    Icons.content_copy_rounded,
                    const Color(0xFF81C784),
                    '+8%',
                    true,
                  ),
                  _buildModernKPICard(
                    'Revenue',
                    _analytics?.financialMetrics != null
                        ? _formatCurrency(
                            _analytics!.financialMetrics.totalRevenue)
                        : '\$0',
                    Icons.trending_up_rounded,
                    const Color(0xFFBA68C8),
                    '+15%',
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
              const Expanded(
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
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
                'Review Content',
                'Moderate pending submissions',
                Icons.rate_review_rounded,
                const Color(0xFFFFB74D),
                () => _mainTabController.animateTo(2),
                badge: _pendingReviews.isNotEmpty
                    ? _pendingReviews.length.toString()
                    : null,
              ),
              _buildModernActionCard(
                'Manage Users',
                'User administration tools',
                Icons.people_rounded,
                const Color(0xFF4FC3F7),
                () => _mainTabController.animateTo(1),
              ),
              _buildModernActionCard(
                'Financial Reports',
                'Revenue and analytics',
                Icons.analytics_rounded,
                const Color(0xFFBA68C8),
                () => _mainTabController.animateTo(3),
              ),
              _buildModernActionCard(
                'System Settings',
                'Configure platform settings',
                Icons.settings_rounded,
                const Color(0xFF81C784),
                () => Navigator.pushNamed(context, '/admin/settings'),
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
              const Expanded(
                child: Text(
                  'Recent Activity',
                  style: TextStyle(
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
                    'No recent activity',
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
              const Expanded(
                child: Text(
                  'System Health',
                  style: TextStyle(
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
                  'Database', true, Icons.storage_rounded),
              const SizedBox(height: 12),
              _buildModernHealthIndicator(
                  'API Services', true, Icons.api_rounded),
              const SizedBox(height: 12),
              _buildModernHealthIndicator(
                  'File Storage', true, Icons.cloud_rounded),
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
          SizedBox(
            width: 70,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isHealthy ? 'Healthy' : 'Error',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
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
                      const Text(
                        'User Management',
                        style: TextStyle(
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
                            'Total Users',
                            _users.length.toString(),
                            Icons.people_rounded,
                            const Color(0xFF4FC3F7),
                          ),
                          _buildUserStatCard(
                            'Verified Users',
                            _users.where((u) => u.isVerified).length.toString(),
                            Icons.verified_rounded,
                            const Color(0xFF81C784),
                          ),
                          _buildUserStatCard(
                            'Featured Users',
                            _users.where((u) => u.isFeatured).length.toString(),
                            Icons.star_rounded,
                            const Color(0xFFFFB74D),
                          ),
                          _buildUserStatCard(
                            'Suspended Users',
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
                      hintText: 'Search users by name, email, or username...',
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
                        _buildFilterChip('All', _getFilteredUsers().length),
                        const SizedBox(width: 8),
                        _buildFilterChip('Verified',
                            _users.where((u) => u.isVerified).length),
                        const SizedBox(width: 8),
                        _buildFilterChip('Featured',
                            _users.where((u) => u.isFeatured).length),
                        const SizedBox(width: 8),
                        _buildFilterChip('Suspended',
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
        '$label ($count)',
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
                        'Joined ${_formatDate(user.createdAt)}',
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
                      const Text(
                        'Content Moderation',
                        style: TextStyle(
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
                          ? 5
                          : (constraints.maxWidth > 600 ? 4 : 2);
                      return GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                        children: [
                          _buildContentStatCard(
                            'Total Content',
                            _allContent.length.toString(),
                            Icons.content_copy_rounded,
                            const Color(0xFF4FC3F7),
                          ),
                          _buildContentStatCard(
                            'Pending Reviews',
                            _pendingReviews.length.toString(),
                            Icons.rate_review_rounded,
                            const Color(0xFFFFB74D),
                          ),
                          _buildContentStatCard(
                            'Approved',
                            _allContent
                                .where((c) => c.status == 'approved')
                                .length
                                .toString(),
                            Icons.check_circle_rounded,
                            const Color(0xFF81C784),
                          ),
                          _buildContentStatCard(
                            'Rejected',
                            _allContent
                                .where((c) => c.status == 'rejected')
                                .length
                                .toString(),
                            Icons.cancel_rounded,
                            const Color(0xFFEF5350),
                          ),
                          _buildContentStatCard(
                            'Reported',
                            _allContent
                                .where((c) => c.status == 'flagged')
                                .length
                                .toString(),
                            Icons.flag_rounded,
                            const Color(0xFFFF5722),
                          ),
                        ],
                      );
                    },
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
                          'Search content by title, author, or description...',
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
                            'All', _getFilteredContent().length),
                        const SizedBox(width: 8),
                        _buildContentFilterChip(
                            'Pending', _pendingReviews.length),
                        const SizedBox(width: 8),
                        _buildContentFilterChip(
                            'Approved',
                            _allContent
                                .where((c) => c.status == 'approved')
                                .length),
                        const SizedBox(width: 8),
                        _buildContentFilterChip(
                            'Rejected',
                            _allContent
                                .where((c) => c.status == 'rejected')
                                .length),
                        const SizedBox(width: 8),
                        _buildContentFilterChip(
                            'Reported',
                            _allContent
                                .where((c) => c.status == 'flagged')
                                .length),
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
                    const Text(
                      'Pending Reviews',
                      style: TextStyle(
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
                  const Text(
                    'Recent Content',
                    style: TextStyle(
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
          '$label ($count)',
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

    // First filter by status
    List<ContentModel> filteredByStatus = _allContent;
    if (_selectedContentFilter != 'All') {
      switch (_selectedContentFilter) {
        case 'Pending':
          final pendingContentIds =
              _pendingReviews.map((r) => r.contentId).toSet();
          filteredByStatus = _allContent
              .where((c) => pendingContentIds.contains(c.id))
              .toList();
          break;
        case 'Approved':
          filteredByStatus =
              _allContent.where((c) => c.status == 'approved').toList();
          break;
        case 'Rejected':
          filteredByStatus =
              _allContent.where((c) => c.status == 'rejected').toList();
          break;
        case 'Reported':
          filteredByStatus =
              _allContent.where((c) => c.status == 'flagged').toList();
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
                child: const Text(
                  'PENDING',
                  style: TextStyle(
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
            'By ${review.authorName}',
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
                        'By ${content.authorName}',
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
              const PopupMenuItem(
                value: 'view',
                child:
                    Text('View Details', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'edit',
                child:
                    Text('Edit Content', style: TextStyle(color: Colors.white)),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete Content',
                    style: TextStyle(color: Colors.white)),
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
      await _unifiedAdminService.approveContent(review.contentId);

      // Trigger rewards if it's a capture
      if (review.contentType == 'capture') {
        await _triggerCaptureApprovalRewards(review);
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

  /// Trigger rewards when a capture is approved
  Future<void> _triggerCaptureApprovalRewards(ContentReviewModel review) async {
    try {
      // Get the capture document to find the author
      final captureDoc = await FirebaseFirestore.instance
          .collection('captures')
          .doc(review.contentId)
          .get();

      if (captureDoc.exists) {
        final captureData = captureDoc.data()!;
        final authorId = captureData['userId'] as String?;

        if (authorId != null) {
          // Award XP and update stats for capture approval
          await FirebaseFirestore.instance
              .collection('users')
              .doc(authorId)
              .update({
            'experiencePoints': FieldValue.increment(
                25), // Additional 25 XP for approval (total 50)
            'stats.capturesApproved': FieldValue.increment(1),
          });

          AppLogger.info(
              '🎉 Awarded capture approval rewards to user: $authorId');
        }
      }
    } catch (e) {
      AppLogger.error('Failed to trigger capture approval rewards: $e');
      // Don't throw - approval should still succeed even if rewards fail
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
      await _unifiedAdminService.rejectContent(review.contentId,
          reason: 'Rejected by admin');

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
                        const Text(
                          'Media',
                          style: TextStyle(
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
                        const Text(
                          'Description',
                          style: TextStyle(
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
                      _buildDetailRow('Author', content.authorName),
                      _buildDetailRow(
                          'Created', _formatDate(content.createdAt)),
                      if (content.updatedAt != null)
                        _buildDetailRow(
                            'Updated', _formatDate(content.updatedAt!)),

                      // Stats
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStatChip('Views', content.viewCount.toString()),
                          const SizedBox(width: 12),
                          _buildStatChip('Likes', content.likeCount.toString()),
                          const SizedBox(width: 12),
                          _buildStatChip(
                              'Reports', content.reportCount.toString()),
                        ],
                      ),

                      // Tags
                      if (content.tags.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Tags',
                          style: TextStyle(
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
                                        content: const Text(
                                            'Review cleared successfully'),
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
        '$label: $value',
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
              const Text(
                'Edit Content',
                style: TextStyle(
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
                const Text(
                  'Title',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter title',
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
                const Text(
                  'Description',
                  style: TextStyle(
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
                    hintText: 'Enter description',
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
                const Text(
                  'Status',
                  style: TextStyle(
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
                  items: ['active', 'pending', 'rejected', 'archived']
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
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
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
        title: const Row(
          children: [
            Icon(
              Icons.warning_rounded,
              color: Colors.red,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Delete Content',
              style: TextStyle(
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
              'Are you sure you want to delete this ${content.type}?',
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
                    'by ${content.authorName}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white),
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
      // Update in Firestore based on content type
      final collection = _getCollectionForContentType(content.type);
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(content.id)
          .update({
        'title': newTitle,
        'description': newDescription,
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

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
      // Delete from Firestore based on content type
      final collection = _getCollectionForContentType(content.type);
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(content.id)
          .delete();

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

  String _getCollectionForContentType(String type) {
    switch (type.toLowerCase()) {
      case 'artwork':
        return 'artworks';
      case 'post':
        return 'posts';
      case 'event':
        return 'events';
      case 'ad':
        return 'advertisements';
      default:
        return 'content';
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
                      const Text(
                        'Financial Analytics',
                        style: TextStyle(
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
                            'Total Revenue',
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
                            'Monthly Recurring',
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
                            'Total Transactions',
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
                            'Avg Transaction',
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
                  const Text(
                    'Revenue Breakdown',
                    style: TextStyle(
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
                          'Advertisements',
                          _revenueBreakdown['Advertisements']?.round() ?? 0,
                          const Color(0xFF4FC3F7),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildRevenueSourceCard(
                          'Subscriptions',
                          _revenueBreakdown['Subscriptions']?.round() ?? 0,
                          const Color(0xFF81C784),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildRevenueSourceCard(
                          'Artwork Sales',
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
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(
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
                  const Text(
                    'Financial Insights',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFinancialInsightCard(
                    'Revenue Growth',
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
                    'Transaction Volume',
                    _analytics?.financialMetrics != null
                        ? '${_analytics!.financialMetrics.totalTransactions} transactions processed'
                        : 'Transaction data will appear here',
                    Icons.receipt_long_rounded,
                    const Color(0xFF4FC3F7),
                  ),
                  const SizedBox(height: 12),
                  _buildFinancialInsightCard(
                    'Average Revenue',
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
            'Revenue Chart',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chart visualization will be implemented\nwith real Firebase data using fl_chart',
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
              'No Recent Transactions',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Transaction data will appear here once payments are processed.',
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

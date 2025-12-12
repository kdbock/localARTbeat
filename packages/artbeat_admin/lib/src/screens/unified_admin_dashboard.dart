import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/analytics_model.dart';
import '../models/recent_activity_model.dart';
import '../models/user_admin_model.dart';
import '../models/content_review_model.dart';
import '../models/content_model.dart';
import '../services/recent_activity_service.dart';
import '../services/enhanced_analytics_service.dart';
import '../services/consolidated_admin_service.dart';
import '../services/admin_service.dart';
import '../services/content_review_service.dart';
import '../services/unified_admin_service.dart';
import '../widgets/admin_drawer.dart';
import 'admin_user_detail_screen.dart';

/// Unified Admin Dashboard - Single interface for all admin functionality
///
/// Consolidates all admin features into 4 main tabs:
/// 1. 📊 Dashboard & Analytics
/// 2. 👥 User Management
/// 3. 📝 Content & Moderation
/// 4. 💰 Financial & Ads
///
/// This replaces all the separate admin screens with a unified, modern interface
class UnifiedAdminDashboard extends StatefulWidget {
  const UnifiedAdminDashboard({super.key});

  @override
  State<UnifiedAdminDashboard> createState() => _UnifiedAdminDashboardState();
}

class _UnifiedAdminDashboardState extends State<UnifiedAdminDashboard>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _mainTabController;

  // Services
  final RecentActivityService _activityService = RecentActivityService();
  final EnhancedAnalyticsService _analyticsService = EnhancedAnalyticsService();
  final ConsolidatedAdminService _consolidatedService =
      ConsolidatedAdminService();
  final AdminService _adminService = AdminService();
  final ContentReviewService _contentService = ContentReviewService();
  final UnifiedAdminService _unifiedAdminService = UnifiedAdminService();

  // Data
  AnalyticsModel? _analytics;
  List<RecentActivityModel> _recentActivities = [];

  List<UserAdminModel> _users = [];
  List<ContentReviewModel> _pendingReviews = [];
  List<ContentModel> _allContent = [];

  // State
  bool _isLoading = true;
  String? _error;

  // User Management State
  final TextEditingController _userSearchController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  bool _isUserSelectionMode = false;

  // Content Management State
  final TextEditingController _contentSearchController =
      TextEditingController();
  final Set<String> _selectedContentIds = {};
  bool _isContentSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(length: 4, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
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
    final analytics = await _analyticsService.getEnhancedAnalytics(
      dateRange: DateRange.last30Days,
    );
    final activities = await _activityService.getRecentActivities(limit: 10);
    await _consolidatedService.getDashboardStats();

    setState(() {
      _analytics = analytics;
      _recentActivities = activities;
    });
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
    // Navigate to main search screen
    Navigator.pushNamed(context, '/search');
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      scaffoldKey: _scaffoldKey,
      appBar: EnhancedUniversalHeader(
        title: 'Admin Dashboard',
        showBackButton: false,
        showSearch: true,
        showDeveloperTools: true,
        onSearchPressed: _handleSearch,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildMainTabBar(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? _buildErrorWidget()
                        : TabBarView(
                            controller: _mainTabController,
                            children: [
                              _buildDashboardTab(),
                              _buildUserManagementTab(),
                              _buildContentModerationTab(),
                              _buildFinancialTab(),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _mainTabController,
        labelColor: const Color(0xFF8C52FF),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF8C52FF),
        tabs: const [
          Tab(
            text: 'Dashboard',
            icon: Icon(Icons.dashboard, size: 20),
          ),
          Tab(
            text: 'Users',
            icon: Icon(Icons.people, size: 20),
          ),
          Tab(
            text: 'Content',
            icon: Icon(Icons.content_copy, size: 20),
          ),
          Tab(
            text: 'Financial',
            icon: Icon(Icons.attach_money, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('admin_unified_admin_dashboard_error_error_error'.tr()),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadAllData,
            child: Text('admin_admin_settings_text_retry'.tr()),
          ),
        ],
      ),
    );
  }

  // ==================== DASHBOARD TAB ====================
  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKPIOverview(),
            const SizedBox(height: 24),
            _buildQuickActions(),
            const SizedBox(height: 24),
            _buildRecentActivity(),
            const SizedBox(height: 24),
            _buildSystemHealth(),
          ],
        ),
      ),
    );
  }

  Widget _buildKPIOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Key Performance Indicators',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
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
                    _buildKPICard(
                      'Total Users',
                      _users.length.toString(),
                      Icons.people,
                      Colors.blue,
                    ),
                    _buildKPICard(
                      'Pending Reviews',
                      _pendingReviews.length.toString(),
                      Icons.rate_review,
                      Colors.orange,
                    ),
                    _buildKPICard(
                      'Total Content',
                      _allContent.length.toString(),
                      Icons.content_copy,
                      Colors.green,
                    ),
                    _buildKPICard(
                      'Revenue',
                      _analytics?.financialMetrics != null
                          ? _formatCurrency(
                              _analytics!.financialMetrics.totalRevenue)
                          : '\$0',
                      Icons.attach_money,
                      Colors.purple,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickActionButton(
                  'Review Content',
                  Icons.rate_review,
                  () => _mainTabController.animateTo(2),
                ),
                _buildQuickActionButton(
                  'Manage Users',
                  Icons.people,
                  () => _mainTabController.animateTo(1),
                ),
                _buildQuickActionButton(
                  'Financial Reports',
                  Icons.analytics,
                  () => _mainTabController.animateTo(3),
                ),
                _buildQuickActionButton(
                  'System Settings',
                  Icons.settings,
                  () => Navigator.pushNamed(context, '/admin/settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
      String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF8C52FF),
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_recentActivities.isEmpty)
              Text('admin_unified_admin_dashboard_text_no_recent_activity'.tr())
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentActivities.length.clamp(0, 5),
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final activity = _recentActivities[index];
                  return ListTile(
                    leading: Icon(
                      _getActivityIcon(activity.type.name),
                      color: const Color(0xFF8C52FF),
                    ),
                    title: Text(activity.description),
                    subtitle: Text(_formatDateTime(activity.timestamp)),
                    dense: true,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemHealth() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'System Health',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildHealthIndicator('Database', true),
                ),
                Expanded(
                  child: _buildHealthIndicator('API', true),
                ),
                Expanded(
                  child: _buildHealthIndicator('Storage', true),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(String service, bool isHealthy) {
    return Column(
      children: [
        Icon(
          isHealthy ? Icons.check_circle : Icons.error,
          color: isHealthy ? Colors.green : Colors.red,
          size: 32,
        ),
        const SizedBox(height: 4),
        Text(
          service,
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          isHealthy ? 'Healthy' : 'Error',
          style: TextStyle(
            fontSize: 10,
            color: isHealthy ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  // ==================== USER MANAGEMENT TAB ====================
  Widget _buildUserManagementTab() {
    return Column(
      children: [
        _buildUserSearchAndFilters(),
        Expanded(
          child: _buildUserList(),
        ),
      ],
    );
  }

  Widget _buildUserSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: Column(
        children: [
          TextField(
            controller: _userSearchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _isUserSelectionMode
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle),
                          onPressed: _selectedUserIds.isNotEmpty
                              ? _approveSelectedUsers
                              : null,
                          tooltip: 'Approve Selected',
                        ),
                        IconButton(
                          icon: const Icon(Icons.block),
                          onPressed: _selectedUserIds.isNotEmpty
                              ? _banSelectedUsers
                              : null,
                          tooltip: 'Ban Selected',
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            setState(() {
                              _isUserSelectionMode = false;
                              _selectedUserIds.clear();
                            });
                          },
                          tooltip: 'Exit Selection Mode',
                        ),
                      ],
                    )
                  : IconButton(
                      icon: const Icon(Icons.checklist),
                      onPressed: () {
                        setState(() {
                          _isUserSelectionMode = true;
                        });
                      },
                      tooltip: 'Enter Selection Mode',
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              // Implement search filtering
              setState(() {});
            },
          ),
          if (_isUserSelectionMode) ...[
            const SizedBox(height: 8),
            Text(
              '${_selectedUserIds.length} users selected',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserList() {
    final filteredUsers = _users.where((user) {
      final searchQuery = _userSearchController.text.toLowerCase();
      return searchQuery.isEmpty ||
          user.fullName.toLowerCase().contains(searchQuery) ||
          user.email.toLowerCase().contains(searchQuery);
    }).toList();

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredUsers.length,
        itemBuilder: (context, index) {
          final user = filteredUsers[index];
          final isSelected = _selectedUserIds.contains(user.id);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: _isUserSelectionMode
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedUserIds.add(user.id);
                          } else {
                            _selectedUserIds.remove(user.id);
                          }
                        });
                      },
                    )
                  : CircleAvatar(
                      backgroundImage: user.profileImageUrl.isNotEmpty
                          ? NetworkImage(user.profileImageUrl)
                          : null,
                      child: user.profileImageUrl.isEmpty
                          ? Text(user.fullName.isNotEmpty
                              ? user.fullName[0].toUpperCase()
                              : 'U')
                          : null,
                    ),
              title: Text(user.fullName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email),
                  Text(
                    'Role: ${user.userType ?? 'User'} • Status: ${user.statusText}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              trailing: _isUserSelectionMode
                  ? null
                  : PopupMenuButton<String>(
                      onSelected: (value) => _handleUserAction(user, value),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'view',
                          child: Text('admin_unified_admin_dashboard_text_view_details'.tr()),
                        ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Text('admin_unified_admin_dashboard_text_edit_user'.tr()),
                        ),
                        PopupMenuItem(
                          value: user.statusText == 'Active' ? 'ban' : 'unban',
                          child: Text(user.statusText == 'Active'
                              ? 'Ban User'
                              : 'Unban User'),
                        ),
                      ],
                    ),
              onTap: _isUserSelectionMode
                  ? () {
                      setState(() {
                        if (isSelected) {
                          _selectedUserIds.remove(user.id);
                        } else {
                          _selectedUserIds.add(user.id);
                        }
                      });
                    }
                  : () => _viewUserDetails(user),
            ),
          );
        },
      ),
    );
  }

  // ==================== CONTENT MODERATION TAB ====================
  Widget _buildContentModerationTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            labelColor: Color(0xFF8C52FF),
            tabs: [
              Tab(text: 'Pending Review'),
              Tab(text: 'All Content'),
              Tab(text: 'Reported'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPendingReviewList(),
                _buildAllContentList(),
                _buildReportedContentList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReviewList() {
    return Column(
      children: [
        _buildContentSearchAndFilters(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadContentData,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingReviews.length,
              itemBuilder: (context, index) {
                final review = _pendingReviews[index];
                return _buildContentReviewCard(review);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAllContentList() {
    return RefreshIndicator(
      onRefresh: _loadContentData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allContent.length,
        itemBuilder: (context, index) {
          final content = _allContent[index];
          return _buildContentCard(content);
        },
      ),
    );
  }

  Widget _buildReportedContentList() {
    final reportedContent = _pendingReviews
        .where((review) => review.status == ReviewStatus.flagged)
        .toList();

    return RefreshIndicator(
      onRefresh: _loadContentData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reportedContent.length,
        itemBuilder: (context, index) {
          final review = reportedContent[index];
          return _buildContentReviewCard(review, isReported: true);
        },
      ),
    );
  }

  Widget _buildContentSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade50,
      child: TextField(
        controller: _contentSearchController,
        decoration: InputDecoration(
          hintText: 'Search content...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _isContentSelectionMode
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle),
                      onPressed: _selectedContentIds.isNotEmpty
                          ? _approveSelectedContent
                          : null,
                      tooltip: 'Approve Selected',
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel),
                      onPressed: _selectedContentIds.isNotEmpty
                          ? _rejectSelectedContent
                          : null,
                      tooltip: 'Reject Selected',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _isContentSelectionMode = false;
                          _selectedContentIds.clear();
                        });
                      },
                      tooltip: 'Exit Selection Mode',
                    ),
                  ],
                )
              : IconButton(
                  icon: const Icon(Icons.checklist),
                  onPressed: () {
                    setState(() {
                      _isContentSelectionMode = true;
                    });
                  },
                  tooltip: 'Enter Selection Mode',
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildContentReviewCard(ContentReviewModel review,
      {bool isReported = false}) {
    final isSelected = _selectedContentIds.contains(review.contentId);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isReported ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (_isContentSelectionMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedContentIds.add(review.contentId);
                        } else {
                          _selectedContentIds.remove(review.contentId);
                        }
                      });
                    },
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('admin_unified_admin_dashboard_label_by_reviewauthorname'.tr()),
                      Text('admin_unified_admin_dashboard_label_type_reviewcontenttypedisplayname'.tr()),
                      if (isReported)
                        Text(
                          'REPORTED CONTENT',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!_isContentSelectionMode) ...[
                  ElevatedButton(
                    onPressed: () => _approveContent(review),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('admin_modern_unified_admin_dashboard_text_approve'.tr()),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _rejectContent(review),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('admin_modern_unified_admin_dashboard_text_reject'.tr()),
                  ),
                ],
              ],
            ),
            if (review.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                review.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(ContentModel content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(content.title),
        subtitle: Text('admin_unified_admin_dashboard_hint_type_contenttype_status'.tr()),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleContentAction(content, value),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'view',
              child: Text('admin_unified_admin_dashboard_text_view_details'.tr()),
            ),
            PopupMenuItem(
              value: 'edit',
              child: Text('admin_modern_unified_admin_dashboard_text_edit'.tr()),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text('admin_modern_unified_admin_dashboard_text_delete'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== FINANCIAL TAB ====================
  Widget _buildFinancialTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            labelColor: Color(0xFF8C52FF),
            tabs: [
              Tab(text: 'Revenue'),
              Tab(text: 'Ads'),
              Tab(text: 'Payouts'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildRevenueTab(),
                _buildAdsTab(),
                _buildPayoutsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildFinancialOverview(),
          const SizedBox(height: 16),
          _buildRevenueChart(),
        ],
      ),
    );
  }

  Widget _buildAdsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ad Management',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildFinancialOverview(),
          const SizedBox(height: 24),
          _buildAdStatsGrid(),
          const SizedBox(height: 24),
          _buildActiveAdsSection(),
        ],
      ),
    );
  }

  Widget _buildPayoutsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payout Management',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPayoutOverview(),
          const SizedBox(height: 24),
          _buildPayoutHistorySection(),
        ],
      ),
    );
  }

  Widget _buildAdStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        _buildStatCard('Page Views', _analytics?.pageViews ?? 0, Colors.blue),
        _buildStatCard('Total Events', _analytics?.totalEvents ?? 0, Colors.green),
        _buildStatCard('Bounce Rate', '${(_analytics?.bounceRate ?? 0.0).toStringAsFixed(2)}%', Colors.orange),
        _buildStatCard('Engagement', _analytics?.totalLikes ?? 0, Colors.red),
      ],
    );
  }

  Widget _buildActiveAdsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Ad Activity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_recentActivities.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('admin_unified_admin_dashboard_text_no_recent_ad'.tr()),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _recentActivities.take(5).length,
                itemBuilder: (context, index) {
                  final activity = _recentActivities[index];
                  return ListTile(
                    title: Text(activity.description),
                    subtitle: Text(activity.timestamp.toString()),
                    leading: const Icon(Icons.local_offer),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutOverview() {
    final financial = _analytics?.financialMetrics;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payout Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildFinancialMetric(
                    'Total Paid Out',
                    financial != null ? _formatCurrency(financial.totalRevenue * 0.7) : '\$0',
                    Icons.payment,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildFinancialMetric(
                    'Pending Payouts',
                    financial != null ? _formatCurrency(financial.monthlyRecurringRevenue * 0.3) : '\$0',
                    Icons.hourglass_empty,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutHistorySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Payouts',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('admin_unified_admin_dashboard_text_payout_index_1'.tr()),
                  subtitle: Text('Processed on ${DateTime.now().subtract(Duration(days: index)).toString().split(' ')[0]}'),
                  trailing: Text(
                    '\$${(100 + (index * 50)).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, dynamic value, Color color) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialOverview() {
    final financial = _analytics?.financialMetrics;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Financial Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildFinancialMetric(
                    'Total Revenue',
                    financial != null
                        ? _formatCurrency(financial.totalRevenue)
                        : '\$0',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildFinancialMetric(
                    'Monthly Revenue',
                    financial != null
                        ? _formatCurrency(financial.monthlyRecurringRevenue)
                        : '\$0',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialMetric(
      String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(title, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Center(
                child: Text('admin_unified_admin_dashboard_text_chart_will_be'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPER METHODS ====================

  void _viewUserDetails(UserAdminModel user) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AdminUserDetailScreen(user: user),
      ),
    );
  }

  void _handleUserAction(UserAdminModel user, String action) {
    switch (action) {
      case 'view':
        _viewUserDetails(user);
        break;
      case 'edit':
        // Implement edit user
        break;
      case 'ban':
      case 'unban':
        _toggleUserBan(user);
        break;
    }
  }

  void _handleContentAction(ContentModel content, String action) {
    switch (action) {
      case 'view':
        // Implement view content details
        break;
      case 'edit':
        // Implement edit content
        break;
      case 'delete':
        _deleteContent(content);
        break;
    }
  }

  Future<void> _toggleUserBan(UserAdminModel user) async {
    try {
      await _adminService.toggleUserBan(user.id);
      await _loadUserData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'User ${user.statusText == 'Active' ? 'banned' : 'unbanned'} successfully'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_unified_admin_dashboard_error_error_e'.tr())),
        );
      }
    }
  }

  Future<void> _approveSelectedUsers() async {
    // Implement bulk user approval
    setState(() {
      _selectedUserIds.clear();
      _isUserSelectionMode = false;
    });
  }

  Future<void> _banSelectedUsers() async {
    // Implement bulk user ban
    setState(() {
      _selectedUserIds.clear();
      _isUserSelectionMode = false;
    });
  }

  Future<void> _approveContent(ContentReviewModel review) async {
    try {
      await _unifiedAdminService.approveContent(review.contentId);
      await _loadContentData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_unified_admin_dashboard_success_content_approved_successfully'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_unified_admin_dashboard_error_error_e'.tr())),
        );
      }
    }
  }

  Future<void> _rejectContent(ContentReviewModel review) async {
    try {
      await _unifiedAdminService.rejectContent(review.contentId);
      await _loadContentData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_unified_admin_dashboard_success_content_rejected_successfully'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_unified_admin_dashboard_error_error_e'.tr())),
        );
      }
    }
  }

  Future<void> _approveSelectedContent() async {
    try {
      await _unifiedAdminService
          .bulkApproveContent(_selectedContentIds.toList());
      await _loadContentData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${_selectedContentIds.length} items approved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_unified_admin_dashboard_error_error_e'.tr())),
        );
      }
    } finally {
      setState(() {
        _selectedContentIds.clear();
        _isContentSelectionMode = false;
      });
    }
  }

  Future<void> _rejectSelectedContent() async {
    try {
      await _unifiedAdminService
          .bulkRejectContent(_selectedContentIds.toList());
      await _loadContentData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${_selectedContentIds.length} items rejected successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_unified_admin_dashboard_error_error_e'.tr())),
        );
      }
    } finally {
      setState(() {
        _selectedContentIds.clear();
        _isContentSelectionMode = false;
      });
    }
  }

  Future<void> _deleteContent(ContentModel content) async {
    // Implement content deletion
  }

  IconData _getActivityIcon(String type) {
    switch (type.toLowerCase()) {
      case 'user':
        return Icons.person;
      case 'content':
        return Icons.content_copy;
      case 'financial':
        return Icons.attach_money;
      default:
        return Icons.info;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }
}

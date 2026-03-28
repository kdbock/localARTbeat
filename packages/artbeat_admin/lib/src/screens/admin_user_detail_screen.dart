import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/user_admin_model.dart';
import '../widgets/admin_drawer.dart';
import '../services/admin_service.dart';
import '../services/recent_activity_service.dart';
import '../services/audit_trail_service.dart';
import '../models/recent_activity_model.dart';

/// Detailed view of a user for admin management
class AdminUserDetailScreen extends StatefulWidget {
  final UserAdminModel user;

  const AdminUserDetailScreen({
    super.key,
    required this.user,
  });

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen>
    with SingleTickerProviderStateMixin {
  late RecentActivityService _activityService;
  late AdminService _adminService;
  late AuditTrailService _auditTrailService;
  late UserService _userService;
  late TabController _tabController;
  late UserAdminModel _currentUser;
  List<RecentActivityModel> _userActivities = [];
  bool _isLoading = false;
  bool _isActivitiesLoading = false;
  bool _isEditing = false;
  late TextEditingController _fullNameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _zipCodeController;

  @override
  void initState() {
    super.initState();
    _activityService = context.read<RecentActivityService>();
    _adminService = context.read<AdminService>();
    _auditTrailService = context.read<AuditTrailService>();
    _userService = context.read<UserService>();
    _tabController = TabController(length: 4, vsync: this);
    _currentUser = widget.user;

    // Initialize text controllers
    _fullNameController = TextEditingController(text: _currentUser.fullName);
    _usernameController = TextEditingController(text: _currentUser.username);
    _emailController = TextEditingController(text: _currentUser.email);
    _bioController = TextEditingController(text: _currentUser.bio);
    _locationController = TextEditingController(text: _currentUser.location);
    _zipCodeController = TextEditingController(text: _currentUser.zipCode);

    _loadUserActivities();
  }

  Future<void> _loadUserActivities() async {
    setState(() => _isActivitiesLoading = true);
    try {
      final activities =
          await _activityService.getActivitiesByUser(_currentUser.id);
      setState(() {
        _userActivities = activities;
      });
    } catch (e) {
      debugPrint('Error loading user activities: $e');
    } finally {
      setState(() => _isActivitiesLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    // Navigate to main search screen
    Navigator.pushNamed(context, '/search');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AdminDrawer(),
      appBar: EnhancedUniversalHeader(
        title: 'admin_user_detail_title'.tr(),
        showBackButton: true,
        showSearch: true,
        showDeveloperTools: true,
        onSearchPressed: _handleSearch,
      ),
      body: Column(
        children: [
          Material(
            color: const Color(0xFF8C52FF), // Admin header color
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF00BF63), // Admin text/icon color
              unselectedLabelColor:
                  const Color(0xFF00BF63).withValues(alpha: 0.7),
              indicatorColor: const Color(0xFF00BF63),
              tabs: [
                Tab(text: 'admin_user_detail_tab_overview'.tr(), icon: const Icon(Icons.person)),
                Tab(text: 'admin_user_detail_tab_details'.tr(), icon: const Icon(Icons.info)),
                Tab(text: 'admin_user_detail_tab_activity'.tr(), icon: const Icon(Icons.history)),
                Tab(text: 'admin_user_detail_tab_admin'.tr(), icon: const Icon(Icons.admin_panel_settings)),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildDetailsTab(),
                      _buildActivityTab(),
                      _buildAdminTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: _getUserTypeColor(
                    _getUserTypeFromString(_currentUser.userType)),
                child: _currentUser.profileImageUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          _currentUser.profileImageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Text(
                            _currentUser.fullName.isNotEmpty
                                ? _currentUser.fullName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : Text(
                        _currentUser.fullName.isNotEmpty
                            ? _currentUser.fullName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser.fullName,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentUser.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildUserTypeChip(
                            _getUserTypeFromString(_currentUser.userType)),
                        const SizedBox(width: 8),
                        _buildStatusChip(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildStatCard(
                'admin_user_detail_stat_level'.tr(),
                _currentUser.level.toString(),
                Icons.star,
                Colors.orange,
              ),
              _buildStatCard(
                'admin_user_detail_stat_experience'.tr(),
                'admin_user_detail_stat_xp_value'
                    .tr(namedArgs: {'value': '${_currentUser.experiencePoints}'}),
                Icons.trending_up,
                Colors.green,
              ),
              _buildStatCard(
                'admin_user_detail_stat_followers'.tr(),
                _currentUser.followersCount.toString(),
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                'admin_user_detail_stat_following'.tr(),
                _currentUser.followingCount.toString(),
                Icons.person_add,
                Colors.purple,
              ),
              _buildStatCard(
                'admin_user_detail_stat_posts'.tr(),
                _currentUser.postsCount.toString(),
                Icons.post_add,
                Colors.teal,
              ),
              _buildStatCard(
                'admin_user_detail_stat_captures'.tr(),
                _currentUser.capturesCount.toString(),
                Icons.camera_alt,
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailSection('admin_user_detail_section_personal_information'.tr(), [
            _buildDetailRow('admin_user_detail_field_full_name'.tr(), _currentUser.fullName),
            _buildDetailRow(
                'admin_user_detail_field_username'.tr(),
                _currentUser.username.isEmpty
                    ? 'admin_user_detail_not_set'.tr()
                    : _currentUser.username),
            _buildDetailRow('admin_user_detail_field_email'.tr(), _currentUser.email),
            _buildDetailRow('admin_user_detail_field_location'.tr(), _currentUser.location),
            _buildDetailRow('admin_user_detail_field_zip_code'.tr(), _currentUser.zipCode ?? 'admin_user_detail_not_set'.tr()),
            _buildDetailRow('admin_user_detail_field_gender'.tr(), _currentUser.gender ?? 'admin_user_detail_not_set'.tr()),
            if (_currentUser.birthDate != null)
              _buildDetailRow('admin_user_detail_field_birth_date'.tr(),
                  '${_currentUser.birthDate!.day}/${_currentUser.birthDate!.month}/${_currentUser.birthDate!.year}'),
          ]),
          const SizedBox(height: 24),
          _buildDetailSection('admin_user_detail_section_account_information'.tr(), [
            _buildDetailRow(
                'admin_user_detail_field_user_type'.tr(),
                _getUserTypeFromString(_currentUser.userType)
                    .name
                    .toUpperCase()),
            _buildDetailRow('admin_user_detail_field_status'.tr(), _currentUser.statusText),
            _buildDetailRow('admin_user_detail_field_verified'.tr(), _currentUser.isVerified ? 'common_yes'.tr() : 'common_no'.tr()),
            _buildDetailRow(
                'admin_user_detail_field_created_at'.tr(), _formatDateTime(_currentUser.createdAt)),
            if (_currentUser.updatedAt != null)
              _buildDetailRow(
                  'admin_user_detail_field_updated_at'.tr(), _formatDateTime(_currentUser.updatedAt!)),
            if (_currentUser.lastActiveAt != null)
              _buildDetailRow(
                  'admin_user_detail_field_last_active'.tr(), _formatDateTime(_currentUser.lastActiveAt!)),
            if (_currentUser.lastLoginAt != null)
              _buildDetailRow(
                  'admin_user_detail_field_last_login'.tr(), _formatDateTime(_currentUser.lastLoginAt!)),
          ]),
          if (_currentUser.bio.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildDetailSection('admin_user_detail_section_biography'.tr(), [
              Text(_currentUser.bio),
            ]),
          ],
          if (_currentUser.achievements.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildDetailSection('admin_user_detail_section_achievements'.tr(), [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _currentUser.achievements
                    .map((achievement) => Chip(
                          label: Text(achievement),
                          backgroundColor: Colors.amber.shade100,
                        ))
                    .toList(),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return RefreshIndicator(
      onRefresh: _loadUserActivities,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'admin_user_detail_activity_history'.tr(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (_isActivitiesLoading)
              const Center(child: CircularProgressIndicator())
            else if (_userActivities.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.history,
                            size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('admin_user_detail_no_recent_activity'.tr(),
                            style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _userActivities.length,
                itemBuilder: (context, index) {
                  final activity = _userActivities[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getActivityColor(activity.type)
                            .withValues(alpha: 0.1),
                        child: Icon(_getActivityIcon(activity.type),
                            color: _getActivityColor(activity.type), size: 20),
                      ),
                      title: Text(activity.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(activity.description),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateTime(activity.timestamp),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
            Text(
              'admin_user_detail_activity_summary'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_currentUser.lastActiveAt != null)
                      _buildActivityItem(
                        'admin_user_detail_field_last_active'.tr(),
                        _formatDateTime(_currentUser.lastActiveAt!),
                        Icons.access_time,
                        Colors.green,
                      ),
                    if (_currentUser.lastLoginAt != null)
                      _buildActivityItem(
                        'admin_user_detail_field_last_login'.tr(),
                        _formatDateTime(_currentUser.lastLoginAt!),
                        Icons.login,
                        Colors.blue,
                      ),
                    _buildActivityItem(
                      'admin_user_detail_account_created'.tr(),
                      _formatDateTime(_currentUser.createdAt),
                      Icons.person_add,
                      Colors.purple,
                    ),
                    _buildActivityItem(
                      'admin_user_detail_active_user'.tr(),
                      _currentUser.isActiveUser ? 'common_yes'.tr() : 'common_no'.tr(),
                      Icons.check_circle,
                      _currentUser.isActiveUser ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.userRegistered:
        return Icons.person_add;
      case ActivityType.userLogin:
        return Icons.login;
      case ActivityType.artworkUploaded:
        return Icons.image;
      case ActivityType.artworkApproved:
        return Icons.check_circle;
      case ActivityType.artworkRejected:
        return Icons.cancel;
      case ActivityType.postCreated:
        return Icons.post_add;
      case ActivityType.commentAdded:
        return Icons.comment;
      case ActivityType.eventCreated:
        return Icons.event;
      case ActivityType.userSuspended:
        return Icons.block;
      case ActivityType.userVerified:
        return Icons.verified;
      case ActivityType.contentReported:
        return Icons.report;
      case ActivityType.adminAction:
        return Icons.admin_panel_settings;
      default:
        return Icons.history;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.userRegistered:
        return Colors.blue;
      case ActivityType.userLogin:
        return Colors.green;
      case ActivityType.artworkUploaded:
        return Colors.purple;
      case ActivityType.artworkApproved:
        return Colors.green;
      case ActivityType.artworkRejected:
        return Colors.red;
      case ActivityType.userSuspended:
        return Colors.red;
      case ActivityType.userVerified:
        return Colors.orange;
      case ActivityType.contentReported:
        return Colors.orange;
      case ActivityType.adminAction:
        return Colors.deepPurple;
      case ActivityType.systemError:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAdminTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'admin_user_detail_admin_information'.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          if (_currentUser.isSuspended) ...[
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.block, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(
                          'admin_user_detail_user_suspended'.tr(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    if (_currentUser.suspensionReason != null) ...[
                      const SizedBox(height: 8),
                      Text(
                          'admin_admin_user_detail_text_reason_currentusersuspensionreason'
                              .tr()),
                    ],
                    if (_currentUser.suspendedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                          'admin_user_detail_suspended_at'.tr(namedArgs: {
                        'timestamp': _formatDateTime(_currentUser.suspendedAt!)
                      })),
                    ],
                    if (_currentUser.suspendedBy != null) ...[
                      const SizedBox(height: 4),
                      Text(
                          'admin_admin_user_detail_text_by_currentusersuspendedby'
                              .tr()),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'admin_user_detail_admin_actions'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _buildAdminActionTile(
                    'admin_user_detail_report_count'.tr(),
                    'admin_user_detail_report_count_value'
                        .tr(namedArgs: {'count': '${_currentUser.reportCount}'}),
                    Icons.report,
                    Colors.red,
                  ),
                  _buildAdminActionTile(
                    'admin_user_detail_admin_flags'.tr(),
                    'admin_user_detail_admin_flags_value'
                        .tr(namedArgs: {'count': '${_currentUser.adminFlags.length}'}),
                    Icons.flag,
                    Colors.orange,
                  ),
                  _buildAdminActionTile(
                    'admin_user_detail_email_verified'.tr(),
                    _currentUser.emailVerifiedAt != null ? 'common_yes'.tr() : 'common_no'.tr(),
                    Icons.email,
                    _currentUser.emailVerifiedAt != null
                        ? Colors.green
                        : Colors.red,
                  ),
                  _buildAdminActionTile(
                    'admin_user_detail_password_reset_required'.tr(),
                    _currentUser.requiresPasswordReset ? 'common_yes'.tr() : 'common_no'.tr(),
                    Icons.lock_reset,
                    _currentUser.requiresPasswordReset
                        ? Colors.red
                        : Colors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'admin_user_detail_admin_notes'.tr(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        onPressed: _addAdminNote,
                        icon: const Icon(Icons.add_comment, size: 20),
                        tooltip: 'admin_user_detail_add_note'.tr(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_currentUser.adminNotes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'admin_user_detail_no_admin_notes'.tr(),
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    ..._currentUser.adminNotes.entries.map((entry) {
                      final noteData = entry.value as Map<String, dynamic>;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              noteData['note']?.toString() ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'admin_user_detail_note_meta'.tr(namedArgs: {
                                'admin': '${noteData['addedBy'] ?? 'admin_user_detail_unknown'.tr()}',
                                'time': noteData['addedAt'] != null
                                    ? _formatDateTime((noteData['addedAt'] as Timestamp).toDate())
                                    : 'admin_user_detail_unknown_time'.tr(),
                              }),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
          if (_currentUser.adminFlags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'admin_user_detail_admin_flags'.tr(),
                      style:
                          const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _currentUser.adminFlags
                          .map((flag) => Chip(
                                label: Text(flag),
                                backgroundColor: Colors.red.shade100,
                                labelStyle:
                                    TextStyle(color: Colors.red.shade700),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          // User Management Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'admin_user_detail_user_management'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  // Edit Profile Section
                  if (_isEditing) ...[
                    Text('admin_admin_user_detail_text_edit_profile'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _fullNameController,
                      decoration: InputDecoration(labelText: 'admin_user_detail_field_full_name'.tr()),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(labelText: 'admin_user_detail_field_username'.tr()),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'admin_user_detail_field_email'.tr()),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bioController,
                      decoration: InputDecoration(labelText: 'admin_user_detail_field_bio'.tr()),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(labelText: 'admin_user_detail_field_location'.tr()),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _zipCodeController,
                      decoration: InputDecoration(labelText: 'admin_user_detail_field_zip_code'.tr()),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _updateUserProfile,
                          child: Text(
                              'admin_admin_user_detail_text_save_changes'.tr()),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            setState(() => _isEditing = false);
                            // Reset controllers to original values
                            _fullNameController.text = _currentUser.fullName;
                            _usernameController.text = _currentUser.username;
                            _emailController.text = _currentUser.email;
                            _bioController.text = _currentUser.bio;
                            _locationController.text = _currentUser.location;
                            _zipCodeController.text =
                                _currentUser.zipCode ?? '';
                          },
                          child: Text('admin_admin_payment_text_cancel'.tr()),
                        ),
                      ],
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: () => setState(() => _isEditing = true),
                      icon: const Icon(Icons.edit),
                      label: Text(
                          'admin_admin_user_detail_text_edit_profile'.tr()),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Image Management
                  Text('admin_user_detail_image_management'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  if (_currentUser.profileImageUrl.isNotEmpty) ...[
                    ElevatedButton.icon(
                      onPressed: _removeProfileImage,
                      icon: const Icon(Icons.delete),
                      label: Text(
                          'admin_admin_user_detail_text_remove_profile_image'
                              .tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // User Type Management
                  const SizedBox(height: 16),
                  Text('admin_user_detail_field_user_type'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  DropdownButton<UserType>(
                    value: _getUserTypeFromString(_currentUser.userType),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                    dropdownColor: Colors.white,
                    onChanged: (UserType? newType) {
                      if (newType != null) {
                        _updateUserType(newType);
                      }
                    },
                    items: UserType.values.map((UserType type) {
                      return DropdownMenuItem<UserType>(
                        value: type,
                        child: Text(
                          type.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Verification and Featured Status
                  Text('admin_user_detail_status_management'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: Text('admin_admin_user_detail_text_verified'.tr()),
                    value: _currentUser.isVerified,
                    onChanged: (_) => _toggleVerificationStatus(),
                  ),
                  SwitchListTile(
                    title: Text('admin_admin_user_detail_text_featured'.tr()),
                    value: _currentUser.isFeatured,
                    onChanged: (_) => _toggleFeaturedStatus(),
                  ),
                  SwitchListTile(
                    title: Text('admin_user_detail_shadow_banned'.tr()),
                    subtitle: Text(
                        'admin_user_detail_shadow_banned_subtitle'.tr()),
                    value: _currentUser.isShadowBanned,
                    onChanged: (_) => _toggleShadowBanStatus(),
                  ),
                  const SizedBox(height: 16),
                  // Critical Account Actions
                  Text('admin_user_detail_critical_actions'.tr(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (!_currentUser.isSuspended)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _suspendUser,
                            icon: const Icon(Icons.block),
                            label: Text('admin_user_detail_suspend'.tr()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _unsuspendUser,
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text('admin_user_detail_unsuspend'.tr()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      if (!_currentUser.isDeleted)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _deleteUser,
                            icon: const Icon(Icons.delete_forever),
                            label: Text('admin_user_detail_delete'.tr()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
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
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
      String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  value,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionTile(
      String title, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeChip(UserType userType) {
    final color = _getUserTypeColor(userType);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        userType.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    final status = _currentUser.statusText;
    final color = _getStatusColor(_currentUser.statusColor);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Convert String? userType to UserType enum
  UserType _getUserTypeFromString(String? userTypeString) {
    if (userTypeString == null) return UserType.regular;
    return UserType.fromString(userTypeString);
  }

  Color _getUserTypeColor(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return Colors.red;
      case UserType.moderator:
        return Colors.orange;
      case UserType.artist:
        return Colors.purple;
      case UserType.gallery:
        return Colors.green;
      case UserType.regular:
        return Colors.blue;
    }
  }

  Color _getStatusColor(String statusColor) {
    switch (statusColor) {
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'yellow':
        return Colors.amber;
      case 'green':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Update user profile
  Future<void> _updateUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final profileData = {
        'fullName': _fullNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'zipCode': _zipCodeController.text.trim(),
      };

      await _adminService.updateUserProfile(_currentUser.id, profileData);

      setState(() {
        _currentUser = _currentUser.copyWithAdmin(
          fullName: _fullNameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          bio: _bioController.text.trim(),
          location: _locationController.text.trim(),
          zipCode: _zipCodeController.text.trim(),
        );
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'admin_admin_user_detail_success_user_profile_updated'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('admin_admin_user_detail_error_failed_to_update'.tr())),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Remove user profile image
  Future<void> _removeProfileImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin_admin_user_detail_text_remove_profile_image'.tr()),
        content: Text(
            'admin_user_detail_remove_profile_image_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('admin_admin_payment_text_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('admin_admin_user_detail_text_remove'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _adminService.removeUserProfileImage(_currentUser.id);

        setState(() {
          _currentUser = _currentUser.copyWithAdmin(profileImageUrl: '');
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'admin_admin_user_detail_success_profile_image_removed'
                        .tr())),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'admin_admin_user_detail_error_failed_to_remove'.tr())),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Toggle user featured status
  Future<void> _toggleFeaturedStatus() async {
    setState(() => _isLoading = true);
    try {
      final newFeaturedStatus = !_currentUser.isFeatured;

      await _adminService.setUserFeatured(_currentUser.id, newFeaturedStatus);

      setState(() {
        _currentUser =
            _currentUser.copyWithAdmin(isFeatured: newFeaturedStatus);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'admin_user_detail_featured_status_updated'.tr(namedArgs: {
                'status': newFeaturedStatus
                    ? 'admin_user_detail_featured_status_featured'.tr()
                    : 'admin_user_detail_featured_status_unfeatured'.tr(),
              }),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('admin_admin_user_detail_error_failed_to_update_28'.tr()),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Update user type
  Future<void> _updateUserType(UserType newType) async {
    setState(() => _isLoading = true);
    try {
      await _adminService.updateUserType(_currentUser.id, newType);

      setState(() {
        _currentUser = _currentUser.copyWithAdmin(userType: newType.name);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('admin_admin_user_detail_success_user_type_updated'.tr()),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('admin_admin_user_detail_error_failed_to_update_30'.tr()),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Toggle user verification status
  Future<void> _toggleVerificationStatus() async {
    setState(() => _isLoading = true);
    try {
      if (_currentUser.isVerified) {
        await _adminService.unverifyUser(_currentUser.id);
      } else {
        await _adminService.verifyUser(_currentUser.id);
      }

      setState(() {
        _currentUser =
            _currentUser.copyWithAdmin(isVerified: !_currentUser.isVerified);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'admin_user_detail_verification_status_updated'.tr(namedArgs: {
                'status': !_currentUser.isVerified
                    ? 'admin_user_detail_verification_status_verified'.tr()
                    : 'admin_user_detail_verification_status_unverified'.tr(),
              }),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('admin_admin_user_detail_error_failed_to_update_31'.tr()),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Toggle shadow ban status
  Future<void> _toggleShadowBanStatus() async {
    setState(() => _isLoading = true);
    try {
      final newStatus = !_currentUser.isShadowBanned;
      await _adminService.toggleShadowBan(_currentUser.id, newStatus);

      // Audit Trail
      await _auditTrailService.logAdminAction(
        action: newStatus ? 'shadow_ban_user' : 'unshadow_ban_user',
        category: 'user',
        targetUserId: _currentUser.id,
        description:
            '${newStatus ? 'Shadow banned' : 'Unshadow banned'} user: ${_currentUser.fullName}',
      );

      setState(() {
        _currentUser = _currentUser.copyWithAdmin(isShadowBanned: newStatus);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'admin_user_detail_shadow_ban_status_updated'.tr(namedArgs: {
                'status': newStatus
                    ? 'admin_user_detail_shadow_ban_status_banned'.tr()
                    : 'admin_user_detail_shadow_ban_status_unbanned'.tr(),
              }),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'admin_user_detail_error_generic'.tr(namedArgs: {'error': '$e'})),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Suspend user
  Future<void> _suspendUser() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin_user_detail_suspend_user'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('admin_user_detail_suspend_confirm'.tr()),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'admin_user_detail_reason_for_suspension'.tr(),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('admin_admin_payment_text_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('admin_user_detail_suspend'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && reasonController.text.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final currentAdminId =
            _userService.currentUserId ?? 'unknown_admin';

        await _adminService.suspendUser(
            _currentUser.id, reasonController.text.trim(), currentAdminId);

        // Log the action
        await _activityService.logUserSuspension(
            _currentUser.id,
            _currentUser.fullName,
            currentAdminId,
            reasonController.text.trim());

        // Audit Trail
        await _auditTrailService.logAdminAction(
          action: 'suspend_user',
          category: 'user',
          targetUserId: _currentUser.id,
          description:
              'Suspended user: ${_currentUser.fullName}. Reason: ${reasonController.text.trim()}',
          metadata: {'reason': reasonController.text.trim()},
        );

        setState(() {
          _currentUser = _currentUser.copyWithAdmin(
            isSuspended: true,
            suspensionReason: reasonController.text.trim(),
            suspendedAt: DateTime.now(),
            suspendedBy: currentAdminId,
          );
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('admin_user_detail_user_suspended_success'.tr()),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'admin_user_detail_error_generic'.tr(namedArgs: {'error': '$e'})),
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    } else if (confirmed == true && reasonController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('admin_user_detail_reason_required'.tr())),
      );
    }
  }

  /// Unsuspend user
  Future<void> _unsuspendUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin_user_detail_unsuspend_user'.tr()),
        content: Text('admin_user_detail_unsuspend_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('admin_admin_payment_text_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('admin_user_detail_unsuspend'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _adminService.unsuspendUser(_currentUser.id);

        // Audit Trail
        await _auditTrailService.logAdminAction(
          action: 'unsuspend_user',
          category: 'user',
          targetUserId: _currentUser.id,
          description: 'Unsuspended user: ${_currentUser.fullName}',
        );

        setState(() {
          _currentUser = _currentUser.copyWithAdmin(
            isSuspended: false,
            suspensionReason: null,
            suspendedAt: null,
            suspendedBy: null,
          );
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('admin_user_detail_user_unsuspended_success'.tr()),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'admin_user_detail_error_generic'.tr(namedArgs: {'error': '$e'})),
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Delete user (soft delete)
  Future<void> _deleteUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin_user_detail_delete_user'.tr()),
        content: Text(
            'admin_user_detail_delete_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('admin_admin_payment_text_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('admin_user_detail_delete'.tr(), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _adminService.deleteUser(_currentUser.id);

        // Audit Trail
        await _auditTrailService.logAdminAction(
          action: 'delete_user',
          category: 'user',
          targetUserId: _currentUser.id,
          description: 'Soft-deleted user: ${_currentUser.fullName}',
        );

        setState(() {
          _currentUser = _currentUser.copyWithAdmin(isDeleted: true);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('admin_user_detail_user_deleted_success'.tr()),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'admin_user_detail_error_generic'.tr(namedArgs: {'error': '$e'})),
            ),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Add admin note
  Future<void> _addAdminNote() async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin_user_detail_add_admin_note'.tr()),
        content: TextField(
          controller: noteController,
          decoration: InputDecoration(
            labelText: 'admin_user_detail_note'.tr(),
            border: const OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('admin_admin_payment_text_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('admin_user_detail_add_note'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && noteController.text.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final currentAdminId =
            _userService.currentUserId ?? 'unknown_admin';
        final noteText = noteController.text.trim();

        await _adminService.addAdminNote(
          _currentUser.id,
          noteText,
          currentAdminId,
        );

        // Audit Trail
        await _auditTrailService.logAdminAction(
          action: 'add_user_note',
          category: 'user',
          targetUserId: _currentUser.id,
          description: 'Added admin note for user: ${_currentUser.fullName}',
          metadata: {
            'note_preview': noteText.length > 50
                ? '${noteText.substring(0, 50)}...'
                : noteText
          },
        );

        // Update local state
        final noteId = DateTime.now().millisecondsSinceEpoch.toString();
        final newNotes = Map<String, dynamic>.from(_currentUser.adminNotes);
        newNotes[noteId] = {
          'note': noteText,
          'addedBy': currentAdminId,
          'addedAt': Timestamp.now(),
        };

        setState(() {
          _currentUser = _currentUser.copyWithAdmin(adminNotes: newNotes);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('admin_user_detail_note_added_success'.tr())),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('admin_user_detail_error_generic'
                    .tr(namedArgs: {'error': '$e'}))),
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}

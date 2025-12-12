import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_admin_model.dart';
import '../widgets/admin_drawer.dart';
import '../services/admin_service.dart';

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
  late TabController _tabController;
  late UserAdminModel _currentUser;
  bool _isLoading = false;
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
    _tabController = TabController(length: 4, vsync: this);
    _currentUser = widget.user;

    // Initialize text controllers
    _fullNameController = TextEditingController(text: _currentUser.fullName);
    _usernameController = TextEditingController(text: _currentUser.username);
    _emailController = TextEditingController(text: _currentUser.email);
    _bioController = TextEditingController(text: _currentUser.bio);
    _locationController = TextEditingController(text: _currentUser.location);
    _zipCodeController = TextEditingController(text: _currentUser.zipCode);
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
        title: 'User Details',
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
              tabs: const [
                Tab(text: 'Overview', icon: Icon(Icons.person)),
                Tab(text: 'Details', icon: Icon(Icons.info)),
                Tab(text: 'Activity', icon: Icon(Icons.history)),
                Tab(text: 'Admin', icon: Icon(Icons.admin_panel_settings)),
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
                'Level',
                _currentUser.level.toString(),
                Icons.star,
                Colors.orange,
              ),
              _buildStatCard(
                'Experience',
                '${_currentUser.experiencePoints} XP',
                Icons.trending_up,
                Colors.green,
              ),
              _buildStatCard(
                'Followers',
                _currentUser.followersCount.toString(),
                Icons.people,
                Colors.blue,
              ),
              _buildStatCard(
                'Following',
                _currentUser.followingCount.toString(),
                Icons.person_add,
                Colors.purple,
              ),
              _buildStatCard(
                'Posts',
                _currentUser.postsCount.toString(),
                Icons.post_add,
                Colors.teal,
              ),
              _buildStatCard(
                'Captures',
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
          _buildDetailSection('Personal Information', [
            _buildDetailRow('Full Name', _currentUser.fullName),
            _buildDetailRow(
                'Username',
                _currentUser.username.isEmpty
                    ? 'Not set'
                    : _currentUser.username),
            _buildDetailRow('Email', _currentUser.email),
            _buildDetailRow('Location', _currentUser.location),
            _buildDetailRow('Zip Code', _currentUser.zipCode ?? 'Not set'),
            _buildDetailRow('Gender', _currentUser.gender ?? 'Not set'),
            if (_currentUser.birthDate != null)
              _buildDetailRow('Birth Date',
                  '${_currentUser.birthDate!.day}/${_currentUser.birthDate!.month}/${_currentUser.birthDate!.year}'),
          ]),
          const SizedBox(height: 24),
          _buildDetailSection('Account Information', [
            _buildDetailRow(
                'User Type',
                _getUserTypeFromString(_currentUser.userType)
                    .name
                    .toUpperCase()),
            _buildDetailRow('Status', _currentUser.statusText),
            _buildDetailRow('Verified', _currentUser.isVerified ? 'Yes' : 'No'),
            _buildDetailRow(
                'Created At', _formatDateTime(_currentUser.createdAt)),
            if (_currentUser.updatedAt != null)
              _buildDetailRow(
                  'Updated At', _formatDateTime(_currentUser.updatedAt!)),
            if (_currentUser.lastActiveAt != null)
              _buildDetailRow(
                  'Last Active', _formatDateTime(_currentUser.lastActiveAt!)),
            if (_currentUser.lastLoginAt != null)
              _buildDetailRow(
                  'Last Login', _formatDateTime(_currentUser.lastLoginAt!)),
          ]),
          if (_currentUser.bio.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildDetailSection('Biography', [
              Text(_currentUser.bio),
            ]),
          ],
          if (_currentUser.achievements.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildDetailSection('Achievements', [
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Activity timeline would go here
          // For now, show basic activity info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Activity Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (_currentUser.lastActiveAt != null)
                    _buildActivityItem(
                      'Last Active',
                      _formatDateTime(_currentUser.lastActiveAt!),
                      Icons.access_time,
                      Colors.green,
                    ),
                  if (_currentUser.lastLoginAt != null)
                    _buildActivityItem(
                      'Last Login',
                      _formatDateTime(_currentUser.lastLoginAt!),
                      Icons.login,
                      Colors.blue,
                    ),
                  _buildActivityItem(
                    'Account Created',
                    _formatDateTime(_currentUser.createdAt),
                    Icons.person_add,
                    Colors.purple,
                  ),
                  if (_currentUser.updatedAt != null)
                    _buildActivityItem(
                      'Profile Updated',
                      _formatDateTime(_currentUser.updatedAt!),
                      Icons.edit,
                      Colors.orange,
                    ),
                  _buildActivityItem(
                    'Active User',
                    _currentUser.isActiveUser ? 'Yes' : 'No',
                    Icons.check_circle,
                    _currentUser.isActiveUser ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Information',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                    const Row(
                      children: [
                        Icon(Icons.block, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'User Suspended',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    if (_currentUser.suspensionReason != null) ...[
                      const SizedBox(height: 8),
                      Text('admin_admin_user_detail_text_reason_currentusersuspensionreason'.tr()),
                    ],
                    if (_currentUser.suspendedAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                          'Suspended: ${_formatDateTime(_currentUser.suspendedAt!)}'),
                    ],
                    if (_currentUser.suspendedBy != null) ...[
                      const SizedBox(height: 4),
                      Text('admin_admin_user_detail_text_by_currentusersuspendedby'.tr()),
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
                  const Text(
                    'Admin Actions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _buildAdminActionTile(
                    'Report Count',
                    '${_currentUser.reportCount} reports',
                    Icons.report,
                    Colors.red,
                  ),
                  _buildAdminActionTile(
                    'Admin Flags',
                    '${_currentUser.adminFlags.length} flags',
                    Icons.flag,
                    Colors.orange,
                  ),
                  _buildAdminActionTile(
                    'Email Verified',
                    _currentUser.emailVerifiedAt != null ? 'Yes' : 'No',
                    Icons.email,
                    _currentUser.emailVerifiedAt != null
                        ? Colors.green
                        : Colors.red,
                  ),
                  _buildAdminActionTile(
                    'Password Reset Required',
                    _currentUser.requiresPasswordReset ? 'Yes' : 'No',
                    Icons.lock_reset,
                    _currentUser.requiresPasswordReset
                        ? Colors.red
                        : Colors.green,
                  ),
                ],
              ),
            ),
          ),
          if (_currentUser.adminNotes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Notes',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
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
                              'By: ${noteData['addedBy'] ?? 'Unknown'} • ${noteData['addedAt'] != null ? _formatDateTime((noteData['addedAt'] as Timestamp).toDate()) : 'Unknown time'}',
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
          if (_currentUser.adminFlags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Flags',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                  const Text(
                    'User Management',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  // Edit Profile Section
                  if (_isEditing) ...[
                    Text('admin_admin_user_detail_text_edit_profile'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bioController,
                      decoration: const InputDecoration(labelText: 'Bio'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _zipCodeController,
                      decoration: const InputDecoration(labelText: 'Zip Code'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _updateUserProfile,
                          child: Text('admin_admin_user_detail_text_save_changes'.tr()),
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
                      label: Text('admin_admin_user_detail_text_edit_profile'.tr()),
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Image Management
                  const Text('Image Management',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  if (_currentUser.profileImageUrl.isNotEmpty) ...[
                    ElevatedButton.icon(
                      onPressed: _removeProfileImage,
                      icon: const Icon(Icons.delete),
                      label: Text('admin_admin_user_detail_text_remove_profile_image'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // User Type Management
                  const SizedBox(height: 16),
                  const Text('User Type',
                      style: TextStyle(fontWeight: FontWeight.w600)),
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
                  const Text('Status Management',
                      style: TextStyle(fontWeight: FontWeight.w600)),
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
      final adminService = AdminService();
      final profileData = {
        'fullName': _fullNameController.text.trim(),
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'zipCode': _zipCodeController.text.trim(),
      };

      await adminService.updateUserProfile(_currentUser.id, profileData);

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
          SnackBar(content: Text('admin_admin_user_detail_success_user_profile_updated'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_admin_user_detail_error_failed_to_update'.tr())),
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
        content: const Text(
            'Are you sure you want to remove this user\'s profile image?'),
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
        final adminService = AdminService();
        await adminService.removeUserProfileImage(_currentUser.id);

        setState(() {
          _currentUser = _currentUser.copyWithAdmin(profileImageUrl: '');
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('admin_admin_user_detail_success_profile_image_removed'.tr())),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('admin_admin_user_detail_error_failed_to_remove'.tr())),
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
      final adminService = AdminService();
      final newFeaturedStatus = !_currentUser.isFeatured;

      await adminService.setUserFeatured(_currentUser.id, newFeaturedStatus);

      setState(() {
        _currentUser =
            _currentUser.copyWithAdmin(isFeatured: newFeaturedStatus);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'User ${newFeaturedStatus ? 'marked as featured' : 'unfeatured'} successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_admin_user_detail_error_failed_to_update_28'.tr())),
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
      final adminService = AdminService();
      await adminService.updateUserType(_currentUser.id, newType);

      setState(() {
        _currentUser = _currentUser.copyWithAdmin(userType: newType.name);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_admin_user_detail_success_user_type_updated'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_admin_user_detail_error_failed_to_update_30'.tr())),
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
      final adminService = AdminService();
      if (_currentUser.isVerified) {
        await adminService.unverifyUser(_currentUser.id);
      } else {
        await adminService.verifyUser(_currentUser.id);
      }

      setState(() {
        _currentUser =
            _currentUser.copyWithAdmin(isVerified: !_currentUser.isVerified);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'User ${!_currentUser.isVerified ? 'verified' : 'unverified'} successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_admin_user_detail_error_failed_to_update_31'.tr())),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

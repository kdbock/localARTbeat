import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_artist/artbeat_artist.dart';
import '../../models/direct_commission_model.dart';
import '../../services/direct_commission_service.dart';
import '../../theme/community_colors.dart';
import 'direct_commissions_screen.dart';
import 'artist_commission_settings_screen.dart';
import 'commission_setup_wizard_screen.dart';
import 'commission_detail_screen.dart';
import 'commission_rating_screen.dart';
import 'commission_progress_tracker.dart';
import 'commission_dispute_screen.dart';
import 'commission_templates_browser.dart';
import 'commission_gallery_screen.dart';
import 'commission_analytics_dashboard.dart';

class CommissionHubScreen extends StatefulWidget {
  const CommissionHubScreen({super.key});

  @override
  State<CommissionHubScreen> createState() => _CommissionHubScreenState();
}

class _CommissionHubScreenState extends State<CommissionHubScreen> {
  final DirectCommissionService _commissionService = DirectCommissionService();

  bool _isLoading = true;
  bool _isArtist = false;
  ArtistCommissionSettings? _artistSettings;
  List<DirectCommissionModel> _recentCommissions = [];
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Check if user is an artist by trying to load settings
      try {
        final settings = await _commissionService.getArtistSettings(user.uid);
        setState(() {
          _isArtist = settings != null;
          _artistSettings = settings;
        });
      } catch (e) {
        // User is not an artist or hasn't set up commission settings
        setState(() => _isArtist = false);
      }

      // Load recent commissions
      final commissions = await _commissionService.getCommissionsByUser(
        user.uid,
      );
      final recentCommissions = commissions.take(5).toList();

      // Calculate stats
      final activeCount = commissions
          .where(
            (c) => [
              CommissionStatus.pending,
              CommissionStatus.quoted,
              CommissionStatus.accepted,
              CommissionStatus.inProgress,
            ].contains(c.status),
          )
          .length;

      final completedCount = commissions
          .where(
            (c) => [
              CommissionStatus.completed,
              CommissionStatus.delivered,
            ].contains(c.status),
          )
          .length;

      final totalEarnings = commissions
          .where(
            (c) =>
                c.artistId == user.uid &&
                [
                  CommissionStatus.completed,
                  CommissionStatus.delivered,
                ].contains(c.status),
          )
          .fold(0.0, (sum, c) => sum + c.totalPrice);

      setState(() {
        _recentCommissions = recentCommissions;
        _stats = {
          'active': activeCount,
          'completed': completedCount,
          'total': commissions.length,
          'earnings': totalEarnings.round(),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 48 + 4),
        child: Container(
          decoration: const BoxDecoration(
            gradient: core.ArtbeatColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.work, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'screen_title_commissions'.tr(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Manage your commission requests',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
        ),
      ),
      backgroundColor: CommunityColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Welcome Card
                  _buildWelcomeCard(),
                  const SizedBox(height: 16),

                  // Stats Cards
                  _buildStatsCards(),
                  const SizedBox(height: 16),

                  // Quick Actions
                  _buildQuickActions(),
                  const SizedBox(height: 16),

                  // Artist Settings (if artist)
                  if (_isArtist) ...[
                    _buildArtistSection(),
                    const SizedBox(height: 16),
                  ],

                  // Recent Commissions
                  _buildRecentCommissions(),
                  const SizedBox(height: 16),

                  // Getting Started (if no commissions)
                  if (_stats['total'] == 0) _buildGettingStarted(),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              CommunityColors.primary.withValues(alpha: 0.1),
              CommunityColors.secondary.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.palette,
                  size: 32,
                  color: CommunityColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isArtist
                            ? 'Manage your commission requests and settings'
                            : 'Request custom artwork from talented artists',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: core.ArtbeatColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!_isArtist) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _setupArtistProfile,
                icon: const Icon(Icons.brush),
                label: const Text('Become an Artist'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: core.ArtbeatColors.primaryPurple,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Active',
            _stats['active']?.toString() ?? '0',
            Icons.pending_actions,
            core.ArtbeatColors.warning,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Completed',
            _stats['completed']?.toString() ?? '0',
            Icons.check_circle,
            core.ArtbeatColors.primaryGreen,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Total',
            _stats['total']?.toString() ?? '0',
            Icons.art_track,
            core.ArtbeatColors.info,
          ),
        ),
        if (_isArtist) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Earnings',
              '\$${_stats['earnings']?.toString() ?? '0'}',
              Icons.attach_money,
              core.ArtbeatColors.primaryPurple,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: CommunityColors.textPrimary,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: CommunityColors.textSecondary,
              ),
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
            Text(
              'Quick Actions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'View All Commissions',
                    Icons.list,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute<DirectCommissionsScreen>(
                        builder: (context) => const DirectCommissionsScreen(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Browse Artists',
                    Icons.search,
                    _browseArtists,
                  ),
                ),
              ],
            ),
            if (_isArtist) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Commission Settings',
                      Icons.settings,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute<ArtistCommissionSettingsScreen>(
                          builder: (context) =>
                              const ArtistCommissionSettingsScreen(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      'Analytics',
                      Icons.analytics,
                      _viewAnalytics,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Templates',
                      Icons.auto_awesome,
                      _viewTemplates,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      'Gallery',
                      Icons.image_search,
                      _viewGallery,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
    );
  }

  Widget _buildArtistSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.brush,
                  color: core.ArtbeatColors.primaryPurple,
                ),
                const SizedBox(width: 8),
                Text(
                  'Artist Dashboard',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_artistSettings != null) ...[
              Row(
                children: [
                  Icon(
                    _artistSettings!.acceptingCommissions
                        ? Icons.check_circle
                        : Icons.pause_circle,
                    color: _artistSettings!.acceptingCommissions
                        ? core.ArtbeatColors.primaryGreen
                        : core.ArtbeatColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _artistSettings!.acceptingCommissions
                        ? 'Currently accepting commissions'
                        : 'Not accepting commissions',
                    style: TextStyle(
                      color: _artistSettings!.acceptingCommissions
                          ? core.ArtbeatColors.primaryGreen
                          : core.ArtbeatColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Base Price: \$${_artistSettings!.basePrice.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                'Available Types: ${_artistSettings!.availableTypes.map((t) => t.displayName).join(', ')}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => CommissionSetupWizardScreen(
                            mode: SetupMode.editing,
                            initialSettings: _artistSettings,
                          ),
                        ),
                      ).then((_) => _loadData()),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit (Wizard)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) =>
                              const ArtistCommissionSettingsScreen(),
                        ),
                      ).then((_) => _loadData()),
                      icon: const Icon(Icons.settings),
                      label: const Text('Advanced'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: core.ArtbeatColors.warning.withAlpha(25),
                  border: Border.all(
                    color: core.ArtbeatColors.warning.withAlpha(100),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: core.ArtbeatColors.warning,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Complete your commission setup',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: core.ArtbeatColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Take our quick guided setup to start accepting commissions',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: core.ArtbeatColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const CommissionSetupWizardScreen(
                      mode: SetupMode.firstTime,
                    ),
                  ),
                ).then((_) => _loadData()),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Quick Setup Wizard'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: core.ArtbeatColors.primaryPurple,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) =>
                        const ArtistCommissionSettingsScreen(),
                  ),
                ).then((_) => _loadData()),
                icon: const Icon(Icons.settings),
                label: const Text('Detailed Settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentCommissions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recent Commissions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_recentCommissions.isNotEmpty)
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<DirectCommissionsScreen>(
                        builder: (context) => const DirectCommissionsScreen(),
                      ),
                    ),
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentCommissions.isEmpty)
              const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.art_track,
                      size: 48,
                      color: core.ArtbeatColors.textSecondary,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No commissions yet',
                      style: TextStyle(color: core.ArtbeatColors.textSecondary),
                    ),
                  ],
                ),
              )
            else
              ...(_recentCommissions.map(
                (commission) => _buildCommissionTile(commission),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionTile(DirectCommissionModel commission) {
    final statusColor = _getStatusColor(commission.status);
    final isArtist =
        commission.artistId == FirebaseAuth.instance.currentUser?.uid;
    final currentUser = FirebaseAuth.instance.currentUser;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.1),
                child: Icon(
                  _getStatusIcon(commission.status),
                  color: statusColor,
                  size: 20,
                ),
              ),
              title: Text(
                commission.title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArtist
                        ? 'Client: ${commission.clientName}'
                        : 'Artist: ${commission.artistName}',
                  ),
                  Text(
                    commission.status.displayName,
                    style: TextStyle(color: statusColor, fontSize: 12),
                  ),
                ],
              ),
              trailing: commission.totalPrice > 0
                  ? Text(
                      '\$${commission.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: core.ArtbeatColors.primaryGreen,
                      ),
                    )
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) =>
                        CommissionDetailScreen(commission: commission),
                  ),
                );
              },
            ),
            // Action buttons
            Wrap(
              spacing: 8,
              children: [
                // View Progress button
                if ([
                  CommissionStatus.accepted,
                  CommissionStatus.inProgress,
                  CommissionStatus.revision,
                ].contains(commission.status))
                  SizedBox(
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: () => _viewProgress(commission),
                      icon: const Icon(Icons.trending_up, size: 16),
                      label: const Text('Progress'),
                    ),
                  ),
                // Rate Commission button (after completed)
                if ([
                      CommissionStatus.completed,
                      CommissionStatus.delivered,
                    ].contains(commission.status) &&
                    currentUser != null)
                  SizedBox(
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: () => _rateCommission(commission),
                      icon: const Icon(Icons.star_outline, size: 16),
                      label: const Text('Rate'),
                    ),
                  ),
                // Report Issue button
                if ([
                      CommissionStatus.inProgress,
                      CommissionStatus.revision,
                    ].contains(commission.status) &&
                    currentUser != null)
                  SizedBox(
                    height: 32,
                    child: OutlinedButton.icon(
                      onPressed: () => _reportDispute(commission),
                      icon: const Icon(Icons.flag_outlined, size: 16),
                      label: const Text('Report'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGettingStarted() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: core.ArtbeatColors.primaryPurple,
            ),
            const SizedBox(height: 16),
            Text(
              'Getting Started with Commissions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _isArtist
                  ? 'Set up your commission settings to start receiving requests from clients.'
                  : 'Browse artists and request custom artwork tailored to your needs.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: core.ArtbeatColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isArtist
                  ? () => Navigator.push(
                      context,
                      MaterialPageRoute<ArtistCommissionSettingsScreen>(
                        builder: (context) =>
                            const ArtistCommissionSettingsScreen(),
                      ),
                    )
                  : _browseArtists,
              icon: Icon(_isArtist ? Icons.settings : Icons.search),
              label: Text(
                _isArtist ? 'Setup Commission Settings' : 'Browse Artists',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: core.ArtbeatColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(CommissionStatus status) {
    switch (status) {
      case CommissionStatus.pending:
        return core.ArtbeatColors.warning;
      case CommissionStatus.quoted:
        return core.ArtbeatColors.info;
      case CommissionStatus.accepted:
        return core.ArtbeatColors.primaryGreen;
      case CommissionStatus.inProgress:
        return core.ArtbeatColors.primaryPurple;
      case CommissionStatus.revision:
        return core.ArtbeatColors.warning;
      case CommissionStatus.completed:
        return core.ArtbeatColors.primaryGreen;
      case CommissionStatus.delivered:
        return core.ArtbeatColors.primaryGreen;
      case CommissionStatus.cancelled:
        return core.ArtbeatColors.error;
      case CommissionStatus.disputed:
        return core.ArtbeatColors.error;
    }
  }

  IconData _getStatusIcon(CommissionStatus status) {
    switch (status) {
      case CommissionStatus.pending:
        return Icons.schedule;
      case CommissionStatus.quoted:
        return Icons.request_quote;
      case CommissionStatus.accepted:
        return Icons.handshake;
      case CommissionStatus.inProgress:
        return Icons.brush;
      case CommissionStatus.revision:
        return Icons.edit;
      case CommissionStatus.completed:
        return Icons.check_circle;
      case CommissionStatus.delivered:
        return Icons.local_shipping;
      case CommissionStatus.cancelled:
        return Icons.cancel;
      case CommissionStatus.disputed:
        return Icons.warning;
    }
  }

  void _setupArtistProfile() {
    Navigator.push(
      context,
      MaterialPageRoute<ArtistCommissionSettingsScreen>(
        builder: (context) => const ArtistCommissionSettingsScreen(),
      ),
    ).then((_) => _loadData());
  }

  void _browseArtists() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const ArtistBrowseScreen(mode: 'commissions'),
      ),
    );
  }

  void _viewAnalytics() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CommissionAnalyticsDashboard(artistId: user.uid),
      ),
    );
  }

  void _viewTemplates() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const CommissionTemplatesBrowser(),
      ),
    );
  }

  void _viewGallery() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CommissionGalleryScreen(artistId: user.uid),
      ),
    );
  }

  void _viewProgress(DirectCommissionModel commission) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CommissionProgressTracker(commission: commission),
      ),
    );
  }

  void _rateCommission(DirectCommissionModel commission) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CommissionRatingScreen(commission: commission),
      ),
    );
  }

  void _reportDispute(DirectCommissionModel commission) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final otherPartyId = commission.artistId == currentUser.uid
        ? commission.clientId
        : commission.artistId;
    final otherPartyName = commission.artistId == currentUser.uid
        ? commission.clientName
        : commission.artistName;

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => CommissionDisputeScreen(
          commissionId: commission.id,
          otherPartyId: otherPartyId,
          otherPartyName: otherPartyName,
        ),
      ),
    );
  }
}

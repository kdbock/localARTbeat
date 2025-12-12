import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../../models/direct_commission_model.dart';
import '../../services/direct_commission_service.dart';
import '../../theme/community_colors.dart';
import 'commission_detail_screen.dart';
import 'artist_selection_screen.dart';

class DirectCommissionsScreen extends StatefulWidget {
  const DirectCommissionsScreen({super.key});

  @override
  State<DirectCommissionsScreen> createState() =>
      _DirectCommissionsScreenState();
}

class _DirectCommissionsScreenState extends State<DirectCommissionsScreen>
    with SingleTickerProviderStateMixin {
  final DirectCommissionService _commissionService = DirectCommissionService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TabController _tabController;

  List<DirectCommissionModel> _allCommissions = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCommissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCommissions() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to view commissions')),
          );
        }
        return;
      }

      _currentUserId = user.uid;
      final commissions = await _commissionService.getCommissionsByUser(
        user.uid,
      );

      setState(() {
        _allCommissions = commissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading commissions: $e')),
        );
      }
    }
  }

  List<DirectCommissionModel> _getCommissionsByStatus(
    List<CommissionStatus> statuses,
  ) {
    return _allCommissions.where((c) => statuses.contains(c.status)).toList();
  }

  bool _isUserArtist(DirectCommissionModel commission) {
    return commission.artistId == _currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
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
                  child: const Icon(
                    Icons.handshake,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Direct Commissions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Manage active commissions',
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      backgroundColor: CommunityColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showArtistSelection(),
        backgroundColor: CommunityColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Commission'),
      ),
      body: Column(
        children: [
          // Summary Cards
          if (!_isLoading) _buildSummaryCards(),

          // Tabs for filtering commissions
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.pending_actions, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Active (${_getCommissionsByStatus([CommissionStatus.pending, CommissionStatus.quoted, CommissionStatus.accepted, CommissionStatus.inProgress]).length})',
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Pending (${_getCommissionsByStatus([CommissionStatus.pending, CommissionStatus.quoted]).length})',
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Completed (${_getCommissionsByStatus([CommissionStatus.completed, CommissionStatus.delivered]).length})',
                    ),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.list, size: 16),
                    const SizedBox(width: 4),
                    Text('All (${_allCommissions.length})'),
                  ],
                ),
              ),
            ],
          ),

          // Commission list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Active commissions
                      _buildCommissionList(
                        _getCommissionsByStatus([
                          CommissionStatus.pending,
                          CommissionStatus.quoted,
                          CommissionStatus.accepted,
                          CommissionStatus.inProgress,
                        ]),
                      ),
                      // Pending commissions
                      _buildCommissionList(
                        _getCommissionsByStatus([
                          CommissionStatus.pending,
                          CommissionStatus.quoted,
                        ]),
                      ),
                      // Completed commissions
                      _buildCommissionList(
                        _getCommissionsByStatus([
                          CommissionStatus.completed,
                          CommissionStatus.delivered,
                        ]),
                      ),
                      // All commissions
                      _buildCommissionList(_allCommissions),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final activeCount = _getCommissionsByStatus([
      CommissionStatus.pending,
      CommissionStatus.quoted,
      CommissionStatus.accepted,
      CommissionStatus.inProgress,
    ]).length;

    final completedCount = _getCommissionsByStatus([
      CommissionStatus.completed,
      CommissionStatus.delivered,
    ]).length;

    final totalEarnings = _allCommissions
        .where(
          (c) =>
              c.artistId == _currentUserId &&
              [
                CommissionStatus.completed,
                CommissionStatus.delivered,
              ].contains(c.status),
        )
        .fold(0.0, (sum, c) => sum + c.totalPrice);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Active',
              activeCount.toString(),
              Icons.pending_actions,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Completed',
              completedCount.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'Earnings',
              '\$${totalEarnings.toStringAsFixed(0)}',
              Icons.attach_money,
              Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionList(List<DirectCommissionModel> commissions) {
    if (commissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.art_track, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No commissions found',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by requesting a commission from an artist',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCommissions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: commissions.length,
        itemBuilder: (context, index) {
          final commission = commissions[index];
          return _buildCommissionCard(commission);
        },
      ),
    );
  }

  Widget _buildCommissionCard(DirectCommissionModel commission) {
    final isArtist = _isUserArtist(commission);
    final statusColor = _getStatusColor(commission.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openCommissionDetail(commission),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commission.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isArtist
                              ? 'Client: ${commission.clientName}'
                              : 'Artist: ${commission.artistName}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      commission.status.displayName,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Commission Details
              Row(
                children: [
                  Icon(
                    _getTypeIcon(commission.type),
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    commission.type.displayName,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(commission.requestedAt),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Price and Progress
              Row(
                children: [
                  if (commission.totalPrice > 0) ...[
                    Text(
                      '\$${commission.totalPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (commission.deadline != null) ...[
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: _isDeadlineClose(commission.deadline!)
                          ? Colors.red.shade600
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${_formatDate(commission.deadline!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _isDeadlineClose(commission.deadline!)
                            ? Colors.red.shade600
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),

              // Progress Bar for Active Commissions
              if ([
                CommissionStatus.accepted,
                CommissionStatus.inProgress,
              ].contains(commission.status)) ...[
                const SizedBox(height: 12),
                _buildProgressBar(commission),
              ],

              // Action Buttons
              if (_shouldShowActionButtons(commission)) ...[
                const SizedBox(height: 12),
                _buildActionButtons(commission),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(DirectCommissionModel commission) {
    final completedMilestones = commission.milestones
        .where(
          (m) =>
              m.status == MilestoneStatus.completed ||
              m.status == MilestoneStatus.paid,
        )
        .length;
    final totalMilestones = commission.milestones.length;
    final progress = totalMilestones > 0
        ? completedMilestones / totalMilestones
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Progress', style: Theme.of(context).textTheme.bodySmall),
            Text(
              '$completedMilestones/$totalMilestones milestones',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey.shade300,
          valueColor: const AlwaysStoppedAnimation<Color>(
            CommunityColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(DirectCommissionModel commission) {
    final isArtist = _isUserArtist(commission);

    return Row(
      children: [
        if (commission.status == CommissionStatus.pending && isArtist)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _provideQuote(commission),
              icon: const Icon(Icons.request_quote, size: 16),
              label: const Text('Provide Quote'),
            ),
          ),
        if (commission.status == CommissionStatus.quoted && !isArtist)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _acceptCommission(commission),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Accept Quote'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        if (commission.status == CommissionStatus.inProgress && isArtist)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _markCompleted(commission),
              icon: const Icon(Icons.done, size: 16),
              label: const Text('Mark Complete'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CommunityColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  bool _shouldShowActionButtons(DirectCommissionModel commission) {
    final isArtist = _isUserArtist(commission);
    return (commission.status == CommissionStatus.pending && isArtist) ||
        (commission.status == CommissionStatus.quoted && !isArtist) ||
        (commission.status == CommissionStatus.inProgress && isArtist);
  }

  Color _getStatusColor(CommissionStatus status) {
    switch (status) {
      case CommissionStatus.pending:
        return Colors.orange;
      case CommissionStatus.quoted:
        return Colors.blue;
      case CommissionStatus.accepted:
        return Colors.green;
      case CommissionStatus.inProgress:
        return Colors.purple;
      case CommissionStatus.revision:
        return Colors.amber;
      case CommissionStatus.completed:
        return Colors.green;
      case CommissionStatus.delivered:
        return Colors.teal;
      case CommissionStatus.cancelled:
        return Colors.red;
      case CommissionStatus.disputed:
        return Colors.red.shade800;
    }
  }

  IconData _getTypeIcon(CommissionType type) {
    switch (type) {
      case CommissionType.digital:
        return Icons.computer;
      case CommissionType.physical:
        return Icons.brush;
      case CommissionType.portrait:
        return Icons.person;
      case CommissionType.commercial:
        return Icons.business;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  bool _isDeadlineClose(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    return difference.inDays <= 3;
  }

  void _openCommissionDetail(DirectCommissionModel commission) {
    Navigator.push(
      context,
      MaterialPageRoute<CommissionDetailScreen>(
        builder: (context) => CommissionDetailScreen(commission: commission),
      ),
    ).then((_) => _loadCommissions());
  }

  void _showArtistSelection() async {
    final selectedArtist = await Navigator.push<core.ArtistProfileModel>(
      context,
      MaterialPageRoute(builder: (context) => const ArtistSelectionScreen()),
    );

    if (selectedArtist != null && mounted) {
      _showCommissionRequestDialog(selectedArtist);
    }
  }

  Future<void> _provideQuote(DirectCommissionModel commission) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _QuoteProvisionDialog(commission: commission),
    );

    if (result == true) {
      await _loadCommissions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quote provided successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _acceptCommission(DirectCommissionModel commission) async {
    try {
      await _commissionService.acceptCommission(commission.id);
      await _loadCommissions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commission accepted! Proceed to payment.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting commission: $e')),
        );
      }
    }
  }

  Future<void> _markCompleted(DirectCommissionModel commission) async {
    try {
      await _commissionService.completeCommission(commission.id);
      await _loadCommissions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commission marked as completed!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing commission: $e')),
        );
      }
    }
  }

  void _showCommissionRequestDialog(core.ArtistProfileModel selectedArtist) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final budgetController = TextEditingController();
    final deadlineController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request Commission from ${selectedArtist.displayName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Commission Title',
                  hintText: 'e.g., Portrait of my dog',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe what you want...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: budgetController,
                decoration: const InputDecoration(
                  labelText: 'Budget (USD)',
                  hintText: 'e.g., 150',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: deadlineController,
                decoration: const InputDecoration(
                  labelText: 'Deadline',
                  hintText: 'e.g., 2 weeks',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty ||
                  descriptionController.text.isEmpty ||
                  budgetController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                // Parse budget
                final budget = double.tryParse(budgetController.text) ?? 0.0;

                // Parse deadline
                final deadline = _parseDeadline(deadlineController.text);

                // Create commission request in Firestore
                await _commissionService.createCommissionRequest(
                  artistId: selectedArtist.id,
                  artistName: selectedArtist.displayName,
                  type: CommissionType
                      .digital, // Default to digital, can be enhanced later
                  title: titleController.text,
                  description: descriptionController.text,
                  specs: CommissionSpecs(
                    size:
                        'Custom', // Default values, can be enhanced with more fields
                    medium: 'Digital',
                    style: 'Custom',
                    colorScheme: 'Full Color',
                    revisions: 2,
                    commercialUse: false,
                    deliveryFormat: 'Digital File',
                    customRequirements: {
                      'budget': budget,
                      'notes': descriptionController.text,
                    },
                  ),
                  deadline: deadline,
                  metadata: {
                    'requestedVia': 'direct_request',
                    'budget': budget,
                  },
                );

                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
                if (mounted) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Commission request sent to ${selectedArtist.displayName}!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  // Refresh the commissions list
                  await _loadCommissions();
                }
              } catch (e) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error creating commission request: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Send Request'),
          ),
        ],
      ),
    );
  }

  DateTime? _parseDeadline(String deadline) {
    if (deadline.isEmpty) return null;

    final now = DateTime.now();
    final lowerDeadline = deadline.toLowerCase().trim();

    // Handle various deadline formats
    if (lowerDeadline.contains('week')) {
      // Extract number from "2-3 weeks", "1 week", etc.
      final weekMatch = RegExp(
        r'(\d+)(?:\s*-\s*\d+)?\s*week',
      ).firstMatch(lowerDeadline);
      if (weekMatch != null) {
        final weeks = int.tryParse(weekMatch.group(1) ?? '1') ?? 1;
        return now.add(Duration(days: weeks * 7));
      }
    } else if (lowerDeadline.contains('month')) {
      // Extract number from "2-3 months", "1 month", etc.
      final monthMatch = RegExp(
        r'(\d+)(?:\s*-\s*\d+)?\s*month',
      ).firstMatch(lowerDeadline);
      if (monthMatch != null) {
        final months = int.tryParse(monthMatch.group(1) ?? '1') ?? 1;
        return DateTime(now.year, now.month + months, now.day);
      }
    } else if (lowerDeadline.contains('day')) {
      // Extract number from "5-7 days", "1 day", etc.
      final dayMatch = RegExp(
        r'(\d+)(?:\s*-\s*\d+)?\s*day',
      ).firstMatch(lowerDeadline);
      if (dayMatch != null) {
        final days = int.tryParse(dayMatch.group(1) ?? '1') ?? 1;
        return now.add(Duration(days: days));
      }
    }

    // Try to parse as a direct date format (MM/dd/yyyy)
    try {
      final parts = deadline.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      // Invalid date format
    }

    // Default fallback: assume 30 days for unrecognized formats
    return now.add(const Duration(days: 30));
  }
}

/// Dialog for artists to provide quotes for commission requests
class _QuoteProvisionDialog extends StatefulWidget {
  final DirectCommissionModel commission;

  const _QuoteProvisionDialog({required this.commission});

  @override
  State<_QuoteProvisionDialog> createState() => _QuoteProvisionDialogState();
}

class _QuoteProvisionDialogState extends State<_QuoteProvisionDialog> {
  final DirectCommissionService _commissionService = DirectCommissionService();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _totalPriceController = TextEditingController();
  final _depositPercentageController = TextEditingController(text: '50');
  final _quoteMessageController = TextEditingController();

  // Milestones
  final List<_MilestoneData> _milestones = [];

  // Estimated completion
  DateTime? _estimatedCompletion;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize with one default milestone
    _addMilestone();
  }

  @override
  void dispose() {
    _totalPriceController.dispose();
    _depositPercentageController.dispose();
    _quoteMessageController.dispose();
    for (final milestone in _milestones) {
      milestone.dispose();
    }
    super.dispose();
  }

  void _addMilestone() {
    setState(() {
      _milestones.add(_MilestoneData());
    });
  }

  void _removeMilestone(int index) {
    if (index < 0 || index >= _milestones.length) {
      return;
    }
    setState(() {
      _milestones[index].dispose();
      _milestones.removeAt(index);
    });
  }

  Future<void> _selectEstimatedCompletion() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _estimatedCompletion ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _estimatedCompletion = picked;
      });
    }
  }

  Future<void> _submitQuote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_estimatedCompletion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an estimated completion date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_milestones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one milestone'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate all milestones
    for (int i = 0; i < _milestones.length; i++) {
      if (!_milestones[i].validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please complete milestone ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final totalPrice = double.parse(_totalPriceController.text);
      final depositPercentage = double.parse(_depositPercentageController.text);

      // Convert milestone data to CommissionMilestone objects
      final milestones = _milestones.map((m) {
        return CommissionMilestone(
          id:
              DateTime.now().millisecondsSinceEpoch.toString() +
              m.hashCode.toString(),
          title: m.titleController.text,
          description: m.descriptionController.text,
          amount: double.parse(m.amountController.text),
          dueDate: m.dueDate!,
          status: MilestoneStatus.pending,
        );
      }).toList();

      await _commissionService.provideQuote(
        commissionId: widget.commission.id,
        totalPrice: totalPrice,
        depositPercentage: depositPercentage,
        milestones: milestones,
        estimatedCompletion: _estimatedCompletion!,
        quoteMessage: _quoteMessageController.text.isNotEmpty
            ? _quoteMessageController.text
            : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error providing quote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final depositAmount =
        _totalPriceController.text.isNotEmpty &&
            _depositPercentageController.text.isNotEmpty
        ? (double.tryParse(_totalPriceController.text) ?? 0) *
              (double.tryParse(_depositPercentageController.text) ?? 0) /
              100
        : 0.0;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: CommunityColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.request_quote, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Provide Quote',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'For: ${widget.commission.clientName}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Commission details
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.commission.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.commission.description,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pricing section
                      const Text(
                        'Pricing',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _totalPriceController,
                              decoration: const InputDecoration(
                                labelText: 'Total Price',
                                prefixText: '\$',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid number';
                                }
                                if (double.parse(value) <= 0) {
                                  return 'Must be > 0';
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _depositPercentageController,
                              decoration: const InputDecoration(
                                labelText: 'Deposit %',
                                suffixText: '%',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final num = double.tryParse(value);
                                if (num == null) {
                                  return 'Invalid';
                                }
                                if (num < 0 || num > 100) {
                                  return '0-100';
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      if (depositAmount > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Deposit: \$${depositAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Estimated completion
                      const Text(
                        'Estimated Completion',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _selectEstimatedCompletion,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 20),
                              const SizedBox(width: 12),
                              Text(
                                _estimatedCompletion != null
                                    ? '${_estimatedCompletion!.month}/${_estimatedCompletion!.day}/${_estimatedCompletion!.year}'
                                    : 'Select date',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _estimatedCompletion != null
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Milestones section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Milestones',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addMilestone,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Milestone'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(_milestones.length, (index) {
                        return _MilestoneCard(
                          milestone: _milestones[index],
                          index: index,
                          onRemove: _milestones.length > 1
                              ? () => _removeMilestone(index)
                              : null,
                        );
                      }),
                      const SizedBox(height: 16),

                      // Quote message (optional)
                      const Text(
                        'Message to Client (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _quoteMessageController,
                        decoration: const InputDecoration(
                          hintText: 'Add any additional details or notes...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer with actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitQuote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CommunityColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Submit Quote'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper class to manage milestone form data
class _MilestoneData {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  DateTime? dueDate;

  bool validate() {
    return titleController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        amountController.text.isNotEmpty &&
        double.tryParse(amountController.text) != null &&
        dueDate != null;
  }

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    amountController.dispose();
  }
}

/// Widget for displaying and editing a milestone
class _MilestoneCard extends StatefulWidget {
  final _MilestoneData milestone;
  final int index;
  final VoidCallback? onRemove;

  const _MilestoneCard({
    required this.milestone,
    required this.index,
    this.onRemove,
  });

  @override
  State<_MilestoneCard> createState() => _MilestoneCardState();
}

class _MilestoneCardState extends State<_MilestoneCard> {
  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.milestone.dueDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        widget.milestone.dueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Milestone ${widget.index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                if (widget.onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: widget.onRemove,
                    color: Colors.red,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.milestone.titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.milestone.descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 2,
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widget.milestone.amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '\$',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Invalid';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: _selectDueDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.milestone.dueDate != null
                                  ? '${widget.milestone.dueDate!.month}/${widget.milestone.dueDate!.day}/${widget.milestone.dueDate!.year}'
                                  : 'Due date',
                              style: TextStyle(
                                fontSize: 14,
                                color: widget.milestone.dueDate != null
                                    ? Colors.black
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

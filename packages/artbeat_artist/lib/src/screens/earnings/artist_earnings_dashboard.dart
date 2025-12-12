import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../../services/earnings_service.dart';
import '../../models/earnings_model.dart';
import '../../models/payout_model.dart';
import 'payout_request_screen.dart';
import 'payout_accounts_screen.dart';

class ArtistEarningsDashboard extends StatefulWidget {
  const ArtistEarningsDashboard({super.key});

  @override
  State<ArtistEarningsDashboard> createState() =>
      _ArtistEarningsDashboardState();
}

class _ArtistEarningsDashboardState extends State<ArtistEarningsDashboard>
    with SingleTickerProviderStateMixin {
  final EarningsService _earningsService = EarningsService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final TabController _tabController;

  EarningsModel? _earnings;
  List<EarningsTransaction> _recentTransactions = [];
  List<PayoutModel> _recentPayouts = [];
  // Map<String, dynamic> _earningsSummary = {}; // Removed unused field
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEarningsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEarningsData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _earningsService.getArtistEarnings(),
        _earningsService.getEarningsTransactions(limit: 10),
        _earningsService.getPayoutHistory(limit: 5),
      ]);

      setState(() {
        _earnings = results[0] as EarningsModel?;
        _recentTransactions = results[1] as List<EarningsTransaction>;
        _recentPayouts = results[2] as List<PayoutModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: 1, // Artist tab
      scaffoldKey: _scaffoldKey,
      appBar: const core.EnhancedUniversalHeader(
        title: 'Earnings Dashboard',
        showBackButton: true,
        showSearch: false,
        showDeveloperTools: true,
        backgroundGradient: LinearGradient(
          colors: [Colors.green, Colors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        titleGradient: LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        foregroundColor: Colors.white,
      ),
      drawer: const core.ArtbeatDrawer(),
      child: Column(
        children: [
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_errorMessage != null)
            _buildErrorView()
          else ...[
            _buildEarningsOverview(),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.analytics), text: 'Overview'),
                Tab(icon: Icon(Icons.receipt), text: 'Transactions'),
                Tab(icon: Icon(Icons.account_balance), text: 'Payouts'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildTransactionsTab(),
                  _buildPayoutsTab(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                tr('art_walk_failed_to_load_earnings_data'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadEarningsData,
                child: Text(tr('art_walk_retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsOverview() {
    if (_earnings == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet,
                  color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  tr('art_walk_total_earnings'),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '\$${_earnings!.totalEarnings.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildEarningsCard(
                  'Available',
                  '\$${_earnings!.availableBalance.toStringAsFixed(2)}',
                  Colors.white.withValues(alpha: 0.9),
                  Colors.green[700]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEarningsCard(
                  'Pending',
                  '\$${_earnings!.pendingBalance.toStringAsFixed(2)}',
                  Colors.white.withValues(alpha: 0.9),
                  Colors.orange[700]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(
      String title, String amount, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
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
          _buildEarningsBreakdown(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildEarningsBreakdown() {
    if (_earnings == null) return const SizedBox.shrink();

    final breakdown = [
      {
        'label': 'Gifts',
        'amount': _earnings!.giftEarnings,
        'color': Colors.pink
      },
      {
        'label': 'Sponsorships',
        'amount': _earnings!.sponsorshipEarnings,
        'color': Colors.purple
      },
      {
        'label': 'Commissions',
        'amount': _earnings!.commissionEarnings,
        'color': Colors.blue
      },
      {
        'label': 'Subscriptions',
        'amount': _earnings!.subscriptionEarnings,
        'color': Colors.orange
      },
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('art_walk_earnings_breakdown'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...breakdown.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: item['color'] as Color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['label'] as String,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '\$${(item['amount'] as double).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                )),
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
              tr('art_walk_quick_actions'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _earnings?.availableBalance != null &&
                            _earnings!.availableBalance > 0
                        ? () => _navigateToPayoutRequest()
                        : null,
                    icon: const Icon(Icons.account_balance),
                    label: Text(tr('art_walk_request_payout')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _navigateToPayoutAccounts(),
                    icon: const Icon(Icons.settings),
                    label: Text(tr('art_walk_manage_accounts')),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    tr('art_walk_recent_activity'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: Text(tr('art_walk_view_all')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_recentTransactions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(tr('art_walk_no_recent_transactions')),
                ),
              )
            else
              ...(_recentTransactions
                  .take(5)
                  .map((transaction) => _buildTransactionItem(transaction))),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return RefreshIndicator(
      onRefresh: _loadEarningsData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recentTransactions.length,
        itemBuilder: (context, index) {
          final transaction = _recentTransactions[index];
          return _buildTransactionItem(transaction);
        },
      ),
    );
  }

  Widget _buildTransactionItem(EarningsTransaction transaction) {
    IconData icon;
    Color color;

    switch (transaction.type) {
      case 'gift':
        icon = Icons.card_giftcard;
        color = Colors.pink;
        break;
      case 'sponsorship':
        icon = Icons.handshake;
        color = Colors.purple;
        break;
      case 'commission':
        icon = Icons.brush;
        color = Colors.blue;
        break;
      case 'subscription':
        icon = Icons.subscriptions;
        color = Colors.orange;
        break;
      default:
        icon = Icons.attach_money;
        color = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(transaction.description),
        subtitle: Text(
          '${transaction.fromUserName} • ${_formatDate(transaction.timestamp)}',
        ),
        trailing: Text(
          '+\$${transaction.amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPayoutsTab() {
    return RefreshIndicator(
      onRefresh: _loadEarningsData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recentPayouts.length,
        itemBuilder: (context, index) {
          final payout = _recentPayouts[index];
          return _buildPayoutItem(payout);
        },
      ),
    );
  }

  Widget _buildPayoutItem(PayoutModel payout) {
    Color statusColor;
    IconData statusIcon;

    switch (payout.status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'failed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(tr('art_walk_payout_request')),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Requested: ${_formatDate(payout.requestedAt)}'),
            if (payout.processedAt != null)
              Text('Processed: ${_formatDate(payout.processedAt!)}'),
            if (payout.failureReason != null)
              Text(
                'Reason: ${payout.failureReason}',
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${payout.amount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              payout.status.toUpperCase(),
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToPayoutRequest() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => PayoutRequestScreen(
          availableBalance: _earnings?.availableBalance ?? 0.0,
          onPayoutRequested: _loadEarningsData,
        ),
      ),
    );
  }

  void _navigateToPayoutAccounts() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const PayoutAccountsScreen(),
      ),
    );
  }
}

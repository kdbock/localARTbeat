import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' as intl;
import 'package:artbeat_core/artbeat_core.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/transaction_model.dart';
import '../models/admin_permissions.dart';
import '../services/financial_service.dart';
import '../services/payment_audit_service.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_metrics_card.dart';
import '../widgets/admin_drawer.dart';

/// Comprehensive Admin Payment Management Screen
///
/// Features:
/// - 🔍 Advanced search and filtering
/// - 📊 Payment analytics dashboard
/// - 💰 Transaction details and management
/// - 🔄 Refund processing capabilities
/// - 📈 Revenue insights and reporting
/// - 📤 Export functionality
/// - 🎯 Dispute resolution tools
class AdminPaymentScreen extends StatefulWidget {
  const AdminPaymentScreen({super.key});

  @override
  State<AdminPaymentScreen> createState() => _AdminPaymentScreenState();
}

class _AdminPaymentScreenState extends State<AdminPaymentScreen>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Services
  final FinancialService _financialService = FinancialService();
  final PaymentAuditService _auditService = PaymentAuditService();
  final AdminRoleService _roleService = AdminRoleService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Data
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  Map<String, double> _revenueBreakdown = {};
  bool _isLoading = true;

  // Search and Filter
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _selectedType = 'All';
  DateTimeRange? _dateRange;
  double _minAmount = 0;
  double _maxAmount = 10000;

  // Bulk Operations
  final Set<String> _selectedTransactionIds = {};
  bool _isSelectionMode = false;
  bool _selectAll = false;

  // Analytics
  double _totalRevenue = 0;
  double _totalRefunds = 0;
  int _totalTransactions = 0;
  double _averageTransactionValue = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load transactions
      final transactions =
          await _financialService.getRecentTransactions(limit: 100);
      final revenueBreakdown = await _financialService.getRevenueBreakdown();

      // Calculate analytics
      _totalRevenue = transactions.fold(0.0, (sum, t) => sum + t.amount);
      _totalRefunds = transactions
          .where((t) => t.type.toLowerCase().contains('refund'))
          .fold(0.0, (sum, t) => sum + t.amount);
      _totalTransactions = transactions.length;
      _averageTransactionValue =
          _totalTransactions > 0 ? _totalRevenue / _totalTransactions : 0;

      setState(() {
        _transactions = transactions;
        _filteredTransactions = transactions;
        _revenueBreakdown = revenueBreakdown;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading payment data: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load payment data');
    }
  }

  void _filterTransactions() {
    setState(() {
      _filteredTransactions = _transactions.where((transaction) {
        // Search filter
        final searchTerm = _searchController.text.toLowerCase();
        final matchesSearch = searchTerm.isEmpty ||
            transaction.userName.toLowerCase().contains(searchTerm) ||
            transaction.id.toLowerCase().contains(searchTerm) ||
            (transaction.itemTitle?.toLowerCase().contains(searchTerm) ??
                false);

        // Status filter
        final matchesStatus =
            _selectedStatus == 'All' || transaction.status == _selectedStatus;

        // Type filter
        final matchesType =
            _selectedType == 'All' || transaction.type == _selectedType;

        // Date range filter
        final matchesDateRange = _dateRange == null ||
            (transaction.transactionDate.isAfter(_dateRange!.start) &&
                transaction.transactionDate.isBefore(_dateRange!.end));

        // Amount range filter
        final matchesAmount = transaction.amount >= _minAmount &&
            transaction.amount <= _maxAmount;

        return matchesSearch &&
            matchesStatus &&
            matchesType &&
            matchesDateRange &&
            matchesAmount;
      }).toList();
    });
  }

  Future<void> _processRefund(TransactionModel transaction) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin_admin_payment_text_process_refund'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('admin_admin_payment_text_transaction_transactionid'.tr()),
            Text('admin_admin_payment_text_amount_transactionformattedamount'.tr()),
            Text('admin_admin_payment_label_user_transactionusername'.tr()),
            const SizedBox(height: 16),
            Text('admin_admin_payment_text_are_you_sure'.tr()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('admin_admin_payment_text_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('admin_admin_payment_text_process_refund'.tr()),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        // Get current admin user
        final currentUser = FirebaseAuth.instance.currentUser;
        final adminUserId = currentUser?.uid ?? 'unknown_admin';
        final adminEmail = currentUser?.email ?? 'unknown';

        // Get payment intent ID from transaction metadata
        final paymentIntentId =
            transaction.metadata['paymentIntentId'] as String?;

        if (paymentIntentId != null) {
          // Process actual Stripe refund using PaymentService
          await PaymentService.refundPayment(
            paymentId: paymentIntentId,
            amount: transaction.amount,
            reason: 'Admin processed refund',
          );
        } else {
          // Fallback: Log warning if no payment intent ID
          AppLogger.warning(
            'No paymentIntentId found for transaction ${transaction.id}. '
            'Recording refund in database only.',
          );
        }

        // Record refund in database
        await _firestore.collection('refunds').add({
          'originalTransactionId': transaction.id,
          'paymentIntentId': paymentIntentId,
          'amount': transaction.amount,
          'currency': transaction.currency,
          'userId': transaction.userId,
          'userName': transaction.userName,
          'reason': 'Admin processed refund',
          'processedBy': adminUserId,
          'processedByEmail': adminEmail,
          'processedAt': FieldValue.serverTimestamp(),
          'status': 'completed',
        });

        // Update transaction status
        await _firestore
            .collection('payment_history')
            .doc(transaction.id)
            .update({
          'status': 'refunded',
          'refundedAt': FieldValue.serverTimestamp(),
          'refundedBy': adminUserId,
        });

        _showSuccessSnackBar('Refund processed successfully');
        _loadData(); // Refresh data
      } catch (e) {
        AppLogger.error('Error processing refund: $e');
        _showErrorSnackBar('Failed to process refund: ${e.toString()}');
      }
    }
  }

  Future<void> _processBulkRefund() async {
    if (_selectedTransactionIds.isEmpty) {
      _showErrorSnackBar('No transactions selected');
      return;
    }

    final selectedTransactions = _transactions
        .where((t) => _selectedTransactionIds.contains(t.id))
        .where((t) => t.status == 'completed')
        .toList();

    if (selectedTransactions.isEmpty) {
      _showErrorSnackBar('No eligible transactions for refund');
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin_admin_payment_text_bulk_refund'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${selectedTransactions.length} transactions selected'),
            Text(
                'Total amount: \$${selectedTransactions.fold(0.0, (sum, t) => sum + t.amount).toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text(
                'Are you sure you want to process refunds for all selected transactions?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('admin_admin_payment_text_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('admin_admin_payment_text_process_bulk_refunds'.tr()),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final currentAdmin = await _roleService.getCurrentAdmin();
        if (currentAdmin == null) {
          _showErrorSnackBar('Admin authentication required');
          return;
        }

        int successCount = 0;
        for (final transaction in selectedTransactions) {
          try {
            // Process individual refund
            await _firestore.collection('refunds').add({
              'originalTransactionId': transaction.id,
              'amount': transaction.amount,
              'currency': transaction.currency,
              'userId': transaction.userId,
              'userName': transaction.userName,
              'reason': 'Bulk admin refund',
              'processedBy': currentAdmin.id,
              'processedAt': FieldValue.serverTimestamp(),
              'status': 'completed',
            });

            // Update transaction status
            await _firestore
                .collection('payment_history')
                .doc(transaction.id)
                .update({
              'status': 'refunded',
              'refundedAt': FieldValue.serverTimestamp(),
            });

            // Log audit
            await _auditService.logRefundAction(
              adminId: currentAdmin.id,
              adminEmail: currentAdmin.email,
              transactionId: transaction.id,
              refundAmount: transaction.amount,
              reason: 'Bulk admin refund',
              userId: transaction.userId,
              notes: 'Part of bulk refund operation',
            );

            successCount++;
          } catch (e) {
            debugPrint('Failed to refund transaction ${transaction.id}: $e');
          }
        }

        _showSuccessSnackBar('Successfully processed $successCount refunds');
        _clearSelection();
        _loadData(); // Refresh data
      } catch (e) {
        debugPrint('Error processing bulk refund: $e');
        _showErrorSnackBar('Failed to process bulk refunds');
      }
    }
  }

  Future<void> _exportSelectedTransactions() async {
    if (_selectedTransactionIds.isEmpty) {
      _showErrorSnackBar('No transactions selected');
      return;
    }

    try {
      final currentAdmin = await _roleService.getCurrentAdmin();
      if (currentAdmin == null) {
        _showErrorSnackBar('Admin authentication required');
        return;
      }

      final selectedTransactions = _transactions
          .where((t) => _selectedTransactionIds.contains(t.id))
          .toList();

      // Generate CSV content
      final csvContent = _generateTransactionCsv(selectedTransactions);

      // Create file name with timestamp
      final fileName =
          'selected_transactions_${DateTime.now().millisecondsSinceEpoch}.csv';

      // Use file download functionality (web) or save to device
      await _downloadCsvFile(csvContent, fileName);

      // Log audit
      await _auditService.logDataExport(
        adminId: currentAdmin.id,
        adminEmail: currentAdmin.email,
        exportType: 'selected_transactions',
        recordCount: selectedTransactions.length,
        filters: {
          'selectedIds': _selectedTransactionIds.toList(),
          'exportFormat': 'csv',
        },
        fileName: fileName,
      );

      _showSuccessSnackBar(
          'Export completed successfully (${selectedTransactions.length} records)');
      _clearSelection();
    } catch (e) {
      debugPrint('Error exporting transactions: $e');
      _showErrorSnackBar('Failed to export transactions');
    }
  }

  Future<void> _exportTransactions() async {
    try {
      final currentAdmin = await _roleService.getCurrentAdmin();
      if (currentAdmin == null) {
        _showErrorSnackBar('Admin authentication required');
        return;
      }

      // Generate CSV content for all filtered transactions
      final csvContent = _generateTransactionCsv(_filteredTransactions);

      // Create file name with timestamp
      final fileName =
          'all_transactions_${DateTime.now().millisecondsSinceEpoch}.csv';

      // Use file download functionality (web) or save to device
      await _downloadCsvFile(csvContent, fileName);

      // Log audit
      await _auditService.logDataExport(
        adminId: currentAdmin.id,
        adminEmail: currentAdmin.email,
        exportType: 'all_transactions',
        recordCount: _filteredTransactions.length,
        filters: {
          'searchTerm': _searchController.text,
          'statusFilter': _selectedStatus,
          'typeFilter': _selectedType,
          'dateRange': _dateRange != null
              ? {
                  'start': _dateRange!.start.toIso8601String(),
                  'end': _dateRange!.end.toIso8601String(),
                }
              : null,
          'amountRange': {
            'min': _minAmount,
            'max': _maxAmount,
          },
          'exportFormat': 'csv',
        },
        fileName: fileName,
      );

      _showSuccessSnackBar(
          'Export completed successfully (${_filteredTransactions.length} records)');
    } catch (e) {
      debugPrint('Error exporting transactions: $e');
      _showErrorSnackBar('Failed to export transactions');
    }
  }

  Future<void> _bulkUpdateStatus(String newStatus) async {
    if (_selectedTransactionIds.isEmpty) {
      _showErrorSnackBar('No transactions selected');
      return;
    }

    try {
      final currentAdmin = await _roleService.getCurrentAdmin();
      if (currentAdmin == null) {
        _showErrorSnackBar('Admin authentication required');
        return;
      }

      final batch = _firestore.batch();
      final updateData = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': currentAdmin.id,
      };

      for (final transactionId in _selectedTransactionIds) {
        final docRef =
            _firestore.collection('payment_history').doc(transactionId);
        batch.update(docRef, updateData);

        // Log audit for each update
        await _auditService.logPaymentAction(
          adminId: currentAdmin.id,
          adminEmail: currentAdmin.email,
          action: 'STATUS_UPDATE',
          transactionId: transactionId,
          details: {
            'newStatus': newStatus,
            'previousStatus':
                _transactions.firstWhere((t) => t.id == transactionId).status,
            'bulkOperation': true,
          },
        );
      }

      await batch.commit();
      _showSuccessSnackBar(
          'Successfully updated ${_selectedTransactionIds.length} transactions');
      _clearSelection();
      _loadData(); // Refresh data
    } catch (e) {
      debugPrint('Error updating transaction statuses: $e');
      _showErrorSnackBar('Failed to update transaction statuses');
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _clearSelection();
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      _selectAll = !_selectAll;
      if (_selectAll) {
        _selectedTransactionIds.addAll(_filteredTransactions.map((t) => t.id));
      } else {
        _selectedTransactionIds.clear();
      }
    });
  }

  void _toggleTransactionSelection(String transactionId) {
    setState(() {
      if (_selectedTransactionIds.contains(transactionId)) {
        _selectedTransactionIds.remove(transactionId);
      } else {
        _selectedTransactionIds.add(transactionId);
      }

      // Update select all state
      _selectAll =
          _selectedTransactionIds.length == _filteredTransactions.length &&
              _filteredTransactions.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedTransactionIds.clear();
      _selectAll = false;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AdminHeader(
        title: 'Payment Management',
        actions: [
          IconButton(
            icon: Icon(_isSelectionMode
                ? Icons.check_box
                : Icons.check_box_outline_blank),
            onPressed: _toggleSelectionMode,
            tooltip: _isSelectionMode
                ? 'Exit Selection Mode'
                : 'Enter Selection Mode',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _selectedTransactionIds.isNotEmpty
                ? _exportSelectedTransactions
                : _exportTransactions,
            tooltip: _selectedTransactionIds.isNotEmpty
                ? 'Export Selected'
                : 'Export All',
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Analytics Overview Cards
                  _buildAnalyticsOverview(),

                  // Tab Bar
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Transactions', icon: Icon(Icons.receipt)),
                      Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
                      Tab(text: 'Refunds', icon: Icon(Icons.undo)),
                      Tab(text: 'Search', icon: Icon(Icons.search)),
                    ],
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).primaryColor,
                  ),

                  // Tab Content
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTransactionsTab(),
                        _buildAnalyticsTab(),
                        _buildRefundsTab(),
                        _buildSearchTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAnalyticsOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: AdminMetricsCard(
              title: 'Total Revenue',
              value: '\$${_totalRevenue.toStringAsFixed(2)}',
              icon: Icons.attach_money,
              color: Colors.green,
              trend: 12.5,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AdminMetricsCard(
              title: 'Total Transactions',
              value: _totalTransactions.toString(),
              icon: Icons.receipt,
              color: Colors.blue,
              trend: 8.2,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AdminMetricsCard(
              title: 'Avg Transaction',
              value: '\$${_averageTransactionValue.toStringAsFixed(2)}',
              icon: Icons.trending_up,
              color: Colors.orange,
              trend: 5.1,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AdminMetricsCard(
              title: 'Total Refunds',
              value: '\$${_totalRefunds.toStringAsFixed(2)}',
              icon: Icons.undo,
              color: Colors.red,
              trend: -2.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return Column(
      children: [
        // Quick Filters
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => _filterTransactions(),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedStatus,
                items: ['All', 'completed', 'pending', 'failed', 'refunded']
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(status.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedStatus = value!);
                  _filterTransactions();
                },
              ),
            ],
          ),
        ),

        // Bulk Operations Toolbar
        if (_isSelectionMode || _selectedTransactionIds.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Row(
              children: [
                Checkbox(
                  value: _selectAll,
                  onChanged: (value) => _toggleSelectAll(),
                ),
                Text('admin_admin_payment_text_select_all'.tr()),
                const SizedBox(width: 16),
                Text('${_selectedTransactionIds.length} selected'),
                const Spacer(),
                if (_selectedTransactionIds.isNotEmpty) ...[
                  ElevatedButton.icon(
                    onPressed: _processBulkRefund,
                    icon: const Icon(Icons.undo),
                    label: Text('admin_admin_payment_text_bulk_refund'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: _bulkUpdateStatus,
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'completed',
                        child: Text('admin_admin_payment_text_mark_as_completed'.tr()),
                      ),
                      PopupMenuItem(
                        value: 'pending',
                        child: Text('admin_admin_payment_text_mark_as_pending'.tr()),
                      ),
                      PopupMenuItem(
                        value: 'failed',
                        child: Text('admin_admin_payment_error_mark_as_failed'.tr()),
                      ),
                    ],
                    child: ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.edit),
                      label: Text('admin_admin_payment_text_update_status'.tr()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _exportSelectedTransactions,
                    icon: const Icon(Icons.file_download),
                    label: Text('admin_admin_payment_text_export_selected'.tr()),
                  ),
                ],
              ],
            ),
          ),

        // Transactions List
        Expanded(
          child: ListView.builder(
            itemCount: _filteredTransactions.length,
            itemBuilder: (context, index) {
              final transaction = _filteredTransactions[index];
              return _buildTransactionCard(transaction);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        leading: _isSelectionMode
            ? Checkbox(
                value: _selectedTransactionIds.contains(transaction.id),
                onChanged: (value) =>
                    _toggleTransactionSelection(transaction.id),
              )
            : CircleAvatar(
                backgroundColor: _getTransactionStatusColor(transaction.status),
                child: Icon(
                  _getTransactionIcon(transaction.type),
                  color: Colors.white,
                ),
              ),
        title: Text(
          transaction.formattedAmount,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${transaction.userName} • ${transaction.displayType}'),
        trailing: Chip(
          label: Text(transaction.status.toUpperCase()),
          backgroundColor: _getTransactionStatusColor(transaction.status)
              .withValues(alpha: 0.2),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('admin_admin_payment_text_transaction_id_transactionid'.tr()),
                Text(
                    'Date: ${intl.DateFormat('MMM dd, yyyy HH:mm').format(transaction.transactionDate)}'),
                Text('admin_admin_payment_text_payment_method_transactionpaymentmethod'.tr()),
                if (transaction.itemTitle != null) ...[
                  Text('admin_admin_payment_title_item_transactionitemtitle'.tr()),
                ],
                if (transaction.description != null) ...[
                  Text('admin_admin_payment_message_description_transactiondescription'.tr()),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (transaction.status == 'completed') ...[
                      TextButton.icon(
                        onPressed: () => _processRefund(transaction),
                        icon: const Icon(Icons.undo, color: Colors.red),
                        label: const Text('Process Refund',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                    TextButton.icon(
                      onPressed: () => _showTransactionDetails(transaction),
                      icon: const Icon(Icons.info),
                      label: Text('admin_admin_payment_text_details'.tr()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Breakdown',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._revenueBreakdown.entries.map((entry) => ListTile(
                title: Text(entry.key),
                trailing: Text('admin_admin_payment_text_entryvaluetostringasfixed2'.tr()),
                leading: const Icon(Icons.pie_chart),
              )),
          const SizedBox(height: 32),
          const Text(
            'Payment Methods',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Payment method analytics
          ..._buildPaymentMethodAnalytics(),
        ],
      ),
    );
  }

  List<Widget> _buildPaymentMethodAnalytics() {
    // Group transactions by payment method
    final paymentMethodStats = <String, Map<String, dynamic>>{};

    for (final transaction in _transactions) {
      final method = transaction.paymentMethod;
      if (!paymentMethodStats.containsKey(method)) {
        paymentMethodStats[method] = {
          'count': 0,
          'totalAmount': 0.0,
          'successful': 0,
          'failed': 0,
        };
      }

      paymentMethodStats[method]!['count']++;
      paymentMethodStats[method]!['totalAmount'] += transaction.amount;

      if (transaction.status == 'completed' ||
          transaction.status == 'success') {
        paymentMethodStats[method]!['successful']++;
      } else if (transaction.status == 'failed') {
        paymentMethodStats[method]!['failed']++;
      }
    }

    // Convert to sorted list for display
    final sortedMethods = paymentMethodStats.entries.toList()
      ..sort((a, b) => (b.value['totalAmount'] as double)
          .compareTo(a.value['totalAmount'] as double));

    return sortedMethods.map<Widget>((entry) {
      final method = entry.key;
      final stats = entry.value;
      final count = stats['count'] as int;
      final totalAmount = stats['totalAmount'] as double;
      final successful = stats['successful'] as int;
      final successRate = count > 0 ? (successful / count * 100) : 0.0;

      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getPaymentMethodIcon(method),
                    color: _getPaymentMethodColor(method),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    method.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem('Transactions', count.toString()),
                  ),
                  Expanded(
                    child: _buildStatItem(
                        'Success Rate', '${successRate.toStringAsFixed(1)}%'),
                  ),
                  Expanded(
                    child: _buildStatItem('Avg Amount',
                        '\$${(totalAmount / count).toStringAsFixed(2)}'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: successRate / 100,
                backgroundColor: Colors.red.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(
                  successRate >= 90
                      ? Colors.green
                      : successRate >= 70
                          ? Colors.orange
                          : Colors.red,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'card':
      case 'credit_card':
        return Icons.credit_card;
      case 'paypal':
        return Icons.account_balance_wallet;
      case 'apple_pay':
        return Icons.apple;
      case 'google_pay':
        return Icons.g_mobiledata;
      case 'bank_transfer':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentMethodColor(String method) {
    switch (method.toLowerCase()) {
      case 'card':
      case 'credit_card':
        return Colors.blue;
      case 'paypal':
        return Colors.blue.shade700;
      case 'apple_pay':
        return Colors.black;
      case 'google_pay':
        return Colors.green;
      case 'bank_transfer':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRefundsTab() {
    final refundTransactions =
        _transactions.where((t) => t.status == 'refunded').toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.undo, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                '${refundTransactions.length} Refunds',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                'Total: \$${refundTransactions.fold(0.0, (sum, t) => sum + t.amount).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: refundTransactions.length,
            itemBuilder: (context, index) {
              return _buildTransactionCard(refundTransactions[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Advanced Search & Filters',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Date Range
          ListTile(
            title: Text('admin_admin_payment_text_date_range'.tr()),
            subtitle: Text(_dateRange == null
                ? 'All dates'
                : '${intl.DateFormat('MMM dd').format(_dateRange!.start)} - ${intl.DateFormat('MMM dd').format(_dateRange!.end)}'),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _dateRange,
              );
              if (picked != null) {
                setState(() => _dateRange = picked);
                _filterTransactions();
              }
            },
          ),

          // Amount Range
          const SizedBox(height: 16),
          const Text('Amount Range',
              style: TextStyle(fontWeight: FontWeight.bold)),
          RangeSlider(
            values: RangeValues(_minAmount, _maxAmount),
            min: 0,
            max: 10000,
            divisions: 100,
            labels: RangeLabels(
                '\$${_minAmount.toInt()}', '\$${_maxAmount.toInt()}'),
            onChanged: (values) {
              setState(() {
                _minAmount = values.start;
                _maxAmount = values.end;
              });
              _filterTransactions();
            },
          ),

          // Transaction Type
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _selectedType,
            decoration: const InputDecoration(labelText: 'Transaction Type'),
            items: [
              'All',
              'subscription',
              'artwork_purchase',
              'ad_payment',
              'commission'
            ]
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.replaceAll('_', ' ').toUpperCase()),
                    ))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedType = value!);
              _filterTransactions();
            },
          ),

          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _selectedStatus = 'All';
                _selectedType = 'All';
                _dateRange = null;
                _minAmount = 0;
                _maxAmount = 10000;
              });
              _filterTransactions();
            },
            icon: const Icon(Icons.clear),
            label: Text('admin_admin_payment_text_clear_all_filters'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(TransactionModel transaction) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin_admin_payment_text_transaction_details'.tr()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', transaction.id),
              _buildDetailRow('User', transaction.userName),
              _buildDetailRow('Amount', transaction.formattedAmount),
              _buildDetailRow('Type', transaction.displayType),
              _buildDetailRow('Status', transaction.status.toUpperCase()),
              _buildDetailRow('Payment Method', transaction.paymentMethod),
              _buildDetailRow(
                  'Date',
                  intl.DateFormat('MMM dd, yyyy HH:mm')
                      .format(transaction.transactionDate)),
              if (transaction.itemTitle != null)
                _buildDetailRow('Item', transaction.itemTitle!),
              if (transaction.description != null)
                _buildDetailRow('Description', transaction.description!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('admin_admin_payment_text_close'.tr()),
          ),
        ],
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
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Color _getTransactionStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type.toLowerCase()) {
      case 'subscription':
        return Icons.subscriptions;
      case 'artwork_purchase':
        return Icons.palette;
      case 'ad_payment':
        return Icons.campaign;
      case 'commission':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  /// Generate CSV content for transactions
  String _generateTransactionCsv(List<TransactionModel> transactions) {
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln(
        'Transaction ID,User ID,User Name,Type,Amount,Currency,Status,Payment Method,Transaction Date,Description,Item Title');

    // CSV Data rows
    for (final transaction in transactions) {
      final description =
          transaction.description?.replaceAll(',', ';') ?? ''; // Escape commas
      final itemTitle =
          transaction.itemTitle?.replaceAll(',', ';') ?? ''; // Escape commas
      final transactionDate = transaction.transactionDate.toIso8601String();

      buffer.writeln(
        '${transaction.id},${transaction.userId},"${transaction.userName}",${transaction.type},${transaction.amount},${transaction.currency},${transaction.status},${transaction.paymentMethod},"$transactionDate","$description","$itemTitle"',
      );
    }

    return buffer.toString();
  }

  /// Download CSV file (web) or save to device
  Future<void> _downloadCsvFile(String csvContent, String fileName) async {
    try {
      if (kIsWeb) {
        // Web implementation using data URL for download
        final bytes = utf8.encode(csvContent);
        final base64Data = base64Encode(bytes);
        final dataUrl = 'data:text/csv;charset=utf-8;base64,$base64Data';

        // Use url_launcher to open the data URL (triggers download)
        if (await canLaunchUrl(Uri.parse(dataUrl))) {
          await launchUrl(Uri.parse(dataUrl));
        } else {
          // Fallback: show content in dialog with copy option
          if (mounted) {
            showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('admin_admin_payment_label_download_filename'.tr()),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('admin_admin_payment_button_click_below_to'.tr()),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(
                            ClipboardData(text: csvContent));
                        if (mounted) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('admin_admin_payment_text_csv_content_copied'.tr())),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: Text('admin_admin_payment_text_copy_to_clipboard'.tr()),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('admin_admin_payment_text_close'.tr()),
                  ),
                ],
              ),
            );
          }
        }
      } else {
        // Mobile implementation using path_provider and share_plus
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(csvContent);

        // Share the file
        await SharePlus.instance.share(
          ShareParams(
            text: 'Exported transaction data',
            subject: 'Transaction Export',
          ),
        );
      }
    } catch (e) {
      debugPrint('Error downloading CSV file: $e');
      throw Exception('Failed to download CSV file');
    }
  }
}

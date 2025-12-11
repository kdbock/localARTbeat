import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../../services/earnings_service.dart';
import '../../models/payout_model.dart';

class PayoutAccountsScreen extends StatefulWidget {
  const PayoutAccountsScreen({super.key});

  @override
  State<PayoutAccountsScreen> createState() => _PayoutAccountsScreenState();
}

class _PayoutAccountsScreenState extends State<PayoutAccountsScreen> {
  final EarningsService _earningsService = EarningsService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  List<PayoutAccountModel> _accounts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accounts = await _earningsService.getPayoutAccounts();
      setState(() {
        _accounts = accounts;
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
      currentIndex: -1,
      scaffoldKey: _scaffoldKey,
      appBar: core.EnhancedUniversalHeader(
        title: 'Payout Accounts',
        showBackButton: true,
        showSearch: false,
        showDeveloperTools: true,
        backgroundGradient: const LinearGradient(
          colors: [Colors.green, Colors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        titleGradient: const LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _showAddAccountDialog(),
            icon: const Icon(Icons.add),
            tooltip: 'Add Account',
          ),
        ],
      ),
      drawer: const core.ArtbeatDrawer(),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (_accounts.isEmpty) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      onRefresh: _loadAccounts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _accounts.length,
        itemBuilder: (context, index) {
          final account = _accounts[index];
          return _buildAccountCard(account);
        },
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('art_walk_failed_to_load_payout_accounts'.tr(),
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
              onPressed: _loadAccounts,
              child: const Text('art_walk_retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text('art_walk_no_payout_accounts'.tr(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text('art_walk_add_a_bank_account_or_paypal_account_to_receive_your_earnings'.tr(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddAccountDialog(),
              icon: const Icon(Icons.add),
              label: const Text('art_walk_add_payout_account'.tr()),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(PayoutAccountModel account) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: account.isVerified
                      ? Colors.green[100]
                      : Colors.orange[100],
                  child: Icon(
                    account.accountType == 'bank_account'
                        ? Icons.account_balance
                        : Icons.payment,
                    color: account.isVerified
                        ? Colors.green[700]
                        : Colors.orange[700],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.accountHolderName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        account.accountType == 'bank_account'
                            ? '${account.bankName ?? 'Bank Account'} •••• ${account.accountNumber.length >= 4 ? account.accountNumber.substring(account.accountNumber.length - 4) : account.accountNumber}'
                            : 'PayPal Account',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleAccountAction(value, account),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('art_walk_edit'.tr()),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('art_walk_delete'.tr(), style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatusChip(
                  account.isVerified ? 'Verified' : 'Pending Verification',
                  account.isVerified ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                _buildStatusChip(
                  account.isActive ? 'Active' : 'Inactive',
                  account.isActive ? Colors.blue : Colors.grey,
                ),
              ],
            ),
            if (!account.isVerified) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('art_walk_account_verification_is_pending__you_cannot_receive_payouts_until_verification_is_complete'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _handleAccountAction(String action, PayoutAccountModel account) {
    switch (action) {
      case 'edit':
        _showEditAccountDialog(account);
        break;
      case 'delete':
        _confirmDeleteAccount(account);
        break;
    }
  }

  void _showAddAccountDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => _AddAccountDialog(
        onAccountAdded: _loadAccounts,
      ),
    );
  }

  void _showEditAccountDialog(PayoutAccountModel account) {
    showDialog<void>(
      context: context,
      builder: (context) => _EditAccountDialog(
        account: account,
        onAccountUpdated: _loadAccounts,
      ),
    );
  }

  void _confirmDeleteAccount(PayoutAccountModel account) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('art_walk_delete_account'.tr()),
        content: const Text('art_walk_are_you_sure_you_want_to_delete_this_payout_account__this_action_cannot_be_undone'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('art_walk_cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount(account);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('art_walk_delete'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(PayoutAccountModel account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('art_walk_delete_account'.tr()),
        content: Text(
          'Are you sure you want to delete the account "${account.displayName}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('art_walk_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('art_walk_delete'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _earningsService.deletePayoutAccount(account.id);
      await _loadAccounts(); // Refresh the list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('art_walk_account_deleted_successfully'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _AddAccountDialog extends StatefulWidget {
  final VoidCallback onAccountAdded;

  const _AddAccountDialog({required this.onAccountAdded});

  @override
  State<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<_AddAccountDialog> {
  final EarningsService _earningsService = EarningsService();
  final _formKey = GlobalKey<FormState>();
  final _accountHolderNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _routingNumberController = TextEditingController();
  final _bankNameController = TextEditingController();

  String _accountType = 'bank_account';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _accountHolderNameController.dispose();
    _accountNumberController.dispose();
    _routingNumberController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('art_walk_add_payout_account'.tr(),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _accountType,
                decoration: const InputDecoration(
                  labelText: 'Account Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'bank_account',
                    child: Text('art_walk_bank_account'.tr()),
                  ),
                  DropdownMenuItem(
                    value: 'paypal',
                    child: Text('art_walk_paypal'.tr()),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _accountType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _accountHolderNameController,
                decoration: const InputDecoration(
                  labelText: 'Account Holder Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the account holder name';
                  }
                  return null;
                },
              ),
              if (_accountType == 'bank_account') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bankNameController,
                  decoration: const InputDecoration(
                    labelText: 'Bank Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _accountNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Account Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the account number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _routingNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Routing Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the routing number';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('art_walk_cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addAccount,
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('art_walk_add_account'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _earningsService.addPayoutAccount(
        accountType: _accountType,
        accountNumber: _accountNumberController.text,
        routingNumber: _routingNumberController.text,
        accountHolderName: _accountHolderNameController.text,
        bankName: _bankNameController.text.isNotEmpty
            ? _bankNameController.text
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onAccountAdded();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('art_walk_payout_account_added_successfully'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class _EditAccountDialog extends StatefulWidget {
  final PayoutAccountModel account;
  final VoidCallback onAccountUpdated;

  const _EditAccountDialog({
    required this.account,
    required this.onAccountUpdated,
  });

  @override
  State<_EditAccountDialog> createState() => _EditAccountDialogState();
}

class _EditAccountDialogState extends State<_EditAccountDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('art_walk_edit_account'.tr()),
      content: const Text('art_walk_account_editing_functionality_coming_soon'.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('art_walk_close'.tr()),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';import 'package:artbeat_core/artbeat_core.dart' as core;
import '../../services/earnings_service.dart';
import '../../models/payout_model.dart';

class PayoutRequestScreen extends StatefulWidget {
  final double availableBalance;
  final VoidCallback onPayoutRequested;

  const PayoutRequestScreen({
    super.key,
    required this.availableBalance,
    required this.onPayoutRequested,
  });

  @override
  State<PayoutRequestScreen> createState() => _PayoutRequestScreenState();
}

class _PayoutRequestScreenState extends State<PayoutRequestScreen> {
  final EarningsService _earningsService = EarningsService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  List<PayoutAccountModel> _payoutAccounts = [];
  PayoutAccountModel? _selectedAccount;
  bool _isLoading = false;
  bool _isLoadingAccounts = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPayoutAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadPayoutAccounts() async {
    setState(() {
      _isLoadingAccounts = true;
      _errorMessage = null;
    });

    try {
      final accounts = await _earningsService.getPayoutAccounts();
      setState(() {
        _payoutAccounts = accounts;
        if (accounts.isNotEmpty) {
          _selectedAccount = accounts.first;
        }
        _isLoadingAccounts = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoadingAccounts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: -1,
      scaffoldKey: _scaffoldKey,
      appBar: const core.EnhancedUniversalHeader(
        title: 'Request Payout',
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
      child: _isLoadingAccounts
          ? const Center(child: CircularProgressIndicator())
          : _buildPayoutForm(),
    );
  }

  Widget _buildPayoutForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(),
            const SizedBox(height: 24),
            _buildAmountSection(),
            const SizedBox(height: 24),
            _buildAccountSection(),
            const SizedBox(height: 24),
            _buildPayoutInfo(),
            const SizedBox(height: 32),
            if (_errorMessage != null) ...[
              _buildErrorMessage(),
              const SizedBox(height: 16),
            ],
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.green[700]),
                const SizedBox(width: 12),
                Text(tr('art_walk_available_balance'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '\$${widget.availableBalance.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(tr('art_walk_this_is_the_amount_available_for_payout_after_processing_fees'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('art_walk_payout_amount'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (\$)',
                prefixIcon: Icon(Icons.attach_money),
                border: OutlineInputBorder(),
                helperText: 'Enter the amount you want to withdraw',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an amount';
                }

                final amount = double.tryParse(value);
                if (amount == null) {
                  return 'Please enter a valid amount';
                }

                if (amount <= 0) {
                  return 'Amount must be greater than 0';
                }

                if (amount > widget.availableBalance) {
                  return 'Amount exceeds available balance';
                }

                if (amount < 10) {
                  return 'Minimum payout amount is \$10';
                }

                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _amountController.text =
                          (widget.availableBalance * 0.25).toStringAsFixed(2);
                    },
                    child: Text(tr('art_walk_25')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _amountController.text =
                          (widget.availableBalance * 0.5).toStringAsFixed(2);
                    },
                    child: Text(tr('art_walk_50')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _amountController.text =
                          (widget.availableBalance * 0.75).toStringAsFixed(2);
                    },
                    child: Text(tr('art_walk_75')),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _amountController.text =
                          widget.availableBalance.toStringAsFixed(2);
                    },
                    child: Text(tr('art_walk_all')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(tr('art_walk_payout_account'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // Navigate to add account screen
                    Navigator.pushNamed(context, '/artist/payout-accounts');
                  },
                  icon: const Icon(Icons.add),
                  label: Text(tr('art_walk_add_account')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_payoutAccounts.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.account_balance,
                        color: Colors.orange[700], size: 48),
                    const SizedBox(height: 12),
                    Text(tr('art_walk_no_payout_accounts'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(tr('art_walk_you_need_to_add_a_payout_account_before_requesting_a_payout'),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/artist/payout-accounts');
                      },
                      icon: const Icon(Icons.add),
                      label: Text(tr('art_walk_add_payout_account')),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<PayoutAccountModel>(
                initialValue: _selectedAccount,
                decoration: const InputDecoration(
                  labelText: 'Select Account',
                  border: OutlineInputBorder(),
                ),
                items: _payoutAccounts.map((account) {
                  return DropdownMenuItem(
                    value: account,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.accountHolderName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${account.bankName ?? 'Bank'} •••• ${account.accountNumber.length >= 4 ? account.accountNumber.substring(account.accountNumber.length - 4) : account.accountNumber}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (account) {
                  setState(() {
                    _selectedAccount = account;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a payout account';
                  }
                  return null;
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Text(tr('art_walk_payout_information'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Processing Time', '1-3 business days'),
            _buildInfoRow('Processing Fee', '2.9% + \$0.30'),
            _buildInfoRow('Minimum Amount', '\$10.00'),
            _buildInfoRow('Maximum Amount', 'Available balance'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(tr('art_walk_payouts_are_processed_securely_through_our_payment_partner__you_will_receive_an_email_confirmation_once_the_payout_is_initiated'),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
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
    );
  }

  Widget _buildSubmitButton() {
    final canSubmit = _payoutAccounts.isNotEmpty && !_isLoading;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: canSubmit ? _submitPayoutRequest : null,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: Colors.green[700],
          foregroundColor: Colors.white,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(tr('art_walk_request_payout'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _submitPayoutRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccount == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final amount = double.parse(_amountController.text);

      await _earningsService.requestPayout(
        amount: amount,
        payoutAccountId: _selectedAccount!.id,
      );

      if (mounted) {
        widget.onPayoutRequested();
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payout request submitted successfully! You will receive \$${amount.toStringAsFixed(2)} in 1-3 business days.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
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

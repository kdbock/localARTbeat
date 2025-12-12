import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show PaymentService, EnhancedUniversalHeader, MainLayout;

/// Screen for handling subscription refunds
class RefundRequestScreen extends StatefulWidget {
  final String subscriptionId;
  final String paymentId;
  final double amount;

  const RefundRequestScreen({
    super.key,
    required this.subscriptionId,
    required this.paymentId,
    required this.amount,
  });

  @override
  State<RefundRequestScreen> createState() => _RefundRequestScreenState();
}

class _RefundRequestScreenState extends State<RefundRequestScreen> {
  final PaymentService _paymentService = PaymentService();
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;

  final List<String> _refundReasons = [
    'Not satisfied with service',
    'Features not as expected',
    'Found better alternative',
    'Technical issues',
    'Financial reasons',
    'Other'
  ];

  String _selectedReason = 'Not satisfied with service';

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitRefundRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Request refund via PaymentService
      final result = await _paymentService.requestRefund(
        paymentId: widget.paymentId,
        subscriptionId: widget.subscriptionId,
        reason:
            '$_selectedReason\nAdditional Details: ${_reasonController.text}',
      );

      if (result['status'] != 'succeeded') {
        throw Exception('Refund request failed. Please try again.');
      }

      if (mounted) {
        // Show success dialog
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tr('artist_refund_request_text_refund_request_submitted')),
            content: const Text(
              'Your refund request has been submitted and will be reviewed. '
              'We\'ll contact you within 2-3 business days with the status of your request.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(tr('common_ok')),
              ),
            ],
          ),
        );

        // Return to previous screen
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate success
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error submitting refund request: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: const EnhancedUniversalHeader(
          title: 'Request Refund',
          showLogo: false,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payment information
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('art_walk_refund_information'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tr('artist_refund_request_text_payment_amount')),
                            Text(
                              '\$${widget.amount.toStringAsFixed(2)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(tr('artist_refund_request_text_payment_id')),
                            Text(
                              '${widget.paymentId.substring(0, 10)}...',
                              style: const TextStyle(fontFamily: 'Monospace'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(tr('art_walk_note__refunds_are_processed_within_5_7_business_days_______________________________depending_on_your_payment_method_and_financial_institution'),
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Refund reason dropdown
                Text(tr('art_walk_reason_for_refund'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedReason,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: _refundReasons.map((reason) {
                    return DropdownMenuItem(
                      value: reason,
                      child: Text(reason),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a reason';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Additional details
                Text(tr('art_walk_additional_details'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText:
                        'Please provide any additional information about your refund request',
                  ),
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please provide additional details';
                    }
                    if (value.length < 10) {
                      return 'Please provide more detailed information';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _submitRefundRequest,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isProcessing
                        ? const CircularProgressIndicator()
                        : Text(tr('artist_refund_request_text_submit_refund_request')),
                  ),
                ),

                const SizedBox(height: 32),

                // Refund policy
                const Text(
                  'Refund Policy',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(tr('art_walk_refund_requests_are_reviewed_on_a_case_by_case_basis_______________________pro_rated_refunds_may_be_issued_for_unused_subscription_time_______________________please_allow_5_7_business_days_for_your_refund_to_process_after_approval'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

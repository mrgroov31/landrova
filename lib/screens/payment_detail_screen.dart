import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'package:intl/intl.dart';

class PaymentDetailScreen extends StatefulWidget {
  final Payment payment;

  const PaymentDetailScreen({super.key, required this.payment});

  @override
  State<PaymentDetailScreen> createState() => _PaymentDetailScreenState();
}

class _PaymentDetailScreenState extends State<PaymentDetailScreen> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final statusColor = widget.payment.status == 'paid'
        ? Colors.green
        : widget.payment.status == 'overdue'
            ? Colors.red
            : Colors.orange;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.getSurfaceColor(context),
        foregroundColor: AppTheme.getTextPrimaryColor(context),
        title: const Text(
          'Payment Details',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editPayment();
                  break;
                case 'delete':
                  _deletePayment();
                  break;
                case 'duplicate':
                  _duplicatePayment();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Duplicate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Status Card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(isMobile ? 20 : 24),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Icon(
                      widget.payment.status == 'paid'
                          ? Icons.check_circle
                          : widget.payment.status == 'overdue'
                              ? Icons.error
                              : Icons.pending,
                      color: statusColor,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.payment.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${widget.payment.amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                  ),
                  if (widget.payment.lateFee > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '+₹${widget.payment.lateFee.toStringAsFixed(0)} late fee',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Payment Information
            _buildInfoSection(
              'Payment Information',
              [
                _buildInfoRow('Tenant', widget.payment.tenantName),
                _buildInfoRow('Room Number', widget.payment.roomNumber),
                _buildInfoRow('Payment Type', widget.payment.type),
                _buildInfoRow('Month/Year', '${widget.payment.month} ${widget.payment.year}'),
                _buildInfoRow('Due Date', dateFormat.format(widget.payment.dueDate)),
                if (widget.payment.paidDate != null)
                  _buildInfoRow('Paid Date', dateFormat.format(widget.payment.paidDate!)),
                if (widget.payment.paymentMethod != null)
                  _buildInfoRow('Payment Method', widget.payment.paymentMethod!),
                if (widget.payment.transactionId != null)
                  _buildInfoRow('Transaction ID', widget.payment.transactionId!),
              ],
              isMobile,
            ),

            const SizedBox(height: 24),

            // Additional Details
            if (widget.payment.notes != null && widget.payment.notes!.isNotEmpty)
              _buildInfoSection(
                'Notes',
                [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.getTextSecondaryColor(context).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.payment.notes!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                  ),
                ],
                isMobile,
              ),

            const SizedBox(height: 32),

            // Action Buttons
            if (widget.payment.status != 'paid') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _markAsPaid,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.check_circle),
                  label: Text(
                    _isProcessing ? 'Processing...' : 'Mark as Paid',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Send Reminder Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _sendReminder,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 16 : 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.notifications),
                label: const Text(
                  'Send Reminder',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children, bool isMobile) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getTextSecondaryColor(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextPrimaryColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsPaid() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final success = await PaymentService.markPaymentAsPaid(
        paymentId: widget.payment.id,
        tenantId: widget.payment.tenantId,
        amount: widget.payment.amount,
        paymentMethod: 'manual',
        transactionId: 'MANUAL_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment marked as paid successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true); // Return true to indicate update
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to mark payment as paid'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _sendReminder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment reminder sent to tenant!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _editPayment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit payment functionality coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _deletePayment() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text('Are you sure you want to delete this payment record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete functionality coming soon!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _duplicatePayment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Duplicate payment functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
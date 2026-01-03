import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class PaymentsScreen extends StatefulWidget {
  final String? heroTag;
  
  const PaymentsScreen({super.key, this.heroTag});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Payment> payments = [];
  bool isLoading = true;
  String? error;
  String filter = 'all'; // all, paid, pending, overdue

  @override
  void initState() {
    super.initState();
    loadPayments();
  }

  Future<void> loadPayments() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });
      
      final response = await ApiService.fetchPayments();
      final loadedPayments = ApiService.parsePayments(response);
      
      setState(() {
        payments = loadedPayments;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  List<Payment> get filteredPayments {
    if (filter == 'all') return payments;
    return payments.where((p) => p.status == filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Payments',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary Cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total',
                    '₹${payments.fold(0.0, (sum, p) => sum + p.amount).toStringAsFixed(0)}',
                    Colors.blue,
                    isMobile,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Paid',
                    '₹${payments.where((p) => p.status == 'paid').fold(0.0, (sum, p) => sum + p.amount).toStringAsFixed(0)}',
                    Colors.green,
                    isMobile,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Pending',
                    '₹${payments.where((p) => p.status == 'pending').fold(0.0, (sum, p) => sum + p.amount).toStringAsFixed(0)}',
                    Colors.orange,
                    isMobile,
                  ),
                ),
              ],
            ),
          ),
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', isMobile),
                  const SizedBox(width: 8),
                  _buildFilterChip('Paid', 'paid', isMobile),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending', 'pending', isMobile),
                  const SizedBox(width: 8),
                  _buildFilterChip('Overdue', 'overdue', isMobile),
                ],
              ),
            ),
          ),
          // Payments List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text('Error: $error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: loadPayments,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredPayments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.payment_outlined, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                Text(
                                  'No payments found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: loadPayments,
                            child: ListView.builder(
                              padding: EdgeInsets.all(isMobile ? 16 : 24),
                              itemCount: filteredPayments.length,
                              itemBuilder: (context, index) {
                                final payment = filteredPayments[index];
                                final statusColor = payment.status == 'paid'
                                    ? Colors.green
                                    : payment.status == 'overdue'
                                        ? Colors.red
                                        : Colors.orange;
                                
                                return Card(
                                  margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.all(isMobile ? 16 : 20),
                                    leading: Container(
                                      width: isMobile ? 56 : 64,
                                      height: isMobile ? 56 : 64,
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        payment.status == 'paid'
                                            ? Icons.check_circle
                                            : payment.status == 'overdue'
                                                ? Icons.error
                                                : Icons.pending,
                                        color: statusColor,
                                        size: isMobile ? 28 : 32,
                                      ),
                                    ),
                                    title: Text(
                                      payment.tenantName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        Text('Room ${payment.roomNumber}'),
                                        const SizedBox(height: 4),
                                        Text('Due: ${dateFormat.format(payment.dueDate)}'),
                                        if (payment.paidDate != null)
                                          Text('Paid: ${dateFormat.format(payment.paidDate!)}'),
                                        if (payment.paymentMethod != null)
                                          Text('Method: ${payment.paymentMethod}'),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${payment.amount.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: isMobile ? 18 : 20,
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            payment.status.toUpperCase(),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      // Navigate to payment detail
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Record new payment
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.payment, color: Colors.white),
        label: const Text(
          'Record Payment',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isMobile) {
    final isSelected = filter == value;
    return SizedBox(
      height: 40, // Fixed height for all chips
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            filter = value;
          });
        },
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[700] ?? Colors.grey,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      ),
    );
  }
}


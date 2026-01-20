import 'package:flutter/material.dart';
import '../models/payment.dart';
import '../models/payment_transaction.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';
import '../utils/payment_test_helper.dart';
import 'payment_detail_screen.dart';
import 'record_payment_screen.dart';
import 'package:intl/intl.dart';

class PaymentsScreen extends StatefulWidget {
  final String? heroTag;
  final String? selectedBuildingId;
  
  const PaymentsScreen({super.key, this.heroTag, this.selectedBuildingId});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> with TickerProviderStateMixin {
  List<Payment> payments = [];
  List<PaymentTransaction> transactions = [];
  bool isLoading = true;
  String? error;
  String filter = 'all'; // all, paid, pending, overdue
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize payment service and run tests
    PaymentService.initialize().then((_) {
      PaymentTestHelper.logPaymentSystemStatus();
    });
    
    loadPaymentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> loadPaymentData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });
      
      final ownerId = AuthService.getOwnerId();
      
      // Use real PaymentService API instead of mock data
      final paymentData = await PaymentService.getOwnerPayments(
        ownerId: ownerId,
        buildingId: widget.selectedBuildingId,
      );
      
      var loadedPayments = <Payment>[];
      if (paymentData['payments'] != null) {
        final paymentsJson = paymentData['payments'] as List;
        loadedPayments = paymentsJson.map((p) => Payment.fromJson(p)).toList();
        debugPrint('💳 [Payments Screen] Loaded ${loadedPayments.length} real payments from API');
      } else {
        debugPrint('💳 [Payments Screen] No payments found in API response');
      }
      
      // Load recent transactions using PaymentService
      final recentTransactions = <PaymentTransaction>[];
      // Note: We could add a method to get recent transactions if needed
      
      setState(() {
        payments = loadedPayments;
        transactions = recentTransactions;
        isLoading = false;
      });
      
      // Log payment data for testing
      PaymentTestHelper.logPaymentData(loadedPayments);
      PaymentTestHelper.logTransactionData(recentTransactions);
      
      // Log revenue calculations
      final stats = paymentStatistics;
      PaymentTestHelper.logRevenueCalculation(
        stats['paidAmount'] as double,
        (stats['pendingAmount'] as double) + (stats['overdueAmount'] as double),
        [45000, 52000, 48000, 55000, 60000, 58000], // Mock monthly data
      );
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

  Map<String, dynamic> get paymentStatistics {
    final totalAmount = payments.fold(0.0, (sum, p) => sum + p.amount);
    final paidAmount = payments.where((p) => p.status == 'paid').fold(0.0, (sum, p) => sum + p.amount);
    final pendingAmount = payments.where((p) => p.status == 'pending').fold(0.0, (sum, p) => sum + p.amount);
    final overdueAmount = payments.where((p) => p.status == 'overdue').fold(0.0, (sum, p) => sum + p.amount);
    
    final totalCount = payments.length;
    final paidCount = payments.where((p) => p.status == 'paid').length;
    final pendingCount = payments.where((p) => p.status == 'pending').length;
    final overdueCount = payments.where((p) => p.status == 'overdue').length;
    
    final collectionRate = totalCount > 0 ? (paidCount / totalCount) * 100 : 0.0;
    
    return {
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'pendingAmount': pendingAmount,
      'overdueAmount': overdueAmount,
      'totalCount': totalCount,
      'paidCount': paidCount,
      'pendingCount': pendingCount,
      'overdueCount': overdueCount,
      'collectionRate': collectionRate,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.getSurfaceColor(context),
        foregroundColor: AppTheme.getTextPrimaryColor(context),
        title: const Text(
          'Payment Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportPayments(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  loadPaymentData();
                  break;
                case 'settings':
                  _showPaymentSettings();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.getTextSecondaryColor(context),
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Payments', icon: Icon(Icons.payment)),
            Tab(text: 'Transactions', icon: Icon(Icons.receipt_long)),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _buildErrorState()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(isMobile),
                    _buildPaymentsTab(isMobile),
                    _buildTransactionsTab(isMobile),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _recordNewPayment(),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.payment, color: Colors.white),
        label: const Text(
          'Record Payment',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Error: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: loadPaymentData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(bool isMobile) {
    final stats = paymentStatistics;
    
    return RefreshIndicator(
      onRefresh: loadPaymentData,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue Summary Cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isMobile ? 2 : 4,
              childAspectRatio: 1.2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _buildStatCard(
                  'Total Revenue',
                  '₹${(stats['paidAmount'] as double).toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                  Colors.green,
                  isMobile,
                ),
                _buildStatCard(
                  'Pending',
                  '₹${(stats['pendingAmount'] as double).toStringAsFixed(0)}',
                  Icons.pending,
                  Colors.orange,
                  isMobile,
                ),
                _buildStatCard(
                  'Overdue',
                  '₹${(stats['overdueAmount'] as double).toStringAsFixed(0)}',
                  Icons.warning,
                  Colors.red,
                  isMobile,
                ),
                _buildStatCard(
                  'Collection Rate',
                  '${(stats['collectionRate'] as double).toStringAsFixed(1)}%',
                  Icons.trending_up,
                  Colors.blue,
                  isMobile,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Payment Status Distribution
            Text(
              'Payment Status Distribution',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimaryColor(context),
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildPaymentDistributionChart(stats, isMobile),
            
            const SizedBox(height: 32),
            
            // Recent Activity
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextPrimaryColor(context),
              ),
            ),
            
            const SizedBox(height: 16),
            
            _buildRecentActivity(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsTab(bool isMobile) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Column(
      children: [
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
          child: filteredPayments.isEmpty
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
                  onRefresh: loadPaymentData,
                  child: ListView.builder(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    itemCount: filteredPayments.length,
                    itemBuilder: (context, index) {
                      final payment = filteredPayments[index];
                      return _buildPaymentCard(payment, isMobile, dateFormat);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildTransactionsTab(bool isMobile) {
    return transactions.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No transactions found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'UPI transactions will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: loadPaymentData,
            child: ListView.builder(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return _buildTransactionCard(transaction, isMobile);
              },
            ),
          );
  }

  Widget _buildPaymentCard(Payment payment, bool isMobile, DateFormat dateFormat) {
    final statusColor = payment.status == 'paid'
        ? Colors.green
        : payment.status == 'overdue'
            ? Colors.red
            : Colors.orange;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 16 : 18,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Room ${payment.roomNumber} • ${payment.type}',
              style: TextStyle(
                color: AppTheme.getTextSecondaryColor(context),
                fontSize: isMobile ? 13 : 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Due: ${dateFormat.format(payment.dueDate)}',
              style: TextStyle(
                color: AppTheme.getTextSecondaryColor(context),
                fontSize: isMobile ? 12 : 13,
              ),
            ),
            if (payment.paidDate != null)
              Text(
                'Paid: ${dateFormat.format(payment.paidDate!)}',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: isMobile ? 12 : 13,
                ),
              ),
            if (payment.paymentMethod != null)
              Text(
                'Method: ${payment.paymentMethod}',
                style: TextStyle(
                  color: AppTheme.getTextSecondaryColor(context),
                  fontSize: isMobile ? 12 : 13,
                ),
              ),
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
            if (payment.lateFee > 0) ...[
              const SizedBox(height: 2),
              Text(
                '+₹${payment.lateFee.toStringAsFixed(0)} fee',
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: Colors.red,
                ),
              ),
            ],
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
        onTap: () => _showPaymentDetail(payment),
      ),
    );
  }

  Widget _buildTransactionCard(PaymentTransaction transaction, bool isMobile) {
    final statusColor = transaction.isSuccessful
        ? Colors.green
        : transaction.isFailed
            ? Colors.red
            : Colors.orange;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    transaction.paymentTypeDisplayName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 16 : 18,
                      color: AppTheme.getTextPrimaryColor(context),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    transaction.statusDisplayName.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${transaction.tenantName} • Room ${transaction.roomNumber}',
              style: TextStyle(
                color: AppTheme.getTextSecondaryColor(context),
                fontSize: isMobile ? 13 : 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transaction.formattedAmount,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(transaction.createdAt),
                  style: TextStyle(
                    color: AppTheme.getTextSecondaryColor(context),
                    fontSize: isMobile ? 12 : 13,
                  ),
                ),
              ],
            ),
            if (transaction.upiTransactionId != null) ...[
              const SizedBox(height: 8),
              Text(
                'UPI ID: ${transaction.upiTransactionId}',
                style: TextStyle(
                  color: AppTheme.getTextSecondaryColor(context),
                  fontSize: isMobile ? 11 : 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: isMobile ? 24 : 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isMobile ? 12 : 14,
              color: AppTheme.getTextSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDistributionChart(Map<String, dynamic> stats, bool isMobile) {
    final paidCount = stats['paidCount'] as int;
    final pendingCount = stats['pendingCount'] as int;
    final overdueCount = stats['overdueCount'] as int;
    final totalCount = stats['totalCount'] as int;

    if (totalCount == 0) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No payment data available',
            style: TextStyle(
              color: AppTheme.getTextSecondaryColor(context),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDistributionItem('Paid', paidCount, Colors.green, totalCount),
              _buildDistributionItem('Pending', pendingCount, Colors.orange, totalCount),
              _buildDistributionItem('Overdue', overdueCount, Colors.red, totalCount),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionItem(String label, int count, Color color, int total) {
    final percentage = total > 0 ? (count / total) * 100 : 0.0;
    
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextPrimaryColor(context),
          ),
        ),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.getTextSecondaryColor(context),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivity(bool isMobile) {
    final recentPayments = payments
        .where((p) => p.paidDate != null)
        .toList()
      ..sort((a, b) => b.paidDate!.compareTo(a.paidDate!));

    if (recentPayments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No recent activity',
            style: TextStyle(
              color: AppTheme.getTextSecondaryColor(context),
            ),
          ),
        ),
      );
    }

    return Container(
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
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentPayments.take(5).length,
        separatorBuilder: (context, index) => Divider(
          color: AppTheme.getTextSecondaryColor(context).withOpacity(0.1),
        ),
        itemBuilder: (context, index) {
          final payment = recentPayments[index];
          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
            ),
            title: Text(
              payment.tenantName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppTheme.getTextPrimaryColor(context),
              ),
            ),
            subtitle: Text(
              'Room ${payment.roomNumber} • ${payment.type}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.getTextSecondaryColor(context),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${payment.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  DateFormat('MMM dd').format(payment.paidDate!),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isMobile) {
    final isSelected = filter == value;
    return SizedBox(
      height: 40,
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

  // Action methods
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Payments'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter tenant name or room number',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            // Implement search functionality
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _exportPayments() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showPaymentSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Payment Reminders'),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
              ),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Auto Late Fees'),
              trailing: Switch(
                value: false,
                onChanged: (value) {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _recordNewPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecordPaymentScreen(),
      ),
    ).then((_) => loadPaymentData());
  }

  void _showPaymentDetail(Payment payment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentDetailScreen(payment: payment),
      ),
    ).then((_) => loadPaymentData());
  }
}
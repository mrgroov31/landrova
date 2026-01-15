import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/payment.dart';
import '../models/payment_transaction.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../utils/payment_test_helper.dart';
import 'upi_debug_screen.dart';
import 'package:intl/intl.dart';

class TenantPaymentScreen extends StatefulWidget {
  const TenantPaymentScreen({super.key});

  @override
  State<TenantPaymentScreen> createState() => _TenantPaymentScreenState();
}

class _TenantPaymentScreenState extends State<TenantPaymentScreen> with TickerProviderStateMixin {
  List<Payment> _pendingPayments = [];
  List<PaymentTransaction> _paymentHistory = [];
  Map<String, dynamic> _paymentStats = {};
  List<UpiApp> _availableUpiApps = [];
  bool _isLoading = true;
  bool _isProcessingPayment = false;
  String? _processingPaymentId; // Track which payment is being processed
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializePaymentService();
    _loadPaymentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializePaymentService() async {
    await PaymentService.initialize();
    setState(() {
      _availableUpiApps = PaymentService.getAvailableUpiApps();
    });
    
    // Log UPI system status for testing
    PaymentTestHelper.logPaymentSystemStatus();
  }

  Future<void> _loadPaymentData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = AuthService.currentUser;
      if (user != null && user.isTenant) {
        final tenantId = user.additionalData?['tenantId'] as String? ?? user.id;
        
        final results = await Future.wait([
          PaymentService.getPendingPayments(tenantId),
          PaymentService.getPaymentHistory(tenantId),
          PaymentService.getPaymentStatistics(tenantId),
        ]);

        setState(() {
          _pendingPayments = results[0] as List<Payment>;
          _paymentHistory = results[1] as List<PaymentTransaction>;
          _paymentStats = results[2] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load payment data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Payments'),
        backgroundColor: AppTheme.getSurfaceColor(context),
        foregroundColor: AppTheme.getTextPrimaryColor(context),
        elevation: 0,
        actions: [
          // Debug button for testing UPI on physical device
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UpiDebugScreen(),
                ),
              );
            },
            icon: const Icon(Icons.bug_report),
            tooltip: 'UPI Debug',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.getTextSecondaryColor(context),
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
            Tab(text: 'History', icon: Icon(Icons.history)),
            Tab(text: 'Statistics', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPendingPaymentsTab(isMobile),
                _buildPaymentHistoryTab(isMobile),
                _buildStatisticsTab(isMobile),
              ],
            ),
    );
  }

  Widget _buildPendingPaymentsTab(bool isMobile) {
    if (_pendingPayments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No pending payments',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All your payments are up to date!',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getTextSecondaryColor(context),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPaymentData,
      child: ListView.builder(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        itemCount: _pendingPayments.length,
        itemBuilder: (context, index) {
          return _buildPendingPaymentCard(_pendingPayments[index], isMobile);
        },
      ),
    );
  }

  Widget _buildPendingPaymentCard(Payment payment, bool isMobile) {
    final isOverdue = payment.status == 'overdue';
    final dueDate = payment.dueDate;
    final daysOverdue = isOverdue ? DateTime.now().difference(dueDate).inDays : 0;

    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue 
              ? Colors.red.withOpacity(0.3)
              : AppTheme.getTextSecondaryColor(context).withOpacity(0.2),
          width: isOverdue ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isOverdue 
                ? Colors.red.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${payment.type} Payment',
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextPrimaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Room ${payment.roomNumber} • ${payment.month} ${payment.year}',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: AppTheme.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOverdue 
                        ? Colors.red.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isOverdue ? Colors.red : Colors.orange,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isOverdue ? 'OVERDUE' : 'PENDING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isOverdue ? Colors.red : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Amount and Due Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        color: AppTheme.getTextSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${payment.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: isMobile ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Due Date',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        color: AppTheme.getTextSecondaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(dueDate),
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                        color: isOverdue ? Colors.red : AppTheme.getTextPrimaryColor(context),
                      ),
                    ),
                    if (isOverdue) ...[
                      const SizedBox(height: 2),
                      Text(
                        '$daysOverdue ${daysOverdue == 1 ? 'day' : 'days'} overdue',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Payment Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessingPayment 
                    ? null 
                    : () => _showPaymentOptions(payment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOverdue ? Colors.red : AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isProcessingPayment
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.payment),
                label: Text(
                  _isProcessingPayment ? 'Processing...' : 'Pay Now',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
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

  Widget _buildPaymentHistoryTab(bool isMobile) {
    if (_paymentHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppTheme.getTextSecondaryColor(context).withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No payment history',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your payment transactions will appear here',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.getTextSecondaryColor(context),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPaymentData,
      child: ListView.builder(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        itemCount: _paymentHistory.length,
        itemBuilder: (context, index) {
          return _buildPaymentHistoryCard(_paymentHistory[index], isMobile);
        },
      ),
    );
  }

  Widget _buildPaymentHistoryCard(PaymentTransaction transaction, bool isMobile) {
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
          color: AppTheme.getTextSecondaryColor(context).withOpacity(0.2),
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.paymentTypeDisplayName,
                        style: TextStyle(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextPrimaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Room ${transaction.roomNumber} • ${transaction.month} ${transaction.year}',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: AppTheme.getTextSecondaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor, width: 1),
                  ),
                  child: Text(
                    transaction.statusDisplayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Amount and Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transaction.formattedAmount,
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimaryColor(context),
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(transaction.createdAt),
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: AppTheme.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
            
            if (transaction.upiTransactionId != null) ...[
              const SizedBox(height: 12),
              Text(
                'Transaction ID: ${transaction.upiTransactionId}',
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12,
                  color: AppTheme.getTextSecondaryColor(context),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTab(bool isMobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 2 : 4,
            childAspectRatio: 1.2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            children: [
              _buildStatCard(
                'Total Paid',
                '₹${(_paymentStats['totalPaid'] ?? 0.0).toStringAsFixed(0)}',
                Icons.check_circle,
                Colors.green,
                isMobile,
              ),
              _buildStatCard(
                'Pending',
                '₹${(_paymentStats['totalPending'] ?? 0.0).toStringAsFixed(0)}',
                Icons.pending,
                Colors.orange,
                isMobile,
              ),
              _buildStatCard(
                'Overdue',
                '${_paymentStats['overdueCount'] ?? 0}',
                Icons.warning,
                Colors.red,
                isMobile,
              ),
              _buildStatCard(
                'Success Rate',
                '${(_paymentStats['successRate'] ?? 0.0).toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.blue,
                isMobile,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Payment Methods Section
          Text(
            'Available Payment Methods',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
          
          const SizedBox(height: 16),
          
          if (_availableUpiApps.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.getCardColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.getTextSecondaryColor(context).withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.payment,
                    size: 48,
                    color: AppTheme.getTextSecondaryColor(context).withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No UPI apps found',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.getTextSecondaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please install a UPI app like PhonePe, Google Pay, or Paytm',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.getTextSecondaryColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...(_availableUpiApps.map((app) => _buildUpiAppCard(app, isMobile))),
        ],
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

  Widget _buildUpiAppCard(UpiApp app, bool isMobile) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.getTextSecondaryColor(context).withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.payment,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.name,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'UPI Payment App',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: AppTheme.getTextSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 24,
          ),
        ],
      ),
    );
  }

  void _showPaymentOptions(Payment payment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildPaymentOptionsSheet(payment),
    );
  }

  Widget _buildPaymentOptionsSheet(Payment payment) {
    final isMobile = Responsive.isMobile(context);
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.getTextSecondaryColor(context),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Title
          Text(
            'Choose Payment Method',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextPrimaryColor(context),
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Pay ₹${payment.amount.toStringAsFixed(0)} for ${payment.type} - Room ${payment.roomNumber}',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: AppTheme.getTextSecondaryColor(context),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // UPI Apps
          if (_availableUpiApps.isNotEmpty) ...[
            Text(
              'UPI Apps',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextPrimaryColor(context),
              ),
            ),
            
            const SizedBox(height: 16),
            
            ...(_availableUpiApps.map((app) => _buildUpiAppOption(app, payment, isMobile))),
            
            const SizedBox(height: 16),
          ],
          
          // Demo Payment Option
          ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
            ),
            title: Text(
              'Mark as Paid (Demo)',
              style: TextStyle(
                fontSize: isMobile ? 16 : 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.getTextPrimaryColor(context),
              ),
            ),
            subtitle: Text(
              'For testing purposes only',
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: AppTheme.getTextSecondaryColor(context),
              ),
            ),
            onTap: () => _processTestPayment(payment),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUpiAppOption(UpiApp app, Payment payment, bool isMobile) {
    final isProcessingThisPayment = _processingPaymentId == payment.id;
    
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: isProcessingThisPayment 
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.payment, color: AppTheme.primaryColor, size: 24),
      ),
      title: Text(
        app.name,
        style: TextStyle(
          fontSize: isMobile ? 16 : 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.getTextPrimaryColor(context),
        ),
      ),
      subtitle: Text(
        isProcessingThisPayment ? 'Processing payment...' : 'Pay via ${app.name}',
        style: TextStyle(
          fontSize: isMobile ? 13 : 14,
          color: AppTheme.getTextSecondaryColor(context),
        ),
      ),
      onTap: isProcessingThisPayment ? null : () => _processUpiPayment(payment, app),
    );
  }

  Future<void> _processUpiPayment(Payment payment, UpiApp app) async {
    Navigator.pop(context); // Close bottom sheet
    
    setState(() {
      _isProcessingPayment = true;
      _processingPaymentId = payment.id;
    });

    try {
      final user = AuthService.currentUser;
      if (user == null) throw Exception('User not logged in');

      final tenantId = user.additionalData?['tenantId'] as String? ?? user.id;
      
      // Get owner UPI details (mock for now)
      final ownerUpiDetails = await PaymentService.getOwnerUpiDetails('owner123');
      if (ownerUpiDetails == null) {
        throw Exception('Owner UPI details not found');
      }

      final transaction = await PaymentService.initiateUpiPayment(
        tenantId: tenantId,
        tenantName: user.name,
        ownerId: 'owner123', // This should come from payment data
        ownerName: ownerUpiDetails['name'] ?? 'Property Owner',
        ownerUpiId: ownerUpiDetails['upiId'] ?? 'owner@paytm',
        amount: payment.amount,
        roomNumber: payment.roomNumber,
        paymentType: payment.type,
        month: payment.month,
        year: payment.year,
        paymentId: payment.id, // Pass the payment ID for backend API
        preferredApp: app,
      );

      if (mounted) {
        if (transaction.isSuccessful) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment completed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadPaymentData(); // Refresh data
        } else if (transaction.isFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment failed: ${transaction.errorMessage ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment launched successfully! Complete it in your UPI app.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
          _processingPaymentId = null;
        });
      }
    }
  }

  Future<void> _processTestPayment(Payment payment) async {
    Navigator.pop(context); // Close bottom sheet
    
    setState(() {
      _isProcessingPayment = true;
      _processingPaymentId = payment.id;
    });

    try {
      final user = AuthService.currentUser;
      if (user == null) throw Exception('User not logged in');

      final tenantId = user.additionalData?['tenantId'] as String? ?? user.id;
      
      final success = await PaymentService.markPaymentAsPaid(
        paymentId: payment.id,
        tenantId: tenantId,
        amount: payment.amount,
        paymentMethod: 'demo',
        transactionId: 'DEMO_${DateTime.now().millisecondsSinceEpoch}',
        upiTransactionId: 'UPI_DEMO_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment marked as paid successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadPaymentData(); // Refresh data
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
          _isProcessingPayment = false;
          _processingPaymentId = null;
        });
      }
    }
  }
}
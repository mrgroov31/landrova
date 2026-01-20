import 'package:flutter/material.dart';
import 'package:own_house/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/payment.dart';
import '../models/payment_transaction.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../utils/payment_test_helper.dart';
import 'upi_debug_screen.dart';
import 'notification_center_screen.dart';
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

  /// Complete payment flow implementation
  Future<void> _processPayment(Payment payment) async {
    if (_isProcessingPayment) return;

    setState(() {
      _isProcessingPayment = true;
      _processingPaymentId = payment.id;
    });

    try {
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final ownerId = AuthService.getOwnerId();
      
      // Fetch real owner UPI details
      debugPrint('🔍 [PAYMENT] Fetching owner UPI details for: $ownerId');
      final ownerUpiResponse = await ApiService.getOwnerUpiDetails(ownerId);
      
      String ownerUpiId = 'owner@paytm'; // Fallback
      String ownerName = 'Property Owner'; // Fallback
      
      if (ownerUpiResponse['success'] == true && ownerUpiResponse['data'] != null) {
        final upiData = ownerUpiResponse['data'];
        ownerUpiId = upiData['upiId'] ?? 'owner@paytm';
        ownerName = upiData['ownerName'] ?? 'Property Owner';
        debugPrint('✅ [PAYMENT] Using real owner UPI ID: $ownerUpiId');
        debugPrint('✅ [PAYMENT] Using real owner name: $ownerName');
      } else {
        debugPrint('⚠️ [PAYMENT] Could not fetch owner UPI details, using fallback');
        debugPrint('💡 [PAYMENT] Owner should set up UPI details in Settings');
      }

      // Step 1 & 2: Create and initiate payment
      final result = await PaymentService.createAndInitiatePayment(
        tenantId: user.additionalData?['tenantId'] as String? ?? user.id,
        tenantName: payment.tenantName,
        ownerId: ownerId,
        ownerName: ownerName, // Real owner name from API
        ownerUpiId: ownerUpiId, // Real UPI ID from API
        roomId: payment.id, // Using payment ID as room ID for now
        roomNumber: payment.roomNumber,
        paymentType: payment.type,
        amount: payment.amount,
        month: payment.month,
        year: payment.year,
        description: 'Payment for ${payment.type} - ${payment.month} ${payment.year}',
        dueDate: payment.dueDate,
        lateFee: payment.lateFee,
      );

      if (!result['success']) {
        throw Exception('Failed to initiate payment');
      }

      final upiUrl = result['upiUrl'] as String;
      final paymentId = result['paymentId'] as String;
      final transactionId = result['transactionId'] as String;

      // Log UPI URL details for verification
      debugPrint('🔗 [PAYMENT] Generated UPI URL: $upiUrl');
      if (upiUrl.contains('pa=')) {
        final paMatch = RegExp(r'pa=([^&]+)').firstMatch(upiUrl);
        if (paMatch != null) {
          debugPrint('💳 [PAYMENT] UPI ID in URL: ${paMatch.group(1)}');
        }
      }
      if (upiUrl.contains('pn=')) {
        final pnMatch = RegExp(r'pn=([^&]+)').firstMatch(upiUrl);
        if (pnMatch != null) {
          debugPrint('👤 [PAYMENT] Payee Name in URL: ${Uri.decodeComponent(pnMatch.group(1) ?? '')}');
        }
      }

      // Step 3: Launch UPI app
      final launched = await PaymentService.launchUpiPayment(upiUrl);
      
      if (!launched) {
        throw Exception('Failed to launch UPI app. Please ensure you have a UPI app installed.');
      }

      // Show payment processing dialog
      if (mounted) {
        _showPaymentProcessingDialog(
          paymentId: paymentId,
          transactionId: transactionId,
          amount: payment.amount + payment.lateFee,
          payment: payment,
        );
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
      setState(() {
        _isProcessingPayment = false;
        _processingPaymentId = null;
      });
    }
  }

  /// Show payment processing dialog with options
  void _showPaymentProcessingDialog({
    required String paymentId,
    required String transactionId,
    required double amount,
    required Payment payment,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Processing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Processing payment of ₹${amount.toStringAsFixed(0)}'),
            const SizedBox(height: 8),
            const Text(
              'Please complete the payment in your UPI app and return here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handlePaymentResult(
                paymentId: paymentId,
                transactionId: transactionId,
                amount: amount,
                success: false,
                payment: payment,
              );
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handlePaymentResult(
                paymentId: paymentId,
                transactionId: transactionId,
                amount: amount,
                success: true,
                payment: payment,
              );
            },
            child: const Text('Payment Done'),
          ),
        ],
      ),
    );
  }

  /// Handle payment result (Step 5)
  Future<void> _handlePaymentResult({
    required String paymentId,
    required String transactionId,
    required double amount,
    required bool success,
    required Payment payment,
  }) async {
    try {
      final status = success ? 'paid' : 'failed';
      
      final updated = await PaymentService.updatePaymentStatus(
        paymentId: paymentId,
        transactionId: transactionId,
        status: status,
        upiTransactionId: success ? 'UPI${DateTime.now().millisecondsSinceEpoch}' : null,
        paidAmount: success ? amount : null,
        errorMessage: success ? null : 'Payment cancelled by user',
        additionalData: {
          'tenantName': AuthService.currentUser?.name ?? 'Tenant',
          'roomNumber': payment.roomNumber,
          'paymentType': payment.type,
        },
      );

      if (updated) {
        // Refresh payment data
        await _loadPaymentData();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(success 
                  ? 'Payment completed successfully!' 
                  : 'Payment was cancelled'),
              backgroundColor: success ? Colors.green : Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update payment status: $e'),
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
          // Notification bell with badge
          ValueListenableBuilder<int>(
            valueListenable: NotificationService.unreadCountNotifier,
            builder: (context, unreadCount, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NotificationCenterScreen(),
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const UpiDebugScreen(),
                ),
              );
            },
            tooltip: 'UPI Debug',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.getTextSecondaryColor(context),
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'History'),
            Tab(text: 'Statistics'),
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
              Icons.payment,
              size: 64,
              color: AppTheme.getTextSecondaryColor(context),
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
          final payment = _pendingPayments[index];
          return _buildPendingPaymentCard(payment, isMobile);
        },
      ),
    );
  }

  Widget _buildPendingPaymentCard(Payment payment, bool isMobile) {
    final isOverdue = payment.dueDate.isBefore(DateTime.now());
    final isProcessing = _processingPaymentId == payment.id;
    final totalAmount = payment.amount + payment.lateFee;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.getSurfaceColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${payment.type.toUpperCase()} - ${payment.month} ${payment.year}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Room ${payment.roomNumber}',
                        style: TextStyle(
                          color: AppTheme.getTextSecondaryColor(context),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOverdue ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isOverdue ? 'OVERDUE' : 'PENDING',
                    style: TextStyle(
                      color: isOverdue ? Colors.red : Colors.orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Amount details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amount:',
                  style: TextStyle(
                    color: AppTheme.getTextSecondaryColor(context),
                  ),
                ),
                Text(
                  '₹${payment.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            
            if (payment.lateFee > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Late Fee:',
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                  Text(
                    '₹${payment.lateFee.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '₹${totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Due Date:',
                  style: TextStyle(
                    color: AppTheme.getTextSecondaryColor(context),
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(payment.dueDate),
                  style: TextStyle(
                    color: isOverdue ? Colors.red : AppTheme.getTextPrimaryColor(context),
                    fontWeight: isOverdue ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Pay button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isProcessing ? null : () => _processPayment(payment),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Pay ₹${totalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
              color: AppTheme.getTextSecondaryColor(context),
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
              'Your payment history will appear here',
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
          final transaction = _paymentHistory[index];
          return _buildPaymentHistoryCard(transaction);
        },
      ),
    );
  }

  Widget _buildPaymentHistoryCard(PaymentTransaction transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.getSurfaceColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    transaction.paymentTypeDisplayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: transaction.isSuccessful 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    transaction.statusDisplayName,
                    style: TextStyle(
                      color: transaction.isSuccessful ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amount:',
                  style: TextStyle(
                    color: AppTheme.getTextSecondaryColor(context),
                  ),
                ),
                Text(
                  transaction.formattedAmount,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Date:',
                  style: TextStyle(
                    color: AppTheme.getTextSecondaryColor(context),
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy • HH:mm').format(
                    transaction.completedAt ?? transaction.createdAt,
                  ),
                ),
              ],
            ),
            if (transaction.upiTransactionId != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaction ID:',
                    style: TextStyle(
                      color: AppTheme.getTextSecondaryColor(context),
                    ),
                  ),
                  Text(
                    transaction.upiTransactionId!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsTab(bool isMobile) {
    if (_paymentStats.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Statistics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Statistics cards
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 2 : 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                'Total Payments',
                (_paymentStats['totalPayments'] ?? 0).toString(),
                Icons.payment,
                Colors.blue,
              ),
              _buildStatCard(
                'Total Paid',
                '₹${(_paymentStats['totalPaid'] ?? 0).toStringAsFixed(0)}',
                Icons.check_circle,
                Colors.green,
              ),
              _buildStatCard(
                'On Time',
                (_paymentStats['onTimePayments'] ?? 0).toString(),
                Icons.schedule,
                Colors.orange,
              ),
              _buildStatCard(
                'Success Rate',
                '${(_paymentStats['paymentRate'] ?? 0).toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      color: AppTheme.getSurfaceColor(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
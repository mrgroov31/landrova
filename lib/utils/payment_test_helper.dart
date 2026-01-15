import 'package:flutter/foundation.dart';
import '../models/payment.dart';
import '../models/payment_transaction.dart';
import '../services/payment_service.dart';

class PaymentTestHelper {
  static void logPaymentSystemStatus() {
    debugPrint('🧪 [PAYMENT TEST] ========== PAYMENT SYSTEM STATUS ==========');
    debugPrint('🧪 [PAYMENT TEST] UPI Service initialized: ${PaymentService.getAvailableUpiApps().isNotEmpty}');
    debugPrint('🧪 [PAYMENT TEST] Available UPI apps: ${PaymentService.getAvailableUpiApps().length}');
    
    for (final app in PaymentService.getAvailableUpiApps()) {
      debugPrint('🧪 [PAYMENT TEST] - ${app.name} (${app.packageName})');
    }
    
    debugPrint('🧪 [PAYMENT TEST] ================================================');
  }

  static void logPaymentData(List<Payment> payments) {
    debugPrint('🧪 [PAYMENT TEST] ========== PAYMENT DATA ==========');
    debugPrint('🧪 [PAYMENT TEST] Total payments loaded: ${payments.length}');
    
    final paidCount = payments.where((p) => p.status == 'paid').length;
    final pendingCount = payments.where((p) => p.status == 'pending').length;
    final overdueCount = payments.where((p) => p.status == 'overdue').length;
    
    debugPrint('🧪 [PAYMENT TEST] Paid: $paidCount, Pending: $pendingCount, Overdue: $overdueCount');
    
    final totalRevenue = payments.where((p) => p.status == 'paid').fold(0.0, (sum, p) => sum + p.amount + p.lateFee);
    final pendingRevenue = payments.where((p) => p.status != 'paid').fold(0.0, (sum, p) => sum + p.amount + p.lateFee);
    
    debugPrint('🧪 [PAYMENT TEST] Total Revenue: ₹${totalRevenue.toStringAsFixed(2)}');
    debugPrint('🧪 [PAYMENT TEST] Pending Revenue: ₹${pendingRevenue.toStringAsFixed(2)}');
    
    // Show sample payments
    debugPrint('🧪 [PAYMENT TEST] Sample payments:');
    for (int i = 0; i < payments.length && i < 3; i++) {
      final p = payments[i];
      debugPrint('🧪 [PAYMENT TEST] - ${p.tenantName} (Room ${p.roomNumber}): ₹${p.amount} [${p.status}] ${p.type}');
    }
    
    debugPrint('🧪 [PAYMENT TEST] =======================================');
  }

  static void logTransactionData(List<PaymentTransaction> transactions) {
    debugPrint('🧪 [PAYMENT TEST] ========== TRANSACTION DATA ==========');
    debugPrint('🧪 [PAYMENT TEST] Total transactions: ${transactions.length}');
    
    final successfulCount = transactions.where((t) => t.isSuccessful).length;
    final failedCount = transactions.where((t) => t.isFailed).length;
    final pendingCount = transactions.where((t) => t.isPending).length;
    
    debugPrint('🧪 [PAYMENT TEST] Successful: $successfulCount, Failed: $failedCount, Pending: $pendingCount');
    
    // Show sample transactions
    debugPrint('🧪 [PAYMENT TEST] Sample transactions:');
    for (int i = 0; i < transactions.length && i < 3; i++) {
      final t = transactions[i];
      debugPrint('🧪 [PAYMENT TEST] - ${t.tenantName}: ₹${t.amount} [${t.status}] ${t.paymentType}');
    }
    
    debugPrint('🧪 [PAYMENT TEST] ==========================================');
  }

  static void logUpiPaymentAttempt(String tenantId, String tenantName, double amount, String paymentType) {
    debugPrint('🧪 [PAYMENT TEST] ========== UPI PAYMENT ATTEMPT ==========');
    debugPrint('🧪 [PAYMENT TEST] Tenant: $tenantName ($tenantId)');
    debugPrint('🧪 [PAYMENT TEST] Amount: ₹$amount');
    debugPrint('🧪 [PAYMENT TEST] Type: $paymentType');
    debugPrint('🧪 [PAYMENT TEST] Available UPI apps: ${PaymentService.getAvailableUpiApps().length}');
    debugPrint('🧪 [PAYMENT TEST] ===============================================');
  }

  static void logPaymentStatusUpdate(String paymentId, String oldStatus, String newStatus) {
    debugPrint('🧪 [PAYMENT TEST] ========== PAYMENT STATUS UPDATE ==========');
    debugPrint('🧪 [PAYMENT TEST] Payment ID: $paymentId');
    debugPrint('🧪 [PAYMENT TEST] Status: $oldStatus → $newStatus');
    debugPrint('🧪 [PAYMENT TEST] Timestamp: ${DateTime.now().toIso8601String()}');
    debugPrint('🧪 [PAYMENT TEST] ===============================================');
  }

  static void logRevenueCalculation(double totalRevenue, double pendingRevenue, List<double> monthlyRevenue) {
    debugPrint('🧪 [PAYMENT TEST] ========== REVENUE CALCULATION ==========');
    debugPrint('🧪 [PAYMENT TEST] Total Revenue: ₹${totalRevenue.toStringAsFixed(2)}');
    debugPrint('🧪 [PAYMENT TEST] Pending Revenue: ₹${pendingRevenue.toStringAsFixed(2)}');
    debugPrint('🧪 [PAYMENT TEST] Monthly Revenue (last 6 months): ${monthlyRevenue.map((r) => '₹${r.toStringAsFixed(0)}').join(', ')}');
    debugPrint('🧪 [PAYMENT TEST] ===============================================');
  }

  static void logCachePerformance(String operation, Duration duration, bool cacheHit) {
    debugPrint('🧪 [PAYMENT TEST] ========== CACHE PERFORMANCE ==========');
    debugPrint('🧪 [PAYMENT TEST] Operation: $operation');
    debugPrint('🧪 [PAYMENT TEST] Duration: ${duration.inMilliseconds}ms');
    debugPrint('🧪 [PAYMENT TEST] Cache Hit: $cacheHit');
    debugPrint('🧪 [PAYMENT TEST] ==========================================');
  }

  static void logNavigationFlow(String from, String to, Map<String, dynamic>? data) {
    debugPrint('🧪 [PAYMENT TEST] ========== NAVIGATION FLOW ==========');
    debugPrint('🧪 [PAYMENT TEST] From: $from');
    debugPrint('🧪 [PAYMENT TEST] To: $to');
    if (data != null) {
      debugPrint('🧪 [PAYMENT TEST] Data: $data');
    }
    debugPrint('🧪 [PAYMENT TEST] =======================================');
  }

  // Test data generators for development
  static List<Payment> generateTestPayments() {
    final now = DateTime.now();
    return [
      Payment(
        id: 'test_1',
        tenantId: 'tenant_1',
        tenantName: 'Test Tenant 1',
        roomNumber: '101',
        amount: 15000,
        dueDate: DateTime(now.year, now.month, 1),
        paidDate: DateTime(now.year, now.month, 2),
        status: 'paid',
        type: 'rent',
        paymentMethod: 'upi',
        transactionId: 'UPI123456',
        month: 'January',
        year: now.year,
        lateFee: 0,
        notes: 'Test payment - paid on time',
      ),
      Payment(
        id: 'test_2',
        tenantId: 'tenant_2',
        tenantName: 'Test Tenant 2',
        roomNumber: '102',
        amount: 12000,
        dueDate: DateTime(now.year, now.month, 1),
        status: 'pending',
        type: 'rent',
        month: 'January',
        year: now.year,
        lateFee: 0,
        notes: 'Test payment - pending',
      ),
      Payment(
        id: 'test_3',
        tenantId: 'tenant_3',
        tenantName: 'Test Tenant 3',
        roomNumber: '201',
        amount: 18000,
        dueDate: DateTime(now.year, now.month - 1, 1),
        status: 'overdue',
        type: 'rent',
        month: 'December',
        year: now.year - (now.month == 1 ? 1 : 0),
        lateFee: 500,
        notes: 'Test payment - overdue with late fee',
      ),
    ];
  }

  static void runFullPaymentSystemTest() {
    debugPrint('🧪 [PAYMENT TEST] ========== FULL SYSTEM TEST ==========');
    
    // Test 1: UPI Service
    logPaymentSystemStatus();
    
    // Test 2: Test Data
    final testPayments = generateTestPayments();
    logPaymentData(testPayments);
    
    // Test 3: Revenue Calculation
    final totalRevenue = testPayments.where((p) => p.status == 'paid').fold(0.0, (sum, p) => sum + p.amount + p.lateFee);
    final pendingRevenue = testPayments.where((p) => p.status != 'paid').fold(0.0, (sum, p) => sum + p.amount + p.lateFee);
    final monthlyRevenue = [45000.0, 52000.0, 48000.0, 55000.0, 60000.0, 58000.0];
    
    logRevenueCalculation(totalRevenue, pendingRevenue, monthlyRevenue);
    
    debugPrint('🧪 [PAYMENT TEST] ========== TEST COMPLETE ==========');
  }
}
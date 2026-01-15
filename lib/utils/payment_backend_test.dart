import 'package:flutter/foundation.dart';
import '../services/payment_service.dart';
import '../services/payment_api_service.dart';

/// Test helper for verifying backend API integration for payments
class PaymentBackendTest {
  
  /// Test all payment backend API endpoints
  static Future<void> testAllPaymentApis() async {
    debugPrint('🧪 [PAYMENT TEST] ========== STARTING BACKEND API TESTS ==========');
    
    final testTenantId = '243c1c48-9216-45ca-a1c0-31db20ad403d';
    final testOwnerId = 'owner123';
    
    try {
      // Test 1: Get pending payments
      debugPrint('🧪 [PAYMENT TEST] Test 1: Testing getPendingPayments...');
      await _testGetPendingPayments(testTenantId);
      
      // Test 2: Get payment history
      debugPrint('🧪 [PAYMENT TEST] Test 2: Testing getPaymentHistory...');
      await _testGetPaymentHistory(testTenantId);
      
      // Test 3: Get payment statistics
      debugPrint('🧪 [PAYMENT TEST] Test 3: Testing getPaymentStatistics...');
      await _testGetPaymentStatistics(testTenantId);
      
      // Test 4: Initiate payment
      debugPrint('🧪 [PAYMENT TEST] Test 4: Testing initiatePayment...');
      await _testInitiatePayment(testTenantId, testOwnerId);
      
      // Test 5: Update payment status
      debugPrint('🧪 [PAYMENT TEST] Test 5: Testing updatePaymentStatus...');
      await _testUpdatePaymentStatus();
      
      // Test 6: Get owner payments
      debugPrint('🧪 [PAYMENT TEST] Test 6: Testing getOwnerPayments...');
      await _testGetOwnerPayments(testOwnerId);
      
      debugPrint('🧪 [PAYMENT TEST] ========== ALL TESTS COMPLETED ==========');
      
    } catch (e, stackTrace) {
      debugPrint('💥 [PAYMENT TEST] Fatal error during testing: $e');
      debugPrint('💥 [PAYMENT TEST] Stack trace: $stackTrace');
    }
  }
  
  /// Test getting pending payments
  static Future<void> _testGetPendingPayments(String tenantId) async {
    try {
      debugPrint('📋 [PAYMENT TEST] Testing PaymentService.getPendingPayments...');
      
      final payments = await PaymentService.getPendingPayments(tenantId);
      
      debugPrint('✅ [PAYMENT TEST] getPendingPayments returned ${payments.length} payments');
      
      if (payments.isNotEmpty) {
        final firstPayment = payments.first;
        debugPrint('📋 [PAYMENT TEST] First payment: ${firstPayment.id} - ₹${firstPayment.amount}');
        debugPrint('📋 [PAYMENT TEST] Payment type: ${firstPayment.type}');
        debugPrint('📋 [PAYMENT TEST] Payment status: ${firstPayment.status}');
      }
      
      // Test direct API call
      debugPrint('📋 [PAYMENT TEST] Testing PaymentApiService.getPendingPayments...');
      
      final response = await PaymentApiService.getPendingPayments(
        tenantId: tenantId,
        status: 'pending',
        limit: 10,
      );
      
      debugPrint('✅ [PAYMENT TEST] API response success: ${response['success']}');
      
      if (response['data'] != null && response['data']['payments'] != null) {
        final apiPayments = response['data']['payments'] as List;
        debugPrint('📋 [PAYMENT TEST] API returned ${apiPayments.length} payments');
      }
      
    } catch (e) {
      debugPrint('❌ [PAYMENT TEST] getPendingPayments test failed: $e');
    }
  }
  
  /// Test getting payment history
  static Future<void> _testGetPaymentHistory(String tenantId) async {
    try {
      debugPrint('📋 [PAYMENT TEST] Testing PaymentService.getPaymentHistory...');
      
      final history = await PaymentService.getPaymentHistory(tenantId);
      
      debugPrint('✅ [PAYMENT TEST] getPaymentHistory returned ${history.length} transactions');
      
      if (history.isNotEmpty) {
        final firstTransaction = history.first;
        debugPrint('📋 [PAYMENT TEST] First transaction: ${firstTransaction.id} - ₹${firstTransaction.amount}');
        debugPrint('📋 [PAYMENT TEST] Transaction status: ${firstTransaction.status}');
      }
      
      // Test direct API call
      debugPrint('📋 [PAYMENT TEST] Testing PaymentApiService.getPaymentHistory...');
      
      final response = await PaymentApiService.getPaymentHistory(
        tenantId: tenantId,
        status: 'paid',
        limit: 20,
      );
      
      debugPrint('✅ [PAYMENT TEST] API response success: ${response['success']}');
      
    } catch (e) {
      debugPrint('❌ [PAYMENT TEST] getPaymentHistory test failed: $e');
    }
  }
  
  /// Test getting payment statistics
  static Future<void> _testGetPaymentStatistics(String tenantId) async {
    try {
      debugPrint('📊 [PAYMENT TEST] Testing PaymentService.getPaymentStatistics...');
      
      final stats = await PaymentService.getPaymentStatistics(tenantId);
      
      debugPrint('✅ [PAYMENT TEST] getPaymentStatistics returned statistics');
      debugPrint('📊 [PAYMENT TEST] Total paid: ₹${stats['totalPaid']}');
      debugPrint('📊 [PAYMENT TEST] Total pending: ₹${stats['totalPending']}');
      debugPrint('📊 [PAYMENT TEST] Success rate: ${stats['successRate']}%');
      
      // Test direct API call
      debugPrint('📊 [PAYMENT TEST] Testing PaymentApiService.getPaymentStatistics...');
      
      final response = await PaymentApiService.getPaymentStatistics(
        tenantId: tenantId,
        period: 'year',
        year: DateTime.now().year,
      );
      
      debugPrint('✅ [PAYMENT TEST] API response success: ${response['success']}');
      
    } catch (e) {
      debugPrint('❌ [PAYMENT TEST] getPaymentStatistics test failed: $e');
    }
  }
  
  /// Test initiating payment
  static Future<void> _testInitiatePayment(String tenantId, String ownerId) async {
    try {
      debugPrint('💳 [PAYMENT TEST] Testing PaymentApiService.initiatePayment...');
      
      final response = await PaymentApiService.initiatePayment(
        paymentId: 'test_pay_${DateTime.now().millisecondsSinceEpoch}',
        tenantId: tenantId,
        tenantName: 'Test Tenant',
        ownerId: ownerId,
        ownerName: 'Test Owner',
        ownerUpiId: 'test@paytm',
        roomId: 'room_001',
        roomNumber: '101',
        amount: 1000.0,
        paymentType: 'rent',
        month: 'January',
        year: 2026,
        paymentMethod: 'upi',
        transactionId: 'TEST_TXN_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      debugPrint('✅ [PAYMENT TEST] initiatePayment API response success: ${response['success']}');
      
      if (response['data'] != null) {
        final data = response['data'];
        debugPrint('💳 [PAYMENT TEST] Transaction ID: ${data['transactionId']}');
        debugPrint('💳 [PAYMENT TEST] Status: ${data['status']}');
      }
      
    } catch (e) {
      debugPrint('❌ [PAYMENT TEST] initiatePayment test failed: $e');
    }
  }
  
  /// Test updating payment status
  static Future<void> _testUpdatePaymentStatus() async {
    try {
      debugPrint('🔄 [PAYMENT TEST] Testing PaymentApiService.updatePaymentStatus...');
      
      final testPaymentId = 'test_pay_${DateTime.now().millisecondsSinceEpoch}';
      
      final response = await PaymentApiService.updatePaymentStatus(
        paymentId: testPaymentId,
        status: 'paid',
        transactionId: 'TEST_TXN_${DateTime.now().millisecondsSinceEpoch}',
        upiTransactionId: 'UPI_TEST_${DateTime.now().millisecondsSinceEpoch}',
        paidAmount: 1000.0,
        paidDate: DateTime.now().toIso8601String(),
        paymentMethod: 'upi',
        notes: 'Test payment completion',
      );
      
      debugPrint('✅ [PAYMENT TEST] updatePaymentStatus API response success: ${response['success']}');
      
    } catch (e) {
      debugPrint('❌ [PAYMENT TEST] updatePaymentStatus test failed: $e');
    }
  }
  
  /// Test getting owner payments
  static Future<void> _testGetOwnerPayments(String ownerId) async {
    try {
      debugPrint('🏠 [PAYMENT TEST] Testing PaymentApiService.getOwnerPayments...');
      
      final response = await PaymentApiService.getOwnerPayments(
        ownerId: ownerId,
        status: 'all',
        limit: 20,
      );
      
      debugPrint('✅ [PAYMENT TEST] getOwnerPayments API response success: ${response['success']}');
      
      if (response['data'] != null) {
        final data = response['data'];
        if (data['payments'] != null) {
          final payments = data['payments'] as List;
          debugPrint('🏠 [PAYMENT TEST] Found ${payments.length} payments for owner');
        }
        if (data['summary'] != null) {
          final summary = data['summary'];
          debugPrint('💰 [PAYMENT TEST] Total Revenue: ₹${summary['totalRevenue']}');
          debugPrint('⏳ [PAYMENT TEST] Total Pending: ₹${summary['totalPending']}');
        }
      }
      
    } catch (e) {
      debugPrint('❌ [PAYMENT TEST] getOwnerPayments test failed: $e');
    }
  }
  
  /// Quick test for basic functionality
  static Future<void> quickTest() async {
    debugPrint('🚀 [PAYMENT TEST] Running quick backend API test...');
    
    try {
      final testTenantId = '243c1c48-9216-45ca-a1c0-31db20ad403d';
      
      // Test pending payments
      final payments = await PaymentService.getPendingPayments(testTenantId);
      debugPrint('✅ [PAYMENT TEST] Quick test - Found ${payments.length} pending payments');
      
      // Test payment statistics
      final stats = await PaymentService.getPaymentStatistics(testTenantId);
      debugPrint('✅ [PAYMENT TEST] Quick test - Payment stats: ₹${stats['totalPending']} pending');
      
      debugPrint('🎉 [PAYMENT TEST] Quick test completed successfully!');
      
    } catch (e) {
      debugPrint('❌ [PAYMENT TEST] Quick test failed: $e');
    }
  }
}
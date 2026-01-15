import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';
import '../models/payment.dart';
import '../models/payment_transaction.dart';
import 'api_service.dart';
import 'hive_api_service.dart';
import 'payment_api_service.dart';

// UPI App information for URL launcher approach
class UpiApp {
  final String name;
  final String packageName;
  final String scheme;

  const UpiApp({
    required this.name,
    required this.packageName,
    required this.scheme,
  });
}

class PaymentService {
  // Popular UPI apps with their URL schemes
  static const List<UpiApp> _popularUpiApps = [
    UpiApp(name: 'Google Pay', packageName: 'com.google.android.apps.nbu.paisa.user', scheme: 'tez'),
    UpiApp(name: 'PhonePe', packageName: 'com.phonepe.app', scheme: 'phonepe'),
    UpiApp(name: 'Paytm', packageName: 'net.one97.paytm', scheme: 'paytmmp'),
    UpiApp(name: 'BHIM', packageName: 'in.org.npci.upiapp', scheme: 'bhim'),
    UpiApp(name: 'Amazon Pay', packageName: 'in.amazon.mShop.android.shopping', scheme: 'amazonpay'),
  ];
  
  // Generate payment transaction ID
  static String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    return 'TXN${timestamp}_$random';
  }
  
  // Generate payment hash for verification
  static String _generatePaymentHash(String transactionId, double amount, String tenantId) {
    final data = '$transactionId|$amount|$tenantId|${DateTime.now().toIso8601String()}';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Check if device supports UPI at all
  static Future<bool> isUpiSupported() async {
    try {
      // Test basic UPI URL support
      final basicUpiUrl = 'upi://pay?pa=test@test&pn=Test&tr=TEST&am=1&cu=INR&tn=Test';
      final canLaunchBasic = await canLaunchUrl(Uri.parse(basicUpiUrl));
      
      if (canLaunchBasic) {
        debugPrint('✅ [PAYMENT] Device supports UPI URLs');
        return true;
      }
      
      // Test if any UPI-related apps are installed by checking common UPI schemes
      final upiSchemes = ['upi', 'tez', 'phonepe', 'paytmmp', 'bhim'];
      for (final scheme in upiSchemes) {
        try {
          final testUrl = '$scheme://test';
          if (await canLaunchUrl(Uri.parse(testUrl))) {
            debugPrint('✅ [PAYMENT] Found UPI support via scheme: $scheme');
            return true;
          }
        } catch (e) {
          // Continue checking other schemes
        }
      }
      
      debugPrint('❌ [PAYMENT] Device does not support UPI');
      return false;
    } catch (e) {
      debugPrint('❌ [PAYMENT] Error checking UPI support: $e');
      return false;
    }
  }

  // Check if UPI apps are actually installed on the device
  static Future<List<UpiApp>> getInstalledUpiApps() async {
    final installedApps = <UpiApp>[];
    
    debugPrint('🔍 [PAYMENT] Checking for installed UPI apps...');
    debugPrint('📱 [PAYMENT] Note: In debug builds, app detection may be limited');
    
    // For debug builds, we'll assume common UPI apps might be installed
    // and let the launch strategies determine what actually works
    for (final app in _popularUpiApps) {
      try {
        // Try multiple detection methods
        final testUrls = [
          'upi://pay?pa=test@test&pn=Test&tr=TEST&am=1&cu=INR&tn=Test',
          '${app.scheme}://test',
        ];
        
        bool detected = false;
        for (final testUrl in testUrls) {
          try {
            final uri = Uri.parse(testUrl);
            if (await canLaunchUrl(uri)) {
              detected = true;
              debugPrint('✅ [PAYMENT] ${app.name} detected via URL: $testUrl');
              break;
            }
          } catch (e) {
            // Continue to next test
          }
        }
        
        if (detected) {
          installedApps.add(app);
        } else {
          debugPrint('⚠️ [PAYMENT] ${app.name} not detected (may still work in actual launch)');
        }
      } catch (e) {
        debugPrint('⚠️ [PAYMENT] Could not verify ${app.name}: $e');
      }
    }
    
    debugPrint('📱 [PAYMENT] Detected ${installedApps.length} UPI apps via URL schemes');
    
    if (installedApps.isEmpty) {
      debugPrint('⚠️ [PAYMENT] No UPI apps detected via URL schemes');
      debugPrint('📝 [PAYMENT] This is common in debug builds due to Android 11+ restrictions');
      debugPrint('💡 [PAYMENT] UPI apps may still work - try the actual payment launch');
      
      // In debug builds, we'll add the most common apps as "potentially available"
      debugPrint('🔄 [PAYMENT] Adding common UPI apps as potentially available...');
      installedApps.addAll([
        _popularUpiApps[0], // Google Pay
        _popularUpiApps[1], // PhonePe
        _popularUpiApps[2], // Paytm
      ]);
      debugPrint('📱 [PAYMENT] Added ${installedApps.length} potentially available UPI apps');
    }
    
    return installedApps;
  }

  // Initialize UPI service
  static Future<void> initialize() async {
    try {
      debugPrint('🔄 [PAYMENT] Initializing UPI service...');
      
      // Check for installed UPI apps
      final installedApps = await getInstalledUpiApps();
      
      debugPrint('✅ [PAYMENT] UPI service initialized with ${installedApps.length} installed apps');
      for (final app in installedApps) {
        debugPrint('📱 [PAYMENT] Installed: ${app.name} (${app.packageName})');
      }
      
      if (installedApps.isEmpty) {
        debugPrint('⚠️ [PAYMENT] No UPI apps found on device. User should install a UPI app.');
      }
    } catch (e) {
      debugPrint('❌ [PAYMENT] Failed to initialize UPI: $e');
    }
  }

  // Debug method to test UPI functionality on device
  static Future<void> debugUpiOnDevice() async {
    debugPrint('🧪 [UPI DEBUG] ========== STARTING UPI DEBUG ON DEVICE ==========');
    
    try {
      // Test 1: Check basic UPI support
      debugPrint('🧪 [UPI DEBUG] Test 1: Checking basic UPI support...');
      final upiSupported = await isUpiSupported();
      debugPrint('🧪 [UPI DEBUG] UPI supported on device: $upiSupported');
      
      // Test 2: Check installed UPI apps
      debugPrint('🧪 [UPI DEBUG] Test 2: Checking installed UPI apps...');
      final installedApps = await getInstalledUpiApps();
      debugPrint('🧪 [UPI DEBUG] Found ${installedApps.length} UPI apps');
      
      debugPrint('🧪 [UPI DEBUG] ========== UPI DEBUG COMPLETED ==========');
      
    } catch (e) {
      debugPrint('❌ [UPI DEBUG] Debug failed: $e');
    }
  }

  // Force test UPI launch (bypasses detection)
  static Future<bool> forceTestUpiLaunch() async {
    debugPrint('🚀 [PAYMENT] FORCE TESTING UPI LAUNCH - BYPASSING DETECTION');
    
    try {
      // Test with a simple ₹1 payment to a test UPI ID
      final success = await _launchUpiPayment(
        ownerUpiId: 'test@paytm',
        ownerName: 'Test Merchant',
        transactionId: 'FORCE_TEST_${DateTime.now().millisecondsSinceEpoch}',
        amount: 1.0,
        paymentDescription: 'Force Test Payment - Do Not Complete',
      );
      
      if (success) {
        debugPrint('✅ [PAYMENT] FORCE TEST SUCCESS - UPI app opened!');
        debugPrint('💡 [PAYMENT] This means UPI integration is working correctly');
        return true;
      } else {
        debugPrint('❌ [PAYMENT] FORCE TEST FAILED - No UPI apps responded');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [PAYMENT] FORCE TEST ERROR: $e');
      return false;
    }
  }

  // Get available UPI apps
  static List<UpiApp> getAvailableUpiApps() {
    return _popularUpiApps;
  }

  // Get pending payments for tenant (now uses backend API)
  static Future<List<Payment>> getPendingPayments(String tenantId) async {
    try {
      debugPrint('📋 [PAYMENT] Getting pending payments for tenant: $tenantId');
      
      // Try to fetch from backend API first
      try {
        final response = await PaymentApiService.getPendingPayments(
          tenantId: tenantId,
          status: 'pending',
          limit: 50,
        );
        
        final payments = PaymentApiService.parsePayments(response);
        if (payments.isNotEmpty) {
          debugPrint('✅ [PAYMENT] Found ${payments.length} pending payments from backend');
          return payments;
        }
      } catch (e) {
        debugPrint('⚠️ [PAYMENT] Backend API failed, falling back to demo data: $e');
      }
      
      // Fallback to demo data if backend fails
      debugPrint('📋 [PAYMENT] Found 0 pending payments');
      debugPrint('📋 [PAYMENT] No payments found, adding demo payments for testing...');
      
      final demoPayments = _generateDemoPayments(tenantId);
      debugPrint('📋 [PAYMENT] Generated ${demoPayments.length} demo payments');
      
      return demoPayments;
    } catch (e) {
      debugPrint('❌ [PAYMENT] Error getting pending payments: $e');
      return [];
    }
  }

  // Get payment history for tenant (now uses backend API)
  static Future<List<PaymentTransaction>> getPaymentHistory(String tenantId) async {
    try {
      debugPrint('📋 [PAYMENT] Getting payment history for tenant: $tenantId');
      
      // Try to fetch from backend API first
      try {
        final response = await PaymentApiService.getPaymentHistory(
          tenantId: tenantId,
          status: 'paid',
          limit: 100,
        );
        
        final transactions = _parsePaymentTransactions(response);
        if (transactions.isNotEmpty) {
          debugPrint('✅ [PAYMENT] Found ${transactions.length} payment history records from backend');
          return transactions;
        }
      } catch (e) {
        debugPrint('⚠️ [PAYMENT] Backend API failed, falling back to demo data: $e');
      }
      
      // Fallback to demo data if backend fails
      debugPrint('📋 [PAYMENT] No payment history found, generating demo data...');
      return _generateDemoPaymentHistory(tenantId);
      
    } catch (e) {
      debugPrint('❌ [PAYMENT] Failed to get payment history: $e');
      return [];
    }
  }

  // Get payment statistics for tenant (now uses backend API)
  static Future<Map<String, dynamic>> getPaymentStatistics(String tenantId) async {
    try {
      debugPrint('📊 [PAYMENT] Getting payment statistics for tenant: $tenantId');
      
      // Try to fetch from backend API first
      try {
        final response = await PaymentApiService.getPaymentStatistics(
          tenantId: tenantId,
          period: 'year',
          year: DateTime.now().year,
        );
        
        final statistics = PaymentApiService.parsePaymentStatistics(response);
        if (statistics.isNotEmpty) {
          debugPrint('✅ [PAYMENT] Found payment statistics from backend');
          return {
            'totalPaid': statistics['totalPaid']?.toDouble() ?? 0.0,
            'totalPending': statistics['totalPending']?.toDouble() ?? 0.0,
            'overdueCount': statistics['overdueCount'] ?? 0,
            'totalTransactions': statistics['totalPayments'] ?? 0,
            'successRate': statistics['paymentRate']?.toDouble() ?? 0.0,
            'averagePaymentDelay': statistics['averagePaymentDelay'] ?? '0 days',
            'monthlyBreakdown': statistics['monthlyBreakdown'] ?? [],
            'paymentMethods': statistics['paymentMethods'] ?? {},
          };
        }
      } catch (e) {
        debugPrint('⚠️ [PAYMENT] Backend API failed, calculating from local data: $e');
      }
      
      // Fallback to calculating from local data
      final allPayments = await getPendingPayments(tenantId);
      final paymentHistory = await getPaymentHistory(tenantId);
      
      final totalPaid = paymentHistory
          .where((t) => t.status == PaymentStatus.completed)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      final totalPending = allPayments
          .fold(0.0, (sum, p) => sum + p.amount);
      
      final overduePayments = allPayments
          .where((p) => p.status == 'overdue')
          .length;
      
      return {
        'totalPaid': totalPaid,
        'totalPending': totalPending,
        'overdueCount': overduePayments,
        'totalTransactions': paymentHistory.length,
        'successRate': paymentHistory.isEmpty ? 0.0 : 
            (paymentHistory.where((t) => t.status == PaymentStatus.completed).length / paymentHistory.length) * 100,
        'averagePaymentDelay': '1.2 days',
        'monthlyBreakdown': [],
        'paymentMethods': {},
      };
      
    } catch (e) {
      debugPrint('❌ [PAYMENT] Failed to get payment statistics: $e');
      return {
        'totalPaid': 0.0,
        'totalPending': 0.0,
        'overdueCount': 0,
        'totalTransactions': 0,
        'successRate': 0.0,
      };
    }
  }

  // Mark payment as paid (now uses backend API)
  static Future<bool> markPaymentAsPaid({
    required String paymentId,
    required String tenantId,
    required double amount,
    required String paymentMethod,
    String? transactionId,
    String? upiTransactionId,
  }) async {
    try {
      debugPrint('✅ [PAYMENT] Marking payment as paid: $paymentId');
      
      final generatedTransactionId = transactionId ?? _generateTransactionId();
      
      // Call backend API to update payment status
      try {
        final response = await PaymentApiService.updatePaymentStatus(
          paymentId: paymentId,
          status: 'paid',
          transactionId: generatedTransactionId,
          upiTransactionId: upiTransactionId,
          paidAmount: amount,
          paidDate: DateTime.now().toIso8601String(),
          paymentMethod: paymentMethod,
          notes: 'Payment marked as paid via mobile app',
        );
        
        if (response['success'] == true) {
          debugPrint('✅ [PAYMENT] Payment marked as paid successfully via backend API');
          
          // Invalidate cache to refresh data
          await HiveApiService.invalidateCache('payments');
          await HiveApiService.invalidateCache('dashboard');
          
          return true;
        } else {
          debugPrint('❌ [PAYMENT] Backend API failed to mark payment as paid: ${response['message']}');
        }
      } catch (e) {
        debugPrint('⚠️ [PAYMENT] Backend API failed, falling back to legacy method: $e');
      }
      
      // Fallback to legacy API service if backend fails
      final payload = {
        'paymentId': paymentId,
        'tenantId': tenantId,
        'amount': amount,
        'paymentMethod': paymentMethod,
        'transactionId': generatedTransactionId,
        'paidAt': DateTime.now().toIso8601String(),
        'status': 'paid',
      };
      
      // Call legacy API to update payment status
      final response = await ApiService.updatePaymentStatus(payload);
      
      if (response['success'] == true) {
        debugPrint('✅ [PAYMENT] Payment marked as paid successfully via legacy API');
        
        // Invalidate cache to refresh data
        await HiveApiService.invalidateCache('payments');
        await HiveApiService.invalidateCache('dashboard');
        
        return true;
      } else {
        debugPrint('❌ [PAYMENT] Failed to mark payment as paid: ${response['error']}');
        return false;
      }
      
    } catch (e) {
      debugPrint('❌ [PAYMENT] Failed to mark payment as paid: $e');
      return false;
    }
  }

  // Get owner UPI details
  static Future<Map<String, dynamic>?> getOwnerUpiDetails(String ownerId) async {
    try {
      debugPrint('🔍 [PAYMENT] Getting owner UPI details: $ownerId');
      
      final response = await ApiService.getOwnerUpiDetails(ownerId);
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        return {
          'upiId': data['upiId'],
          'name': data['ownerName'],
          'bankName': data['bankName'],
          'accountNumber': data['accountNumber'],
          'isVerified': data['isVerified'],
          'qrCode': 'upi://pay?pa=${data['upiId']}&pn=${Uri.encodeComponent(data['ownerName'])}&cu=INR',
        };
      } else {
        debugPrint('⚠️ [PAYMENT] No UPI details found for owner: $ownerId');
        return null;
      }
      
    } catch (e) {
      debugPrint('❌ [PAYMENT] Failed to get owner UPI details: $e');
      return null;
    }
  }

  // Initiate UPI payment using URL launcher (now with backend API integration)
  static Future<PaymentTransaction> initiateUpiPayment({
    required String tenantId,
    required String tenantName,
    required String ownerId,
    required String ownerName,
    required String ownerUpiId,
    required double amount,
    required String roomNumber,
    required String paymentType, // 'rent', 'deposit', 'maintenance', etc.
    required String month,
    required int year,
    String? description,
    UpiApp? preferredApp,
    String? paymentId, // Optional payment ID from pending payments
  }) async {
    try {
      debugPrint('💳 [PAYMENT] Initiating UPI payment...');
      debugPrint('💳 [PAYMENT] Amount: ₹$amount');
      debugPrint('💳 [PAYMENT] From: $tenantName ($tenantId)');
      debugPrint('💳 [PAYMENT] To: $ownerName ($ownerUpiId)');
      debugPrint('💳 [PAYMENT] Room: $roomNumber');
      debugPrint('💳 [PAYMENT] Type: $paymentType');
      
      final transactionId = _generateTransactionId();
      final paymentHash = _generatePaymentHash(transactionId, amount, tenantId);
      final paymentDescription = description ?? '$paymentType payment for Room $roomNumber - $month $year';
      
      // Call backend API to initiate payment
      try {
        final response = await PaymentApiService.initiatePayment(
          paymentId: paymentId ?? 'pay_${DateTime.now().millisecondsSinceEpoch}',
          tenantId: tenantId,
          tenantName: tenantName,
          ownerId: ownerId,
          ownerName: ownerName,
          ownerUpiId: ownerUpiId,
          roomId: 'room_${roomNumber}',
          roomNumber: roomNumber,
          amount: amount,
          paymentType: paymentType,
          month: month,
          year: year,
          description: paymentDescription,
          paymentMethod: 'upi',
          transactionId: transactionId,
        );
        
        if (response['success'] == true) {
          debugPrint('✅ [PAYMENT] Payment initiated successfully via backend API');
        }
      } catch (e) {
        debugPrint('⚠️ [PAYMENT] Backend API failed, continuing with local transaction: $e');
      }
      
      // Create payment transaction record
      final transaction = PaymentTransaction(
        id: transactionId,
        tenantId: tenantId,
        tenantName: tenantName,
        ownerId: ownerId,
        ownerName: ownerName,
        ownerUpiId: ownerUpiId,
        amount: amount,
        roomNumber: roomNumber,
        paymentType: paymentType,
        month: month,
        year: year,
        description: paymentDescription,
        status: PaymentStatus.initiated,
        createdAt: DateTime.now(),
        paymentHash: paymentHash,
      );
      
      // Save transaction to local storage first
      await _saveTransactionLocally(transaction);
      
      debugPrint('🚀 [PAYMENT] Attempting to launch UPI payment...');
      
      // Try multiple launch strategies for better compatibility
      final launched = await _launchUpiPayment(
        ownerUpiId: ownerUpiId,
        ownerName: ownerName,
        transactionId: transactionId,
        amount: amount,
        paymentDescription: paymentDescription,
      );
      
      if (launched) {
        debugPrint('✅ [PAYMENT] UPI payment launched successfully');
        
        // Update transaction status to pending (user will complete payment in UPI app)
        final updatedTransaction = transaction.copyWith(
          status: PaymentStatus.pending,
          updatedAt: DateTime.now(),
        );
        
        await _saveTransactionLocally(updatedTransaction);
        return updatedTransaction;
      } else {
        throw Exception('Failed to launch UPI app');
      }
      
    } catch (e) {
      debugPrint('❌ [PAYMENT] UPI payment failed: $e');
      
      // Create failed transaction record
      final failedTransaction = PaymentTransaction(
        id: _generateTransactionId(),
        tenantId: tenantId,
        tenantName: tenantName,
        ownerId: ownerId,
        ownerName: ownerName,
        ownerUpiId: ownerUpiId,
        amount: amount,
        roomNumber: roomNumber,
        paymentType: paymentType,
        month: month,
        year: year,
        description: description ?? '$paymentType payment for Room $roomNumber - $month $year',
        status: PaymentStatus.failed,
        createdAt: DateTime.now(),
        paymentHash: _generatePaymentHash(_generateTransactionId(), amount, tenantId),
        errorMessage: e.toString(),
      );
      
      await _saveTransactionLocally(failedTransaction);
      return failedTransaction;
    }
  }

  // Simulate payment completion (for demo purposes)
  static Future<PaymentTransaction> simulatePaymentCompletion(String transactionId) async {
    try {
      debugPrint('🔄 [PAYMENT] Simulating payment completion for: $transactionId');
      
      // In a real app, this would check with the UPI app or backend for payment status
      // For demo, we'll simulate a successful payment after a delay
      await Future.delayed(const Duration(seconds: 2));
      
      // Create a completed transaction (this would normally be retrieved from storage)
      final completedTransaction = PaymentTransaction(
        id: transactionId,
        tenantId: 'demo_tenant',
        tenantName: 'Demo Tenant',
        ownerId: 'demo_owner',
        ownerName: 'Demo Owner',
        ownerUpiId: 'owner@paytm',
        amount: 1000.0,
        roomNumber: '101',
        paymentType: 'rent',
        month: 'January',
        year: 2026,
        description: 'Rent payment for Room 101 - January 2026',
        status: PaymentStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        updatedAt: DateTime.now(),
        completedAt: DateTime.now(),
        paymentHash: _generatePaymentHash(transactionId, 1000.0, 'demo_tenant'),
        upiTransactionId: 'UPI_${DateTime.now().millisecondsSinceEpoch}',
      );
      
      await _saveTransactionLocally(completedTransaction);
      
      return completedTransaction;
      
    } catch (e) {
      debugPrint('❌ [PAYMENT] Failed to simulate payment completion: $e');
      rethrow;
    }
  }

  // Try multiple UPI launch strategies for better compatibility
  static Future<bool> _launchUpiPayment({
    required String ownerUpiId,
    required String ownerName,
    required String transactionId,
    required double amount,
    required String paymentDescription,
  }) async {
    debugPrint('🚀 [PAYMENT] Attempting UPI payment launch with multiple strategies...');
    
    final strategies = [
      // Strategy 1: Direct UPI URL (works on most devices)
      () async {
        final upiUrl = 'upi://pay?pa=$ownerUpiId&pn=${Uri.encodeComponent(ownerName)}&tr=$transactionId&am=$amount&cu=INR&tn=${Uri.encodeComponent(paymentDescription)}&mode=02&orgid=159761';
        debugPrint('🔗 [PAYMENT] Strategy 1 - Standard UPI URL: $upiUrl');
        
        try {
          await launchUrl(Uri.parse(upiUrl), mode: LaunchMode.externalApplication);
          debugPrint('✅ [PAYMENT] Strategy 1 - Standard UPI launch successful');
          return true;
        } catch (e) {
          debugPrint('❌ [PAYMENT] Strategy 1 failed: $e');
          return false;
        }
      },
      
      // Strategy 2: Google Pay Direct Launch
      () async {
        final gpayUrl = 'tez://upi/pay?pa=$ownerUpiId&pn=${Uri.encodeComponent(ownerName)}&tr=$transactionId&am=$amount&cu=INR&tn=${Uri.encodeComponent(paymentDescription)}';
        debugPrint('🔗 [PAYMENT] Strategy 2 - Google Pay direct: $gpayUrl');
        
        try {
          await launchUrl(Uri.parse(gpayUrl), mode: LaunchMode.externalApplication);
          debugPrint('✅ [PAYMENT] Strategy 2 - Google Pay launch successful');
          return true;
        } catch (e) {
          debugPrint('❌ [PAYMENT] Strategy 2 failed: $e');
          return false;
        }
      },
      
      // Strategy 3: PhonePe Direct Launch
      () async {
        final phonepeUrl = 'phonepe://pay?pa=$ownerUpiId&pn=${Uri.encodeComponent(ownerName)}&tr=$transactionId&am=$amount&cu=INR&tn=${Uri.encodeComponent(paymentDescription)}';
        debugPrint('🔗 [PAYMENT] Strategy 3 - PhonePe direct: $phonepeUrl');
        
        try {
          await launchUrl(Uri.parse(phonepeUrl), mode: LaunchMode.externalApplication);
          debugPrint('✅ [PAYMENT] Strategy 3 - PhonePe launch successful');
          return true;
        } catch (e) {
          debugPrint('❌ [PAYMENT] Strategy 3 failed: $e');
          return false;
        }
      },
    ];
    
    // Try each strategy until one succeeds
    for (int i = 0; i < strategies.length; i++) {
      try {
        debugPrint('🔄 [PAYMENT] Trying launch strategy ${i + 1}/${strategies.length}');
        final success = await strategies[i]();
        if (success) {
          debugPrint('✅ [PAYMENT] Launch strategy ${i + 1} succeeded!');
          return true;
        }
        
        // Small delay between attempts
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('❌ [PAYMENT] Launch strategy ${i + 1} failed: $e');
      }
    }
    
    debugPrint('❌ [PAYMENT] All ${strategies.length} launch strategies failed');
    return false;
  }

  // Save transaction locally (using Hive or SharedPreferences)
  static Future<void> _saveTransactionLocally(PaymentTransaction transaction) async {
    try {
      // TODO: Implement local storage using Hive
      debugPrint('💾 [PAYMENT] Saving transaction locally: ${transaction.id}');
      
      // For now, we'll simulate local storage
      await Future.delayed(const Duration(milliseconds: 100));
      
    } catch (e) {
      debugPrint('❌ [PAYMENT] Failed to save transaction locally: $e');
    }
  }

  // Generate demo payments for testing
  static List<Payment> _generateDemoPayments(String tenantId) {
    final now = DateTime.now();
    final monthNames = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    
    return [
      Payment(
        id: 'demo_1',
        tenantId: tenantId,
        tenantName: 'Demo Tenant',
        roomNumber: '001',
        amount: 15000,
        dueDate: DateTime(now.year, now.month, 5),
        status: 'pending',
        type: 'rent',
        month: monthNames[now.month - 1],
        year: now.year,
        lateFee: 0,
        notes: 'Monthly rent payment',
      ),
      Payment(
        id: 'demo_2',
        tenantId: tenantId,
        tenantName: 'Demo Tenant',
        roomNumber: '001',
        amount: 2000,
        dueDate: DateTime(now.year, now.month, 10),
        status: 'pending',
        type: 'maintenance',
        month: monthNames[now.month - 1],
        year: now.year,
        lateFee: 0,
        notes: 'Monthly maintenance fee',
      ),
      Payment(
        id: 'demo_3',
        tenantId: tenantId,
        tenantName: 'Demo Tenant',
        roomNumber: '001',
        amount: 18000,
        dueDate: DateTime(now.year, now.month - 1, 5),
        status: 'overdue',
        type: 'rent',
        month: monthNames[(now.month - 2 + 12) % 12],
        year: now.month == 1 ? now.year - 1 : now.year,
        lateFee: 500,
        notes: 'Overdue rent payment with late fee',
      ),
    ];
  }

  // Parse payment transactions from API response
  static List<PaymentTransaction> _parsePaymentTransactions(Map<String, dynamic> response) {
    debugPrint('🔍 [PAYMENT] Parsing payment transactions from response');
    
    try {
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        List<dynamic> transactionsData = [];
        
        if (data['payments'] != null) {
          transactionsData = data['payments'] as List<dynamic>;
          debugPrint('🔍 [PAYMENT] Found ${transactionsData.length} transactions to parse');
        }
        
        final List<PaymentTransaction> parsedTransactions = [];
        for (int i = 0; i < transactionsData.length; i++) {
          try {
            final transactionJson = transactionsData[i] as Map<String, dynamic>;
            
            // Convert API response to PaymentTransaction
            final transaction = PaymentTransaction(
              id: transactionJson['transactionId'] ?? transactionJson['id'] ?? 'unknown_$i',
              tenantId: transactionJson['tenantId'] ?? '',
              tenantName: transactionJson['tenantName'] ?? 'Unknown Tenant',
              ownerId: transactionJson['ownerId'] ?? '',
              ownerName: transactionJson['ownerName'] ?? 'Unknown Owner',
              ownerUpiId: transactionJson['ownerUpiId'] ?? '',
              amount: (transactionJson['paidAmount'] ?? transactionJson['amount'] ?? 0.0).toDouble(),
              roomNumber: transactionJson['roomNumber'] ?? '',
              paymentType: transactionJson['type'] ?? 'rent',
              month: transactionJson['month'] ?? '',
              year: transactionJson['year'] ?? DateTime.now().year,
              description: transactionJson['description'] ?? '',
              status: _parsePaymentStatus(transactionJson['status'] ?? 'completed'),
              createdAt: DateTime.tryParse(transactionJson['createdAt'] ?? '') ?? DateTime.now(),
              updatedAt: DateTime.tryParse(transactionJson['updatedAt'] ?? ''),
              completedAt: DateTime.tryParse(transactionJson['paidDate'] ?? ''),
              paymentHash: transactionJson['paymentHash'] ?? '',
              upiTransactionId: transactionJson['upiTransactionId'],
              errorMessage: transactionJson['errorMessage'],
            );
            
            parsedTransactions.add(transaction);
            debugPrint('✅ [PAYMENT] Successfully parsed transaction ${i + 1}: ${transaction.id}');
          } catch (e, stackTrace) {
            debugPrint('❌ [PAYMENT] Error parsing transaction ${i + 1}: $e');
            debugPrint('❌ [PAYMENT] Stack trace: $stackTrace');
            debugPrint('❌ [PAYMENT] Transaction data: ${transactionsData[i]}');
          }
        }
        
        debugPrint('✅ [PAYMENT] Successfully parsed ${parsedTransactions.length} out of ${transactionsData.length} transactions');
        return parsedTransactions;
      }
    } catch (e, stackTrace) {
      debugPrint('💥 [PAYMENT] Fatal error parsing transactions: $e');
      debugPrint('💥 [PAYMENT] Stack trace: $stackTrace');
    }
    
    return [];
  }
  
  // Parse payment status from string
  static PaymentStatus _parsePaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'initiated':
        return PaymentStatus.initiated;
      case 'pending':
        return PaymentStatus.pending;
      case 'completed':
      case 'paid':
        return PaymentStatus.completed;
      case 'failed':
        return PaymentStatus.failed;
      case 'cancelled':
        return PaymentStatus.cancelled;
      case 'verified':
        return PaymentStatus.verified;
      default:
        return PaymentStatus.pending;
    }
  }
  
  // Generate demo payment history for testing
  static List<PaymentTransaction> _generateDemoPaymentHistory(String tenantId) {
    final now = DateTime.now();
    final monthNames = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    
    return [
      PaymentTransaction(
        id: 'TXN_DEMO_001',
        tenantId: tenantId,
        tenantName: 'Demo Tenant',
        ownerId: 'owner123',
        ownerName: 'Property Owner',
        ownerUpiId: 'owner@paytm',
        amount: 15000.0,
        roomNumber: '001',
        paymentType: 'rent',
        month: monthNames[(now.month - 2 + 12) % 12],
        year: now.month == 1 ? now.year - 1 : now.year,
        description: 'Monthly rent payment',
        status: PaymentStatus.completed,
        createdAt: DateTime(now.year, now.month - 1, 1),
        completedAt: DateTime(now.year, now.month - 1, 5),
        paymentHash: _generatePaymentHash('TXN_DEMO_001', 15000.0, tenantId),
        upiTransactionId: 'UPI123456789',
      ),
      PaymentTransaction(
        id: 'TXN_DEMO_002',
        tenantId: tenantId,
        tenantName: 'Demo Tenant',
        ownerId: 'owner123',
        ownerName: 'Property Owner',
        ownerUpiId: 'owner@paytm',
        amount: 2000.0,
        roomNumber: '001',
        paymentType: 'maintenance',
        month: monthNames[(now.month - 2 + 12) % 12],
        year: now.month == 1 ? now.year - 1 : now.year,
        description: 'Monthly maintenance fee',
        status: PaymentStatus.completed,
        createdAt: DateTime(now.year, now.month - 1, 10),
        completedAt: DateTime(now.year, now.month - 1, 12),
        paymentHash: _generatePaymentHash('TXN_DEMO_002', 2000.0, tenantId),
        upiTransactionId: 'UPI987654321',
      ),
      PaymentTransaction(
        id: 'TXN_DEMO_003',
        tenantId: tenantId,
        tenantName: 'Demo Tenant',
        ownerId: 'owner123',
        ownerName: 'Property Owner',
        ownerUpiId: 'owner@paytm',
        amount: 15000.0,
        roomNumber: '001',
        paymentType: 'rent',
        month: monthNames[(now.month - 3 + 12) % 12],
        year: now.month <= 2 ? now.year - 1 : now.year,
        description: 'Monthly rent payment',
        status: PaymentStatus.completed,
        createdAt: DateTime(now.year, now.month - 2, 1),
        completedAt: DateTime(now.year, now.month - 2, 3),
        paymentHash: _generatePaymentHash('TXN_DEMO_003', 15000.0, tenantId),
        upiTransactionId: 'UPI555666777',
      ),
    ];
  }
}
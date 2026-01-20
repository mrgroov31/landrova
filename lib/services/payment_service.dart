import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';
import '../models/payment.dart';
import '../models/payment_transaction.dart';
import 'api_service.dart';
import 'hive_api_service.dart';
import 'payment_api_service.dart';
import 'notification_service.dart';
import 'auth_service.dart';

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
        
        for (final testUrl in testUrls) {
          try {
            if (await canLaunchUrl(Uri.parse(testUrl))) {
              installedApps.add(app);
              debugPrint('✅ [PAYMENT] Found UPI app: ${app.name}');
              break; // Found this app, move to next
            }
          } catch (e) {
            // Continue with next URL
          }
        }
      } catch (e) {
        debugPrint('⚠️ [PAYMENT] Could not detect ${app.name}: $e');
      }
    }
    
    if (installedApps.isEmpty) {
      debugPrint('⚠️ [PAYMENT] No UPI apps detected (this may be normal in debug mode)');
      // Return all apps as potentially available for testing
      return _popularUpiApps;
    }
    
    debugPrint('📱 [PAYMENT] Found ${installedApps.length} UPI apps');
    return installedApps;
  }

  // Initialize payment service
  static Future<void> initialize() async {
    try {
      await NotificationService.initialize();
      debugPrint('✅ [PAYMENT] Service initialized with notifications');
    } catch (e) {
      debugPrint('❌ [PAYMENT] Failed to initialize: $e');
    }
  }

  /// Complete Payment Flow Implementation
  /// Following the backend API documentation flow:
  /// 1. Create payment record
  /// 2. Initiate payment (get UPI URL)
  /// 3. Launch UPI app
  /// 4. Handle payment result
  /// 5. Update payment status

  /// Step 1 & 2: Create and initiate payment
  static Future<Map<String, dynamic>> createAndInitiatePayment({
    required String tenantId,
    required String tenantName,
    required String ownerId,
    required String ownerName,
    required String ownerUpiId,
    required String roomId,
    required String roomNumber,
    required String paymentType,
    required double amount,
    required String month,
    required int year,
    required String description,
    required DateTime dueDate,
    double lateFee = 0,
  }) async {
    try {
      debugPrint('🚀 [PAYMENT] Starting complete payment flow');
      
      // Step 1: Create payment record
      final createResponse = await PaymentApiService.createPayment(
        tenantId: tenantId,
        type: paymentType,
        amount: amount,
        month: month,
        year: year,
        description: description,
        dueDate: dueDate.toIso8601String(),
        lateFee: lateFee,
      );

      if (!createResponse['success']) {
        throw Exception('Failed to create payment record');
      }

      final paymentId = createResponse['data']['id'];
      debugPrint('✅ [PAYMENT] Payment record created: $paymentId');

      // Step 2: Initiate payment (get UPI URL)
      final transactionId = _generateTransactionId();
      
      final initiateResponse = await PaymentApiService.initiatePayment(
        paymentId: paymentId,
        tenantId: tenantId,
        tenantName: tenantName,
        ownerId: ownerId,
        ownerName: ownerName,
        ownerUpiId: ownerUpiId,
        amount: amount + lateFee,
        roomId: roomId,
        roomNumber: roomNumber,
        paymentType: paymentType,
        month: month,
        year: year,
        paymentMethod: 'upi',
        transactionId: transactionId,
        clientMetadata: {
          'deviceId': 'flutter_device_${DateTime.now().millisecondsSinceEpoch}',
          'appVersion': '1.0.0',
          'platform': 'flutter',
        },
      );

      if (!initiateResponse['success']) {
        throw Exception('Failed to initiate payment');
      }

      final upiUrl = initiateResponse['data']['upiUrl'];
      final trackingId = initiateResponse['data']['trackingId'];
      
      debugPrint('✅ [PAYMENT] Payment initiated successfully');
      debugPrint('🔗 [PAYMENT] UPI URL: $upiUrl');

      return {
        'success': true,
        'paymentId': paymentId,
        'transactionId': transactionId,
        'upiUrl': upiUrl,
        'trackingId': trackingId,
        'expiresAt': initiateResponse['data']['expiresAt'],
      };
    } catch (e) {
      debugPrint('❌ [PAYMENT] Failed to create and initiate payment: $e');
      throw Exception('Payment initiation failed: $e');
    }
  }

  /// Step 3: Launch UPI app with payment URL
  static Future<bool> launchUpiPayment(String upiUrl) async {
    try {
      debugPrint('📱 [PAYMENT] Launching UPI payment');
      debugPrint('🔗 [PAYMENT] UPI URL: $upiUrl');

      final uri = Uri.parse(upiUrl);
      
      // Try to launch the UPI URL
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        
        if (launched) {
          debugPrint('✅ [PAYMENT] UPI app launched successfully');
          return true;
        } else {
          debugPrint('❌ [PAYMENT] Failed to launch UPI app');
          return false;
        }
      } else {
        debugPrint('❌ [PAYMENT] Cannot launch UPI URL - no compatible apps found');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [PAYMENT] Exception launching UPI payment: $e');
      return false;
    }
  }

  /// Step 5: Update payment status after UPI completion
  static Future<bool> updatePaymentStatus({
    required String paymentId,
    required String transactionId,
    required String status, // 'paid', 'failed', 'cancelled'
    String? upiTransactionId,
    double? paidAmount,
    String? errorMessage,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('🔄 [PAYMENT] Updating payment status to: $status');
      
      final receiptNumber = status == 'paid' 
          ? _generateReceiptNumber()
          : null;

      final response = await PaymentApiService.updatePaymentStatus(
        paymentId: paymentId,
        status: status,
        transactionId: transactionId,
        upiTransactionId: upiTransactionId,
        paidAmount: paidAmount,
        paidDate: status == 'paid' ? DateTime.now().toIso8601String() : null,
        paymentMethod: 'upi',
        notes: errorMessage ?? 'Payment completed via UPI',
        receipt: receiptNumber != null ? {
          'receiptNumber': receiptNumber,
          'receiptUrl': 'https://example.com/receipts/$receiptNumber.pdf',
        } : null,
      );

      if (response['success']) {
        debugPrint('✅ [PAYMENT] Payment status updated successfully');
        
        // Send notifications based on status
        await _sendPaymentStatusNotifications(
          status: status,
          paymentId: paymentId,
          transactionId: transactionId,
          amount: paidAmount ?? 0,
          receiptNumber: receiptNumber,
          errorMessage: errorMessage,
          additionalData: additionalData,
        );
        
        return true;
      } else {
        debugPrint('❌ [PAYMENT] Failed to update payment status');
        return false;
      }
    } catch (e) {
      debugPrint('❌ [PAYMENT] Exception updating payment status: $e');
      return false;
    }
  }

  /// Send notifications based on payment status
  static Future<void> _sendPaymentStatusNotifications({
    required String status,
    required String paymentId,
    required String transactionId,
    required double amount,
    String? receiptNumber,
    String? errorMessage,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final user = AuthService.currentUser;
      if (user == null) return;

      final tenantName = additionalData?['tenantName'] ?? 'Tenant';
      final roomNumber = additionalData?['roomNumber'] ?? 'Unknown';
      final paymentType = additionalData?['paymentType'] ?? 'rent';

      switch (status) {
        case 'paid':
          if (user.isOwner) {
            await NotificationService.notifyPaymentReceived(
              tenantName: tenantName,
              roomNumber: roomNumber,
              amount: amount,
              paymentType: paymentType,
              transactionId: transactionId,
            );
          } else if (user.isTenant) {
            await NotificationService.notifyPaymentSuccess(
              amount: amount,
              paymentType: paymentType,
              transactionId: transactionId,
              receiptNumber: receiptNumber ?? 'N/A',
            );
          }
          break;

        case 'failed':
        case 'cancelled':
          if (user.isTenant) {
            await NotificationService.notifyPaymentFailed(
              amount: amount,
              paymentType: paymentType,
              reason: errorMessage ?? 'Payment was $status',
              transactionId: transactionId,
            );
          }
          break;
      }
    } catch (e) {
      debugPrint('❌ [PAYMENT] Failed to send notifications: $e');
    }
  }

  /// Get pending payments using new API
  static Future<List<Payment>> getPendingPayments(String tenantId) async {
    try {
      final response = await PaymentApiService.getPendingPayments(
        tenantId: tenantId,
        ownerId: AuthService.getOwnerId(),
      );

      if (response['success'] && response['data'] != null) {
        final paymentsData = response['data']['payments'] as List;
        return paymentsData.map((p) => Payment.fromJson(p)).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('❌ [PAYMENT] Failed to get pending payments: $e');
      return [];
    }
  }

  /// Get payment history using new API
  static Future<List<PaymentTransaction>> getPaymentHistory(String tenantId) async {
    try {
      final response = await PaymentApiService.getPaymentHistory(
        tenantId: tenantId,
        ownerId: AuthService.getOwnerId(),
        status: 'paid',
      );

      if (response['success'] && response['data'] != null) {
        final paymentsData = response['data']['payments'] as List;
        return paymentsData.map((p) => PaymentTransaction.fromJson(p)).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('❌ [PAYMENT] Failed to get payment history: $e');
      return [];
    }
  }

  /// Get payment statistics using new API
  static Future<Map<String, dynamic>> getPaymentStatistics(String tenantId) async {
    try {
      final response = await PaymentApiService.getPaymentStatistics(
        tenantId: tenantId,
        ownerId: AuthService.getOwnerId(),
        period: 'year',
        year: DateTime.now().year,
      );

      if (response['success'] && response['data'] != null) {
        return response['data'];
      }
      
      return {};
    } catch (e) {
      debugPrint('❌ [PAYMENT] Failed to get payment statistics: $e');
      return {};
    }
  }

  /// Get owner payments for dashboard
  static Future<Map<String, dynamic>> getOwnerPayments({
    required String ownerId,
    String status = 'all',
    String? buildingId,
    int limit = 50,
  }) async {
    try {
      final response = await PaymentApiService.getOwnerPayments(
        ownerId: ownerId,
        status: status,
        buildingId: buildingId,
        limit: limit,
      );

      if (response['success'] && response['data'] != null) {
        return response['data'];
      }
      
      return {
        'payments': [],
        'summary': {
          'totalRevenue': 0.0,
          'totalPending': 0.0,
          'totalOverdue': 0.0,
          'collectionRate': 0.0,
        },
      };
    } catch (e) {
      debugPrint('❌ [PAYMENT] Failed to get owner payments: $e');
      return {
        'payments': [],
        'summary': {
          'totalRevenue': 0.0,
          'totalPending': 0.0,
          'totalOverdue': 0.0,
          'collectionRate': 0.0,
        },
      };
    }
  }

  /// Simulate payment completion for testing
  static Future<void> simulatePaymentCompletion({
    required String paymentId,
    required String transactionId,
    required double amount,
    bool success = true,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('🧪 [PAYMENT] Simulating payment completion');
      
      // Simulate delay
      await Future.delayed(const Duration(seconds: 2));
      
      final status = success ? 'paid' : 'failed';
      final upiTransactionId = success ? 'UPI${DateTime.now().millisecondsSinceEpoch}' : null;
      
      await updatePaymentStatus(
        paymentId: paymentId,
        transactionId: transactionId,
        status: status,
        upiTransactionId: upiTransactionId,
        paidAmount: success ? amount : null,
        errorMessage: success ? null : 'Simulated payment failure',
        additionalData: additionalData,
      );
      
      debugPrint('✅ [PAYMENT] Payment simulation completed: $status');
    } catch (e) {
      debugPrint('❌ [PAYMENT] Payment simulation failed: $e');
    }
  }

  /// Check payment status (polling mechanism)
  static Future<String?> checkPaymentStatus(String paymentId) async {
    try {
      // This would typically call a backend endpoint to check status
      // For now, we'll return null to indicate no status change
      debugPrint('🔍 [PAYMENT] Checking payment status for: $paymentId');
      return null;
    } catch (e) {
      debugPrint('❌ [PAYMENT] Failed to check payment status: $e');
      return null;
    }
  }

  /// Start payment status polling
  static void startPaymentStatusPolling({
    required String paymentId,
    required Function(String status) onStatusChange,
    Duration interval = const Duration(seconds: 5),
    Duration timeout = const Duration(minutes: 5),
  }) {
    final startTime = DateTime.now();
    
    Timer.periodic(interval, (timer) async {
      try {
        // Check if timeout reached
        if (DateTime.now().difference(startTime) > timeout) {
          timer.cancel();
          debugPrint('⏰ [PAYMENT] Polling timeout reached for: $paymentId');
          return;
        }

        final status = await checkPaymentStatus(paymentId);
        if (status != null && (status == 'paid' || status == 'failed' || status == 'cancelled')) {
          timer.cancel();
          onStatusChange(status);
          debugPrint('✅ [PAYMENT] Status polling completed: $status');
        }
      } catch (e) {
        debugPrint('❌ [PAYMENT] Error during status polling: $e');
      }
    });
  }

  // Helper methods
  static String _generateReceiptNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'RCP_${timestamp.toString().substring(timestamp.toString().length - 6)}';
  }

  // Keep existing methods for backward compatibility
  static List<UpiApp> getAvailableUpiApps() => _popularUpiApps;
}
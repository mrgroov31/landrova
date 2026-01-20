import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/payment.dart';
import '../models/payment_transaction.dart';

/// Service for handling all payment-related API calls to the backend
/// Implements the complete payment flow from the backend documentation
class PaymentApiService {
  static const String baseUrl = 'https://www.leranothrive.com/api';
  
  /// Enhanced logging helper for API responses
  static void _logApiResponse(String method, String endpoint, http.Response response, [Map<String, dynamic>? payload]) {
    debugPrint('');
    debugPrint('🔥 ===== PAYMENT API RESPONSE LOG =====');
    debugPrint('📍 Method: $method');
    debugPrint('🌐 Endpoint: $endpoint');
    debugPrint('📤 Request Payload: ${payload != null ? json.encode(payload) : 'None'}');
    debugPrint('📥 Response Status: ${response.statusCode}');
    debugPrint('📥 Response Headers: ${response.headers}');
    debugPrint('📥 Response Body: ${response.body}');
    
    // Try to parse and pretty print JSON response
    try {
      final jsonResponse = json.decode(response.body);
      debugPrint('📋 Parsed JSON Response:');
      debugPrint(const JsonEncoder.withIndent('  ').convert(jsonResponse));
    } catch (e) {
      debugPrint('⚠️ Response is not valid JSON: $e');
    }
    
    debugPrint('🔥 ===== END API RESPONSE LOG =====');
    debugPrint('');
  }

  /// Enhanced error logging helper
  static void _logApiError(String method, String endpoint, dynamic error, [Map<String, dynamic>? payload]) {
    debugPrint('');
    debugPrint('💥 ===== PAYMENT API ERROR LOG =====');
    debugPrint('📍 Method: $method');
    debugPrint('🌐 Endpoint: $endpoint');
    debugPrint('📤 Request Payload: ${payload != null ? json.encode(payload) : 'None'}');
    debugPrint('❌ Error: $error');
    debugPrint('💥 ===== END API ERROR LOG =====');
    debugPrint('');
  }

  // Headers for API requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'accept': '*/*',
    // Add authorization header when implementing auth
    // 'Authorization': 'Bearer ${AuthService.getToken()}',
  };

  /// Create a payment record (Step 1 of payment flow)
  static Future<Map<String, dynamic>> createPayment({
    required String tenantId,
    required String type,
    required double amount,
    required String month,
    required int year,
    required String description,
    required String dueDate,
    double lateFee = 0,
  }) async {
    const method = 'POST';
    const endpoint = '/payments';
    final uri = Uri.parse('$baseUrl$endpoint');
    
    final payload = {
      'tenantId': tenantId,
      'type': type,
      'amount': amount,
      'month': month,
      'year': year,
      'description': description,
      'dueDate': dueDate,
      'lateFee': lateFee,
    };
    
    try {
      debugPrint('💳 [PAYMENT API] Creating payment record');
      
      final response = await http.post(uri, headers: _headers, body: json.encode(payload));
      
      // Enhanced logging
      _logApiResponse(method, endpoint, response, payload);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [PAYMENT API] Payment record created successfully');
        return decodedResponse;
      } else {
        debugPrint('❌ [PAYMENT API] Failed to create payment: ${response.statusCode}');
        throw Exception('Failed to create payment: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logApiError(method, endpoint, e, payload);
      throw Exception('Error creating payment: $e');
    }
  }

  /// Initiate payment (Step 2 of payment flow) - Generate UPI URL
  static Future<Map<String, dynamic>> initiatePayment({
    required String paymentId,
    required String tenantId,
    required String ownerId,
    required double amount,
    required String transactionId,
    Map<String, dynamic>? clientMetadata,
    required String tenantName,
    required String ownerName,
    required String ownerUpiId,
    required String roomId,
    required String roomNumber,
    required String paymentType,
    required int year,
    required String paymentMethod,
    required String month,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/payments/initiate');
      
      final payload = {
        'paymentId': paymentId,
        'tenantId': tenantId,
        'tenantName': tenantName,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'ownerUpiId': ownerUpiId,
        'amount': amount,
        'roomId': roomId,
        'roomNumber': roomNumber,
        'paymentType': paymentType,
        'month': month,
        'year': year,
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
        'clientMetadata': clientMetadata ?? {
          'deviceId': 'flutter_device',
          'appVersion': '1.0.0',
          'platform': 'flutter',
        },
      };
      
      debugPrint('🚀 [PAYMENT API] Initiating payment');
      debugPrint('🌐 [PAYMENT API] URL: $uri');
      debugPrint('📤 [PAYMENT API] Payload: ${json.encode(payload)}');
      
      final response = await http.post(uri, headers: _headers, body: json.encode(payload));
      
      debugPrint('📥 [PAYMENT API] Response Status: ${response.statusCode}');
      debugPrint('📥 [PAYMENT API] Response Body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [PAYMENT API] Payment initiated successfully');
        debugPrint('🔗 [PAYMENT API] UPI URL: ${decodedResponse['data']?['upiUrl']}');
        return decodedResponse;
      } else {
        debugPrint('❌ [PAYMENT API] Failed to initiate payment: ${response.statusCode}');
        throw Exception('Failed to initiate payment: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [PAYMENT API] Exception while initiating payment: $e');
      throw Exception('Error initiating payment: $e');
    }
  }

  /// Update payment status (Step 5 of payment flow)
  static Future<Map<String, dynamic>> updatePaymentStatus({
    required String paymentId,
    required String status,
    required String transactionId,
    String? upiTransactionId,
    double? paidAmount,
    String? paidDate,
    String? paymentMethod,
    String? notes,
    Map<String, dynamic>? receipt,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/payments/$paymentId/status');
      
      final payload = {
        'status': status,
        'transactionId': transactionId,
        if (upiTransactionId != null) 'upiTransactionId': upiTransactionId,
        if (paidAmount != null) 'paidAmount': paidAmount,
        if (paidDate != null) 'paidDate': paidDate,
        if (paymentMethod != null) 'paymentMethod': paymentMethod,
        if (notes != null) 'notes': notes,
        if (receipt != null) 'receipt': receipt,
      };
      
      debugPrint('🔄 [PAYMENT API] Updating payment status');
      debugPrint('🌐 [PAYMENT API] URL: $uri');
      debugPrint('📤 [PAYMENT API] Payload: ${json.encode(payload)}');
      
      final response = await http.put(uri, headers: _headers, body: json.encode(payload));
      
      debugPrint('📥 [PAYMENT API] Response Status: ${response.statusCode}');
      debugPrint('📥 [PAYMENT API] Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [PAYMENT API] Payment status updated successfully');
        return decodedResponse;
      } else {
        debugPrint('❌ [PAYMENT API] Failed to update payment status: ${response.statusCode}');
        throw Exception('Failed to update payment status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [PAYMENT API] Exception while updating payment status: $e');
      throw Exception('Error updating payment status: $e');
    }
  }

  /// Get pending payments for a tenant
  static Future<Map<String, dynamic>> getPendingPayments({
    required String tenantId,
    String? ownerId,
    String? roomId,
    String status = 'pending',
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = {
        'tenantId': tenantId,
        'status': status,
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      if (ownerId != null) queryParams['ownerId'] = ownerId;
      if (roomId != null) queryParams['roomId'] = roomId;
      
      final uri = Uri.parse('$baseUrl/payments/pending').replace(
        queryParameters: queryParams,
      );
      
      debugPrint('📋 [PAYMENT API] Fetching pending payments');
      debugPrint('🌐 [PAYMENT API] URL: $uri');
      
      final response = await http.get(uri, headers: _headers);
      
      debugPrint('📥 [PAYMENT API] Response Status: ${response.statusCode}');
      debugPrint('📥 [PAYMENT API] Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [PAYMENT API] Successfully fetched pending payments');
        
        if (decodedResponse['data'] != null && decodedResponse['data']['payments'] != null) {
          final payments = decodedResponse['data']['payments'] as List;
          debugPrint('📊 [PAYMENT API] Found ${payments.length} pending payments');
        }
        
        return decodedResponse;
      } else {
        debugPrint('❌ [PAYMENT API] Failed to fetch pending payments: ${response.statusCode}');
        throw Exception('Failed to fetch pending payments: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [PAYMENT API] Exception while fetching pending payments: $e');
      throw Exception('Error fetching pending payments: $e');
    }
  }

  /// Get payment history for a tenant
  static Future<Map<String, dynamic>> getPaymentHistory({
    required String tenantId,
    String? ownerId,
    String? roomId,
    String status = 'paid',
    String? fromDate,
    String? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = {
        'tenantId': tenantId,
        'status': status,
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      if (ownerId != null) queryParams['ownerId'] = ownerId;
      if (roomId != null) queryParams['roomId'] = roomId;
      if (fromDate != null) queryParams['fromDate'] = fromDate;
      if (toDate != null) queryParams['toDate'] = toDate;
      
      final uri = Uri.parse('$baseUrl/payments/history').replace(
        queryParameters: queryParams,
      );
      
      debugPrint('📋 [PAYMENT API] Fetching payment history');
      debugPrint('🌐 [PAYMENT API] URL: $uri');
      
      final response = await http.get(uri, headers: _headers);
      
      debugPrint('📥 [PAYMENT API] Response Status: ${response.statusCode}');
      debugPrint('📥 [PAYMENT API] Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [PAYMENT API] Successfully fetched payment history');
        return decodedResponse;
      } else {
        debugPrint('❌ [PAYMENT API] Failed to fetch payment history: ${response.statusCode}');
        throw Exception('Failed to fetch payment history: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [PAYMENT API] Exception while fetching payment history: $e');
      throw Exception('Error fetching payment history: $e');
    }
  }

  /// Get payment statistics
  static Future<Map<String, dynamic>> getPaymentStatistics({
    required String tenantId,
    String? ownerId,
    String period = 'year',
    int? year,
    int? month,
  }) async {
    try {
      final queryParams = {
        'tenantId': tenantId,
        'period': period,
      };
      
      if (ownerId != null) queryParams['ownerId'] = ownerId;
      if (year != null) queryParams['year'] = year.toString();
      if (month != null) queryParams['month'] = month.toString();
      
      final uri = Uri.parse('$baseUrl/payments/statistics').replace(
        queryParameters: queryParams,
      );
      
      debugPrint('📊 [PAYMENT API] Fetching payment statistics');
      debugPrint('🌐 [PAYMENT API] URL: $uri');
      
      final response = await http.get(uri, headers: _headers);
      
      debugPrint('📥 [PAYMENT API] Response Status: ${response.statusCode}');
      debugPrint('📥 [PAYMENT API] Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [PAYMENT API] Successfully fetched payment statistics');
        return decodedResponse;
      } else {
        debugPrint('❌ [PAYMENT API] Failed to fetch payment statistics: ${response.statusCode}');
        throw Exception('Failed to fetch payment statistics: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [PAYMENT API] Exception while fetching payment statistics: $e');
      throw Exception('Error fetching payment statistics: $e');
    }
  }

  /// Get owner payments (for owner dashboard)
  static Future<Map<String, dynamic>> getOwnerPayments({
    required String ownerId,
    String status = 'all',
    String? roomId,
    String? buildingId,
    String? fromDate,
    String? toDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = {
        'ownerId': ownerId,
        'status': status,
        'limit': limit.toString(),
        'offset': offset.toString(),
      };
      
      if (roomId != null) queryParams['roomId'] = roomId;
      if (buildingId != null) queryParams['buildingId'] = buildingId;
      if (fromDate != null) queryParams['fromDate'] = fromDate;
      if (toDate != null) queryParams['toDate'] = toDate;
      
      final uri = Uri.parse('$baseUrl/payments/owner').replace(
        queryParameters: queryParams,
      );
      
      debugPrint('🏠 [PAYMENT API] Fetching owner payments');
      debugPrint('🌐 [PAYMENT API] URL: $uri');
      
      final response = await http.get(uri, headers: _headers);
      
      debugPrint('📥 [PAYMENT API] Response Status: ${response.statusCode}');
      debugPrint('📥 [PAYMENT API] Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [PAYMENT API] Successfully fetched owner payments');
        return decodedResponse;
      } else {
        debugPrint('❌ [PAYMENT API] Failed to fetch owner payments: ${response.statusCode}');
        throw Exception('Failed to fetch owner payments: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [PAYMENT API] Exception while fetching owner payments: $e');
      throw Exception('Error fetching owner payments: $e');
    }
  }

  /// Generate transaction ID
  static String generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (DateTime.now().microsecond % 9999) + 1000;
    return 'TXN${timestamp}_$random';
  }

  /// Generate receipt number
  static String generateReceiptNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'RCP_${timestamp.toString().substring(timestamp.toString().length - 6)}';
  }
}
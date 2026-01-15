import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/payment.dart';
import '../models/payment_transaction.dart';

/// Service for handling all payment-related API calls to the backend
class PaymentApiService {
  static const String baseUrl = 'https://www.leranothrive.com/api';
  
  // Headers for API requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'accept': '*/*',
    // Add authorization header when implementing auth
    // 'Authorization': 'Bearer ${AuthService.getToken()}',
  };

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
      debugPrint('📤 [PAYMENT API] Method: GET');
      
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
      
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [PAYMENT API] Successfully fetched payment history');
        
        if (decodedResponse['data'] != null && decodedResponse['data']['payments'] != null) {
          final payments = decodedResponse['data']['payments'] as List;
          debugPrint('📊 [PAYMENT API] Found ${payments.length} payment history records');
        }
        
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

  /// Get payment statistics for a tenant
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
      
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [PAYMENT API] Successfully fetched payment statistics');
        
        if (decodedResponse['data'] != null) {
          final data = decodedResponse['data'];
          debugPrint('📊 [PAYMENT API] Total payments: ${data['totalPayments']}');
          debugPrint('📊 [PAYMENT API] Payment rate: ${data['paymentRate']}%');
        }
        
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

  /// Initiate a payment transaction
  static Future<Map<String, dynamic>> initiatePayment({
    required String paymentId,
    required String tenantId,
    required String tenantName,
    required String ownerId,
    required String ownerName,
    required String ownerUpiId,
    required String roomId,
    required String roomNumber,
    required double amount,
    required String paymentType,
    required String month,
    required int year,
    String? description,
    required String paymentMethod,
    required String transactionId,
    Map<String, dynamic>? clientMetadata,
  }) async {
    try {
      final payload = {
        'paymentId': paymentId,
        'tenantId': tenantId,
        'tenantName': tenantName,
        'ownerId': ownerId,
        'ownerName': ownerName,
        'ownerUpiId': ownerUpiId,
        'roomId': roomId,
        'roomNumber': roomNumber,
        'amount': amount,
        'paymentType': paymentType,
        'month': month,
        'year': year,
        'description': description ?? '$paymentType payment for Room $roomNumber - $month $year',
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
        'clientMetadata': clientMetadata ?? {
          'deviceId': 'flutter_device',
          'appVersion': '1.0.0',
          'platform': 'android',
        },
      };
      
      final uri = Uri.parse('$baseUrl/payments/initiate');
      
      debugPrint('💳 [PAYMENT API] Initiating payment');
      debugPrint('🌐 [PAYMENT API] URL: $uri');
      debugPrint('📤 [PAYMENT API] Method: POST');
      debugPrint('📤 [PAYMENT API] Payload: ${json.encode(payload)}');
      
      final response = await http.post(
        uri,
        headers: _headers,
        body: json.encode(payload),
      );
      
      debugPrint('📥 [PAYMENT API] Response Status: ${response.statusCode}');
      debugPrint('📥 [PAYMENT API] Response Body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [PAYMENT API] Payment initiated successfully');
        
        if (decodedResponse['data'] != null) {
          final data = decodedResponse['data'];
          debugPrint('💳 [PAYMENT API] Transaction ID: ${data['transactionId']}');
          debugPrint('💳 [PAYMENT API] Status: ${data['status']}');
        }
        
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

  /// Update payment status
  static Future<Map<String, dynamic>> updatePaymentStatus({
    required String paymentId,
    required String status,
    required String transactionId,
    String? upiTransactionId,
    double? paidAmount,
    String? paidDate,
    required String paymentMethod,
    String? notes,
    Map<String, dynamic>? receipt,
  }) async {
    try {
      final payload = <String, dynamic>{
        'status': status,
        'transactionId': transactionId,
        'paymentMethod': paymentMethod,
      };
      
      if (upiTransactionId != null) payload['upiTransactionId'] = upiTransactionId;
      if (paidAmount != null) payload['paidAmount'] = paidAmount;
      if (paidDate != null) payload['paidDate'] = paidDate;
      if (notes != null) payload['notes'] = notes;
      if (receipt != null) payload['receipt'] = receipt;
      
      final uri = Uri.parse('$baseUrl/payments/$paymentId/status');
      
      debugPrint('🔄 [PAYMENT API] Updating payment status');
      debugPrint('🌐 [PAYMENT API] URL: $uri');
      debugPrint('📤 [PAYMENT API] Method: PUT');
      debugPrint('📤 [PAYMENT API] Payload: ${json.encode(payload)}');
      
      final response = await http.put(
        uri,
        headers: _headers,
        body: json.encode(payload),
      );
      
      debugPrint('📥 [PAYMENT API] Response Status: ${response.statusCode}');
      debugPrint('📥 [PAYMENT API] Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [PAYMENT API] Payment status updated successfully');
        
        if (decodedResponse['data'] != null) {
          final data = decodedResponse['data'];
          debugPrint('🔄 [PAYMENT API] Payment ID: ${data['paymentId']}');
          debugPrint('🔄 [PAYMENT API] New Status: ${data['status']}');
        }
        
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

  /// Get all payments for an owner (for owner dashboard)
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
      
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [PAYMENT API] Successfully fetched owner payments');
        
        if (decodedResponse['data'] != null) {
          final data = decodedResponse['data'];
          if (data['payments'] != null) {
            final payments = data['payments'] as List;
            debugPrint('📊 [PAYMENT API] Found ${payments.length} payments for owner');
          }
          if (data['summary'] != null) {
            final summary = data['summary'];
            debugPrint('💰 [PAYMENT API] Total Revenue: ₹${summary['totalRevenue']}');
            debugPrint('⏳ [PAYMENT API] Total Pending: ₹${summary['totalPending']}');
            debugPrint('📈 [PAYMENT API] Collection Rate: ${summary['collectionRate']}%');
          }
        }
        
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

  /// Parse payments from API response
  static List<Payment> parsePayments(Map<String, dynamic> response) {
    debugPrint('🔍 [PAYMENT API] Parsing payments from response');
    
    try {
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        List<dynamic> paymentsData = [];
        
        if (data['payments'] != null) {
          paymentsData = data['payments'] as List<dynamic>;
          debugPrint('🔍 [PAYMENT API] Found ${paymentsData.length} payments to parse');
        }
        
        final List<Payment> parsedPayments = [];
        for (int i = 0; i < paymentsData.length; i++) {
          try {
            final paymentJson = paymentsData[i] as Map<String, dynamic>;
            final payment = Payment.fromJson(paymentJson);
            parsedPayments.add(payment);
            debugPrint('✅ [PAYMENT API] Successfully parsed payment ${i + 1}: ${payment.id}');
          } catch (e, stackTrace) {
            debugPrint('❌ [PAYMENT API] Error parsing payment ${i + 1}: $e');
            debugPrint('❌ [PAYMENT API] Stack trace: $stackTrace');
            debugPrint('❌ [PAYMENT API] Payment data: ${paymentsData[i]}');
          }
        }
        
        debugPrint('✅ [PAYMENT API] Successfully parsed ${parsedPayments.length} out of ${paymentsData.length} payments');
        return parsedPayments;
      }
    } catch (e, stackTrace) {
      debugPrint('💥 [PAYMENT API] Fatal error parsing payments: $e');
      debugPrint('💥 [PAYMENT API] Stack trace: $stackTrace');
    }
    
    return [];
  }

  /// Parse payment statistics from API response
  static Map<String, dynamic> parsePaymentStatistics(Map<String, dynamic> response) {
    debugPrint('🔍 [PAYMENT API] Parsing payment statistics from response');
    
    try {
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        debugPrint('✅ [PAYMENT API] Successfully parsed payment statistics');
        return data;
      }
    } catch (e) {
      debugPrint('💥 [PAYMENT API] Error parsing payment statistics: $e');
    }
    
    return {};
  }
}
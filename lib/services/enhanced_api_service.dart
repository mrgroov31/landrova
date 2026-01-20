import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class EnhancedApiService {
  static Future<Map<String, dynamic>> makeRequest({
    required String endpoint,
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    String? fallbackAssetPath,
  }) async {
    final defaultHeaders = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?headers,
    };

    for (int attempt = 1; attempt <= ApiConfig.maxRetries; attempt++) {
      try {
        debugPrint('🌐 [API] Attempt $attempt/$ApiConfig.maxRetries: $method $endpoint');
        
        final uri = Uri.parse(endpoint);
        http.Response response;

        switch (method.toUpperCase()) {
          case 'GET':
            response = await http.get(uri, headers: defaultHeaders)
                .timeout(ApiConfig.connectionTimeout);
            break;
          case 'POST':
            response = await http.post(
              uri,
              headers: defaultHeaders,
              body: body != null ? json.encode(body) : null,
            ).timeout(ApiConfig.connectionTimeout);
            break;
          case 'PUT':
            response = await http.put(
              uri,
              headers: defaultHeaders,
              body: body != null ? json.encode(body) : null,
            ).timeout(ApiConfig.connectionTimeout);
            break;
          case 'DELETE':
            response = await http.delete(uri, headers: defaultHeaders)
                .timeout(ApiConfig.connectionTimeout);
            break;
          default:
            throw Exception('Unsupported HTTP method: $method');
        }

        debugPrint('📥 [API] Response: ${response.statusCode}');

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final responseData = json.decode(response.body);
          debugPrint('✅ [API] Success: $endpoint');
          return responseData;
        } else {
          debugPrint('❌ [API] HTTP Error ${response.statusCode}: ${response.body}');
          if (attempt == ApiConfig.maxRetries) {
            throw HttpException('HTTP ${response.statusCode}: ${response.body}');
          }
        }
      } on SocketException catch (e) {
        debugPrint('🔌 [API] Connection error (attempt $attempt): $e');
        if (attempt == ApiConfig.maxRetries) {
          return _handleConnectionFailure(endpoint, fallbackAssetPath, e);
        }
      } on TimeoutException catch (e) {
        debugPrint('⏰ [API] Timeout error (attempt $attempt): $e');
        if (attempt == ApiConfig.maxRetries) {
          return _handleConnectionFailure(endpoint, fallbackAssetPath, e);
        }
      } catch (e) {
        debugPrint('💥 [API] Unexpected error (attempt $attempt): $e');
        if (attempt == ApiConfig.maxRetries) {
          return _handleConnectionFailure(endpoint, fallbackAssetPath, e);
        }
      }

      if (attempt < ApiConfig.maxRetries) {
        debugPrint('🔄 [API] Retrying in ${ApiConfig.retryDelay.inSeconds}s...');
        await Future.delayed(ApiConfig.retryDelay);
      }
    }

    return _handleConnectionFailure(endpoint, fallbackAssetPath, 
        Exception('Max retries exceeded'));
  }

  static Future<Map<String, dynamic>> _handleConnectionFailure(
    String endpoint,
    String? fallbackAssetPath,
    dynamic error,
  ) async {
    debugPrint('🚨 [API] Connection failed for: $endpoint');
    debugPrint('🚨 [API] Error: $error');

    if (ApiConfig.enableMockFallback && fallbackAssetPath != null) {
      try {
        debugPrint('📁 [API] Loading fallback data from: $fallbackAssetPath');
        final String response = await rootBundle.loadString(fallbackAssetPath);
        final data = json.decode(response);
        debugPrint('✅ [API] Fallback data loaded successfully');
        return data;
      } catch (fallbackError) {
        debugPrint('❌ [API] Fallback also failed: $fallbackError');
      }
    }

    // Return a structured error response
    return {
      'success': false,
      'error': 'Connection failed',
      'message': 'Unable to connect to server. Please check your internet connection.',
      'details': error.toString(),
      'fallbackUsed': fallbackAssetPath != null,
    };
  }

  // Convenience methods for common API calls
  static Future<Map<String, dynamic>> getRooms(String ownerId) async {
    return makeRequest(
      endpoint: ApiEndpoints.rooms(ownerId),
      fallbackAssetPath: 'lib/data/mock_responses/rooms.json',
    );
  }

  static Future<Map<String, dynamic>> getTenants(String ownerId) async {
    return makeRequest(
      endpoint: ApiEndpoints.tenants(ownerId),
      fallbackAssetPath: 'lib/data/mock_responses/tenants.json',
    );
  }

  static Future<Map<String, dynamic>> getBuildings(String ownerId) async {
    return makeRequest(
      endpoint: ApiEndpoints.buildings(ownerId),
      fallbackAssetPath: 'lib/data/mock_responses/buildings.json',
    );
  }

  static Future<Map<String, dynamic>> getComplaints(String ownerId) async {
    return makeRequest(
      endpoint: ApiEndpoints.complaints(ownerId),
      fallbackAssetPath: 'lib/data/mock_responses/complaints.json',
    );
  }

  static Future<Map<String, dynamic>> getServiceProviders({
    Map<String, String>? queryParams,
  }) async {
    String endpoint = ApiEndpoints.serviceProviders;
    if (queryParams != null && queryParams.isNotEmpty) {
      final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);
      endpoint = uri.toString();
    }
    
    return makeRequest(
      endpoint: endpoint,
      fallbackAssetPath: 'lib/data/mock_responses/service_providers.json',
    );
  }

  static Future<Map<String, dynamic>> recordPayment(Map<String, dynamic> paymentData) async {
    return makeRequest(
      endpoint: ApiEndpoints.payments,
      method: 'POST',
      body: paymentData,
    );
  }

  static Future<Map<String, dynamic>> getOwnerUpiDetails(String ownerId) async {
    return makeRequest(
      endpoint: ApiEndpoints.ownerUpi(ownerId),
    );
  }

  static Future<Map<String, dynamic>> saveOwnerUpiDetails(
    String ownerId, 
    Map<String, dynamic> upiData,
  ) async {
    return makeRequest(
      endpoint: ApiEndpoints.ownerUpi(ownerId),
      method: 'POST',
      body: upiData,
    );
  }
}
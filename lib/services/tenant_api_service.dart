import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/tenant.dart';

/// Service for handling all tenant-related API calls to the backend
/// Implements the complete tenant CRUD operations from the backend documentation
class TenantApiService {
  static const String baseUrl = 'https://www.leranothrive.com/api';
  
  /// Enhanced logging helper for API responses
  static void _logApiResponse(String method, String endpoint, http.Response response, [Map<String, dynamic>? payload]) {
    debugPrint('');
    debugPrint('🏠 ===== TENANT API RESPONSE LOG =====');
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
    
    debugPrint('🏠 ===== END TENANT API RESPONSE LOG =====');
    debugPrint('');
  }

  /// Enhanced error logging helper
  static void _logApiError(String method, String endpoint, dynamic error, [Map<String, dynamic>? payload]) {
    debugPrint('');
    debugPrint('💥 ===== TENANT API ERROR LOG =====');
    debugPrint('📍 Method: $method');
    debugPrint('🌐 Endpoint: $endpoint');
    debugPrint('📤 Request Payload: ${payload != null ? json.encode(payload) : 'None'}');
    debugPrint('❌ Error: $error');
    debugPrint('💥 ===== END TENANT API ERROR LOG =====');
    debugPrint('');
  }

  // Headers for API requests
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // Add authorization header when implementing auth
    // 'Authorization': 'Bearer ${AuthService.getToken()}',
  };

  /// Create a new tenant (POST /api/tenants)
  static Future<Map<String, dynamic>> createTenant({
    required String roomId,
    required String name,
    required String email,
    required String phone,
    required String moveInDate,
    String? leaseEndDate,
    required String type,
    String? occupation,
    String? aadharNumber,
    String? emergencyContact,
    String? profileImage,
    String? aadharFrontImage,
    String? aadharBackImage,
    String? panCardImage,
    String? addressProofImage,
    List<FamilyMember>? familyMembers,
    EmergencyContactDetails? emergencyContactDetails,
    IdProof? idProof,
  }) async {
    const method = 'POST';
    const endpoint = '/tenants';
    final uri = Uri.parse('$baseUrl$endpoint');
    
    final payload = {
      'roomId': roomId,
      'name': name,
      'email': email,
      'phone': phone,
      'moveInDate': moveInDate,
      if (leaseEndDate != null) 'leaseEndDate': leaseEndDate,
      'type': type,
      if (occupation != null) 'occupation': occupation,
      if (aadharNumber != null) 'aadharNumber': aadharNumber,
      if (emergencyContact != null) 'emergencyContact': emergencyContact,
      if (profileImage != null) 'profileImage': profileImage,
      if (aadharFrontImage != null) 'aadharFrontImage': aadharFrontImage,
      if (aadharBackImage != null) 'aadharBackImage': aadharBackImage,
      if (panCardImage != null) 'panCardImage': panCardImage,
      if (addressProofImage != null) 'addressProofImage': addressProofImage,
      if (familyMembers != null) 
        'familyMembers': familyMembers.map((member) => member.toJson()).toList(),
      if (emergencyContactDetails != null) 
        'emergencyContactDetails': emergencyContactDetails.toJson(),
      if (idProof != null) 'idProof': idProof.toJson(),
    };
    
    try {
      debugPrint('🏠 [TENANT API] Creating tenant');
      
      final response = await http.post(uri, headers: _headers, body: json.encode(payload));
      
      // Enhanced logging
      _logApiResponse(method, endpoint, response, payload);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [TENANT API] Tenant created successfully');
        return decodedResponse;
      } else {
        debugPrint('❌ [TENANT API] Failed to create tenant: ${response.statusCode}');
        throw Exception('Failed to create tenant: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logApiError(method, endpoint, e, payload);
      throw Exception('Error creating tenant: $e');
    }
  }

  /// Update tenant (PATCH /api/tenants/{id})
  static Future<Map<String, dynamic>> updateTenant({
    required String tenantId,
    String? name,
    String? email,
    String? phone,
    String? type,
    String? occupation,
    String? aadharNumber,
    String? emergencyContact,
    String? leaseEndDate,
    String? profileImage,
    String? aadharFrontImage,
    String? aadharBackImage,
    String? panCardImage,
    String? addressProofImage,
    List<FamilyMember>? familyMembers,
    EmergencyContactDetails? emergencyContactDetails,
    IdProof? idProof,
    bool? isActive,
  }) async {
    const method = 'PATCH';
    final endpoint = '/tenants/$tenantId';
    final uri = Uri.parse('$baseUrl$endpoint');
    
    final payload = <String, dynamic>{};
    
    // Only include fields that are being updated
    if (name != null) payload['name'] = name;
    if (email != null) payload['email'] = email;
    if (phone != null) payload['phone'] = phone;
    if (type != null) payload['type'] = type;
    if (occupation != null) payload['occupation'] = occupation;
    if (aadharNumber != null) payload['aadharNumber'] = aadharNumber;
    if (emergencyContact != null) payload['emergencyContact'] = emergencyContact;
    if (leaseEndDate != null) payload['leaseEndDate'] = leaseEndDate;
    if (profileImage != null) payload['profileImage'] = profileImage;
    if (aadharFrontImage != null) payload['aadharFrontImage'] = aadharFrontImage;
    if (aadharBackImage != null) payload['aadharBackImage'] = aadharBackImage;
    if (panCardImage != null) payload['panCardImage'] = panCardImage;
    if (addressProofImage != null) payload['addressProofImage'] = addressProofImage;
    if (isActive != null) payload['isActive'] = isActive;
    
    if (familyMembers != null) {
      payload['familyMembers'] = familyMembers.map((member) => member.toJson()).toList();
    }
    if (emergencyContactDetails != null) {
      payload['emergencyContactDetails'] = emergencyContactDetails.toJson();
    }
    if (idProof != null) {
      payload['idProof'] = idProof.toJson();
    }
    
    try {
      debugPrint('🏠 [TENANT API] Updating tenant: $tenantId');
      
      final response = await http.patch(uri, headers: _headers, body: json.encode(payload));
      
      // Enhanced logging
      _logApiResponse(method, endpoint, response, payload);
      
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [TENANT API] Tenant updated successfully');
        return decodedResponse;
      } else {
        debugPrint('❌ [TENANT API] Failed to update tenant: ${response.statusCode}');
        throw Exception('Failed to update tenant: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logApiError(method, endpoint, e, payload);
      throw Exception('Error updating tenant: $e');
    }
  }

  /// Get single tenant (GET /api/tenants/{id})
  static Future<Map<String, dynamic>> getTenant(String tenantId) async {
    const method = 'GET';
    final endpoint = '/tenants/$tenantId';
    final uri = Uri.parse('$baseUrl$endpoint');
    
    try {
      debugPrint('🏠 [TENANT API] Getting tenant: $tenantId');
      
      final response = await http.get(uri, headers: _headers);
      
      // Enhanced logging
      _logApiResponse(method, endpoint, response);
      
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [TENANT API] Tenant fetched successfully');
        return decodedResponse;
      } else {
        debugPrint('❌ [TENANT API] Failed to get tenant: ${response.statusCode}');
        throw Exception('Failed to get tenant: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logApiError(method, endpoint, e);
      throw Exception('Error getting tenant: $e');
    }
  }

  /// Get all tenants (GET /api/tenants)
  static Future<Map<String, dynamic>> getAllTenants({
    String? roomId,
    bool? isActive,
    int limit = 50,
    int offset = 0,
  }) async {
    const method = 'GET';
    const endpoint = '/tenants';
    
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    
    if (roomId != null) queryParams['roomId'] = roomId;
    if (isActive != null) queryParams['isActive'] = isActive.toString();
    
    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);
    
    try {
      debugPrint('🏠 [TENANT API] Getting all tenants');
      debugPrint('🌐 [TENANT API] URL: $uri');
      
      final response = await http.get(uri, headers: _headers);
      
      // Enhanced logging
      _logApiResponse(method, endpoint, response);
      
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [TENANT API] Tenants fetched successfully');
        
        if (decodedResponse['data'] != null && decodedResponse['data']['tenants'] != null) {
          final tenants = decodedResponse['data']['tenants'] as List;
          debugPrint('📊 [TENANT API] Found ${tenants.length} tenants');
        }
        
        return decodedResponse;
      } else {
        debugPrint('❌ [TENANT API] Failed to get tenants: ${response.statusCode}');
        throw Exception('Failed to get tenants: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logApiError(method, endpoint, e);
      throw Exception('Error getting tenants: $e');
    }
  }

  /// Delete tenant (DELETE /api/tenants/{id})
  static Future<Map<String, dynamic>> deleteTenant(String tenantId) async {
    const method = 'DELETE';
    final endpoint = '/tenants/$tenantId';
    final uri = Uri.parse('$baseUrl$endpoint');
    
    try {
      debugPrint('🏠 [TENANT API] Deleting tenant: $tenantId');
      
      final response = await http.delete(uri, headers: _headers);
      
      // Enhanced logging
      _logApiResponse(method, endpoint, response);
      
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [TENANT API] Tenant deleted successfully');
        return decodedResponse;
      } else {
        debugPrint('❌ [TENANT API] Failed to delete tenant: ${response.statusCode}');
        throw Exception('Failed to delete tenant: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      _logApiError(method, endpoint, e);
      throw Exception('Error deleting tenant: $e');
    }
  }

  /// Get tenants by room (convenience method)
  static Future<List<Tenant>> getTenantsByRoom(String roomId) async {
    try {
      final response = await getAllTenants(roomId: roomId, isActive: true);
      
      if (response['success'] == true && response['data'] != null) {
        final tenantsData = response['data']['tenants'] as List;
        return tenantsData.map((t) => Tenant.fromJson(t)).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('❌ [TENANT API] Failed to get tenants by room: $e');
      return [];
    }
  }

  /// Get active tenants (convenience method)
  static Future<List<Tenant>> getActiveTenants() async {
    try {
      final response = await getAllTenants(isActive: true);
      
      if (response['success'] == true && response['data'] != null) {
        final tenantsData = response['data']['tenants'] as List;
        return tenantsData.map((t) => Tenant.fromJson(t)).toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('❌ [TENANT API] Failed to get active tenants: $e');
      return [];
    }
  }

  /// Update tenant family members only (convenience method)
  static Future<Map<String, dynamic>> updateTenantFamilyMembers({
    required String tenantId,
    required List<FamilyMember> familyMembers,
  }) async {
    return updateTenant(
      tenantId: tenantId,
      familyMembers: familyMembers,
    );
  }

  /// Deactivate tenant (convenience method for tenant move-out)
  static Future<Map<String, dynamic>> deactivateTenant(String tenantId) async {
    return updateTenant(
      tenantId: tenantId,
      isActive: false,
    );
  }
}
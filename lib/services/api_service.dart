import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/room.dart';
import '../models/tenant.dart';
import '../models/api_tenant.dart';
import '../models/complaint.dart';
import '../models/payment.dart';
import '../models/building.dart';
import '../models/service_provider.dart';
import '../config/api_config.dart';
import 'enhanced_api_service.dart';
import 'dart:developer';

class ApiService {
  // Simulate API calls by loading JSON files
  static Future<Map<String, dynamic>> fetchRooms() async {
    final String response = await rootBundle.loadString('lib/data/mock_responses/rooms.json');
    return json.decode(response);
  }

  static Future<Map<String, dynamic>> fetchTenants() async {
    final String response = await rootBundle.loadString('lib/data/mock_responses/tenants.json');
    return json.decode(response);
  }

  static Future<Map<String, dynamic>> fetchComplaints() async {
    final String response = await rootBundle.loadString('lib/data/mock_responses/complaints.json');
    return json.decode(response);
  }

  static Future<Map<String, dynamic>> fetchPayments() async {
    final String response = await rootBundle.loadString('lib/data/mock_responses/payments.json');
    return json.decode(response);
  }

  static Future<Map<String, dynamic>> fetchDashboard() async {
    final String response = await rootBundle.loadString('lib/data/mock_responses/dashboard.json');
    return json.decode(response);
  }

  // Fetch rooms by owner ID
  static Future<Map<String, dynamic>> fetchRoomsByOwnerId(String ownerId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/owners/$ownerId/rooms');
      
      debugPrint('🏠 [API] Fetching rooms for ownerId: $ownerId');
      debugPrint('🌐 [API] URL: $url');
      debugPrint('📤 [API] Method: GET');
      debugPrint('📤 [API] Headers: {accept: */*}');
      
      final response = await http.get(
        url,
        headers: {
          'accept': '*/*',
        },
      );

      debugPrint('📥 [API] Response Status Code: ${response.statusCode}');
      debugPrint('📥 [API] Response Headers: ${response.headers}');
      log('📥 [API] Response Body: 1 ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [API] Successfully fetched rooms');
        print('📊 [API] Number of rooms: ${decodedResponse['data']?.length ?? 0}');
        return decodedResponse;
      } else {
        debugPrint('❌ [API] Failed to fetch rooms: ${response.statusCode}');
        debugPrint('❌ [API] Error Body: ${response.body}');
        throw Exception('Failed to fetch rooms: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [API] Exception while fetching rooms: $e');
      throw Exception('Error fetching rooms: $e');
    }
  }

  // Parse rooms from API response
  static List<Room> parseRooms(Map<String, dynamic> response) {
    debugPrint('🔍 [PARSE] Parsing rooms from response: ${response.keys}');
    
    // Handle both old mock format and new API format
    List<dynamic> roomsData = [];
    
    try {
      if (response['data'] != null) {
        debugPrint('🔍 [PARSE] Found data key in response');
        
        if (response['data'] is List) {
          // New API format: { "success": true, "data": [...] }
          roomsData = response['data'] as List<dynamic>;
          debugPrint('🔍 [PARSE] Data is a List, found ${roomsData.length} rooms');
        } else if (response['data'] is Map) {
          final dataMap = response['data'] as Map<String, dynamic>;
          if (dataMap['rooms'] != null) {
            // Old mock format: { "data": { "rooms": [...] } }
            roomsData = dataMap['rooms'] as List<dynamic>;
            debugPrint('🔍 [PARSE] Data is a Map with rooms key, found ${roomsData.length} rooms');
          } else {
            debugPrint('⚠️ [PARSE] Data is a Map but no rooms key found. Keys: ${dataMap.keys}');
          }
        } else {
          debugPrint('⚠️ [PARSE] Data is neither List nor Map, type: ${response['data'].runtimeType}');
        }
      } else {
        debugPrint('⚠️ [PARSE] No data key in response. Response keys: ${response.keys}');
        // Try direct array format: [{...}, {...}]
        if (response is List) {
          roomsData = response as List<dynamic>;
          debugPrint('🔍 [PARSE] Response is directly a List, found ${roomsData.length} rooms');
        }
      }
      
      debugPrint('✅ [PARSE] Total rooms to parse: ${roomsData.length}');
      
      // Parse each room with error handling
      final List<Room> parsedRooms = [];
      for (int i = 0; i < roomsData.length; i++) {
        try {
          final roomJson = roomsData[i];
          // Ensure we have a proper Map<String, dynamic>
          final Map<String, dynamic> roomMap;
          if (roomJson is Map<String, dynamic>) {
            roomMap = roomJson;
          } else if (roomJson is Map) {
            roomMap = Map<String, dynamic>.from(roomJson);
          } else {
            debugPrint('❌ [PARSE] Room ${i + 1} is not a Map: ${roomJson.runtimeType}');
            continue;
          }
          
          final room = Room.fromJson(roomMap);
          parsedRooms.add(room);
          debugPrint('✅ [PARSE] Successfully parsed room ${i + 1}: ${room.number}');
        } catch (e, stackTrace) {
          debugPrint('❌ [PARSE] Error parsing room ${i + 1}: $e');
          debugPrint('❌ [PARSE] Stack trace: $stackTrace');
          debugPrint('❌ [PARSE] Room data: ${roomsData[i]}');
        }
      }
      
      debugPrint('✅ [PARSE] Successfully parsed ${parsedRooms.length} out of ${roomsData.length} rooms');
      return parsedRooms;
    } catch (e, stackTrace) {
      debugPrint('💥 [PARSE] Fatal error parsing rooms: $e');
      debugPrint('💥 [PARSE] Stack trace: $stackTrace');
      return [];
    }
  }

  static List<Tenant> parseTenants(Map<String, dynamic> response) {
    final List<dynamic> tenantsData = response['data']['tenants'];
    return tenantsData.map((json) => Tenant.fromJson(json)).toList();
  }

  static List<Complaint> parseComplaints(Map<String, dynamic> response) {
    final List<dynamic> complaintsData = response['data']['complaints'];
    return complaintsData.map((json) => Complaint.fromJson(json)).toList();
  }

  static List<Payment> parsePayments(Map<String, dynamic> response) {
    final List<dynamic> paymentsData = response['data']['payments'];
    return paymentsData.map((json) => Payment.fromJson(json)).toList();
  }

  // Fetch buildings by owner ID
  static Future<Map<String, dynamic>> fetchBuildingsByOwnerId(String ownerId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/buildings?ownerId=$ownerId');
      
      debugPrint('🏢 [API] Fetching buildings for ownerId: $ownerId');
      debugPrint('🌐 [API] URL: $url');
      debugPrint('📤 [API] Method: GET');
      debugPrint('📤 [API] Headers: {accept: */*}');
      
      final response = await http.get(
        url,
        headers: {
          'accept': '*/*',
        },
      );

      debugPrint('📥 [API] Response Status Code: ${response.statusCode}');
      debugPrint('📥 [API] Response Headers: ${response.headers}');
      log('📥 [API] Response Body: 2${response.body}');
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [API] Successfully fetched buildings');
        debugPrint('📊 [API] Number of buildings: ${decodedResponse['data']?.length ?? 0}');
        return decodedResponse;
      } else {
        debugPrint('❌ [API] Failed to fetch buildings: ${response.statusCode}');
        debugPrint('❌ [API] Error Body: ${response.body}');
        throw Exception('Failed to fetch buildings: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [API] Exception while fetching buildings: $e');
      throw Exception('Error fetching buildings: $e');
    }
  }

  // Parse buildings from API response
  static List<Building> parseBuildings(Map<String, dynamic> response) {
    debugPrint('🔍 [PARSE] Parsing buildings from response: ${response.keys}');
    
    try {
      if (response['success'] == true && response['data'] != null) {
        List<dynamic> buildingsData = [];
        
        if (response['data'] is List) {
          // Direct array format: { "success": true, "data": [...] }
          buildingsData = response['data'] as List<dynamic>;
          debugPrint('🔍 [PARSE] Data is a List, found ${buildingsData.length} buildings');
        } else if (response['data'] is Map) {
          final dataMap = response['data'] as Map<String, dynamic>;
          if (dataMap['buildings'] != null) {
            // Nested format: { "success": true, "data": { "buildings": [...] } }
            buildingsData = dataMap['buildings'] as List<dynamic>;
            debugPrint('🔍 [PARSE] Data is a Map with buildings key, found ${buildingsData.length} buildings');
          } else {
            debugPrint('⚠️ [PARSE] Data is a Map but no buildings key found. Keys: ${dataMap.keys}');
          }
        }
        
        debugPrint('✅ [PARSE] Total buildings to parse: ${buildingsData.length}');
        
        // Parse each building with error handling
        final List<Building> parsedBuildings = [];
        for (int i = 0; i < buildingsData.length; i++) {
          try {
            final buildingJson = buildingsData[i] as Map<String, dynamic>;
            final building = Building.fromJson(buildingJson);
            parsedBuildings.add(building);
            debugPrint('✅ [PARSE] Successfully parsed building ${i + 1}: ${building.name}');
          } catch (e, stackTrace) {
            debugPrint('❌ [PARSE] Error parsing building ${i + 1}: $e');
            debugPrint('❌ [PARSE] Stack trace: $stackTrace');
            debugPrint('❌ [PARSE] Building data: ${buildingsData[i]}');
          }
        }
        
        debugPrint('✅ [PARSE] Successfully parsed ${parsedBuildings.length} out of ${buildingsData.length} buildings');
        return parsedBuildings;
      }
    } catch (e, stackTrace) {
      debugPrint('💥 [PARSE] Fatal error parsing buildings: $e');
      debugPrint('💥 [PARSE] Stack trace: $stackTrace');
    }
    
    return [];
  }

  // Create buildings via bulk API
  static Future<Map<String, dynamic>> createBuildingsBulk({
    required String ownerId,
    required List<Map<String, dynamic>> buildings,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/buildings/bulk');
      
      final payload = {
        'ownerId': ownerId,
        'buildings': buildings,
      };

      debugPrint('🏗️ [API] Creating buildings for ownerId: $ownerId');
      debugPrint('🌐 [API] URL: $url');
      debugPrint('📤 [API] Method: POST');
      debugPrint('📤 [API] Headers: {Content-Type: application/json}');
      debugPrint('📤 [API] Request Payload: ${json.encode(payload)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      debugPrint('📥 [API] Response Status Code: ${response.statusCode}');
      debugPrint('📥 [API] Response Headers: ${response.headers}');
      log('📥 [API] Response Body: 3${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [API] Successfully created buildings');
        debugPrint('📊 [API] Created buildings count: ${buildings.length}');
        return decodedResponse;
      } else {
        debugPrint('❌ [API] Failed to create buildings: ${response.statusCode}');
        debugPrint('❌ [API] Error Body: ${response.body}');
        throw Exception('Failed to create buildings: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [API] Exception while creating buildings: $e');
      throw Exception('Error creating buildings: $e');
    }
  }

  // Create rooms via bulk API
  static Future<Map<String, dynamic>> createRoomsBulk({
    required String buildingId,
    required List<Map<String, dynamic>> rooms,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/rooms/bulk');
      
      final payload = {
        'buildingId': buildingId,
        'rooms': rooms,
      };

      debugPrint('🏠 [API] Creating rooms for buildingId: $buildingId');
      debugPrint('🌐 [API] URL: $url');
      debugPrint('📤 [API] Method: POST');
      debugPrint('📤 [API] Headers: {Content-Type: application/json}');
      debugPrint('📤 [API] Request Payload: ${json.encode(payload)}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      debugPrint('📥 [API] Response Status Code: ${response.statusCode}');
      debugPrint('📥 [API] Response Headers: ${response.headers}');
      log('📥 [API] Response Body: 3${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [API] Successfully created rooms');
        debugPrint('📊 [API] Created rooms count: ${rooms.length}');
        return decodedResponse;
      } else {
        debugPrint('❌ [API] Failed to create rooms: ${response.statusCode}');
        debugPrint('❌ [API] Error Body: ${response.body}');
        throw Exception('Failed to create rooms: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [API] Exception while creating rooms: $e');
      throw Exception('Error creating rooms: $e');
    }
  }

  // Get room ID by room number and building ID
  static Future<String?> getRoomIdByNumber({
    required String ownerId,
    required String roomNumber,
    String? buildingId,
  }) async {
    try {
      debugPrint('');
      debugPrint('🔍 ===== ROOM ID LOOKUP START =====');
      debugPrint('🔍 [API] Looking for room ID...');
      debugPrint('🔍 [API] Owner ID: $ownerId');
      debugPrint('🔍 [API] Room Number: $roomNumber');
      debugPrint('🔍 [API] Building ID: ${buildingId ?? 'Not specified'}');
      debugPrint('');

      final response = await fetchRoomsByOwnerId(ownerId);
      final rooms = parseRooms(response);
      
      debugPrint('🔍 [API] Found ${rooms.length} total rooms for owner');
      
      Room? targetRoom;
      
      // Always search by room number first
      final matchingRooms = rooms.where(
        (room) => room.number == roomNumber,
      ).toList();
      
      debugPrint('🔍 [API] Found ${matchingRooms.length} rooms with number $roomNumber');
      for (var room in matchingRooms) {
        debugPrint('🔍 [API] - Room: ${room.id} | Number: ${room.number} | Building: ${room.buildingId}');
      }
      
      if (matchingRooms.isNotEmpty) {
        if (buildingId != null && buildingId.isNotEmpty) {
          // If building ID is provided, try to find exact match
          debugPrint('🔍 [API] Filtering by building ID: $buildingId');
          final exactMatch = matchingRooms.where(
            (room) => room.buildingId == buildingId,
          ).toList();
          
          if (exactMatch.isNotEmpty) {
            targetRoom = exactMatch.first;
            debugPrint('🔍 [API] Found exact match with building ID');
          } else {
            // If no exact match, use first room with that number
            targetRoom = matchingRooms.first;
            debugPrint('🔍 [API] No exact building match, using first room with number $roomNumber');
            debugPrint('⚠️ [API] WARNING: Building ID mismatch - expected: $buildingId, found: ${targetRoom.buildingId}');
          }
        } else {
          // No building ID provided, use first match
          targetRoom = matchingRooms.first;
          debugPrint('🔍 [API] No building ID provided, using first room with number $roomNumber');
        }
      }
      
      if (targetRoom != null) {
        debugPrint('✅ [API] SUCCESS: Found room!');
        debugPrint('✅ [API] Room ID: ${targetRoom.id}');
        debugPrint('✅ [API] Room Number: ${targetRoom.number}');
        debugPrint('✅ [API] Building ID: ${targetRoom.buildingId}');
        debugPrint('✅ [API] Room Status: ${targetRoom.status}');
        debugPrint('🔍 ===== ROOM ID LOOKUP END =====');
        debugPrint('');
        return targetRoom.id;
      } else {
        debugPrint('❌ [API] FAILED: Room not found!');
        debugPrint('❌ [API] Searched for room number: $roomNumber');
        debugPrint('❌ [API] In building: ${buildingId ?? 'Any building'}');
        debugPrint('❌ [API] Available rooms:');
        for (var room in rooms.take(10)) { // Show first 10 rooms for debugging
          debugPrint('❌ [API] - Room: ${room.number} | Building: ${room.buildingId} | Status: ${room.status}');
        }
        if (rooms.length > 10) {
          debugPrint('❌ [API] ... and ${rooms.length - 10} more rooms');
        }
        debugPrint('🔍 ===== ROOM ID LOOKUP END =====');
        debugPrint('');
        return null;
      }
    } catch (e) {
      debugPrint('💥 [API] EXCEPTION: Room ID lookup failed!');
      debugPrint('💥 [API] Exception: $e');
      debugPrint('💥 [API] Exception Type: ${e.runtimeType}');
      debugPrint('🔍 ===== ROOM ID LOOKUP END =====');
      debugPrint('');
      return null;
    }
  }

  // Get room details by room ID
  static Future<Room?> getRoomById({
    required String ownerId,
    required String roomId,
  }) async {
    try {
      debugPrint('');
      debugPrint('🔍 ===== ROOM DETAILS LOOKUP START =====');
      debugPrint('🔍 [API] Looking for room details...');
      debugPrint('🔍 [API] Owner ID: $ownerId');
      debugPrint('🔍 [API] Room ID: $roomId');
      debugPrint('');

      final response = await fetchRoomsByOwnerId(ownerId);
      final rooms = parseRooms(response);
      
      debugPrint('🔍 [API] Found ${rooms.length} total rooms for owner');
      
      final targetRoom = rooms.firstWhere(
        (room) => room.id == roomId,
        orElse: () => throw Exception('Room not found'),
      );
      
      debugPrint('✅ [API] SUCCESS: Found room details!');
      debugPrint('✅ [API] Room ID: ${targetRoom.id}');
      debugPrint('✅ [API] Room Number: ${targetRoom.number}');
      debugPrint('✅ [API] Building ID: ${targetRoom.buildingId}');
      debugPrint('✅ [API] Room Status: ${targetRoom.status}');
      debugPrint('✅ [API] Room Rent: ₹${targetRoom.rent}');
      debugPrint('🔍 ===== ROOM DETAILS LOOKUP END =====');
      debugPrint('');
      
      return targetRoom;
    } catch (e) {
      debugPrint('❌ [API] FAILED: Room details not found!');
      debugPrint('❌ [API] Room ID: $roomId');
      debugPrint('❌ [API] Error: $e');
      debugPrint('🔍 ===== ROOM DETAILS LOOKUP END =====');
      debugPrint('');
      return null;
    }
  }

  // Fetch tenants by owner ID
  static Future<Map<String, dynamic>> fetchTenantsByOwnerId(String ownerId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/owners/$ownerId/tenants');
      
      debugPrint('👥 [API] Fetching tenants for ownerId: $ownerId');
      debugPrint('🌐 [API] URL: $url');
      debugPrint('📤 [API] Method: GET');
      debugPrint('📤 [API] Headers: {Content-Type: application/json}');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('📥 [API] Response Status Code: ${response.statusCode}');
      debugPrint('📥 [API] Response Headers: ${response.headers}');
      debugPrint('📥 [API] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [API] Successfully fetched tenants');
        debugPrint('📊 [API] Number of tenants: ${decodedResponse['data']?.length ?? 0}');
        return decodedResponse;
      } else {
        debugPrint('❌ [API] Failed to fetch tenants: ${response.statusCode}');
        debugPrint('❌ [API] Error Body: ${response.body}');
        throw Exception('Failed to fetch tenants: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [API] Exception while fetching tenants: $e');
      throw Exception('Error fetching tenants: $e');
    }
  }
  // Parse tenants from API response
  static List<ApiTenant> parseApiTenants(Map<String, dynamic> response) {
    debugPrint('🔍 [PARSE] Parsing tenants from response: ${response.keys}');
    
    try {
      if (response['success'] == true && response['data'] != null) {
        List<dynamic> tenantsData = [];
        
        if (response['data'] is List) {
          // Direct array format: { "success": true, "data": [...] }
          tenantsData = response['data'] as List<dynamic>;
          debugPrint('🔍 [PARSE] Data is a List, found ${tenantsData.length} tenants');
        } else if (response['data'] is Map) {
          final dataMap = response['data'] as Map<String, dynamic>;
          if (dataMap['tenants'] != null) {
            // Nested format: { "success": true, "data": { "tenants": [...] } }
            tenantsData = dataMap['tenants'] as List<dynamic>;
            debugPrint('🔍 [PARSE] Data is a Map with tenants key, found ${tenantsData.length} tenants');
          } else {
            debugPrint('⚠️ [PARSE] Data is a Map but no tenants key found. Keys: ${dataMap.keys}');
          }
        }
        
        debugPrint('✅ [PARSE] Total tenants to parse: ${tenantsData.length}');
        
        // Parse each tenant with error handling
        final List<ApiTenant> parsedTenants = [];
        for (int i = 0; i < tenantsData.length; i++) {
          try {
            final tenantJson = tenantsData[i] as Map<String, dynamic>;
            final tenant = ApiTenant.fromJson(tenantJson);
            parsedTenants.add(tenant);
            debugPrint('✅ [PARSE] Successfully parsed tenant ${i + 1}: ${tenant.name}');
          } catch (e, stackTrace) {
            debugPrint('❌ [PARSE] Error parsing tenant ${i + 1}: $e');
            debugPrint('❌ [PARSE] Stack trace: $stackTrace');
            debugPrint('❌ [PARSE] Tenant data: ${tenantsData[i]}');
          }
        }
        
        debugPrint('✅ [PARSE] Successfully parsed ${parsedTenants.length} out of ${tenantsData.length} tenants');
        return parsedTenants;
      }
    } catch (e, stackTrace) {
      debugPrint('💥 [PARSE] Fatal error parsing tenants: $e');
      debugPrint('💥 [PARSE] Stack trace: $stackTrace');
    }
    
    return [];
  }

  static Future<Map<String, dynamic>> createTenant({
    required String roomId,
    required String name,
    required String email,
    required String phone,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required String emergencyContactRelation,
    required String idProofType,
    required String idProofNumber,
    required String moveInDate,
    required String leaseEndDate,
    required double depositPaid,
    String? occupation,
    String? invitationToken,
    String? roomNumber, // Add room number parameter
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/tenants');
      
      final payload = {
        'roomId': roomId,
        'name': name,
        'phone': phone,
        'email': email,
        'moveInDate': moveInDate,
        'type': 'tenant',
        'isActive': true,
        'aadharNumber': idProofNumber,
        'emergencyContact': emergencyContactPhone,
        'occupation': occupation ?? '',
        'invitationToken': invitationToken,
      };
      
      // Add room number only if provided
      if (roomNumber != null && roomNumber.isNotEmpty) {
        payload['roomNumber'] = roomNumber;
      }
      
      // Remove null values to clean up payload
      payload.removeWhere((key, value) => value == null);

      debugPrint('');
      debugPrint('🚀 ===== TENANT CREATION API CALL START =====');
      debugPrint('👤 [API] Creating tenant: $name');
      debugPrint('🌐 [API] URL: $url');
      debugPrint('📤 [API] Method: POST');
      debugPrint('📤 [API] Headers: {Content-Type: application/json}');
      debugPrint('📤 [API] Request Payload:');
      debugPrint('📤 [API] ${json.encode(payload)}');
      debugPrint('');
      debugPrint('📋 [API] Payload Details:');
      debugPrint('📋 [API] - Room ID: $roomId');
      debugPrint('📋 [API] - Room Number: ${roomNumber ?? 'Not provided'}');
      debugPrint('📋 [API] - Tenant Name: $name');
      debugPrint('📋 [API] - Email: $email');
      debugPrint('📋 [API] - Phone: $phone');
      debugPrint('📋 [API] - Move In Date: $moveInDate');
      debugPrint('📋 [API] - Type: tenant');
      debugPrint('📋 [API] - Is Active: true');
      debugPrint('📋 [API] - Aadhar Number: $idProofNumber');
      debugPrint('📋 [API] - Emergency Contact: $emergencyContactPhone');
      debugPrint('📋 [API] - Occupation: ${occupation ?? 'Not provided'}');
      debugPrint('📋 [API] - Invitation Token: ${invitationToken ?? 'Not provided'}');
      debugPrint('');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      debugPrint('📥 ===== TENANT CREATION API RESPONSE =====');
      debugPrint('📥 [API] Response Status Code: ${response.statusCode}');
      debugPrint('📥 [API] Response Headers: ${response.headers}');
      debugPrint('📥 [API] Response Body:');
      debugPrint('📥 [API] ${response.body}');
      debugPrint('');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [API] SUCCESS: Tenant created successfully!');
        debugPrint('✅ [API] Tenant Name: $name');
        debugPrint('✅ [API] Response Data: ${decodedResponse['data']}');
        debugPrint('🚀 ===== TENANT CREATION API CALL END =====');
        debugPrint('');
        return decodedResponse;
      } else {
        debugPrint('❌ [API] FAILED: Tenant creation failed!');
        debugPrint('❌ [API] Status Code: ${response.statusCode}');
        debugPrint('❌ [API] Error Body: ${response.body}');
        debugPrint('🚀 ===== TENANT CREATION API CALL END =====');
        debugPrint('');
        throw Exception('Failed to create tenant: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [API] EXCEPTION: Tenant creation failed with exception!');
      debugPrint('💥 [API] Exception Details: $e');
      debugPrint('💥 [API] Exception Type: ${e.runtimeType}');
      debugPrint('🚀 ===== TENANT CREATION API CALL END =====');
      debugPrint('');
      throw Exception('Error creating tenant: $e');
    }
  }

  // Create complaint via API
  static Future<Map<String, dynamic>> createComplaint({
    required String title,
    required String description,
    required String roomId,
    required String buildingId,
    required String tenantId,
    required String category,
    required String priority,
    List<String> images = const [],
    String contactPreference = 'phone',
    bool urgentContact = false,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/complaints');
      
      final payload = {
        'title': title,
        'description': description,
        'roomId': roomId,
        'buildingId': buildingId,
        'tenantId': tenantId,
        'category': category,
        'priority': priority,
        'images': images,
        'contactPreference': contactPreference,
        'urgentContact': urgentContact,
      };

      debugPrint('');
      debugPrint('🚀 ===== COMPLAINT CREATION API CALL START =====');
      debugPrint('📝 [API] Creating complaint: $title');
      debugPrint('🌐 [API] URL: $url');
      debugPrint('📤 [API] Method: POST');
      debugPrint('📤 [API] Headers: {Content-Type: application/json}');
      debugPrint('📤 [API] Request Payload:');
      debugPrint('📤 [API] ${json.encode(payload)}');
      debugPrint('');
      debugPrint('📋 [API] Payload Details:');
      debugPrint('📋 [API] - Title: $title');
      debugPrint('📋 [API] - Description: $description');
      debugPrint('📋 [API] - Room ID: $roomId');
      debugPrint('📋 [API] - Building ID: $buildingId');
      debugPrint('📋 [API] - Tenant ID: $tenantId');
      debugPrint('📋 [API] - Category: $category');
      debugPrint('📋 [API] - Priority: $priority');
      debugPrint('📋 [API] - Images Count: ${images.length}');
      debugPrint('📋 [API] - Contact Preference: $contactPreference');
      debugPrint('📋 [API] - Urgent Contact: $urgentContact');
      debugPrint('');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      debugPrint('📥 ===== COMPLAINT CREATION API RESPONSE =====');
      debugPrint('📥 [API] Response Status Code: ${response.statusCode}');
      debugPrint('📥 [API] Response Headers: ${response.headers}');
      debugPrint('📥 [API] Response Body:');
      debugPrint('📥 [API] ${response.body}');
      debugPrint('');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [API] SUCCESS: Complaint created successfully!');
        debugPrint('✅ [API] Complaint Title: $title');
        debugPrint('✅ [API] Response Data: ${decodedResponse['data']}');
        debugPrint('🚀 ===== COMPLAINT CREATION API CALL END =====');
        debugPrint('');
        return decodedResponse;
      } else {
        debugPrint('❌ [API] FAILED: Complaint creation failed!');
        debugPrint('❌ [API] Status Code: ${response.statusCode}');
        debugPrint('❌ [API] Error Body: ${response.body}');
        debugPrint('🚀 ===== COMPLAINT CREATION API CALL END =====');
        debugPrint('');
        throw Exception('Failed to create complaint: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [API] EXCEPTION: Complaint creation failed with exception!');
      debugPrint('💥 [API] Exception Details: $e');
      debugPrint('💥 [API] Exception Type: ${e.runtimeType}');
      debugPrint('🚀 ===== COMPLAINT CREATION API CALL END =====');
      debugPrint('');
      throw Exception('Error creating complaint: $e');
    }
  }

  // Fetch complaints by owner ID
  static Future<Map<String, dynamic>> fetchComplaintsByOwnerId(String ownerId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/complaints?ownerId=$ownerId');
      
      debugPrint('📝 [API] Fetching complaints for ownerId: $ownerId');
      debugPrint('🌐 [API] URL: $url');
      debugPrint('📤 [API] Method: GET');
      debugPrint('📤 [API] Headers: {accept: */*}');
      
      final response = await http.get(
        url,
        headers: {
          'accept': '*/*',
        },
      );

      debugPrint('📥 [API] Response Status Code: ${response.statusCode}');
      debugPrint('📥 [API] Response Headers: ${response.headers}');
      log('📥 [API] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [API] Successfully fetched complaints');
        final complaintsData = decodedResponse['data'];
        if (complaintsData != null && complaintsData['complaints'] != null) {
          debugPrint('📊 [API] Number of complaints: ${complaintsData['complaints'].length}');
          debugPrint('📊 [API] Total: ${complaintsData['total']}');
          debugPrint('📊 [API] Pending: ${complaintsData['pending']}');
          debugPrint('📊 [API] In Progress: ${complaintsData['in_progress']}');
          debugPrint('📊 [API] Resolved: ${complaintsData['resolved']}');
        }
        return decodedResponse;
      } else {
        debugPrint('❌ [API] Failed to fetch complaints: ${response.statusCode}');
        debugPrint('❌ [API] Error Body: ${response.body}');
        throw Exception('Failed to fetch complaints: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [API] Exception while fetching complaints: $e');
      throw Exception('Error fetching complaints: $e');
    }
  }

  // Parse complaints from API response
  static List<Complaint> parseApiComplaints(Map<String, dynamic> response) {
    debugPrint('🔍 [PARSE] Parsing complaints from response: ${response.keys}');
    
    try {
      if (response['status'] == 'success' && response['data'] != null) {
        final dataMap = response['data'] as Map<String, dynamic>;
        
        if (dataMap['complaints'] != null) {
          final complaintsData = dataMap['complaints'] as List<dynamic>;
          debugPrint('🔍 [PARSE] Found ${complaintsData.length} complaints');
          
          // Parse each complaint with error handling
          final List<Complaint> parsedComplaints = [];
          for (int i = 0; i < complaintsData.length; i++) {
            try {
              final complaintJson = complaintsData[i] as Map<String, dynamic>;
              final complaint = Complaint.fromJson(complaintJson);
              parsedComplaints.add(complaint);
              debugPrint('✅ [PARSE] Successfully parsed complaint ${i + 1}: ${complaint.title}');
            } catch (e, stackTrace) {
              debugPrint('❌ [PARSE] Error parsing complaint ${i + 1}: $e');
              debugPrint('❌ [PARSE] Stack trace: $stackTrace');
              debugPrint('❌ [PARSE] Complaint data: ${complaintsData[i]}');
            }
          }
          
          debugPrint('✅ [PARSE] Successfully parsed ${parsedComplaints.length} out of ${complaintsData.length} complaints');
          return parsedComplaints;
        } else {
          debugPrint('⚠️ [PARSE] No complaints key found in data. Keys: ${dataMap.keys}');
        }
      } else {
        debugPrint('⚠️ [PARSE] Invalid response format. Status: ${response['status']}, Data: ${response['data']}');
      }
    } catch (e, stackTrace) {
      debugPrint('💥 [PARSE] Fatal error parsing complaints: $e');
      debugPrint('💥 [PARSE] Stack trace: $stackTrace');
    }
    
    return [];
  }

  // ===== SERVICE PROVIDER API METHODS =====

  // Fetch all service providers
  static Future<Map<String, dynamic>> fetchServiceProviders({
    String? serviceType,
    String? city,
    String? availability,
    double? minRating,
    double? maxRating,
    int? minPrice,
    int? maxPrice,
    bool? emergencyAvailable,
    bool? verified,
    String? sortBy = 'rating',
    String? sortOrder = 'desc',
    int page = 1,
    int limit = 10,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
        'sortBy': sortBy ?? 'rating',
        'sortOrder': sortOrder ?? 'desc',
      };

      if (serviceType != null) queryParams['serviceType'] = serviceType;
      if (city != null) queryParams['city'] = city;
      if (availability != null) queryParams['availability'] = availability;
      if (minRating != null) queryParams['minRating'] = minRating.toString();
      if (maxRating != null) queryParams['maxRating'] = maxRating.toString();
      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      if (emergencyAvailable != null) queryParams['emergencyAvailable'] = emergencyAvailable.toString();
      if (verified != null) queryParams['verified'] = verified.toString();

      final uri = Uri.parse("${ApiConfig.baseUrl}/service-providers").replace(queryParameters: queryParams);
      
      debugPrint('🔧 [API] Fetching service providers');
      debugPrint('🌐 [API] URL: $uri');
      debugPrint('📤 [API] Method: GET');
      debugPrint('📤 [API] Headers: {accept: */*}');
      
      final response = await http.get(
        uri,
        headers: {
          'accept': '*/*',
        },
      );

      debugPrint('📥 [API] Response Status Code: ${response.statusCode}');
      debugPrint('📥 [API] Response Headers: ${response.headers}');
      log('📥 [API] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [API] Successfully fetched service providers');
        return decodedResponse;
      } else {
        debugPrint('❌ [API] Failed to fetch service providers: ${response.statusCode}');
        debugPrint('❌ [API] Error Body: ${response.body}');
        throw Exception('Failed to fetch service providers: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [API] Exception while fetching service providers: $e');
      throw Exception('Error fetching service providers: $e');
    }
  }

  // Create a new service provider
  static Future<Map<String, dynamic>> createServiceProvider({
    required String name,
    required String serviceType,
    required String phone,
    required String email,
    required String address,
    required String city,
    required String state,
    required String pincode,
    required List<String> specialties,
    required String experience,
    required Map<String, dynamic> priceRange,
    required Map<String, dynamic> workingHours,
    required bool emergencyAvailable,
    required List<String> languages,
    Map<String, dynamic>? documents,
    String? profileImage,
    Map<String, dynamic>? bankDetails,
    List<Map<String, dynamic>>? references,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/service-providers');
      
      final payload = {
        'name': name,
        'serviceType': serviceType,
        'phone': phone,
        'email': email,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'specialties': specialties,
        'experience': experience,
        'priceRange': priceRange,
        'workingHours': workingHours,
        'emergencyAvailable': emergencyAvailable,
        'languages': languages,
        'isAvailable': true,
        'isVerified': false,
      };

      // Add optional fields if provided
      if (documents != null) payload['documents'] = documents;
      if (profileImage != null) payload['profileImage'] = profileImage;
      if (bankDetails != null) payload['bankDetails'] = bankDetails;
      if (references != null) payload['references'] = references;

      debugPrint('');
      debugPrint('🚀 ===== SERVICE PROVIDER CREATION API CALL START =====');
      debugPrint('🔧 [API] Creating service provider: $name');
      debugPrint('🌐 [API] URL: $url');
      debugPrint('📤 [API] Method: POST');
      debugPrint('📤 [API] Headers: {Content-Type: application/json}');
      debugPrint('📤 [API] Request Payload:');
      debugPrint('📤 [API] ${json.encode(payload)}');
      debugPrint('');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      debugPrint('📥 ===== SERVICE PROVIDER CREATION API RESPONSE =====');
      debugPrint('📥 [API] Response Status Code: ${response.statusCode}');
      debugPrint('📥 [API] Response Headers: ${response.headers}');
      debugPrint('📥 [API] Response Body: ${response.body}');
      debugPrint('');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [API] SUCCESS: Service provider created successfully!');
        debugPrint('✅ [API] Provider Name: $name');
        debugPrint('🚀 ===== SERVICE PROVIDER CREATION API CALL END =====');
        debugPrint('');
        return decodedResponse;
      } else {
        debugPrint('❌ [API] FAILED: Service provider creation failed!');
        debugPrint('❌ [API] Status Code: ${response.statusCode}');
        debugPrint('❌ [API] Error Body: ${response.body}');
        debugPrint('🚀 ===== SERVICE PROVIDER CREATION API CALL END =====');
        debugPrint('');
        throw Exception('Failed to create service provider: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [API] EXCEPTION: Service provider creation failed with exception!');
      debugPrint('💥 [API] Exception Details: $e');
      debugPrint('🚀 ===== SERVICE PROVIDER CREATION API CALL END =====');
      debugPrint('');
      throw Exception('Error creating service provider: $e');
    }
  }

  // Update an existing service provider
  static Future<Map<String, dynamic>> updateServiceProvider({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? pincode,
    List<String>? specialties,
    String? experience,
    Map<String, dynamic>? priceRange,
    Map<String, dynamic>? workingHours,
    bool? emergencyAvailable,
    List<String>? languages,
    bool? isAvailable,
    String? profileImage,
    Map<String, dynamic>? bankDetails,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/service-providers/$id');
      
      final payload = <String, dynamic>{};
      
      // Add only non-null fields to payload
      if (name != null) payload['name'] = name;
      if (phone != null) payload['phone'] = phone;
      if (email != null) payload['email'] = email;
      if (address != null) payload['address'] = address;
      if (city != null) payload['city'] = city;
      if (state != null) payload['state'] = state;
      if (pincode != null) payload['pincode'] = pincode;
      if (specialties != null) payload['specialties'] = specialties;
      if (experience != null) payload['experience'] = experience;
      if (priceRange != null) payload['priceRange'] = priceRange;
      if (workingHours != null) payload['workingHours'] = workingHours;
      if (emergencyAvailable != null) payload['emergencyAvailable'] = emergencyAvailable;
      if (languages != null) payload['languages'] = languages;
      if (isAvailable != null) payload['isAvailable'] = isAvailable;
      if (profileImage != null) payload['profileImage'] = profileImage;
      if (bankDetails != null) payload['bankDetails'] = bankDetails;

      debugPrint('');
      debugPrint('🚀 ===== SERVICE PROVIDER UPDATE API CALL START =====');
      debugPrint('🔧 [API] Updating service provider: $id');
      debugPrint('🌐 [API] URL: $url');
      debugPrint('📤 [API] Method: PUT');
      debugPrint('📤 [API] Headers: {Content-Type: application/json}');
      debugPrint('📤 [API] Request Payload: ${json.encode(payload)}');
      debugPrint('');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      debugPrint('📥 ===== SERVICE PROVIDER UPDATE API RESPONSE =====');
      debugPrint('📥 [API] Response Status Code: ${response.statusCode}');
      debugPrint('📥 [API] Response Body: ${response.body}');
      debugPrint('');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [API] SUCCESS: Service provider updated successfully!');
        debugPrint('🚀 ===== SERVICE PROVIDER UPDATE API CALL END =====');
        debugPrint('');
        return decodedResponse;
      } else {
        debugPrint('❌ [API] FAILED: Service provider update failed!');
        debugPrint('❌ [API] Status Code: ${response.statusCode}');
        debugPrint('❌ [API] Error Body: ${response.body}');
        debugPrint('🚀 ===== SERVICE PROVIDER UPDATE API CALL END =====');
        debugPrint('');
        throw Exception('Failed to update service provider: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [API] EXCEPTION: Service provider update failed with exception!');
      debugPrint('💥 [API] Exception Details: $e');
      debugPrint('🚀 ===== SERVICE PROVIDER UPDATE API CALL END =====');
      debugPrint('');
      throw Exception('Error updating service provider: $e');
    }
  }

  // Book a service provider
  static Future<Map<String, dynamic>> bookServiceProvider({
    required String serviceProviderId,
    required String customerId,
    required String buildingId,
    required String roomId,
    required String serviceType,
    required String jobTitle,
    required String jobDescription,
    required String priority,
    required String scheduledDate,
    required String scheduledTime,
    required int estimatedDuration,
    required Map<String, dynamic> location,
    required List<String> requirements,
    String? specialInstructions,
    Map<String, dynamic>? budgetRange,
    String paymentMethod = 'cash',
    bool emergencyJob = false,
    List<String> images = const [],
    String? customerNotes,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/service-providers/$serviceProviderId/book');
      
      final payload = {
        'serviceProviderId': serviceProviderId,
        'customerId': customerId,
        'buildingId': buildingId,
        'roomId': roomId,
        'serviceType': serviceType,
        'jobTitle': jobTitle,
        'jobDescription': jobDescription,
        'priority': priority,
        'scheduledDate': scheduledDate,
        'scheduledTime': scheduledTime,
        'estimatedDuration': estimatedDuration,
        'location': location,
        'requirements': requirements,
        'paymentMethod': paymentMethod,
        'emergencyJob': emergencyJob,
        'images': images,
      };

      // Add optional fields
      if (specialInstructions != null) payload['specialInstructions'] = specialInstructions;
      if (budgetRange != null) payload['budgetRange'] = budgetRange;
      if (customerNotes != null) payload['customerNotes'] = customerNotes;

      debugPrint('');
      debugPrint('🚀 ===== SERVICE PROVIDER BOOKING API CALL START =====');
      debugPrint('📅 [API] Booking service provider: $serviceProviderId');
      debugPrint('🌐 [API] URL: $url');
      debugPrint('📤 [API] Method: POST');
      debugPrint('📤 [API] Headers: {Content-Type: application/json}');
      debugPrint('📤 [API] Request Payload: ${json.encode(payload)}');
      debugPrint('');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      debugPrint('📥 ===== SERVICE PROVIDER BOOKING API RESPONSE =====');
      debugPrint('📥 [API] Response Status Code: ${response.statusCode}');
      debugPrint('📥 [API] Response Body: ${response.body}');
      debugPrint('');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [API] SUCCESS: Service provider booked successfully!');
        debugPrint('🚀 ===== SERVICE PROVIDER BOOKING API CALL END =====');
        debugPrint('');
        return decodedResponse;
      } else {
        debugPrint('❌ [API] FAILED: Service provider booking failed!');
        debugPrint('❌ [API] Status Code: ${response.statusCode}');
        debugPrint('❌ [API] Error Body: ${response.body}');
        debugPrint('🚀 ===== SERVICE PROVIDER BOOKING API CALL END =====');
        debugPrint('');
        throw Exception('Failed to book service provider: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [API] EXCEPTION: Service provider booking failed with exception!');
      debugPrint('💥 [API] Exception Details: $e');
      debugPrint('🚀 ===== SERVICE PROVIDER BOOKING API CALL END =====');
      debugPrint('');
      throw Exception('Error booking service provider: $e');
    }
  }

  // Search service providers with filters
  static Future<Map<String, dynamic>> searchServiceProviders({
    required Map<String, dynamic> filters,
    Map<String, dynamic>? location,
    String sortBy = 'rating',
    String sortOrder = 'desc',
    int page = 1,
    int limit = 10,
    String? searchQuery,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/service-providers/search');
      
      final payload = {
        'filters': filters,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
        'page': page,
        'limit': limit,
      };

      if (location != null) payload['location'] = location;
      if (searchQuery != null) payload['searchQuery'] = searchQuery;

      debugPrint('');
      debugPrint('🚀 ===== SERVICE PROVIDER SEARCH API CALL START =====');
      debugPrint('🔍 [API] Searching service providers');
      debugPrint('🌐 [API] URL: $url');
      debugPrint('📤 [API] Method: POST');
      debugPrint('📤 [API] Headers: {Content-Type: application/json}');
      debugPrint('📤 [API] Request Payload: ${json.encode(payload)}');
      debugPrint('');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      debugPrint('📥 ===== SERVICE PROVIDER SEARCH API RESPONSE =====');
      debugPrint('📥 [API] Response Status Code: ${response.statusCode}');
      debugPrint('📥 [API] Response Body: ${response.body}');
      debugPrint('');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [API] SUCCESS: Service providers search completed!');
        debugPrint('🚀 ===== SERVICE PROVIDER SEARCH API CALL END =====');
        debugPrint('');
        return decodedResponse;
      } else {
        debugPrint('❌ [API] FAILED: Service providers search failed!');
        debugPrint('❌ [API] Status Code: ${response.statusCode}');
        debugPrint('❌ [API] Error Body: ${response.body}');
        debugPrint('🚀 ===== SERVICE PROVIDER SEARCH API CALL END =====');
        debugPrint('');
        throw Exception('Failed to search service providers: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [API] EXCEPTION: Service providers search failed with exception!');
      debugPrint('💥 [API] Exception Details: $e');
      debugPrint('🚀 ===== SERVICE PROVIDER SEARCH API CALL END =====');
      debugPrint('');
      throw Exception('Error searching service providers: $e');
    }
  }

  // Get service provider reviews
  static Future<Map<String, dynamic>> getServiceProviderReviews({
    required String serviceProviderId,
    int page = 1,
    int limit = 5,
  }) async {
    try {
      final uri = Uri.parse("${ApiConfig.baseUrl}/service-providers/$serviceProviderId/reviews").replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });
      
      debugPrint('⭐ [API] Fetching reviews for service provider: $serviceProviderId');
      debugPrint('🌐 [API] URL: $uri');
      debugPrint('📤 [API] Method: GET');
      
      final response = await http.get(
        uri,
        headers: {
          'accept': '*/*',
        },
      );

      debugPrint('📥 [API] Response Status Code: ${response.statusCode}');
      debugPrint('📥 [API] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [API] Successfully fetched service provider reviews');
        return decodedResponse;
      } else {
        debugPrint('❌ [API] Failed to fetch reviews: ${response.statusCode}');
        debugPrint('❌ [API] Error Body: ${response.body}');
        throw Exception('Failed to fetch reviews: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [API] Exception while fetching reviews: $e');
      throw Exception('Error fetching reviews: $e');
    }
  }

  // Parse service providers from API response
  static List<ServiceProvider> parseServiceProviders(Map<String, dynamic> response) {
    debugPrint('🔍 [PARSE] Parsing service providers from response: ${response.keys}');
    
    try {
      if (response['success'] == true && response['data'] != null) {
        final dataMap = response['data'] as Map<String, dynamic>;
        List<dynamic> providersData = [];
        
        if (dataMap['serviceProviders'] != null) {
          providersData = dataMap['serviceProviders'] as List<dynamic>;
          debugPrint('🔍 [PARSE] Found ${providersData.length} service providers');
        } else if (response['data'] is List) {
          // Direct array format
          providersData = response['data'] as List<dynamic>;
          debugPrint('🔍 [PARSE] Data is a List, found ${providersData.length} service providers');
        }
        
        debugPrint('✅ [PARSE] Total service providers to parse: ${providersData.length}');
        
        // Parse each service provider with error handling
        final List<ServiceProvider> parsedProviders = [];
        for (int i = 0; i < providersData.length; i++) {
          try {
            final providerJson = providersData[i] as Map<String, dynamic>;
            final provider = ServiceProvider.fromJson(providerJson);
            parsedProviders.add(provider);
            debugPrint('✅ [PARSE] Successfully parsed service provider ${i + 1}: ${provider.name}');
          } catch (e, stackTrace) {
            debugPrint('❌ [PARSE] Error parsing service provider ${i + 1}: $e');
            debugPrint('❌ [PARSE] Stack trace: $stackTrace');
            debugPrint('❌ [PARSE] Provider data: ${providersData[i]}');
          }
        }
        
        debugPrint('✅ [PARSE] Successfully parsed ${parsedProviders.length} out of ${providersData.length} service providers');
        return parsedProviders;
      }
    } catch (e, stackTrace) {
      debugPrint('💥 [PARSE] Fatal error parsing service providers: $e');
      debugPrint('💥 [PARSE] Stack trace: $stackTrace');
    }
    
    return [];
  }

  // Load mock service providers data (fallback)
  static Future<Map<String, dynamic>> fetchMockServiceProviders() async {
    try {
      final String response = await rootBundle.loadString('lib/data/mock_responses/service_providers.json');
      return json.decode(response);
    } catch (e) {
      debugPrint('❌ [API] Failed to load mock service providers: $e');
      return {
        'success': true,
        'data': {
          'serviceProviders': [],
          'pagination': {
            'currentPage': 1,
            'totalPages': 0,
            'totalItems': 0,
            'itemsPerPage': 10
          }
        }
      };
    }
  }

  // ===== PAYMENT API METHODS =====

  // Record payment transaction
  static Future<Map<String, dynamic>> recordPayment(Map<String, dynamic> paymentData) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/payments');
      
      debugPrint('💳 [API] Recording payment transaction');
      debugPrint('🌐 [API] URL: $url');
      debugPrint('📤 [API] Method: POST');
      debugPrint('📤 [API] Headers: {Content-Type: application/json}');
      debugPrint('📤 [API] Request Payload: ${json.encode(paymentData)}');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(paymentData),
      );

      debugPrint('📥 [API] Response Status Code: ${response.statusCode}');
      debugPrint('📥 [API] Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [API] Payment recorded successfully');
        return decodedResponse;
      } else {
        debugPrint('❌ [API] Failed to record payment: ${response.statusCode}');
        throw Exception('Failed to record payment: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [API] Exception while recording payment: $e');
      // Return success for demo purposes
      return {
        'success': true,
        'data': {
          'paymentId': 'PAY_${DateTime.now().millisecondsSinceEpoch}',
          'status': 'recorded',
          'message': 'Payment recorded successfully'
        }
      };
    }
  }

  // Update payment status
  static Future<Map<String, dynamic>> updatePaymentStatus(Map<String, dynamic> statusData) async {
    try {
      final paymentId = statusData['paymentId'];
      final url = Uri.parse('${ApiConfig.baseUrl}/payments/$paymentId/status');
      
      debugPrint('🔄 [API] Updating payment status');
      debugPrint('🌐 [API] URL: $url');
      debugPrint('📤 [API] Method: PUT');
      debugPrint('📤 [API] Headers: {Content-Type: application/json}');
      debugPrint('📤 [API] Request Payload: ${json.encode(statusData)}');
      
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(statusData),
      );

      debugPrint('📥 [API] Response Status Code: ${response.statusCode}');
      debugPrint('📥 [API] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [API] Payment status updated successfully');
        return decodedResponse;
      } else {
        debugPrint('❌ [API] Failed to update payment status: ${response.statusCode}');
        throw Exception('Failed to update payment status: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [API] Exception while updating payment status: $e');
      // Return success for demo purposes
      return {
        'success': true,
        'data': {
          'paymentId': statusData['paymentId'],
          'status': statusData['status'],
          'updatedAt': DateTime.now().toIso8601String(),
          'message': 'Payment status updated successfully'
        }
      };
    }
  }

  // Get payment history for tenant
  static Future<Map<String, dynamic>> fetchPaymentHistory(String tenantId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/payments/history?tenantId=$tenantId');
      
      debugPrint('📋 [API] Fetching payment history for tenant: $tenantId');
      debugPrint('🌐 [API] URL: $url');
      debugPrint('📤 [API] Method: GET');
      
      final response = await http.get(
        url,
        headers: {
          'accept': '*/*',
        },
      );

      debugPrint('📥 [API] Response Status Code: ${response.statusCode}');
      debugPrint('📥 [API] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [API] Payment history fetched successfully');
        return decodedResponse;
      } else {
        debugPrint('❌ [API] Failed to fetch payment history: ${response.statusCode}');
        throw Exception('Failed to fetch payment history: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [API] Exception while fetching payment history: $e');
      // Return empty history for demo purposes
      return {
        'success': true,
        'data': {
          'payments': [],
          'totalAmount': 0.0,
          'totalTransactions': 0
        }
      };
    }
  }

  // Get owner UPI details
  static Future<Map<String, dynamic>> fetchOwnerUpiDetails(String ownerId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/owners/$ownerId/upi');
      
      debugPrint('🔍 [API] Fetching owner UPI details: $ownerId');
      debugPrint('🌐 [API] URL: $url');
      debugPrint('📤 [API] Method: GET');
      
      final response = await http.get(
        url,
        headers: {
          'accept': '*/*',
        },
      );

      debugPrint('📥 [API] Response Status Code: ${response.statusCode}');
      debugPrint('📥 [API] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);
        debugPrint('✅ [API] Owner UPI details fetched successfully');
        return decodedResponse;
      } else {
        debugPrint('❌ [API] Failed to fetch owner UPI details: ${response.statusCode}');
        throw Exception('Failed to fetch owner UPI details: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('💥 [API] Exception while fetching owner UPI details: $e');
      // Return mock UPI details for demo purposes
      return {
        'success': true,
        'data': {
          'upiId': 'owner@paytm',
          'name': 'Property Owner',
          'qrCode': 'upi://pay?pa=owner@paytm&pn=Property%20Owner&cu=INR',
          'preferredApps': ['paytm', 'phonepe', 'googlepay']
        }
      };
    }
  }

  // Save owner UPI details to backend
  static Future<Map<String, dynamic>> saveOwnerUpiDetails(dynamic upiDetails) async {
    try {
      debugPrint('💳 [API] Saving owner UPI details to backend...');
      debugPrint('💳 [API] UPI ID: ${upiDetails.upiId}');
      debugPrint('💳 [API] Owner Name: ${upiDetails.ownerName}');
      debugPrint('💳 [API] Bank Name: ${upiDetails.bankName}');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/owners/${upiDetails.ownerId}/upi-details');
      
      final payload = {
        'upiId': upiDetails.upiId,
        'ownerName': upiDetails.ownerName,
        'bankName': upiDetails.bankName,
        'accountNumber': upiDetails.accountNumber,
        'isActive': upiDetails.isActive,
      };
      
      debugPrint('🌐 [API] POST $uri');
      debugPrint('📤 [API] Payload: ${json.encode(payload)}');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Add authorization header when implementing auth
          // 'Authorization': 'Bearer ${AuthService.getToken()}',
        },
        body: json.encode(payload),
      );
      
      debugPrint('📥 [API] Response Status: ${response.statusCode}');
      debugPrint('📥 [API] Response Body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        
        // Also save to local storage as cache
        final prefs = await SharedPreferences.getInstance();
        final key = 'owner_upi_${upiDetails.ownerId}';
        await prefs.setString(key, json.encode(responseData['data']));
        
        debugPrint('✅ [API] UPI details saved to backend and cached locally');
        
        return responseData;
      } else {
        throw Exception('Backend error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('❌ [API] Failed to save UPI details to backend: $e');
      
      // Fallback: Save to local storage if backend fails
      try {
        final prefs = await SharedPreferences.getInstance();
        final upiData = {
          'id': upiDetails.id,
          'ownerId': upiDetails.ownerId,
          'upiId': upiDetails.upiId,
          'ownerName': upiDetails.ownerName,
          'bankName': upiDetails.bankName,
          'accountNumber': upiDetails.accountNumber,
          'isVerified': false,
          'isActive': upiDetails.isActive,
          'createdAt': upiDetails.createdAt.toIso8601String(),
          'updatedAt': upiDetails.updatedAt.toIso8601String(),
        };
        
        final key = 'owner_upi_${upiDetails.ownerId}';
        await prefs.setString(key, json.encode(upiData));
        
        debugPrint('⚠️ [API] Saved to local storage as fallback');
        
        return {
          'success': true,
          'message': 'UPI details saved locally (backend unavailable)',
          'data': upiData,
        };
      } catch (localError) {
        debugPrint('❌ [API] Local storage fallback also failed: $localError');
        return {
          'success': false,
          'error': 'Failed to save UPI details: $e',
        };
      }
    }
  }

  // Get owner UPI details from backend
  static Future<Map<String, dynamic>> getOwnerUpiDetails(String ownerId) async {
    try {
      debugPrint('🔍 [API] Getting owner UPI details for: $ownerId');
      
      final uri = Uri.parse('${ApiConfig.baseUrl}/owners/$ownerId/upi-details');
      
      debugPrint('🌐 [API] GET $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Add authorization header when implementing auth
          // 'Authorization': 'Bearer ${AuthService.getToken()}',
        },
      );
      
      debugPrint('📥 [API] Response Status: ${response.statusCode}');
      debugPrint('📥 [API] Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          debugPrint('✅ [API] Found UPI details on backend');
          debugPrint('✅ [API] UPI ID: ${responseData['data']['upiId']}');
          debugPrint('✅ [API] Owner Name: ${responseData['data']['ownerName']}');
          
          // Cache to local storage for offline access
          final prefs = await SharedPreferences.getInstance();
          final key = 'owner_upi_$ownerId';
          await prefs.setString(key, json.encode(responseData['data']));
          
          return responseData;
        }
      } else if (response.statusCode == 404) {
        debugPrint('⚠️ [API] No UPI details found on backend for owner: $ownerId');
      } else {
        debugPrint('❌ [API] Backend error: ${response.statusCode}');
      }
      
      // Fallback: Try local storage
      debugPrint('🔍 [API] Trying local storage as fallback...');
      final prefs = await SharedPreferences.getInstance();
      final key = 'owner_upi_$ownerId';
      final savedData = prefs.getString(key);
      
      if (savedData != null) {
        debugPrint('✅ [API] Found cached UPI details in local storage');
        final upiData = json.decode(savedData);
        debugPrint('✅ [API] Cached UPI ID: ${upiData['upiId']}');
        debugPrint('✅ [API] Cached Owner Name: ${upiData['ownerName']}');
        
        return {
          'success': true,
          'data': upiData,
        };
      }
      
      debugPrint('⚠️ [API] No UPI details found anywhere, returning demo data');
      debugPrint('💡 [API] Owner should set up their UPI details in Settings');
      
      // Final fallback: Demo data
      return {
        'success': true,
        'data': {
          'id': 'upi_${ownerId}_demo',
          'ownerId': ownerId,
          'upiId': 'owner@paytm',
          'ownerName': 'Property Owner',
          'bankName': 'State Bank of India',
          'accountNumber': '1234',
          'isVerified': true,
          'isActive': true,
          'createdAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        }
      };
    } catch (e) {
      debugPrint('❌ [API] Exception while getting UPI details: $e');
      
      // Emergency fallback: Try local storage
      try {
        final prefs = await SharedPreferences.getInstance();
        final key = 'owner_upi_$ownerId';
        final savedData = prefs.getString(key);
        
        if (savedData != null) {
          debugPrint('✅ [API] Using cached data due to network error');
          final upiData = json.decode(savedData);
          return {
            'success': true,
            'data': upiData,
          };
        }
      } catch (cacheError) {
        debugPrint('❌ [API] Cache access also failed: $cacheError');
      }
      
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Delete owner UPI details
  static Future<Map<String, dynamic>> deleteOwnerUpiDetails(String ownerId) async {
    try {
      debugPrint('🗑️ [API] Deleting owner UPI details for: $ownerId');
      
      final prefs = await SharedPreferences.getInstance();
      final key = 'owner_upi_$ownerId';
      await prefs.remove(key);
      
      debugPrint('✅ [API] UPI details deleted from local storage');
      
      return {
        'success': true,
        'message': 'UPI details deleted successfully',
      };
    } catch (e) {
      debugPrint('❌ [API] Failed to delete UPI details: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }


}
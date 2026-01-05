import 'package:flutter/foundation.dart';

// Simplified tenant model for API responses within room data
class RoomTenant {
  final String id;
  final String name;
  final String email;
  final String phone;
  final DateTime? moveInDate;
  final DateTime? leaseEndDate;
  final bool isActive;

  RoomTenant({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.moveInDate,
    this.leaseEndDate,
    this.isActive = true,
  });

  factory RoomTenant.fromJson(Map<String, dynamic> json) {
    return RoomTenant(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      moveInDate: json['moveInDate'] != null 
          ? DateTime.tryParse(json['moveInDate'].toString())
          : null,
      leaseEndDate: json['leaseEndDate'] != null 
          ? DateTime.tryParse(json['leaseEndDate'].toString())
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'moveInDate': moveInDate?.toIso8601String(),
      'leaseEndDate': leaseEndDate?.toIso8601String(),
      'isActive': isActive,
    };
  }
}

class Room {
  final String id;
  final String buildingId; // Reference to building
  final String number;
  final String type; // 'pg' (Paying Guest), 'rented', 'leased'
  final String status; // 'occupied', 'vacant', 'maintenance'
  final String? tenantId;
  final double rent;
  final int capacity;
  final int currentOccupancy;
  final List<String> amenities;
  final List<String> images;
  final String? description;
  final int? floor;
  final String? area;
  final bool isOccupied;
  final RoomTenant? tenant; // Tenant information if room is occupied

  Room({
    required this.id,
    required this.buildingId,
    required this.number,
    required this.type,
    required this.status,
    this.tenantId,
    required this.rent,
    required this.capacity,
    this.currentOccupancy = 0,
    this.amenities = const [],
    this.images = const [],
    this.description,
    this.floor,
    this.area,
    this.isOccupied = false,
    this.tenant,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    try {
      // Debug logging for buildingId extraction
      String extractedBuildingId = json['buildingId']?.toString() ?? 
                    json['building_id']?.toString() ?? 
                    (json['building'] is Map ? json['building']['id']?.toString() : json['building']?.toString()) ?? 
                    '1';
      
      debugPrint('🏠 [Room.fromJson] Room ${json['number']} - buildingId extraction:');
      debugPrint('  - buildingId field: ${json['buildingId']}');
      debugPrint('  - building_id field: ${json['building_id']}');
      debugPrint('  - building field: ${json['building']}');
      debugPrint('  - extracted buildingId: $extractedBuildingId');
      
      // Parse tenant information if available
      RoomTenant? roomTenant;
      if (json['tenant'] != null && json['tenant'] is Map<String, dynamic>) {
        try {
          roomTenant = RoomTenant.fromJson(json['tenant'] as Map<String, dynamic>);
          debugPrint('✅ [Room.fromJson] Parsed tenant: ${roomTenant.name}');
        } catch (e) {
          debugPrint('❌ [Room.fromJson] Error parsing tenant: $e');
        }
      }
      
      return Room(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        buildingId: extractedBuildingId,
        number: json['number']?.toString() ?? json['roomNumber']?.toString() ?? '',
        type: json['type']?.toString() ?? 'rented',
        status: json['status']?.toString() ?? 'vacant',
        tenantId: json['tenantId']?.toString() ?? json['tenant_id']?.toString() ?? roomTenant?.id,
        rent: (json['rent'] as num?)?.toDouble() ?? 
              (json['monthlyRent'] as num?)?.toDouble() ?? 
              (json['price'] as num?)?.toDouble() ?? 
              0.0,
        capacity: (json['capacity'] as num?)?.toInt() ?? 
                  (json['maxOccupancy'] as num?)?.toInt() ?? 
                  1,
        currentOccupancy: (json['currentOccupancy'] as num?)?.toInt() ?? 
                          (json['occupancy'] as num?)?.toInt() ?? 
                          (json['occupied'] as num?)?.toInt() ?? 
                          (roomTenant != null ? 1 : 0),
        amenities: json['amenities'] != null
            ? (json['amenities'] as List).map((e) => e.toString()).toList()
            : [],
        images: json['images'] != null
            ? (json['images'] as List).map((e) => e.toString()).toList()
            : [],
        description: json['description']?.toString(),
        floor: (json['floor'] as num?)?.toInt() ?? 
               (json['floorNumber'] as num?)?.toInt(),
        area: json['area']?.toString() ?? json['size']?.toString(),
        isOccupied: json['isOccupied'] as bool? ?? (roomTenant != null),
        tenant: roomTenant,
      );
    } catch (e) {
      debugPrint('❌ [Room.fromJson] Error parsing room: $e');
      debugPrint('❌ [Room.fromJson] JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buildingId': buildingId,
      'number': number,
      'type': type,
      'status': status,
      'tenantId': tenantId,
      'rent': rent,
      'capacity': capacity,
      'currentOccupancy': currentOccupancy,
      'amenities': amenities,
      'images': images,
      'description': description,
      'floor': floor,
      'area': area,
      'isOccupied': isOccupied,
      'tenant': tenant?.toJson(),
    };
  }

  // Helper method to get room type display name
  String get typeDisplayName {
    switch (type.toLowerCase()) {
      case 'pg':
        return 'Paying Guest';
      case 'rented':
        return 'Rented';
      case 'leased':
        return 'Leased';
      default:
        return type;
    }
  }

  // Helper method to check if room has tenant
  bool get hasTenant => tenant != null && isOccupied;

  // Helper method to get tenant name or placeholder
  String get tenantName => tenant?.name ?? 'No Tenant';

  // Helper method to get occupancy status
  String get occupancyStatus {
    if (hasTenant) {
      return 'Occupied by ${tenant!.name}';
    } else if (status == 'maintenance') {
      return 'Under Maintenance';
    } else {
      return 'Vacant';
    }
  }
}
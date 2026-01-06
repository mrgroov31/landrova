import 'package:flutter/foundation.dart';

// Building info within tenant response
class TenantBuilding {
  final String id;
  final String name;
  final String address;
  final String? city;
  final String? state;
  final String? pincode;

  TenantBuilding({
    required this.id,
    required this.name,
    required this.address,
    this.city,
    this.state,
    this.pincode,
  });

  factory TenantBuilding.fromJson(Map<String, dynamic> json) {
    return TenantBuilding(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      pincode: json['pincode']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
    };
  }
}

// Room info within tenant response
class TenantRoom {
  final String number;
  final String type;
  final int? floor;
  final int? capacity;
  final String? area;

  TenantRoom({
    required this.number,
    required this.type,
    this.floor,
    this.capacity,
    this.area,
  });

  factory TenantRoom.fromJson(Map<String, dynamic> json) {
    return TenantRoom(
      number: json['number']?.toString() ?? '',
      type: json['type']?.toString() ?? 'rented',
      floor: (json['floor'] as num?)?.toInt(),
      capacity: (json['capacity'] as num?)?.toInt(),
      area: json['area']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'type': type,
      'floor': floor,
      'capacity': capacity,
      'area': area,
    };
  }
}

// Main API Tenant model
class ApiTenant {
  final String tenantId;
  final String buildingId;
  final String roomId;
  final String name;
  final String email;
  final String phone;
  final String roomNumber;
  final double monthlyRent;
  final String type;
  final String? occupation;
  final String? aadharNumber;
  final String? emergencyContact;
  final String? profileImage;
  final String? aadharFrontImage;
  final String? aadharBackImage;
  final String? panCardImage;
  final String? addressProofImage;
  final String? invitationToken;
  final DateTime? moveInDate;
  final DateTime? leaseEndDate;
  final double? depositPaid;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final TenantBuilding? building;
  final TenantRoom? room;

  ApiTenant({
    required this.tenantId,
    required this.buildingId,
    required this.roomId,
    required this.name,
    required this.email,
    required this.phone,
    required this.roomNumber,
    required this.monthlyRent,
    required this.type,
    this.occupation,
    this.aadharNumber,
    this.emergencyContact,
    this.profileImage,
    this.aadharFrontImage,
    this.aadharBackImage,
    this.panCardImage,
    this.addressProofImage,
    this.invitationToken,
    this.moveInDate,
    this.leaseEndDate,
    this.depositPaid,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.building,
    this.room,
  });

  factory ApiTenant.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('👥 [ApiTenant.fromJson] Parsing tenant: ${json['name']}');
      
      // Parse building info
      TenantBuilding? building;
      if (json['building'] != null && json['building'] is Map<String, dynamic>) {
        try {
          building = TenantBuilding.fromJson(json['building'] as Map<String, dynamic>);
          debugPrint('✅ [ApiTenant.fromJson] Parsed building: ${building.name}');
        } catch (e) {
          debugPrint('❌ [ApiTenant.fromJson] Error parsing building: $e');
        }
      }
      
      // Parse room info
      TenantRoom? room;
      if (json['room'] != null && json['room'] is Map<String, dynamic>) {
        try {
          room = TenantRoom.fromJson(json['room'] as Map<String, dynamic>);
          debugPrint('✅ [ApiTenant.fromJson] Parsed room: ${room.number}');
        } catch (e) {
          debugPrint('❌ [ApiTenant.fromJson] Error parsing room: $e');
        }
      }
      
      return ApiTenant(
        tenantId: json['tenantId']?.toString() ?? '',
        buildingId: json['buildingId']?.toString() ?? '',
        roomId: json['roomId']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        phone: json['phone']?.toString() ?? '',
        roomNumber: json['roomNumber']?.toString() ?? '',
        monthlyRent: (json['monthlyRent'] as num?)?.toDouble() ?? 0.0,
        type: json['type']?.toString() ?? 'tenant',
        occupation: json['occupation']?.toString(),
        aadharNumber: json['aadharNumber']?.toString(),
        emergencyContact: json['emergencyContact']?.toString(),
        profileImage: json['profileImage']?.toString(),
        aadharFrontImage: json['aadharFrontImage']?.toString(),
        aadharBackImage: json['aadharBackImage']?.toString(),
        panCardImage: json['panCardImage']?.toString(),
        addressProofImage: json['addressProofImage']?.toString(),
        invitationToken: json['invitationToken']?.toString(),
        moveInDate: json['moveInDate'] != null 
            ? DateTime.tryParse(json['moveInDate'].toString())
            : null,
        leaseEndDate: json['leaseEndDate'] != null 
            ? DateTime.tryParse(json['leaseEndDate'].toString())
            : null,
        depositPaid: (json['depositPaid'] as num?)?.toDouble(),
        isActive: json['isActive'] as bool? ?? true,
        createdAt: json['createdAt'] != null 
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
        updatedAt: json['updatedAt'] != null 
            ? DateTime.tryParse(json['updatedAt'].toString())
            : null,
        building: building,
        room: room,
      );
    } catch (e) {
      debugPrint('❌ [ApiTenant.fromJson] Error parsing tenant: $e');
      debugPrint('❌ [ApiTenant.fromJson] JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'tenantId': tenantId,
      'buildingId': buildingId,
      'roomId': roomId,
      'name': name,
      'email': email,
      'phone': phone,
      'roomNumber': roomNumber,
      'monthlyRent': monthlyRent,
      'type': type,
      'occupation': occupation,
      'aadharNumber': aadharNumber,
      'emergencyContact': emergencyContact,
      'profileImage': profileImage,
      'aadharFrontImage': aadharFrontImage,
      'aadharBackImage': aadharBackImage,
      'panCardImage': panCardImage,
      'addressProofImage': addressProofImage,
      'invitationToken': invitationToken,
      'moveInDate': moveInDate?.toIso8601String(),
      'leaseEndDate': leaseEndDate?.toIso8601String(),
      'depositPaid': depositPaid,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'building': building?.toJson(),
      'room': room?.toJson(),
    };
  }

  // Helper getters
  String get buildingName => building?.name ?? 'Unknown Building';
  String get fullAddress => building != null 
      ? '${building!.address}${building!.city != null ? ', ${building!.city}' : ''}'
      : 'Unknown Address';
  String get typeDisplayName {
    switch (type.toLowerCase()) {
      case 'tenant':
        return 'Tenant';
      case 'paying_guest':
      case 'pg':
        return 'Paying Guest';
      default:
        return type;
    }
  }
}
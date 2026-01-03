class BuildingFacility {
  final String name;
  final bool isPaid; // true for paid, false for free

  BuildingFacility({
    required this.name,
    required this.isPaid,
  });

  factory BuildingFacility.fromJson(Map<String, dynamic> json) {
    return BuildingFacility(
      name: json['name'].toString(),
      isPaid: json['isPaid'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isPaid': isPaid,
    };
  }
}

class BuildingOwner {
  final String name;
  final String email;
  final String phone;
  final String? image; // Path to owner profile image

  BuildingOwner({
    required this.name,
    required this.email,
    required this.phone,
    this.image,
  });

  factory BuildingOwner.fromJson(Map<String, dynamic> json) {
    return BuildingOwner(
      name: json['name'].toString(),
      email: json['email'].toString(),
      phone: json['phone'].toString(),
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'image': image,
    };
  }
}

class Building {
  final String id;
  final String name;
  final String address;
  final String? city;
  final String? state;
  final String? pincode;
  final int totalFloors;
  final int totalRooms;
  final String buildingType; // 'standalone', 'apartment', 'complex'
  final String propertyType; // 'pg', 'rented', 'leased' - set when property is created
  final String? image;
  final String? description;
  final DateTime createdAt;
  final bool isActive;
  final BuildingOwner? owner; // Owner details
  final List<BuildingFacility> facilities; // Building facilities

  Building({
    required this.id,
    required this.name,
    required this.address,
    this.city,
    this.state,
    this.pincode,
    required this.totalFloors,
    required this.totalRooms,
    required this.buildingType,
    required this.propertyType, // Required: PG, Rented, or Leased
    this.image,
    this.description,
    required this.createdAt,
    this.isActive = true,
    this.owner,
    this.facilities = const [],
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['id'].toString(),
      name: json['name'].toString(),
      address: json['address'].toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      pincode: json['pincode']?.toString(),
      totalFloors: json['totalFloors'] as int,
      totalRooms: json['totalRooms'] as int,
      buildingType: json['buildingType']?.toString() ?? 'standalone',
      propertyType: json['propertyType']?.toString() ?? 'rented', // Default to 'rented' if not specified
      image: json['image']?.toString(),
      description: json['description']?.toString(),
      createdAt: DateTime.parse(json['createdAt'].toString()),
      isActive: json['isActive'] as bool? ?? true,
      owner: json['owner'] != null ? BuildingOwner.fromJson(json['owner'] as Map<String, dynamic>) : null,
      facilities: json['facilities'] != null
          ? (json['facilities'] as List)
              .map((f) => BuildingFacility.fromJson(f as Map<String, dynamic>))
              .toList()
          : [],
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
      'totalFloors': totalFloors,
      'totalRooms': totalRooms,
      'buildingType': buildingType,
      'propertyType': propertyType,
      'image': image,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
      'owner': owner?.toJson(),
      'facilities': facilities.map((f) => f.toJson()).toList(),
    };
  }

  // Helper method to get property type display name
  String get propertyTypeDisplayName {
    switch (propertyType.toLowerCase()) {
      case 'pg':
        return 'Paying Guest';
      case 'rented':
        return 'Rented';
      case 'leased':
        return 'Leased';
      default:
        return propertyType;
    }
  }
}


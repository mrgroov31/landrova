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
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'].toString(),
      buildingId: json['buildingId']?.toString() ?? json['building_id']?.toString() ?? '1',
      number: json['number'].toString(),
      type: json['type'].toString(),
      status: json['status'].toString(),
      tenantId: json['tenantId']?.toString(),
      rent: (json['rent'] as num).toDouble(),
      capacity: json['capacity'] as int,
      currentOccupancy: json['currentOccupancy'] as int? ?? 0,
      amenities: json['amenities'] != null
          ? List<String>.from(json['amenities'])
          : [],
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [],
      description: json['description']?.toString(),
      floor: json['floor'] as int?,
      area: json['area']?.toString(),
    );
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
}


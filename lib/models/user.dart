enum UserRole {
  owner,
  tenant,
}

class AppUser {
  final String id;
  final String email;
  final String phone;
  final String name;
  final UserRole role;
  final String? profileImage;
  final Map<String, dynamic>? additionalData; // Role-specific data

  AppUser({
    required this.id,
    required this.email,
    required this.phone,
    required this.name,
    required this.role,
    this.profileImage,
    this.additionalData,
  });

  // Owner user
  factory AppUser.owner({
    required String id,
    required String email,
    required String phone,
    required String name,
    String? profileImage,
    String? buildingId,
  }) {
    return AppUser(
      id: id,
      email: email,
      phone: phone,
      name: name,
      role: UserRole.owner,
      profileImage: profileImage,
      additionalData: {
        'buildingId': buildingId,
      },
    );
  }

  // Tenant user
  factory AppUser.tenant({
    required String id,
    required String email,
    required String phone,
    required String name,
    String? profileImage,
    String? roomNumber,
    String? tenantId,
  }) {
    return AppUser(
      id: id,
      email: email,
      phone: phone,
      name: name,
      role: UserRole.tenant,
      profileImage: profileImage,
      additionalData: {
        'roomNumber': roomNumber,
        'tenantId': tenantId,
      },
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(),
      email: json['email'].toString(),
      phone: json['phone'].toString(),
      name: json['name'].toString(),
      role: json['role'] == 'owner' ? UserRole.owner : UserRole.tenant,
      profileImage: json['profileImage']?.toString(),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'name': name,
      'role': role == UserRole.owner ? 'owner' : 'tenant',
      'profileImage': profileImage,
      'additionalData': additionalData,
    };
  }

  bool get isOwner => role == UserRole.owner;
  bool get isTenant => role == UserRole.tenant;
}


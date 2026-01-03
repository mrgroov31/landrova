class Tenant {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String roomNumber;
  final DateTime moveInDate;
  final double monthlyRent;
  final String type; // 'tenant' or 'paying_guest'
  final bool isActive;
  final String? aadharNumber;
  final String? emergencyContact;
  final String? occupation;
  final String? profileImage;
  final String? aadharFrontImage;
  final String? aadharBackImage;
  final String? panCardImage;
  final String? addressProofImage;
  final String? invitationToken; // Token from the invitation link

  Tenant({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.roomNumber,
    required this.moveInDate,
    required this.monthlyRent,
    required this.type,
    this.isActive = true,
    this.aadharNumber,
    this.emergencyContact,
    this.occupation,
    this.profileImage,
    this.aadharFrontImage,
    this.aadharBackImage,
    this.panCardImage,
    this.addressProofImage,
    this.invitationToken,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'].toString(),
      name: json['name'].toString(),
      phone: json['phone'].toString(),
      email: json['email'].toString(),
      roomNumber: json['roomNumber'].toString(),
      moveInDate: DateTime.parse(json['moveInDate'].toString()),
      monthlyRent: (json['monthlyRent'] as num).toDouble(),
      type: json['type'].toString(),
      isActive: json['isActive'] as bool? ?? true,
      aadharNumber: json['aadharNumber']?.toString(),
      emergencyContact: json['emergencyContact']?.toString(),
      occupation: json['occupation']?.toString(),
      profileImage: json['profileImage']?.toString(),
      aadharFrontImage: json['aadharFrontImage']?.toString(),
      aadharBackImage: json['aadharBackImage']?.toString(),
      panCardImage: json['panCardImage']?.toString(),
      addressProofImage: json['addressProofImage']?.toString(),
      invitationToken: json['invitationToken']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'roomNumber': roomNumber,
      'moveInDate': moveInDate.toIso8601String(),
      'monthlyRent': monthlyRent,
      'type': type,
      'isActive': isActive,
      'aadharNumber': aadharNumber,
      'emergencyContact': emergencyContact,
      'occupation': occupation,
      'profileImage': profileImage,
      'aadharFrontImage': aadharFrontImage,
      'aadharBackImage': aadharBackImage,
      'panCardImage': panCardImage,
      'addressProofImage': addressProofImage,
      'invitationToken': invitationToken,
    };
  }
}


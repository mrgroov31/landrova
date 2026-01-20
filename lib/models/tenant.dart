// Family member model for tenant
class FamilyMember {
  final String name;
  final int? age;
  final String relation;
  final String? aadharNumber;
  final String? phone;

  FamilyMember({
    required this.name,
    this.age,
    required this.relation,
    this.aadharNumber,
    this.phone,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      name: json['name'].toString(),
      age: json['age'] as int?,
      relation: json['relation'].toString(),
      aadharNumber: json['aadharNumber']?.toString(),
      phone: json['phone']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (age != null) 'age': age,
      'relation': relation,
      if (aadharNumber != null) 'aadharNumber': aadharNumber,
      if (phone != null) 'phone': phone,
    };
  }
}

// Emergency contact details
class EmergencyContactDetails {
  final String name;
  final String phone;
  final String relation;

  EmergencyContactDetails({
    required this.name,
    required this.phone,
    required this.relation,
  });

  factory EmergencyContactDetails.fromJson(Map<String, dynamic> json) {
    return EmergencyContactDetails(
      name: json['name'].toString(),
      phone: json['phone'].toString(),
      relation: json['relation'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'relation': relation,
    };
  }
}

// ID proof details
class IdProof {
  final String type;
  final String number;

  IdProof({
    required this.type,
    required this.number,
  });

  factory IdProof.fromJson(Map<String, dynamic> json) {
    return IdProof(
      type: json['type'].toString(),
      number: json['number'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'number': number,
    };
  }
}

class Tenant {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String roomNumber;
  final DateTime moveInDate;
  final DateTime? leaseEndDate;
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
  final List<FamilyMember>? familyMembers; // New field from backend API
  final EmergencyContactDetails? emergencyContactDetails;
  final IdProof? idProof;
  final String? roomId; // Room UUID reference

  Tenant({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.roomNumber,
    required this.moveInDate,
    this.leaseEndDate,
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
    this.familyMembers,
    this.emergencyContactDetails,
    this.idProof,
    this.roomId,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'].toString(),
      name: json['name'].toString(),
      phone: json['phone'].toString(),
      email: json['email'].toString(),
      roomNumber: json['roomNumber'].toString(),
      moveInDate: DateTime.parse(json['moveInDate'].toString()),
      leaseEndDate: json['leaseEndDate'] != null 
          ? DateTime.parse(json['leaseEndDate'].toString()) 
          : null,
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
      roomId: json['roomId']?.toString(),
      familyMembers: json['familyMembers'] != null
          ? (json['familyMembers'] as List)
              .map((member) => FamilyMember.fromJson(member))
              .toList()
          : null,
      emergencyContactDetails: json['emergencyContactDetails'] != null
          ? EmergencyContactDetails.fromJson(json['emergencyContactDetails'])
          : null,
      idProof: json['idProof'] != null
          ? IdProof.fromJson(json['idProof'])
          : null,
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
      if (leaseEndDate != null) 'leaseEndDate': leaseEndDate!.toIso8601String(),
      'monthlyRent': monthlyRent,
      'type': type,
      'isActive': isActive,
      if (aadharNumber != null) 'aadharNumber': aadharNumber,
      if (emergencyContact != null) 'emergencyContact': emergencyContact,
      if (occupation != null) 'occupation': occupation,
      if (profileImage != null) 'profileImage': profileImage,
      if (aadharFrontImage != null) 'aadharFrontImage': aadharFrontImage,
      if (aadharBackImage != null) 'aadharBackImage': aadharBackImage,
      if (panCardImage != null) 'panCardImage': panCardImage,
      if (addressProofImage != null) 'addressProofImage': addressProofImage,
      if (invitationToken != null) 'invitationToken': invitationToken,
      if (roomId != null) 'roomId': roomId,
      if (familyMembers != null) 
        'familyMembers': familyMembers!.map((member) => member.toJson()).toList(),
      if (emergencyContactDetails != null) 
        'emergencyContactDetails': emergencyContactDetails!.toJson(),
      if (idProof != null) 'idProof': idProof!.toJson(),
    };
  }

  // Helper method to create tenant for API creation (without auto-generated fields)
  Map<String, dynamic> toCreateJson() {
    return {
      if (roomId != null) 'roomId': roomId,
      'name': name,
      'email': email,
      'phone': phone,
      'moveInDate': moveInDate.toIso8601String(),
      if (leaseEndDate != null) 'leaseEndDate': leaseEndDate!.toIso8601String(),
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
        'familyMembers': familyMembers!.map((member) => member.toJson()).toList(),
      if (emergencyContactDetails != null) 
        'emergencyContactDetails': emergencyContactDetails!.toJson(),
      if (idProof != null) 'idProof': idProof!.toJson(),
    };
  }

  // Helper method for partial updates (PATCH)
  Map<String, dynamic> toUpdateJson() {
    final Map<String, dynamic> updateData = {};
    
    // Only include non-null fields for update
    updateData['name'] = name;
    updateData['email'] = email;
    updateData['phone'] = phone;
    updateData['type'] = type;
    updateData['isActive'] = isActive;
    
    if (occupation != null) updateData['occupation'] = occupation;
    if (aadharNumber != null) updateData['aadharNumber'] = aadharNumber;
    if (emergencyContact != null) updateData['emergencyContact'] = emergencyContact;
    if (leaseEndDate != null) updateData['leaseEndDate'] = leaseEndDate!.toIso8601String();
    if (profileImage != null) updateData['profileImage'] = profileImage;
    if (aadharFrontImage != null) updateData['aadharFrontImage'] = aadharFrontImage;
    if (aadharBackImage != null) updateData['aadharBackImage'] = aadharBackImage;
    if (panCardImage != null) updateData['panCardImage'] = panCardImage;
    if (addressProofImage != null) updateData['addressProofImage'] = addressProofImage;
    
    if (familyMembers != null) {
      updateData['familyMembers'] = familyMembers!.map((member) => member.toJson()).toList();
    }
    if (emergencyContactDetails != null) {
      updateData['emergencyContactDetails'] = emergencyContactDetails!.toJson();
    }
    if (idProof != null) {
      updateData['idProof'] = idProof!.toJson();
    }
    
    return updateData;
  }
}


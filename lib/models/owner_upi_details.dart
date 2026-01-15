class OwnerUpiDetails {
  final String id;
  final String ownerId;
  final String upiId;
  final String ownerName;
  final String bankName;
  final String accountNumber; // Last 4 digits only for display
  final bool isVerified;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? qrCodeData;

  OwnerUpiDetails({
    required this.id,
    required this.ownerId,
    required this.upiId,
    required this.ownerName,
    required this.bankName,
    required this.accountNumber,
    this.isVerified = false,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.qrCodeData,
  });

  factory OwnerUpiDetails.fromJson(Map<String, dynamic> json) {
    return OwnerUpiDetails(
      id: json['id'].toString(),
      ownerId: json['ownerId'].toString(),
      upiId: json['upiId'].toString(),
      ownerName: json['ownerName'].toString(),
      bankName: json['bankName'].toString(),
      accountNumber: json['accountNumber'].toString(),
      isVerified: json['isVerified'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'].toString()) 
          : null,
      qrCodeData: json['qrCodeData']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'upiId': upiId,
      'ownerName': ownerName,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'isVerified': isVerified,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'qrCodeData': qrCodeData,
    };
  }

  // Generate UPI payment URL for this owner
  String generateUpiUrl({
    required double amount,
    required String transactionId,
    required String description,
  }) {
    final encodedName = Uri.encodeComponent(ownerName);
    final encodedNote = Uri.encodeComponent(description);
    
    return 'upi://pay?pa=$upiId&pn=$encodedName&tr=$transactionId&am=$amount&cu=INR&tn=$encodedNote';
  }

  // Validate UPI ID format
  static bool isValidUpiId(String upiId) {
    // UPI ID format: username@bankcode
    final upiRegex = RegExp(r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$');
    return upiRegex.hasMatch(upiId);
  }

  // Get display name for account
  String get displayAccountNumber => '****${accountNumber.substring(accountNumber.length - 4)}';

  // Copy with method for updates
  OwnerUpiDetails copyWith({
    String? id,
    String? ownerId,
    String? upiId,
    String? ownerName,
    String? bankName,
    String? accountNumber,
    bool? isVerified,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? qrCodeData,
  }) {
    return OwnerUpiDetails(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      upiId: upiId ?? this.upiId,
      ownerName: ownerName ?? this.ownerName,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      isVerified: isVerified ?? this.isVerified,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      qrCodeData: qrCodeData ?? this.qrCodeData,
    );
  }
}
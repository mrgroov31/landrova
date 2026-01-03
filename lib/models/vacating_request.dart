class VacatingRequest {
  final String id;
  final String tenantId;
  final String tenantName;
  final String roomNumber;
  final DateTime vacatingDate;
  final String reason;
  String status; // 'pending', 'approved', 'rejected', 'completed'
  final DateTime createdAt;
  DateTime? updatedAt;
  DateTime? approvedAt;
  String? approvedBy; // Owner ID

  VacatingRequest({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.roomNumber,
    required this.vacatingDate,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.approvedAt,
    this.approvedBy,
  });

  factory VacatingRequest.fromJson(Map<String, dynamic> json) {
    return VacatingRequest(
      id: json['id'].toString(),
      tenantId: json['tenantId'].toString(),
      tenantName: json['tenantName'].toString(),
      roomNumber: json['roomNumber'].toString(),
      vacatingDate: DateTime.parse(json['vacatingDate'].toString()),
      reason: json['reason'].toString(),
      status: json['status'].toString(),
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'].toString())
          : null,
      approvedBy: json['approvedBy']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'tenantName': tenantName,
      'roomNumber': roomNumber,
      'vacatingDate': vacatingDate.toIso8601String(),
      'reason': reason,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'approvedBy': approvedBy,
    };
  }

  // Helper method to approve request
  void approve(String ownerId) {
    status = 'approved';
    approvedAt = DateTime.now();
    approvedBy = ownerId;
    updatedAt = DateTime.now();
  }

  // Helper method to reject request
  void reject() {
    status = 'rejected';
    updatedAt = DateTime.now();
  }

  // Check if vacating date has passed
  bool get isVacatingDatePassed {
    return DateTime.now().isAfter(vacatingDate);
  }

  // Check if request is completed (approved and date passed)
  bool get isCompleted {
    return status == 'approved' && isVacatingDatePassed;
  }
}


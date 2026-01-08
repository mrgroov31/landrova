class Complaint {
  final String id;
  final String title;
  final String description;
  final String roomNumber;
  final String tenantId;
  final String tenantName;
  String status; // 'pending', 'assigned', 'in_progress', 'resolved', 'fixed'
  final DateTime createdAt;
  DateTime updatedAt;
  DateTime? resolvedAt;
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String? category;
  String? assignedTo;
  String? serviceProviderId; // ID of assigned service provider
  final List<String> images;
  
  // New fields for API integration
  final String? roomId;
  final String? buildingId;
  final String? contactPreference;
  final bool? urgentContact;

  Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.roomNumber,
    required this.tenantId,
    required this.tenantName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedAt,
    required this.priority,
    this.category,
    this.assignedTo,
    this.serviceProviderId,
    this.images = const [],
    this.roomId,
    this.buildingId,
    this.contactPreference,
    this.urgentContact,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id'].toString(),
      title: json['title'].toString(),
      description: json['description'].toString(),
      roomNumber: json['roomNumber'].toString(),
      tenantId: json['tenantId'].toString(),
      tenantName: json['tenantName'].toString(),
      status: json['status'].toString(),
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: DateTime.parse(json['updatedAt'].toString()),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.parse(json['resolvedAt'].toString())
          : null,
      priority: json['priority'].toString(),
      category: json['category']?.toString(),
      assignedTo: json['assignedTo']?.toString(),
      serviceProviderId: json['serviceProviderId']?.toString(),
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [],
      roomId: json['roomId']?.toString(),
      buildingId: json['buildingId']?.toString(),
      contactPreference: json['contactPreference']?.toString(),
      urgentContact: json['urgentContact'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'roomNumber': roomNumber,
      'tenantId': tenantId,
      'tenantName': tenantName,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'priority': priority,
      'category': category,
      'assignedTo': assignedTo,
      'serviceProviderId': serviceProviderId,
      'images': images,
      'roomId': roomId,
      'buildingId': buildingId,
      'contactPreference': contactPreference,
      'urgentContact': urgentContact,
    };
  }

  // Helper method to create API payload for complaint creation
  Map<String, dynamic> toApiPayload() {
    return {
      'title': title,
      'description': description,
      'roomId': roomId,
      'buildingId': buildingId,
      'tenantId': tenantId,
      'category': category,
      'priority': priority,
      'images': images,
      'contactPreference': contactPreference ?? 'phone',
      'urgentContact': urgentContact ?? false,
    };
  }
  
  // Helper method to assign service provider
  void assignServiceProvider(String providerId, String providerName) {
    serviceProviderId = providerId;
    assignedTo = providerName;
    status = 'assigned';
    updatedAt = DateTime.now();
  }
  
  // Helper method to mark as fixed by tenant
  void markAsFixed() {
    status = 'resolved';
    resolvedAt = DateTime.now();
    updatedAt = DateTime.now();
  }
}


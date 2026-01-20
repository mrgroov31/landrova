import 'package:flutter/foundation.dart';

enum PaymentStatus {
  initiated,
  pending,
  completed,
  failed,
  cancelled,
  verified,
}

class PaymentTransaction {
  final String id;
  final String tenantId;
  final String tenantName;
  final String ownerId;
  final String ownerName;
  final String ownerUpiId;
  final double amount;
  final String roomNumber;
  final String paymentType; // 'rent', 'deposit', 'maintenance', etc.
  final String month;
  final int year;
  final String description;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final String paymentHash;
  final String? upiTransactionId;
  final String? upiResponseCode;
  final String? backendPaymentId;
  final String? errorMessage;

  const PaymentTransaction({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.ownerId,
    required this.ownerName,
    required this.ownerUpiId,
    required this.amount,
    required this.roomNumber,
    required this.paymentType,
    required this.month,
    required this.year,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.paymentHash,
    this.updatedAt,
    this.completedAt,
    this.upiTransactionId,
    this.upiResponseCode,
    this.backendPaymentId,
    this.errorMessage,
  });

  // Factory constructor with default values for easier creation
  factory PaymentTransaction.create({
    required String id,
    required String tenantId,
    String? tenantName,
    required String ownerId,
    String? ownerName,
    String? ownerUpiId,
    required double amount,
    String? roomNumber,
    String paymentType = 'rent',
    String? month,
    int? year,
    String? description,
    PaymentStatus status = PaymentStatus.initiated,
    DateTime? createdAt,
    String? paymentHash,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? upiTransactionId,
    String? upiResponseCode,
    String? backendPaymentId,
    String? errorMessage,
  }) {
    final now = DateTime.now();
    final monthNames = ['January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    
    return PaymentTransaction(
      id: id,
      tenantId: tenantId,
      tenantName: tenantName ?? 'Unknown Tenant',
      ownerId: ownerId,
      ownerName: ownerName ?? 'Unknown Owner',
      ownerUpiId: ownerUpiId ?? 'unknown@upi',
      amount: amount,
      roomNumber: roomNumber ?? 'Unknown Room',
      paymentType: paymentType,
      month: month ?? monthNames[now.month - 1],
      year: year ?? now.year,
      description: description ?? 'Payment transaction',
      status: status,
      createdAt: createdAt ?? now,
      paymentHash: paymentHash ?? 'hash_${now.millisecondsSinceEpoch}',
      updatedAt: updatedAt,
      completedAt: completedAt,
      upiTransactionId: upiTransactionId,
      upiResponseCode: upiResponseCode,
      backendPaymentId: backendPaymentId,
      errorMessage: errorMessage,
    );
  }

  PaymentTransaction copyWith({
    String? id,
    String? tenantId,
    String? tenantName,
    String? ownerId,
    String? ownerName,
    String? ownerUpiId,
    double? amount,
    String? roomNumber,
    String? paymentType,
    String? month,
    int? year,
    String? description,
    PaymentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    String? paymentHash,
    String? upiTransactionId,
    String? upiResponseCode,
    String? backendPaymentId,
    String? errorMessage,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      tenantName: tenantName ?? this.tenantName,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerUpiId: ownerUpiId ?? this.ownerUpiId,
      amount: amount ?? this.amount,
      roomNumber: roomNumber ?? this.roomNumber,
      paymentType: paymentType ?? this.paymentType,
      month: month ?? this.month,
      year: year ?? this.year,
      description: description ?? this.description,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      paymentHash: paymentHash ?? this.paymentHash,
      upiTransactionId: upiTransactionId ?? this.upiTransactionId,
      upiResponseCode: upiResponseCode ?? this.upiResponseCode,
      backendPaymentId: backendPaymentId ?? this.backendPaymentId,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'tenantName': tenantName,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerUpiId': ownerUpiId,
      'amount': amount,
      'roomNumber': roomNumber,
      'paymentType': paymentType,
      'month': month,
      'year': year,
      'description': description,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'paymentHash': paymentHash,
      'upiTransactionId': upiTransactionId,
      'upiResponseCode': upiResponseCode,
      'backendPaymentId': backendPaymentId,
      'errorMessage': errorMessage,
    };
  }

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as String,
      tenantId: json['tenantId'] as String,
      tenantName: json['tenantName'] as String,
      ownerId: json['ownerId'] as String,
      ownerName: json['ownerName'] as String,
      ownerUpiId: json['ownerUpiId'] as String,
      amount: (json['amount'] as num).toDouble(),
      roomNumber: json['roomNumber'] as String,
      paymentType: json['paymentType'] as String,
      month: json['month'] as String,
      year: json['year'] as int,
      description: json['description'] as String,
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => PaymentStatus.failed,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt'] as String) 
          : null,
      paymentHash: json['paymentHash'] as String,
      upiTransactionId: json['upiTransactionId'] as String?,
      upiResponseCode: json['upiResponseCode'] as String?,
      backendPaymentId: json['backendPaymentId'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  @override
  String toString() {
    return 'PaymentTransaction(id: $id, amount: $amount, status: $status, tenantName: $tenantName, roomNumber: $roomNumber)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentTransaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper getters
  String get statusDisplayName {
    switch (status) {
      case PaymentStatus.initiated:
        return 'Initiated';
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.verified:
        return 'Verified';
    }
  }

  bool get isSuccessful => status == PaymentStatus.completed || status == PaymentStatus.verified;
  bool get isPending => status == PaymentStatus.pending || status == PaymentStatus.initiated;
  bool get isFailed => status == PaymentStatus.failed || status == PaymentStatus.cancelled;

  String get formattedAmount => '₹${amount.toStringAsFixed(2)}';
  
  String get paymentTypeDisplayName {
    switch (paymentType.toLowerCase()) {
      case 'rent':
        return 'Rent Payment';
      case 'deposit':
        return 'Security Deposit';
      case 'maintenance':
        return 'Maintenance Fee';
      case 'electricity':
        return 'Electricity Bill';
      case 'water':
        return 'Water Bill';
      default:
        return paymentType;
    }
  }
}
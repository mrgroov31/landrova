class Payment {
  final String id;
  final String tenantId;
  final String tenantName;
  final String roomNumber;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final String status; // 'pending', 'paid', 'overdue'
  final String? paymentMethod;
  final String? transactionId;
  final String month;
  final int year;
  final double lateFee;
  final String? notes;

  Payment({
    required this.id,
    required this.tenantId,
    required this.tenantName,
    required this.roomNumber,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    required this.status,
    this.paymentMethod,
    this.transactionId,
    required this.month,
    required this.year,
    this.lateFee = 0,
    this.notes,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'].toString(),
      tenantId: json['tenantId'].toString(),
      tenantName: json['tenantName'].toString(),
      roomNumber: json['roomNumber'].toString(),
      amount: (json['amount'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'].toString()),
      paidDate: json['paidDate'] != null
          ? DateTime.parse(json['paidDate'].toString())
          : null,
      status: json['status'].toString(),
      paymentMethod: json['paymentMethod']?.toString(),
      transactionId: json['transactionId']?.toString(),
      month: json['month'].toString(),
      year: json['year'] as int,
      lateFee: (json['lateFee'] as num?)?.toDouble() ?? 0,
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'tenantName': tenantName,
      'roomNumber': roomNumber,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'status': status,
      'paymentMethod': paymentMethod,
      'transactionId': transactionId,
      'month': month,
      'year': year,
      'lateFee': lateFee,
      'notes': notes,
    };
  }
}


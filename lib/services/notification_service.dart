import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user.dart';
import 'auth_service.dart';

enum NotificationType {
  paymentReceived,
  paymentPending,
  paymentOverdue,
  paymentFailed,
  paymentReminder,
  tenantRegistered,
  complaintCreated,
  maintenanceScheduled,
  general,
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? actionUrl;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
    this.actionUrl,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      title: json['title'].toString(),
      message: json['message'].toString(),
      type: NotificationType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => NotificationType.general,
      ),
      createdAt: DateTime.parse(json['createdAt'].toString()),
      isRead: json['isRead'] ?? false,
      data: json['data'] as Map<String, dynamic>?,
      actionUrl: json['actionUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'data': data,
      'actionUrl': actionUrl,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? data,
    String? actionUrl,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  IconData get icon {
    switch (type) {
      case NotificationType.paymentReceived:
        return Icons.payment;
      case NotificationType.paymentPending:
        return Icons.schedule;
      case NotificationType.paymentOverdue:
        return Icons.warning;
      case NotificationType.paymentFailed:
        return Icons.error;
      case NotificationType.paymentReminder:
        return Icons.notifications;
      case NotificationType.tenantRegistered:
        return Icons.person_add;
      case NotificationType.complaintCreated:
        return Icons.report_problem;
      case NotificationType.maintenanceScheduled:
        return Icons.build;
      case NotificationType.general:
        return Icons.info;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.paymentReceived:
        return Colors.green;
      case NotificationType.paymentPending:
        return Colors.orange;
      case NotificationType.paymentOverdue:
        return Colors.red;
      case NotificationType.paymentFailed:
        return Colors.red;
      case NotificationType.paymentReminder:
        return Colors.blue;
      case NotificationType.tenantRegistered:
        return Colors.green;
      case NotificationType.complaintCreated:
        return Colors.orange;
      case NotificationType.maintenanceScheduled:
        return Colors.blue;
      case NotificationType.general:
        return Colors.grey;
    }
  }
}

class NotificationService {
  static const String _boxName = 'notifications';
  static Box? _box;
  static final List<AppNotification> _notifications = [];
  static final ValueNotifier<int> _unreadCount = ValueNotifier<int>(0);

  // Initialize notification service
  static Future<void> initialize() async {
    try {
      if (_box != null && _box!.isOpen) return;
      
      _box = await Hive.openBox(_boxName);
      await _loadNotifications();
      
      debugPrint('✅ [NOTIFICATION] Service initialized');
    } catch (e) {
      debugPrint('❌ [NOTIFICATION] Failed to initialize: $e');
    }
  }

  // Load notifications from storage
  static Future<void> _loadNotifications() async {
    if (_box == null) return;
    
    try {
      final storedNotifications = _box!.get('notifications', defaultValue: <Map<String, dynamic>>[]);
      _notifications.clear();
      
      for (final notificationData in storedNotifications) {
        try {
          final notification = AppNotification.fromJson(Map<String, dynamic>.from(notificationData));
          _notifications.add(notification);
        } catch (e) {
          debugPrint('⚠️ [NOTIFICATION] Failed to parse notification: $e');
        }
      }
      
      // Sort by creation date (newest first)
      _notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Update unread count
      _updateUnreadCount();
      
      debugPrint('📱 [NOTIFICATION] Loaded ${_notifications.length} notifications');
    } catch (e) {
      debugPrint('❌ [NOTIFICATION] Failed to load notifications: $e');
    }
  }

  // Save notifications to storage
  static Future<void> _saveNotifications() async {
    if (_box == null) return;
    
    try {
      final notificationData = _notifications.map((n) => n.toJson()).toList();
      await _box!.put('notifications', notificationData);
      debugPrint('💾 [NOTIFICATION] Saved ${_notifications.length} notifications');
    } catch (e) {
      debugPrint('❌ [NOTIFICATION] Failed to save notifications: $e');
    }
  }

  // Update unread count
  static void _updateUnreadCount() {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    _unreadCount.value = unreadCount;
  }

  // Get all notifications
  static List<AppNotification> get notifications => List.unmodifiable(_notifications);

  // Get unread count notifier
  static ValueNotifier<int> get unreadCountNotifier => _unreadCount;

  // Get unread count
  static int get unreadCount => _unreadCount.value;

  // Add notification
  static Future<void> addNotification(AppNotification notification) async {
    try {
      _notifications.insert(0, notification);
      
      // Keep only last 100 notifications
      if (_notifications.length > 100) {
        _notifications.removeRange(100, _notifications.length);
      }
      
      await _saveNotifications();
      _updateUnreadCount();
      
      debugPrint('📱 [NOTIFICATION] Added: ${notification.title}');
    } catch (e) {
      debugPrint('❌ [NOTIFICATION] Failed to add notification: $e');
    }
  }

  // Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        await _saveNotifications();
        _updateUnreadCount();
        
        debugPrint('✅ [NOTIFICATION] Marked as read: $notificationId');
      }
    } catch (e) {
      debugPrint('❌ [NOTIFICATION] Failed to mark as read: $e');
    }
  }

  // Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
      
      await _saveNotifications();
      _updateUnreadCount();
      
      debugPrint('✅ [NOTIFICATION] Marked all as read');
    } catch (e) {
      debugPrint('❌ [NOTIFICATION] Failed to mark all as read: $e');
    }
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      _notifications.removeWhere((n) => n.id == notificationId);
      await _saveNotifications();
      _updateUnreadCount();
      
      debugPrint('🗑️ [NOTIFICATION] Deleted: $notificationId');
    } catch (e) {
      debugPrint('❌ [NOTIFICATION] Failed to delete notification: $e');
    }
  }

  // Clear all notifications
  static Future<void> clearAll() async {
    try {
      _notifications.clear();
      await _saveNotifications();
      _updateUnreadCount();
      
      debugPrint('🗑️ [NOTIFICATION] Cleared all notifications');
    } catch (e) {
      debugPrint('❌ [NOTIFICATION] Failed to clear notifications: $e');
    }
  }

  // Payment-specific notification methods
  
  /// Notify when payment is received (for owners)
  static Future<void> notifyPaymentReceived({
    required String tenantName,
    required String roomNumber,
    required double amount,
    required String paymentType,
    required String transactionId,
  }) async {
    final user = AuthService.currentUser;
    if (user == null || !user.isOwner) return;

    final notification = AppNotification(
      id: 'payment_received_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Payment Received',
      message: '₹${amount.toStringAsFixed(0)} $paymentType payment received from $tenantName (Room $roomNumber)',
      type: NotificationType.paymentReceived,
      createdAt: DateTime.now(),
      data: {
        'tenantName': tenantName,
        'roomNumber': roomNumber,
        'amount': amount,
        'paymentType': paymentType,
        'transactionId': transactionId,
      },
      actionUrl: '/payments',
    );

    await addNotification(notification);
  }

  /// Notify when payment is pending (for owners)
  static Future<void> notifyPaymentPending({
    required String tenantName,
    required String roomNumber,
    required double amount,
    required String paymentType,
    required DateTime dueDate,
  }) async {
    final user = AuthService.currentUser;
    if (user == null || !user.isOwner) return;

    final notification = AppNotification(
      id: 'payment_pending_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Payment Pending',
      message: '₹${amount.toStringAsFixed(0)} $paymentType payment pending from $tenantName (Room $roomNumber)',
      type: NotificationType.paymentPending,
      createdAt: DateTime.now(),
      data: {
        'tenantName': tenantName,
        'roomNumber': roomNumber,
        'amount': amount,
        'paymentType': paymentType,
        'dueDate': dueDate.toIso8601String(),
      },
      actionUrl: '/payments',
    );

    await addNotification(notification);
  }

  /// Notify when payment is overdue (for owners)
  static Future<void> notifyPaymentOverdue({
    required String tenantName,
    required String roomNumber,
    required double amount,
    required String paymentType,
    required int daysPastDue,
  }) async {
    final user = AuthService.currentUser;
    if (user == null || !user.isOwner) return;

    final notification = AppNotification(
      id: 'payment_overdue_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Payment Overdue',
      message: '₹${amount.toStringAsFixed(0)} $paymentType payment from $tenantName (Room $roomNumber) is $daysPastDue days overdue',
      type: NotificationType.paymentOverdue,
      createdAt: DateTime.now(),
      data: {
        'tenantName': tenantName,
        'roomNumber': roomNumber,
        'amount': amount,
        'paymentType': paymentType,
        'daysPastDue': daysPastDue,
      },
      actionUrl: '/payments',
    );

    await addNotification(notification);
  }

  /// Notify when payment fails (for tenants)
  static Future<void> notifyPaymentFailed({
    required double amount,
    required String paymentType,
    required String reason,
    required String transactionId,
  }) async {
    final user = AuthService.currentUser;
    if (user == null || !user.isTenant) return;

    final notification = AppNotification(
      id: 'payment_failed_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Payment Failed',
      message: '₹${amount.toStringAsFixed(0)} $paymentType payment failed. Reason: $reason',
      type: NotificationType.paymentFailed,
      createdAt: DateTime.now(),
      data: {
        'amount': amount,
        'paymentType': paymentType,
        'reason': reason,
        'transactionId': transactionId,
      },
      actionUrl: '/tenant-payments',
    );

    await addNotification(notification);
  }

  /// Notify payment reminder (for tenants)
  static Future<void> notifyPaymentReminder({
    required double amount,
    required String paymentType,
    required DateTime dueDate,
    required int daysUntilDue,
  }) async {
    final user = AuthService.currentUser;
    if (user == null || !user.isTenant) return;

    final notification = AppNotification(
      id: 'payment_reminder_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Payment Reminder',
      message: '₹${amount.toStringAsFixed(0)} $paymentType payment due in $daysUntilDue days',
      type: NotificationType.paymentReminder,
      createdAt: DateTime.now(),
      data: {
        'amount': amount,
        'paymentType': paymentType,
        'dueDate': dueDate.toIso8601String(),
        'daysUntilDue': daysUntilDue,
      },
      actionUrl: '/tenant-payments',
    );

    await addNotification(notification);
  }

  /// Notify when payment is successful (for tenants)
  static Future<void> notifyPaymentSuccess({
    required double amount,
    required String paymentType,
    required String transactionId,
    required String receiptNumber,
  }) async {
    final user = AuthService.currentUser;
    if (user == null || !user.isTenant) return;

    final notification = AppNotification(
      id: 'payment_success_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Payment Successful',
      message: '₹${amount.toStringAsFixed(0)} $paymentType payment completed successfully',
      type: NotificationType.paymentReceived,
      createdAt: DateTime.now(),
      data: {
        'amount': amount,
        'paymentType': paymentType,
        'transactionId': transactionId,
        'receiptNumber': receiptNumber,
      },
      actionUrl: '/tenant-payments',
    );

    await addNotification(notification);
  }

  // General notification methods

  /// Show in-app notification (SnackBar)
  static void showInAppNotification(
    BuildContext context,
    AppNotification notification,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(notification.message),
          ],
        ),
        backgroundColor: notification.color,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to notification action URL if available
            if (notification.actionUrl != null) {
              // Implement navigation logic here
              debugPrint('Navigate to: ${notification.actionUrl}');
            }
          },
        ),
      ),
    );
  }
}
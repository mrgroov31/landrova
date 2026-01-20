import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import 'package:intl/intl.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, unread, payment, general

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await NotificationService.initialize();
      setState(() {
        _notifications = NotificationService.notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<AppNotification> get _filteredNotifications {
    switch (_filter) {
      case 'unread':
        return _notifications.where((n) => !n.isRead).toList();
      case 'payment':
        return _notifications.where((n) => 
          n.type == NotificationType.paymentReceived ||
          n.type == NotificationType.paymentPending ||
          n.type == NotificationType.paymentOverdue ||
          n.type == NotificationType.paymentFailed ||
          n.type == NotificationType.paymentReminder
        ).toList();
      case 'general':
        return _notifications.where((n) => 
          n.type == NotificationType.general ||
          n.type == NotificationType.tenantRegistered ||
          n.type == NotificationType.complaintCreated ||
          n.type == NotificationType.maintenanceScheduled
        ).toList();
      default:
        return _notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.getSurfaceColor(context),
        foregroundColor: AppTheme.getTextPrimaryColor(context),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          // Mark all as read button
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _notifications.any((n) => !n.isRead) ? () async {
              await NotificationService.markAllAsRead();
              await _loadNotifications();
            } : null,
            tooltip: 'Mark all as read',
          ),
          // Clear all button
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'clear_all':
                  await _showClearAllDialog();
                  break;
                case 'clear_read':
                  await _clearReadNotifications();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_read',
                child: Row(
                  children: [
                    Icon(Icons.clear),
                    SizedBox(width: 8),
                    Text('Clear read'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear all', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Unread', 'unread'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Payments', 'payment'),
                  const SizedBox(width: 8),
                  _buildFilterChip('General', 'general'),
                ],
              ),
            ),
          ),
          
          // Notifications list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotifications.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadNotifications,
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 16 : 24,
                            vertical: 8,
                          ),
                          itemCount: _filteredNotifications.length,
                          itemBuilder: (context, index) {
                            final notification = _filteredNotifications[index];
                            return _buildNotificationCard(notification);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    final count = value == 'all' 
        ? _notifications.length
        : value == 'unread'
            ? _notifications.where((n) => !n.isRead).length
            : value == 'payment'
                ? _notifications.where((n) => 
                    n.type == NotificationType.paymentReceived ||
                    n.type == NotificationType.paymentPending ||
                    n.type == NotificationType.paymentOverdue ||
                    n.type == NotificationType.paymentFailed ||
                    n.type == NotificationType.paymentReminder
                  ).length
                : _notifications.where((n) => 
                    n.type == NotificationType.general ||
                    n.type == NotificationType.tenantRegistered ||
                    n.type == NotificationType.complaintCreated ||
                    n.type == NotificationType.maintenanceScheduled
                  ).length;

    return FilterChip(
      label: Text('$label${count > 0 ? ' ($count)' : ''}'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = value;
        });
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: notification.isRead 
          ? AppTheme.getSurfaceColor(context)
          : AppTheme.primaryColor.withOpacity(0.05),
      child: InkWell(
        onTap: () async {
          if (!notification.isRead) {
            await NotificationService.markAsRead(notification.id);
            await _loadNotifications();
          }
          
          // Handle navigation if actionUrl is provided
          if (notification.actionUrl != null) {
            // Implement navigation logic here
            debugPrint('Navigate to: ${notification.actionUrl}');
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: notification.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  notification.icon,
                  color: notification.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead 
                                  ? FontWeight.w500 
                                  : FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.getTextPrimaryColor(context),
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getTextSecondaryColor(context),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateFormat.format(notification.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getTextSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Actions menu
              PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'mark_read':
                      await NotificationService.markAsRead(notification.id);
                      await _loadNotifications();
                      break;
                    case 'delete':
                      await NotificationService.deleteNotification(notification.id);
                      await _loadNotifications();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (!notification.isRead)
                    const PopupMenuItem(
                      value: 'mark_read',
                      child: Row(
                        children: [
                          Icon(Icons.done),
                          SizedBox(width: 8),
                          Text('Mark as read'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;
    
    switch (_filter) {
      case 'unread':
        message = 'No unread notifications';
        icon = Icons.done_all;
        break;
      case 'payment':
        message = 'No payment notifications';
        icon = Icons.payment;
        break;
      case 'general':
        message = 'No general notifications';
        icon = Icons.info;
        break;
      default:
        message = 'No notifications yet';
        icon = Icons.notifications_none;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppTheme.getTextSecondaryColor(context),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.getTextSecondaryColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifications will appear here when you receive them',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.getTextSecondaryColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _showClearAllDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await NotificationService.clearAll();
      await _loadNotifications();
    }
  }

  Future<void> _clearReadNotifications() async {
    final readNotifications = _notifications.where((n) => n.isRead).toList();
    
    for (final notification in readNotifications) {
      await NotificationService.deleteNotification(notification.id);
    }
    
    await _loadNotifications();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cleared ${readNotifications.length} read notifications'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
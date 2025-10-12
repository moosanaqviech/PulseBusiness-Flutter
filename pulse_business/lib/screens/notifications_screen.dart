// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'info', 'success', 'warning', 'error'
  final String? actionUrl;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.type = 'info',
    this.actionUrl,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    // Simulate loading notifications
    // TODO: Replace with actual Firebase/API call
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        notifications = _getMockNotifications();
        isLoading = false;
      });
    });
  }

  List<NotificationItem> _getMockNotifications() {
    return [
      NotificationItem(
        id: '1',
        title: 'Welcome to Pulse!',
        message: 'Thanks for joining Pulse. Start creating deals to attract customers!',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        type: 'success',
      ),
      NotificationItem(
        id: '2',
        title: 'Deal Performance Update',
        message: 'Your "Special Lunch Deal" has been viewed 25 times today.',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        type: 'info',
        isRead: true,
      ),
      NotificationItem(
        id: '3',
        title: 'Payment Received',
        message: 'You received \$12.50 from a deal redemption.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
        type: 'success',
        isRead: true,
      ),
      NotificationItem(
        id: '4',
        title: 'Complete Your Profile',
        message: 'Add business hours and photos to attract more customers.',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        type: 'warning',
      ),
    ];
  }

  void _markAsRead(String notificationId) {
    setState(() {
      final index = notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        notifications[index] = NotificationItem(
          id: notifications[index].id,
          title: notifications[index].title,
          message: notifications[index].message,
          timestamp: notifications[index].timestamp,
          isRead: true,
          type: notifications[index].type,
          actionUrl: notifications[index].actionUrl,
        );
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      notifications = notifications.map((n) => NotificationItem(
        id: n.id,
        title: n.title,
        message: n.message,
        timestamp: n.timestamp,
        isRead: true,
        type: n.type,
        actionUrl: n.actionUrl,
      )).toList();
    });
  }

  void _deleteNotification(String notificationId) {
    setState(() {
      notifications.removeWhere((n) => n.id == notificationId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification deleted'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all as read',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationItem(notification);
                  },
                ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    IconData getIcon() {
      switch (notification.type) {
        case 'success':
          return Icons.check_circle;
        case 'warning':
          return Icons.warning;
        case 'error':
          return Icons.error;
        default:
          return Icons.info;
      }
    }

    Color getColor() {
      switch (notification.type) {
        case 'success':
          return Colors.green;
        case 'warning':
          return Colors.orange;
        case 'error':
          return Colors.red;
        default:
          return Colors.blue;
      }
    }

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) => _deleteNotification(notification.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: getColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              getIcon(),
              color: getColor(),
              size: 20,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(notification.message),
              const SizedBox(height: 4),
              Text(
                _formatTimestamp(notification.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          trailing: notification.isRead
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
          onTap: () {
            if (!notification.isRead) {
              _markAsRead(notification.id);
            }
            // TODO: Handle notification tap action
            if (notification.actionUrl != null) {
              // Navigate to specific screen based on actionUrl
            }
          },
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
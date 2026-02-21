// Flutter Notification Integration Example
// Copy these files into your Flutter project

// ============================================
// 1. MODEL: notification_model.dart
// ============================================

class NotificationModel {
  final int id;
  final int customerId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final int? relatedId;
  final String? relatedType;
  final String createdAt;

  NotificationModel({
    required this.id,
    required this.customerId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.relatedId,
    this.relatedType,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      customerId: json['customer_id'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      isRead: json['is_read'] == true || json['is_read'] == 1,
      relatedId: json['related_id'],
      relatedType: json['related_type'],
      createdAt: json['created_at'],
    );
  }

  // Get icon based on notification type
  String getIcon() {
    switch (type) {
      case 'order':
        return '📦';
      case 'payment':
        return '💰';
      case 'delivery':
        return '🚚';
      case 'system':
        return '🔔';
      case 'account':
        return '👤';
      default:
        return '📋';
    }
  }

  // Get color based on notification type
  String getColorHex() {
    switch (type) {
      case 'order':
        return '#4CAF50';
      case 'payment':
        return '#2196F3';
      case 'delivery':
        return '#FF9800';
      case 'system':
        return '#9C27B0';
      case 'account':
        return '#F44336';
      default:
        return '#757575';
    }
  }
}

// ============================================
// 2. SERVICE: notification_service.dart
// ============================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String baseUrl = 'http://ruyadream.com/velox/api/notifications.php';

  // Fetch all notifications
  static Future<Map<String, dynamic>> fetchNotifications({
    required int customerId,
    bool? isRead,
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    String url = '$baseUrl?customer_id=$customerId&limit=$limit&offset=$offset';
    
    if (isRead != null) {
      url += '&is_read=${isRead ? 1 : 0}';
    }
    
    if (type != null && type.isNotEmpty) {
      url += '&type=$type';
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return {
            'success': true,
            'notifications': (data['data']['notifications'] as List)
                .map((json) => NotificationModel.fromJson(json))
                .toList(),
            'total_count': data['data']['total_count'],
            'unread_count': data['data']['unread_count'],
          };
        }
      }
      
      return {'success': false, 'message': 'Failed to load notifications'};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Get unread count only
  static Future<int> getUnreadCount(int customerId) async {
    final result = await fetchNotifications(
      customerId: customerId,
      limit: 1, // We only need the count
    );
    
    return result['unread_count'] ?? 0;
  }

  // Mark notification as read
  static Future<bool> markAsRead(int customerId, int notificationId) async {
    final url = '$baseUrl?customer_id=$customerId';

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'notification_id': notificationId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
      
      return false;
    } catch (e) {
      print('Error marking as read: $e');
      return false;
    }
  }

  // Mark all as read
  static Future<bool> markAllAsRead(int customerId) async {
    final url = '$baseUrl?customer_id=$customerId';

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'mark_all_read': true}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] ?? false;
      }
      
      return false;
    } catch (e) {
      print('Error marking all as read: $e');
      return false;
    }
  }
}

// ============================================
// 3. SCREEN: notifications_screen.dart
// ============================================

import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  final int customerId;

  const NotificationsScreen({Key? key, required this.customerId}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> notifications = [];
  int unreadCount = 0;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await NotificationService.fetchNotifications(
      customerId: widget.customerId,
    );

    setState(() {
      isLoading = false;
      if (result['success']) {
        notifications = result['notifications'];
        unreadCount = result['unread_count'];
      } else {
        errorMessage = result['message'];
      }
    });
  }

  Future<void> markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      final success = await NotificationService.markAsRead(
        widget.customerId,
        notification.id,
      );

      if (success) {
        await loadNotifications(); // Refresh list
      }
    }

    // Navigate to related item if available
    if (notification.relatedType == 'order' && notification.relatedId != null) {
      // Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: notification.relatedId!)));
    }
  }

  Future<void> markAllAsRead() async {
    final success = await NotificationService.markAllAsRead(widget.customerId);
    if (success) {
      await loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: markAllAsRead,
              icon: Icon(Icons.done_all, color: Colors.white),
              label: Text('Mark all read', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadNotifications,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(child: Text(errorMessage!, style: TextStyle(color: Colors.red)))
                : notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none, size: 80, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No notifications yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final notification = notifications[index];
                          return NotificationTile(
                            notification: notification,
                            onTap: () => markAsRead(notification),
                          );
                        },
                      ),
      ),
    );
  }
}

// ============================================
// 4. WIDGET: notification_tile.dart
// ============================================

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationTile({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: notification.isRead ? Colors.white : Colors.blue.shade50,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getColor(),
          child: Text(
            notification.getIcon(),
            style: TextStyle(fontSize: 24),
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
            SizedBox(height: 4),
            Text(notification.message),
            SizedBox(height: 4),
            Text(
              _formatDate(notification.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: onTap,
      ),
    );
  }

  Color _getColor() {
    return Color(int.parse(notification.getColorHex().replaceFirst('#', '0xFF')));
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Just now';
          }
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }
}

// ============================================
// 5. BADGE WIDGET: notification_badge.dart
// ============================================

class NotificationBadge extends StatefulWidget {
  final int customerId;

  const NotificationBadge({Key? key, required this.customerId}) : super(key: key);

  @override
  _NotificationBadgeState createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    loadUnreadCount();
  }

  Future<void> loadUnreadCount() async {
    final count = await NotificationService.getUnreadCount(widget.customerId);
    setState(() {
      unreadCount = count;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        children: [
          Icon(Icons.notifications),
          if (unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Center(
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NotificationsScreen(customerId: widget.customerId),
          ),
        );
        loadUnreadCount(); // Refresh count when returning
      },
    );
  }
}

// ============================================
// 6. USAGE EXAMPLE
// ============================================

// In your AppBar:
// AppBar(
//   title: Text('Home'),
//   actions: [
//     NotificationBadge(customerId: currentUser.id),
//   ],
// )

// To navigate to notifications screen:
// Navigator.push(
//   context,
//   MaterialPageRoute(
//     builder: (_) => NotificationsScreen(customerId: currentUser.id),
//   ),
// );


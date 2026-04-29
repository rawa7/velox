import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../models/notification_model.dart';
import '../generated/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  User? _user;
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      _user = await StorageService.getUser();
      if (_user != null) {
        final result = await ApiService.getNotifications(customerId: _user!.id);
        if (result['success'] == true && result['data'] != null) {
          final data = result['data'] as NotificationData;
          _notifications = data.notifications;
          _unreadCount = data.unreadCount;
        }
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }

    // Same as tapping "Mark all read": clear server unread state when opening this screen.
    if (mounted && _user != null && _unreadCount > 0) {
      await _markAllAsRead();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(NotificationItem notification) async {
    if (_user == null || notification.isRead) return;

    final result = await ApiService.markNotificationAsRead(
      customerId: _user!.id,
      notificationId: notification.id,
    );

    if (result['success'] == true) {
      setState(() {
        // Update the notification in the list
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = NotificationItem(
            id: notification.id,
            customerId: notification.customerId,
            title: notification.title,
            message: notification.message,
            type: notification.type,
            isRead: true,
            relatedId: notification.relatedId,
            relatedType: notification.relatedType,
            createdAt: notification.createdAt,
          );
          _unreadCount = (_unreadCount > 0) ? _unreadCount - 1 : 0;
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (_user == null) return;

    final result = await ApiService.markAllNotificationsAsRead(customerId: _user!.id);
    if (result['success'] == true) {
      setState(() {
        _notifications = _notifications.map((n) => NotificationItem(
          id: n.id,
          customerId: n.customerId,
          title: n.title,
          message: n.message,
          type: n.type,
          isRead: true,
          relatedId: n.relatedId,
          relatedType: n.relatedType,
          createdAt: n.createdAt,
        )).toList();
        _unreadCount = 0;
      });
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return Icons.shopping_bag_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'delivery':
        return Icons.local_shipping_outlined;
      case 'promo':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type.toLowerCase()) {
      case 'order':
        return AppColors.primary;
      case 'payment':
        return AppColors.success;
      case 'delivery':
        return AppColors.info;
      case 'promo':
        return AppColors.primary;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTimestamp(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.surfaceColor,
        foregroundColor: context.textPrimaryColor,
        elevation: 0,
        title: Row(
          children: [
            Text(AppLocalizations.of(context)!.notifications, style: TextStyle(color: context.textPrimaryColor)),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: AppColors.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _notifications.isEmpty
                ? _buildEmptyState(l10n)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationCard(_notifications[index]);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: context.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifications will appear here',
            style: TextStyle(
              fontSize: 14,
              color: context.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    final iconColor = _getNotificationColor(notification.type);
    final icon = _getNotificationIcon(notification.type);

    return GestureDetector(
      onTap: () => _markAsRead(notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: notification.isRead ? context.surfaceColor : AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead ? context.borderColor : AppColors.primary.withOpacity(0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
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
                            fontSize: 15,
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.textSecondaryColor,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimestamp(notification.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: context.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

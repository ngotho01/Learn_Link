import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/notification_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: AppColors.textPrimary),
            onSelected: (value) async {
              if (value == 'mark_all_read') {
                await _notificationService.markAllAsRead();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('All notifications marked as read'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } else if (value == 'test') {
                await _notificationService.createTestNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Test notification created'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.done_all_rounded, size: 20, color: AppColors.primary),
                    SizedBox(width: AppSpacing.sm),
                    Text('Mark all as read'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'test',
                child: Row(
                  children: [
                    Icon(Icons.science_rounded, size: 20, color: AppColors.accent),
                    SizedBox(width: AppSpacing.sm),
                    Text('Send test notification'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notificationService.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState();
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: EdgeInsets.all(AppSpacing.md),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final bool isRead = notification['read'] ?? false;
    final String type = notification['type'] ?? 'general';
    final String title = notification['title'] ?? 'Notification';
    final String body = notification['body'] ?? '';
    final Timestamp? timestamp = notification['created_at'];
    final String notificationId = notification['id'];

    return Dismissible(
      key: Key(notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
        ),
        child: Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (direction) async {
        await _notificationService.deleteNotification(notificationId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notification deleted'),
              backgroundColor: AppColors.error,
              action: SnackBarAction(
                label: 'Undo',
                textColor: Colors.white,
                onPressed: () {
                  // Implement undo if needed
                },
              ),
            ),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(bottom: AppSpacing.md),
        decoration: BoxDecoration(
          color: isRead ? AppColors.surface : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: isRead ? AppColors.border : AppColors.primary.withValues(alpha: 0.2),
            width: isRead ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppBorderRadius.md),
            onTap: () async {
              if (!isRead) {
                await _notificationService.markAsRead(notificationId);
              }
              // Handle notification tap - navigate to relevant screen
              _handleNotificationTap(type);
            },
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: _getNotificationColor(type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                    ),
                    child: Icon(
                      _getNotificationIcon(type),
                      color: _getNotificationColor(type),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          body,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          _formatTimestamp(timestamp),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'We\'ll notify you when something arrives',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 64,
            color: AppColors.error,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            'Failed to load notifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => setState(() {}),
            icon: Icon(Icons.refresh_rounded),
            label: Text('Retry'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'job':
        return Icons.work_rounded;
      case 'news':
        return Icons.article_rounded;
      case 'learning':
        return Icons.school_rounded;
      case 'achievement':
        return Icons.emoji_events_rounded;
      case 'reminder':
        return Icons.alarm_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'job':
        return AppColors.primary;
      case 'news':
        return AppColors.accent;
      case 'learning':
        return AppColors.secondary;
      case 'achievement':
        return AppColors.warning;
      case 'reminder':
        return AppColors.success;
      default:
        return AppColors.primary;
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';

    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _handleNotificationTap(String type) {
    // Navigate based on notification type
    switch (type) {
      case 'job':
        Navigator.pushNamed(context, '/jobs');
        break;
      case 'news':
        Navigator.pushNamed(context, '/news');
        break;
      case 'learning':
        Navigator.pushNamed(context, '/learning');
        break;
      default:
        break;
    }
  }
}
import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/custom_app_bar.dart';
// import 'dart:io';
import '../services/event_bus_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _notificationService = NotificationService();
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() => _isLoading = true);
      final notifications = await _notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading notifications: $e')),
        );
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Notifikasi'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada notifikasi',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.surfaceVariant,
                          backgroundImage:
                              notification.senderProfileImage != null
                                  ? CachedNetworkImageProvider(
                                      EventBusService().getProfileImageUrl(
                                        notification.senderId,
                                        notification.senderProfileImage,
                                      ),
                                    )
                                  : null,
                          child: notification.senderProfileImage == null
                              ? Icon(
                                  Icons.person,
                                  color: colorScheme.onSurfaceVariant,
                                )
                              : null,
                        ),
                        title: RichText(
                          text: TextSpan(
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                            children: [
                              TextSpan(
                                text: notification.senderName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: ' ${notification.content}',
                              ),
                            ],
                          ),
                        ),
                        subtitle: Text(
                          _getTimeAgo(notification.createdAt),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: notification.isRead
                            ? null
                            : Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: colorScheme.primary,
                                ),
                              ),
                        onTap: () {
                          if (!notification.isRead) {
                            _notificationService.markAsRead(notification.id);
                            setState(() {
                              _notifications[index] = NotificationItem(
                                id: notification.id,
                                type: notification.type,
                                postId: notification.postId,
                                senderId: notification.senderId,
                                senderName: notification.senderName,
                                senderProfileImage:
                                    notification.senderProfileImage,
                                createdAt: notification.createdAt,
                                isRead: true,
                                content: notification.content,
                              );
                            });
                          }
                          // Navigate to the post
                          // TODO: Implement post navigation
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

import 'package:flutter/material.dart';

class NotificationItem {
  final String title;
  final String message;
  final DateTime time;
  final bool isRead;
  final String type; // 'like' or 'agenda'
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
    required this.type,
    this.data,
  });
}

class NotificationManager extends ChangeNotifier {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;

  NotificationManager._internal();

  final List<NotificationItem> _notifications = [];

  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotification(NotificationItem notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }

  void markAsRead(int index) {
    if (index >= 0 && index < _notifications.length) {
      final notification = _notifications[index];
      _notifications[index] = NotificationItem(
        title: notification.title,
        message: notification.message,
        time: notification.time,
        isRead: true,
        type: notification.type,
        data: notification.data,
      );
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      final notification = _notifications[i];
      _notifications[i] = NotificationItem(
        title: notification.title,
        message: notification.message,
        time: notification.time,
        isRead: true,
        type: notification.type,
        data: notification.data,
      );
    }
    notifyListeners();
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}

class NotificationItem {
  final int id;
  final String type; // 'like' or 'comment'
  final int postId;
  final int senderId;
  final String senderName;
  final String? senderProfileImage;
  final DateTime createdAt;
  final bool isRead;
  final String content;

  NotificationItem({
    required this.id,
    required this.type,
    required this.postId,
    required this.senderId,
    required this.senderName,
    this.senderProfileImage,
    required this.createdAt,
    required this.isRead,
    required this.content,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int,
      type: json['type'] as String,
      postId: json['post_id'] as int,
      senderId: json['sender_id'] as int,
      senderName: json['sender_name'] as String,
      senderProfileImage: json['sender_profile_image'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isRead: json['is_read'] as bool,
      content: json['content'] as String,
    );
  }
}

import 'dart:io';

class PostComment {
  final int id;
  final int postId;
  final int profileId;
  final String content;
  final DateTime createdAt;
  final String fullName;
  final String? profileImage;
  final int currentUserId;

  PostComment({
    required this.id,
    required this.postId,
    required this.profileId,
    required this.content,
    required this.createdAt,
    required this.fullName,
    this.profileImage,
    required this.currentUserId,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'] as int,
      postId: json['post_id'] as int,
      profileId: json['profile_id'] as int,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      fullName: json['full_name'] as String,
      profileImage: json['profile_image']?.toString(),
      currentUserId: json['current_user_id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'profile_id': profileId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'full_name': fullName,
      'profile_image': profileImage,
      'current_user_id': currentUserId,
    };
  }

  String getProfileImageUrl() {
    if (profileImage == null || profileImage!.isEmpty) return '';
    final baseUrl =
        Platform.isAndroid ? 'http://10.0.2.2:5000' : 'http://localhost:5000';
    return '$baseUrl/uploads/profiles/$profileId/$profileImage';
  }
}

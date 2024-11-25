import 'dart:io';
import 'post_comment.dart';

class SiswaPost {
  final int id;
  final int profileId;
  final String caption;
  final List<Map<String, dynamic>> images;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final String fullName;
  final String? profileImage;
  final String title;
  final PostComment? latestComment;

  SiswaPost({
    required this.id,
    required this.profileId,
    required this.caption,
    required this.images,
    required this.createdAt,
    required this.likesCount,
    this.commentsCount = 0,
    required this.isLiked,
    required this.fullName,
    this.profileImage,
    required this.title,
    this.latestComment,
  });

  factory SiswaPost.fromJson(Map<String, dynamic> json) {
    try {
      print('Processing post JSON: $json'); // Debug log

      return SiswaPost(
        id: json['id'] as int,
        profileId: json['profile_id'] as int,
        caption: json['caption']?.toString() ?? '',
        images: (json['images'] as List<dynamic>?)
                ?.map((img) => img as Map<String, dynamic>)
                .toList() ??
            [],
        createdAt: DateTime.parse(json['created_at'] as String),
        likesCount: json['likes_count'] as int? ?? 0,
        commentsCount: int.tryParse(json['comments_count'].toString()) ?? 0,
        isLiked: json['is_liked'] as bool? ?? false,
        fullName: json['full_name']?.toString() ?? '',
        profileImage: json['profile_image']?.toString(),
        title: json['title']?.toString() ?? '',
        latestComment: json['latest_comment'] != null
            ? PostComment.fromJson(json['latest_comment'])
            : null,
      );
    } catch (e) {
      print('Error parsing post: $e');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'caption': caption,
      'images': images,
      'created_at': createdAt.toIso8601String(),
      'likes_count': likesCount,
      'comments_count': commentsCount,
      'is_liked': isLiked,
      'full_name': fullName,
      'profile_image': profileImage,
      'title': title,
      'latest_comment': latestComment?.toJson(),
    };
  }

  String getProfileImageUrl() {
    if (profileImage == null || profileImage!.isEmpty) return '';
    final baseUrl =
        Platform.isAndroid ? 'http://10.0.2.2:5000' : 'http://localhost:5000';

    // Log for debugging
    print('Profile image path: $profileImage');
    // Construct URL with profile ID path
    final fullUrl = '$baseUrl/uploads/profiles/$profileId/$profileImage';
    print('Full profile image URL: $fullUrl');

    return fullUrl;
  }

  String getImageUrl(Map<String, dynamic> image) {
    final filePath = image['file'] as String;
    if (filePath.isEmpty) return '';
    final baseUrl =
        Platform.isAndroid ? 'http://10.0.2.2:5000' : 'http://localhost:5000';

    // Log the image path for debugging
    print('Original file path: $filePath');

    // The filePath already contains the full path from the database
    // No need to add postSiswa prefix as it's already in the path
    final fullUrl = '$baseUrl/uploads/$filePath';

    print('Constructed URL: $fullUrl');
    return fullUrl;
  }
}

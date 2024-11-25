import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;

class LatestArticle {
  final int id;
  final String title;
  final String content;
  final String imageUrl;
  final String category;
  final DateTime date;

  LatestArticle({
    required this.id,
    required this.title,
    required this.content,
    required this.imageUrl,
    required this.category,
    required this.date,
  });

  factory LatestArticle.fromJson(Map<String, dynamic> json) {
    debugPrint('Parsing article JSON: $json');

    String extractThumbnail() {
      if (json['thumbnail'] != null) {
        debugPrint('Thumbnail data: ${json['thumbnail']}');
        return json['thumbnail'] ?? '';
      }
      if (json['gallery_images'] != null &&
          (json['gallery_images'] as List).isNotEmpty) {
        debugPrint('Gallery images: ${json['gallery_images']}');
        return json['gallery_images'][0] ?? '';
      }
      debugPrint('No thumbnail found');
      return '';
    }

    final article = LatestArticle(
      id: json['id'] as int? ?? 0,
      title: json['judul']?.toString() ?? '',
      content: json['isi']?.toString() ?? '',
      imageUrl: extractThumbnail(),
      category: json['kategori_judul']?.toString() ?? '',
      date: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );

    debugPrint(
        'Created article: ${article.title} with image: ${article.imageUrl}');
    return article;
  }

  String get excerpt {
    if (content.isEmpty) return '';
    final document = parse(content);
    final text = document.body?.text ?? '';
    return text.length > 100 ? '${text.substring(0, 100)}...' : text;
  }

  String get fullImageUrl {
    if (imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http')) return imageUrl;
    final cleanPath = imageUrl.replaceAll(RegExp(r'^/+'), '');
    return 'http://10.0.2.2:5000/uploads/$cleanPath';
  }

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }
}

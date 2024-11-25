import 'package:html/parser.dart' show parse;
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter/material.dart';

class Article {
  final int id;
  final String title;
  final String content;
  final String excerpt;
  final String category;
  final int categoryId;
  final String imageUrl;
  final DateTime date;
  final List<String> galleryImages;
  final String formattedDate;

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.excerpt,
    required this.category,
    required this.categoryId,
    required this.imageUrl,
    required this.date,
    required this.galleryImages,
    required this.formattedDate,
  });

  String get fullImageUrl => _getFullUrl(imageUrl);
  List<String> get fullGalleryImages =>
      galleryImages.map((img) => _getFullUrl(img)).toList();

  // Clean HTML content
  String get cleanContent {
    if (content.isEmpty) return '';
    final document = parse(content);
    return document.body?.text ?? '';
  }

  // Clean excerpt
  String get cleanExcerpt {
    if (excerpt.isEmpty) return '';
    final document = parse(excerpt);
    final text = document.body?.text ?? '';
    return text.length > 100 ? '${text.substring(0, 100)}...' : text;
  }

  static String _getFullUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    final cleanPath = path.replaceAll(RegExp(r'^/+'), '');
    debugPrint('Constructing URL for path: $cleanPath');
    return 'http://10.0.2.2:5000/uploads/$cleanPath';
  }

  // Get formatted HTML content
  Widget getFormattedContent(BuildContext context) {
    return Html(
      data: content,
      style: {
        "p": Style(
          margin: Margins(bottom: Margin(16)),
          lineHeight: LineHeight.number(1.5),
        ),
        "body": Style(
          fontSize: FontSize(16.0),
          fontFamily: 'Roboto',
          padding: HtmlPaddings.zero,
          margin: Margins.zero,
        ),
      },
      onAnchorTap: (url, _, __) {
        if (url != null) {
          // Handle link taps
          debugPrint('Tapped link: $url');
        }
      },
    );
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    try {
      // Extract gallery images
      List<String> extractGalleryImages() {
        if (json['gallery_images'] == null) return [];
        final List<dynamic> images = json['gallery_images'] as List;
        return images.map((img) => img.toString()).toList();
      }

      // Extract thumbnail/first image
      String extractThumbnail() {
        if (json['thumbnail'] != null) {
          return json['thumbnail'].toString();
        }
        final galleryImages = extractGalleryImages();
        return galleryImages.isNotEmpty ? galleryImages.first : '';
      }

      // Create excerpt from content
      String createExcerpt(String content) {
        final document = parse(content);
        final text = document.body?.text ?? '';
        return text.length > 100 ? '${text.substring(0, 100)}...' : text;
      }

      return Article(
        id: json['id'] as int? ?? 0,
        title: json['judul']?.toString() ?? '',
        content: json['isi']?.toString() ?? '',
        excerpt: createExcerpt(json['isi']?.toString() ?? ''),
        category: json['kategori_judul']?.toString() ?? '',
        categoryId: json['kategori_id'] as int? ?? 0,
        imageUrl: extractThumbnail(),
        date: DateTime.parse(
            json['created_at'] ?? DateTime.now().toIso8601String()),
        galleryImages: extractGalleryImages(),
        formattedDate: _formatDate(DateTime.parse(
            json['created_at'] ?? DateTime.now().toIso8601String())),
      );
    } catch (e, stackTrace) {
      debugPrint('Error parsing Article: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Problematic JSON: $json');
      rethrow;
    }
  }

  String get formattedFullDate {
    return '${date.day}/${date.month}/${date.year} ${_formatTime(date)}';
  }

  static String _formatTime(DateTime date) {
    String hours = date.hour.toString().padLeft(2, '0');
    String minutes = date.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

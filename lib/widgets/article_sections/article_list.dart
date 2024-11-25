import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../models/article.dart';
import 'article_detail_modal.dart';
import '../../services/event_bus_service.dart';
import 'dart:async';
import '../../services/article_service.dart';

final Map<String, Color> categoryColors = {
  'Prestasi': Colors.green,
  'Dokumentasi': Colors.blue,
  'Kegiatan/Acara': Colors.orange,
  'default': Colors.grey,
};

class ArticleList extends StatefulWidget {
  final int? selectedCategoryId;

  const ArticleList({
    super.key,
    this.selectedCategoryId,
  });

  @override
  State<ArticleList> createState() => _ArticleListState();
}

class _ArticleListState extends State<ArticleList> {
  List<Article> _articles = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _articleUpdateSubscription;

  @override
  void initState() {
    super.initState();
    ArticleService().initialize();
    _fetchArticles();

    // Listen for article updates
    _articleUpdateSubscription =
        EventBusService().articleUpdates.listen((event) {
      if (mounted) {
        setState(() {
          if (widget.selectedCategoryId == null) {
            _articles = event.articles;
          } else {
            _articles = event.articles
                .where((article) =>
                    article.categoryId == widget.selectedCategoryId)
                .toList();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    ArticleService().dispose();
    _articleUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _fetchArticles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final String baseUrl =
          Platform.isAndroid ? 'http://10.0.2.2:5000' : 'http://localhost:5000';

      debugPrint('Fetching articles from: $baseUrl/api/mobile/posts');

      final response = await http.get(
        Uri.parse('$baseUrl/api/mobile/posts'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final allArticles = data.map((json) => Article.fromJson(json)).toList();

        setState(() {
          if (widget.selectedCategoryId == null) {
            _articles = allArticles;
          } else {
            _articles = allArticles
                .where((article) =>
                    article.categoryId == widget.selectedCategoryId)
                .toList();
          }
          _isLoading = false;
        });
      } else {
        throw Exception(
            'Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching articles: $e');
      setState(() {
        _error = 'Failed to load articles. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_articles.isEmpty) {
      return const Center(
        child: Text('Tidak ada artikel'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _articles.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final article = _articles[index];
        return _ArticleCard(article: article);
      },
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final Article article;

  const _ArticleCard({required this.article});

  void _showArticleDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ArticleDetailModal(article: article),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Get category color or use default
    final categoryColor =
        categoryColors[article.category] ?? categoryColors['default']!;

    return InkWell(
      onTap: () => _showArticleDetail(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section - Adjusted height
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 120,
                height: 90,
                child: Hero(
                  tag: 'article-image-${article.id}',
                  child: CachedNetworkImage(
                    imageUrl: article.fullImageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: colorScheme.surfaceVariant,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      debugPrint(
                          'Image error for article ${article.id}: $error');
                      debugPrint('Attempted URL: $url');
                      debugPrint('Original imageUrl: ${article.imageUrl}');
                      debugPrint('Full imageUrl: ${article.fullImageUrl}');

                      // Try to load a test image to verify the connection
                      final testUrl =
                          'http://10.0.2.2:5000/test-image/${article.imageUrl}';
                      debugPrint('Testing URL: $testUrl');

                      return Container(
                        color: colorScheme.surfaceVariant,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: colorScheme.error),
                            const SizedBox(height: 4),
                            FittedBox(
                              child: Text(
                                'Image Error\n${article.imageUrl}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 8,
                                  color: colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    httpHeaders: const {
                      'Accept': 'image/jpeg,image/png,image/jpg',
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Content section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category and date row
                  Row(
                    children: [
                      // Category badge with dynamic color
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: categoryColor.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          article.category,
                          style: textTheme.labelSmall?.copyWith(
                            color: categoryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        article.formattedDate,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Title
                  Text(
                    article.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Content preview
                  Text(
                    article.excerpt,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

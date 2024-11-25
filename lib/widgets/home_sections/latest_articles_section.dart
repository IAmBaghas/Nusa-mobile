import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../models/latest_article.dart';
import '../article_sections/article_detail_modal.dart';
import '../../models/article.dart';
import '../../screens/notification_screen.dart';
import '../../services/notification_service.dart';
import '../../models/notification_item.dart';
import '../../services/event_bus_service.dart';
import 'dart:async';
import '../../services/article_service.dart';

class LatestArticlesSection extends StatefulWidget {
  const LatestArticlesSection({super.key});

  @override
  State<LatestArticlesSection> createState() => _LatestArticlesSectionState();
}

class _LatestArticlesSectionState extends State<LatestArticlesSection> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<LatestArticle> _latestArticles = [];
  bool _isLoading = true;
  final _notificationService = NotificationService();
  List<NotificationItem> _recentNotifications = [];
  bool _hasUnreadNotifications = false;
  StreamSubscription? _articleUpdateSubscription;

  @override
  void initState() {
    super.initState();
    debugPrint('LatestArticlesSection initialized');
    ArticleService().initialize();
    _loadRecentNotifications();

    // Listen for article updates
    _articleUpdateSubscription =
        EventBusService().articleUpdates.listen((event) {
      if (mounted) {
        setState(() {
          _latestArticles = event.latestArticles;
          _isLoading = false;
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

  Future<void> _loadArticles() async {
    debugPrint('Starting to load articles');
    setState(() => _isLoading = true);

    try {
      final String baseUrl =
          Platform.isAndroid ? 'http://10.0.2.2:5000' : 'http://localhost:5000';

      debugPrint('Fetching from: $baseUrl/api/mobile/posts/latest');

      final response = await http.get(
        Uri.parse('$baseUrl/api/mobile/posts/latest'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint('Parsed data length: ${data.length}');

        if (data.isEmpty) {
          debugPrint('No articles returned from API');
          setState(() {
            _latestArticles = [];
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _latestArticles =
              data.map((json) => LatestArticle.fromJson(json)).toList();
          _isLoading = false;
        });

        debugPrint('Loaded ${_latestArticles.length} articles');
        debugPrint('First article: ${_latestArticles.first.title}');
      } else {
        debugPrint('Error response: ${response.body}');
        setState(() {
          _isLoading = false;
          _latestArticles = [];
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading articles: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
        _latestArticles = [];
      });
    }
  }

  Future<void> _loadRecentNotifications() async {
    try {
      final notifications = await _notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _recentNotifications = notifications.take(5).toList();
          _hasUnreadNotifications = _recentNotifications.any((n) => !n.isRead);
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  void _showArticleDetail(LatestArticle latestArticle) {
    final article = Article(
      id: latestArticle.id,
      title: latestArticle.title,
      content: latestArticle.content,
      excerpt: latestArticle.excerpt,
      category: latestArticle.category,
      categoryId: 0,
      imageUrl: latestArticle.imageUrl,
      date: latestArticle.date,
      galleryImages: [latestArticle.imageUrl],
      formattedDate: latestArticle.formattedDate,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ArticleDetailModal(article: article),
    );
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
    debugPrint(
        'Building LatestArticlesSection. Loading: $_isLoading, Articles: ${_latestArticles.length}');

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const SizedBox(
        height: 280,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_latestArticles.isEmpty) {
      debugPrint('No articles to display');
      return const SizedBox(
        height: 280,
        child: Center(
          child: Text('No articles available'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title with Notification Bell
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Informasi Terkini',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
              ),
              PopupMenuButton<NotificationItem>(
                position: PopupMenuPosition.under,
                offset: const Offset(0, 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (_hasUnreadNotifications)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                onSelected: (notification) {
                  // Handle notification tap
                  _notificationService.markAsRead(notification.id);
                  setState(() {
                    _recentNotifications = _recentNotifications.map((n) {
                      if (n.id == notification.id) {
                        return NotificationItem(
                          id: n.id,
                          type: n.type,
                          postId: n.postId,
                          senderId: n.senderId,
                          senderName: n.senderName,
                          senderProfileImage: n.senderProfileImage,
                          createdAt: n.createdAt,
                          isRead: true,
                          content: n.content,
                        );
                      }
                      return n;
                    }).toList();
                    _hasUnreadNotifications =
                        _recentNotifications.any((n) => !n.isRead);
                  });
                },
                itemBuilder: (context) => [
                  if (_recentNotifications.isEmpty)
                    PopupMenuItem(
                      enabled: false,
                      height: 100,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_none,
                              size: 32,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tidak ada notifikasi',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._recentNotifications.map((notification) => PopupMenuItem(
                          value: notification,
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 64),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: colorScheme.surfaceVariant,
                                  backgroundImage:
                                      notification.senderProfileImage != null
                                          ? CachedNetworkImageProvider(
                                              EventBusService()
                                                  .getProfileImageUrl(
                                                notification.senderId,
                                                notification.senderProfileImage,
                                              ),
                                            )
                                          : null,
                                  child: notification.senderProfileImage == null
                                      ? Icon(
                                          Icons.person,
                                          size: 16,
                                          color: colorScheme.onSurfaceVariant,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notification.senderName,
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          if (!notification.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notification.content,
                                        style: textTheme.bodySmall,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getTimeAgo(notification.createdAt),
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                  if (_recentNotifications.isNotEmpty) ...[
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      height: 48,
                      child: Center(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const NotificationScreen(),
                              ),
                            ).then((_) => _loadRecentNotifications());
                          },
                          child: const Text('Lihat Semua'),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // Article Slider
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _latestArticles.length,
            itemBuilder: (context, index) {
              final article = _latestArticles[index];
              return GestureDetector(
                onTap: () => _showArticleDetail(article),
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
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
                              debugPrint('Image error: $error');
                              debugPrint('URL: $url');
                              return Container(
                                color: colorScheme.surfaceVariant,
                                child: const Icon(Icons.error_outline),
                              );
                            },
                          ),
                        ),
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                        // Content
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  article.category,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                article.title,
                                style: textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                article.excerpt,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
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
                ),
              );
            },
          ),
        ),
        // Page Indicator
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _latestArticles.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? colorScheme.primary
                      : colorScheme.primary.withOpacity(0.2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

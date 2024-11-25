import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:async';
import '../models/article.dart';
import '../models/latest_article.dart';
import '../services/event_bus_service.dart';

class ArticleService {
  static final ArticleService _instance = ArticleService._internal();
  factory ArticleService() => _instance;
  ArticleService._internal();

  final String baseUrl = Platform.isAndroid
      ? 'http://10.0.2.2:5000/api'
      : 'http://localhost:5000/api';

  final _eventBus = EventBusService();
  Timer? _refreshTimer;

  // Initialize auto-refresh
  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      refreshArticles();
    });
  }

  // Stop auto-refresh
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> refreshArticles() async {
    try {
      // Fetch both regular and latest articles
      final articlesResponse = await http.get(
        Uri.parse('$baseUrl/mobile/posts'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      final latestArticlesResponse = await http.get(
        Uri.parse('$baseUrl/mobile/posts/latest'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (articlesResponse.statusCode == 200 &&
          latestArticlesResponse.statusCode == 200) {
        final List<dynamic> articlesData = json.decode(articlesResponse.body);
        final List<dynamic> latestArticlesData =
            json.decode(latestArticlesResponse.body);

        final articles =
            articlesData.map((json) => Article.fromJson(json)).toList();
        final latestArticles = latestArticlesData
            .map((json) => LatestArticle.fromJson(json))
            .toList();

        // Emit update event
        _eventBus.emitArticleUpdate(ArticleUpdateEvent(
          articles: articles,
          latestArticles: latestArticles,
        ));
      }
    } catch (e) {
      print('Error refreshing articles: $e');
    }
  }

  // Call this when the app starts
  void initialize() {
    startAutoRefresh();
    refreshArticles(); // Initial refresh
  }

  // Call this when the app is closed or paused
  void dispose() {
    stopAutoRefresh();
  }
}

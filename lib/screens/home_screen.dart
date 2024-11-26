import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/home_sections/agenda_section.dart';
import '../widgets/home_sections/latest_articles_section.dart';
import '../widgets/home_sections/main_page_posts_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String? _error;

  // Reference keys for child widgets to trigger their refresh
  final _latestArticlesKey = GlobalKey<LatestArticlesSectionState>();
  final _agendaKey = GlobalKey<AgendaSectionState>();
  final _mainPagePostsKey = GlobalKey<MainPagePostsSectionState>();

  Future<void> _handleRefresh() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Create a list of non-null futures
      final futures = <Future<void>>[];
      
      if (_latestArticlesKey.currentState != null) {
        futures.add(_latestArticlesKey.currentState!.loadData());
      }
      if (_agendaKey.currentState != null) {
        futures.add(_agendaKey.currentState!.loadData());
      }
      if (_mainPagePostsKey.currentState != null) {
        futures.add(_mainPagePostsKey.currentState!.loadData());
      }

      // Wait for all futures to complete
      await Future.wait(futures);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to refresh content. Please try again.';
          _isLoading = false;
        });
      }
      print('Error refreshing home screen: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building HomeScreen');

    return Scaffold(
      appBar: const CustomAppBar(),
      body: _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _handleRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Latest Articles Section
                        SizedBox(
                          height: 380,
                          child: LatestArticlesSection(key: _latestArticlesKey),
                        ),

                        const SizedBox(height: 10),

                        // Agenda Section
                        AgendaSection(key: _agendaKey),

                        const SizedBox(height: 10),
                        const Divider(height: 10),

                        // Main Page Posts Section
                        MainPagePostsSection(key: _mainPagePostsKey),

                        // Bottom padding
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                  if (_isLoading)
                    const Positioned.fill(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

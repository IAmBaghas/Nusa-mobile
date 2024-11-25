import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/home_sections/agenda_section.dart';
import '../widgets/home_sections/latest_articles_section.dart';
import '../widgets/home_sections/main_page_posts_section.dart';
import 'explore_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _handleRefresh() async {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Building HomeScreen');

    return Scaffold(
      appBar: const CustomAppBar(),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              // Latest Articles Section
              SizedBox(
                height: 380,
                child: LatestArticlesSection(),
              ),

              SizedBox(height: 10),

              // Agenda Section
              AgendaSection(),

              SizedBox(height: 10),
              Divider(height: 10),

              // Main Page Posts Section
              MainPagePostsSection(),

              // Bottom padding
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

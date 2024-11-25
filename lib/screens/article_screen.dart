import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/article_sections/article_list.dart';
import '../models/category.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ArticleScreen extends StatefulWidget {
  const ArticleScreen({super.key});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  int? _selectedCategoryId;
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await _fetchCategories();
    } catch (e) {
      print('Error refreshing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui data'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final String baseUrl =
          Platform.isAndroid ? 'http://10.0.2.2:5000' : 'http://localhost:5000';

      final response = await http.get(
        Uri.parse('$baseUrl/api/categories'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _categories = data.map((json) => Category.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _categories = [];
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _categories = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Artikel',
        actions: [
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Theme(
                data: Theme.of(context).copyWith(
                  popupMenuTheme: PopupMenuThemeData(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                child: PopupMenuButton<int?>(
                  initialValue: _selectedCategoryId,
                  position: PopupMenuPosition.under,
                  offset: const Offset(0, 8),
                  onSelected: (int? value) {
                    print('Selected category value: $value');
                    setState(() {
                      if (value == -1) {
                        _selectedCategoryId = null;
                      } else {
                        _selectedCategoryId = value;
                      }
                    });
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<int?>(
                      value: -1,
                      child: Row(
                        children: [
                          if (_selectedCategoryId == null)
                            Icon(
                              Icons.check,
                              color: colorScheme.primary,
                              size: 18,
                            ),
                          const SizedBox(width: 8),
                          const Text('Semua'),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    ..._categories.map((category) => PopupMenuItem<int?>(
                          value: category.id,
                          child: Row(
                            children: [
                              if (_selectedCategoryId == category.id)
                                Icon(
                                  Icons.check,
                                  color: colorScheme.primary,
                                  size: 18,
                                ),
                              const SizedBox(width: 8),
                              Text(category.judul),
                            ],
                          ),
                        )),
                  ],
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_list,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _selectedCategoryId != null
                              ? _categories
                                  .firstWhere(
                                      (c) => c.id == _selectedCategoryId)
                                  .judul
                              : 'Semua',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_drop_down,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  ArticleList(selectedCategoryId: _selectedCategoryId),
                  if (_isRefreshing)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: LinearProgressIndicator(
                        backgroundColor: colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

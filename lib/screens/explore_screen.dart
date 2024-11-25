import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/custom_app_bar.dart';
import '../services/siswa_posts_service.dart';
import 'dart:io';
import '../services/auth_service.dart';
import 'user_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../widgets/like_button.dart';
import '../models/siswa_post.dart';
import '../widgets/post_images_viewer.dart';
import '../widgets/post_comment_section.dart';
import '../services/event_bus_service.dart';
import '../widgets/post_comment_modal.dart';
import '../models/post_comment.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  bool _isSearching = false;
  bool _isSearchingUsers = false;
  final TextEditingController _searchController = TextEditingController();
  final SiswaPostsService _siswaPostsService = SiswaPostsService();
  final _authService = AuthService();
  bool _isLoading = true;
  List<SiswaPost> _posts = [];
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _searchHistory = [];
  Timer? _debounce;
  String? _error;
  StreamSubscription? _postUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    // Listen for post updates
    _postUpdateSubscription = EventBusService().postUpdates.listen((event) {
      if (mounted) {
        setState(() {
          final postIndex =
              _posts.indexWhere((post) => post.id == event.postId);
          if (postIndex != -1) {
            final post = _posts[postIndex];
            _posts[postIndex] = SiswaPost(
              id: post.id,
              profileId: post.profileId,
              caption: post.caption,
              images: post.images,
              createdAt: post.createdAt,
              likesCount: event.type == UpdateType.like
                  ? event.likesCount ?? post.likesCount
                  : post.likesCount,
              commentsCount: event.type == UpdateType.comment
                  ? event.commentsCount ?? post.commentsCount
                  : post.commentsCount,
              isLiked: event.type == UpdateType.like
                  ? event.isLiked ?? post.isLiked
                  : post.isLiked,
              fullName: post.fullName,
              profileImage: post.profileImage,
              title: post.title,
              latestComment: event.type == UpdateType.comment
                  ? event.latestComment ?? post.latestComment
                  : post.latestComment,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _postUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('search_history') ?? [];
    setState(() {
      _searchHistory = history
          .map((item) => jsonDecode(item) as Map<String, dynamic>)
          .toList();
    });
  }

  Future<void> _saveSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = _searchHistory.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('search_history', history);
  }

  void _addToSearchHistory(Map<String, dynamic> user) {
    setState(() {
      _searchHistory.removeWhere((item) => item['id'] == user['id']);
      _searchHistory.insert(0, user);
      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    });
    _saveSearchHistory();
  }

  void _removeFromSearchHistory(int userId) {
    setState(() {
      _searchHistory.removeWhere((item) => item['id'] == userId);
    });
    _saveSearchHistory();
  }

  void _clearSearchHistory() {
    setState(() {
      _searchHistory.clear();
    });
    _saveSearchHistory();
  }

  Future<void> _handleSearch(String query) async {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        setState(() => _searchResults = []);
        return;
      }

      try {
        final results = await _authService.searchUsers(query);
        if (mounted) {
          setState(() => _searchResults = results);
        }
      } catch (e) {
        print('Search error: $e');
      }
    });
  }

  void _navigateToUserProfile(Map<String, dynamic> userData) {
    _addToSearchHistory(userData);

    final baseUrl =
        Platform.isAndroid ? 'http://10.0.2.2:5000' : 'http://localhost:5000';
    final profileImageUrl = userData['profile_image'] != null
        ? '$baseUrl/uploads/profiles/${userData['id']}/${userData['profile_image'].split('/').last}'
        : null;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userData: {
            ...userData,
            'profile_image_url': profileImageUrl,
          },
        ),
      ),
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

  Future<void> _loadInitialData() async {
    try {
      setState(() => _isLoading = true);
      await _loadPosts();
      await _loadSearchHistory();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('Error loading initial data: $e');
    }
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await _siswaPostsService.getAllPosts();
      if (mounted) {
        setState(() {
          _posts = posts;
          _error = null;
        });
      }
    } catch (e) {
      print('Error loading posts: $e');
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat post. Silakan coba lagi nanti.';
          _posts = [];
        });
      }
    }
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
      _isSearchingUsers = true;
      _searchResults = [];
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _isSearchingUsers = false;
      _searchResults = [];
      _searchController.clear();
    });
  }

  Widget _buildLatestComment(PostComment comment) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            backgroundImage: comment.profileImage != null
                ? CachedNetworkImageProvider(
                    comment.getProfileImageUrl(),
                    headers: const {
                      'Accept': 'image/png,image/jpeg,image/jpg',
                    },
                  )
                : null,
            child: comment.profileImage == null
                ? Icon(
                    Icons.person,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: comment.fullName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(text: comment.content),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isSearching ? null : null,
        actions: [
          if (_isSearching)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Cari pengguna...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  style: Theme.of(context).textTheme.bodyLarge,
                  onChanged: _handleSearch,
                ),
              ),
            ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              if (_isSearching) {
                _stopSearch();
              } else {
                _startSearch();
              }
            },
          ),
        ],
      ),
      body: _isSearching
          ? _buildSearchResults()
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
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
                            _error ?? 'Terjadi kesalahan',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadInitialData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadPosts,
                      child: _posts.isEmpty
                          ? const Center(
                              child: Text('No posts available'),
                            )
                          : ListView.separated(
                              itemCount: _posts.length,
                              separatorBuilder: (context, index) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Divider(height: 32),
                              ),
                              itemBuilder: (context, index) {
                                final post = _posts[index];
                                return Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      InkWell(
                                        onTap: () => _navigateToUserProfile({
                                          'id': post.profileId,
                                          'full_name': post.fullName,
                                          'profile_image': post.profileImage,
                                        }),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceVariant,
                                              backgroundImage: post
                                                          .profileImage !=
                                                      null
                                                  ? CachedNetworkImageProvider(
                                                      post.getProfileImageUrl())
                                                  : null,
                                              child: post.profileImage == null
                                                  ? Icon(
                                                      Icons.person,
                                                      size: 24,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  post.fullName,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleSmall,
                                                ),
                                                Text(
                                                  _getTimeAgo(post.createdAt),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        child: Text(post.caption),
                                      ),
                                      if (post.images.isNotEmpty)
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: PostImagesViewer(
                                              images: post.images),
                                        ),
                                      const SizedBox(height: 8),
                                      LikeButton(
                                        postId: post.id,
                                        postTitle: post.title,
                                        initialLikeCount: post.likesCount,
                                        commentsCount: post.commentsCount,
                                        initialIsLiked: post.isLiked,
                                        onLikeChanged: (isLiked, newCount) {
                                          setState(() {
                                            final updatedPost = _posts[index];
                                            _posts[index] = SiswaPost(
                                              id: updatedPost.id,
                                              profileId: updatedPost.profileId,
                                              caption: updatedPost.caption,
                                              images: updatedPost.images,
                                              createdAt: updatedPost.createdAt,
                                              likesCount: newCount,
                                              commentsCount:
                                                  updatedPost.commentsCount,
                                              isLiked: isLiked,
                                              fullName: updatedPost.fullName,
                                              profileImage:
                                                  updatedPost.profileImage,
                                              title: updatedPost.title,
                                              latestComment:
                                                  updatedPost.latestComment,
                                            );
                                          });
                                        },
                                      ),
                                      if (post.latestComment != null)
                                        _buildLatestComment(
                                            post.latestComment!),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      if (_searchHistory.isEmpty) {
        return const Center(
          child: Text('Belum ada riwayat pencarian'),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Riwayat Pencarian',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                TextButton(
                  onPressed: _clearSearchHistory,
                  child: const Text('Hapus Semua'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _searchHistory.length,
              itemBuilder: (context, index) {
                final user = _searchHistory[index];
                return ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceVariant,
                    backgroundImage: user['profile_image'] != null
                        ? CachedNetworkImageProvider(
                            '${Platform.isAndroid ? 'http://10.0.2.2:5000' : 'http://localhost:5000'}/uploads/profiles/${user['id']}/${user['profile_image']}',
                            errorListener: (error) =>
                                print('Error loading image: $error'),
                          )
                        : null,
                    child: user['profile_image'] == null
                        ? Icon(
                            Icons.person,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                  title: Text(user['full_name']),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => _removeFromSearchHistory(user['id']),
                  ),
                  onTap: () => _navigateToUserProfile(user),
                );
              },
            ),
          ),
        ],
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('Tidak ada hasil'),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            backgroundImage: user['profile_image'] != null
                ? CachedNetworkImageProvider(
                    EventBusService().getProfileImageUrl(
                      user['id'],
                      user['profile_image'],
                    ),
                  )
                : null,
            child: user['profile_image'] == null
                ? Icon(
                    Icons.person,
                    size: 24,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  )
                : null,
          ),
          title: Text(user['full_name']),
          onTap: () => _navigateToUserProfile(user),
        );
      },
    );
  }
}

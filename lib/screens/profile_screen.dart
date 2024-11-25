import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

import '../services/auth_service.dart';
import '../services/siswa_posts_service.dart';
import '../models/siswa_post.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/like_button.dart';
import '../widgets/post_images_viewer.dart';
import '../widgets/image_cropper_dialog.dart';
import 'settings_screen.dart';
import '../widgets/article_sections/image_viewer.dart';
import 'upload_screen.dart';
import '../services/event_bus_service.dart';
import '../models/post_comment.dart';
import '../services/post_comment_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _siswaPostsService = SiswaPostsService();
  final _commentService = PostCommentService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  final _imagePicker = ImagePicker();
  List<SiswaPost> _userPosts = [];
  List<String> _userMedia = [];
  String? _error;
  late int userId;
  StreamSubscription? _postUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Listen for post updates
    _postUpdateSubscription = EventBusService().postUpdates.listen((event) {
      if (mounted) {
        setState(() {
          final postIndex =
              _userPosts.indexWhere((post) => post.id == event.postId);
          if (postIndex != -1) {
            final post = _userPosts[postIndex];
            _userPosts[postIndex] = SiswaPost(
              id: post.id,
              profileId: post.profileId,
              caption: post.caption,
              images: post.images,
              createdAt: post.createdAt,
              likesCount: event.type == UpdateType.like
                  ? (event.likesCount ?? post.likesCount)
                  : post.likesCount,
              commentsCount: event.type == UpdateType.comment
                  ? (event.commentsCount ?? post.commentsCount)
                  : post.commentsCount,
              isLiked: event.type == UpdateType.like
                  ? (event.isLiked ?? post.isLiked)
                  : post.isLiked,
              fullName: post.fullName,
              profileImage: post.profileImage,
              title: post.title,
              latestComment: event.type == UpdateType.comment
                  ? event.latestComment
                  : post.latestComment,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _postUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);

      // Load user data from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');

      if (userDataString != null) {
        final userData = json.decode(userDataString);
        setState(() {
          _userData = userData;
          userId = userData['id'];
        });

        // Load posts after user data is loaded
        await _loadPosts();
      } else {
        setState(() {
          _error = 'User data not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadPosts() async {
    if (userId == null) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get posts with latest comments and counts
      final posts = await _siswaPostsService.getPostsByProfile(userId);

      // Update comment counts for each post
      final updatedPosts = await Future.wait(posts.map((post) async {
        try {
          final (latestComment, commentCount) =
              await _commentService.getLatestComment(post.id);
          return SiswaPost(
            id: post.id,
            profileId: post.profileId,
            caption: post.caption,
            images: post.images,
            createdAt: post.createdAt,
            likesCount: post.likesCount,
            commentsCount: commentCount, // Use the actual count
            isLiked: post.isLiked,
            fullName: post.fullName,
            profileImage: post.profileImage,
            title: post.title,
            latestComment: latestComment,
          );
        } catch (e) {
          print('Error getting comment data for post ${post.id}: $e');
          return post;
        }
      }));

      if (mounted) {
        setState(() {
          _userPosts = updatedPosts;
          _userMedia = updatedPosts.expand((post) {
            return post.images.map((img) => img['file'] as String);
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
      print('Error loading posts: $e');
    }
  }

  Future<void> _updateProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) return;

      // Show cropping dialog
      final File imageFile = File(image.path);
      final Uint8List imageBytes = await imageFile.readAsBytes();

      final croppedBytes = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageCropperDialog(
            image: imageBytes,
          ),
        ),
      );

      if (croppedBytes == null) return;

      // Save cropped image to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/cropped_image.jpg');
      await tempFile.writeAsBytes(croppedBytes);

      setState(() => _isLoading = true);

      // Create multipart request
      final url = Uri.parse(
        Platform.isAndroid
            ? 'http://10.0.2.2:5000/api/profile/image'
            : 'http://localhost:5000/api/profile/image',
      );

      final token = await _authService.getToken();
      if (token == null) throw Exception('Not authenticated');

      // Create the request
      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';

      // Add the file
      final file = await http.MultipartFile.fromPath(
        'profile_image',
        tempFile.path,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(file);

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Update user data in SharedPreferences with the new path format
        final userData = await _authService.getUserData();
        if (userData != null) {
          // Store only the filename part of the profile image path
          final profileImagePath = responseData['profile_image'];
          userData['profile_image'] = profileImagePath;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(userData));
        }

        // Reload user data to update UI
        await _loadUserData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Foto profil berhasil diperbarui'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      print('Error updating profile image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui foto profil: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePostAction(String action, SiswaPost post) async {
    if (action == 'delete') {
      try {
        // Show confirmation dialog
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Post'),
            content: const Text('Are you sure you want to delete this post?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (shouldDelete == true) {
          // Show loading indicator
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deleting post...')),
          );

          // Delete post
          await _siswaPostsService.deletePost(post.id);

          // Refresh posts
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post deleted successfully')),
          );
          _loadPosts();
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting post: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: CustomAppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    // Profile Image with Edit Button
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _updateProfileImage,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  Theme.of(context).colorScheme.surfaceVariant,
                            ),
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ClipOval(
                                    child: _userData?['profile_image'] != null
                                        ? CachedNetworkImage(
                                            imageUrl:
                                                '${Platform.isAndroid ? 'http://10.0.2.2:5000' : 'http://localhost:5000'}/uploads/profiles/${_userData!['id']}/${_userData!['profile_image']?.split('/').last ?? _userData!['profile_image']}',
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                            errorWidget: (context, url, error) {
                                              print(
                                                  'Profile image error: $error');
                                              print('URL: $url');
                                              return Container(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surfaceVariant,
                                                child: Icon(
                                                  Icons.person,
                                                  size: 64,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              );
                                            },
                                          )
                                        : Icon(
                                            Icons.person,
                                            size: 64,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit,
                              size: 20,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // User Info
                    Text(
                      _userData?['full_name'] ?? 'Loading...',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userData?['email'] ?? '',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    tabs: const [
                      Tab(text: 'Postingan'),
                      Tab(text: 'Media'),
                    ],
                    labelColor: colorScheme.primary,
                    unselectedLabelColor: colorScheme.onSurfaceVariant,
                    indicatorColor: colorScheme.primary,
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildPostsList(),
              _buildMediaGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostsList() {
    if (_userPosts.isEmpty) {
      return const Center(
        child: Text('Belum ada postingan'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _userPosts.length,
      separatorBuilder: (context, index) => const Divider(height: 32),
      itemBuilder: (context, index) {
        final post = _userPosts[index];
        final createdAt = post.createdAt;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with profile info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  backgroundImage: post.profileImage != null
                      ? CachedNetworkImageProvider(
                          post.getProfileImageUrl(),
                        )
                      : null,
                  child: post.profileImage == null
                      ? Icon(
                          Icons.person,
                          size: 24,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.fullName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        _getTimeAgo(createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                // Post Actions
                PopupMenuButton<String>(
                  onSelected: (value) => _handlePostAction(value, post),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Caption
            Text(post.caption),
            const SizedBox(height: 12),
            // Images
            if (post.images.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: PostImagesViewer(images: post.images),
              ),
            const SizedBox(height: 8),
            // Like Button
            LikeButton(
              postId: post.id,
              postTitle: post.title,
              initialLikeCount: post.likesCount,
              commentsCount: post.commentsCount,
              initialIsLiked: post.isLiked,
              onLikeChanged: (isLiked, newCount) {
                setState(() {
                  final updatedPost = _userPosts[index];
                  _userPosts[index] = SiswaPost(
                    id: updatedPost.id,
                    profileId: updatedPost.profileId,
                    caption: updatedPost.caption,
                    images: updatedPost.images,
                    createdAt: updatedPost.createdAt,
                    likesCount: newCount,
                    commentsCount: updatedPost.commentsCount,
                    isLiked: isLiked,
                    fullName: updatedPost.fullName,
                    profileImage: updatedPost.profileImage,
                    title: updatedPost.title,
                    latestComment: updatedPost.latestComment,
                  );
                });
              },
              onCommentCountChanged: (newCount) {
                setState(() {
                  final updatedPost = _userPosts[index];
                  _userPosts[index] = SiswaPost(
                    id: updatedPost.id,
                    profileId: updatedPost.profileId,
                    caption: updatedPost.caption,
                    images: updatedPost.images,
                    createdAt: updatedPost.createdAt,
                    likesCount: updatedPost.likesCount,
                    commentsCount: newCount,
                    isLiked: updatedPost.isLiked,
                    fullName: updatedPost.fullName,
                    profileImage: updatedPost.profileImage,
                    title: updatedPost.title,
                    latestComment: updatedPost.latestComment,
                  );
                });
              },
            ),
          ],
        );
      },
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

  Widget _buildMediaGrid(BuildContext context) {
    if (_userMedia.isEmpty) {
      return const Center(
        child: Text('Belum ada media'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: _userMedia.length,
      itemBuilder: (context, index) {
        final imagePath = _userMedia[index];
        final baseUrl = Platform.isAndroid
            ? 'http://10.0.2.2:5000'
            : 'http://localhost:5000';
        final fullImageUrl = '$baseUrl/uploads/$imagePath';

        print('Loading media image: $fullImageUrl');

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImageViewer(
                  imageUrls: [fullImageUrl],
                  initialIndex: 0,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: fullImageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) {
                print('Image error: $error');
                print('Failed URL: $url');
                return Container(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: const Icon(Icons.error),
                );
              },
            ),
          ),
        );
      },
    );
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
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class _Post {
  final String content;
  final String? imageUrl;
  final String date;

  _Post({
    required this.content,
    this.imageUrl,
    required this.date,
  });
}

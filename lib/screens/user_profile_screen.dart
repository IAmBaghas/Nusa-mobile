import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import '../widgets/custom_app_bar.dart';
import '../services/siswa_posts_service.dart';
import '../widgets/article_sections/image_viewer.dart';
import '../models/siswa_post.dart';
import '../widgets/like_button.dart';
import '../widgets/post_images_viewer.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../models/post_comment.dart';
import '../services/event_bus_service.dart';
import 'dart:async';
import '../services/post_comment_service.dart';

class UserProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const UserProfileScreen({
    super.key,
    required this.userData,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _siswaPostsService = SiswaPostsService();
  final _commentService = PostCommentService();
  List<SiswaPost> _userPosts = [];
  List<String> _userMedia = [];
  bool _isLoading = true;
  StreamSubscription? _postUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _loadPosts();

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

  Future<void> _loadPosts() async {
    try {
      final posts =
          await _siswaPostsService.getPostsByProfile(widget.userData['id']);

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
            commentsCount: commentCount,
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
          print('Loaded media paths: $_userMedia');
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading posts: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRefresh() async {
    try {
      setState(() => _isLoading = true);
      await _loadPosts();
      setState(() => _isLoading = false);
    } catch (e) {
      print('Error refreshing data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CustomAppBar(
          showLogo: false,
        ),
        body: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: NestedScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _buildProfileImage(),
                      const SizedBox(height: 16),
                      Text(
                        widget.userData['full_name'],
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
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
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ];
            },
            body: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    children: [
                      _buildPostList(context),
                      _buildMediaGrid(context),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostList(BuildContext context) {
    if (_userPosts.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Text('Belum ada postingan'),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
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

  Widget _buildMediaGrid(BuildContext context) {
    if (_userMedia.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Text('Belum ada media'),
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Error',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                );
              },
              cacheManager: DefaultCacheManager(),
              memCacheWidth: 300,
              memCacheHeight: 300,
            ),
          ),
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

  Widget _buildProfileImage() {
    return CircleAvatar(
      radius: 50,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      backgroundImage: widget.userData['profile_image_url'] != null
          ? CachedNetworkImageProvider(
              widget.userData['profile_image_url'],
              errorListener: (error) {
                print('Error loading image: $error');
                print('URL: ${widget.userData['profile_image_url']}');
              },
            )
          : null,
      child: widget.userData['profile_image_url'] == null
          ? Icon(
              Icons.person,
              size: 50,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            )
          : null,
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

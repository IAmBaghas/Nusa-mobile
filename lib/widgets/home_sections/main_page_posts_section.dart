import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/siswa_post.dart';
import '../../services/siswa_posts_service.dart';
import '../post_images_viewer.dart';
import '../like_button.dart';
import '../../screens/user_profile_screen.dart';
import 'dart:io';
import '../../services/event_bus_service.dart';
import 'dart:async';

class MainPagePostsSection extends StatefulWidget {
  const MainPagePostsSection({super.key});

  @override
  State<MainPagePostsSection> createState() => _MainPagePostsSectionState();
}

class _MainPagePostsSectionState extends State<MainPagePostsSection> {
  final _siswaPostsService = SiswaPostsService();
  List<SiswaPost> _posts = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _postUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _loadPosts();

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
      final posts = await _siswaPostsService.getMainPagePosts();
      if (mounted) {
        setState(() {
          _posts = posts;
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

    if (_posts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _posts.length,
          separatorBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 32),
          ),
          itemBuilder: (context, index) {
            final post = _posts[index];
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(
                            userData: {
                              'id': post.profileId,
                              'full_name': post.fullName,
                              'profile_image': post.profileImage,
                            },
                          ),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceVariant,
                          backgroundImage: post.profileImage != null
                              ? CachedNetworkImageProvider(
                                  post.getProfileImageUrl(),
                                )
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
                        Text(
                          post.fullName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(post.caption),
                  if (post.images.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: PostImagesViewer(images: post.images),
                    ),
                  ],
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
                          commentsCount: updatedPost.commentsCount,
                          isLiked: isLiked,
                          fullName: updatedPost.fullName,
                          profileImage: updatedPost.profileImage,
                          title: updatedPost.title,
                        );
                      });
                    },
                    onCommentCountChanged: (newCount) {
                      setState(() {
                        final updatedPost = _posts[index];
                        _posts[index] = SiswaPost(
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
                        );
                      });
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

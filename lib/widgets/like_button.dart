import 'package:flutter/material.dart';
import '../services/siswa_posts_service.dart';
import '../services/notification_manager.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'post_comment_modal.dart';
import '../services/event_bus_service.dart';
import 'dart:async';

class LikeButton extends StatefulWidget {
  final int postId;
  final String postTitle;
  final int initialLikeCount;
  final int commentsCount;
  final bool initialIsLiked;
  final Function(bool, int) onLikeChanged;
  final Function(int)? onCommentCountChanged;

  const LikeButton({
    Key? key,
    required this.postId,
    required this.postTitle,
    required this.initialLikeCount,
    required this.commentsCount,
    required this.initialIsLiked,
    required this.onLikeChanged,
    this.onCommentCountChanged,
  }) : super(key: key);

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  final SiswaPostsService _postsService = SiswaPostsService();
  final NotificationService _notificationService = NotificationService();
  late bool _isLiked;
  late int _likeCount;
  final _eventBus = EventBusService();
  StreamSubscription? _subscription;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.initialIsLiked;
    _likeCount = widget.initialLikeCount;
    _checkInitialLikeStatus();

    // Listen for updates from other screens
    _subscription = _eventBus.postUpdates.listen((event) {
      if (event.postId == widget.postId &&
          mounted &&
          event.type == UpdateType.like) {
        setState(() {
          _isLiked = event.isLiked ?? _isLiked;
          _likeCount = event.likesCount ?? _likeCount;
        });
      }
    });
  }

  Future<void> _checkInitialLikeStatus() async {
    try {
      final isLiked = await _postsService.checkLike(widget.postId);
      if (mounted && isLiked != _isLiked) {
        setState(() {
          _isLiked = isLiked;
        });
      }
    } catch (e) {
      print('Error checking initial like status: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to like posts')),
        );
        return;
      }

      setState(() => _isLoading = true);

      final newLikeStatus = await _postsService.toggleLike(widget.postId);
      final newLikeCount = await _postsService.getLikeCount(widget.postId);

      if (mounted) {
        setState(() {
          _isLiked = newLikeStatus;
          _likeCount = newLikeCount;
          _isLoading = false;
        });

        widget.onLikeChanged(newLikeStatus, newLikeCount);

        // Emit the update event
        _eventBus.emitPostUpdate(PostUpdateEvent(
          postId: widget.postId,
          isLiked: newLikeStatus,
          likesCount: newLikeCount,
          commentsCount: widget.commentsCount,
          type: UpdateType.like,
        ));

        if (newLikeStatus) {
          NotificationManager().addNotification(
            NotificationItem(
              title: 'New Like',
              message: 'You liked: ${widget.postTitle}',
              time: DateTime.now(),
              type: 'like',
              data: {'postId': widget.postId},
            ),
          );

          try {
            await _notificationService.createNotification(
                widget.postId, 'like', 'menyukai postingan Anda');
          } catch (e) {
            print('Error creating notification: $e');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostCommentModal(
        postId: widget.postId,
        onCommentUpdated: (newCount, _) {
          if (widget.onCommentCountChanged != null) {
            widget.onCommentCountChanged!(newCount);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.pink : null,
                ),
          onPressed: _isLoading ? null : _toggleLike,
        ),
        Text(
          _likeCount.toString(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.comment_outlined),
          onPressed: () => _showComments(context),
        ),
        Text(
          widget.commentsCount.toString(),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

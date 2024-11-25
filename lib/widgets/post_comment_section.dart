import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/post_comment.dart';
import '../services/post_comment_service.dart';
import 'post_comment_modal.dart';

class PostCommentSection extends StatefulWidget {
  final int postId;
  final Function(int) onCommentCountChanged;

  const PostCommentSection({
    super.key,
    required this.postId,
    required this.onCommentCountChanged,
  });

  @override
  State<PostCommentSection> createState() => _PostCommentSectionState();
}

class _PostCommentSectionState extends State<PostCommentSection> {
  final PostCommentService _commentService = PostCommentService();
  List<PostComment> _comments = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final comments = await _commentService.getComments(widget.postId);
      if (mounted) {
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('Error loading comments: $e');
    }
  }

  Future<void> _refreshLatestComment() async {
    try {
      final (latestComment, totalComments) =
          await _commentService.getLatestComment(widget.postId);
      if (mounted) {
        setState(() {
          if (latestComment != null) {
            _comments = [latestComment];
          } else {
            _comments = [];
          }
        });
        widget.onCommentCountChanged(totalComments);
      }
    } catch (e) {
      print('Error refreshing latest comment: $e');
    }
  }

  void _showCommentModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostCommentModal(
        postId: widget.postId,
        onCommentUpdated: (newCount, updatedComments) async {
          await _refreshLatestComment();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return const SizedBox(height: 40);
    }

    return InkWell(
      onTap: () => _showCommentModal(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Komentar',
              style: textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (_comments.isEmpty)
              Text(
                'Belum ada komentar',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colorScheme.surfaceVariant,
                    backgroundImage: _comments.first.profileImage != null
                        ? CachedNetworkImageProvider(
                            _comments.first.getProfileImageUrl(),
                            headers: const {
                              'Accept': 'image/png,image/jpeg,image/jpg',
                            },
                          )
                        : null,
                    child: _comments.first.profileImage == null
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _comments.first.fullName,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _comments.first.content,
                          style: textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

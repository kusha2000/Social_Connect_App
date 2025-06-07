import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:social_connect/models/post_model.dart';
import 'package:social_connect/services/feed/feed_service.dart';
import 'package:social_connect/utils/app_constants/colors.dart';
import 'package:social_connect/utils/util_functions/mood.dart';
import 'package:social_connect/utils/util_functions/snackbar_functions.dart';
import 'package:social_connect/widgets/main/feed/comment_bottom_sheet.dart';
import 'package:social_connect/widgets/main/feed/like_bottom_sheet.dart';

class PostWidget extends StatefulWidget {
  final Post post;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String currentUserId;

  const PostWidget({
    required this.post,
    required this.onEdit,
    required this.onDelete,
    required this.currentUserId,
    Key? key,
  }) : super(key: key);

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> with TickerProviderStateMixin {
  bool _isLiked = false;
  int _currentLikes = 0;
  late AnimationController _likeAnimationController;
  late AnimationController _scaleAnimationController;
  late Animation<double> _likeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isExpanded = false;
  bool _isLiking = false; // Add this to prevent double-tapping

  @override
  void initState() {
    super.initState();
    _currentLikes = widget.post.likes;
    _checkIfLiked();
    _initializeAnimations();
  }

  @override
  void didUpdateWidget(PostWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update likes count when widget updates (for real-time updates)
    if (oldWidget.post.likes != widget.post.likes) {
      setState(() {
        _currentLikes = widget.post.likes;
      });
    }
  }

  void _initializeAnimations() {
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _likeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _likeAnimationController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    _scaleAnimationController.dispose();
    super.dispose();
  }

  Future<void> _checkIfLiked() async {
    try {
      final hasLiked = await FeedService().hasUserLikedPost(
        postId: widget.post.postId,
        userId: widget.currentUserId,
      );
      if (mounted) {
        setState(() {
          _isLiked = hasLiked;
        });
      }
    } catch (e) {
      print('Error checking if liked: $e');
    }
  }

  void _likePost() async {
    // Prevent double-tapping
    if (_isLiking) return;
    _isLiking = true;

    // Haptic feedback
    // HapticFeedback.lightImpact();

    // Animate button press
    _scaleAnimationController.forward().then((_) {
      _scaleAnimationController.reverse();
    });

    // Optimistic update - update UI immediately
    final previousLikedState = _isLiked;
    final previousLikesCount = _currentLikes;

    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _currentLikes = _currentLikes > 0 ? _currentLikes - 1 : 0;
      } else {
        _isLiked = true;
        _currentLikes++;
        // Animate heart for like
        _likeAnimationController.forward().then((_) {
          _likeAnimationController.reverse();
        });
      }
    });

    try {
      if (previousLikedState) {
        await FeedService().unlikePost(
          postId: widget.post.postId,
          userId: widget.currentUserId,
        );
      } else {
        await FeedService().likePost(
          postId: widget.post.postId,
          userId: widget.currentUserId,
        );
      }
    } catch (e) {
      print('Error liking/unliking post: $e');

      // Revert optimistic update on error
      if (mounted) {
        setState(() {
          _isLiked = previousLikedState;
          _currentLikes = previousLikesCount;
        });
      }

      SnackBarFunctions.showErrorSnackBar(
          context, 'Failed to ${previousLikedState ? 'unlike' : 'like'} post');
    } finally {
      _isLiking = false;
    }
  }

  void _showLikesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LikesBottomSheet(postId: widget.post.postId),
    );
  }

  void _showCommentsBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(
        postId: widget.post.postId,
        currentUserId: widget.currentUserId,
      ),
    );
  }

  void _showOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildOptionItem(
              icon: Icons.edit_outlined,
              title: 'Edit Post',
              onTap: () {
                Navigator.pop(context);
                widget.onEdit();
              },
            ),
            _buildOptionItem(
              icon: Icons.delete_outline,
              title: 'Delete Post',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                widget.onDelete();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color ?? AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color ?? AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 600;
    String formattedDate =
        DateFormat('MMM dd, yyyy • HH:mm').format(widget.post.datePublished);

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: EdgeInsets.symmetric(
              horizontal: isWeb ? 0 : 4,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.border.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(
                            widget.post.profImage.isEmpty
                                ? 'https://i.stack.imgur.com/l60Hf.png'
                                : widget.post.profImage,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.username,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.post.userId == widget.currentUserId) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _showOptionsBottomSheet,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.more_vert,
                              color: AppColors.textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Enhanced Mood Badge with "Feeling" text
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Feeling',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.post.mood.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.post.mood.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Content
                if (widget.post.postCaption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isExpanded || widget.post.postCaption.length <= 150
                              ? widget.post.postCaption
                              : '${widget.post.postCaption.substring(0, 150)}...',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        if (widget.post.postCaption.length > 150)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _isExpanded ? 'Show less' : 'Show more',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                // Image
                if (widget.post.postUrl.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          widget.post.postUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: progress.expectedTotalBytes != null
                                      ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                      : null,
                                  color: AppColors.primary,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    color: AppColors.textSecondary,
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                // Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Like Button
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _likePost,
                            child: AnimatedBuilder(
                              animation: _likeAnimation,
                              builder: (context, _) {
                                return Transform.scale(
                                  scale: 1.0 + (_likeAnimation.value * 0.3),
                                  child: Icon(
                                    _isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: _isLiked
                                        ? AppColors.error
                                        : AppColors.textSecondary,
                                    size: 24,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _showLikesBottomSheet,
                            child: Text(
                              _currentLikes.toString(),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Comment Button
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _showCommentsBottomSheet,
                            child: Icon(
                              Icons.chat_bubble_outline,
                              color: AppColors.textSecondary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.post.comments.toString(),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

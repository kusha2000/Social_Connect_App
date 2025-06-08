import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:social_connect/services/reels/video_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:social_connect/models/reel_model.dart';
import 'package:social_connect/services/reels/reel_service.dart';
import 'package:social_connect/utils/app_constants/colors.dart';
import 'package:social_connect/widgets/main/reels/comment_bottom_sheet.dart';
import 'package:social_connect/widgets/main/reels/like_bottom_sheet.dart';
import 'video_player_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReelWidget extends StatefulWidget {
  final Reel reel;

  const ReelWidget({
    required this.reel,
    Key? key,
  }) : super(key: key);

  @override
  State<ReelWidget> createState() => _ReelWidgetState();
}

class _ReelWidgetState extends State<ReelWidget>
    with SingleTickerProviderStateMixin {
  final ReelService _reelService = ReelService();
  bool _isLiking = false;
  String? _currentUserId;
  late AnimationController _heartAnimationController;
  late Animation<double> _heartAnimation;

  // Real-time stream subscriptions
  Stream<DocumentSnapshot>? _reelStream;
  Stream<bool>? _likeStatusStream;

  // Video player controllers
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _heartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _heartAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _heartAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    _initializeData();
    _initializeVideo();
  }

  @override
  void dispose() {
    _heartAnimationController.dispose();
    if (_videoController != null) {
      VideoControllerManager().unregisterController(_videoController!);
      _videoController!.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeData() async {
    await _getCurrentUserId();
    _setupRealtimeStreams(); // Move this after getting current user ID
  }

  void _setupRealtimeStreams() {
    // Stream for reel document changes (likes and comments count)
    _reelStream = FirebaseFirestore.instance
        .collection('reels')
        .doc(widget.reel.reelId)
        .snapshots();

    // Stream for user's like status
    if (_currentUserId != null) {
      _likeStatusStream = FirebaseFirestore.instance
          .collection('reels')
          .doc(widget.reel.reelId)
          .collection('likes')
          .doc(_currentUserId)
          .snapshots()
          .map((doc) => doc.exists);
    }
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.reel.videoUrl),
      );

      await _videoController!.initialize();
      _videoController!.setLooping(true);

      // Set up video position listener
      _videoController!.addListener(_videoListener);

      // Register with VideoControllerManager
      VideoControllerManager().registerController(_videoController!);

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _totalDuration = _videoController!.value.duration;
          _isPlaying = _videoController!.value.isPlaying;
        });
      }
    } catch (e) {
      print('Error initializing video: $e');
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    }
  }

  void _videoListener() {
    if (_videoController != null && mounted) {
      setState(() {
        _currentPosition = _videoController!.value.position;
        _isPlaying = _videoController!.value.isPlaying;
      });
    }
  }

  void _togglePlayPause() {
    if (_videoController == null || !_isVideoInitialized) return;

    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isPlaying = false;
      } else {
        _videoController!.play();
        _isPlaying = true;
      }
    });
  }

  void _seekTo(double value) {
    if (_videoController == null || !_isVideoInitialized) return;

    final position =
        Duration(milliseconds: (value * _totalDuration.inMilliseconds).round());
    _videoController!.seekTo(position);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _getCurrentUserId() async {
    final userId = await _reelService.getCurrentUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_isLiking || _currentUserId == null) return;

    setState(() {
      _isLiking = true;
    });

    try {
      // Get current like status from the stream
      final likeDoc = await FirebaseFirestore.instance
          .collection('reels')
          .doc(widget.reel.reelId)
          .collection('likes')
          .doc(_currentUserId)
          .get();

      final isCurrentlyLiked = likeDoc.exists;

      if (isCurrentlyLiked) {
        await _reelService.unlikeReel(widget.reel.reelId);
      } else {
        await _reelService.likeReel(widget.reel.reelId);
        // Trigger heart animation for likes
        _heartAnimationController.forward().then((_) {
          _heartAnimationController.reverse();
        });
      }
    } catch (e) {
      print('Error toggling like: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error ${_isLiking ? 'updating' : 'liking'} reel'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLiking = false;
        });
      }
    }
  }

  void _showCommentsBottomSheet() {
    if (_currentUserId == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReelCommentsBottomSheet(
        reelId: widget.reel.reelId,
        currentUserId: _currentUserId!,
      ),
    );
  }

  void _showLikesBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReelLikesBottomSheet(
        reelId: widget.reel.reelId,
      ),
    );
  }

  void _deleteReel() async {
    if (_currentUserId == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete Reel',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this reel? This action cannot be undone.',
          style: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await _reelService.deleteReel(widget.reel);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reel deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting reel: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserHeader(),
          _buildVideoPlayer(),
          _buildVideoControls(),
          if (widget.reel.caption.isNotEmpty) _buildCaption(),
          _buildInteractionButtons(),
        ],
      ),
    );
  }

  Widget _buildUserHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(2),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.surface,
              child: CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(
                  widget.reel.userProfilePic,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.reel.username,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(widget.reel.datePublished),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_currentUserId != null && widget.reel.userId == _currentUserId)
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.more_vert,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              color: AppColors.cardBackground,
              onSelected: (value) {
                if (value == 'delete') {
                  _deleteReel();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Delete',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_isVideoInitialized && _videoController != null)
                VideoPlayerWidget(
                  videoUrl: widget.reel.videoUrl,
                  controller: _videoController!,
                )
              else
                Container(
                  color: AppColors.background,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.video_file,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading Video...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoControls() {
    if (!_isVideoInitialized || _videoController == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Play/Pause button and time display
          Row(
            children: [
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _formatDuration(_currentPosition),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                _formatDuration(_totalDuration),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primary,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              trackHeight: 3,
            ),
            child: Slider(
              value: _totalDuration.inMilliseconds > 0
                  ? _currentPosition.inMilliseconds /
                      _totalDuration.inMilliseconds
                  : 0.0,
              min: 0.0,
              max: 1.0,
              onChanged: _seekTo,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaption() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        widget.reel.caption,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildInteractionButtons() {
    // If current user ID is not available, don't show the streams
    if (_currentUserId == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.favorite_border,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '0',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.textSecondary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: _reelStream,
      builder: (context, snapshot) {
        int likesCount = widget.reel.likes; // Use initial value as fallback
        int commentsCount =
            widget.reel.comments; // Use initial value as fallback

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data != null) {
            likesCount = data['likes'] ?? widget.reel.likes;
            commentsCount = data['comments'] ?? widget.reel.comments;
          }
        }

        return StreamBuilder<bool>(
          stream: _likeStatusStream,
          builder: (context, likeSnapshot) {
            final isLiked = likeSnapshot.data ?? false;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _isLiking ? null : _toggleLike,
                        child: AnimatedBuilder(
                          animation: _heartAnimation,
                          builder: (context, _) {
                            return Transform.scale(
                              scale: _heartAnimation.value,
                              child: _isLiking
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          AppColors.primary,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      isLiked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isLiked
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
                          likesCount.toString(),
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _showCommentsBottomSheet,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                          if (commentsCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              commentsCount.toString(),
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

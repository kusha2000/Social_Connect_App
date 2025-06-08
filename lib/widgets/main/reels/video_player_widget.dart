// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:social_connect/services/reels/video_controller.dart';
import 'package:social_connect/utils/app_constants/colors.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final VideoPlayerController controller; 

  const VideoPlayerWidget({
    required this.videoUrl,
    required this.controller,
    Key? key,
  }) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  bool _isInitialized = false;
  bool _showControls = true;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      if (!widget.controller.value.isInitialized) {
        await widget.controller.initialize();
      }
      widget.controller
        ..addListener(_videoListener)
        ..setLooping(true);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (error) {
      print("Error initializing video: $error");
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
      }
    }
  }

  void _videoListener() {
    if (mounted) {
      setState(() {
        _isPlaying = widget.controller.value.isPlaying;
      });
    }
  }

  void _togglePlayPause() {
    print("Play/Pause button pressed!");
    if (!_isInitialized) {
      print("Video not initialized yet");
      return;
    }

    if (widget.controller.value.isPlaying) {
      widget.controller.pause();
    } else {
      // Use VideoControllerManager to play this video and pause others
      VideoControllerManager().playController(widget.controller);
    }

    _toggleControls();
  }

  void _toggleControls() {
    setState(() {
      _showControls = true;
    });

    if (_isPlaying) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isPlaying) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _onScreenTap() {
    print("Screen tapped - toggling controls");
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls && _isPlaying) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _isPlaying) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_videoListener);
    // Do NOT dispose controller here; ReelWidget handles it
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Update AppColors based on current theme
    AppColors.setDarkMode(isDark);
    return Container(
      color: AppColors.background,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video Player
          if (_isInitialized)
            AspectRatio(
              aspectRatio: widget.controller.value.aspectRatio,
              child: VideoPlayer(widget.controller),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),

          // Full screen tap detector for showing/hiding controls
          if (_isInitialized)
            Positioned.fill(
              child: GestureDetector(
                onTap: _onScreenTap,
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}

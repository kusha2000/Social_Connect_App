import 'dart:io';
import 'package:flutter/foundation.dart';
// Conditional imports
import 'web_helper.dart' if (dart.library.io) 'mobile_helper.dart' as platform;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:social_connect/services/auth/auth_service.dart';
import 'package:social_connect/services/reels/reel_service.dart';
import 'package:social_connect/services/reels/reel_storage.dart';
import 'package:social_connect/services/users/user_service.dart';
import 'package:social_connect/utils/app_constants/colors.dart';
import 'package:social_connect/widgets/reusable/modern_button.dart';

class AddReelModal extends StatefulWidget {
  const AddReelModal({super.key});

  @override
  _AddReelModalState createState() => _AddReelModalState();
}

class _AddReelModalState extends State<AddReelModal>
    with TickerProviderStateMixin {
  final _captionController = TextEditingController();
  File? _videoFile;
  Uint8List? _videoBytes;
  String? _webVideoUrl; // Add this for web video URL
  bool _isUploading = false;
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Video preview controller
  VideoPlayerController? _previewController;
  bool _isPreviewInitialized = false;

  @override
  void initState() {
    super.initState();
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _previewController?.dispose();
    // Clean up web video URL if it exists
    if (_webVideoUrl != null && kIsWeb) {
      platform.revokeVideoUrl(_webVideoUrl!);
    }
    super.dispose();
  }

  // Initialize video preview
  Future<void> _initializeVideoPreview() async {
    try {
      // Dispose previous controller
      _previewController?.dispose();
      _previewController = null;

      if (_videoFile != null && !kIsWeb) {
        // Mobile/Desktop: Use file
        _previewController = VideoPlayerController.file(_videoFile!);
      } else if (_videoBytes != null && kIsWeb) {
        // Web: Create blob URL from bytes
        _webVideoUrl = platform.createVideoUrl(_videoBytes!);
        if (_webVideoUrl != null) {
          _previewController = VideoPlayerController.network(_webVideoUrl!);
        } else {
          return;
        }
      } else {
        return;
      }

      await _previewController!.initialize();
      _previewController!.setLooping(true);
      _previewController!.pause(); // Start paused

      if (mounted) {
        setState(() {
          _isPreviewInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing video preview: $e');
      if (mounted) {
        setState(() {
          _isPreviewInitialized = false;
        });
      }
    }
  }

  // Fetch user email
  Future<String?> _getUserEmail() async {
    try {
      final user = await AuthService().getCurrentUser();
      if (user != null) {
        final userModel = await UserService().getUserById(user.uid);
        return userModel?.email;
      }
    } catch (e) {
      print('Error fetching user email: $e');
    }
    return null;
  }

  // Pick a video from the gallery
  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      // Clean up previous resources
      _previewController?.dispose();
      _previewController = null;
      if (_webVideoUrl != null && kIsWeb) {
        platform.revokeVideoUrl(_webVideoUrl!);
        _webVideoUrl = null;
      }

      setState(() {
        _isPreviewInitialized = false;
      });

      if (kIsWeb) {
        // Web: Read as bytes and create blob URL
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _videoBytes = bytes;
          _videoFile = null;
        });
      } else {
        // Mobile/Desktop: Use file path
        setState(() {
          _videoFile = File(pickedFile.path);
          _videoBytes = null;
        });
      }

      // Initialize preview after state is updated
      await _initializeVideoPreview();
    }
  }

  // Handle video upload and post creation
  void _submitReel() async {
    if ((_videoFile != null || _videoBytes != null) &&
        _captionController.text.isNotEmpty) {
      try {
        setState(() {
          _isUploading = true;
        });

        final userEmail = await _getUserEmail();
        if (userEmail == null) {
          throw Exception('Failed to fetch user email');
        }

        final videoUrl = await ReelStorageService().uploadVideoUniversal(
          videoFile: _videoFile,
          videoBytes: _videoBytes,
          userEmail: userEmail,
        );

        final reelDetails = {
          'caption': _captionController.text.trim(),
          'videoUrl': videoUrl,
        };

        await ReelService().saveReel(reelDetails);

        // Success animation before closing
        await _slideAnimationController.reverse();

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Reel uploaded successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Failed to upload reel: $e')),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please select a video and add a caption'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildVideoSection(),
                          const SizedBox(height: 24),
                          _buildCaptionSection(),
                          const SizedBox(height: 32),
                          _buildUploadButton(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.border.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.videocam_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create Reel',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Share your moment with the world',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          if (_videoFile != null || _videoBytes != null) ...[
            // Small Reel-sized preview container
            Center(
              child: Container(
                width: 140, // Small reel width
                height: 250, // Small reel height (9:16 aspect ratio)
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: _isPreviewInitialized && _previewController != null
                      ? Stack(
                          alignment: Alignment.center,
                          children: [
                            // Video player with proper aspect ratio
                            SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _previewController!.value.size.width,
                                  height: _previewController!.value.size.height,
                                  child: VideoPlayer(_previewController!),
                                ),
                              ),
                            ),
                            // Play/Pause overlay
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                  icon: Icon(
                                    _previewController!.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (_previewController!.value.isPlaying) {
                                        _previewController!.pause();
                                      } else {
                                        _previewController!.play();
                                      }
                                    });
                                  },
                                ),
                              ),
                            ),
                            // Duration indicator
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _formatDuration(
                                      _previewController!.value.duration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.video_file,
                                size: 24,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Loading...',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Preview label
            Text(
              'Reel Preview',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            // No video selected state
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.border,
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.video_library_outlined,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No video selected',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose a video to create your reel',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Select Video Button
          Container(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _pickVideo,
              icon: Icon(
                Icons.video_library_rounded,
                size: 20,
              ),
              label: Text(
                _videoFile != null || _videoBytes != null
                    ? 'Change Video'
                    : 'Select Video',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.edit_note_rounded,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Add Caption',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _captionController,
            maxLines: 4,
            minLines: 2,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.done,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Write a caption for your reel...',
              hintStyle: TextStyle(
                color: AppColors.textSecondary.withOpacity(0.6),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton() {
    return ModernGradientButton(
      onPressed: _isUploading ? null : _submitReel,
      isLoading: _isUploading,
      text: "Upload Reel",
    );
  }

  // Helper method to format duration
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigitMinutes}:${twoDigitSeconds}";
  }
}

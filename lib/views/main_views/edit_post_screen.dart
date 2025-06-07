import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:social_connect/models/post_model.dart';
import 'package:social_connect/services/feed/feed_service.dart';
import 'package:social_connect/services/users/user_service.dart';
import 'package:social_connect/utils/util_functions/mood.dart';
import 'package:social_connect/utils/util_functions/snackbar_functions.dart';
import 'package:social_connect/utils/app_constants/colors.dart';

class EditPostScreen extends StatefulWidget {
  final Post post;

  const EditPostScreen({required this.post, super.key});

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final _scrollController = ScrollController();

  File? _imageFile;
  Uint8List? _webImage;
  String? _existingImageUrl;
  Mood _selectedMood = Mood.happy;
  bool _isUploading = false;
  bool _showImagePreview = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _uploadController;
  late Animation<double> _uploadAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize with existing post data
    _captionController.text = widget.post.postCaption;
    _selectedMood = widget.post.mood;
    _existingImageUrl = widget.post.postUrl;
    print("Post:${widget.post}");

    _showImagePreview =
        _existingImageUrl != null && _existingImageUrl!.isNotEmpty;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _uploadController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _uploadAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _uploadController, curve: Curves.elasticOut),
    );

    _animationController.forward();
    if (_showImagePreview) {
      _uploadController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _uploadController.dispose();
    _captionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isWebPlatform => kIsWeb;
  bool get _isDesktop =>
      _isWebPlatform && MediaQuery.of(context).size.width > 768;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxHeight: 1080,
        maxWidth: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (_isWebPlatform) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _imageFile = null;
            _showImagePreview = true;
          });
        } else {
          setState(() {
            _imageFile = File(pickedFile.path);
            _webImage = null;
            _showImagePreview = true;
          });
        }
        _uploadController.forward();
      }
    } catch (e) {
      SnackBarFunctions.showErrorSnackBar(
          context, 'Failed to pick image. Please try again.');
    }
  }

  void _submitPost() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_hasImage()) {
        SnackBarFunctions.showErrorSnackBar(
            context, 'Please select an image for your post');
        return;
      }

      try {
        setState(() {
          _isUploading = true;
        });

        final postCaption = _captionController.text.trim();
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          final userDetails = await UserService().getUserById(user.uid);

          if (userDetails != null) {
            final postDetails = {
              'postId': widget.post.postId,
              'postCaption': postCaption,
              'mood': _selectedMood.name,
              'userId': user.uid,
              'username': userDetails.name,
              'profImage': userDetails.imageUrl,
              'postImage': _isWebPlatform ? _webImage : _imageFile,
              'userEmail': user.email ?? '',
              'existingImageUrl': widget.post.postUrl,
            };

            bool isPostUpdated = await FeedService().updatePost(postDetails);

            if (isPostUpdated) {
              SnackBarFunctions.showSuccessSnackBar(
                  context, 'Post updated successfully! 🎉');
              _clearForm();

              await Future.delayed(const Duration(milliseconds: 500));
              if (mounted) {
                GoRouter.of(context).go('/main-screen');
              }
            } else {
              SnackBarFunctions.showErrorSnackBar(
                  context, 'Failed to update post. Please try again.');
            }
          } else {
            SnackBarFunctions.showErrorSnackBar(
                context, 'Failed to fetch user details');
          }
        } else {
          SnackBarFunctions.showErrorSnackBar(
              context, 'Please log in to update a post');
        }
      } catch (e) {
        print('Error in _submitPost: $e');
        SnackBarFunctions.showErrorSnackBar(
            context, 'Failed to update post. Please try again.');
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  }

  bool _hasImage() =>
      (_isWebPlatform ? _webImage != null : _imageFile != null) ||
      (_existingImageUrl != null && _existingImageUrl!.isNotEmpty);

  void _clearForm() {
    _captionController.clear();
    setState(() {
      _imageFile = null;
      _webImage = null;
      _existingImageUrl = null;
      _selectedMood = Mood.happy;
      _showImagePreview = false;
    });
    _uploadController.reset();
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _webImage = null;
      _existingImageUrl = null;
      _showImagePreview = false;
    });
    _uploadController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    AppColors.setDarkMode(isDark);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isDesktop ? _buildDesktopLayout(theme) : _buildMobileLayout(theme),
    );
  }

  Widget _buildDesktopLayout(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: _buildFormSection(theme),
          ),
          Expanded(
            flex: 1,
            child: _buildPreviewSection(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(theme),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: _buildFormContent(theme),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.1),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        title: const Text(
          'Edit Post',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
      ),
    );
  }

  Widget _buildFormSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: _buildFormContent(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Edit Post',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Update your moment',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCaptionInput(theme),
          const SizedBox(height: 24),
          _buildMoodSelector(theme),
          const SizedBox(height: 24),
          _buildImageSection(theme),
          const SizedBox(height: 32),
          _buildActionButtons(theme),
        ],
      ),
    );
  }

  Widget _buildCaptionInput(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _captionController,
        maxLines: 4,
        maxLength: 500,
        decoration: InputDecoration(
          labelText: 'What\'s on your mind?',
          hintText: 'Update your thoughts...',
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.edit,
              color: Colors.white,
              size: 20,
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          labelStyle: theme.textTheme.bodyLarge,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textHint,
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a caption';
          }
          if (value.trim().length < 3) {
            return 'Caption must be at least 3 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildMoodSelector(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.mood,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'How are you feeling?',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                Mood.values.map((mood) => _buildMoodChip(mood, theme)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChip(Mood mood, ThemeData theme) {
    final isSelected = _selectedMood == mood;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMood = mood;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppColors.border.withOpacity(0.3),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mood.emoji,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(width: 8),
            Text(
              mood.name.toLowerCase(),
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.photo_camera,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Update Photo',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_showImagePreview && _hasImage())
            _buildImagePreview(theme)
          else
            _buildImagePicker(theme),
        ],
      ),
    );
  }

  Widget _buildImagePreview(ThemeData theme) {
    return ScaleTransition(
      scale: _uploadAnimation,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: _isDesktop ? 300 : 250,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _isWebPlatform && _webImage != null
                  ? Image.memory(
                      _webImage!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : _imageFile != null
                      ? Image.file(
                          _imageFile!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.network(
                          _existingImageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _removeImage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
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
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          Text(
            'Add a new photo to your post',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose from camera or gallery',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildImagePickerButton(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: () => _pickImage(ImageSource.camera),
                theme: theme,
              ),
              const SizedBox(width: 16),
              _buildImagePickerButton(
                icon: Icons.photo_library,
                label: 'Gallery',
                onTap: () => _pickImage(ImageSource.gallery),
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: _isUploading
                ? LinearGradient(
                    colors: [
                      Colors.grey.shade400,
                      Colors.grey.shade500,
                    ],
                  )
                : AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isUploading
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _isUploading ? null : _submitPost,
              child: Center(
                child: _isUploading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Updating Post...',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.save,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Update Post',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
        if (_hasImage() || _captionController.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: _clearForm,
            child: Text(
              'Clear All',
              style: TextStyle(
                color: AppColors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewSection(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.preview,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Preview',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildPostPreview(theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostPreview(ThemeData theme) {
    final hasContent = _captionController.text.isNotEmpty || _hasImage();

    if (!hasContent) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_off,
              size: 64,
              color: AppColors.textHint.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Your post preview will appear here',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          _selectedMood.emoji,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Feeling ${_selectedMood.name.toLowerCase()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            if (_captionController.text.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _captionController.text,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (_hasImage()) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _isWebPlatform && _webImage != null
                    ? Image.memory(
                        _webImage!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                    : _imageFile != null
                        ? Image.file(
                            _imageFile!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          )
                        : Image.network(
                            _existingImageUrl!,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 20,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.comment_outlined,
                  size: 20,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.share_outlined,
                  size: 20,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

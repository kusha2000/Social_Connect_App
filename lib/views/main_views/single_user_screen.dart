import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:social_connect/models/user_model.dart';
import 'package:social_connect/services/auth/auth_service.dart';
import 'package:social_connect/services/feed/feed_service.dart';
import 'package:social_connect/services/users/user_service.dart';
import 'package:social_connect/utils/app_constants/colors.dart';
import 'package:social_connect/services/providers/theme_provider.dart';
import 'dart:async';

class SingleUserScreen extends StatefulWidget {
  final UserModel user;
  const SingleUserScreen({super.key, required this.user});

  @override
  State<SingleUserScreen> createState() => _SingleUserScreenState();
}

class _SingleUserScreenState extends State<SingleUserScreen>
    with TickerProviderStateMixin {
  late Future<List<String>> _userPosts;
  late Future<bool> _isFollowing;
  late UserService _userService;
  late String _currentUserId;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late AnimationController _toggleController;
  late Animation<double> _toggleAnimation;

  late StreamSubscription<int>? _followersCountSubscription;
  late StreamSubscription<int>? _followingCountSubscription;

  int _followersCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _userService = UserService();
    _currentUserId = AuthService().getCurrentUser()!.uid;
    _userPosts = FeedService().getUserPosts(widget.user.userId);
    _isFollowing = _userService.isFollowing(_currentUserId, widget.user.userId);

    _followersCount = widget.user.followersCount;
    _followingCount = widget.user.followingCount;

    _setupRealTimeListeners();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _toggleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _toggleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _toggleController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
    if (AppColors.isDarkMode) _toggleController.forward();
  }

  void _setupRealTimeListeners() {
    _followersCountSubscription = _userService
        .getFollowersCountStream(widget.user.userId)
        .listen((count) {
      if (mounted) {
        setState(() {
          _followersCount = count;
        });
      }
    }, onError: (error) {
      print('Error listening to followers count: $error');
    });

    _followingCountSubscription = _userService
        .getFollowingCountStream(widget.user.userId)
        .listen((count) {
      if (mounted) {
        setState(() {
          _followingCount = count;
        });
      }
    }, onError: (error) {
      print('Error listening to following count: $error');
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _toggleController.dispose();
    _followersCountSubscription?.cancel();
    _followingCountSubscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleFollow() async {
    try {
      final isFollowing = await _isFollowing;

      if (isFollowing) {
        await _userService.unfollowUser(_currentUserId, widget.user.userId);
        _showSnackBar('Unfollowed ${widget.user.name}', Icons.person_remove);
      } else {
        await _userService.followUser(_currentUserId, widget.user.userId);
        _showSnackBar('Followed ${widget.user.name}', Icons.person_add);
      }

      setState(() {
        _isFollowing =
            _userService.isFollowing(_currentUserId, widget.user.userId);
      });
    } catch (error) {
      _showSnackBar('Error updating follow status', Icons.error, isError: true);
    }
  }

  Future<void> _signOut() async {
    try {
      await AuthService().signOut();
      _showSnackBar('Signed out successfully', Icons.logout);
      GoRouter.of(context).push('/login');
    } catch (error) {
      _showSnackBar('Error signing out', Icons.error, isError: true);
    }
  }

  void _showSnackBar(String message, IconData icon, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 20),
            const SizedBox(width: 8),
            Text(
              message,
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _showFollowersDialog() async {
    try {
      final followers = await _getFollowersList(widget.user.userId);
      if (!mounted) return;

      _showUserListDialog('Followers', followers, Icons.people);
    } catch (e) {
      _showSnackBar('Error loading followers', Icons.error, isError: true);
    }
  }

  Future<void> _showFollowingDialog() async {
    try {
      final following = await _getFollowingList(widget.user.userId);
      if (!mounted) return;

      _showUserListDialog('Following', following, Icons.person_search);
    } catch (e) {
      _showSnackBar('Error loading following list', Icons.error, isError: true);
    }
  }

  Future<List<UserModel>> _getFollowersList(String userId) async {
    return await _userService.getFollowersList(userId);
  }

  Future<List<UserModel>> _getFollowingList(String userId) async {
    return await _userService.getFollowingList(userId);
  }

  void _showUserListDialog(String title, List<UserModel> users, IconData icon) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: AppColors.textPrimary, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: users.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(Icons.people_outline,
                                  size: 64, color: AppColors.textHint),
                              const SizedBox(height: 16),
                              Text(
                                'No users found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final user = users[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundImage: user.imageUrl.isNotEmpty
                                      ? NetworkImage(user.imageUrl)
                                      : const AssetImage('assets/logo.png')
                                          as ImageProvider,
                                ),
                                title: Text(
                                  user.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  user.jobTitle,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: AppColors.textHint,
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SingleUserScreen(user: user),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildToggleSwitch() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: () {
            if (_toggleController.isCompleted) {
              _toggleController.reverse();
            } else {
              _toggleController.forward();
            }
            // Use the ThemeProvider to toggle theme
            themeProvider.toggleTheme();
          },
          child: Container(
            width: 60,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              gradient: LinearGradient(
                colors: AppColors.isDarkMode
                    ? [Colors.grey[800]!, Colors.grey[900]!]
                    : [Colors.blue[300]!, Colors.blue[500]!],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.isDarkMode
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedAlign(
                  alignment: _toggleAnimation.value == 1
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            AppColors.isDarkMode ? Colors.white : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        AppColors.isDarkMode
                            ? Icons.nightlight_round
                            : Icons.wb_sunny,
                        size: 18,
                        color: AppColors.isDarkMode
                            ? Colors.grey[900]
                            : Colors.yellow[700],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 60,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
            ),
            actions: [
              _buildToggleSwitch(),
              const SizedBox(width: 16),
              if (widget.user.userId == _currentUserId)
                IconButton(
                  onPressed: _signOut,
                  icon: Icon(Icons.logout, color: AppColors.textPrimary),
                  tooltip: 'Sign Out',
                ),
              const SizedBox(width: 16),
            ],
          ),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.isDarkMode
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.surface,
                              child: CircleAvatar(
                                radius: 46,
                                backgroundImage: widget.user.imageUrl.isNotEmpty
                                    ? NetworkImage(widget.user.imageUrl)
                                    : const AssetImage('assets/logo.png')
                                        as ImageProvider,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.user.name,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FutureBuilder<List<String>>(
                            future: _userPosts,
                            builder: (context, postsSnapshot) {
                              final postCount = postsSnapshot.hasData
                                  ? postsSnapshot.data!.length.toString()
                                  : '0';

                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatCard(
                                    'Posts',
                                    postCount,
                                    Icons.grid_on,
                                    AppColors.isDarkMode
                                        ? DarkThemeColors.accent2
                                        : LightThemeColors.accent2,
                                    () {},
                                  ),
                                  _buildStatCard(
                                    'Followers',
                                    _followersCount.toString(),
                                    Icons.people,
                                    AppColors.isDarkMode
                                        ? DarkThemeColors.accent3
                                        : LightThemeColors.accent3,
                                    _showFollowersDialog,
                                  ),
                                  _buildStatCard(
                                    'Following',
                                    _followingCount.toString(),
                                    Icons.person_add,
                                    AppColors.secondary,
                                    _showFollowingDialog,
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          if (widget.user.userId != _currentUserId)
                            FutureBuilder<bool>(
                              future: _isFollowing,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Container(
                                    height: 50,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: AppColors.border,
                                      borderRadius: BorderRadius.circular(25),
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Text(
                                    'Error checking follow status',
                                    style: TextStyle(color: AppColors.error),
                                  );
                                }

                                if (!snapshot.hasData) {
                                  return Container();
                                }

                                final isFollowing = snapshot.data!;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _toggleFollow,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isFollowing
                                          ? AppColors.textHint
                                          : AppColors.primary,
                                      foregroundColor: AppColors.textPrimary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          isFollowing
                                              ? Icons.person_remove
                                              : Icons.person_add,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isFollowing ? 'Unfollow' : 'Follow',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.isDarkMode
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.grid_on,
                                color: AppColors.textSecondary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Posts',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 300,
                            child: FutureBuilder<List<String>>(
                              future: _userPosts,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                    ),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 48,
                                          color: AppColors.textHint,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Error loading posts',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.photo_library_outlined,
                                          size: 48,
                                          color: AppColors.textHint,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No posts yet',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                final postImages = snapshot.data!;
                                return GridView.builder(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: postImages.length,
                                  itemBuilder: (context, index) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        postImages[index],
                                        fit: BoxFit.cover,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.border,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: AppColors.border,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.broken_image,
                                              color: AppColors.textHint,
                                              size: 32,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String count,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              count,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

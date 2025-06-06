import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:social_connect/utils/app_constants/colors.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _rotationController;
  late AnimationController _gradientController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _gradientAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _gradientController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Initialize animations
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));

    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOut,
    ));

    // Start animations with delays
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    _scaleController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _slideController.forward();

    _rotationController.repeat();
    _gradientController.repeat(reverse: true);

    // Navigate to main screen after animations
    await Future.delayed(const Duration(seconds: 4));
    _navigateToMainScreen();
  }

  void _navigateToMainScreen() {
    if (mounted) {
      context.go('/');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _rotationController.dispose();
    _gradientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get theme-aware colors
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Use appropriate color sets based on theme
    final backgroundColors = isDark
        ? [
            DarkThemeColors.background,
            DarkThemeColors.surface,
            DarkThemeColors.surfaceVariant,
            DarkThemeColors.primary.withOpacity(0.1),
          ]
        : [
            LightThemeColors.background,
            LightThemeColors.surface,
            LightThemeColors.surfaceVariant,
            LightThemeColors.primary.withOpacity(0.1),
          ];

    final primaryColor = colorScheme.primary;
    final secondaryColor = colorScheme.secondary;
    final accentColor =
        isDark ? DarkThemeColors.accent1 : LightThemeColors.accent1;
    final textSecondary =
        isDark ? DarkThemeColors.textSecondary : LightThemeColors.textSecondary;
    final textHint =
        isDark ? DarkThemeColors.textHint : LightThemeColors.textHint;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([
          _gradientAnimation,
          _fadeAnimation,
          _scaleAnimation,
          _slideAnimation,
          _rotationAnimation,
        ]),
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: backgroundColors,
                stops: [
                  0.0,
                  0.3 + (_gradientAnimation.value * 0.2),
                  0.7 + (_gradientAnimation.value * 0.1),
                  1.0,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Animated background particles
                ...List.generate(
                    6, (index) => _buildFloatingParticle(index, isDark)),

                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo container with rotation and scale
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Transform.rotate(
                            angle: _rotationAnimation.value * 0.1,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    primaryColor,
                                    secondaryColor,
                                    accentColor,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.rocket_launch_rounded,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // App name with slide animation
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [
                                primaryColor,
                                secondaryColor,
                                accentColor,
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'Social Connect',
                              style: GoogleFonts.poppins(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Subtitle
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _slideController,
                          curve:
                              const Interval(0.3, 1.0, curve: Curves.easeOut),
                        )),
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            'Connect with the World',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: textSecondary,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 60),

                      // Loading indicator
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          width: 200,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: colorScheme.surface,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Loading text
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Text(
                          'Loading...',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: textHint,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFloatingParticle(int index, bool isDark) {
    final double size = 20 + (index * 10);
    final double initialX = (index % 3 - 1) * 100;
    final double initialY = (index % 2 - 0.5) * 200;

    // Theme-aware particle colors
    final particleColors = isDark
        ? [
            DarkThemeColors.primary,
            DarkThemeColors.secondary,
            DarkThemeColors.accent1,
            DarkThemeColors.accent2,
            DarkThemeColors.accent3,
          ]
        : [
            LightThemeColors.primary,
            LightThemeColors.secondary,
            LightThemeColors.accent1,
            LightThemeColors.accent2,
            LightThemeColors.accent3,
          ];

    return Positioned(
      left: MediaQuery.of(context).size.width / 2 + initialX,
      top: MediaQuery.of(context).size.height / 2 + initialY,
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              30 * _rotationAnimation.value * (index % 2 == 0 ? 1 : -1),
              20 * _gradientAnimation.value * (index % 3 == 0 ? 1 : -1),
            ),
            child: Opacity(
              opacity: 0.1 + (_fadeAnimation.value * 0.2),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      particleColors[index % 5],
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

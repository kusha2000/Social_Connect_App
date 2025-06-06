import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:social_connect/services/auth/auth_service.dart';
import 'package:social_connect/utils/app_constants/colors.dart';
import 'package:social_connect/utils/util_functions/snackbar_functions.dart';
import 'package:social_connect/widgets/reusable/modern_button.dart';
import 'package:social_connect/widgets/reusable/modern_input.dart';
import 'package:social_connect/utils/app_constants/constants.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await AuthService().sendPasswordResetEmail(_emailController.text.trim());
      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
        SnackBarFunctions.showSuccessSnackBar(context,
            'Reset link sent! Check your email for password reset instructions.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackBarFunctions.showErrorSnackBar(context,
            'Failed to send reset email. Please check your email address.');
      }
    }
  }

  // Check if current screen is web view
  bool _isWebView(double screenWidth) {
    return screenWidth >= webScreenMinWidth;
  }

  Widget _buildMobileLayout(BuildContext context, Size size) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Column(
      children: [
        // Back Button
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: IconButton(
              onPressed: () => GoRouter.of(context).go('/login'),
              icon: Icon(
                Icons.arrow_back_ios,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),

        // Header Section
        Expanded(
          flex: isKeyboardOpen ? 2 : 3,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAppLogo(),
                const SizedBox(height: 32),
                _buildHeaderText(context),
              ],
            ),
          ),
        ),

        // Form Section
        Expanded(
          flex: _emailSent ? 7 : 4,
          child: _emailSent
              ? _buildSuccessMessage(context)
              : _buildForgotPasswordForm(context),
        ),

        // Footer Section
        if (!_emailSent) _buildFooter(context),
      ],
    );
  }

  Widget _buildWebLayout(BuildContext context, Size size) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
          children: [
            // Left side - Welcome section
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAppLogo(),
                      const SizedBox(height: 48),
                      Text(
                        _emailSent ? 'Check Your Email!' : 'Forgot Password?',
                        style:
                            Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  fontSize: 48,
                                ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _emailSent
                            ? 'We\'ve sent password reset instructions to your email address. Please check your inbox and follow the link to reset your password.'
                            : 'Don\'t worry! It happens to everyone. Enter your email address and we\'ll send you a link to reset your password.',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                      ),
                      const SizedBox(height: 32),

                      // Security features
                      if (!_emailSent) _buildSecurityFeatures(),
                    ],
                  ),
                ),
              ),
            ),

            // Right side - Form
            Expanded(
              flex: 4,
              child: Container(
                height: double.infinity,
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    // Back button for web
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => GoRouter.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _emailSent
                                  ? _buildSuccessMessage(context, isWeb: true)
                                  : _buildForgotPasswordForm(context,
                                      isWeb: true),
                              const SizedBox(height: 24),
                              if (!_emailSent)
                                _buildFooter(context, isWeb: true),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(
        Icons.lock_reset,
        size: 60,
        color: Colors.white,
      ),
    );
  }

  Widget _buildHeaderText(BuildContext context) {
    return Column(
      children: [
        Text(
          _emailSent ? 'Check Your Email!' : 'Forgot Password?',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _emailSent
              ? 'We\'ve sent you reset instructions'
              : 'Enter your email to reset password',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSecurityFeatures() {
    final features = [
      {
        'icon': Icons.security_outlined,
        'text': 'Secure password reset process'
      },
      {'icon': Icons.email_outlined, 'text': 'Email verification required'},
      {'icon': Icons.timer_outlined, 'text': 'Reset link expires in 24 hours'},
    ];

    return Column(
      children: features
          .map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      feature['text'] as String,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildForgotPasswordForm(BuildContext context, {bool isWeb = false}) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isWeb ? 40 : 32),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isWeb) ...[
                  Text(
                    'Reset Password',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your email address and we\'ll send you a password reset link',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                ],

                // Email Input
                ModernInput(
                  controller: _emailController,
                  labelText: 'Email Address',
                  hintText: 'Enter your email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Send Reset Email Button
                ModernGradientButton(
                  text: 'Send Reset Link',
                  isLoading: _isLoading,
                  onPressed: _isLoading
                      ? null
                      : () => _sendPasswordResetEmail(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessMessage(BuildContext context, {bool isWeb = false}) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(isWeb ? 40 : 32),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.success.withOpacity(0.1),
                ),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  size: 64,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Email Sent!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 12),

              Text(
                'We\'ve sent password reset instructions to:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                _emailController.text.trim(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              Text(
                'Please check your email and follow the instructions to reset your password. The link will expire in 24 hours.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Resend Email Button
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _emailSent = false;
                        });
                      },
                child: Text(
                  'Send Again',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Back to Login Button
              ModernGradientButton(
                text: 'Back to Login',
                onPressed: () => GoRouter.of(context).go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, {bool isWeb = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isWeb ? 0 : 24),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Remember your password? ",
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            GestureDetector(
              onTap: () => GoRouter.of(context).go('/login'),
              child: Text(
                'Sign In',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = _isWebView(size.width);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: isWeb
              ? _buildWebLayout(context, size)
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    height: size.height - MediaQuery.of(context).padding.top,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildMobileLayout(context, size),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/toast_util.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _onEmailAuth() async {
    // Drop the keyboard first, otherwise the bottom-anchored toast renders
    // behind it and is never seen (esp. after sign-up, which stays on-screen).
    FocusScope.of(context).unfocus();
    final isSignUp = ref.read(authFormProvider).isSignUp;
    final needsUsername = isSignUp && _usernameCtrl.text.trim().isEmpty;
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty || needsUsername) {
      ToastUtil.warning(context, 'Please fill in all fields');
      return;
    }

    if (isSignUp) {
      final ok = await ref.read(authProvider.notifier).register(
            email: _emailCtrl.text.trim(),
            username: _usernameCtrl.text.trim(),
            password: _passCtrl.text,
          );
      if (!mounted) return;
      final auth = ref.read(authProvider);
      if (ok) {
        ToastUtil.success(
          context,
          auth.message ?? 'Account created successfully',
        );
        context.go(AppConstants.routeHome);
      } else {
        ToastUtil.error(context, auth.error ?? 'Registration failed');
      }
      return;
    }

    final ok = await ref
        .read(authProvider.notifier)
        .signInWithEmail(_emailCtrl.text.trim(), _passCtrl.text);
    if (!mounted) return;
    if (ok) {
      // Toast on the root overlay survives the route change to home.
      ToastUtil.success(
        context,
        ref.read(authProvider).message ?? 'Welcome back! 👋',
      );
      context.go(AppConstants.routeHome);
    } else {
      ToastUtil.error(context, ref.read(authProvider).error ?? 'Login failed');
    }
  }

  // Future<void> _onGoogle() async {
  //   await ref.read(authProvider.notifier).signInWithGoogle();
  //   if (mounted) context.go(AppConstants.routeHome);
  // }

  // Future<void> _onApple() async {
  //   await ref.read(authProvider.notifier).signInWithApple();
  //   if (mounted) context.go(AppConstants.routeHome);
  // }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final form = ref.watch(authFormProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background orbs
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withValues(alpha: 0.12),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),
                  // Logo
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.bolt_rounded,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 12),
                      ShaderMask(
                        shaderCallback: (b) =>
                            AppColors.primaryGradient.createShader(b),
                        child: Text(
                          'VibeLink',
                          style: AppTextStyles.headlineLarge
                              .copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 40),
                  Text(
                    form.isSignUp
                        ? 'Create your\naccount ✨'
                        : 'Welcome\nback 👋',
                    style: AppTextStyles.displayMedium,
                  )
                      .animate(delay: 100.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 8),
                  Text(
                    form.isSignUp
                        ? 'Join the real-world social revolution'
                        : 'Your vibe squad is waiting for you',
                    style: AppTextStyles.bodyMedium,
                  ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
                  const SizedBox(height: 36),
                  // Social buttons
                  // _SocialAuthButton(
                  //   label: 'Continue with Google',
                  //   emoji: 'G',
                  //   onTap: _onGoogle,
                  //   isLoading: auth.isLoading,
                  // ).animate(delay: 250.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                  // const SizedBox(height: 12),
                  // _SocialAuthButton(
                  //   label: 'Continue with Apple',
                  //   emoji: '',
                  //   icon: Icons.apple_rounded,
                  //   onTap: _onApple,
                  //   isLoading: auth.isLoading,
                  // ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                  // const SizedBox(height: 24),
                  // // Divider
                  // Row(
                  //   children: [
                  //     Expanded(child: Divider(color: AppColors.cardBorder)),
                  //     Padding(
                  //       padding: const EdgeInsets.symmetric(horizontal: 16),
                  //       child: Text('or', style: AppTextStyles.bodySmall),
                  //     ),
                  //     Expanded(child: Divider(color: AppColors.cardBorder)),
                  //   ],
                  // ).animate(delay: 350.ms).fadeIn(),
                  const SizedBox(height: 24),
                  // Email field
                  _GlassTextField(
                    controller: _emailCtrl,
                    hint: 'Email address',
                    icon: Icons.email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  )
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 12),
                  // Username field (sign up only)
                  if (form.isSignUp) ...[
                    _GlassTextField(
                      controller: _usernameCtrl,
                      hint: 'Username',
                      icon: Icons.person_rounded,
                      keyboardType: TextInputType.name,
                    )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 12),
                  ],
                  // Password field
                  _GlassTextField(
                    controller: _passCtrl,
                    hint: 'Password',
                    icon: Icons.lock_rounded,
                    obscure: form.obscurePassword,
                    suffix: IconButton(
                      icon: Icon(
                        form.obscurePassword
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () =>
                          ref.read(authFormProvider.notifier).toggleObscure(),
                    ),
                  )
                      .animate(delay: 450.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 28),
                  GradientButton(
                    label: form.isSignUp ? 'Create Account' : 'Sign In',
                    onTap: _onEmailAuth,
                    isLoading: auth.isLoading,
                    width: double.infinity,
                  ).animate(delay: 500.ms).fadeIn(duration: 400.ms),
                  const SizedBox(height: 24),
                  Center(
                    child: GestureDetector(
                      onTap: () =>
                          ref.read(authFormProvider.notifier).toggleMode(),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: form.isSignUp
                                  ? 'Already have an account? '
                                  : 'Don\'t have an account? ',
                              style: AppTextStyles.bodyMedium,
                            ),
                            TextSpan(
                              text: form.isSignUp ? 'Sign In' : 'Sign Up',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate(delay: 550.ms).fadeIn(duration: 400.ms),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassTextField extends StatelessWidget {
  const _GlassTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textHint,
            ),
            prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
            suffixIcon: suffix,
            filled: true,
            fillColor: AppColors.cardBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppColors.primaryLight, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ),
    );
  }
}

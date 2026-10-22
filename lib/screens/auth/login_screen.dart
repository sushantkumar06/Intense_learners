import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:dio/dio.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../components/ui/ui.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'STUDENT';
  bool _showPassword = false;
  String _error = "";
  bool _loading = false;
  DateTime? _lastBackPressTime;

  void _handlePop() {
    final now = DateTime.now();
    if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Press back again to exit',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.only(bottom: 24, left: 32, right: 32),
        ),
      );
      return;
    }
    SystemNavigator.pop();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = "Please fill in all fields");
      return;
    }

    setState(() {
      _error = "";
      _loading = true;
    });

    try {
      await ref.read(authProvider.notifier).login(email, password, _role);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.response?.data?['error'] ?? "Something went wrong. Please try again.";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Something went wrong. Please try again.";
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handlePop();
      },
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: SingleChildScrollView(
        child: Column(
          children: [
            // Brand hero banner
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              padding: const EdgeInsets.only(
                top: 72,
                bottom: 48,
                left: 24,
                right: 24,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: -50,
                    left: -40,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0x0DFFFFFF),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: AppRadius.lgBorder,
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 64,
                          height: 64,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: AppRadius.lgBorder,
                            ),
                            child: const Icon(
                              LucideIcons.graduationCap,
                              color: AppColors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome Back',
                        style: AppTypography.h1.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to continue learning',
                        style: AppTypography.body.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Form card
            Transform.translate(
              offset: const Offset(0, -28),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AppCard(
                  elevation: AppCardElevation.raised,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.coralTint,
                            borderRadius: AppRadius.mdBorder,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.alertCircle,
                                color: AppColors.coral,
                                size: 17,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.coral,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      Text(
                        'I am a:',
                        style: AppTypography.label.copyWith(
                          color: AppColors.ink,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Role toggles
                      Row(
                        children: [
                          Expanded(
                            child: _buildRoleButton(
                              roleValue: 'STUDENT',
                              label: 'Student',
                              icon: LucideIcons.graduationCap,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildRoleButton(
                              roleValue: 'TEACHER',
                              label: 'Teacher',
                              icon: LucideIcons.userCheck,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      AppInput(
                        label: 'Email Address',
                        controller: _emailController,
                        placeholder: 'you@example.com',
                        keyboardType: TextInputType.emailAddress,
                        leftIcon: Icon(
                          LucideIcons.mail,
                          size: 17,
                          color: AppColors.inkFaint,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      AppInput(
                        label: 'Password',
                        controller: _passwordController,
                        placeholder: 'Enter your password',
                        obscureText: !_showPassword,
                        leftIcon: Icon(
                          LucideIcons.lock,
                          size: 17,
                          color: AppColors.inkFaint,
                        ),
                        rightIcon: AnimatedPressable(
                          pressScale: 0.85,
                          onPress: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                          child: Icon(
                            _showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                            size: 17,
                            color: AppColors.inkFaint,
                          ),
                        ),
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: AnimatedPressable(
                          pressScale: 0.95,
                          onPress: () => context.push('/forgot-password'),
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: AppSpacing.sm,
                              bottom: AppSpacing.lg,
                            ),
                            child: Text(
                              'Forgot password?',
                              style: AppTypography.label.copyWith(
                                color: AppColors.indigo,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ),
                      ),

                      AppButton(
                        label: 'Sign In',
                        onPress: _handleSubmit,
                        loading: _loading,
                        fullWidth: true,
                        size: AppButtonSize.lg,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: AppTypography.body.copyWith(
                              color: AppColors.inkMuted,
                              fontSize: 13,
                            ),
                          ),
                          AnimatedPressable(
                            pressScale: 0.95,
                            onPress: () => context.push('/register'),
                            child: Text(
                              'Sign up for free',
                              style: AppTypography.label.copyWith(
                                color: AppColors.indigo,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildRoleButton({
    required String roleValue,
    required String label,
    required IconData icon,
  }) {
    final active = _role == roleValue;
    return AnimatedPressable(
      pressScale: 0.96,
      onPress: () => setState(() => _role = roleValue),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: active ? AppColors.indigoTint : AppColors.surface,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(
            color: active ? AppColors.indigo : AppColors.border,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? AppColors.indigo : AppColors.inkFaint,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.label.copyWith(
                color: active ? AppColors.indigo : AppColors.inkMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

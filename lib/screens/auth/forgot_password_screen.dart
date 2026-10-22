import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../components/safe_back_scope.dart';
import '../../components/ui/ui.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  String _step = "email"; // "email" | "sent"
  bool _loading = false;
  String _error = "";

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = "Please enter your email");
      return;
    }

    setState(() {
      _error = "";
      _loading = true;
    });

    try {
      await ref.read(dioProvider).post("/api/auth/forgot-password", data: {"email": email});
      if (!mounted) return;
      setState(() => _step = "sent");
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _error = err.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmailStep = _step == "email";

    return SafeBackScope(
      fallbackLocation: '/login',
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
                  top: 56,
                  bottom: 52,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedPressable(
                        pressScale: 0.92,
                        onPress: () => context.canPop()
                            ? context.pop()
                            : context.go('/login'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              borderRadius: AppRadius.smBorder,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              LucideIcons.arrowLeft,
                              size: 18,
                              color: AppColors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Back to Sign In',
                            style: AppTypography.label.copyWith(
                              color: AppColors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.lgBorder,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.keyRound,
                      size: 28,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isEmailStep ? 'Forgot Password?' : 'Check Your Email',
                    style: AppTypography.h2.copyWith(
                      color: AppColors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      isEmailStep
                          ? "No worries! Enter your email and we'll send you reset instructions."
                          : "We've sent a password reset link to ${_emailController.text}",
                      style: AppTypography.body.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        height: 19 / 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
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
                      if (isEmailStep) ...[
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
                        const SizedBox(height: AppSpacing.lg),

                        AppButton(
                          label: 'Send Reset Link',
                          onPress: _handleSubmit,
                          loading: _loading,
                          fullWidth: true,
                          size: AppButtonSize.lg,
                        ),
                      ] else ...[
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.mintTint,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  LucideIcons.checkCircle2,
                                  size: 30,
                                  color: AppColors.mint,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                "Click the link in the email to reset your password. Check your spam folder if you don't see it.",
                                style: AppTypography.body.copyWith(
                                  color: AppColors.inkMuted,
                                  fontSize: 13,
                                  height: 19 / 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              AnimatedPressable(
                                pressScale: 0.95,
                                onPress: () {
                                  setState(() {
                                    _step = "email";
                                    _error = "";
                                  });
                                },
                                child: Text(
                                  "Didn't receive it? Try again",
                                  style: AppTypography.label.copyWith(
                                    color: AppColors.indigo,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: AppSpacing.lg),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Remembered your password? ',
                            style: AppTypography.body.copyWith(
                              color: AppColors.inkMuted,
                              fontSize: 13,
                            ),
                          ),
                          AnimatedPressable(
                            pressScale: 0.95,
                            onPress: () => context.canPop()
                                ? context.pop()
                                : context.go('/login'),
                            child: Text(
                              'Sign in',
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
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:dio/dio.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../components/safe_back_scope.dart';
import '../../components/ui/ui.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const _teacherRegistrationCode = "P8YGJCVR2";

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _teacherCodeController = TextEditingController();

  String _role = 'STUDENT';
  bool _showPassword = false;
  String _error = "";
  String _success = "";
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _teacherCodeController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    setState(() {
      _error = "";
      _success = "";
    });

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final teacherCode = _teacherCodeController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _error = "Please fill in all fields");
      return;
    }

    if (password != confirmPassword) {
      setState(() => _error = "Passwords do not match!");
      return;
    }

    if (password.length < 6) {
      setState(() => _error = "Password must be at least 6 characters long");
      return;
    }

    if (_role == "TEACHER" && teacherCode != _teacherRegistrationCode) {
      setState(() => _error = "Invalid teacher registration code.");
      return;
    }

    setState(() => _loading = true);

    try {
      await ref.read(authProvider.notifier).register(name, email, password, _role);
      if (!mounted) return;
      setState(() => _success = "Account created! Redirecting...");
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data?['error'] ?? "Something went wrong";
      setState(() {
        _error = msg.toString().contains("already registered")
            ? "This email is already registered. Please login instead."
            : msg.toString();
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
                  bottom: 44,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        AnimatedPressable(
                          pressScale: 0.92,
                          onPress: () => context.canPop()
                              ? context.pop()
                              : context.go('/login'),
                        child: Row(
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
                              'Back',
                              style: AppTypography.label.copyWith(
                                color: AppColors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Create Account',
                    style: AppTypography.h1.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start your journey today',
                    style: AppTypography.body.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),

            // Form card
            Transform.translate(
              offset: const Offset(0, -24),
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

                      if (_success.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.mintTint,
                            borderRadius: AppRadius.mdBorder,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.checkCircle2,
                                color: AppColors.mint,
                                size: 17,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _success,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.mint,
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
                        'I want to register as:',
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

                      if (_role == 'TEACHER') ...[
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.goldTint,
                            borderRadius: AppRadius.mdBorder,
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    LucideIcons.keyRound,
                                    size: 14,
                                    color: AppColors.gold,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Teacher Registration Code *',
                                    style: AppTypography.label.copyWith(
                                      color: const Color(0xFF8A6816),
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              AppInput(
                                controller: _teacherCodeController,
                                placeholder: 'Enter teacher code',
                                onChanged: (text) {
                                  _teacherCodeController.value = TextEditingValue(
                                    text: text.toUpperCase(),
                                    selection: TextSelection.collapsed(offset: text.length),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      AppInput(
                        label: 'Full Name',
                        controller: _nameController,
                        placeholder: 'Vivek Kumar Jha',
                        leftIcon: Icon(
                          LucideIcons.user,
                          size: 17,
                          color: AppColors.inkFaint,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

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
                        placeholder: 'Create a strong password',
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
                      const SizedBox(height: AppSpacing.md),

                      AppInput(
                        label: 'Confirm Password',
                        controller: _confirmPasswordController,
                        placeholder: 'Confirm your password',
                        obscureText: !_showPassword,
                        leftIcon: Icon(
                          LucideIcons.lock,
                          size: 17,
                          color: AppColors.inkFaint,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      AppButton(
                        label: 'Create Account',
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
                            'Already have an account? ',
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

  Widget _buildRoleButton({
    required String roleValue,
    required String label,
    required IconData icon,
  }) {
    final active = _role == roleValue;
    return AnimatedPressable(
      pressScale: 0.96,
      onPress: () {
        setState(() {
          _role = roleValue;
          _teacherCodeController.clear();
          _error = "";
        });
      },
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

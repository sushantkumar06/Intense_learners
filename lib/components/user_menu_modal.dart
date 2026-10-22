import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/ui_provider.dart';
import '../theme/app_theme.dart';

class UserMenuModal extends ConsumerWidget {
  const UserMenuModal({super.key});

  static void show(BuildContext context) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) => const UserMenuModal(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 200),
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.5),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    
    final String name = user?['name'] ?? '';
    final String email = user?['email'] ?? '';
    final String initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final String role = user?['role'] ?? 'STUDENT';

    final String? avatarUrl = user?['avatar']?.toString();

    return Stack(
      children: [
        Positioned(
          top: 96,
          right: 16,
          width: 260,
          child: Material(
            color: Colors.transparent,
            child: GlassContainer(
              borderRadius: BorderRadius.circular(20),
              blur: kGlassBlurSigma,
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Profile header (tappable to view profile)
                  InkWell(
                    onTap: () {
                      final router = GoRouter.of(context);
                      Navigator.of(context, rootNavigator: true).pop();
                      if (role == 'STUDENT') {
                        router.push('/student/profile');
                      } else {
                        router.push('/shared/edit-profile');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: AppColors.indigo,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: avatarUrl != null && avatarUrl.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      avatarUrl,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Text(
                                        initials,
                                        style: const TextStyle(
                                          color: AppColors.onIndigo,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  )
                                : Text(
                                    initials,
                                    style: const TextStyle(
                                      color: AppColors.onIndigo,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name.isNotEmpty ? name : 'My Account',
                                  style: const TextStyle(
                                    color: AppColors.ink,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    color: AppColors.inkMuted,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: AppColors.inkMuted,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Menu Items
                  _buildMenuItem(
                    icon: LucideIcons.edit,
                    label: 'Edit Profile',
                    onTap: () {
                      final router = GoRouter.of(context);
                      Navigator.of(context, rootNavigator: true).pop();
                      router.push('/shared/edit-profile');
                    },
                  ),
                  _buildMenuItem(
                    icon: LucideIcons.settings,
                    label: 'Settings',
                    onTap: () {
                      final router = GoRouter.of(context);
                      Navigator.of(context, rootNavigator: true).pop();
                      router.push('/shared/settings');
                    },
                  ),
                  _buildMenuItem(
                    icon: LucideIcons.moon,
                    label: 'Dark Mode',
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dark mode is active in the app.')),
                      );
                    },
                  ),

                  if (role == 'TEACHER') ...[
                    const Divider(height: 1, color: Color(0x1AFFFFFF)),
                    Consumer(
                      builder: (context, ref, _) {
                        final viewMode = ref.watch(uiProvider).viewMode;
                        return _buildMenuItem(
                          icon: LucideIcons.eye,
                          label: 'Switch to ${viewMode == 'teacher' ? 'Student' : 'Teacher'} View',
                          onTap: () {
                            final router = GoRouter.of(context);
                            Navigator.of(context, rootNavigator: true).pop();
                            final newMode = viewMode == 'teacher' ? 'student' : 'teacher';
                            ref.read(uiProvider.notifier).setViewMode(newMode);
                            if (newMode == 'teacher') {
                              router.go('/teacher');
                            } else {
                              router.go('/student/dashboard');
                            }
                          },
                        );
                      },
                    ),
                  ],

                  const Divider(height: 1, color: Color(0x1AFFFFFF)),
                  _buildMenuItem(
                    icon: LucideIcons.logOut,
                    label: 'Logout',
                    labelColor: AppColors.coral,
                    iconColor: AppColors.coral,
                    onTap: () {
                      Navigator.of(context, rootNavigator: true).pop();
                      ref.read(authProvider.notifier).logout();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color labelColor = AppColors.ink,
    Color iconColor = AppColors.indigo,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 14,
                fontWeight: labelColor == AppColors.coral ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


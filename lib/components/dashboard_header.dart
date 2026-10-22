import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_theme.dart';
import 'ui/animated_pressable.dart';
import 'user_menu_modal.dart';

class DashboardHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const DashboardHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 4, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: AppRadius.smBorder,
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 38,
                    height: 38,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: AppRadius.smBorder,
                      ),
                      child: const Icon(
                        LucideIcons.graduationCap,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.label.copyWith(
                          color: AppColors.white,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        Text(
                          subtitle!,
                          style: AppTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          AnimatedPressable(
            pressScale: 0.9,
            onPress: () => UserMenuModal.show(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: AppRadius.mdBorder,
              ),
              alignment: Alignment.center,
              child: const Icon(LucideIcons.user, size: 18, color: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

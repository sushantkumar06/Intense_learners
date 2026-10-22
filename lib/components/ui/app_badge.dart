import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum AppBadgeTone { neutral, brand, gold, success, danger }

class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeTone tone;
  final Widget? icon;

  const AppBadge({
    super.key,
    required this.label,
    this.tone = AppBadgeTone.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;

    switch (tone) {
      case AppBadgeTone.neutral:
        bg = const Color(0x1AFFFFFF);
        fg = AppColors.inkMuted;
        border = Border.all(color: const Color(0x26FFFFFF), width: 1);
        break;
      case AppBadgeTone.brand:
        bg = const Color(0x262EE6C5);
        fg = AppColors.indigo;
        border = Border.all(color: const Color(0x522EE6C5), width: 1);
        break;
      case AppBadgeTone.gold:
        bg = const Color(0x26FFD166);
        fg = AppColors.gold;
        border = Border.all(color: const Color(0x52FFD166), width: 1);
        break;
      case AppBadgeTone.success:
        bg = const Color(0x262EE6A8);
        fg = AppColors.mint;
        border = Border.all(color: const Color(0x522EE6A8), width: 1);
        break;
      case AppBadgeTone.danger:
        bg = const Color(0x26FF6B6B);
        fg = AppColors.coral;
        border = Border.all(color: const Color(0x52FF6B6B), width: 1);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.pillBorder,
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: AppTypography.label.copyWith(
                color: fg,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

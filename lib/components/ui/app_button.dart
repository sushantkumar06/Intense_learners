import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'animated_pressable.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive }
enum AppButtonSize { sm, md, lg }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPress;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final Widget? iconWidget;
  final bool iconOnRight;
  final bool loading;
  final bool disabled;
  final bool fullWidth;
  final EdgeInsetsGeometry? customPadding;

  const AppButton({
    super.key,
    required this.label,
    required this.onPress,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.iconWidget,
    this.iconOnRight = false,
    this.loading = false,
    this.disabled = false,
    this.fullWidth = false,
    this.customPadding,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;
    List<BoxShadow>? shadow;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = AppColors.indigo; // #2EE6C5 bright aqua
        fg = AppColors.onIndigo; // #0F2027 dark teal label
        border = null;
        shadow = (disabled || loading) ? null : kAccentGlowShadow;
        break;
      case AppButtonVariant.secondary:
        bg = const Color(0x1F2EE6C5);
        fg = AppColors.indigo;
        border = Border.all(color: const Color(0x522EE6C5), width: 1);
        shadow = null;
        break;
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = AppColors.indigo;
        border = Border.all(color: AppColors.border, width: 1);
        shadow = null;
        break;
      case AppButtonVariant.destructive:
        bg = AppColors.coralTint;
        fg = AppColors.coral;
        border = Border.all(color: const Color(0x52FF6B6B), width: 1);
        shadow = null;
        break;
    }

    if (disabled || loading) {
      fg = fg.withValues(alpha: 0.45);
      bg = bg.withValues(alpha: 0.3);
      shadow = null;
    }

    double paddingV;
    double paddingH;
    double fontSize;
    double iconSize;

    switch (size) {
      case AppButtonSize.sm:
        paddingV = 8;
        paddingH = 14;
        fontSize = 13;
        iconSize = 16;
        break;
      case AppButtonSize.md:
        paddingV = 13;
        paddingH = 20;
        fontSize = 15;
        iconSize = 18;
        break;
      case AppButtonSize.lg:
        paddingV = 16;
        paddingH = 24;
        fontSize = 16;
        iconSize = 20;
        break;
    }

    Widget? renderedIcon = iconWidget;
    if (renderedIcon == null && icon != null) {
      renderedIcon = Icon(icon, size: iconSize, color: fg);
    }

    Widget content;
    if (loading) {
      content = SizedBox(
        width: iconSize,
        height: iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    } else {
      content = Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (renderedIcon != null && !iconOnRight) ...[
            renderedIcon,
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTypography.label.copyWith(
                color: fg,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (renderedIcon != null && iconOnRight) ...[
            const SizedBox(width: AppSpacing.sm),
            renderedIcon,
          ],
        ],
      );
    }

    return AnimatedPressable(
      onPress: onPress,
      disabled: disabled || loading,
      pressScale: 0.95,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: customPadding ?? EdgeInsets.symmetric(vertical: paddingV, horizontal: paddingH),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.pillBorder,
          border: border,
          boxShadow: shadow,
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );
  }
}


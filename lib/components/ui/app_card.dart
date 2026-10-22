import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'animated_pressable.dart';

enum AppCardElevation { flat, raised }

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPress;
  final AppCardElevation elevation;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Border? border;
  final double? blur;

  const AppCard({
    super.key,
    required this.child,
    this.onPress,
    this.elevation = AppCardElevation.flat,
    this.padding,
    this.borderRadius,
    this.backgroundColor,
    this.border,
    this.blur,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? AppRadius.lgBorder;
    final effectivePadding = padding ?? const EdgeInsets.all(AppSpacing.lg);
    final isRaised = elevation == AppCardElevation.raised;
    final effectiveBlur = blur ?? (isRaised ? kGlassBlurSigma : 0.0);

    final cardContent = GlassContainer(
      borderRadius: effectiveRadius,
      padding: effectivePadding,
      blur: effectiveBlur,
      fillGradient: backgroundColor != null
          ? LinearGradient(colors: [backgroundColor!, backgroundColor!])
          : null,
      borderColor: border?.top.color,
      borderWidth: border?.top.width ?? 1.0,
      boxShadow: isRaised
          ? kGlassCardShadow
          : const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
      child: child,
    );

    if (onPress != null) {
      return AnimatedPressable(
        onPress: onPress,
        pressScale: 0.98,
        child: cardContent,
      );
    }

    return cardContent;
  }
}


import 'dart:ui';
import 'package:flutter/material.dart';

/// Shared blur sigma for all frosted glass surfaces.
const double kGlassBlurSigma = 24.0;

/// Shared rim light gradient for glass cards and panels.
const LinearGradient kGlassRimGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0x66FFFFFF), // bright rim at top-left (~40% white)
    Color(0x14FFFFFF), // subtle fade at bottom-right (~8% white)
  ],
);

/// Shared glass card fill gradient.
const LinearGradient kGlassCardFillGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0x42385D6E), // translucent teal-tinted white (~26% alpha)
    Color(0x241E3845), // darker translucent teal at bottom-right (~14% alpha)
  ],
);

/// Shared glass modal / bottom sheet fill gradient (deep teal frosted glass).
const LinearGradient kGlassModalFillGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xF2162C36), // rich dark teal frosted modal (~95% alpha)
    Color(0xF50F2027), // deep dark teal at bottom (~96% alpha)
  ],
);


/// Shared soft ambient shadow for glass surfaces.
const List<BoxShadow> kGlassCardShadow = [
  BoxShadow(
    color: Color(0x40000000), // black at 25% opacity
    blurRadius: 30,
    offset: Offset(0, 12),
    spreadRadius: 0,
  ),
];

/// Shared glowing shadow for primary aqua buttons.
const List<BoxShadow> kAccentGlowShadow = [
  BoxShadow(
    color: Color(0x522EE6C5), // aqua accent at ~32% opacity
    blurRadius: 20,
    offset: Offset(0, 6),
    spreadRadius: 0,
  ),
];

/// ThemeExtension holding glassmorphism design tokens.
class GlassTheme extends ThemeExtension<GlassTheme> {
  final double blurSigma;
  final Gradient backgroundGradient;
  final Gradient cardFillGradient;
  final Gradient rimGradient;
  final Color accent;
  final Color onAccent;
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> accentGlow;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  const GlassTheme({
    this.blurSigma = kGlassBlurSigma,
    this.backgroundGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF0F2027),
        Color(0xFF203A43),
        Color(0xFF2C5364),
      ],
      stops: [0.0, 0.5, 1.0],
    ),
    this.cardFillGradient = kGlassCardFillGradient,
    this.rimGradient = kGlassRimGradient,
    this.accent = const Color(0xFF2EE6C5),
    this.onAccent = const Color(0xFF0F2027),
    this.cardShadow = kGlassCardShadow,
    this.accentGlow = kAccentGlowShadow,
    this.textPrimary = const Color(0xFFFFFFFF),
    this.textSecondary = const Color(0xA3FFFFFF), // ~64% white
    this.textMuted = const Color(0x7AFFFFFF),     // ~48% white
  });

  @override
  ThemeExtension<GlassTheme> copyWith({
    double? blurSigma,
    Gradient? backgroundGradient,
    Gradient? cardFillGradient,
    Gradient? rimGradient,
    Color? accent,
    Color? onAccent,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? accentGlow,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
  }) {
    return GlassTheme(
      blurSigma: blurSigma ?? this.blurSigma,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      cardFillGradient: cardFillGradient ?? this.cardFillGradient,
      rimGradient: rimGradient ?? this.rimGradient,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      cardShadow: cardShadow ?? this.cardShadow,
      accentGlow: accentGlow ?? this.accentGlow,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  ThemeExtension<GlassTheme> lerp(ThemeExtension<GlassTheme>? other, double t) {
    if (other is! GlassTheme) return this;
    return GlassTheme(
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t) ?? blurSigma,
      backgroundGradient: Gradient.lerp(backgroundGradient, other.backgroundGradient, t) ?? backgroundGradient,
      cardFillGradient: Gradient.lerp(cardFillGradient, other.cardFillGradient, t) ?? cardFillGradient,
      rimGradient: Gradient.lerp(rimGradient, other.rimGradient, t) ?? rimGradient,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      onAccent: Color.lerp(onAccent, other.onAccent, t) ?? onAccent,
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t) ?? cardShadow,
      accentGlow: BoxShadow.lerpList(accentGlow, other.accentGlow, t) ?? accentGlow,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      textMuted: Color.lerp(textMuted, other.textMuted, t) ?? textMuted,
    );
  }
}

/// Global static background with 3-stop diagonal gradient and soft radial ambient glow orbs.
class GlassBackground extends StatelessWidget {
  final Widget child;

  const GlassBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Static ambient background layer - never intercepts touches or causes re-layouts
        Positioned.fill(
          child: RepaintBoundary(
            child: IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 3-stop diagonal dark teal gradient: #0F2027 -> #203A43 -> #2C5364
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0F2027),
                          Color(0xFF203A43),
                          Color(0xFF2C5364),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  // Glow orb 1: Upper-left bright aqua ambient glow (18% opacity)
                  Positioned(
                    top: -120,
                    left: -120,
                    width: 440,
                    height: 440,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF2EE6C5).withValues(alpha: 0.18),
                            const Color(0xFF2EE6C5).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Glow orb 2: Lower-right subtle teal ambient glow (14% opacity)
                  Positioned(
                    bottom: -140,
                    right: -100,
                    width: 420,
                    height: 420,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF2EE6C5).withValues(alpha: 0.13),
                            const Color(0xFF203A43).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Glow orb 3: Center-mid soft ambient glow (12% opacity)
                  Positioned(
                    top: 260,
                    right: -80,
                    width: 300,
                    height: 300,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF2C5364).withValues(alpha: 0.15),
                            const Color(0xFF2C5364).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // App content sitting above the background
        child,
      ],
    );
  }
}

/// Reusable frosted glass container with rim light, frosted blur, and soft shadow.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final Gradient? fillGradient;
  final Gradient? rimGradient;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final Clip clipBehavior;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = kGlassBlurSigma,
    this.fillGradient,
    this.rimGradient,
    this.borderColor,
    this.borderWidth = 1.0,
    this.boxShadow,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(28);
    final effectiveFill = fillGradient ?? kGlassCardFillGradient;
    final effectiveRim = rimGradient ?? kGlassRimGradient;
    final effectiveShadow = boxShadow ?? kGlassCardShadow;

    // Outer container holding shadow and outer rim gradient
    Widget box = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: effectiveShadow,
        gradient: borderColor == null ? effectiveRim : null,
        color: borderColor,
      ),
      padding: EdgeInsets.all(borderWidth),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular((effectiveRadius.topLeft.x - borderWidth).clamp(0.0, 999.0)),
          topRight: Radius.circular((effectiveRadius.topRight.x - borderWidth).clamp(0.0, 999.0)),
          bottomLeft: Radius.circular((effectiveRadius.bottomLeft.x - borderWidth).clamp(0.0, 999.0)),
          bottomRight: Radius.circular((effectiveRadius.bottomRight.x - borderWidth).clamp(0.0, 999.0)),
        ),
        clipBehavior: clipBehavior,
        child: blur > 0
            ? RepaintBoundary(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: effectiveFill,
                    ),
                    child: Padding(
                      padding: padding ?? EdgeInsets.zero,
                      child: child,
                    ),
                  ),
                ),
              )
            : DecoratedBox(
                decoration: BoxDecoration(
                  gradient: effectiveFill,
                ),
                child: Padding(
                  padding: padding ?? EdgeInsets.zero,
                  child: child,
                ),
              ),
      ),
    );

    return box;
  }
}

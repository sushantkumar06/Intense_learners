import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'glass_theme.dart';

export 'glass_theme.dart';

/// Design tokens matching the unified Dark Teal Glassmorphism design system.
class AppColors {
  AppColors._();

  // Neutrals (White hierarchy over dark teal glass)
  static const Color ink = Color(0xFFFFFFFF); // primary text, headings (pure white)
  static const Color inkMuted = Color(0xA3FFFFFF); // secondary text, captions (~64% white)
  static const Color inkFaint = Color(0x7AFFFFFF); // placeholder / disabled text (~48% white)
  static const Color paper = Colors.transparent; // app background reveals global glass gradient
  static const Color surface = Color(0x38355666); // translucent teal-tinted glass card surface
  static const Color surfaceMuted = Color(0x1AFFFFFF); // subtle input/chip glass fill (~10% white)
  static const Color border = Color(0x2EFFFFFF); // 1px hairline rim divider (~18% white)

  // Brand Accent (Bright Aqua #2EE6C5)
  static const Color indigo = Color(0xFF2EE6C5); // primary accent
  static const Color indigoDark = Color(0xFF1FCFB0); // deep aqua hover/press
  static const Color indigoTint = Color(0x2E2EE6C5); // subtle aqua glow wash (~18% opacity)

  // On-Accent text/icon color
  static const Color onIndigo = Color(0xFF0F2027); // dark teal text on primary aqua buttons

  // Accents — harmonized with the dark teal palette
  static const Color gold = Color(0xFFFFD166); // achievement: streaks, ratings, top rated
  static const Color goldTint = Color(0x29FFD166);
  static const Color coral = Color(0xFFFF6B6B); // urgent/destructive only: errors, delete (soft coral)
  static const Color coralTint = Color(0x29FF6B6B);
  static const Color mint = Color(0xFF2EE6A8); // success/confirmation: paid, submitted (aqua-green)
  static const Color mintTint = Color(0x292EE6A8);

  // Fixed
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}

class AppRadius {
  AppRadius._();

  static const double sm = 12.0;
  static const double md = 16.0; // text fields & compact buttons
  static const double lg = 28.0; // large glass cards (28-32)
  static const double xl = 32.0; // bottom sheets & large modals
  static const double pill = 999.0;

  static BorderRadius get smBorder => BorderRadius.circular(sm);
  static BorderRadius get mdBorder => BorderRadius.circular(md);
  static BorderRadius get lgBorder => BorderRadius.circular(lg);
  static BorderRadius get xlBorder => BorderRadius.circular(xl);
  static BorderRadius get pillBorder => BorderRadius.circular(pill);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xl2 = 32.0;
  static const double xl3 = 48.0;
}

class AppShadows {
  AppShadows._();

  /// Soft ambient shadow for floating glass cards (no hard Material elevation)
  static const List<BoxShadow> raised = kGlassCardShadow;

  /// Soft glowing aqua shadow for primary action buttons
  static const List<BoxShadow> glow = kAccentGlowShadow;
}

class AppTypography {
  AppTypography._();

  // Space Grotesk = headlines, stats, scores
  static TextStyle get h1 => GoogleFonts.spaceGrotesk(
        fontSize: 30,
        height: 36 / 30,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      );

  static TextStyle get h2 => GoogleFonts.spaceGrotesk(
        fontSize: 24,
        height: 30 / 24,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  static TextStyle get h3 => GoogleFonts.spaceGrotesk(
        fontSize: 19,
        height: 25 / 19,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  static TextStyle get stat => GoogleFonts.spaceGrotesk(
        fontSize: 34,
        height: 38 / 34,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      );

  // Inter = body copy and UI chrome
  static TextStyle get body => GoogleFonts.inter(
        fontSize: 15,
        height: 22 / 15,
        fontWeight: FontWeight.w400,
        color: AppColors.ink,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 15,
        height: 22 / 15,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      );

  static TextStyle get label => GoogleFonts.inter(
        fontSize: 13,
        height: 18 / 13,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      );

  static TextStyle get caption => GoogleFonts.inter(
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
        color: AppColors.inkMuted,
      );
}

class AppTheme {
  AppTheme._();

  /// Single Unified Glassmorphism Theme (Dark Teal)
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF2EE6C5),
        onPrimary: Color(0xFF0F2027),
        primaryContainer: Color(0x2E2EE6C5),
        onPrimaryContainer: Color(0xFF2EE6C5),
        secondary: Color(0xFF2EE6A8),
        onSecondary: Color(0xFF0F2027),
        surface: Color(0x38355666),
        onSurface: Colors.white,
        error: Color(0xFFFF6B6B),
        onError: Color(0xFF0F2027),
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: AppTypography.h3,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0x2EFFFFFF), width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xEA162933),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0x3DFFFFFF), width: 1),
        ),
        titleTextStyle: AppTypography.h3,
        contentTextStyle: AppTypography.body,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        modalBackgroundColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x14FFFFFF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x26FFFFFF), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x26FFFFFF), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x992EE6C5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.5),
        ),
        hintStyle: AppTypography.body.copyWith(color: AppColors.inkFaint),
        labelStyle: AppTypography.label.copyWith(color: AppColors.inkMuted),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFF2EE6C5),
        selectionColor: Color(0x4D2EE6C5),
        selectionHandleColor: Color(0xFF2EE6C5),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2EE6C5),
          foregroundColor: const Color(0xFF0F2027),
          elevation: 0,
          shadowColor: const Color(0x522EE6C5),
          shape: const StadiumBorder(),
          textStyle: AppTypography.label.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F2027),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2EE6C5),
          side: const BorderSide(color: Color(0x4D2EE6C5), width: 1),
          shape: const StadiumBorder(),
          textStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF2EE6C5),
          shape: const StadiumBorder(),
          textStyle: AppTypography.label.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: Color(0x1AFFFFFF),
        selectedColor: Color(0x332EE6C5),
        secondarySelectedColor: Color(0xFF2EE6C5),
        labelStyle: TextStyle(color: Colors.white, fontSize: 12),
        side: BorderSide(color: Color(0x26FFFFFF), width: 1),
        shape: StadiumBorder(),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const Color(0xFF2EE6C5);
          return const Color(0xA3FFFFFF);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const Color(0x4D2EE6C5);
          return const Color(0x26FFFFFF);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xEA162933),
        contentTextStyle: AppTypography.body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x33FFFFFF), width: 1),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1AFFFFFF), // white 10%
        thickness: 1,
      ),
      extensions: const [
        GlassTheme(),
      ],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.fuchsia: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  /// Alias returning the exact same dark glass theme to satisfy any legacy callers.
  static ThemeData get lightTheme => darkTheme;
}

import 'package:flutter/material.dart';

import 'logic/bp_category.dart';

/// Palette from the PressSure design.
abstract final class AppColors {
  static const background = Color(0xFFF4F1EB);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFE6E0D6);
  static const borderStrong = Color(0xFFCFC7BA);
  static const divider = Color(0xFFEFEAE2);
  static const navBar = Color(0xFFECE7DE);
  static const navIndicator = Color(0xFFC7DEDF);

  static const primary = Color(0xFF0F4C5C);
  static const primaryDark = Color(0xFF0A3642);
  static const primarySoft = Color(0xFFD5E6E6);
  static const primaryMuted = Color(0xFF1F6474);
  static const primaryOutline = Color(0xFF7FB3BC);
  static const primaryFaint = Color(0xFF5E97A2);
  static const onPrimaryMuted = Color(0xFFBFE0DF);
  static const onPrimarySoft = Color(0xFFE3F0EF);

  static const ink = Color(0xFF1A1D21);
  static const ink2 = Color(0xFF3B4046);
  static const muted = Color(0xFF545A60);
  static const faint = Color(0xFF6F767C);
  static const slash = Color(0xFFA39C92);

  static const systolic = Color(0xFFC4581F);
  static const systolicDark = Color(0xFFA8481A);
  static const diastolic = Color(0xFF2B5F8E);

  static const gold = Color(0xFFE0B04A);
  static const goldLight = Color(0xFFF4D58D);
  static const orangeSoft = Color(0xFFFBEBD9);
  static const blueSoft = Color(0xFFDCE6F0);
  static const greenSoft = Color(0xFFD9EDE0);
  static const green = Color(0xFF1F5A3E);
  static const greenOk = Color(0xFF2F6B4A);
  static const warnSoft = Color(0xFFF6E7C4);
  static const warn = Color(0xFF7A4F00);
  static const warnBorder = Color(0xFFD9A21B);
  static const warnBg = Color(0xFFFFFBF0);
  static const high = Color(0xFFB3261E);
  static const highSoft = Color(0xFFF9DEDC);
  static const highInk = Color(0xFF8C1D18);
  static const bandLow = Color(0xFF7FB895);
}

/// Text styles on the design's two variable fonts. The weight is set both as
/// [FontWeight] and as a `wght` variation so the variable font renders it.
abstract final class AppText {
  static TextStyle _style(
    String family,
    double size,
    FontWeight weight,
    Color? color,
    double? height,
    double? letterSpacing,
    bool tabular,
  ) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    fontVariations: [FontVariation.weight(weight.value.toDouble())],
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// Bricolage Grotesque, for titles and numbers.
  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? height,
    double? letterSpacing,
    bool tabular = false,
  }) => _style(
    'BricolageGrotesque',
    size,
    weight,
    color,
    height,
    letterSpacing ?? size * -0.01,
    tabular,
  );

  /// Manrope, for everything else.
  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color? color,
    double? height,
    double? letterSpacing,
    bool tabular = false,
  }) => _style('Manrope', size, weight, color, height, letterSpacing, tabular);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondaryContainer: AppColors.primarySoft,
    onSecondaryContainer: AppColors.primary,
    surface: AppColors.background,
    onSurface: AppColors.ink,
    error: AppColors.high,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    textTheme: base.textTheme.apply(
      fontFamily: 'Manrope',
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: AppText.display(24, color: AppColors.ink),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.navBar,
      indicatorColor: AppColors.navIndicator,
      surfaceTintColor: Colors.transparent,
      height: 80,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => AppText.body(
          12,
          weight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w700,
          color: states.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.ink
              : AppColors.muted,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: AppText.body(15, weight: FontWeight.w800),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(44, 44),
        textStyle: AppText.body(14, weight: FontWeight.w800),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: AppText.body(
        15,
        weight: FontWeight.w500,
        color: AppColors.faint,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderStrong, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderStrong, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? Colors.white : null,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? AppColors.primary : null,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? AppColors.primary : null,
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.muted,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: AppText.body(14, color: Colors.white),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.divider, space: 1),
  );
}

extension BpCategoryColors on BpCategory {
  Color get chipBackground => switch (this) {
    BpCategory.nonElevated => AppColors.greenSoft,
    BpCategory.elevated => AppColors.warnSoft,
    BpCategory.high => AppColors.highSoft,
  };

  Color get chipForeground => switch (this) {
    BpCategory.nonElevated => AppColors.green,
    BpCategory.elevated => AppColors.warn,
    BpCategory.high => AppColors.highInk,
  };

  /// Color of the band in distribution bars.
  Color get bandColor => switch (this) {
    BpCategory.nonElevated => AppColors.bandLow,
    BpCategory.elevated => AppColors.gold,
    BpCategory.high => AppColors.high,
  };
}

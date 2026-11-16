import 'package:flutter/material.dart';

/// Fitted Pulse & Presence: deep ocean, luminous mint, warm apricot and iris.
/// Designed for confident adults 35–50, not a neon or teen dating aesthetic.
/// Static tokens support Flutter Web, Android and iOS without external fonts.
abstract final class FitDateColors {
  static const ink = Color(0xFF1B3038);
  static const inkDeep = Color(0xFF0F1821);
  static const surface = Color(0xFF182830);
  static const surfaceRaised = Color(0xFF233942);
  static const coral = Color(0xFFFFB59E);
  static const coralDark = Color(0xFF3F3540);
  static const lime = Color(0xFF58DEBA);
  static const aqua = Color(0xFF58DEBA);
  static const apricot = Color(0xFFFFB59E);
  static const lilac = Color(0xFFC5B7F6);
  static const pearl = Color(0xFFF9F4EC);
  static const muted = Color(0xFFC3D1D0);
  static const outline = Color(0xFF476069);
}

abstract final class FitDateTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: FitDateColors.coral,
      onPrimary: FitDateColors.inkDeep,
      secondary: FitDateColors.lime,
      onSecondary: FitDateColors.inkDeep,
      tertiary: FitDateColors.lilac,
      onTertiary: FitDateColors.inkDeep,
      surface: FitDateColors.surface,
      onSurface: FitDateColors.pearl,
      error: Color(0xFFFFB4B4),
      onError: FitDateColors.inkDeep,
      outline: FitDateColors.outline,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: FitDateColors.inkDeep,
      canvasColor: FitDateColors.inkDeep,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: FitDateColors.inkDeep,
        foregroundColor: FitDateColors.pearl,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      selectionTheme: TextSelectionThemeData(
        cursorColor: FitDateColors.aqua,
        selectionColor: FitDateColors.aqua.withValues(alpha: .29),
        selectionHandleColor: FitDateColors.aqua,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: FitDateColors.surfaceRaised,
        selectedColor: FitDateColors.aqua.withValues(alpha: .18),
        side: const BorderSide(color: FitDateColors.outline),
        labelStyle: const TextStyle(color: FitDateColors.pearl, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 56, fontFamily: 'Georgia', fontWeight: FontWeight.w700,
          color: FitDateColors.pearl, height: 1.08, letterSpacing: -1.8,
        ),
        displayMedium: TextStyle(
          fontSize: 40, fontFamily: 'Georgia', fontWeight: FontWeight.w700,
          color: FitDateColors.pearl, height: 1.10, letterSpacing: -1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 28, fontFamily: 'Georgia', fontWeight: FontWeight.w700,
          color: FitDateColors.pearl, height: 1.15,
        ),
        titleLarge: TextStyle(
          fontSize: 21, fontWeight: FontWeight.w700,
          color: FitDateColors.pearl,
        ),
        bodyLarge: TextStyle(
          fontSize: 16, height: 1.5, color: FitDateColors.pearl,
        ),
        bodyMedium: TextStyle(
          fontSize: 14, height: 1.45, color: FitDateColors.muted,
        ),
      ),
      cardTheme: CardThemeData(
        color: FitDateColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: const BorderSide(color: FitDateColors.outline, width: .65),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FitDateColors.ink,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: FitDateColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: FitDateColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: FitDateColors.aqua, width: 2),
        ),
        labelStyle: const TextStyle(color: FitDateColors.muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FitDateColors.coral,
          foregroundColor: FitDateColors.inkDeep,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FitDateColors.pearl,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: const BorderSide(color: FitDateColors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: FitDateColors.inkDeep,
        indicatorColor: const Color(0xFF1B4D4D),
        selectedIconTheme: const IconThemeData(
          color: FitDateColors.coral, size: 26,
        ),
        unselectedIconTheme: const IconThemeData(
          color: FitDateColors.muted, size: 23,
        ),
        selectedLabelTextStyle: const TextStyle(
          color: FitDateColors.pearl, fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: FitDateColors.muted, fontSize: 12,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: FitDateColors.surface,
        indicatorColor: const Color(0xFF285150),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? FitDateColors.pearl : FitDateColors.muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? FitDateColors.coral : FitDateColors.muted,
          ),
        ),
      ),
    );
  }
}

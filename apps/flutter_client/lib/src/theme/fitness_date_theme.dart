import 'package:flutter/material.dart';

/// Fitted editorial tokens: midnight teal, champagne and sage.
/// Static tokens support Flutter Web, Android and iOS without external fonts.
abstract final class FitDateColors {
  static const ink = Color(0xFF18282C);
  static const inkDeep = Color(0xFF101B21);
  static const surface = Color(0xFF19272C);
  static const surfaceRaised = Color(0xFF23363A);
  static const coral = Color(0xFFD5BE8A);
  static const coralDark = Color(0xFF34483F);
  static const lime = Color(0xFF9FB5A9);
  static const lilac = Color(0xFFB0B5AC);
  static const pearl = Color(0xFFF4F0E8);
  static const muted = Color(0xFFB0C1B8);
  static const outline = Color(0xFF425150);
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
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 56, fontWeight: FontWeight.w900,
          color: FitDateColors.pearl, height: 1.08, letterSpacing: -1.8,
        ),
        displayMedium: TextStyle(
          fontSize: 40, fontWeight: FontWeight.w900,
          color: FitDateColors.pearl, height: 1.10, letterSpacing: -1.3,
        ),
        headlineMedium: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w800,
          color: FitDateColors.pearl, height: 1.15,
        ),
        titleLarge: TextStyle(
          fontSize: 21, fontWeight: FontWeight.w800,
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
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: FitDateColors.outline, width: .65),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FitDateColors.ink,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: FitDateColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: FitDateColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: FitDateColors.lime, width: 2),
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
            borderRadius: BorderRadius.circular(16),
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
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: FitDateColors.inkDeep,
        indicatorColor: const Color(0xFF34483F),
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
        indicatorColor: const Color(0xFF3A263F),
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

import 'package:flutter/material.dart';

/// Fitted Motion F: midnight navy, ice-blue rhythm, violet glass and a restrained fuchsia pulse.
/// Designed for confident adults 35–50. Accents are used selectively, never as saturated full-screen fills.
/// Static tokens support Flutter Web, Android and iOS without external fonts.
abstract final class FitDateColors {
  static const ink = Color(0xFF18234C);
  static const inkDeep = Color(0xFF0D1030);
  static const surface = Color(0xFF151B3E);
  static const surfaceRaised = Color(0xFF202953);
  // Keep semantic tokens compatible with existing components while
  // shifting the Fitted design system to the Motion F visual identity.
  static const coral = Color(0xFFD9C3FF); // accessible lavender CTA
  static const coralDark = Color(0xFF35224F);
  static const lime = Color(0xFF65D3FA);
  static const aqua = Color(0xFF65D3FA);  // rhythm / focus
  static const apricot = Color(0xFFF385C5); // restrained pulse
  static const lilac = Color(0xFFC4ACFF);
  static const pearl = Color(0xFFF7F6FF);
  static const muted = Color(0xFFBCC8E4);
  static const outline = Color(0xFF424B7D);
  static const pulseViolet = Color(0xFF8A63EE);
  static const pulsePink = Color(0xFFF15FAB);
  static const pulseBlue = Color(0xFF50C8FF);
}

abstract final class FitDateTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: FitDateColors.coral,
      onPrimary: FitDateColors.inkDeep,
      secondary: FitDateColors.lime,
      onSecondary: FitDateColors.inkDeep,
      tertiary: FitDateColors.apricot,
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
      textSelectionTheme: TextSelectionThemeData(
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
        indicatorColor: const Color(0xFF30245F),
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
        indicatorColor: const Color(0xFF36265C),
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

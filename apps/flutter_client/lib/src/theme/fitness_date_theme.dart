import 'package:flutter/material.dart';

/// Dynamic Fitted palette: brand-controlled colors with neutral editorial accents.
/// Designed for confident adults 35–50. Accents are used selectively, never as saturated full-screen fills.
/// Tokens update on the same global brand version across Flutter Web, Android and iOS.
/// Semantic palette driven by the live Brand Designer, never by a screen.
 /// Neutral silver is the editorial accent; branded colors remain for actions.
 /// The current brand is applied before each MaterialApp theme is built.
 abstract final class FitDateColors {
   static Color _primary = Color(0xFF8EF0D5);
   static Color _accent = Color(0xFF68D4C7);
   static Color _background = Color(0xFF1A2D38);
   static bool _dark = true;

   static void useBrand({required Color primary,required Color accent,
       required Color background,required bool dark}) {
     _primary=primary;
     _accent=accent;
     _background=background;
     _dark=dark;
   }

   static Color get inkDeep => _background;
   static Color get ink => _layer(.025);
   static Color get surface => _layer(.065);
   static Color get surfaceRaised => _layer(.12);
   static Color get coral => _primary;
   static Color get coralDark => _shade(_primary,.48);
   static Color get lime => _accent;
   static Color get aqua => Color.lerp(_primary, _neutral, .44)!;
   static Color get apricot => Color.lerp(_accent, _neutral, .55)!;
   static Color get lilac => Color.lerp(_primary, _neutral, .73)!;
   static Color get pearl => _dark ? Color(0xFFF6FBFD) : Color(0xFF172731);
   static Color get muted => Color.lerp(pearl, _background, .34)!;
   static Color get outline => Color.lerp(pearl, _background, .71)!;
   static Color get pulseViolet => Color.lerp(_primary, _neutral, .65)!;
   static Color get pulsePink => Color.lerp(_accent, _neutral, .42)!;
   static Color get pulseBlue => Color.lerp(_accent, _neutral, .25)!;
   static Color get _neutral => _dark ? Color(0xFFB7C6CF) : Color(0xFF667983);
   static Color _layer(double strength) =>
       Color.lerp(_background, _dark ? Colors.white : Colors.black, strength)!;
   static Color _shade(Color color,double strength) =>
       Color.lerp(color,_dark ? Colors.black : Colors.white,strength)!;
 }

abstract final class FitDateTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.dark(
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
      appBarTheme: AppBarTheme(
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
        side: BorderSide(color: FitDateColors.outline),
        labelStyle: TextStyle(color: FitDateColors.pearl, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textTheme: TextTheme(
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
          side: BorderSide(color: FitDateColors.outline, width: .65),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FitDateColors.ink,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: FitDateColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: FitDateColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: FitDateColors.aqua, width: 2),
        ),
        labelStyle: TextStyle(color: FitDateColors.muted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: FitDateColors.coral,
          foregroundColor: FitDateColors.inkDeep,
          minimumSize: Size(0, 52),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: FitDateColors.pearl,
          minimumSize: Size(0, 52),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          side: BorderSide(color: FitDateColors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: FitDateColors.inkDeep,
        indicatorColor: Color(0xFF315650),
        selectedIconTheme: IconThemeData(
          color: FitDateColors.coral, size: 26,
        ),
        unselectedIconTheme: IconThemeData(
          color: FitDateColors.muted, size: 23,
        ),
        selectedLabelTextStyle: TextStyle(
          color: FitDateColors.pearl, fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: FitDateColors.muted, fontSize: 12,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: FitDateColors.surface,
        indicatorColor: Color(0xFF315650),
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

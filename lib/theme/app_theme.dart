import 'package:flutter/material.dart';

import '../flavor/gym_flavor.dart';

/// Stitch Monochrome Health tokens + gym accent hue.
class TitanTheme {
  TitanTheme._();

  // Dark (Stitch void)
  static const Color canvasDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF141313);
  static const Color surfaceContainerDark = Color(0xFF201F1F);
  static const Color surfaceHighDark = Color(0xFF2A2A2A);
  static const Color borderDark = Color(0xFF2C2C2E);
  static const Color onSurfaceDark = Color(0xFFE5E2E1);
  static const Color onSurfaceVariantDark = Color(0xFFC4C7C8);
  static const Color outlineDark = Color(0xFF8E9192);

  // Light
  static const Color canvasLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF5F5F5);
  static const Color surfaceContainerLight = Color(0xFFEEEEEE);
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color onSurfaceLight = Color(0xFF1A1A1A);
  static const Color onSurfaceVariantLight = Color(0xFF5C5C5C);

  static const Color pillLight = Color(0xFFFFFFFF);
  static const Color onPillLight = Color(0xFF2F3131);
  static const Color pillDark = Color(0xFFFFFFFF);
  static const Color onPillDark = Color(0xFF2F3131);

  static Color accent(double hue, {bool monochrome = false}) {
    if (monochrome || hue <= 0) return pillLight;
    return HSLColor.fromAHSL(1, hue, 0.55, 0.62).toColor();
  }

  static Color glassFill(Brightness b) =>
      b == Brightness.dark ? const Color(0x66281C1E) : const Color(0x99FFFFFF);

  static ThemeData dark(GymFlavor? flavor) => _build(Brightness.dark, flavor);
  static ThemeData light(GymFlavor? flavor) => _build(Brightness.light, flavor);

  static ThemeData _build(Brightness brightness, GymFlavor? flavor) {
    final hue = flavor?.effectiveHue ?? 240;
    final mono = (flavor?.mobileThemeSlug ?? 'monochrome') == 'monochrome' && hue <= 0;
    final accentColor = accent(hue, monochrome: mono);

    final isDark = brightness == Brightness.dark;
    final canvas = isDark ? canvasDark : canvasLight;
    final surface = isDark ? surfaceDark : surfaceLight;
    final surfaceContainer = isDark ? surfaceContainerDark : surfaceContainerLight;
    final onSurface = isDark ? onSurfaceDark : onSurfaceLight;
    final onVariant = isDark ? onSurfaceVariantDark : onSurfaceVariantLight;
    final border = isDark ? borderDark : borderLight;

    final colorScheme = isDark
        ? ColorScheme.dark(
            surface: surface,
            onSurface: onSurface,
            primary: accentColor,
            onPrimary: onPillDark,
            secondary: surfaceContainer,
            onSecondary: onSurface,
            outline: outlineDark,
            surfaceContainerHighest: surfaceHighDark,
          )
        : ColorScheme.light(
            surface: surface,
            onSurface: onSurface,
            primary: accentColor,
            onPrimary: onPillLight,
            secondary: surfaceContainer,
            onSecondary: onSurface,
            outline: outlineDark,
            surfaceContainerHighest: surfaceContainer,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: canvas,
      extensions: [TitanTokens(hue: hue, border: border, glassFill: glassFill(brightness))],
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        labelStyle: TextStyle(color: onVariant, fontSize: 13),
        hintStyle: TextStyle(color: onVariant, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pillLight,
          foregroundColor: onPillDark,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textTheme: _buildTextTheme(onSurface, onVariant),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? surfaceContainer : surfaceLight,
        indicatorColor: accentColor.withValues(alpha: 0.15),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color onSurface, Color onVariant) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
        color: onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: onSurface,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: onVariant,
        height: 1.5,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: onSurface,
        letterSpacing: 0.08,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: onVariant,
        letterSpacing: 1.32,
      ),
    );
  }
}

@immutable
class TitanTokens extends ThemeExtension<TitanTokens> {
  const TitanTokens({
    required this.hue,
    required this.border,
    required this.glassFill,
  });

  final double hue;
  final Color border;
  final Color glassFill;

  @override
  TitanTokens copyWith({double? hue, Color? border, Color? glassFill}) {
    return TitanTokens(
      hue: hue ?? this.hue,
      border: border ?? this.border,
      glassFill: glassFill ?? this.glassFill,
    );
  }

  @override
  TitanTokens lerp(ThemeExtension<TitanTokens>? other, double t) {
    if (other is! TitanTokens) return this;
    return TitanTokens(
      hue: hue + (other.hue - hue) * t,
      border: Color.lerp(border, other.border, t)!,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
    );
  }
}

/// Back-compat wrapper.
class AppTheme {
  static ThemeData build(GymFlavor? flavor) => TitanTheme.dark(flavor);
  static ThemeData buildLight(GymFlavor? flavor) => TitanTheme.light(flavor);
}

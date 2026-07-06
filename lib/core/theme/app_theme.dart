import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// App theming calibrated to dwelleo.sa. Light and dark share one builder so the
/// two stay in lockstep; the app bar is seamless with the page (no tint clash),
/// and every surface/text/icon color flows from the [ColorScheme] so toggling
/// light/dark restyles the whole app.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ColorScheme _scheme(Brightness b) {
    final isDark = b == Brightness.dark;
    return ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: b,
    ).copyWith(
      // dwelleo.sa flips its primary action color by theme: purple in light,
      // lime in dark. Drive the whole ColorScheme from that so every CTA,
      // selected state, link and focus ring matches the site in both modes.
      primary: AppColors.accentFor(b),
      onPrimary: AppColors.onAccentFor(b),
      secondary: isDark ? AppColors.accent : AppColors.primary,
      onSecondary: isDark ? Colors.white : AppColors.ink,
      surface: isDark ? AppColors.surfaceDark : AppColors.surface,
      onSurface: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      onSurfaceVariant: isDark
          ? AppColors.textSecondaryDark
          : AppColors.textSecondary,
      surfaceContainerHighest: isDark
          ? AppColors.cardDark
          : const Color(0xFFEFF1EA),
      outline: isDark ? AppColors.dividerDark : AppColors.divider,
      outlineVariant: isDark ? AppColors.dividerDark : AppColors.divider,
      error: AppColors.error,
    );
  }

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    final scheme = _scheme(b);
    final bg = isDark ? AppColors.backgroundDark : AppColors.background;
    final card = isDark ? AppColors.cardDark : AppColors.surface;

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      // Dwelleo's brand typeface (matches dwelleo.sa exactly).
      fontFamily: 'RocGrotesk',
      textTheme: _textTheme,
      splashFactory: InkSparkle.splashFactory,

      // Seamless app bar: same color as the page, no tint, no shadow.
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      cardTheme: CardThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 1.5,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentFor(b),
          foregroundColor: AppColors.onAccentFor(b),
          // Disabled state mirrors the site exactly: solid zinc-grey #A1A1AA
          // with a darker label (captured from dwelleo.sa's disabled Sign In).
          disabledBackgroundColor: const Color(0xFFA1A1AA),
          disabledForegroundColor: const Color(0xFF3F3F46),
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          // dwelleo.sa CTAs use a 14px radius (not a full pill).
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outline),
          minimumSize: const Size.fromHeight(54),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.accentFor(b)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // Glassy fields like the site: translucent white over the grey page in
        // dark, solid white in light.
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: _inputBorder(scheme.outline),
        enabledBorder: _inputBorder(scheme.outline),
        focusedBorder: _inputBorder(AppColors.accentFor(b), width: 1.6),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.cardDark : const Color(0xFFF0F2EA),
        // Selected chips read as a clean accent tint (not a murky olive box).
        selectedColor: AppColors.accentFor(b).withValues(alpha: 0.18),
        checkmarkColor: AppColors.accentFor(b),
        side: BorderSide(color: scheme.outline),
        labelStyle: TextStyle(color: scheme.onSurface, fontSize: 12),
        secondaryLabelStyle: TextStyle(color: scheme.onSurface, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      dividerTheme: DividerThemeData(color: scheme.outline, thickness: 1),
      iconTheme: IconThemeData(color: scheme.onSurface),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accentFor(b)
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(AppColors.onAccentFor(b)),
        side: BorderSide(color: scheme.outline, width: 1.5),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.accentFor(b),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 57,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    ),
    displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w800),
    displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.3,
    ),
    labelLarge: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    ),
    labelMedium: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    ),
  );
}

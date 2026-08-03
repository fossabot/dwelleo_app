import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark
        ? AppColors.backgroundDark
        : AppColors.background;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surface;
    final elevated = isDark ? AppColors.cardDark : AppColors.surface;
    final muted = isDark
        ? AppColors.mutedSurfaceDark
        : AppColors.mutedSurface;
    final outline = isDark ? AppColors.dividerDark : AppColors.divider;
    final onSurface = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final onSurfaceVariant = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final primary = AppColors.accentFor(brightness);

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: isDark
          ? const Color(0xFF163D38)
          : const Color(0xFFDDF3EE),
      onPrimaryContainer: isDark
          ? AppColors.textPrimaryDark
          : AppColors.primaryDeep,
      secondary: AppColors.accent,
      onSecondary: AppColors.ink,
      secondaryContainer: isDark
          ? const Color(0xFF34431F)
          : const Color(0xFFEDF8CE),
      onSecondaryContainer: isDark
          ? AppColors.textPrimaryDark
          : AppColors.ink,
      surface: surface,
      onSurface: onSurface,
      onSurfaceVariant: onSurfaceVariant,
      surfaceContainerHighest: muted,
      outline: outline,
      outlineVariant: outline,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      textTheme: _textTheme.apply(
        bodyColor: onSurface,
        displayColor: onSurface,
      ),
      extensions: [
        AppSurfaceTokens(
          muted: muted,
          elevated: elevated,
          warm: isDark ? const Color(0xFF4B3820) : AppColors.warmLight,
          onWarm: isDark ? const Color(0xFFFFE8BF) : const Color(0xFF5A3B0A),
          successContainer: isDark
              ? const Color(0xFF143B2B)
              : const Color(0xFFDDF4E8),
          onSuccessContainer: isDark
              ? const Color(0xFFB7E9D1)
              : const Color(0xFF145C3E),
        ),
      ],
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: elevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: outline),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: muted,
          disabledForegroundColor: onSurfaceVariant,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: onSurface,
          side: BorderSide(color: outline),
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: elevated,
        hintStyle: TextStyle(color: onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: _inputBorder(outline),
        enabledBorder: _inputBorder(outline),
        focusedBorder: _inputBorder(primary, width: 1.5),
        errorBorder: _inputBorder(AppColors.error),
        prefixIconColor: onSurfaceVariant,
        suffixIconColor: onSurfaceVariant,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: muted,
        selectedColor: scheme.primaryContainer,
        checkmarkColor: primary,
        side: BorderSide(color: outline),
        labelStyle: TextStyle(color: onSurface, fontSize: 13),
        secondaryLabelStyle: TextStyle(color: onSurface, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: elevated,
        elevation: 0,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? primary
                : onSurfaceVariant,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(color: outline, thickness: 1),
      iconTheme: IconThemeData(color: onSurface),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: color, width: width),
      );

  static const TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w700),
    displayMedium: TextStyle(fontSize: 40, fontWeight: FontWeight.w700),
    displaySmall: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
    headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
    headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 16, height: 1.45),
    bodyMedium: TextStyle(fontSize: 14, height: 1.45),
    bodySmall: TextStyle(fontSize: 12, height: 1.4),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
  );
}

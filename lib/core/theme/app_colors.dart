import 'package:flutter/material.dart';

/// Independent mobile-product palette.
///
/// The compatibility names are intentionally retained so existing features can
/// migrate incrementally without continuing the old website-derived visual
/// system.
abstract final class AppColors {
  // Brand: calm mineral teal with a restrained lime highlight.
  static const Color primary = Color(0xFF0F766E);
  static const Color primaryDark = Color(0xFF0B5F59);
  static const Color primaryLight = Color(0xFF50B9A3);
  static const Color primaryDeep = Color(0xFF075E58);

  /// Secondary product highlight. It is no longer the primary CTA colour.
  static const Color accent = Color(0xFFC6EF65);
  static const Color accentLight = Color(0xFFDDF7A0);

  static const Color warm = Color(0xFFD8A85B);
  static const Color warmLight = Color(0xFFF5E7CB);

  static Color accentFor(Brightness brightness) =>
      brightness == Brightness.dark ? primaryLight : primary;

  static Color onAccentFor(Brightness brightness) => Colors.white;

  static const Color ink = Color(0xFF17201E);

  // Light surfaces.
  static const Color background = Color(0xFFF7F7F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color mutedSurface = Color(0xFFEEF2EF);
  static const Color divider = Color(0xFFDDE4E0);
  static const Color textPrimary = Color(0xFF17201E);
  static const Color textSecondary = Color(0xFF66706D);

  // Dark surfaces form a visible tonal ladder rather than one flat black page.
  static const Color backgroundDark = Color(0xFF0C1211);
  static const Color surfaceDark = Color(0xFF141B19);
  static const Color cardDark = Color(0xFF1B2421);
  static const Color mutedSurfaceDark = Color(0xFF222D29);
  static const Color dividerDark = Color(0xFF2D3A36);
  static const Color textPrimaryDark = Color(0xFFF3F7F5);
  static const Color textSecondaryDark = Color(0xFFA9B3AF);

  // Shared semantic colours.
  static const Color textOnPrimary = Colors.white;
  static const Color success = Color(0xFF16855B);
  static const Color error = Color(0xFFC94A4A);
  static const Color warning = Color(0xFFB9791D);
  static const Color info = Color(0xFF3678A8);
  static const Color shadow = Color(0x1A0A1512);

  static const Color heroTop = Color(0xFF123D39);
  static const Color heroBottom = Color(0xFF0C1211);
}

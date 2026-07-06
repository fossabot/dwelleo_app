import 'package:flutter/material.dart';

/// Brand palette, calibrated to dwelleo.sa (lime + purple on near-black / white).
abstract final class AppColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  /// Signature lime — sampled from dwelleo.sa's live CTA (#D1F145), a bright
  /// chartreuse. (Earlier #B8D030 was too dark/olive and made accents look off.)
  static const Color primary = Color(0xFFD1F145);
  static const Color primaryDark = Color(0xFFB5D62E);
  static const Color primaryLight = Color(0xFFE2FF6E);

  /// Purple accent (List Property / AI pill).
  static const Color accent = Color(0xFF6B4FA0);
  static const Color accentLight = Color(0xFF9B7FD4);

  /// dwelleo.sa flips its PRIMARY action color by theme: purple in light mode,
  /// lime in dark mode. Use these for CTAs, selected states, links and icon
  /// tints so the app matches the site in both themes.
  static Color accentFor(Brightness b) =>
      b == Brightness.dark ? primary : accent;

  /// Foreground that sits on [accentFor]: near-black on lime, white on purple.
  static Color onAccentFor(Brightness b) =>
      b == Brightness.dark ? ink : Colors.white;

  /// Text/icon color that sits ON the lime CTA — near-pure black per the
  /// captured spec (§5), not a green-tinted ink.
  static const Color ink = Color(0xFF0A0A0A);

  // ── Light surfaces ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFFF6F7F3);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFE7E9E2);

  static const Color textPrimary = Color(0xFF14160F);
  static const Color textSecondary = Color(0xFF646B58);

  // ── Dark surfaces — sampled from dwelleo.sa: the page is a NEUTRAL #1B1B1B
  //     grey (not near-black, no green tint). Cards sit a touch lighter, like
  //     the site's translucent white panels reading over the grey page. ───────
  static const Color backgroundDark = Color(0xFF1B1B1B);
  static const Color surfaceDark = Color(0xFF1F1F20);
  static const Color cardDark = Color(0xFF242427);
  static const Color dividerDark = Color(0xFF333335);

  static const Color textPrimaryDark = Color(0xFFF4F4F5);
  static const Color textSecondaryDark = Color(0xFFA1A1AA);

  // ── Shared ──────────────────────────────────────────────────────────────────
  static const Color textOnPrimary = ink;
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  static const Color shadow = Color(0x14000000);

  /// Onboarding/auth hero gradient (deep greenish-black -> black).
  static const Color heroTop = Color(0xFF12180A);
  static const Color heroBottom = Color(0xFF000000);
}

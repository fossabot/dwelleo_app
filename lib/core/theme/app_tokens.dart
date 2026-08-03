import 'package:flutter/material.dart';

/// Mobile-first spacing scale used across the rebuilt product UI.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;

  static const double screen = lg;
}

/// Shared shape scale. Components should use these values instead of
/// introducing one-off radii.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double sheet = 24;
  static const double pill = 999;
}

/// Calm, non-looping motion timings for the mobile product.
abstract final class AppMotion {
  static const Duration micro = Duration(milliseconds: 120);
  static const Duration standard = Duration(milliseconds: 220);
  static const Duration sheet = Duration(milliseconds: 320);

  static const Curve curve = Curves.easeOutCubic;
}

/// Width thresholds used by adaptive widgets.
abstract final class AppBreakpoints {
  static const double compact = 600;
  static const double medium = 840;
}

/// Extra semantic surface colours that are not represented directly by
/// [ColorScheme]. Keeping them in the theme makes light and dark modes read as
/// the same product while preserving a clear elevation ladder.
@immutable
class AppSurfaceTokens extends ThemeExtension<AppSurfaceTokens> {
  final Color muted;
  final Color elevated;
  final Color warm;
  final Color onWarm;
  final Color successContainer;
  final Color onSuccessContainer;

  const AppSurfaceTokens({
    required this.muted,
    required this.elevated,
    required this.warm,
    required this.onWarm,
    required this.successContainer,
    required this.onSuccessContainer,
  });

  @override
  AppSurfaceTokens copyWith({
    Color? muted,
    Color? elevated,
    Color? warm,
    Color? onWarm,
    Color? successContainer,
    Color? onSuccessContainer,
  }) {
    return AppSurfaceTokens(
      muted: muted ?? this.muted,
      elevated: elevated ?? this.elevated,
      warm: warm ?? this.warm,
      onWarm: onWarm ?? this.onWarm,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    );
  }

  @override
  AppSurfaceTokens lerp(covariant AppSurfaceTokens? other, double t) {
    if (other == null) return this;
    return AppSurfaceTokens(
      muted: Color.lerp(muted, other.muted, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      warm: Color.lerp(warm, other.warm, t)!,
      onWarm: Color.lerp(onWarm, other.onWarm, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
    );
  }
}

extension AppThemeTokensX on BuildContext {
  AppSurfaceTokens get surfaces =>
      Theme.of(this).extension<AppSurfaceTokens>()!;
}

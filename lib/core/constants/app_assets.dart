/// Centralized asset paths. Prefer the true-vector SVGs (crisp at any size) for
/// UI icons; the raster-embedded brand art (logos/flags) is shipped as PNG.
abstract final class AppSvg {
  static const String _d = 'assets/svg';

  // Multicolor brand icon — render WITHOUT a color filter.
  static const String google = '$_d/google-icon.svg';
  static const String whatsapp = '$_d/whatsapp.svg';
  static const String aiVoice = '$_d/aiVoiceSearchLogo.svg';

  // Monochrome UI icons — safe to tint via ColorFilter.
  static const String sar = '$_d/SAR.svg';
  static const String sqf = '$_d/SqF.svg';
  static const String bed = '$_d/withe-bed.svg';
  static const String bath = '$_d/white-bath.svg';
  static const String inputEmail = '$_d/input-email.svg';
  static const String inputPassword = '$_d/input-password.svg';
  static const String signinArrow = '$_d/signin-arrow.svg';
  static const String rightArrow = '$_d/rightArrow.svg';
  static const String arrowTopRight = '$_d/arrowTopRight.svg';

  // Account-type (sign-up) icons — already brand-colored vectors.
  static const String roleBuyer = '$_d/SignupBuyer.svg';
  static const String roleSeller = '$_d/SignupSeller.svg';
  static const String roleAgent = '$_d/SignupAgent.svg';
  static const String roleBroker = '$_d/SignupBroker.svg';
  static const String roleDeveloper = '$_d/SignupDeveloper.svg';
  static const String roleIndividualBroker = '$_d/SignupIndividualBroker.svg';
}

/// Brand art (logo wordmark, flags, onboarding hero). These design exports are
/// raster-embedded SVGs that flutter_svg cannot render, so they ship as PNG
/// (extracted from the SVGs). Replace with true-vector SVGs to use them as SVG.
abstract final class AppImage {
  static const String _b = 'assets/images/brand';
  static const String flagEn = '$_b/flag_en.png';
  static const String flagAr = '$_b/flag_ar.png';
  static const String wordmarkLight = '$_b/wordmark_light.png';
  static const String wordmarkDark = '$_b/wordmark_dark.png';
  // Arabic wordmark (logo switches with language, like the website).
  static const String wordmarkArLight = '$_b/wordmark_ar_light.png';
  static const String wordmarkArDark = '$_b/wordmark_ar_dark.png';

  /// Locale + theme aware brand wordmark path.
  static String wordmark({required bool isArabic, required bool isDark}) {
    if (isArabic) return isDark ? wordmarkArDark : wordmarkArLight;
    return isDark ? wordmarkDark : wordmarkLight;
  }

  static const String onboardingLight = '$_b/onboarding_light.png';
  static const String onboardingDark = '$_b/onboarding_dark.png';
}

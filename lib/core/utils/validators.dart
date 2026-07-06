/// Shared input validators (used across auth screens).
///
/// The password rules mirror the verified backend policy (HANDOFF §1): at least
/// one lowercase, one uppercase, one digit, and a minimum length of 8. Each rule
/// is exposed individually so the UI can show a live, per-rule checklist while
/// [isStrongPassword] is the single gate the submit buttons use.
abstract final class Validators {
  static bool hasMinLength(String v) => v.length >= 8;
  static bool hasUpper(String v) => v.contains(RegExp('[A-Z]'));
  static bool hasLower(String v) => v.contains(RegExp('[a-z]'));
  static bool hasDigit(String v) => v.contains(RegExp(r'\d'));

  static bool isStrongPassword(String v) =>
      hasMinLength(v) && hasUpper(v) && hasLower(v) && hasDigit(v);
}

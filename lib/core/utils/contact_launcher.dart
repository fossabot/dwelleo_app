import 'package:url_launcher/url_launcher.dart';

/// Builds and launches native contact actions (call / WhatsApp).
/// URL building is pure and unit-tested; launching is a thin wrapper.
abstract final class ContactLauncher {
  /// Digits-only MSISDN for wa.me: strips spaces/dashes/parens and the
  /// leading `+`/`00`. Saudi local numbers (05x…) become 9665x… — matching
  /// how dwelleo.sa renders its WhatsApp links.
  static String normalizeMsisdn(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.startsWith('+')) digits = digits.substring(1);
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('05')) digits = '966${digits.substring(1)}';
    if (digits.startsWith('5') && digits.length == 9) digits = '966$digits';
    return digits;
  }

  static Uri telUri(String phone) =>
      Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^0-9+]'), ''));

  static Uri whatsAppUri(String phone, {String? text}) => Uri.https(
    'wa.me',
    '/${normalizeMsisdn(phone)}',
    text == null || text.isEmpty ? null : {'text': text},
  );

  /// Opens the platform's maps app at a coordinate. Uses the geo: scheme's
  /// universal `?q=lat,lng(label)` form, which Apple Maps and Google Maps
  /// both honour.
  static Future<bool> openMap({
    required double lat,
    required double lng,
    String? label,
  }) {
    final query = label == null || label.isEmpty
        ? '$lat,$lng'
        : '$lat,$lng($label)';
    return launchUrl(
      Uri.parse('https://maps.google.com/?q=${Uri.encodeComponent(query)}'),
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<bool> call(String phone) =>
      launchUrl(telUri(phone), mode: LaunchMode.externalApplication);

  static Future<bool> whatsApp(String phone, {String? text}) => launchUrl(
    whatsAppUri(phone, text: text),
    mode: LaunchMode.externalApplication,
  );
}

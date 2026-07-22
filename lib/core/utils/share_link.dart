import 'package:share_plus/share_plus.dart';

/// Native share sheet for dwelleo.sa canonical links (site parity for the
/// listing page's Share control). Pure utility — no widget coupling.
abstract final class ShareLink {
  static String propertyUrl(String slug, {required bool arabic}) =>
      'https://dwelleo.sa/${arabic ? 'ar' : 'en'}/properties/$slug';

  static Future<void> shareProperty({
    required String slug,
    required String title,
    required bool arabic,
  }) async {
    // share_plus 13.x instance API (the static Share.share is deprecated).
    await SharePlus.instance.share(
      ShareParams(
        text: '$title\n${propertyUrl(slug, arabic: arabic)}',
        subject: title,
      ),
    );
  }
}

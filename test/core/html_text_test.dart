import 'package:dwelleo_app/core/utils/html_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HtmlText.strip', () {
    test('cleans the live project-description payload shape', () {
      // Shape observed on the device: raw HTML leaking into the sheet.
      const html =
          '<p><strong>Al Aziziyah Al Janubiyah</strong> is a premier real '
          'estate project boasting a highly strategic and premium location '
          'in Makkah, situated within the sought-after '
          '<strong>Sattar Al-Lahyani plan</strong>.</p>';

      final text = HtmlText.strip(html);

      expect(text, isNot(contains('<')));
      expect(text, contains('Al Aziziyah Al Janubiyah is a premier'));
      expect(text, contains('Sattar Al-Lahyani plan.'));
    });

    test('converts list items to bullets', () {
      const html =
          '<ul><li><p><strong>Location:</strong> Al Wisam neighborhood, '
          'Taif city.</p></li><li><p><strong>Project Type:</strong> A '
          'luxurious residential project.</p></li></ul>';

      final text = HtmlText.strip(html);

      expect(text, contains('• Location: Al Wisam neighborhood, Taif city.'));
      expect(text, contains('• Project Type: A luxurious residential'));
      expect(text, isNot(contains('<li>')));
    });

    test('decodes common entities and collapses whitespace', () {
      expect(
        HtmlText.strip('A&nbsp;&amp;&nbsp;B   C&#39;s &quot;home&quot;'),
        'A & B C\'s "home"',
      );
    });
  });
}

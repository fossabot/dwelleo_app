/// Converts the API's HTML-formatted rich text (project/property
/// descriptions arrive as `<p><strong>…</strong></p><ul><li>…`) into clean
/// plain text for native rendering. No packages — a display-grade
/// sanitizer, not a parser.
abstract final class HtmlText {
  static final RegExp _breaks = RegExp(
    r'</(p|div|li|ul|ol|h[1-6]|br)\s*>|<br\s*/?>',
    caseSensitive: false,
  );
  static final RegExp _bullets = RegExp(r'<li[^>]*>', caseSensitive: false);
  static final RegExp _tags = RegExp(r'<[^>]+>');
  static final RegExp _blankRuns = RegExp(r'\n{3,}');
  static final RegExp _spaceRuns = RegExp(r'[ \t]{2,}');

  static String strip(String html) {
    var text = html
        .replaceAll(_bullets, '\n• ')
        .replaceAll(_breaks, '\n')
        .replaceAll(_tags, '');
    // Common entities seen in the live payloads.
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    text = text.replaceAll(_spaceRuns, ' ').replaceAll(_blankRuns, '\n\n');
    return text.trim();
  }
}

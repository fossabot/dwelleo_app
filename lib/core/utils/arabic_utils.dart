/// Returns true when [s] contains any Arabic-script character, covering
/// Basic Arabic (U+0600–U+06FF), Arabic Supplement (U+0750–U+077F), and
/// Presentation Forms A/B (U+FB50–U+FEFF).
bool hasArabic(String s) =>
    RegExp(
      '[؀-ۿݐ-ݿﭐ-﷿ﹰ-ﻼ]',
    ).hasMatch(s);

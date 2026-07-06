/// Bridge from the API's raw S3 image URLs (often multi-MB PNGs) to
/// dwelleo.sa's own Next.js image optimizer, which resizes and re-encodes
/// (WebP/AVIF when the Accept header allows it).
///
/// CONFIRMED live 2026-07-02: `https://dwelleo.sa/_next/image?url={enc}&w={w}&q=75`
/// returns 200 for w ∈ {640, 828, 1080, 3840} — the exact pipeline the
/// website itself uses (it requests w=3840).
abstract final class DwelleoImages {
  static const String _optimizer = 'https://dwelleo.sa/_next/image';

  /// Next.js only serves whitelisted widths — snap up to the nearest.
  static const List<int> _widths = [640, 828, 1080, 3840];

  /// Request headers that let the optimizer negotiate WebP/AVIF.
  static const Map<String, String> headers = {
    'Accept': 'image/avif,image/webp,image/*,*/*;q=0.8',
  };

  /// Optimized variant of [url] at (roughly) [width] css-px × device ratio.
  /// Non-S3/absolute-URL inputs are returned untouched.
  static String optimized(String url, {int width = 828, int quality = 75}) {
    if (!url.startsWith('http')) return url;
    final w = _widths.firstWhere((x) => x >= width, orElse: () => _widths.last);
    return Uri.parse(_optimizer)
        .replace(queryParameters: {'url': url, 'w': '$w', 'q': '$quality'})
        .toString();
  }
}

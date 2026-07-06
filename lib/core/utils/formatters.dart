import 'package:intl/intl.dart';

/// Shared display formatters (core — reusable across features).
abstract final class Formatters {
  static final NumberFormat _grouped = NumberFormat.decimalPattern('en');

  /// e.g. `SAR 1,300,000`. Returns `—` for null.
  static String price(num? value, {String currency = 'SAR'}) =>
      value == null ? '—' : '$currency ${_grouped.format(value)}';

  /// Grouped number only, e.g. `1,300,000` (pair with the SAR icon).
  static String priceValue(num? value) =>
      value == null ? '—' : _grouped.format(value);

  /// e.g. `275 m²`.
  static String area(num? value) =>
      value == null ? '—' : '${_grouped.format(value)} m²';

  static String count(num? value) =>
      value == null ? '—' : _grouped.format(value);

  /// Chart-style compact value, matching dwelleo.sa's axis labels:
  /// 4614.58 → `4.6k`, 950 → `950`. Locale-neutral by design (the site
  /// renders these Latin in both languages).
  static String compactK(num value) {
    if (value.abs() < 1000) return value.round().toString();
    final k = value / 1000;
    final text = k.toStringAsFixed(k.abs() < 10 ? 1 : 0);
    return '${text.endsWith('.0') ? text.substring(0, text.length - 2) : text}k';
  }

  static final NumberFormat _stat = NumberFormat('#,##0.##', 'en');

  /// Market-stat value exactly like dwelleo.sa's tables: grouped with up to
  /// two decimals (`4,614.58`, `2,544.5`, `12,404.95`).
  static String statValue(num value) => _stat.format(value);
}

/// Null-and-type-tolerant JSON coercion helpers shared by all data-layer
/// models (the API occasionally delivers numbers as strings and booleans as
/// 0/1). Centralized here per the core-for-shared-code rule.
abstract final class JsonParse {
  static Map<String, dynamic>? asMap(dynamic v) =>
      v is Map<String, dynamic> ? v : null;

  static int? toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static num? toNum(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v.replaceAll(',', ''));
    return null;
  }

  static double? toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static bool toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    if (v is String) return v == 'true' || v == '1';
    return false;
  }
}

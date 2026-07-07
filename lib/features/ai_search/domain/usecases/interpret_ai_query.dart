import '../../../../core/lookup/lookup_service.dart';
import '../entities/ai_search_models.dart';

/// Deterministic on-device NLU: maps a natural-language utterance (EN or AR)
/// onto the **verified** `/properties` filter params, using the real
/// `/lookup` cities and property types for id resolution.
///
/// WHY ON-DEVICE: the backend AI endpoints (`/user/ai/*`,
/// `/user/ai/search` in the handoff spec) have **PENDING request/response
/// bodies** — per project rules we never invent contracts. This interpreter
/// makes AI Search fully functional today on captured contracts only, and it
/// becomes the offline/quota fallback once the remote contract is captured.
class InterpretAiQuery {
  final LookupService _lookup;

  const InterpretAiQuery(this._lookup);

  Future<AiInterpretation> call(String utterance) async {
    // Lookup failures (offline) must not kill interpretation — beds/price/
    // listing intent still parse without them.
    List<CityOption> cities = const [];
    List<PropertyTypeOption> types = const [];
    try {
      cities = await _lookup.cities();
    } catch (_) {}
    try {
      types = await _lookup.propertyTypes();
    } catch (_) {}
    return parse(utterance, cities: cities, types: types);
  }

  // ---------------------------------------------------------------- parsing

  /// Pure + deterministic — unit-tested directly with fake lookup options.
  static AiInterpretation parse(
    String utterance, {
    required List<CityOption> cities,
    required List<PropertyTypeOption> types,
  }) {
    final text = _normalize(utterance);

    return AiInterpretation(
      listingType: _listingType(text),
      propertyType: _match<PropertyTypeOption>(
        text,
        types,
        (t) => t.name,
        _typeSynonyms,
      ),
      city: _match<CityOption>(text, cities, (c) => c.name, _citySynonyms),
      minBedrooms: _count(text, _bedWords),
      minBathrooms: _count(text, _bathWords),
      minPrice: _price(text, min: true),
      maxPrice: _price(text, min: false),
      furnishingStatus: _furnishing(text),
    );
  }

  /// Lowercase, Arabic-Indic digits → Latin, hamza/taa-marbuta folding,
  /// diacritics stripped, punctuation → spaces, padded for word matching.
  static String _normalize(String input) {
    var s = input.toLowerCase();
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < eastern.length; i++) {
      s = s.replaceAll(eastern[i], '$i');
    }
    s = s
        .replaceAll(RegExp('[ً-ْٰـ]'), '')
        .replaceAll(RegExp('[أإآ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ئ', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll(RegExp(r'[^a-z0-9؀-ۿ.]+'), ' ');
    return ' ${s.trim()} ';
  }

  /// Word/phrase present? Also tries the Arabic definite-article variant.
  static bool _has(String text, String word) {
    final w = _normalize(word).trim();
    if (w.isEmpty) return false;
    return text.contains(' $w ') || text.contains(' ال$w ');
  }

  static bool _hasAny(String text, List<String> words) =>
      words.any((w) => _has(text, w));

  /// Resolves a lookup option by (a) its own localized name appearing in the
  /// text, or (b) a synonym bridge: the option's name identifies its
  /// canonical group (e.g. AR "شقة" ∈ apartment group), then any synonym of
  /// that group in the text matches it. This makes EN input work in the AR
  /// app and vice versa without extra lookup calls.
  static T? _match<T>(
    String text,
    List<T> options,
    String Function(T) nameOf,
    Map<String, List<String>> synonyms,
  ) {
    for (final option in options) {
      final name = _normalize(nameOf(option)).trim();
      if (name.isEmpty) continue;
      if (_has(text, name)) return option;
      // Definite-article fold so "الرياض" joins the "رياض"/"riyadh" group.
      final stripped = name.startsWith('ال') && name.length > 3
          ? name.substring(2)
          : name;
      for (final entry in synonyms.entries) {
        final group = [entry.key, ...entry.value];
        final inGroup = group.any((w) {
          final g = _normalize(w).trim();
          return g == name || g == stripped;
        });
        if (inGroup && _hasAny(text, group)) return option;
      }
    }
    return null;
  }

  static const _bedWords = [
    'bed',
    'beds',
    'bedroom',
    'bedrooms',
    'br',
    'غرف',
    'غرفه',
    'غرف نوم',
  ];
  static const _bathWords = [
    'bath',
    'baths',
    'bathroom',
    'bathrooms',
    'حمام',
    'حمامات',
    'دورات مياه',
  ];

  static int? _count(String text, List<String> units) {
    for (final unit in units) {
      final u = _normalize(unit).trim();
      final m = RegExp('(\\d+)\\s+(?:ال)?$u ').firstMatch(text);
      if (m != null) return int.tryParse(m.group(1)!);
    }
    return null;
  }

  // Price. Verified params are filter[min_price]/filter[max_price] (SAR).
  // "above/أكثر من" → min; "under/أقل من" → max; a bare amount with a
  // million/thousand unit (or ≥ 50k raw) is treated as a budget → max,
  // matching the handoff spec's `budget` semantics.
  static const _aboveWords = ['above', 'over', 'more than', 'at least', 'from', 'فوق', 'اكثر من', 'باكثر من', 'بحد ادني'];
  static const _belowWords = ['under', 'below', 'less than', 'up to', 'max', 'within', 'اقل من', 'تحت', 'حتي', 'باقل من', 'بحد اقصي'];

  static final _amountRe = RegExp(
    r'(\d[\d,]*(?:\.\d+)?)\s*(million|m|mil|k|thousand|مليون|ملايين|الف|ريال|sar|riyal)?',
  );

  static num? _price(String text, {required bool min}) {
    final markers = min ? _aboveWords : _belowWords;
    for (final marker in markers) {
      final mk = _normalize(marker).trim();
      final re = RegExp('$mk\\s+${_amountRe.pattern}');
      final m = re.firstMatch(text);
      final v = m == null ? null : _amount(m.group(1)!, m.group(2));
      if (v != null) return v;
    }
    if (min) return null;
    // Bare budget (no direction marker anywhere in the text).
    final directed = [..._aboveWords, ..._belowWords]
        .any((w) => text.contains(' ${_normalize(w).trim()} '));
    if (directed) return null;
    for (final m in _amountRe.allMatches(text)) {
      final unit = m.group(2);
      final v = _amount(m.group(1)!, unit);
      if (v == null) continue;
      final hasUnit = unit != null && unit != 'ريال' && unit != 'sar' && unit != 'riyal';
      if (hasUnit || v >= 50000) return v;
    }
    return null;
  }

  static num? _amount(String digits, String? unit) {
    final v = num.tryParse(digits.replaceAll(',', ''));
    if (v == null) return null;
    return switch (unit) {
      'million' || 'm' || 'mil' || 'مليون' || 'ملايين' => v * 1000000,
      'k' || 'thousand' || 'الف' => v * 1000,
      _ => v,
    };
  }

  // Verified furnishing_status enum only. A bare "furnished/مفروشة" has no
  // verified enum value, so it deliberately sets NOTHING (never guess).
  static String? _furnishing(String text) {
    if (_hasAny(text, ['unfurnished', 'غير مفروش', 'غير مفروشه', 'بدون فرش'])) {
      return 'unfurnished';
    }
    if (_hasAny(text, ['semi furnished', 'semi-furnished', 'شبه مفروش', 'شبه مفروشه'])) {
      return 'semi-furnished';
    }
    if (_hasAny(text, ['partially furnished', 'مفروش جزييا', 'مفروشه جزييا'])) {
      return 'partially_furnished';
    }
    return null;
  }

  static String? _listingType(String text) {
    if (_hasAny(text, ['rent', 'rental', 'lease', 'renting', 'ايجار', 'للايجار', 'استيجار'])) {
      return 'for-rent';
    }
    if (_hasAny(text, ['buy', 'sale', 'purchase', 'buying', 'بيع', 'للبيع', 'شراء', 'تملك'])) {
      return 'for-sale';
    }
    return null;
  }

  // Canonical bridges keyed by the API's EN titles (lowercased). Values
  // cover plurals + Arabic forms (normalized at match time).
  static const Map<String, List<String>> _typeSynonyms = {
    'apartment': ['apartments', 'flat', 'flats', 'شقه', 'شقق'],
    'villa': ['villas', 'فيلا', 'فلل'],
    'townhouse': ['townhouses', 'town house', 'تاون هاوس'],
    'penthouse': ['penthouses', 'بنتهاوس'],
    'studio': ['studios', 'ستوديو', 'استوديو'],
    'farm': ['farms', 'مزرعه', 'مزارع'],
    'land': ['lands', 'plot', 'ارض', 'اراضي'],
    'office': ['offices', 'office space', 'مكتب', 'مكاتب', 'مساحات مكتبيه', 'مساحه مكتبيه'],
    'roof': ['سطح', 'اسطح'],
    'shop': ['shops', 'محل', 'محلات'],
    'building': ['buildings', 'عماره', 'مبني'],
    'chalet': ['chalets', 'شاليه', 'شاليهات'],
    'floor': ['دور', 'طابق'],
  };

  static const Map<String, List<String>> _citySynonyms = {
    'riyadh': ['رياض'],
    'jeddah': ['jedda', 'jaddah', 'جده'],
    'makkah': ['mecca', 'makka', 'مكه', 'مكه المكرمه'],
    'dammam': ['دمام'],
    'khobar': ['al khobar', 'خبر'],
    'taif': ['الطايف', 'طايف'],
    'dhahran': ['ظهران'],
    'hofuf': ['هفوف'],
    'al qatif': ['قطيف'],
    'al jubail': ['جبيل'],
  };
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// One saved search from the home search card — mirrors the website's
/// "Latest searches" chips ("Off-Plan / All — Riyadh").
class RecentSearch {
  /// 0=Buy 1=Rent 2=Off-Plan 3=Commercial (search-card tab order).
  final int tab;
  final int? propertyTypeId;
  final String? propertyTypeLabel;
  final String query;

  const RecentSearch({
    required this.tab,
    this.propertyTypeId,
    this.propertyTypeLabel,
    required this.query,
  });

  Map<String, dynamic> toJson() => {
    'tab': tab,
    'ptid': propertyTypeId,
    'ptl': propertyTypeLabel,
    'q': query,
  };

  static RecentSearch? fromJson(dynamic v) {
    if (v is! Map) return null;
    final tab = v['tab'];
    final q = v['q'];
    if (tab is! int || q is! String) return null;
    return RecentSearch(
      tab: tab,
      propertyTypeId: v['ptid'] is int ? v['ptid'] as int : null,
      propertyTypeLabel: v['ptl']?.toString(),
      query: q,
    );
  }
}

/// Local persistence for the last few searches (newest first, de-duplicated).
class RecentSearchesStore {
  static const String _key = 'recent_searches_v1';
  static const int _max = 5;

  Future<List<RecentSearch>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map(RecentSearch.fromJson)
          .whereType<RecentSearch>()
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<RecentSearch>> add(RecentSearch search) async {
    final current = await load();
    final next = [
      search,
      ...current.where(
        (s) => !(s.query == search.query && s.tab == search.tab),
      ),
    ].take(_max).toList(growable: false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode([for (final s in next) s.toJson()]));
    return next;
  }
}

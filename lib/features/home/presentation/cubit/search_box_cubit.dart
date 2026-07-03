import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/lookup/lookup_service.dart';
import '../../../../core/storage/recent_searches_store.dart';

/// The search card's tabs, mirroring the website's search box.
enum SearchTab { buy, rent, offPlan, commercial }

class SearchBoxState {
  final SearchTab tab;

  /// Selected property type (null = All).
  final PropertyTypeOption? propertyType;

  /// Property types from /lookup (empty while loading or on failure —
  /// the dropdown simply offers "All" until they arrive).
  final List<PropertyTypeOption> types;

  /// Cities from /lookup, used to resolve the typed query to a real
  /// `filter[city_id]` (the website resolves text → city slug the same way).
  final List<CityOption> cities;

  final List<RecentSearch> recents;

  const SearchBoxState({
    this.tab = SearchTab.buy,
    this.propertyType,
    this.types = const [],
    this.cities = const [],
    this.recents = const [],
  });

  SearchBoxState copyWith({
    SearchTab? tab,
    PropertyTypeOption? Function()? propertyType,
    List<PropertyTypeOption>? types,
    List<CityOption>? cities,
    List<RecentSearch>? recents,
  }) {
    return SearchBoxState(
      tab: tab ?? this.tab,
      propertyType: propertyType == null ? this.propertyType : propertyType(),
      types: types ?? this.types,
      cities: cities ?? this.cities,
      recents: recents ?? this.recents,
    );
  }
}

/// Drives the home search card: lookup-backed dropdown, tab selection and
/// the persisted "Latest searches" chips.
class SearchBoxCubit extends Cubit<SearchBoxState> {
  final LookupService _lookup;
  final RecentSearchesStore _store;

  SearchBoxCubit(this._lookup, this._store) : super(const SearchBoxState());

  Future<void> init() async {
    final recents = await _store.load();
    if (isClosed) return;
    emit(state.copyWith(recents: recents));
    try {
      final types = await _lookup.propertyTypes();
      final cities = await _lookup.cities();
      if (isClosed) return;
      emit(state.copyWith(types: types, cities: cities));
    } catch (_) {
      // Lookups are an enhancement (dropdown + city matching); the card
      // stays fully usable without them, so failures are non-fatal here.
    }
  }

  void selectTab(SearchTab tab) => emit(state.copyWith(tab: tab));

  void selectType(PropertyTypeOption? type) =>
      emit(state.copyWith(propertyType: () => type));

  /// Resolves the typed text to a lookup city id (EN or AR — /lookup names come
  /// localized). Exact match wins; otherwise a word-prefix match for queries of
  /// 2+ chars. Deliberately avoids substring/`q.contains(name)` matching, which
  /// let empty or short city names ("Al…") match unrelated input and filter to
  /// the wrong city. Null when no confident match.
  int? resolveCityId(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return null;

    // 1) Exact (case-insensitive) match.
    for (final c in state.cities) {
      final name = c.name.trim().toLowerCase();
      if (name.isNotEmpty && name == q) return int.tryParse(c.id);
    }

    // 2) Word-prefix match — the city name, or a word within it, starts with
    //    the query. Only for 2+ chars so single letters can't match arbitrarily.
    if (q.length < 2) return null;
    for (final c in state.cities) {
      final name = c.name.trim().toLowerCase();
      if (name.isEmpty) continue;
      final words = name.split(RegExp(r'\s+'));
      if (name.startsWith(q) || words.any((w) => w.startsWith(q))) {
        return int.tryParse(c.id);
      }
    }
    return null;
  }

  /// Persist a submitted search and refresh the chips.
  Future<void> remember(String query) async {
    final recents = await _store.add(
      RecentSearch(
        tab: state.tab.index,
        propertyTypeId: state.propertyType?.id,
        propertyTypeLabel: state.propertyType?.name,
        query: query.trim(),
      ),
    );
    if (isClosed) return;
    emit(state.copyWith(recents: recents));
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/api_result.dart';
import '../../../../core/lookup/lookup_service.dart';
import '../../domain/entities/property_query.dart';
import '../../domain/entities/type_count.dart';
import '../../domain/usecases/search_properties.dart';
import 'type_counts_cache.dart';

/// Live counts per property type, matching the strip dwelleo.sa shows above
/// its results.
///
/// The totals come from the SAME verified search endpoint the list uses —
/// `filter[property_types][]=<id>` and the envelope's `pagination.total`
/// (spot-checked live 2026-07-21: type 1 → 2,321, type 2 → 926, exactly the
/// numbers the website prints). There is no dedicated counts endpoint, so
/// each type costs one cheap request; results are emitted as they land so
/// the strip fills in progressively instead of blocking the list.
///
/// Results are memoized per query in [TypeCountsCache] so revisiting a list
/// reuses the strip instead of re-running the fan-out. A single cubit only ever
/// loads its screen's one query and never overlaps its own fan-outs: a plain
/// load joins the in-flight one, and a forceRefresh chains after it (see
/// [_inFlight]). Concurrent first-opens of *different* cubit instances can each
/// still fan out (rare, accepted).
class TypeCountsCubit extends Cubit<List<TypeCount>> {
  final SearchProperties _search;
  final LookupService _lookup;
  final TypeCountsCache _cache;

  TypeCountsCubit(this._search, this._lookup, this._cache) : super(const []);

  /// Cap the fan-out: the site shows a handful of headline types, not all.
  static const int maxTypes = 6;

  /// The cubit's current load, if any — serializes this cubit's own loads so
  /// two fan-outs never run (and emit) at once.
  Future<void>? _inFlight;

  /// Loads the strip for [base] (default query when null). Serves the cached
  /// result unless [forceRefresh] is set, in which case the fan-out re-runs and
  /// overwrites the cache entry — used by pull-to-refresh so the counts can move.
  Future<void> load({PropertyQuery? base, bool forceRefresh = false}) {
    final pending = _inFlight;
    // A plain load already running is exactly what a caller wants — join it.
    if (pending != null && !forceRefresh) return pending;
    // Chain after any in-flight load so the fan-outs never overlap.
    final future = pending == null
        ? _load(base: base, forceRefresh: forceRefresh)
        : pending.then((_) => _load(base: base, forceRefresh: forceRefresh));
    _inFlight = future;
    future.whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
    return future;
  }

  Future<void> _load({PropertyQuery? base, required bool forceRefresh}) async {
    final key = base ?? const PropertyQuery();
    // Always read (syncs the cache's locale); ignore the value on a refresh.
    final cached = await _cache.get(key);
    if (isClosed) return;
    if (!forceRefresh && cached != null) {
      // Session cache hit — reuse the strip instead of re-firing the fan-out.
      emit(cached);
      return;
    }

    List<PropertyTypeOption> types;
    try {
      types = await _lookup.propertyTypes();
    } catch (_) {
      return;
    }
    if (isClosed || types.isEmpty) return;

    final wanted = types.take(maxTypes).toList(growable: false);
    // Fixed slots keep the site's type order regardless of which request
    // lands first; counts are independent, so fire them all at once.
    final slots = List<TypeCount?>.filled(wanted.length, null);
    // A single failed request means the strip is missing a type — don't cache a
    // partial result, so the next visit retries instead of freezing the gap.
    var complete = true;

    Future<void> fetch(int index, PropertyTypeOption type) async {
      final result = await _search(
        key.copyWith(propertyTypeIds: [type.id], page: 1),
      );
      if (isClosed) return;
      if (result case ApiSuccess(:final data)) {
        final total = data.pageInfo?.total;
        if (total != null && total > 0) {
          slots[index] = TypeCount(
            typeId: type.id,
            name: type.name,
            total: total,
          );
          // Emit progressively so the strip fills in as counts arrive.
          emit(List.unmodifiable(slots.whereType<TypeCount>()));
        }
      } else {
        complete = false;
      }
    }

    await Future.wait([
      for (var i = 0; i < wanted.length; i++) fetch(i, wanted[i]),
    ]);
    if (isClosed) return;
    // Cache from THIS load's own slots (not `state`, which a sibling load could
    // have touched) and only when complete — a failed refresh leaves the prior
    // good entry untouched rather than dropping it.
    final counts = List<TypeCount>.unmodifiable(slots.whereType<TypeCount>());
    if (complete && counts.isNotEmpty) _cache.put(key, counts);
  }
}

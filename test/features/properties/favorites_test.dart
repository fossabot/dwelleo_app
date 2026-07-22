import 'package:dwelleo_app/core/db/app_database.dart';
import 'package:dwelleo_app/core/errors/api_result.dart';
import 'package:dwelleo_app/features/properties/data/datasources/favorites_local_data_source.dart';
import 'package:dwelleo_app/features/properties/data/repositories/favorites_repository_impl.dart';
import 'package:dwelleo_app/features/properties/domain/entities/property.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory stand-in for the SQLite data source — overrides every method so
/// the real [AppDatabase] (passed but unused) never touches sqflite.
class _MemFavoritesDataSource extends FavoritesLocalDataSource {
  _MemFavoritesDataSource() : super(AppDatabase());

  final Map<int, Property> _store = {};
  bool throwOnWrite = false;

  @override
  Future<void> upsert(Property p) async {
    if (throwOnWrite) throw Exception('disk full');
    _store[p.id] = p;
  }

  @override
  Future<void> remove(int propertyId) async {
    if (throwOnWrite) throw Exception('disk full');
    _store.remove(propertyId);
  }

  @override
  Future<Set<int>> ids() async => _store.keys.toSet();

  @override
  Future<List<Property>> all() async => _store.values.toList();
}

Property _property(int id) =>
    Property(id: id, slug: 'p$id', title: 'Property $id');

void main() {
  late _MemFavoritesDataSource local;
  late FavoritesRepositoryImpl repo;

  setUp(() {
    local = _MemFavoritesDataSource();
    repo = FavoritesRepositoryImpl(local);
  });

  test('toggle saves when absent and reports the new state', () async {
    final result = await repo.toggle(_property(7));

    expect(result, isA<ApiSuccess<bool>>());
    expect((result as ApiSuccess<bool>).data, isTrue);
    expect(await local.ids(), {7});
  });

  test('toggle removes when already saved', () async {
    await repo.toggle(_property(7)); // save
    final result = await repo.toggle(_property(7)); // unsave

    expect((result as ApiSuccess<bool>).data, isFalse);
    expect(await local.ids(), isEmpty);
  });

  test('favorites() returns every saved property', () async {
    await repo.toggle(_property(1));
    await repo.toggle(_property(2));

    final result = await repo.favorites();
    final list = (result as ApiSuccess<List<Property>>).data;

    expect(list.map((p) => p.id), containsAll(<int>[1, 2]));
  });

  test('a storage failure surfaces as an ApiError, never throws', () async {
    local.throwOnWrite = true;

    final result = await repo.toggle(_property(7));

    // Saving must never crash browsing — the boundary maps it to a Failure.
    expect(result, isA<ApiError>());
  });
}

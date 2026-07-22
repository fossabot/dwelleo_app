import '../../../../core/db/app_database.dart';
import '../../domain/entities/estimate_models.dart';

/// Raw SQLite CRUD for saved estimates (DB v3 `estimates`). Throws on
/// failure — the repository maps errors to typed Failures at the boundary.
class EstimateLocalDataSource {
  final AppDatabase _db;

  const EstimateLocalDataSource(this._db);

  Future<int> save(EstimateInput input, EstimateResult result) async {
    final db = await _db.database;
    return db.insert('estimates', {
      'purpose': input.purpose.name,
      'city_id': input.cityId,
      'city_name': input.cityName ?? '',
      'district_id': input.districtId,
      'district_name': input.districtName ?? '',
      'unit_type_id': input.unitTypeId,
      'area_sqm': (input.areaSqm ?? 0).toDouble(),
      'mid': result.mid.toDouble(),
      'low': result.low.toDouble(),
      'high': result.high.toDouble(),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<List<SavedEstimate>> all() async {
    final db = await _db.database;
    final rows = await db.query('estimates', orderBy: 'created_at DESC');
    return [
      for (final r in rows)
        SavedEstimate(
          id: r['id'] as int,
          purpose: r['purpose'] == EstimatePurpose.rent.name
              ? EstimatePurpose.rent
              : EstimatePurpose.sell,
          cityName: r['city_name'] as String,
          districtName: r['district_name'] as String,
          unitTypeId: r['unit_type_id'] as int,
          areaSqm: r['area_sqm'] as num,
          mid: r['mid'] as num,
          low: r['low'] as num,
          high: r['high'] as num,
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            r['created_at'] as int,
          ),
        ),
    ];
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('estimates', where: 'id = ?', whereArgs: [id]);
  }
}

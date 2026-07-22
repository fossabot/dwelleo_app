import 'package:sqflite/sqflite.dart';

import '../../../../core/db/app_database.dart';
import '../../domain/entities/property.dart';

/// SQLite CRUD for locally saved (favorited) properties. Stores a compact
/// snapshot so the Saved tab renders instantly and offline; tapping through
/// re-fetches the fresh listing by slug. Throws on failure — the repository
/// maps to typed Failures.
class FavoritesLocalDataSource {
  final AppDatabase _db;

  const FavoritesLocalDataSource(this._db);

  Future<void> upsert(Property p) async {
    final db = await _db.database;
    await db.insert('favorites', {
      'property_id': p.id,
      'slug': p.slug,
      'title': p.title,
      'price': p.price?.toDouble(),
      'city': p.cityName,
      'image_url': p.coverImage?.displayThumb,
      'listing_key': p.listingType?.key,
      'beds': p.bedrooms,
      'baths': p.bathrooms,
      'area': p.areaSqm?.toDouble(),
      'created_at': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> remove(int propertyId) async {
    final db = await _db.database;
    await db.delete(
      'favorites',
      where: 'property_id = ?',
      whereArgs: [propertyId],
    );
  }

  Future<Set<int>> ids() async {
    final db = await _db.database;
    final rows = await db.query('favorites', columns: ['property_id']);
    return {for (final r in rows) r['property_id'] as int};
  }

  Future<List<Property>> all() async {
    final db = await _db.database;
    final rows = await db.query('favorites', orderBy: 'created_at DESC');
    return [
      for (final r in rows)
        Property(
          id: r['property_id'] as int,
          slug: r['slug'] as String,
          title: r['title'] as String,
          price: r['price'] as double?,
          bedrooms: r['beds'] as int?,
          bathrooms: r['baths'] as int?,
          areaSqm: r['area'] as double?,
          isFavorite: true,
          city: (r['city'] as String?) == null
              ? null
              : NamedRef(id: 0, name: r['city'] as String),
          coverImage: (r['image_url'] as String?) == null
              ? null
              : MediaImage(id: 0, path: r['image_url'] as String),
          listingType: (r['listing_key'] as String?) == null
              ? null
              : ListingType(
                  key: r['listing_key'] as String,
                  label: r['listing_key'] as String,
                ),
        ),
    ];
  }
}

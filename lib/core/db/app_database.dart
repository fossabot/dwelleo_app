import 'package:sqflite/sqflite.dart';

/// Single SQLite database for on-device relational data.
///
/// Today it holds the AI Sales Agent chat history; future tables (drafts,
/// offline cache…) join here with a version bump + migration in [_onUpgrade].
class AppDatabase {
  // Cache the Future, not the Database — prevents two concurrent callers both
  // running _open() before the first one finishes (race on the ??= read).
  Future<Database>? _opening;

  static const _version = 3;

  Future<Database> get database => _opening ??= _open();

  Future<Database> _open() async {
    final path = '${await getDatabasesPath()}/dwelleo.db';
    return openDatabase(
      path,
      version: _version,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sales_conversations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        lead_json TEXT NOT NULL DEFAULT '{}',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sales_messages(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        conversation_id INTEGER NOT NULL
          REFERENCES sales_conversations(id) ON DELETE CASCADE,
        role TEXT NOT NULL,
        text TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_sales_messages_convo '
      'ON sales_messages(conversation_id)',
    );
    await db.execute(_createFavorites);
    await db.execute(_createEstimates);
  }

  /// v2: local favorites — the Saved tab's source of truth (guest-friendly;
  /// the authed `filter[is_favorite]` sync can merge in later).
  static const _createFavorites = '''
      CREATE TABLE favorites(
        property_id INTEGER PRIMARY KEY,
        slug TEXT NOT NULL,
        title TEXT NOT NULL,
        price REAL,
        city TEXT,
        image_url TEXT,
        listing_key TEXT,
        beds INTEGER,
        baths INTEGER,
        area REAL,
        created_at INTEGER NOT NULL
      )
    ''';

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(_createFavorites);
    }
    if (oldVersion < 3) {
      await db.execute(_createEstimates);
    }
  }

  /// v3: saved property estimates — the 6-phase wizard's output, kept on
  /// device so the owner's "wizard effects the database" requirement holds
  /// for guests too and the Sales Agent can read the seller's own valuation.
  static const _createEstimates = '''
      CREATE TABLE estimates(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purpose TEXT NOT NULL,
        city_id INTEGER,
        city_name TEXT NOT NULL,
        district_id INTEGER,
        district_name TEXT NOT NULL,
        unit_type_id INTEGER NOT NULL,
        area_sqm REAL NOT NULL,
        mid REAL NOT NULL,
        low REAL NOT NULL,
        high REAL NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''';

  Future<void> close() async {
    final db = await _opening;
    _opening = null;
    await db?.close();
  }
}

import 'package:sqflite/sqflite.dart';

/// Single SQLite database for on-device relational data.
///
/// Today it holds the AI Sales Agent chat history; future tables (drafts,
/// offline cache…) join here with a version bump + migration in [_onUpgrade].
class AppDatabase {
  Database? _database;

  static const _version = 1;

  Future<Database> get database async => _database ??= await _open();

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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // v1 → future migrations go here, gated by oldVersion checks.
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

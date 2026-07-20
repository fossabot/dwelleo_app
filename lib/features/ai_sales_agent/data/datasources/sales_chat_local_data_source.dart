import 'dart:convert';

import '../../../../core/db/app_database.dart';
import '../../domain/entities/chat_history.dart';
import '../../domain/entities/sales_models.dart';

/// Raw SQLite CRUD for Sales Agent chat history. Throws on failure — the
/// repository maps errors to typed Failures at the data boundary.
class SalesChatLocalDataSource {
  final AppDatabase _db;

  const SalesChatLocalDataSource(this._db);

  Future<List<ConversationSummary>> conversations() async {
    final db = await _db.database;
    final rows = await db.query(
      'sales_conversations',
      columns: ['id', 'title', 'updated_at'],
      orderBy: 'updated_at DESC',
    );
    return [
      for (final r in rows)
        ConversationSummary(
          id: r['id'] as int,
          title: r['title'] as String,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(
            r['updated_at'] as int,
          ),
        ),
    ];
  }

  Future<ChatSnapshot> load(int conversationId) async {
    final db = await _db.database;
    final convo = await db.query(
      'sales_conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
      limit: 1,
    );
    final rows = await db.query(
      'sales_messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'id ASC',
    );

    // Rebuild resolved turns by pairing each user message with the agent
    // reply that follows it (stray rows are skipped defensively).
    final turns = <SalesTurn>[];
    String? pendingUser;
    for (final r in rows) {
      final role = r['role'] as String;
      final text = r['text'] as String;
      if (role == SalesRole.user.name) {
        pendingUser = text;
      } else if (pendingUser != null) {
        turns.add(
          SalesTurn(utterance: pendingUser, reply: SalesReply(text: text)),
        );
        pendingUser = null;
      }
    }

    final leadJson = convo.isEmpty
        ? '{}'
        : (convo.first['lead_json'] as String? ?? '{}');
    return ChatSnapshot(
      turns: List.unmodifiable(turns),
      lead: _leadFromJson(leadJson),
    );
  }

  Future<int> create({required String title, required LeadProfile lead}) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    return db.insert('sales_conversations', {
      'title': title,
      'lead_json': _leadToJson(lead),
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<void> appendMessage({
    required int conversationId,
    required SalesRole role,
    required String text,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('sales_messages', {
      'conversation_id': conversationId,
      'role': role.name,
      'text': text,
      'created_at': now,
    });
    await db.update(
      'sales_conversations',
      {'updated_at': now},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<void> saveLead({
    required int conversationId,
    required LeadProfile lead,
  }) async {
    final db = await _db.database;
    await db.update(
      'sales_conversations',
      {'lead_json': _leadToJson(lead)},
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  Future<void> delete(int conversationId) async {
    final db = await _db.database;
    // Messages cascade via the FK (PRAGMA foreign_keys=ON in AppDatabase).
    await db.delete(
      'sales_conversations',
      where: 'id = ?',
      whereArgs: [conversationId],
    );
  }

  static String _leadToJson(LeadProfile l) => jsonEncode({
    'budget': l.budget,
    'intent': l.intent,
    'timeline': l.timeline,
    'eligibility': l.eligibility,
    'preferences': l.preferences,
  });

  static LeadProfile _leadFromJson(String raw) {
    try {
      final m = jsonDecode(raw);
      if (m is! Map) return LeadProfile.empty;
      String? f(Object? v) =>
          (v is String && v.trim().isNotEmpty) ? v : null;
      return LeadProfile(
        budget: f(m['budget']),
        intent: f(m['intent']),
        timeline: f(m['timeline']),
        eligibility: f(m['eligibility']),
        preferences: f(m['preferences']),
      );
    } catch (_) {
      return LeadProfile.empty;
    }
  }
}

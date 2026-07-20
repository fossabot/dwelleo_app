import 'sales_models.dart';

/// One saved conversation in the history list (Claude-app-style journey:
/// persisted chats the user can reopen or delete).
class ConversationSummary {
  final int id;
  final String title;
  final DateTime updatedAt;

  const ConversationSummary({
    required this.id,
    required this.title,
    required this.updatedAt,
  });
}

/// A fully loaded conversation: resolved turns + the cumulative lead sheet.
class ChatSnapshot {
  final List<SalesTurn> turns;
  final LeadProfile lead;

  const ChatSnapshot({required this.turns, required this.lead});
}

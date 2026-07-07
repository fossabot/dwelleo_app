import '../../domain/entities/ai_search_models.dart';

/// Sealed union for the AI Search screen (Dart 3, no codegen).
sealed class AiSearchState {
  const AiSearchState();
}

/// Welcome view — logo, intro copy and the site's six suggestions.
class AiSearchIdle extends AiSearchState {
  const AiSearchIdle();
}

/// Conversation view — an append-only list of turns; the last turn carries
/// the in-flight/loaded/failed status.
class AiSearchChat extends AiSearchState {
  final List<AiSearchTurn> turns;
  const AiSearchChat(this.turns);
}

import '../../../../core/errors/failure.dart';

/// Who said a chat line — used to rebuild conversation history for the model.
enum SalesRole { user, agent }

class SalesMessage {
  final SalesRole role;
  final String text;

  const SalesMessage({required this.role, required this.text});
}

/// BITEP lead qualification — Budget, Intent, Timeline, Eligibility,
/// Preferences. CONFIRMED as Dwelleo's framework on the live /ai-Sales page
/// ("5-Dimension Lead Scoring — BITEP"). Values are short, localized snippets
/// extracted by the model; null = not captured yet.
class LeadProfile {
  final String? budget;
  final String? intent;
  final String? timeline;
  final String? eligibility;
  final String? preferences;

  const LeadProfile({
    this.budget,
    this.intent,
    this.timeline,
    this.eligibility,
    this.preferences,
  });

  static const empty = LeadProfile();

  bool get hasAny =>
      budget != null ||
      intent != null ||
      timeline != null ||
      eligibility != null ||
      preferences != null;

  /// Cumulative lead sheet: newer non-empty values win, older ones persist.
  LeadProfile merge(LeadProfile other) => LeadProfile(
    budget: _pick(other.budget, budget),
    intent: _pick(other.intent, intent),
    timeline: _pick(other.timeline, timeline),
    eligibility: _pick(other.eligibility, eligibility),
    preferences: _pick(other.preferences, preferences),
  );

  static String? _pick(String? next, String? current) =>
      (next != null && next.trim().isNotEmpty) ? next.trim() : current;
}

/// One resolved agent reply: the conversational text plus the model's
/// cumulative BITEP understanding.
class SalesReply {
  final String text;
  final LeadProfile lead;

  const SalesReply({required this.text, this.lead = LeadProfile.empty});
}

/// One conversation turn (user utterance + agent outcome), mirroring the
/// AiSearchTurn shape so both AI surfaces feel identical.
class SalesTurn {
  final String utterance;
  final bool loading;
  final SalesReply? reply;
  final Failure? failure;

  const SalesTurn({
    required this.utterance,
    this.loading = false,
    this.reply,
    this.failure,
  });
}

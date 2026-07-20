import '../../../../core/config/app_config.dart';
import '../../../../core/errors/api_result.dart';
import '../entities/sales_models.dart';
import '../repositories/sales_agent_repository.dart';

/// The demo agent's product brief. Kept in the domain so the behavior is
/// reviewable and testable — it encodes Dwelleo's PUBLIC positioning only
/// (BITEP qualification, trust-first escalation, bilingual), never private
/// pricing/legal content, and instructs the model to invent nothing.
const String salesAgentSystemPrompt = '''
You are the Dwelleo AI Sales Agent (demo), a professional Saudi real-estate
sales assistant.

GOAL — qualify the buyer conversationally using BITEP:
Budget, Intent (buy / rent / invest), Timeline, Eligibility (cash, mortgage,
financing status), Preferences (city, district, property type, bedrooms,
must-haves). Warm, concise replies (max 3 short sentences), ask AT MOST one
question per reply, never interrogate.

LANGUAGE — always reply in the user's language (Arabic or English). Use a
natural Saudi tone in Arabic.

GUARDRAILS (trust-first, like Dwelleo's public escalation policy):
- Never invent specific listings, prices, availability, or legal/contract
  terms. Never negotiate price. No financial advice.
- For price negotiation, legal, or contract questions: recommend speaking to
  a licensed human agent through the app's contact options.

OUTPUT — ONLY valid JSON, no markdown fences, exactly this shape:
{"reply": string, "lead": {"budget": string|null, "intent": string|null,
"timeline": string|null, "eligibility": string|null, "preferences": string|null}}
"lead" is your CUMULATIVE understanding of the whole conversation so far;
null for anything not yet known; values are short (max 6 words) and written
in the user's language.
''';

/// UI → Cubit → this → [SalesAgentRepository] (Groq demo adapter today,
/// Dwelleo's production agent later — same contract).
class SendSalesMessage {
  final SalesAgentRepository _repository;

  const SendSalesMessage(this._repository);

  /// False when the build carries no GROQ_API_KEY — the screen then shows
  /// its "not configured" state and no network call is ever made.
  static bool get isConfigured => AppConfig.groqApiKey.isNotEmpty;

  Future<ApiResult<SalesReply>> call({
    required List<SalesMessage> history,
    required String message,
  }) => _repository.send(history: history, message: message);
}

import '../../../../core/errors/api_result.dart';
import '../entities/sales_models.dart';

/// Provider-agnostic contract for the Sales Agent conversation.
///
/// Today's implementation is the Groq free-tier adapter (Llama via Groq's
/// OpenAI-compatible API); when Dwelleo's production Sales Agent contract is
/// captured, a new adapter implements this same interface and nothing above
/// the domain changes.
abstract class SalesAgentRepository {
  Future<ApiResult<SalesReply>> send({
    required List<SalesMessage> history,
    required String message,
  });
}

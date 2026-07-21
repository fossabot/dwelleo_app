import '../../domain/entities/sales_models.dart';

/// Provider-agnostic LLM transport for the Sales Agent. Each adapter
/// (Groq today, Dwelleo's future production agent) maps its own wire
/// envelope down to the model's raw text; the repository parses that text
/// into a [SalesReply] via SalesReplyModel.fromModelText.
abstract class SalesRemoteDataSource {
  Future<String> generateText({
    required String systemPrompt,
    required List<SalesMessage> history,
    required String message,
  });
}

import '../../../../core/errors/api_result.dart';
import '../entities/chat_history.dart';
import '../entities/sales_models.dart';

/// Persistence contract for Sales Agent conversations (local SQLite today;
/// a synced backend can implement the same contract later).
abstract class SalesChatRepository {
  Future<ApiResult<List<ConversationSummary>>> conversations();

  Future<ApiResult<ChatSnapshot>> load(int conversationId);

  /// Creates a conversation and returns its id.
  Future<ApiResult<int>> create({
    required String title,
    required LeadProfile lead,
  });

  Future<ApiResult<void>> appendMessage({
    required int conversationId,
    required SalesRole role,
    required String text,
  });

  Future<ApiResult<void>> saveLead({
    required int conversationId,
    required LeadProfile lead,
  });

  Future<ApiResult<void>> delete(int conversationId);
}

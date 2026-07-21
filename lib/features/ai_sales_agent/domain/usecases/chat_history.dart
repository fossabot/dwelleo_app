import '../../../../core/errors/api_result.dart';
import '../entities/chat_history.dart';
import '../entities/sales_models.dart';
import '../repositories/sales_chat_repository.dart';

/// Chat-history use case facade (pure delegation) — keeps the cubit
/// depending on use cases only, per CLAUDE.md, without six one-line classes.
class ChatHistory {
  final SalesChatRepository _repository;

  const ChatHistory(this._repository);

  Future<ApiResult<List<ConversationSummary>>> conversations() =>
      _repository.conversations();

  Future<ApiResult<ChatSnapshot>> load(int conversationId) =>
      _repository.load(conversationId);

  Future<ApiResult<int>> create({
    required String title,
    required LeadProfile lead,
  }) => _repository.create(title: title, lead: lead);

  Future<ApiResult<void>> appendMessage({
    required int conversationId,
    required SalesRole role,
    required String text,
  }) => _repository.appendMessage(
    conversationId: conversationId,
    role: role,
    text: text,
  );

  Future<ApiResult<void>> saveLead({
    required int conversationId,
    required LeadProfile lead,
  }) => _repository.saveLead(conversationId: conversationId, lead: lead);

  Future<ApiResult<void>> delete(int conversationId) =>
      _repository.delete(conversationId);
}

import '../../../../core/errors/api_result.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/chat_history.dart';
import '../../domain/entities/sales_models.dart';
import '../../domain/repositories/sales_chat_repository.dart';
import '../datasources/sales_chat_local_data_source.dart';

/// Local SQLite implementation — every call is guarded here (data boundary)
/// and surfaces as a typed [CacheFailure]; persistence problems must never
/// crash the conversation itself.
class SalesChatRepositoryImpl implements SalesChatRepository {
  final SalesChatLocalDataSource _local;

  const SalesChatRepositoryImpl(this._local);

  @override
  Future<ApiResult<List<ConversationSummary>>> conversations() =>
      _guard(_local.conversations);

  @override
  Future<ApiResult<ChatSnapshot>> load(int conversationId) =>
      _guard(() => _local.load(conversationId));

  @override
  Future<ApiResult<int>> create({
    required String title,
    required LeadProfile lead,
  }) => _guard(() => _local.create(title: title, lead: lead));

  @override
  Future<ApiResult<void>> appendMessage({
    required int conversationId,
    required SalesRole role,
    required String text,
  }) => _guard(
    () => _local.appendMessage(
      conversationId: conversationId,
      role: role,
      text: text,
    ),
  );

  @override
  Future<ApiResult<void>> saveLead({
    required int conversationId,
    required LeadProfile lead,
  }) => _guard(() => _local.saveLead(conversationId: conversationId, lead: lead));

  @override
  Future<ApiResult<void>> delete(int conversationId) =>
      _guard(() => _local.delete(conversationId));

  Future<ApiResult<T>> _guard<T>(Future<T> Function() run) async {
    try {
      return ApiSuccess(await run());
    } catch (e) {
      return ApiError(CacheFailure('$e'));
    }
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';

// Provides the ApiResult.when extension used below.
import '../../../../core/errors/api_result.dart';
import '../../domain/entities/sales_models.dart';
import '../../domain/usecases/send_sales_message.dart';
import 'sales_agent_state.dart';

/// Drives the Sales Agent conversation. Depends ONLY on the use case; voice
/// I/O stays in the widget layer (SpeechService/TtsService), matching the
/// AI Search architecture.
class SalesAgentCubit extends Cubit<SalesAgentState> {
  final SendSalesMessage _send;

  SalesAgentCubit(this._send) : super(const SalesAgentIdle());

  List<SalesTurn> get _turns => switch (state) {
    SalesAgentChat(:final turns) => turns,
    SalesAgentIdle() => const [],
  };

  LeadProfile get _lead => switch (state) {
    SalesAgentChat(:final lead) => lead,
    SalesAgentIdle() => LeadProfile.empty,
  };

  Future<void> submit(String raw) async {
    final utterance = raw.trim();
    if (utterance.isEmpty) return;
    final current = _turns;
    if (current.isNotEmpty && current.last.loading) return;

    // History = resolved exchanges only (failed turns are excluded so a
    // retry does not replay an error into the model's context).
    final history = <SalesMessage>[
      for (final t in current)
        if (t.reply != null) ...[
          SalesMessage(role: SalesRole.user, text: t.utterance),
          SalesMessage(role: SalesRole.agent, text: t.reply!.text),
        ],
    ];

    emit(
      SalesAgentChat(
        List.unmodifiable([
          ...current,
          SalesTurn(utterance: utterance, loading: true),
        ]),
        lead: _lead,
      ),
    );

    final result = await _send(history: history, message: utterance);
    if (isClosed) return;

    result.when(
      success: (reply) => _replaceLast(
        SalesTurn(utterance: utterance, reply: reply),
        lead: _lead.merge(reply.lead),
      ),
      error: (failure) => _replaceLast(
        SalesTurn(utterance: utterance, failure: failure),
        lead: _lead,
      ),
    );
  }

  /// Re-sends the last failed turn.
  Future<void> retry() async {
    final current = _turns;
    if (current.isEmpty || current.last.failure == null) return;
    final utterance = current.last.utterance;
    emit(
      SalesAgentChat(
        List.unmodifiable(current.sublist(0, current.length - 1)),
        lead: _lead,
      ),
    );
    await submit(utterance);
  }

  /// New conversation (welcome view, lead sheet cleared).
  void reset() => emit(const SalesAgentIdle());

  void _replaceLast(SalesTurn turn, {required LeadProfile lead}) {
    final current = _turns;
    if (current.isEmpty) return;
    emit(
      SalesAgentChat(
        List.unmodifiable([...current.sublist(0, current.length - 1), turn]),
        lead: lead,
      ),
    );
  }
}

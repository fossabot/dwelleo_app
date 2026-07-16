import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/api_result.dart';
import '../../domain/entities/listing_result.dart';
import '../../domain/entities/sales_models.dart';
import '../../domain/usecases/search_listings.dart';
import '../../domain/usecases/send_sales_message.dart';
import 'sales_agent_state.dart';

/// Drives the Sales Agent conversation. Depends ONLY on use cases; voice
/// I/O stays in the widget layer (SpeechService/TtsService), matching the
/// AI Search architecture.
class SalesAgentCubit extends Cubit<SalesAgentState> {
  final SendSalesMessage _send;
  final SearchListings _search;

  SalesAgentCubit(this._send, this._search) : super(const SalesAgentIdle());

  List<SalesTurn> get _turns => switch (state) {
    SalesAgentChat(:final turns) => turns,
    SalesAgentIdle() => const [],
  };

  LeadProfile get _lead => switch (state) {
    SalesAgentChat(:final lead) => lead,
    SalesAgentIdle() => LeadProfile.empty,
  };

  List<ListingResult> get _listings => switch (state) {
    SalesAgentChat(:final listings) => listings,
    SalesAgentIdle() => const [],
  };

  Future<void> submit(String raw) async {
    final utterance = raw.trim();
    if (utterance.isEmpty) return;
    final current = _turns;
    if (current.isNotEmpty && current.last.loading) return;

    // History = resolved exchanges only (failed turns excluded so a retry
    // does not replay an error into the model's context).
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
        listings: _listings,
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

    // Fire Serper search after a successful reply when the lead has criteria.
    // Non-fatal: a Serper failure never surfaces to the user.
    if (result.isSuccess && SearchListings.isConfigured && _lead.hasAny) {
      await _triggerSearch(_lead);
    }
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
        listings: _listings,
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
        listings: _listings,
      ),
    );
  }

  Future<void> _triggerSearch(LeadProfile lead) async {
    final query = _buildQuery(lead);
    final result = await _search(query);
    if (isClosed) return;
    result.when(
      success: (listings) {
        final current = state;
        if (current is SalesAgentChat) {
          emit(SalesAgentChat(current.turns, lead: current.lead, listings: listings));
        }
      },
      error: (_) {},
    );
  }

  String _buildQuery(LeadProfile lead) {
    final parts = <String>['site:dwelleo.sa'];
    if (lead.preferences != null) parts.add(lead.preferences!);
    if (lead.intent != null) parts.add(lead.intent!);
    return parts.join(' ');
  }
}

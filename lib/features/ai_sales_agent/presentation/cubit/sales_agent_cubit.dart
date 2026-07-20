import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/api_result.dart';
import '../../domain/entities/chat_history.dart';
import '../../domain/entities/listing_result.dart';
import '../../domain/entities/sales_models.dart';
import '../../domain/usecases/chat_history.dart';
import '../../domain/usecases/search_listings.dart';
import '../../domain/usecases/send_sales_message.dart';
import 'sales_agent_state.dart';

/// Drives the Sales Agent conversation. Depends ONLY on use cases; voice
/// I/O stays in the widget layer (SpeechService/TtsService), matching the
/// AI Search architecture.
///
/// Every resolved exchange is persisted through [ChatHistory] (SQLite) —
/// the Claude-app journey: conversations survive restarts, reopen from the
/// history sheet, and can be deleted. Persistence failures are NON-FATAL:
/// the live conversation always wins over the database.
class SalesAgentCubit extends Cubit<SalesAgentState> {
  final SendSalesMessage _send;
  final SearchListings _search;
  final ChatHistory _history;

  SalesAgentCubit(this._send, this._search, this._history)
    : super(const SalesAgentIdle());

  /// Row id of the persisted conversation backing the current chat
  /// (created lazily on the first successful exchange).
  int? _conversationId;

  /// Last Serper query string — skip the API call when unchanged so we don't
  /// burn credits on every reply when the lead criteria hasn't moved.
  String? _lastSearchQuery;

  /// Current app language code ('ar' / 'en') forwarded by the widget via
  /// [setLocale]; Serper passes it as the `hl` ranking hint.
  String _locale = 'ar';

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

    SalesReply? resolved;
    LeadProfile? resolvedLead;
    result.when(
      success: (reply) {
        final merged = _lead.merge(reply.lead);
        _replaceLast(
          SalesTurn(utterance: utterance, reply: reply),
          lead: merged,
        );
        resolved = reply;
        resolvedLead = merged;
      },
      error: (failure) => _replaceLast(
        SalesTurn(utterance: utterance, failure: failure),
        lead: _lead,
      ),
    );

    // Persist AFTER emitting (UI never waits on disk), but awaited so the
    // write order is deterministic — required by tests and by history
    // opened immediately after a reply.
    if (resolved != null) {
      await _persistExchange(utterance, resolved!.text, resolvedLead!);
    }

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

  /// Forwarded by the widget so Serper results are ranked in the current
  /// language (Arabic 'ar' or English 'en').
  void setLocale(String languageCode) {
    _locale = languageCode == 'ar' ? 'ar' : 'en';
  }

  /// New conversation (welcome view, lead sheet cleared). The previous chat
  /// stays in history.
  void reset() {
    _conversationId = null;
    _lastSearchQuery = null;
    emit(const SalesAgentIdle());
  }

  // ------------------------------------------------------------- history

  /// Saved conversations, newest first ([] when the store fails — the
  /// history sheet simply shows its empty state).
  Future<List<ConversationSummary>> conversations() async {
    final result = await _history.conversations();
    return switch (result) {
      ApiSuccess(:final data) => data,
      ApiError() => const [],
    };
  }

  /// Reopens a saved conversation (turns + lead sheet; listings are
  /// ephemeral and start empty).
  Future<void> openConversation(int id) async {
    final result = await _history.load(id);
    if (isClosed) return;
    result.when(
      success: (snapshot) {
        _conversationId = id;
        emit(SalesAgentChat(snapshot.turns, lead: snapshot.lead));
      },
      error: (_) {},
    );
  }

  Future<void> deleteConversation(int id) async {
    await _history.delete(id);
    if (isClosed) return;
    if (id == _conversationId) reset();
  }

  /// Fire-and-forget persistence of a resolved exchange. All ApiErrors are
  /// intentionally swallowed — chat must never break because SQLite did.
  Future<void> _persistExchange(
    String userText,
    String agentText,
    LeadProfile lead,
  ) async {
    var id = _conversationId;
    final isNew = id == null;
    if (isNew) {
      final created = await _history.create(
        title: titleFrom(userText),
        lead: lead,
      );
      if (created is! ApiSuccess<int>) return;
      id = created.data;
      // Do NOT set _conversationId yet — wait until messages are written.
      // If appendMessage fails the conversation row is orphaned, so delete it.
    } else {
      await _history.saveLead(conversationId: id, lead: lead);
    }
    final userOk = await _history.appendMessage(
      conversationId: id,
      role: SalesRole.user,
      text: userText,
    );
    final agentOk = await _history.appendMessage(
      conversationId: id,
      role: SalesRole.agent,
      text: agentText,
    );
    if (isNew) {
      if (userOk is ApiSuccess && agentOk is ApiSuccess) {
        _conversationId = id;
      } else {
        await _history.delete(id);
      }
    }
  }

  /// Conversation title = the first utterance, whitespace-collapsed and
  /// capped at 42 Unicode code points (public for tests).
  static String titleFrom(String utterance) {
    final clean = utterance.trim().replaceAll(RegExp(r'\s+'), ' ');
    // Use Runes (code points) not .length (UTF-16 code units) to avoid
    // splitting a surrogate pair mid-emoji or mid-Arabic glyph.
    final runes = clean.runes;
    if (runes.length <= 42) return clean;
    return '${String.fromCharCodes(runes.take(41))}…';
  }

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
    // Skip the API call when the query hasn't changed — avoids burning a
    // Serper credit on every reply when the lead criteria are the same.
    if (query == _lastSearchQuery) return;
    _lastSearchQuery = query;
    final result = await _search(query, hl: _locale);
    if (isClosed) return;
    result.when(
      success: (listings) {
        final current = state;
        if (current is SalesAgentChat) {
          emit(
            SalesAgentChat(
              current.turns,
              lead: current.lead,
              listings: listings,
            ),
          );
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

import 'package:dwelleo_app/core/errors/api_result.dart';
import 'package:dwelleo_app/core/errors/failure.dart';
import 'package:dwelleo_app/features/ai_sales_agent/data/models/sales_reply_model.dart';
import 'package:dwelleo_app/features/ai_sales_agent/domain/entities/chat_history.dart';
import 'package:dwelleo_app/features/ai_sales_agent/domain/entities/listing_result.dart';
import 'package:dwelleo_app/features/ai_sales_agent/domain/entities/sales_models.dart';
import 'package:dwelleo_app/features/ai_sales_agent/domain/repositories/listing_search_repository.dart';
import 'package:dwelleo_app/features/ai_sales_agent/domain/repositories/sales_agent_repository.dart';
import 'package:dwelleo_app/features/ai_sales_agent/domain/repositories/sales_chat_repository.dart';
import 'package:dwelleo_app/features/ai_sales_agent/domain/usecases/chat_history.dart';
import 'package:dwelleo_app/features/ai_sales_agent/domain/usecases/search_listings.dart';
import 'package:dwelleo_app/features/ai_sales_agent/domain/usecases/send_sales_message.dart';
import 'package:dwelleo_app/features/ai_sales_agent/presentation/cubit/sales_agent_cubit.dart';
import 'package:dwelleo_app/features/ai_sales_agent/presentation/cubit/sales_agent_state.dart';
import 'package:flutter_test/flutter_test.dart';

// SearchListings.isConfigured is false in tests (no --dart-define), so this
// stub is never called — it exists only to satisfy the constructor signature.
SearchListings _noopSearch() => SearchListings(const _FakeListingRepo());

void main() {
  group('SalesReplyModel', () {
    test('parses clean JSON output with an Arabic lead sheet', () {
      final reply = SalesReplyModel.fromModelText(
        '{"reply":"أهلًا! ميزانيتك ممتازة.","lead":{"budget":"٢ مليون ريال","intent":"شراء","timeline":null,"eligibility":null,"preferences":"فيلا في الرياض"}}',
      );
      expect(reply.text, 'أهلًا! ميزانيتك ممتازة.');
      expect(reply.lead.budget, '٢ مليون ريال');
      expect(reply.lead.timeline, isNull);
      expect(reply.lead.preferences, 'فيلا في الرياض');
    });

    test('tolerates markdown-fenced JSON', () {
      final reply = SalesReplyModel.fromModelText(
        '```json\n{"reply":"Great budget!","lead":{"budget":"2M SAR","intent":null,"timeline":null,"eligibility":null,"preferences":null}}\n```',
      );
      expect(reply.text, 'Great budget!');
      expect(reply.lead.budget, '2M SAR');
    });

    test('falls back to prose when the model ignores the JSON contract', () {
      final reply = SalesReplyModel.fromModelText(
        'Welcome! How can I help you today?',
      );
      expect(reply.text, 'Welcome! How can I help you today?');
      expect(reply.lead.hasAny, isFalse);
    });

    test('"null" strings and empties normalize to null', () {
      final reply = SalesReplyModel.fromModelText(
        '{"reply":"ok","lead":{"budget":"null","intent":"","timeline":" ","eligibility":null,"preferences":"villa"}}',
      );
      expect(reply.lead.budget, isNull);
      expect(reply.lead.intent, isNull);
      expect(reply.lead.timeline, isNull);
      expect(reply.lead.preferences, 'villa');
    });
  });

  test('LeadProfile.merge keeps old values and prefers new non-empty ones', () {
    const first = LeadProfile(budget: '2M SAR', intent: 'buy');
    const second = LeadProfile(timeline: '3 months', budget: '2.5M SAR');
    final merged = first.merge(second);
    expect(merged.budget, '2.5M SAR');
    expect(merged.intent, 'buy');
    expect(merged.timeline, '3 months');
    expect(merged.hasAny, isTrue);
  });

  group('SalesAgentCubit', () {
    test('submit resolves a turn and accumulates the lead sheet', () async {
      final repo = _FakeRepo();
      final cubit = SalesAgentCubit(
        SendSalesMessage(repo),
        _noopSearch(),
        ChatHistory(_MemChatRepo()),
      );

      await cubit.submit('I have 2M SAR for a villa');
      var chat = cubit.state as SalesAgentChat;
      expect(chat.turns.single.reply, isNotNull);
      expect(chat.lead.budget, '2M SAR');

      await cubit.submit('within 3 months');
      chat = cubit.state as SalesAgentChat;
      expect(chat.turns.length, 2);
      expect(chat.lead.budget, '2M SAR', reason: 'older value persists');
      expect(chat.lead.timeline, '3 months');
      // History sent to the model contains only resolved exchanges.
      expect(repo.lastHistory, hasLength(2));
      await cubit.close();
    });

    test(
      'persists the conversation: create once, then append + save lead',
      () async {
        final store = _MemChatRepo();
        final cubit = SalesAgentCubit(
          SendSalesMessage(_FakeRepo()),
          _noopSearch(),
          ChatHistory(store),
        );

        await cubit.submit('I have 2M SAR for a villa');
        expect(store.createCalls, 1);
        expect(store.messages[1], hasLength(2), reason: 'user + agent rows');
        expect(store.messages[1]!.first.$1, SalesRole.user);

        await cubit.submit('within 3 months');
        expect(store.createCalls, 1, reason: 'same conversation row reused');
        expect(store.messages[1], hasLength(4));
        expect(store.leads[1]?.timeline, '3 months');
        expect(
          store.titles[1],
          'I have 2M SAR for a villa',
          reason: 'title = first utterance',
        );
        await cubit.close();
      },
    );

    test('long first utterance is truncated into the title', () {
      final title = SalesAgentCubit.titleFrom(
        'I am looking for a very spacious luxury villa with a big garden in north Riyadh',
      );
      expect(title.length, 42);
      expect(title.endsWith('…'), isTrue);
    });

    test('failed turns are NOT persisted', () async {
      final store = _MemChatRepo();
      final cubit = SalesAgentCubit(
        SendSalesMessage(_FakeRepo(failFirst: true)),
        _noopSearch(),
        ChatHistory(store),
      );
      await cubit.submit('hello');
      expect(store.createCalls, 0);
      await cubit.close();
    });

    test('openConversation restores turns and lead from the store', () async {
      final store = _MemChatRepo();
      final seed = SalesAgentCubit(
        SendSalesMessage(_FakeRepo()),
        _noopSearch(),
        ChatHistory(store),
      );
      await seed.submit('I have 2M SAR for a villa');
      await seed.close();

      final cubit = SalesAgentCubit(
        SendSalesMessage(_FakeRepo()),
        _noopSearch(),
        ChatHistory(store),
      );
      await cubit.openConversation(1);
      final chat = cubit.state as SalesAgentChat;
      expect(chat.turns.single.utterance, 'I have 2M SAR for a villa');
      expect(chat.turns.single.reply?.text, 'Reply #1');
      expect(chat.lead.budget, '2M SAR');
      await cubit.close();
    });

    test('deleting the OPEN conversation resets to welcome', () async {
      final store = _MemChatRepo();
      final cubit = SalesAgentCubit(
        SendSalesMessage(_FakeRepo()),
        _noopSearch(),
        ChatHistory(store),
      );
      await cubit.submit('I have 2M SAR for a villa');
      await cubit.deleteConversation(1);
      expect(cubit.state, isA<SalesAgentIdle>());
      expect(store.titles, isEmpty);
      await cubit.close();
    });

    test('failure keeps the turn and retry() recovers', () async {
      final repo = _FakeRepo(failFirst: true);
      final cubit = SalesAgentCubit(
        SendSalesMessage(repo),
        _noopSearch(),
        ChatHistory(_MemChatRepo()),
      );
      await cubit.submit('hello');
      var chat = cubit.state as SalesAgentChat;
      expect(chat.turns.single.failure, isA<ServerFailure>());

      await cubit.retry();
      chat = cubit.state as SalesAgentChat;
      expect(chat.turns.single.failure, isNull);
      expect(chat.turns.single.reply, isNotNull);
      await cubit.close();
    });

    test('reset returns to the welcome state and clears the lead', () async {
      final cubit = SalesAgentCubit(
        SendSalesMessage(_FakeRepo()),
        _noopSearch(),
        ChatHistory(_MemChatRepo()),
      );
      await cubit.submit('I have 2M SAR for a villa');
      cubit.reset();
      expect(cubit.state, isA<SalesAgentIdle>());
      await cubit.close();
    });

    test('blank input is ignored', () async {
      final cubit = SalesAgentCubit(
        SendSalesMessage(_FakeRepo()),
        _noopSearch(),
        ChatHistory(_MemChatRepo()),
      );
      await cubit.submit('   ');
      expect(cubit.state, isA<SalesAgentIdle>());
      await cubit.close();
    });
  });
}

class _FakeListingRepo implements ListingSearchRepository {
  const _FakeListingRepo();

  @override
  Future<ApiResult<List<ListingResult>>> search(
    String query, {
    String hl = '',
  }) async => const ApiSuccess([]);
}

/// In-memory chat store — verifies persistence behavior without SQLite.
class _MemChatRepo implements SalesChatRepository {
  int createCalls = 0;
  int _nextId = 0;
  final titles = <int, String>{};
  final leads = <int, LeadProfile>{};
  final messages = <int, List<(SalesRole, String)>>{};

  @override
  Future<ApiResult<List<ConversationSummary>>> conversations() async =>
      ApiSuccess([
        for (final e in titles.entries)
          ConversationSummary(
            id: e.key,
            title: e.value,
            updatedAt: DateTime(2026, 7, 20),
          ),
      ]);

  @override
  Future<ApiResult<ChatSnapshot>> load(int conversationId) async {
    final rows = messages[conversationId] ?? const [];
    final turns = <SalesTurn>[];
    String? pending;
    for (final (role, text) in rows) {
      if (role == SalesRole.user) {
        pending = text;
      } else if (pending != null) {
        turns.add(
          SalesTurn(
            utterance: pending,
            reply: SalesReply(text: text),
          ),
        );
        pending = null;
      }
    }
    return ApiSuccess(
      ChatSnapshot(
        turns: turns,
        lead: leads[conversationId] ?? LeadProfile.empty,
      ),
    );
  }

  @override
  Future<ApiResult<int>> create({
    required String title,
    required LeadProfile lead,
  }) async {
    createCalls++;
    final id = ++_nextId;
    titles[id] = title;
    leads[id] = lead;
    messages[id] = [];
    return ApiSuccess(id);
  }

  @override
  Future<ApiResult<void>> appendMessage({
    required int conversationId,
    required SalesRole role,
    required String text,
  }) async {
    messages[conversationId]?.add((role, text));
    return const ApiSuccess(null);
  }

  @override
  Future<ApiResult<void>> saveLead({
    required int conversationId,
    required LeadProfile lead,
  }) async {
    leads[conversationId] = lead;
    return const ApiSuccess(null);
  }

  @override
  Future<ApiResult<void>> delete(int conversationId) async {
    titles.remove(conversationId);
    leads.remove(conversationId);
    messages.remove(conversationId);
    return const ApiSuccess(null);
  }
}

class _FakeRepo implements SalesAgentRepository {
  final bool failFirst;
  int calls = 0;
  List<SalesMessage> lastHistory = const [];

  _FakeRepo({this.failFirst = false});

  @override
  Future<ApiResult<SalesReply>> send({
    required List<SalesMessage> history,
    required String message,
    String? buyerContext,
  }) async {
    calls++;
    lastHistory = history;
    if (failFirst && calls == 1) {
      return const ApiError(ServerFailure('quota', statusCode: 429));
    }
    return ApiSuccess(
      SalesReply(
        text: 'Reply #$calls',
        lead: message.contains('2M')
            ? const LeadProfile(budget: '2M SAR', intent: 'buy')
            : const LeadProfile(timeline: '3 months'),
      ),
    );
  }
}

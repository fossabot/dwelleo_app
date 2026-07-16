import 'package:dwelleo_app/core/errors/api_result.dart';
import 'package:dwelleo_app/core/errors/failure.dart';
import 'package:dwelleo_app/features/ai_sales_agent/data/models/sales_reply_model.dart';
import 'package:dwelleo_app/features/ai_sales_agent/domain/entities/sales_models.dart';
import 'package:dwelleo_app/features/ai_sales_agent/domain/repositories/sales_agent_repository.dart';
import 'package:dwelleo_app/features/ai_sales_agent/domain/usecases/send_sales_message.dart';
import 'package:dwelleo_app/features/ai_sales_agent/presentation/cubit/sales_agent_cubit.dart';
import 'package:dwelleo_app/features/ai_sales_agent/presentation/cubit/sales_agent_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalesReplyModel', () {
    test('parses the Gemini envelope with clean JSON output', () {
      final reply = SalesReplyModel.fromEnvelope({
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text':
                      '{"reply":"أهلًا! ميزانيتك ممتازة.","lead":{"budget":"٢ مليون ريال","intent":"شراء","timeline":null,"eligibility":null,"preferences":"فيلا في الرياض"}}',
                },
              ],
            },
            'finishReason': 'STOP',
          },
        ],
      });
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
      final cubit = SalesAgentCubit(SendSalesMessage(repo));

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

    test('failure keeps the turn and retry() recovers', () async {
      final repo = _FakeRepo(failFirst: true);
      final cubit = SalesAgentCubit(SendSalesMessage(repo));
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
      final cubit = SalesAgentCubit(SendSalesMessage(_FakeRepo()));
      await cubit.submit('I have 2M SAR for a villa');
      cubit.reset();
      expect(cubit.state, isA<SalesAgentIdle>());
      await cubit.close();
    });

    test('blank input is ignored', () async {
      final cubit = SalesAgentCubit(SendSalesMessage(_FakeRepo()));
      await cubit.submit('   ');
      expect(cubit.state, isA<SalesAgentIdle>());
      await cubit.close();
    });
  });
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

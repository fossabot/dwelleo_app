import 'package:flutter_bloc/flutter_bloc.dart';

// Provides the ApiResult.when extension used below.
import '../../../../core/errors/api_result.dart';
import '../../../properties/domain/usecases/search_properties.dart';
import '../../domain/entities/ai_search_models.dart';
import '../../domain/usecases/interpret_ai_query.dart';
import 'ai_search_state.dart';

/// Drives the AI Search conversation. Depends ONLY on use cases:
/// interpret (on-device NLU over verified filters) → live `/properties`
/// search. Voice input is handled in the widget layer (SpeechService) and
/// arrives here as plain text — the cubit is transport-agnostic, so the
/// PENDING `/user/ai/*` remote interpreter can slot in behind
/// [InterpretAiQuery] later without touching this class.
class AiSearchCubit extends Cubit<AiSearchState> {
  final InterpretAiQuery _interpret;
  final SearchProperties _search;

  AiSearchCubit(this._interpret, this._search) : super(const AiSearchIdle());

  static const _previewSize = 3;

  List<AiSearchTurn> get _turns => switch (state) {
    AiSearchChat(:final turns) => turns,
    AiSearchIdle() => const [],
  };

  Future<void> submit(String raw) async {
    final utterance = raw.trim();
    if (utterance.isEmpty) return;
    // Ignore re-entry while the last turn is still resolving.
    final current = _turns;
    if (current.isNotEmpty && current.last.loading) return;

    emit(
      AiSearchChat(
        List.unmodifiable([
          ...current,
          AiSearchTurn(utterance: utterance, loading: true),
        ]),
      ),
    );

    final interpretation = await _interpret(utterance);
    if (isClosed) return;

    if (!interpretation.hasSignal) {
      _replaceLast(AiSearchTurn(utterance: utterance, unrecognized: true));
      return;
    }

    final query = interpretation.toQuery();
    final result = await _search(query);
    if (isClosed) return;

    result.when(
      success: (page) => _replaceLast(
        AiSearchTurn(
          utterance: utterance,
          answer: AiSearchAnswer(
            interpretation: interpretation,
            query: query,
            total: page.pageInfo?.total ?? page.properties.length,
            preview: page.properties.take(_previewSize).toList(growable: false),
          ),
        ),
      ),
      error: (failure) =>
          _replaceLast(AiSearchTurn(utterance: utterance, failure: failure)),
    );
  }

  /// Re-runs the last failed turn (e.g. after connectivity returns).
  Future<void> retry() async {
    final current = _turns;
    if (current.isEmpty || current.last.failure == null) return;
    final utterance = current.last.utterance;
    emit(AiSearchChat(List.unmodifiable(current.sublist(0, current.length - 1))));
    await submit(utterance);
  }

  /// Back to the welcome view (new conversation).
  void reset() => emit(const AiSearchIdle());

  void _replaceLast(AiSearchTurn turn) {
    final current = _turns;
    if (current.isEmpty) return;
    emit(
      AiSearchChat(
        List.unmodifiable([...current.sublist(0, current.length - 1), turn]),
      ),
    );
  }
}

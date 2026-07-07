import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

// Provides the ApiResult.when extension used below.
import '../../../../core/errors/api_result.dart';
import '../../../../core/errors/failure.dart';
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

    await _resolve(utterance, interpretation);
  }

  /// The site's "Are you looking to rent or buy?" follow-up: re-runs the
  /// last answer's interpretation with an explicit listing type, appended
  /// as a new user turn ([label] is the localized chip the user tapped).
  Future<void> submitRefined({
    required String label,
    required String listingType,
  }) async {
    final current = _turns;
    if (current.isEmpty || current.last.loading) return;
    final answer = current.last.answer;
    if (answer == null) return;

    emit(
      AiSearchChat(
        List.unmodifiable([
          ...current,
          AiSearchTurn(utterance: label, loading: true),
        ]),
      ),
    );

    final b = answer.interpretation;
    await _resolve(
      label,
      AiInterpretation(
        listingType: listingType,
        propertyType: b.propertyType,
        city: b.city,
        minBedrooms: b.minBedrooms,
        minBathrooms: b.minBathrooms,
        minPrice: b.minPrice,
        maxPrice: b.maxPrice,
        furnishingStatus: b.furnishingStatus,
      ),
    );
  }

  static const _searchTimeout = Duration(seconds: 15);

  Future<void> _resolve(
    String utterance,
    AiInterpretation interpretation,
  ) async {
    final query = interpretation.toQuery();
    ApiResult result;
    try {
      result = await _search(query).timeout(_searchTimeout);
    } on TimeoutException {
      result = const ApiError(NetworkFailure('Request timed out'));
    }
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
      error: (failure) => _replaceLast(
        AiSearchTurn(
          utterance: utterance,
          failure: failure,
          // Preserved so retry() can re-run the exact filters instead of
          // re-interpreting the utterance (which loses all filters when the
          // utterance is a chip label like "Rent").
          retryInterpretation: interpretation,
        ),
      ),
    );
  }

  /// Re-runs the last failed turn (e.g. after connectivity returns).
  Future<void> retry() async {
    final current = _turns;
    if (current.isEmpty || current.last.failure == null) return;
    final failed = current.last;
    final base = current.sublist(0, current.length - 1);
    final retryInterp = failed.retryInterpretation;
    if (retryInterp != null) {
      // Re-run with the exact same filters (avoids re-interpreting chip labels
      // from submitRefined which would lose city/bedroom/price filters).
      emit(
        AiSearchChat(
          List.unmodifiable([
            ...base,
            AiSearchTurn(utterance: failed.utterance, loading: true),
          ]),
        ),
      );
      await _resolve(failed.utterance, retryInterp);
    } else {
      emit(AiSearchChat(List.unmodifiable(base)));
      await submit(failed.utterance);
    }
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

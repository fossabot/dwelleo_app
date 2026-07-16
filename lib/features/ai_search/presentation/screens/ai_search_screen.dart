import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/failure_l10n.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/speech/speech_service.dart';
import '../../../../core/speech/tts_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_utils.dart';
import '../../../../core/utils/dwelleo_images.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/chat_bubbles.dart';
import '../../../../core/widgets/dwelleo_app_bar.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/app_localizations_ar.dart';
import '../../../../l10n/app_localizations_en.dart';
import '../../../properties/domain/entities/property.dart';
import '../../domain/entities/ai_search_models.dart';
import '../cubit/ai_search_cubit.dart';
import '../cubit/ai_search_state.dart';

// Module-level singletons — avoids allocating new l10n instances on every
// widget rebuild or state transition.
final _arL10n = AppLocalizationsAr();
final _enL10n = AppLocalizationsEn();

/// Conversation-language l10n: app locale takes precedence; falls back to
/// utterance-script detection so typing Arabic in EN mode also answers in AR.
AppLocalizations _replyL10nFor(String utterance, {bool appIsArabic = false}) =>
    (appIsArabic || hasArabic(utterance)) ? _arL10n : _enL10n;

/// The agent's conversational sentence for a resolved turn — shown in the
/// black bubble AND spoken aloud. Null while loading.
String? _sentenceFor(AiSearchTurn turn, AppLocalizations replyL10n) {
  if (turn.loading) return null;
  if (turn.failure != null) return turn.failure!.localized(replyL10n);
  if (turn.unrecognized) return replyL10n.aiNoSignal;
  final answer = turn.answer!;
  final base = answer.total > 0
      ? replyL10n.aiReplyFound(Formatters.count(answer.total))
      : replyL10n.aiReplyNone;
  // Site parity: when listing intent is missing, the agent asks
  // "Are you looking to rent or buy?" (quick chips answer it).
  final ask = answer.total > 0 && answer.interpretation.listingType == null;
  return ask ? '$base\n${replyL10n.aiAskListing}' : base;
}

/// AI Search — the site's `/ai-voice-search` experience as a native chat:
/// welcome + the six live-site suggestions, then a conversation where each
/// utterance (typed or spoken) is interpreted on-device onto VERIFIED
/// `/properties` filters and answered with live results — spoken back by
/// the agent (TTS) in the user's language, like the website.
class AiSearchScreen extends StatefulWidget {
  const AiSearchScreen({super.key});

  @override
  State<AiSearchScreen> createState() => _AiSearchScreenState();
}

class _AiSearchScreenState extends State<AiSearchScreen> {
  late final AiSearchCubit _cubit;
  late final TextEditingController _input;
  late final ScrollController _scroll;
  final TtsService _tts = sl<TtsService>();

  /// Number of resolved turns already spoken (avoids re-speaking on rebuilds).
  int _spoken = 0;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _cubit = sl<AiSearchCubit>();
    _input = TextEditingController();
    _scroll = ScrollController();
  }

  @override
  void dispose() {
    _tts.stop();
    _input.dispose();
    _scroll.dispose();
    _cubit.close();
    super.dispose();
  }

  /// Speaks the newest resolved turn in the user's language (site parity:
  /// the agent answers with its voice for BOTH typed and spoken input).
  void _maybeSpeak(AiSearchState state, BuildContext context) {
    switch (state) {
      case AiSearchIdle():
        _spoken = 0;
        _tts.stop();
      case AiSearchChat(:final turns):
        final resolved = turns.where((t) => !t.loading).length;
        if (resolved <= _spoken || turns.isEmpty || turns.last.loading) {
          return;
        }
        if (_muted) return;
        _spoken = resolved;
        final turn = turns.last;
        final appIsArabic =
            Localizations.localeOf(context).languageCode == 'ar';
        final useArabic = appIsArabic || hasArabic(turn.utterance);
        final text = _sentenceFor(
          turn,
          _replyL10nFor(turn.utterance, appIsArabic: appIsArabic),
        );
        if (text != null) {
          _tts.speak(text, arabic: useArabic);
        }
    }
  }

  void _send([String? text]) {
    final value = (text ?? _input.text).trim();
    if (value.isEmpty) return;
    _input.clear();
    _cubit.submit(value);
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: DwelleoAppBar(
        actions: [
          IconButton(
            tooltip: l10n.aiVoiceReplies,
            onPressed: () => setState(() {
              _muted = !_muted;
              if (_muted) _tts.stop();
            }),
            icon: Icon(
              _muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            ),
          ),
          BlocBuilder<AiSearchCubit, AiSearchState>(
            bloc: _cubit,
            builder: (context, state) => switch (state) {
              AiSearchChat() => IconButton(
                tooltip: l10n.reset,
                onPressed: _cubit.reset,
                icon: const Icon(Icons.restart_alt_rounded),
              ),
              AiSearchIdle() => const SizedBox.shrink(),
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocConsumer<AiSearchCubit, AiSearchState>(
                bloc: _cubit,
                listener: (context, state) {
                  _scrollToEnd();
                  _maybeSpeak(state, context);
                },
                builder: (context, state) => switch (state) {
                  AiSearchIdle() => _WelcomeView(onAsk: _send),
                  AiSearchChat(:final turns) => _ThreadView(
                    turns: turns,
                    controller: _scroll,
                    onRetry: _cubit.retry,
                    onAsk: _send,
                    onRefine: (label, listingType) => _cubit.submitRefined(
                      label: label,
                      listingType: listingType,
                    ),
                  ),
                },
              ),
            ),
            _Composer(input: _input, onSend: _send),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- welcome

class _WelcomeView extends StatelessWidget {
  final ValueChanged<String> onAsk;

  const _WelcomeView({required this.onAsk});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final accent = AppColors.accentFor(brightness);

    final suggestions = <String>[
      l10n.aiSuggestion1,
      l10n.aiSuggestion2,
      l10n.aiSuggestion3,
      l10n.aiSuggestion4,
      l10n.aiSuggestion5,
      l10n.aiSuggestion6,
    ];
    const icons = <IconData>[
      Icons.apartment_rounded,
      Icons.payments_rounded,
      Icons.pool_rounded,
      Icons.business_center_rounded,
      Icons.diamond_rounded,
      Icons.chair_rounded,
    ];

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 24, 16),
      children: [
        Center(
          child: PulseGlow(
            glowColor: accent,
            strength: 1.2,
            child: Container(
              width: 88,
              height: 88,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: brightness == Brightness.dark
                      ? [
                          AppColors.primary.withValues(alpha: 0.75),
                          AppColors.primary,
                        ]
                      : [AppColors.accentLight, AppColors.accent],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: SvgPicture.asset(
                AppSvg.aiVoice,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
                errorBuilder: (ctx, error, stack) => const Icon(
                  Icons.auto_awesome,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        FadeSlideIn(
          child: Column(
            children: [
              Text(
                l10n.aiWelcomeTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.aiWelcomeSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.aiWelcomeBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, size: 17, color: accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.aiWelcomeTip,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 16, color: accent),
            const SizedBox(width: 7),
            Text(
              l10n.aiTryAsking,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < suggestions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: FadeSlideIn(
              delay: Duration(milliseconds: 40 * i),
              child: _SuggestionTile(
                icon: icons[i],
                label: suggestions[i],
                onTap: () => onAsk(suggestions[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 11, 10, 11),
          child: Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.north_east_rounded,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- thread

class _ThreadView extends StatelessWidget {
  final List<AiSearchTurn> turns;
  final ScrollController controller;
  final VoidCallback onRetry;
  final ValueChanged<String> onAsk;
  final void Function(String label, String listingType) onRefine;

  const _ThreadView({
    required this.turns,
    required this.controller,
    required this.onRetry,
    required this.onAsk,
    required this.onRefine,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 10),
      itemCount: turns.length,
      itemBuilder: (context, index) {
        final turn = turns[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UserChatBubble(text: turn.utterance),
              const SizedBox(height: 10),
              _AssistantEntry(
                turn: turn,
                onRetry: onRetry,
                onAsk: onAsk,
                onRefine: onRefine,
              ),
            ],
          ),
        );
      },
    );
  }
}

// User/agent bubbles moved to core/widgets/chat_bubbles.dart — they are now
// shared with the AI Sales Agent feature.

class _AssistantEntry extends StatelessWidget {
  final AiSearchTurn turn;
  final VoidCallback onRetry;
  final ValueChanged<String> onAsk;
  final void Function(String label, String listingType) onRefine;

  const _AssistantEntry({
    required this.turn,
    required this.onRetry,
    required this.onAsk,
    required this.onRefine,
  });

  @override
  Widget build(BuildContext context) {
    final appL10n = AppLocalizations.of(context);
    final appIsArabic = Localizations.localeOf(context).languageCode == 'ar';
    final replyL10n = _replyL10nFor(turn.utterance, appIsArabic: appIsArabic);

    final answer = turn.answer;
    final askListing =
        answer != null &&
        answer.total > 0 &&
        answer.interpretation.listingType == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgentChatBubble(
          child: turn.loading
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentFor(
                          Theme.of(context).brightness,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(appL10n.aiThinking),
                  ],
                )
              : Text(_sentenceFor(turn, replyL10n) ?? ''),
        ),
        if (turn.failure != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, top: 2),
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(replyL10n.retry),
            ),
          ),
        if (turn.unrecognized)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in [
                  replyL10n.aiSuggestion1,
                  replyL10n.aiSuggestion2,
                ])
                  ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 11.5)),
                    onPressed: () => onAsk(s),
                  ),
              ],
            ),
          ),
        if (askListing)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 8),
            child: Wrap(
              spacing: 8,
              children: [
                for (final (label, key) in [
                  (replyL10n.buy, 'for-sale'),
                  (replyL10n.rent, 'for-rent'),
                ])
                  ActionChip(
                    avatar: Icon(
                      key == 'for-sale'
                          ? Icons.sell_outlined
                          : Icons.key_outlined,
                      size: 15,
                    ),
                    label: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () => onRefine(label, key),
                  ),
              ],
            ),
          ),
        if (answer != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 10),
            child: _ResultsCard(answer: answer, replyL10n: replyL10n),
          ),
      ],
    );
  }
}

/// Results block under the agent bubble: recognized-filter chips, live
/// count, preview tiles and the "view all" handoff.
class _ResultsCard extends StatelessWidget {
  final AiSearchAnswer answer;
  final AppLocalizations replyL10n;

  const _ResultsCard({required this.answer, required this.replyL10n});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(
                replyL10n.aiSearch,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _AnswerBody(answer: answer),
        ],
      ),
    );
  }
}

class _AnswerBody extends StatelessWidget {
  final AiSearchAnswer answer;

  const _AnswerBody({required this.answer});

  List<String> _chips(AppLocalizations l10n) {
    final i = answer.interpretation;
    return [
      if (i.listingType == 'for-sale')
        l10n.forSale
      else if (i.listingType == 'for-rent')
        l10n.forRent,
      if (i.propertyType != null) i.propertyType!.name,
      if (i.city != null) i.city!.name,
      if (i.minBedrooms != null) '${i.minBedrooms}+ ${l10n.beds}',
      if (i.minBathrooms != null) '${i.minBathrooms}+ ${l10n.baths}',
      if (i.minPrice != null) l10n.aiFromPrice(Formatters.price(i.minPrice)),
      if (i.maxPrice != null) l10n.aiUpToPrice(Formatters.price(i.maxPrice)),
      if (i.furnishingStatus == 'unfurnished') l10n.furnishingUnfurnished,
      if (i.furnishingStatus == 'semi-furnished') l10n.furnishingSemi,
      if (i.furnishingStatus == 'partially_furnished') l10n.furnishingPartially,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);
    final chips = _chips(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.aiUnderstoodIntro,
          style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final chip in chips)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  chip,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          l10n.resultsCount(Formatters.count(answer.total)),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        if (answer.preview.isNotEmpty) ...[
          const SizedBox(height: 10),
          for (final property in answer.preview)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ResultTile(property: property),
            ),
        ],
        if (answer.total > 0)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  context.push(RoutePaths.propertySearch, extra: answer.query),
              icon: const Icon(Icons.grid_view_rounded, size: 17),
              label: Text(
                l10n.aiViewAllResults(Formatters.count(answer.total)),
              ),
            ),
          ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  final Property property;

  const _ResultTile({required this.property});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final thumb = property.coverImage?.displayThumb;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => context.push(RoutePaths.propertyDetailPath(property.slug)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: thumb == null
                      ? ColoredBox(
                          color: scheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.home_work_outlined,
                            size: 22,
                            color: scheme.onSurfaceVariant,
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: DwelleoImages.optimized(thumb, width: 640),
                          httpHeaders: DwelleoImages.headers,
                          memCacheWidth: 168,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.price(property.price),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (property.bedrooms != null)
                          '${property.bedrooms} ${l10n.beds}',
                        if (property.bathrooms != null)
                          '${property.bathrooms} ${l10n.baths}',
                        if (property.areaSqm != null)
                          Formatters.area(property.areaSqm),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------------------------------------------------------------- composer

class _Composer extends StatefulWidget {
  final TextEditingController input;
  final ValueChanged<String?> onSend;

  const _Composer({required this.input, required this.onSend});

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  final SpeechService _speech = sl<SpeechService>();
  bool _listening = false;

  @override
  void dispose() {
    if (_listening) _speech.cancel();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    if (_listening) {
      await _speech.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    final ready = await _speech.ensureReady();
    if (!ready) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.aiMicUnavailable)));
      return;
    }
    final localeId = await _speech.localeIdFor(languageCode);
    if (!mounted) return;
    setState(() => _listening = true);
    await _speech.listen(
      localeId: localeId,
      onResult: (text, isFinal) {
        if (!mounted) return;
        widget.input.text = text;
        widget.input.selection = TextSelection.collapsed(offset: text.length);
        if (isFinal) {
          setState(() => _listening = false);
          if (text.trim().isNotEmpty) widget.onSend(text);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final accent = AppColors.accentFor(brightness);

    final mic = IconButton(
      tooltip: _listening ? l10n.aiListening : l10n.aiSearch,
      onPressed: _toggleMic,
      icon: Icon(
        _listening ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
        color: _listening ? accent : scheme.onSurfaceVariant,
      ),
    );

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: widget.input,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: widget.onSend,
              decoration: InputDecoration(
                hintText: _listening ? l10n.aiListening : l10n.aiComposerHint,
                isDense: true,
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                contentPadding: const EdgeInsetsDirectional.fromSTEB(
                  14,
                  10,
                  4,
                  10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: _listening
                    ? PulseGlow(glowColor: accent, strength: 0.5, child: mic)
                    : mic,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            height: 44,
            child: FilledButton(
              onPressed: () => widget.onSend(null),
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
              child: const Icon(Icons.arrow_upward_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/failure_l10n.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/speech/speech_service.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../../core/speech/tts_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/arabic_utils.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/chat_history.dart';
import '../../domain/entities/listing_result.dart';
import '../../domain/entities/sales_models.dart';
import '../../domain/usecases/send_sales_message.dart';
import '../cubit/sales_agent_cubit.dart';
import '../cubit/sales_agent_state.dart';

/// AI Sales Agent — its OWN product surface (distinct from AI Search, per
/// dwelleo.sa's taxonomy): a BITEP-qualifying sales conversation with a live
/// lead sheet, bilingual text + voice, spoken replies, and an honest
/// disclosure that this build runs on a demo AI adapter until Dwelleo's
/// production agent contract is captured.
class AiSalesAgentScreen extends StatefulWidget {
  const AiSalesAgentScreen({super.key});

  @override
  State<AiSalesAgentScreen> createState() => _AiSalesAgentScreenState();
}

class _AiSalesAgentScreenState extends State<AiSalesAgentScreen> {
  late final SalesAgentCubit _cubit;
  late final TextEditingController _input;
  late final ScrollController _scroll;
  final TtsService _tts = sl<TtsService>();

  int _spoken = 0;
  bool _muted = false;

  @override
  void initState() {
    super.initState();
    _cubit = sl<SalesAgentCubit>();
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

  void _send([String? text]) {
    final value = (text ?? _input.text).trim();
    if (value.isEmpty) return;
    _input.clear();
    _cubit.submit(value);
  }

  /// Claude-app-style history: saved conversations, reopen or delete.
  void _openHistory(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _HistorySheet(cubit: _cubit),
    );
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

  /// The agent speaks each resolved reply in its own language.
  void _maybeSpeak(SalesAgentState state) {
    switch (state) {
      case SalesAgentIdle():
        _spoken = 0;
        _tts.stop();
      case SalesAgentChat(:final turns):
        final resolved = turns.where((t) => !t.loading).length;
        if (resolved <= _spoken || turns.isEmpty || turns.last.loading) {
          return;
        }
        _spoken = resolved;
        if (_muted) return;
        final reply = turns.last.reply;
        if (reply != null && reply.text.isNotEmpty) {
          _tts.speak(reply.text, arabic: hasArabic(reply.text));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final configured = SendSalesMessage.isConfigured;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Site call-UI parity: solid modern black backdrop in dark mode.
      backgroundColor: dark ? AppColors.ink : null,
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const _PersonaAvatar(size: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${l10n.salesPersonaName} — ${l10n.aiSalesAgent}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3DBE5B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.salesOnline,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.salesHistory,
            onPressed: () => _openHistory(context),
            icon: const Icon(Icons.history_rounded),
          ),
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
          BlocBuilder<SalesAgentCubit, SalesAgentState>(
            bloc: _cubit,
            builder: (context, state) => switch (state) {
              SalesAgentChat() => IconButton(
                tooltip: l10n.reset,
                onPressed: _cubit.reset,
                icon: const Icon(Icons.restart_alt_rounded),
              ),
              SalesAgentIdle() => const SizedBox.shrink(),
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: BlocConsumer<SalesAgentCubit, SalesAgentState>(
                bloc: _cubit,
                listener: (context, state) {
                  _scrollToEnd();
                  _maybeSpeak(state);
                },
                builder: (context, state) => switch (state) {
                  SalesAgentIdle() => _WelcomeView(
                    configured: configured,
                    onAsk: _send,
                  ),
                  SalesAgentChat(:final turns, :final lead, :final listings) =>
                    Column(
                      children: [
                        if (lead.hasAny) _LeadSheet(lead: lead),
                        Expanded(
                          child: _ThreadView(
                            turns: turns,
                            controller: _scroll,
                            onRetry: _cubit.retry,
                          ),
                        ),
                        if (listings.isNotEmpty)
                          _ListingsSection(listings: listings),
                        // Site call-UI parity: Call · WhatsApp · Visit · Docs.
                        _ActionBar(onAsk: _send),
                      ],
                    ),
                },
              ),
            ),
            if (configured) _Composer(input: _input, onSend: _send),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- welcome

class _WelcomeView extends StatelessWidget {
  final bool configured;
  final ValueChanged<String> onAsk;

  const _WelcomeView({required this.configured, required this.onAsk});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    final starters = <String>[
      l10n.salesSuggestion1,
      l10n.salesSuggestion2,
      l10n.salesSuggestion3,
    ];
    const icons = <IconData>[
      Icons.payments_rounded,
      Icons.trending_up_rounded,
      Icons.description_outlined,
    ];

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(24, 20, 24, 16),
      children: [
        Center(
          child: Builder(
            builder: (context) {
              // Brand rule (like every accent in the app): LIME in dark
              // mode, PURPLE in light mode — as the ring/glow around
              // Sarah's portrait.
              final dark = Theme.of(context).brightness == Brightness.dark;
              final ring = dark ? AppColors.primary : AppColors.accent;
              return PulseGlow(
                glowColor: dark ? AppColors.primary : AppColors.accentLight,
                strength: 1.2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ring, width: 2.5),
                  ),
                  child: const _PersonaAvatar(size: 88),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),
        FadeSlideIn(
          child: Column(
            children: [
              Text(
                l10n.aiSalesAgent,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.aiBannerBody,
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
        _DisclosureCard(text: l10n.salesDisclosure),
        if (!configured) ...[
          const SizedBox(height: 10),
          _DisclosureCard(text: l10n.salesKeyMissing, warning: true),
        ] else ...[
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
          for (var i = 0; i < starters.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FadeSlideIn(
                delay: Duration(milliseconds: 40 * i),
                child: Material(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => onAsk(starters[i]),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        12,
                        11,
                        10,
                        11,
                      ),
                      child: Row(
                        children: [
                          Icon(icons[i], size: 18, color: accent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              starters[i],
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
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _DisclosureCard extends StatelessWidget {
  final String text;
  final bool warning;

  const _DisclosureCard({required this.text, this.warning = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = warning
        ? scheme.error
        : AppColors.accentFor(Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warning ? Icons.key_off_rounded : Icons.info_outline_rounded,
            size: 17,
            color: accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- lead sheet

/// Live BITEP lead sheet — fills in as the agent qualifies the buyer.
class _LeadSheet extends StatelessWidget {
  final LeadProfile lead;

  const _LeadSheet({required this.lead});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    final entries = <(String, String?)>[
      (l10n.leadBudget, lead.budget),
      (l10n.leadIntent, lead.intent),
      (l10n.leadTimeline, lead.timeline),
      (l10n.leadEligibility, lead.eligibility),
      (l10n.leadPreferences, lead.preferences),
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.badge_outlined, size: 15, color: accent),
              const SizedBox(width: 6),
              Text(
                l10n.leadProfile,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: accent,
                ),
              ),
              const Spacer(),
              // Site parity: the call UI shows a live "BITEP: n/100" badge.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'BITEP: ${lead.bitepScore}/100',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (label, value) in entries)
                if (value != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      '$label: $value',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
            ],
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- thread

class _ThreadView extends StatelessWidget {
  final List<SalesTurn> turns;
  final ScrollController controller;
  final VoidCallback onRetry;

  const _ThreadView({
    required this.turns,
    required this.controller,
    required this.onRetry,
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
              _CallBubble(
                agent: false,
                // TODO(profile): use the signed-in user's real name once the
                // session exposes the profile (his note: "customer name will
                // be added from user name").
                label: AppLocalizations.of(context).you,
                child: Text(turn.utterance),
              ),
              const SizedBox(height: 10),
              _AgentEntry(turn: turn, onRetry: onRetry),
            ],
          ),
        );
      },
    );
  }
}

class _AgentEntry extends StatelessWidget {
  final SalesTurn turn;
  final VoidCallback onRetry;

  const _AgentEntry({required this.turn, required this.onRetry});

  /// Failure copy: quota (429, observed live) and rejected-key (4xx auth)
  /// get specific guidance; everything else uses the shared mapping.
  String _failureText(Failure failure, AppLocalizations l10n) {
    if (failure is ServerFailure) {
      if (failure.statusCode == 429) return l10n.salesQuotaMessage;
      if (failure.statusCode == 400 ||
          failure.statusCode == 401 ||
          failure.statusCode == 403) {
        return l10n.salesKeyInvalid;
      }
    }
    return failure.localized(l10n);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CallBubble(
          agent: true,
          label: '${l10n.salesPersonaName} — ${l10n.aiSalesAgent}',
          child: turn.loading
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentLight,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(l10n.salesThinking),
                  ],
                )
              : Text(
                  turn.failure != null
                      ? _failureText(turn.failure!, l10n)
                      : (turn.reply?.text ?? ''),
                ),
        ),
        if (turn.failure != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, top: 2),
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(l10n.retry),
            ),
          ),
      ],
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
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    final mic = IconButton(
      tooltip: _listening ? l10n.aiListening : l10n.aiSalesAgent,
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
                hintText: _listening
                    ? l10n.aiListening
                    : l10n.salesComposerHint,
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

// ----------------------------------------------------------- listing results

class _ListingsSection extends StatelessWidget {
  final List<ListingResult> listings;
  const _ListingsSection({required this.listings});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 6),
            child: Row(
              children: [
                Icon(Icons.travel_explore_rounded, size: 14, color: accent),
                const SizedBox(width: 6),
                Text(
                  AppLocalizations.of(context).salesResults,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 106,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 10),
              itemCount: listings.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _ListingCard(result: listings[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  final ListingResult result;
  const _ListingCard({required this.result});

  /// dwelleo.sa property URLs carry the same slug the live API's
  /// `/properties/{slug}` detail endpoint expects — so property results
  /// open IN-APP. Anything else falls back to copy-link.
  static String? propertySlugOf(String link) {
    final match = RegExp(r'/properties/([^/?#]+)').firstMatch(link);
    final slug = match?.group(1);
    return (slug == null || slug.isEmpty || slug.contains(':')) ? null : slug;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final slug = propertySlugOf(result.link);

    return GestureDetector(
      onTap: () {
        if (slug != null) {
          context.push(RoutePaths.propertyDetailPath(slug));
          return;
        }
        Clipboard.setData(ClipboardData(text: result.link));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.salesLinkCopied),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: Container(
        width: 210,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.25,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 3),
            Expanded(
              child: Text(
                result.snippet,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.3,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    slug != null
                        ? l10n.salesOpensInApp
                        : (Uri.tryParse(result.link)?.host ?? result.link),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: scheme.primary),
                  ),
                ),
                Icon(
                  slug != null ? Icons.north_east_rounded : Icons.copy_rounded,
                  size: 11,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ history sheet

/// Saved conversations (Claude-app journey): newest first, tap to reopen,
/// trash to delete. Reads through the cubit so the widget stays dumb.
class _HistorySheet extends StatefulWidget {
  final SalesAgentCubit cubit;

  const _HistorySheet({required this.cubit});

  @override
  State<_HistorySheet> createState() => _HistorySheetState();
}

class _HistorySheetState extends State<_HistorySheet> {
  late Future<List<ConversationSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.cubit.conversations();
  }

  void _reload() => setState(() => _future = widget.cubit.conversations());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.salesHistory,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: FutureBuilder<List<ConversationSummary>>(
                future: _future,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final chats = snapshot.data!;
                  if (chats.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        l10n.salesHistoryEmpty,
                        style: TextStyle(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];
                      return ListTile(
                        contentPadding: EdgeInsetsDirectional.zero,
                        leading: const Icon(Icons.chat_bubble_outline_rounded),
                        title: Text(
                          chat.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatShortDate(chat.updatedAt),
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: IconButton(
                          tooltip: l10n.delete,
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                          ),
                          onPressed: () async {
                            await widget.cubit.deleteConversation(chat.id);
                            if (mounted) _reload();
                          },
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          widget.cubit.openConversation(chat.id);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- persona/call

/// Sarah's portrait. Drop the approved photo at
/// `assets/images/brand/sales_agent.png` (folder already registered in
/// pubspec) — until then a themed headset disc renders as fallback.
class _PersonaAvatar extends StatelessWidget {
  final double size;

  const _PersonaAvatar({required this.size});

  static const _asset = 'assets/images/brand/sales_agent.png';

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          _asset,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => ColoredBox(
            color: dark ? AppColors.primary : AppColors.accent,
            child: Icon(
              Icons.support_agent_rounded,
              size: size * 0.55,
              color: dark ? AppColors.ink : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// dwelleo.sa call-UI bubble: grey panel with a small-caps speaker label and
/// a colored edge bar — LIME for Sarah, PURPLE for the customer.
class _CallBubble extends StatelessWidget {
  final bool agent;
  final String label;
  final Widget child;

  const _CallBubble({
    required this.agent,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final accent = agent ? AppColors.primary : AppColors.accent;
    final panel = dark ? const Color(0xFF1C1C1C) : const Color(0xFFECEEE6);
    final bar = BorderSide(color: accent, width: 3);

    return Align(
      alignment: agent
          ? AlignmentDirectional.centerStart
          : AlignmentDirectional.centerEnd,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsetsDirectional.fromSTEB(12, 9, 12, 10),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(12),
          border: BorderDirectional(
            start: agent ? bar : BorderSide.none,
            end: agent ? BorderSide.none : bar,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: accent,
              ),
            ),
            const SizedBox(height: 4),
            DefaultTextStyle(
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

/// The call UI's action strip: Call · WhatsApp · Visit · Docs.
/// Call/WhatsApp reach Dwelleo's PUBLIC contact number (site header,
/// tel:+966567777390) via the verified ContactLauncher; Visit/Docs feed the
/// conversation — Sarah collects the visit slot / explains the paperwork
/// (the booking/leads APIs remain PENDING, so no fake submissions).
class _ActionBar extends StatelessWidget {
  final ValueChanged<String> onAsk;

  const _ActionBar({required this.onAsk});

  static const _dwelleoPhone = '+966567777390';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 6),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          _ActionButton(
            icon: Icons.call_rounded,
            label: l10n.call,
            onTap: () => ContactLauncher.call(_dwelleoPhone),
          ),
          _ActionButton(
            icon: Icons.chat_rounded,
            label: l10n.whatsapp,
            onTap: () => ContactLauncher.whatsApp(_dwelleoPhone),
          ),
          _ActionButton(
            icon: Icons.event_available_rounded,
            label: l10n.visit,
            onTap: () => onAsk(l10n.salesVisitPrompt),
          ),
          _ActionButton(
            icon: Icons.description_outlined,
            label: l10n.docs,
            onTap: () => onAsk(l10n.salesDocsPrompt),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 34,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: accent),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

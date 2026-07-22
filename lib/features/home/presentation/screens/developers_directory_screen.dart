import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/failure_l10n.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dwelleo_images.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/developer.dart';
import '../cubit/developers_directory_cubit.dart';
import '../widgets/home_choice_chip.dart';

/// Developers/Brokers directory — the site page the owner flagged as missing
/// ("developers screen have search engine but this page missing"). Live
/// lists + client-side name search; rows open the full partner profile.
class DevelopersDirectoryScreen extends StatefulWidget {
  const DevelopersDirectoryScreen({super.key});

  @override
  State<DevelopersDirectoryScreen> createState() =>
      _DevelopersDirectoryScreenState();
}

class _DevelopersDirectoryScreenState extends State<DevelopersDirectoryScreen> {
  late final DevelopersDirectoryCubit _cubit;
  final TextEditingController _search = TextEditingController();
  int _tab = 0; // 0 developers · 1 brokers · 2 agents

  @override
  void initState() {
    super.initState();
    _cubit = sl<DevelopersDirectoryCubit>()..load();
  }

  @override
  void dispose() {
    _search.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.developers)),
      body: BlocBuilder<DevelopersDirectoryCubit, DirectoryState>(
        bloc: _cubit,
        builder: (context, state) => switch (state) {
          DirectoryLoading() => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          DirectoryError(:final failure) => Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(failure.localized(l10n), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  FilledButton(onPressed: _cubit.load, child: Text(l10n.retry)),
                ],
              ),
            ),
          ),
          DirectoryLoaded(:final developers, :final brokers, :final agents) =>
            _list(context, l10n, scheme, switch (_tab) {
              1 => brokers,
              2 => agents,
              _ => developers,
            }),
        },
      ),
    );
  }

  Widget _list(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme scheme,
    List<Developer> source,
  ) {
    final query = _search.text.trim().toLowerCase();
    final partners = query.isEmpty
        ? source
        : source
              .where((d) => d.name.toLowerCase().contains(query))
              .toList(growable: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.searchDevelopersHint,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => setState(_search.clear),
                    ),
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 16, 4),
          child: Row(
            children: [
              HomeChoiceChip(
                label: l10n.developers,
                selected: _tab == 0,
                onTap: () => setState(() => _tab = 0),
              ),
              const SizedBox(width: 8),
              HomeChoiceChip(
                label: l10n.brokers,
                selected: _tab == 1,
                onTap: () => setState(() => _tab = 1),
              ),
              const SizedBox(width: 8),
              HomeChoiceChip(
                label: l10n.agents,
                selected: _tab == 2,
                onTap: () => setState(() => _tab = 2),
              ),
            ],
          ),
        ),
        Expanded(
          child: partners.isEmpty
              ? Center(
                  child: Text(
                    l10n.noResults,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: partners.length,
                  separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _PartnerRow(partner: partners[i]),
                ),
        ),
      ],
    );
  }
}

class _PartnerRow extends StatelessWidget {
  final Developer partner;

  const _PartnerRow({required this.partner});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);
    final thumb = partner.image?.displayThumb;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(
          RoutePaths.developerProfilePath(partner.id),
          extra: partner,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: thumb == null
                    ? Icon(Icons.business_rounded, size: 22, color: accent)
                    : CachedNetworkImage(
                        imageUrl: DwelleoImages.optimized(thumb, width: 320),
                        httpHeaders: DwelleoImages.headers,
                        fit: BoxFit.contain,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (partner.rating > 0) ...[
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            partner.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

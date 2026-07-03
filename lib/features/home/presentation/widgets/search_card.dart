import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/lookup/lookup_service.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/storage/recent_searches_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/search_box_cubit.dart';
import 'ai_search_pill.dart';
import 'home_choice_chip.dart';

/// The dwelleo.sa search box, mobile-adapted:
/// Buy/Rent/Off-Plan/Commercial tabs, PROPERTY TYPE picker (from /lookup),
/// the "City, area or project" field with the AI chip, the lime Search
/// button and the persisted "Latest searches" chips.
class SearchCard extends StatefulWidget {
  const SearchCard({super.key});

  @override
  State<SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<SearchCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── business logic: what each tab actually does ───────────────────────────

  void _submit(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SearchBoxCubit>();
    final query = _controller.text.trim();
    final cityId = cubit.resolveCityId(query);
    final typeId = cubit.state.propertyType?.id;
    if (query.isNotEmpty) cubit.remember(query);

    switch (cubit.state.tab) {
      case SearchTab.buy:
        context.push(
          RoutePaths.propertySearchPath(
            'for-sale',
            cityId: cityId,
            propertyTypeId: typeId,
          ),
        );
      case SearchTab.rent:
        context.push(
          RoutePaths.propertySearchPath(
            'for-rent',
            cityId: cityId,
            propertyTypeId: typeId,
          ),
        );
      case SearchTab.offPlan:
        // Off-plan = the projects browser; carry the typed city as the
        // pre-selected chip when it matches one.
        context.go(RoutePaths.explore, extra: query.isEmpty ? null : query);
      case SearchTab.commercial:
        // The commercial slug's filter params are not yet captured from
        // live traffic (@bodyPending discipline) — navigate with the
        // filters we can honor and label the list truthfully.
        context.push(
          RoutePaths.propertySearchPath(
            null,
            cityId: cityId,
            propertyTypeId: typeId,
          ),
          extra: l10n.commercial,
        );
    }
  }

  void _rerun(BuildContext context, RecentSearch recent) {
    final cubit = context.read<SearchBoxCubit>();
    final tab =
        SearchTab.values[recent.tab.clamp(0, SearchTab.values.length - 1)];
    cubit.selectTab(tab);
    PropertyTypeOption? type;
    for (final t in cubit.state.types) {
      if (t.id == recent.propertyTypeId) type = t;
    }
    cubit.selectType(type);
    _controller.text = recent.query;
    _submit(context);
  }

  Future<void> _pickType(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SearchBoxCubit>();
    final types = cubit.state.types;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(
              title: Text(l10n.all),
              onTap: () {
                cubit.selectType(null);
                Navigator.pop(sheetContext);
              },
            ),
            for (final t in types)
              ListTile(
                title: Text(t.name),
                onTap: () {
                  cubit.selectType(t);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return BlocBuilder<SearchBoxCubit, SearchBoxState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tabs — same set as the website's search box.
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final tab in SearchTab.values)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: HomeChoiceChip(
                          label: _tabLabel(l10n, tab),
                          selected: state.tab == tab,
                          onTap: () =>
                              context.read<SearchBoxCubit>().selectTab(tab),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // The bordered search box: property type + query + AI chip.
              Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.accentFor(brightness)),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _pickType(context),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          14,
                          12,
                          14,
                          12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.propertyTypeLabel.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    state.propertyType?.name ?? l10n.all,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.accentFor(brightness),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(height: 1, color: scheme.outlineVariant),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        14,
                        4,
                        8,
                        4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 20,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (value) => _submit(context),
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: l10n.searchHint,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const AiSearchPill(compact: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // The lime Search action, like the website's.
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _submit(context),
                  icon: const Icon(Icons.search_rounded, size: 19),
                  label: Text(l10n.search),
                ),
              ),
              if (state.recents.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 17,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      l10n.latestSearches,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 58,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: state.recents.length,
                    separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => _RecentChip(
                      recent: state.recents[i],
                      tabLabel: _tabLabel(
                        l10n,
                        SearchTab.values[state.recents[i].tab.clamp(
                          0,
                          SearchTab.values.length - 1,
                        )],
                      ),
                      allLabel: l10n.all,
                      onTap: () => _rerun(context, state.recents[i]),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static String _tabLabel(AppLocalizations l10n, SearchTab tab) =>
      switch (tab) {
        SearchTab.buy => l10n.buy,
        SearchTab.rent => l10n.rent,
        SearchTab.offPlan => l10n.offPlan,
        SearchTab.commercial => l10n.commercial,
      };
}

/// "Off-Plan / All — Riyadh" chip, like the website's latest searches.
class _RecentChip extends StatelessWidget {
  final RecentSearch recent;
  final String tabLabel;
  final String allLabel;
  final VoidCallback onTap;

  const _RecentChip({
    required this.recent,
    required this.tabLabel,
    required this.allLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_rounded,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$tabLabel / ${recent.propertyTypeLabel ?? allLabel}',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    recent.query,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

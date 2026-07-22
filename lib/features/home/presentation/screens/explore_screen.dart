import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/failure_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dwelleo_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/explore_cubit.dart';
import '../cubit/explore_state.dart';
import '../widgets/home_choice_chip.dart';
import '../widgets/project_card.dart';
import '../widgets/section_header.dart';

/// Explore tab — the full projects-by-cities browser (website's "Explore
/// Projects by Cities" as a screen of its own). [initialCity] pre-selects a
/// city chip when it matches one (e.g. from the search card's Off-Plan tab).
class ExploreScreen extends StatefulWidget {
  final String? initialCity;

  const ExploreScreen({super.key, this.initialCity});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final ExploreCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<ExploreCubit>();
    _cubit.load().then((_) {
      final wanted = widget.initialCity?.trim().toLowerCase();
      final state = _cubit.state;
      if (wanted == null || wanted.isEmpty || state is! ExploreLoaded) return;
      // Exact-then-prefix match; avoids short/substring names pre-selecting the
      // wrong chip (mirrors SearchBoxCubit.resolveCityId).
      String? match;
      for (final c in state.cities) {
        if (c.toLowerCase() == wanted) {
          match = c;
          break;
        }
      }
      if (match == null && wanted.length >= 2) {
        for (final c in state.cities) {
          if (c.toLowerCase().startsWith(wanted)) {
            match = c;
            break;
          }
        }
      }
      if (match != null) _cubit.selectCity(match);
    });
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: const DwelleoAppBar(),
        body: BlocBuilder<ExploreCubit, ExploreState>(
          builder: (context, state) {
            final l10n = AppLocalizations.of(context);
            return switch (state) {
              ExploreInitial() || ExploreLoading() => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              ExploreError(:final failure) => _ErrorView(
                message: failure.localized(l10n),
                onRetry: () => context.read<ExploreCubit>().load(),
              ),
              ExploreLoaded loaded => _LoadedView(loaded: loaded),
            };
          },
        ),
      ),
    );
  }
}

class _LoadedView extends StatefulWidget {
  final ExploreLoaded loaded;

  const _LoadedView({required this.loaded});

  @override
  State<_LoadedView> createState() => _LoadedViewState();
}

class _LoadedViewState extends State<_LoadedView> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loaded = widget.loaded;
    final l10n = AppLocalizations.of(context);
    final cities = loaded.cities;
    final query = _search.text.trim().toLowerCase();
    final projects = query.isEmpty
        ? loaded.filtered
        : loaded.filtered
              .where(
                (p) =>
                    p.name.toLowerCase().contains(query) ||
                    (p.cityName ?? '').toLowerCase().contains(query),
              )
              .toList(growable: false);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<ExploreCubit>().load(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SectionHeader(
              title: l10n.exploreProjectsLead,
              accent: l10n.exploreProjectsAccent,
              subtitle: l10n.exploreProjectsSubtitle,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: l10n.searchProjectsHint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(_search.clear),
                        ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: cities.length + 1,
                separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final value = i == 0 ? null : cities[i - 1];
                  final selected = loaded.selectedCity == value;
                  return HomeChoiceChip(
                    label: i == 0 ? l10n.all : cities[i - 1],
                    selected: selected,
                    onTap: () => context.read<ExploreCubit>().selectCity(value),
                  );
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          if (projects.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  l10n.noResults,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: projects.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 14),
                itemBuilder: (context, i) =>
                    ProjectCard(project: projects[i], height: 240),
              ),
            ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}

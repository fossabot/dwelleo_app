import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/localization/failure_l10n.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dwelleo_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/favorites_cubit.dart';
import '../widgets/property_card.dart';

/// Saved tab — LOCAL favorites (owner direction: liked properties persist in
/// the on-device database, deletable, and feed the Sales Agent's context).
/// Works for guests; server-side `filter[is_favorite]` sync can merge later.
class SavedPropertiesScreen extends StatefulWidget {
  const SavedPropertiesScreen({super.key});

  @override
  State<SavedPropertiesScreen> createState() => _SavedPropertiesScreenState();
}

class _SavedPropertiesScreenState extends State<SavedPropertiesScreen> {
  late final FavoritesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<FavoritesCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: const DwelleoAppBar(),
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        bloc: _cubit,
        builder: (context, state) => switch (state) {
          FavoritesLoading() => const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
          FavoritesError(:final failure) => Center(
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
          FavoritesLoaded(:final properties) =>
            properties.isEmpty
                ? _EmptySaved(l10n: l10n)
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _cubit.load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: properties.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final property = properties[index];
                        // Swipe to delete — the "ability to delete" the owner
                        // asked for, with optimistic UI + rollback.
                        return Dismissible(
                          key: ValueKey('fav-${property.id}'),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) => _cubit.remove(property.id),
                          background: Container(
                            alignment: AlignmentDirectional.centerEnd,
                            padding: const EdgeInsetsDirectional.only(end: 24),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              Icons.delete_outline_rounded,
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                          child: PropertyCard(
                            property: property,
                            onTap: () => context.push(
                              RoutePaths.propertyDetailPath(property.slug),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
        },
      ),
    );
  }
}

class _EmptySaved extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptySaved({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_outline_rounded,
              size: 44,
              color: AppColors.accentFor(Theme.of(context).brightness),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.savedEmptyTitle,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.savedEmptyBody,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  context.push(RoutePaths.propertySearchPath(null)),
              icon: const Icon(Icons.home_work_outlined, size: 18),
              label: Text(l10n.browseProperties),
            ),
          ],
        ),
      ),
    );
  }
}

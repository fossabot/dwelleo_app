import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dwelleo_app_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/property_query.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/properties_state.dart';
import '../widgets/property_card.dart';

/// Saved tab — the user's favorites via the real `filter[is_favorite]`
/// param (requires an authenticated session; AuthInterceptor attaches the
/// token). Website equivalent: user menu → Favorites.
class SavedPropertiesScreen extends StatefulWidget {
  const SavedPropertiesScreen({super.key});

  @override
  State<SavedPropertiesScreen> createState() => _SavedPropertiesScreenState();
}

class _SavedPropertiesScreenState extends State<SavedPropertiesScreen> {
  late final PropertiesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<PropertiesCubit>()
      ..load(query: const PropertyQuery(onlyFavorites: true));
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: const DwelleoAppBar(),
        body: BlocBuilder<PropertiesCubit, PropertiesState>(
          builder: (context, state) {
            return switch (state) {
              PropertiesInitial() || PropertiesLoading() => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              PropertiesError(:final message) => _ErrorView(
                message: message,
                onRetry: () => context.read<PropertiesCubit>().refresh(),
              ),
              PropertiesLoaded(:final properties) =>
                properties.isEmpty
                    ? _EmptySaved(l10n: l10n)
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () =>
                            context.read<PropertiesCubit>().refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: properties.length,
                          separatorBuilder: (ctx, i) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, i) {
                            final property = properties[i];
                            return PropertyCard(
                              property: property,
                              onTap: () => context.push(
                                RoutePaths.propertyDetailPath(property.slug),
                              ),
                            );
                          },
                        ),
                      ),
            };
          },
        ),
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
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_outline_rounded,
                size: 34,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.savedEmptyTitle,
              textAlign: TextAlign.center,
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
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () =>
                  context.push(RoutePaths.propertySearchPath(null)),
              icon: const Icon(Icons.search_rounded, size: 18),
              label: Text(l10n.browseProperties),
            ),
          ],
        ),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_query.dart';
import '../cubit/properties_cubit.dart';
import '../cubit/properties_state.dart';
import '../widgets/property_card.dart';
import '../widgets/property_filters_sheet.dart';

/// `for-sale` (Buy) or `for-rent` (Rent). Null = curated home set.
/// [cityId]/[propertyTypeId]/[developerId] are the real API filter ids;
/// [title] lets the caller pass a pre-localized heading
/// (e.g. "Apartments in Riyadh" or a developer's name).
class PropertiesListScreen extends StatefulWidget {
  final String? listingType;
  final int? cityId;
  final int? propertyTypeId;
  final int? developerId;
  final String? title;

  const PropertiesListScreen({
    super.key,
    this.listingType,
    this.cityId,
    this.propertyTypeId,
    this.developerId,
    this.title,
  });

  @override
  State<PropertiesListScreen> createState() => _PropertiesListScreenState();
}

class _PropertiesListScreenState extends State<PropertiesListScreen> {
  late final PropertiesCubit _cubit;

  @override
  void initState() {
    super.initState();
    final hasFilters =
        widget.listingType != null ||
        widget.cityId != null ||
        widget.propertyTypeId != null ||
        widget.developerId != null;
    _cubit = sl<PropertiesCubit>()
      ..load(
        query: !hasFilters
            ? null
            : PropertyQuery(
                listingType: widget.listingType,
                cityId: widget.cityId,
                propertyTypeId: widget.propertyTypeId,
                developerId: widget.developerId,
              ),
      );
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
      child: _PropertiesView(
        listingType: widget.listingType,
        title: widget.title,
      ),
    );
  }
}

class _PropertiesView extends StatelessWidget {
  final String? listingType;
  final String? title;
  const _PropertiesView({this.listingType, this.title});

  String _titleOf(AppLocalizations l10n) =>
      title ??
      switch (listingType) {
        'for-rent' => l10n.propertiesForRent,
        'for-sale' => l10n.propertiesForSale,
        _ => l10n.properties,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleOf(AppLocalizations.of(context))),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () async {
              final cubit = context.read<PropertiesCubit>();
              final base = cubit.query ?? const PropertyQuery();
              final result = await showPropertyFiltersSheet(context, base);
              if (result != null) cubit.load(query: result);
            },
          ),
        ],
      ),
      body: BlocBuilder<PropertiesCubit, PropertiesState>(
        builder: (context, state) {
          return switch (state) {
            PropertiesInitial() || PropertiesLoading() => const _Loading(),
            PropertiesError(:final message) => _ErrorView(
              message: message,
              onRetry: () => context.read<PropertiesCubit>().refresh(),
            ),
            PropertiesLoaded(:final properties) =>
              properties.isEmpty
                  ? const _EmptyView()
                  : _PropertiesGrid(
                      onRefresh: () =>
                          context.read<PropertiesCubit>().refresh(),
                      properties: properties,
                    ),
          };
        },
      ),
    );
  }
}

class _PropertiesGrid extends StatelessWidget {
  final List<Property> properties;
  final Future<void> Function() onRefresh;
  const _PropertiesGrid({required this.properties, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: properties.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 14),
        itemBuilder: (context, i) {
          final property = properties[i];
          return PropertyCard(
            property: property,
            onTap: () =>
                context.push(RoutePaths.propertyDetailPath(property.slug)),
          );
        },
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.primary));
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48, color: AppColors.textSecondary),
          SizedBox(height: 12),
          Text(
            'No properties found',
            style: TextStyle(color: AppColors.textSecondary),
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
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

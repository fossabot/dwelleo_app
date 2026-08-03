import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/dwelleo_images.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/property.dart';
import 'favorite_heart.dart';

/// Mobile-first property card with a calm hierarchy:
/// image → status → price → title → location → essential facts.
///
/// Contact, compare and share actions intentionally live on the detail screen
/// or in contextual menus instead of competing below every result.
class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;
  final double height;

  /// Retained for source compatibility during the migration. The rebuilt card
  /// no longer renders the website-style four-button action row.
  final bool showActions;

  const PropertyCard({
    super.key,
    required this.property,
    this.onTap,
    this.height = 248,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final imageUrl = property.coverImage?.displayThumb;

    return Semantics(
      button: true,
      label: '${property.title}, ${Formatters.price(property.price)}',
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: height,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl != null)
                      CachedNetworkImage(
                        imageUrl: DwelleoImages.optimized(imageUrl, width: 960),
                        httpHeaders: DwelleoImages.headers,
                        memCacheWidth: 960,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const _ImageFallback(),
                        errorWidget: (_, _, _) => const _ImageFallback(),
                      )
                    else
                      const _ImageFallback(),
                    PositionedDirectional(
                      top: AppSpacing.sm,
                      start: AppSpacing.sm,
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        children: [
                          if (property.isFeatured)
                            _Badge(
                              label: l10n.featured,
                              background: scheme.secondaryContainer,
                              foreground: scheme.onSecondaryContainer,
                            ),
                          if (property.listingType != null)
                            _Badge(
                              label: property.listingType!.isForRent
                                  ? l10n.forRent
                                  : l10n.forSale,
                              background: scheme.primaryContainer,
                              foreground: scheme.onPrimaryContainer,
                            ),
                        ],
                      ),
                    ),
                    PositionedDirectional(
                      top: AppSpacing.xs,
                      end: AppSpacing.xs,
                      child: FavoriteHeart(property: property, scrim: true),
                    ),
                    if ((property.photoCount ?? 0) > 1)
                      PositionedDirectional(
                        end: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                        child: _PhotoCount(count: property.photoCount!),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Formatters.price(property.price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      property.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (property.cityName != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          Expanded(
                            child: Text(
                              property.cityName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    _Facts(property: property),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  final Property property;

  const _Facts({required this.property});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final facts = <Widget>[
      if (property.bedrooms != null)
        _Fact(
          icon: Icons.bed_outlined,
          label: '${property.bedrooms} ${l10n.beds}',
        ),
      if (property.bathrooms != null)
        _Fact(
          icon: Icons.bathtub_outlined,
          label: '${property.bathrooms} ${l10n.baths}',
        ),
      if (property.areaSqm != null)
        _Fact(
          icon: Icons.square_foot_rounded,
          label: Formatters.area(property.areaSqm),
        ),
    ];

    if (facts.isEmpty) return const SizedBox.shrink();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.xs,
          children: facts,
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Fact({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PhotoCount extends StatelessWidget {
  final int count;

  const _PhotoCount({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.photo_library_outlined,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            '$count',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.apartment_rounded,
          size: 44,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

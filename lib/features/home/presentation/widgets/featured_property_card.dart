import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dwelleo_images.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/arrow_badge.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../properties/domain/entities/property.dart';

/// Image-first property card in the dwelleo.sa style used by the home
/// "Some Excellent Properties" rail: full-bleed photo with the price, title,
/// location and specs OVERLAID on a bottom gradient (matching the site and the
/// project cards) — not stacked in a panel below the image. The vertical list
/// keeps its own stacked [PropertyCard]; this variant is for the rail only.
class FeaturedPropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;

  const FeaturedPropertyCard({super.key, required this.property, this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final url = property.coverImage?.displayThumb;

    return Material(
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null)
              CachedNetworkImage(
                imageUrl: DwelleoImages.optimized(url, width: 1080),
                httpHeaders: DwelleoImages.headers,
                memCacheWidth: 1080,
                fit: BoxFit.cover,
                placeholder: (ctx, _) => const _ImageFallback(),
                errorWidget: (ctx, u, e) => const _ImageFallback(),
              )
            else
              const _ImageFallback(),
            // Bottom scrim so the overlaid text is readable on any photo.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.30, 1.0],
                  colors: [Colors.transparent, Color(0xE6000000)],
                ),
              ),
            ),
            // Badges: Featured (purple) + Sale/Rent (lime) top-start.
            PositionedDirectional(
              top: 12,
              start: 12,
              child: Row(
                children: [
                  if (property.isFeatured)
                    _Badge(label: l10n.featured, color: AppColors.accent),
                  if (property.isFeatured && property.listingType != null)
                    const SizedBox(width: 6),
                  if (property.listingType != null)
                    _Badge(
                      label: property.listingType!.isForRent
                          ? l10n.forRent
                          : l10n.forSale,
                      color: AppColors.accentFor(Theme.of(context).brightness),
                    ),
                ],
              ),
            ),
            // Site's ↗ open affordance.
            PositionedDirectional(
              top: 12,
              end: 12,
              child: ArrowBadge(onTap: onTap),
            ),
            // Overlaid details.
            PositionedDirectional(
              start: 14,
              end: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        AppSvg.sar,
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          Formatters.priceValue(property.price),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    property.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (property.cityName != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            property.cityName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 10),
                  _Specs(property: property),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Specs extends StatelessWidget {
  final Property property;
  const _Specs({required this.property});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        if (property.bedrooms != null)
          _Spec(svg: AppSvg.bed, label: '${property.bedrooms} ${l10n.beds}'),
        if (property.bathrooms != null)
          _Spec(svg: AppSvg.bath, label: '${property.bathrooms} ${l10n.baths}'),
        if (property.areaSqm != null)
          _Spec(svg: AppSvg.sqf, label: Formatters.area(property.areaSqm)),
      ],
    );
  }
}

class _Spec extends StatelessWidget {
  final String svg;
  final String label;
  const _Spec({required this.svg, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          svg,
          width: 15,
          height: 15,
          colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
              ? Colors.white
              : AppColors.ink,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
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
      child: Icon(
        Icons.home_outlined,
        size: 44,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}

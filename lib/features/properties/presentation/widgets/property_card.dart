import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../../core/utils/dwelleo_images.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/share_link.dart';
import '../../../../core/widgets/arrow_badge.dart';
import '../../../../core/widgets/whatsapp_icon.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/property.dart';
import '../cubit/compare_cubit.dart';
import 'favorite_heart.dart';

/// Listing card in the dwelleo.sa image-first style — full-bleed photo with
/// price, title, city and specs OVERLAID on a bottom scrim.
///
/// Owner review: "all cards of properties and projects — if they match the
/// cards at home screen it will be more modern". This now uses the same
/// treatment as the home rail and the project cards, so every surface reads
/// as one family. The favourite heart and the ↗ affordance sit in the top
/// corners, where the photo's own contrast is handled by the badge chrome.
class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;

  /// Card height (image area). The vertical list uses the default.
  final double height;

  /// Site parity: the listing cards on dwelleo.sa carry Call · WhatsApp ·
  /// Compare · Share under the photo. Rails pass false.
  final bool showActions;

  const PropertyCard({
    super.key,
    required this.property,
    this.onTap,
    this.height = 236,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!showActions) return _photo(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _photo(context),
        _ActionRow(property: property),
      ],
    );
  }

  Widget _photo(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final url = property.coverImage?.displayThumb;

    return SizedBox(
      height: height,
      child: Material(
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

              // Bottom scrim so overlaid text stays readable on any photo.
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

              // Featured (purple) + Sale/Rent (accent) badges.
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
                        color: AppColors.accentFor(
                          Theme.of(context).brightness,
                        ),
                      ),
                  ],
                ),
              ),

              // Save + open affordances.
              PositionedDirectional(
                top: 6,
                end: 8,
                child: Row(
                  children: [
                    FavoriteHeart(property: property, scrim: true),
                    const SizedBox(width: 4),
                    ArrowBadge(onTap: onTap),
                  ],
                ),
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

              // Photo-count badge (site parity), from the API's
              // `number_of_images`.
              if ((property.photoCount ?? 0) > 1)
                PositionedDirectional(
                  bottom: 12,
                  end: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0x99000000),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library_outlined,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${property.photoCount}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Call · WhatsApp · Compare · Share — the action row dwelleo.sa puts on
/// every listing card. Contact buttons only appear when the listing
/// actually publishes a phone number.
class _ActionRow extends StatelessWidget {
  final Property property;

  const _ActionRow({required this.property});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final phone = property.owner?.phone;
    final tray = sl<CompareCubit>();

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(2, 8, 2, 0),
      child: Row(
        children: [
          if (phone != null && phone.isNotEmpty) ...[
            Expanded(
              child: _ActionButton(
                icon: Icons.call_rounded,
                label: l10n.callNow,
                onTap: () => ContactLauncher.call(phone),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ActionButton(
                glyph: const WhatsAppIcon(size: 16),
                label: l10n.whatsapp,
                tint: WhatsAppIcon.brand,
                onTap: () => ContactLauncher.whatsApp(phone),
              ),
            ),
            const SizedBox(width: 8),
          ],
          BlocBuilder<CompareCubit, List<Property>>(
            bloc: tray,
            builder: (context, items) {
              final inTray = items.any((p) => p.id == property.id);
              return _IconAction(
                icon: inTray
                    ? Icons.library_add_check_rounded
                    : Icons.compare_arrows_rounded,
                active: inTray,
                tooltip: l10n.compare,
                onTap: () {
                  final wasIn = tray.contains(property.id);
                  tray.toggle(property);
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.hideCurrentSnackBar();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        wasIn ? l10n.compareRemoved : l10n.compareAdded,
                      ),
                      action: !wasIn && tray.isFull
                          ? SnackBarAction(
                              label: l10n.view,
                              onPressed: () => context.push(RoutePaths.compare),
                            )
                          : null,
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
          _IconAction(
            glyph: SvgPicture.asset(
              AppSvg.share,
              width: 17,
              height: 17,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onSurfaceVariant,
                BlendMode.srcIn,
              ),
            ),
            tooltip: l10n.share,
            onTap: () => ShareLink.shareProperty(
              slug: property.slug,
              title: property.title,
              arabic: Localizations.localeOf(context).languageCode == 'ar',
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  /// Either a Material icon OR a custom glyph (the WhatsApp brand SVG).
  final IconData? icon;
  final Widget? glyph;
  final String label;
  final Color? tint;
  final VoidCallback onTap;

  const _ActionButton({
    this.icon,
    this.glyph,
    required this.label,
    this.tint,
    required this.onTap,
  }) : assert(icon != null || glyph != null, 'need an icon or a glyph');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = tint ?? AppColors.accentFor(Theme.of(context).brightness);

    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              glyph ?? Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData? icon;
  final Widget? glyph;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  const _IconAction({
    this.icon,
    this.glyph,
    required this.tooltip,
    this.active = false,
    required this.onTap,
  }) : assert(icon != null || glyph != null, 'need an icon or a glyph');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 38,
            child: Center(
              child:
                  glyph ??
                  Icon(
                    icon,
                    size: 18,
                    color: active ? accent : scheme.onSurfaceVariant,
                  ),
            ),
          ),
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
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
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
    // Lime needs dark text, the brand purple needs white — pick by luminance
    // so both themes stay readable.
    final onColor = color.computeLuminance() > 0.5
        ? Colors.black
        : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.2,
          color: onColor,
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
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 34,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

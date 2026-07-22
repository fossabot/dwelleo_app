import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/contact_launcher.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/share_link.dart';
import '../../../../core/widgets/whatsapp_icon.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/property.dart';
import '../cubit/compare_cubit.dart';
import '../cubit/property_detail_cubit.dart';
import '../widgets/favorite_heart.dart';
import '../widgets/property_insights.dart';
import '../widgets/property_location_section.dart';
import '../cubit/property_detail_state.dart';

class PropertyDetailScreen extends StatefulWidget {
  final String slug;
  const PropertyDetailScreen({super.key, required this.slug});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  late final PropertyDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<PropertyDetailCubit>()..load(widget.slug);
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
        body: BlocBuilder<PropertyDetailCubit, PropertyDetailState>(
          builder: (context, state) {
            return switch (state) {
              PropertyDetailInitial() || PropertyDetailLoading() =>
                const Center(child: CircularProgressIndicator()),
              PropertyDetailError(:final message) => _DetailError(
                message: message,
                onRetry: () =>
                    context.read<PropertyDetailCubit>().load(widget.slug),
              ),
              PropertyDetailLoaded(:final property) => _DetailBody(
                property: property,
              ),
            };
          },
        ),
        bottomNavigationBar:
            BlocBuilder<PropertyDetailCubit, PropertyDetailState>(
              builder: (context, state) => state is PropertyDetailLoaded
                  ? _ContactBar(
                      propertyId: state.property.id,
                      owner: state.property.owner,
                    )
                  : const SizedBox.shrink(),
            ),
      ),
    );
  }
}

class _DetailBody extends StatefulWidget {
  final Property property;
  const _DetailBody({required this.property});

  @override
  State<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends State<_DetailBody> {
  final _pageController = PageController();
  int _imageIndex = 0;
  late List<MediaImage> _images;

  @override
  void initState() {
    super.initState();
    // Dedupe (cover already appears in `images`) lives on the entity —
    // Property.galleryImages — so it stays out of the widget layer.
    _images = widget.property.galleryImages;
  }

  @override
  void didUpdateWidget(_DetailBody old) {
    super.didUpdateWidget(old);
    if (old.property != widget.property) {
      _images = widget.property.galleryImages;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Toggle the compare tray with feedback; when the tray fills (2 items)
  /// the snackbar offers a jump straight to the /compare page.
  void _toggleCompare(BuildContext context, Property property) {
    final l10n = AppLocalizations.of(context);
    final cubit = sl<CompareCubit>();
    final wasIn = cubit.contains(property.id);
    cubit.toggle(property);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(wasIn ? l10n.compareRemoved : l10n.compareAdded),
        action: !wasIn && cubit.isFull
            ? SnackBarAction(
                label: l10n.view,
                onPressed: () => context.push(RoutePaths.compare),
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    final scheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          actions: [
            // Share / Compare sit on a scrim disc so they read the same as
            // the favourite heart over any photo (owner review).
            _ScrimAction(
              tooltip: AppLocalizations.of(context).share,
              glyph: SvgPicture.asset(
                AppSvg.share,
                width: 15,
                height: 15,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              onTap: () => ShareLink.shareProperty(
                slug: property.slug,
                title: property.title,
                arabic: Localizations.localeOf(context).languageCode == 'ar',
              ),
            ),
            BlocBuilder<CompareCubit, List<Property>>(
              bloc: sl<CompareCubit>(),
              builder: (context, tray) {
                final inTray = tray.any((p) => p.id == property.id);
                return _ScrimAction(
                  tooltip: AppLocalizations.of(context).compare,
                  icon: inTray
                      ? Icons.library_add_check_rounded
                      : Icons.compare_arrows_rounded,
                  active: inTray,
                  onTap: () => _toggleCompare(context, property),
                );
              },
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: FavoriteHeart(property: property, scrim: true),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (_images.isEmpty)
                  const _ImagePlaceholder()
                else
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _imageIndex = i),
                    itemCount: _images.length,
                    itemBuilder: (_, i) => CachedNetworkImage(
                      imageUrl: _images[i].path,
                      fit: BoxFit.cover,
                      placeholder: (ctx, _) => const _ImagePlaceholder(),
                      errorWidget: (ctx, url, error) =>
                          const _ImagePlaceholder(),
                    ),
                  ),
                if (_images.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: _GalleryDots(
                      count: _images.length,
                      index: _imageIndex,
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      AppSvg.sar,
                      width: 22,
                      height: 22,
                      colorFilter: ColorFilter.mode(
                        scheme.onSurface,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      Formatters.priceValue(property.price),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    if (property.listingType != null)
                      _Pill(
                        label: property.listingType!.isForRent
                            ? 'For Rent'
                            : 'For Sale',
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  property.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (property.location?.address != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.location!.address!,
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 18),
                _Specs(property: property),
                if (property.description?.isNotEmpty == true) ...[
                  const _SectionTitle('About this property'),
                  Text(
                    property.description!,
                    style: TextStyle(height: 1.55, color: scheme.onSurface),
                  ),
                ],
                if (property.amenities.isNotEmpty) ...[
                  const _SectionTitle('Amenities'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final a in property.amenities)
                        Chip(label: Text(a.title)),
                    ],
                  ),
                ],
                // dwelleo.sa parity: the AI insight system (price
                // prediction / investment / lifestyle) + similar listings,
                // all from the verified public payload.
                PropertyLocationSection(property: property),
                const SizedBox(height: 22),
                PropertyInsightsSection(property: property),
                SimilarPropertiesSection(property: property),
                if (property.owner != null) ...[
                  const _SectionTitle('Listed by'),
                  _OwnerCard(owner: property.owner!),
                ],
                if (property.location?.adLicenseNumber != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Ad license: ${property.location!.adLicenseNumber}',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant),
    );
  }
}

class _GalleryDots extends StatelessWidget {
  final int count;
  final int index;
  const _GalleryDots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.white70,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentFor(brightness),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.onAccentFor(brightness),
          fontWeight: FontWeight.w700,
          fontSize: 12,
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
    final c = Theme.of(context).colorScheme.onSurface;
    final items = <Widget>[
      if (property.bedrooms != null)
        _SpecChip(
          svg: AppSvg.bed,
          label: '${property.bedrooms} Beds',
          color: c,
        ),
      if (property.bathrooms != null)
        _SpecChip(
          svg: AppSvg.bath,
          label: '${property.bathrooms} Baths',
          color: c,
        ),
      if (property.areaSqm != null)
        _SpecChip(
          svg: AppSvg.sqf,
          label: Formatters.area(property.areaSqm),
          color: c,
        ),
      if (property.hasMaidRoom)
        _SpecIcon(
          icon: Icons.cleaning_services_outlined,
          label: '${property.maidRoom} Maid',
          color: c,
        ),
      if (property.furnishingStatus != null)
        _SpecIcon(
          icon: Icons.chair_outlined,
          label: _pretty(property.furnishingStatus!),
          color: c,
        ),
    ];
    return Wrap(spacing: 18, runSpacing: 12, children: items);
  }

  static String _pretty(String s) =>
      s.replaceAll('_', ' ').replaceAll('-', ' ');
}

class _SpecChip extends StatelessWidget {
  final String svg;
  final String label;
  final Color color;
  const _SpecChip({
    required this.svg,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          svg,
          width: 18,
          height: 18,
          colorFilter: ColorFilter.mode(AppColors.primaryDark, BlendMode.srcIn),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class _SpecIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SpecIcon({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryDark),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class _OwnerCard extends StatelessWidget {
  final PropertyOwner owner;
  const _OwnerCard({required this.owner});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: owner.image?.path != null
                ? CachedNetworkImageProvider(owner.image!.path)
                : null,
            child: owner.image?.path == null
                ? const Icon(Icons.business, color: AppColors.ink)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        owner.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (owner.verified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified,
                        size: 16,
                        color: AppColors.info,
                      ),
                    ],
                  ],
                ),
                if (owner.userType != null)
                  Text(
                    owner.userType!.replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactBar extends StatelessWidget {
  final int propertyId;
  final PropertyOwner? owner;
  const _ContactBar({required this.propertyId, required this.owner});

  Future<void> _contact(BuildContext context, {required bool whatsApp}) async {
    final l10n = AppLocalizations.of(context);
    final phone = owner?.phone;
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.contactUnavailable)));
      return;
    }
    // App-side lead signal (backend leads/ingest lands once its payload is
    // captured — @bodyPending discipline).
    sl<AnalyticsService>().leadContact(
      method: whatsApp ? 'whatsapp' : 'call',
      propertyId: propertyId,
      ownerType: owner?.userType,
    );
    final ok = whatsApp
        ? await ContactLauncher.whatsApp(phone)
        : await ContactLauncher.call(phone);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.contactUnavailable)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _contact(context, whatsApp: false),
              icon: const Icon(Icons.phone, size: 18),
              label: Text(l10n.callNow),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _contact(context, whatsApp: true),
              icon: const WhatsAppIcon(),
              label: Text(l10n.whatsapp),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _DetailError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _DetailError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
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
      ),
    );
  }
}

/// Circular scrim button used by the detail app bar so Share and Compare
/// match the favourite heart's treatment over the hero photo.
class _ScrimAction extends StatelessWidget {
  final IconData? icon;
  final Widget? glyph;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  const _ScrimAction({
    this.icon,
    this.glyph,
    required this.tooltip,
    this.active = false,
    required this.onTap,
  }) : assert(icon != null || glyph != null, 'need an icon or a glyph');

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 6),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.black.withValues(alpha: 0.35),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 38,
              height: 38,
              child: Center(
                child:
                    glyph ??
                    Icon(icon, size: 19, color: active ? accent : Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

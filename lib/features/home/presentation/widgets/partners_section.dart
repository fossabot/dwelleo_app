import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/failure_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dwelleo_images.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/developer.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import 'partner_details_sheet.dart';
import 'scroll_rail.dart';
import 'section_error_box.dart';

/// dwelleo.sa's featured-partners section: heading that switches between
/// "Featured Developers" / "Featured Brokers", the segmented
/// [Top Real Estate Developers | Top Real Estate Brokers] pill, and the
/// white-logo cards. Both feeds are real API lists
/// (`/developers` and `/developers?filter[user_type]=broker`).
class PartnersSection extends StatefulWidget {
  const PartnersSection({super.key});

  @override
  State<PartnersSection> createState() => _PartnersSectionState();
}

class _PartnersSectionState extends State<PartnersSection> {
  bool _brokers = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (a, b) =>
          !identical(a.developers, b.developers) ||
          !identical(a.brokers, b.brokers),
      builder: (context, state) {
        final section = _brokers ? state.brokers : state.developers;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 26, 16, 6),
              child: Text.rich(
                TextSpan(
                  text: _brokers
                      ? '${l10n.featuredBrokersLead} '
                      : '${l10n.featuredDevelopersLead} ',
                  children: [
                    TextSpan(
                      text: _brokers
                          ? l10n.featuredBrokersAccent
                          : l10n.featuredDevelopersAccent,
                      style: TextStyle(color: accent),
                    ),
                  ],
                ),
                style: TextStyle(
                  fontSize: 26,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
              child: Text(
                l10n.featuredDevelopersSubtitle,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            // The site's wide segmented pill.
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 14),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _PartnersTab(
                        label: l10n.topDevelopers,
                        selected: !_brokers,
                        onTap: () => setState(() => _brokers = false),
                      ),
                    ),
                    Expanded(
                      child: _PartnersTab(
                        label: l10n.topBrokers,
                        selected: _brokers,
                        onTap: () => setState(() => _brokers = true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            switch (section) {
              SectionLoading<List<Developer>>() => const RailSkeleton(
                height: 206,
                itemWidth: 158,
              ),
              SectionError<List<Developer>>(:final failure) => SectionErrorBox(
                message: failure.localized(l10n),
                onRetry: () => context.read<HomeCubit>().refresh(),
              ),
              SectionLoaded<List<Developer>>(:final data) =>
                data.isEmpty
                    ? const SizedBox.shrink()
                    : ScrollRail(
                        height: 206,
                        gap: 10,
                        itemCount: data.length,
                        itemBuilder: (context, i) =>
                            _PartnerCard(partner: data[i]),
                      ),
            },
          ],
        );
      },
    );
  }
}

class _PartnersTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PartnersTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentFor(brightness)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          // Scale down instead of ellipsizing — "Top Real Estate Developers"
          // must never truncate like it did.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected
                    ? AppColors.onAccentFor(brightness)
                    : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Site-style partner card: white logo plate, name, lime divider and the
/// circular arrow. Tapping opens the partner sheet whose CTA lists the
/// partner's real properties (`filter[developer_id]`).
class _PartnerCard extends StatelessWidget {
  final Developer partner;

  const _PartnerCard({required this.partner});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    void open() => showPartnerDetailsSheet(context, partner);

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: open,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 158,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // Logos ship on white — keep the white plate in dark mode
                  // too, like the website's tiles.
                  color: Colors.white,
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: partner.image == null
                    ? _Initial(name: partner.name)
                    : CachedNetworkImage(
                        imageUrl: DwelleoImages.optimized(
                          partner.image!.displayThumb,
                          width: 640,
                        ),
                        httpHeaders: DwelleoImages.headers,
                        memCacheWidth: 320,
                        fit: BoxFit.contain,
                        placeholder: (ctx, url) => _Initial(name: partner.name),
                        errorWidget: (ctx, url, error) =>
                            _Initial(name: partner.name),
                      ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  partner.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 34,
                height: 2.5,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              // Site's circular FORWARD-arrow (→), tinted with the theme accent
              // (lime in dark, purple in light) with a readable arrow on top.
              Material(
                color: AppColors.accentFor(brightness),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: open,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 34,
                    height: 34,
                    child: Icon(
                      Icons.arrow_forward,
                      size: 18,
                      color: AppColors.onAccentFor(brightness),
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

class _Initial extends StatelessWidget {
  final String name;

  const _Initial({required this.name});

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    return Center(
      child: Text(
        trimmed.isEmpty ? '•' : trimmed.characters.first.toUpperCase(),
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

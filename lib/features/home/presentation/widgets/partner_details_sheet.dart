import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/dwelleo_images.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/developer.dart';

/// Quick-look sheet for a developer/broker with the REAL payoff:
/// "View Properties" opens the properties list filtered by
/// `filter[developer_id]` — the actual API filter.
Future<void> showPartnerDetailsSheet(BuildContext context, Developer partner) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => _PartnerSheet(partner: partner),
  );
}

class _PartnerSheet extends StatelessWidget {
  final Developer partner;

  const _PartnerSheet({required this.partner});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: partner.image == null
                  ? const Icon(
                      Icons.business_rounded,
                      size: 36,
                      color: AppColors.accent,
                    )
                  : CachedNetworkImage(
                      imageUrl: DwelleoImages.optimized(
                        partner.image!.displayThumb,
                        width: 640,
                      ),
                      httpHeaders: DwelleoImages.headers,
                      memCacheWidth: 368,
                      fit: BoxFit.contain,
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              partner.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                height: 1.25,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                if (partner.rating > 0)
                  _InfoChip(
                    icon: Icons.star_rounded,
                    label: partner.rating.toStringAsFixed(1),
                  ),
                if (partner.featured || partner.featuredInHome)
                  _InfoChip(
                    icon: Icons.workspace_premium_rounded,
                    label: l10n.featured,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  context.push(
                    RoutePaths.propertySearchPath(
                      null,
                      developerId: partner.id,
                    ),
                    extra: partner.name.trim(),
                  );
                },
                icon: const Icon(Icons.home_work_outlined, size: 19),
                label: Text(l10n.viewProperties),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.viewPropertiesHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

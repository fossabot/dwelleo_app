import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../l10n/app_localizations.dart';

/// The four shortcut tiles under the hero, mirroring dwelleo.sa
/// (Price Statistics / Apartments in Riyadh / Villas in Jeddah / Off-Plan).
///
/// City & property-type ids are CONFIRMED live values shared by /lookup and
/// /market/cities (2026-07-02): Riyadh=1, Jeddah=11; Apartment=1, Villa=2.
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  static const int _riyadhCityId = 1;
  static const int _jeddahCityId = 11;
  static const int _apartmentTypeId = 1;
  static const int _villaTypeId = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 18, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.bar_chart_rounded,
                  tint: const Color(0xFF6366F1),
                  label: l10n.quickPriceStats,
                  onTap: () => context.push(RoutePaths.marketInsights),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  icon: Icons.location_city_rounded,
                  tint: const Color(0xFF84CC16),
                  label: l10n.quickApartmentsRiyadh,
                  onTap: () => context.push(
                    RoutePaths.propertySearchPath(
                      'for-sale',
                      cityId: _riyadhCityId,
                      propertyTypeId: _apartmentTypeId,
                    ),
                    extra: l10n.quickApartmentsRiyadh,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionTile(
                  icon: Icons.house_rounded,
                  tint: const Color(0xFFF97316),
                  label: l10n.quickVillasJeddah,
                  onTap: () => context.push(
                    RoutePaths.propertySearchPath(
                      'for-sale',
                      cityId: _jeddahCityId,
                      propertyTypeId: _villaTypeId,
                    ),
                    extra: l10n.quickVillasJeddah,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionTile(
                  icon: Icons.layers_rounded,
                  tint: const Color(0xFF8B5CF6),
                  label: l10n.quickOffPlanProjects,
                  onTap: () => context.push(RoutePaths.explore),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.tint,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: tint),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import 'ai_search_pill.dart';

/// Mobile version of dwelleo.sa's second header row:
/// Buy · Rent · Explore ▾ · Subscriptions · AI Sales Agent [NEW] · AI Search.
class HomeNavStrip extends StatelessWidget {
  /// Scrolls Home to the Featured Developers/Brokers section
  /// (the Explore ▾ → Developers entry, kept on-page like the website's
  /// featured partners anchor).
  final VoidCallback onDevelopers;

  const HomeNavStrip({super.key, required this.onDevelopers});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SizedBox(
      height: 44,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        children: [
          _NavLink(
            label: l10n.buy,
            onTap: () =>
                context.push(RoutePaths.propertySearchPath('for-sale')),
          ),
          _NavLink(
            label: l10n.rent,
            onTap: () =>
                context.push(RoutePaths.propertySearchPath('for-rent')),
          ),
          _NavLink(
            label: l10n.explore,
            trailing: Icons.keyboard_arrow_down_rounded,
            onTap: () => _showExploreSheet(context, l10n),
          ),
          _NavLink(
            label: l10n.subscriptions,
            onTap: () => context.push(RoutePaths.subscriptions),
          ),
          _NavLink(
            label: l10n.aiSalesAgent,
            badge: l10n.newLabel,
            // Its own surface — never aliased to AI Search (review P0).
            onTap: () => context.go(RoutePaths.aiSalesAgent),
          ),
          const Padding(
            padding: EdgeInsetsDirectional.only(start: 4),
            child: Center(child: AiSearchPill()),
          ),
        ],
      ),
    );
  }

  void _showExploreSheet(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SheetItem(
              icon: Icons.home_work_outlined,
              label: l10n.properties,
              onTap: () {
                Navigator.pop(sheetContext);
                context.push(RoutePaths.propertySearchPath(null));
              },
            ),
            _SheetItem(
              icon: Icons.apartment_rounded,
              label: l10n.projects,
              onTap: () {
                Navigator.pop(sheetContext);
                context.push(RoutePaths.explore);
              },
            ),
            _SheetItem(
              icon: Icons.business_center_outlined,
              label: l10n.developers,
              onTap: () {
                Navigator.pop(sheetContext);
                onDevelopers();
              },
            ),
            _SheetItem(
              icon: Icons.calculate_outlined,
              label: l10n.estimateProperty,
              onTap: () {
                Navigator.pop(sheetContext);
                context.push(RoutePaths.estimate);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _NavLink extends StatelessWidget {
  final String label;
  final IconData? trailing;
  final String? badge;
  final VoidCallback onTap;

  const _NavLink({
    required this.label,
    this.trailing,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            if (trailing != null)
              Icon(trailing, size: 18, color: scheme.onSurfaceVariant),
            if (badge != null) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.accentFor(Theme.of(context).brightness),
      ),
      title: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurface),
      ),
      trailing: Icon(
        Icons.arrow_outward_rounded,
        size: 18,
        color: scheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

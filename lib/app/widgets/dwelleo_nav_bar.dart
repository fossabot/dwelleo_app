import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/motion.dart';
import '../../l10n/app_localizations.dart';

/// Bottom navigation for the main shell — the mobile answer to dwelleo.sa's
/// header/user-menu: Home, Explore (projects), a raised lime AI Search action
/// (the brand's signature CTA), Saved and Profile.
///
/// RTL-safe: a plain [Row] mirrors automatically with text direction.
class DwelleoNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const DwelleoNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _NavItem(
                  index: 0,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: l10n.home,
                ),
                _NavItem(
                  index: 1,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  icon: Icons.apartment_outlined,
                  activeIcon: Icons.apartment_rounded,
                  label: l10n.explore,
                ),
                _AiNavItem(
                  selected: currentIndex == 2,
                  onTap: () => onTap(2),
                  label: l10n.aiSearchShort,
                ),
                _NavItem(
                  index: 3,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  icon: Icons.favorite_outline_rounded,
                  activeIcon: Icons.favorite_rounded,
                  label: l10n.saved,
                ),
                _NavItem(
                  index: 4,
                  currentIndex: currentIndex,
                  onTap: onTap,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: l10n.profile,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == currentIndex;
    final brightness = Theme.of(context).brightness;
    final color = selected
        ? AppColors.accentFor(brightness)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkResponse(
        onTap: () => onTap(index),
        radius: 36,
        child: Semantics(
          selected: selected,
          button: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? activeIcon : icon, size: 24, color: color),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The raised center action — lime circle with the AI spark, floating a touch
/// above the bar like dwelleo.sa's glowing CTA.
class _AiNavItem extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final String label;

  const _AiNavItem({
    required this.selected,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final color = selected
        ? AppColors.accentFor(brightness)
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: 40,
        child: Semantics(
          selected: selected,
          button: true,
          label: label,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.translate(
                offset: const Offset(0, -12),
                child: PulseGlow(
                  glowColor: AppColors.primary,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                        width: 3,
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      size: 22,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -10),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

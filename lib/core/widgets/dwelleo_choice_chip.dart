import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The brand pill filter chip (accent-filled when selected) used across
/// Home/Explore and the property filters. In core: shared by 2+ features.
class DwelleoChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const DwelleoChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final bg = selected
        ? AppColors.accentFor(brightness)
        : scheme.surfaceContainerHighest;
    final fg = selected ? AppColors.onAccentFor(brightness) : scheme.onSurface;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
          ),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'RocGrotesk',
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: fg,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

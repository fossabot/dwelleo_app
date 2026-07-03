import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The website's labeled segmented capsule ("LISTING  [Buy | Rent]") used by
/// the City Intelligence table and the Interactive Market map.
class LabeledToggle extends StatelessWidget {
  final String label;
  final String first;
  final String second;
  final bool firstSelected;
  final VoidCallback onFirst;
  final VoidCallback onSecond;

  const LabeledToggle({
    super.key,
    required this.label,
    required this.first,
    required this.second,
    required this.firstSelected,
    required this.onFirst,
    required this.onSecond,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Segment(label: first, selected: firstSelected, onTap: onFirst),
                _Segment(
                  label: second,
                  selected: !firstSelected,
                  onTap: onSecond,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({
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
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.accentFor(brightness)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected
                  ? AppColors.onAccentFor(brightness)
                  : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

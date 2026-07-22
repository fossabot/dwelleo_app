import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Compact icon+label suggestion pill used across the AI surfaces
/// (Sales Agent action row, AI Search quick replies). Accent follows the
/// brand rule: lime in dark mode, purple in light mode.
class SuggestionPill extends StatelessWidget {
  /// Material icon, OR pass [glyph] for a brand mark (e.g. WhatsApp).
  final IconData? icon;
  final Widget? glyph;
  final String label;
  final VoidCallback onTap;

  const SuggestionPill({
    super.key,
    this.icon,
    this.glyph,
    required this.label,
    required this.onTap,
  }) : assert(icon != null || glyph != null, 'need an icon or a glyph');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = AppColors.accentFor(Theme.of(context).brightness);

    return Material(
      color: accent.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              glyph ?? Icon(icon, size: 15, color: accent),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

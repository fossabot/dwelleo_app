import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Section headline in the dwelleo.sa style: bold title with an optional
/// accent-colored tail ("Explore Projects by *Cities*"), optional subtitle,
/// optional trailing action (e.g. "View All").
class SectionHeader extends StatelessWidget {
  final String title;
  final String? accent;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.accent,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accentColor = AppColors.accentFor(Theme.of(context).brightness);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 26, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: title,
                    children: [
                      if (accent != null)
                        TextSpan(
                          text: ' $accent',
                          style: TextStyle(color: accentColor),
                        ),
                    ],
                  ),
                  style: TextStyle(
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(width: 12),
                _ActionChip(label: actionLabel!, onTap: onAction),
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _ActionChip({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.primary : AppColors.accent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 7, 10, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.ink : Colors.white,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_outward_rounded,
                size: 15,
                color: isDark ? AppColors.ink : Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

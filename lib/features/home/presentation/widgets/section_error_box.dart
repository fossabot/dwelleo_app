import 'package:flutter/material.dart';

import '../../../../core/widgets/motion.dart';
import '../../../../l10n/app_localizations.dart';

/// Compact inline error for one home section — the rest of the page keeps
/// working (never blank the whole screen for one failed feed).
class SectionErrorBox extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const SectionErrorBox({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 20,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}

/// Skeleton placeholder boxes for a loading horizontal rail.
class RailSkeleton extends StatelessWidget {
  final double height;
  final double itemWidth;

  const RailSkeleton({super.key, required this.height, this.itemWidth = 260});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    return SkeletonPulse(
      child: SizedBox(
        height: height,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (ctx, i) => const SizedBox(width: 12),
          itemBuilder: (context, i) => Container(
            width: itemWidth,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}

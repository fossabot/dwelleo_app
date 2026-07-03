import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/route_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/motion.dart';
import '../../../../l10n/app_localizations.dart';

/// The website's signature AI Search control: a purple pill with a lime
/// "AI" disc, the label and a spark — reused in the nav strip and the
/// search card ("Try AI Search").
class AiSearchPill extends StatelessWidget {
  /// Compact = the small in-field chip; full = the nav-strip pill.
  final bool compact;

  const AiSearchPill({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Material(
      color: AppColors.accent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => context.go(RoutePaths.aiSearch),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            compact ? 4 : 5,
            compact ? 4 : 5,
            compact ? 10 : 14,
            compact ? 4 : 5,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Same living glow as the bottom-nav AI button.
              PulseGlow(
                glowColor: AppColors.primary,
                strength: 0.5,
                child: Container(
                  width: compact ? 22 : 26,
                  height: compact ? 22 : 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    'AI',
                    style: TextStyle(
                      fontSize: compact ? 9.5 : 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
              SizedBox(width: compact ? 6 : 8),
              Text(
                compact ? l10n.tryAiSearch : l10n.search,
                style: TextStyle(
                  fontSize: compact ? 11.5 : 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: compact ? 4 : 6),
              const Icon(
                Icons.auto_awesome,
                size: 13,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

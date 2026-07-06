import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// The dwelleo.sa hero headline ("Find What You Need *with Confidence*").
/// Intent tabs and the query field live in [SearchCard] right below —
/// on mobile we don't repeat them here.
class HomeHero extends StatelessWidget {
  const HomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              text: l10n.heroTitleLead,
              children: [
                TextSpan(
                  text: ' ${l10n.heroTitleAccent}',
                  style: TextStyle(color: AppColors.accentFor(brightness)),
                ),
              ],
            ),
            style: TextStyle(
              fontSize: 30,
              height: 1.12,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.heroSubtitle,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

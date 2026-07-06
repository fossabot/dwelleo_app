import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/dwelleo_app_bar.dart';
import '../../../../l10n/app_localizations.dart';

/// Profile tab — branded placeholder until the account branch lands
/// (real endpoints exist: /profile, /user/*, see REAL_API_SPEC).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const DwelleoAppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_rounded,
                  size: 44,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.profile,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.profileStubBody,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentFor(
                    Theme.of(context).brightness,
                  ).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.comingSoon,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentFor(Theme.of(context).brightness),
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

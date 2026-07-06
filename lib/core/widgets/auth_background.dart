import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Ambient page backdrop for the auth screens (login + sign-up), matching the
/// modern "fed" background on dwelleo.sa. The site's cards/inputs are simply
/// TRANSLUCENT (white @10% / @5%) — there is no real blur — so the glassy look
/// comes entirely from a rich dark gradient + an accent glow showing THROUGH
/// the translucent card. This widget paints exactly that so the [AuthCard]
/// blends into the background instead of reading as a flat grey block.
///
/// Purely decorative ([IgnorePointer]); sits BELOW the page content.
class AuthBackground extends StatelessWidget {
  final Widget child;
  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glow = AppColors.accentFor(Theme.of(context).brightness);

    // Base vertical gradient: top matches the app bar (#1B1B1B) so there's no
    // seam, fading to a darker near-black at the bottom where the glow sits.
    final baseColors = isDark
        ? const [Color(0xFF1B1B1B), Color(0xFF141414), Color(0xFF0E0E0E)]
        : const [Color(0xFFF6F7F3), Color(0xFFF1F3EC), Color(0xFFECEFE4)];

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: baseColors,
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        // Accent glow rising from the bottom (the signature dwelleo.sa look).
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, 1.15),
                  radius: 1.1,
                  colors: [
                    glow.withValues(alpha: isDark ? 0.16 : 0.07),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.72],
                ),
              ),
            ),
          ),
        ),
        // Soft secondary glow up top so the translucent card top edge lifts too.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.9),
                  radius: 0.95,
                  colors: [
                    glow.withValues(alpha: isDark ? 0.07 : 0.035),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

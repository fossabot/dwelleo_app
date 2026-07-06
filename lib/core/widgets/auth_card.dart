import 'package:flutter/material.dart';

/// The translucent "glassy" panel that wraps the auth forms (Login + both
/// sign-up steps), matching the card captured from dwelleo.sa:
///   dark  → bg rgba(255,255,255,.10), 1px rgba(255,255,255,.10) border, r24
///   light → faint near-white panel on the page, hairline border, r24
/// Shared so every auth screen uses one definition instead of re-declaring it.
class AuthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const AuthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(32),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        // Very subtle fill so the card melts into the gradient backdrop like
        // the site (was a heavier grey @10%). The glow behind now reads through.
        color: isDark
            ? Colors.white.withValues(alpha: 0.045)
            : Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: child,
    );
  }
}

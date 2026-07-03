import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The website's circular ↗ affordance that marks a card as tappable
/// (property, project and partner cards all carry it on dwelleo.sa).
/// In core: shared by the properties and home features.
class ArrowBadge extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;

  /// White disc (over photos) or muted (on flat cards).
  final bool onPhoto;

  const ArrowBadge({
    super.key,
    this.onTap,
    this.size = 34,
    this.onPhoto = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = onPhoto ? Colors.white : scheme.surfaceContainerHighest;
    final fg = onPhoto ? AppColors.ink : scheme.onSurface;

    return Material(
      color: bg,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(Icons.arrow_outward_rounded, size: size * 0.5, color: fg),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_assets.dart';

/// The WhatsApp brand glyph, from the project's own SVG.
///
/// Shared in `core/` because every WhatsApp affordance in the app must look
/// identical — the list card, the property detail CTA and the Sales Agent
/// action row were previously drawing three different things (two of them a
/// generic Material chat bubble), which read as sloppy next to the website.
///
/// [color] tints the glyph; pass null to keep WhatsApp's own brand green.
class WhatsAppIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const WhatsAppIcon({super.key, this.size = 18, this.color});

  /// WhatsApp's official brand green — correct on both themes.
  static const Color brand = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AppSvg.whatsapp,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color ?? brand, BlendMode.srcIn),
    );
  }
}

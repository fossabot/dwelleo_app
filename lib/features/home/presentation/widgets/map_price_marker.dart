import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';

/// Draws dwelleo.sa's lime price bubbles as custom map markers via dart:ui —
/// no assets. Bubble size and opacity scale with the "heatmap intensity"
/// (0..1), matching the website's legend semantics: pricier = bigger and
/// brighter.
abstract final class MapPriceMarker {
  /// [title] is the uppercased city name (null for district bubbles),
  /// [price] a pre-formatted value like `3,782`, [intensity] 0..1.
  static Future<BitmapDescriptor> bubble({
    required String price,
    String? title,
    required double devicePixelRatio,
    double intensity = 1,
    // Bubble body + label color. dwelleo.sa flips these by theme: lime bubble +
    // near-black label in dark, purple bubble + white label in light.
    Color body = AppColors.primary,
    Color onBody = AppColors.ink,
  }) async {
    final large = title != null;
    final t = intensity.clamp(0.0, 1.0);
    final logicalSize = large ? 68 + 34 * t : 44 + 22 * t;
    final alpha = 0.62 + 0.38 * t;
    final scale = devicePixelRatio.clamp(1.0, 3.0);
    final px = logicalSize * scale;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(px / 2, px / 2);

    // Outer glow + white ring + lime body, like the website's bubbles.
    canvas.drawCircle(
      center,
      px / 2,
      Paint()..color = body.withValues(alpha: 0.22 + 0.16 * t),
    );
    canvas.drawCircle(
      center,
      px / 2 - 3 * scale,
      Paint()..color = Colors.white.withValues(alpha: alpha),
    );
    canvas.drawCircle(
      center,
      px / 2 - 5 * scale,
      Paint()..color = body.withValues(alpha: alpha),
    );

    void text(
      String value, {
      required double size,
      required FontWeight weight,
      required double dy,
      double maxWidth = double.infinity,
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: value,
          style: TextStyle(
            fontSize: size * scale,
            fontWeight: weight,
            color: onBody,
          ),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxWidth);
      painter.paint(
        canvas,
        Offset(center.dx - painter.width / 2, center.dy + dy * scale),
      );
    }

    if (large) {
      final titleSize = 8.5 + 1.5 * t;
      final priceSize = 11.5 + 2.5 * t;
      text(
        title.toUpperCase(),
        size: titleSize,
        weight: FontWeight.w700,
        dy: -titleSize - 3,
        maxWidth: px - 14 * scale,
      );
      text(price, size: priceSize, weight: FontWeight.w800, dy: -1);
    } else {
      final priceSize = 9.5 + 2 * t;
      text(
        price,
        size: priceSize,
        weight: FontWeight.w800,
        dy: -priceSize / 2 - 1,
        maxWidth: px - 8 * scale,
      );
    }

    final image = await recorder.endRecording().toImage(px.round(), px.round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: scale,
    );
  }
}

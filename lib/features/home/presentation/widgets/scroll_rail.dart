import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Horizontal rail with the website's ‹ › paddle buttons overlaid at the
/// edges (featured properties, projects and partners rows all have them on
/// dwelleo.sa). Site behavior faithfully kept: the back paddle is hidden at
/// the start and the forward paddle hides at the end — each fades in only
/// when there is somewhere to go. RTL-aware.
class ScrollRail extends StatefulWidget {
  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double gap;
  final EdgeInsetsGeometry padding;

  const ScrollRail({
    super.key,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
    this.gap = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  State<ScrollRail> createState() => _ScrollRailState();
}

class _ScrollRailState extends State<ScrollRail> {
  late final ScrollController _controller;
  bool _canBack = false;
  bool _canForward = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _controller.addListener(_syncPaddles);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _syncPaddles() {
    if (!_controller.hasClients) return;
    final position = _controller.position;
    final canBack = position.pixels > 4;
    final canForward = position.pixels < position.maxScrollExtent - 4;
    if (canBack != _canBack || canForward != _canForward) {
      setState(() {
        _canBack = canBack;
        _canForward = canForward;
      });
    }
  }

  void _page(double direction) {
    if (!_controller.hasClients) return;
    final viewport = _controller.position.viewportDimension;
    final target = (_controller.offset + direction * viewport * 0.85).clamp(
      0.0,
      _controller.position.maxScrollExtent,
    );
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;

    return SizedBox(
      height: widget.height,
      child: NotificationListener<ScrollMetricsNotification>(
        // Fires when the viewport/content is first laid out (and on any
        // content change) so the forward paddle appears without user input.
        onNotification: (notification) {
          _syncPaddles();
          return false;
        },
        child: Stack(
          children: [
            ListView.separated(
              controller: _controller,
              padding: widget.padding,
              scrollDirection: Axis.horizontal,
              itemCount: widget.itemCount,
              separatorBuilder: (ctx, i) => SizedBox(width: widget.gap),
              itemBuilder: widget.itemBuilder,
            ),
            _PaddleSlot(
              visible: _canBack,
              start: true,
              icon: rtl ? Icons.chevron_right : Icons.chevron_left,
              onTap: () => _page(-1),
            ),
            _PaddleSlot(
              visible: _canForward,
              start: false,
              icon: rtl ? Icons.chevron_left : Icons.chevron_right,
              onTap: () => _page(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaddleSlot extends StatelessWidget {
  final bool visible;
  final bool start;
  final IconData icon;
  final VoidCallback onTap;

  const _PaddleSlot({
    required this.visible,
    required this.start,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PositionedDirectional(
      start: start ? 4 : null,
      end: start ? null : 4,
      top: 0,
      bottom: 0,
      child: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: visible ? 1 : 0,
          child: IgnorePointer(
            ignoring: !visible,
            child: Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              elevation: 3,
              shadowColor: Colors.black45,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(icon, size: 24, color: AppColors.ink),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

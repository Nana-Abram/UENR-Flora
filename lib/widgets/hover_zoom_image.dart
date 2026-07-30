import 'package:flutter/material.dart';

/// Wraps a card's image so it zooms in slightly on hover, clipped to its
/// original frame so the zoom never bleeds into surrounding content.
/// Pairs with [HoverLift]'s whole-card lift for the same hover moment —
/// used on the Explorer grid, Learn's featured articles, and Home's
/// featured species cards.
class HoverZoomImage extends StatefulWidget {
  final Widget child;
  final double scale;
  const HoverZoomImage({super.key, required this.child, this.scale = 1.08});

  @override
  State<HoverZoomImage> createState() => _HoverZoomImageState();
}

class _HoverZoomImageState extends State<HoverZoomImage> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: ClipRect(
        child: AnimatedScale(
          scale: _hovering ? widget.scale : 1.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

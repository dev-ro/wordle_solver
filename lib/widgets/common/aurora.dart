import 'package:flutter/material.dart';

/// Aurora gradient used for borders, highlights, and glows.
const LinearGradient kAuroraGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF89CFF0), Color(0xFFF4C2C2)],
);

/// Semi-transparent dark glass background for cards.
BoxDecoration glassDecoration({double radius = 16, double opacity = 0.28}) {
  return BoxDecoration(
    color: const Color(0xFF0E0E12).withValues(alpha: opacity),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 16,
        offset: Offset(0, 8),
      ),
    ],
  );
}

/// Container with an aurora gradient border and glassy inner background.
class AuroraCard extends StatelessWidget {
  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const AuroraCard({
    super.key,
    required this.child,
    this.borderWidth = 1.5,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: kAuroraGradient,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Container(
        margin: EdgeInsets.all(borderWidth),
        padding: padding,
        decoration: glassDecoration(radius: borderRadius - borderWidth),
        child: child,
      ),
    );
  }
}

/// A tile-like container with gradient border and hover/press animations.
class AuroraHoverTile extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double borderWidth;
  final bool emphasize; // for top recommendation emphasis
  final VoidCallback? onTap;

  const AuroraHoverTile({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.borderRadius = 12,
    this.borderWidth = 1.5,
    this.emphasize = false,
    this.onTap,
  });

  @override
  State<AuroraHoverTile> createState() => _AuroraHoverTileState();
}

class _AuroraHoverTileState extends State<AuroraHoverTile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final baseScale = widget.emphasize ? 1.02 : 1.0;
    final hoverScale = _hovered ? 1.05 : 1.0;
    final pressScale = _pressed ? 0.98 : 1.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: baseScale * hoverScale * pressScale,
          child: Container(
            decoration: BoxDecoration(
              gradient: kAuroraGradient,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF89CFF0).withValues(
                    alpha: widget.emphasize ? 0.35 : (_hovered ? 0.3 : 0.18),
                  ),
                  blurRadius: widget.emphasize ? 22 : 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Container(
              margin: EdgeInsets.all(widget.borderWidth),
              padding: widget.padding,
              decoration: BoxDecoration(
                color: const Color(0xFF15151A).withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(widget.borderRadius - widget.borderWidth),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}



import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Aurora gradient used for borders, highlights, and glows.
const LinearGradient kAuroraGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF89CFF0), Color(0xFFF4C2C2)],
);

/// Semi-transparent dark glass background for cards.
/// Increased transparency per UI update for animated white background.
BoxDecoration glassDecoration({double radius = 16, double opacity = 0.16}) {
  return BoxDecoration(
    color: const Color(0xFF0E0E12).withValues(alpha: opacity),
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [
      BoxShadow(color: Color(0x66000000), blurRadius: 16, offset: Offset(0, 8)),
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
  final Color?
  borderColorOverride; // when provided, use solid color border instead of gradient
  final Gradient? borderGradientOverride; // metallic gradient override
  final bool animatedGlow; // subtle pulsing glow

  const AuroraHoverTile({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.borderRadius = 12,
    this.borderWidth = 1.5,
    this.emphasize = false,
    this.onTap,
    this.borderColorOverride,
    this.borderGradientOverride,
    this.animatedGlow = false,
  });

  @override
  State<AuroraHoverTile> createState() => _AuroraHoverTileState();
}

class _AuroraHoverTileState extends State<AuroraHoverTile>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  bool _pressed = false;
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowTween;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowTween = Tween<double>(
      begin: 0.16,
      end: 0.34,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseScale = widget.emphasize ? 1.02 : 1.0;
    final hoverScale = _hovered ? 1.05 : 1.0;
    final pressScale = _pressed ? 0.98 : 1.0;

    Widget content = MouseRegion(
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
              color: widget.borderGradientOverride == null
                  ? widget.borderColorOverride
                  : null,
              gradient:
                  widget.borderGradientOverride ??
                  (widget.borderColorOverride == null ? kAuroraGradient : null),
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: _shadowColor().withValues(alpha: _shadowAlpha()),
                  blurRadius: widget.emphasize ? 22 : 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Container(
              margin: EdgeInsets.all(widget.borderWidth),
              padding: widget.padding,
              decoration: BoxDecoration(
                color: const Color(0xFF15151A).withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(
                  widget.borderRadius - widget.borderWidth,
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    if (widget.animatedGlow) {
      content = AnimatedBuilder(
        animation: _glowCtrl,
        builder: (context, child) => child!,
        child: content,
      );
    }

    return content;
  }

  Color _shadowColor() {
    if (widget.borderColorOverride != null) {
      return widget.borderColorOverride!;
    }
    if (widget.borderGradientOverride != null) {
      final colors = widget.borderGradientOverride is LinearGradient
          ? (widget.borderGradientOverride as LinearGradient).colors
          : (widget.borderGradientOverride as Gradient).colors;
      return colors.isNotEmpty ? colors.first : const Color(0xFF89CFF0);
    }
    return const Color(0xFF89CFF0);
  }

  double _shadowAlpha() {
    if (!widget.animatedGlow) {
      return widget.emphasize ? 0.35 : (_hovered ? 0.3 : 0.18);
    }
    // Blend animated glow with hover/emphasis for subtle motion
    final base = widget.emphasize ? 0.22 : (_hovered ? 0.20 : 0.16);
    return (_glowTween.value).clamp(base, 0.38);
  }
}

/// Full-width glassy AppBar matching `AuroraCard` styling.
class AuroraAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const AuroraAppBar({super.key, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 18);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Container(
          decoration: BoxDecoration(
            gradient: kAuroraGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            margin: const EdgeInsets.all(1.5),
            decoration: glassDecoration(radius: 14.5, opacity: 0.16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.5),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

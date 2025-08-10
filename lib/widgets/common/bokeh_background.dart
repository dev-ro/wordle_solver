import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'aurora.dart';

class BokehBackground extends StatefulWidget {
  const BokehBackground({super.key});

  @override
  State<BokehBackground> createState() => _BokehBackgroundState();
}

class _BokehBackgroundState extends State<BokehBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late List<_Orb> _orbs;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 36),
    )..repeat();
    _orbs = const [];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        // Lazily initialize orbs when size is known
        if (_orbs.isEmpty && size.width > 0 && size.height > 0) {
          _orbs = _generateOrbs(size);
        }

        // Adapt orb count/size if constraints changed meaningfully
        if (_orbs.isNotEmpty &&
            (size.width - _orbs.first.bounds.width).abs() > 50) {
          _orbs = _generateOrbs(size);
        }

        return ColoredBox(
          color: const Color(0xFF0F1115),
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  size: size,
                  painter: _BokehPainter(time: _controller.value, orbs: _orbs),
                  isComplex: true,
                  willChange: true,
                );
              },
            ),
          ),
        );
      },
    );
  }

  List<_Orb> _generateOrbs(Size size) {
    final rand = math.Random(42);
    final colors = kAuroraGradient.colors;

    // Adapt orb count to size (increase for stronger visibility)
    final baseCount = size.shortestSide < 500
        ? 10
        : (size.shortestSide < 900 ? 14 : 18);

    return List.generate(baseCount, (i) {
      final color = colors[i % colors.length];
      final center = Offset(
        rand.nextDouble() * size.width,
        rand.nextDouble() * size.height,
      );
      final radius = lerpDouble(
        60,
        size.shortestSide * 0.22,
        rand.nextDouble(),
      )!;
      final speed = lerpDouble(
        1.2,
        2.4,
        rand.nextDouble(),
      )!; // slightly faster again
      final alpha = lerpDouble(0.16, 0.28, rand.nextDouble())!;
      final direction = rand.nextDouble() * 2 * math.pi;
      final wobble = rand.nextDouble() * 1.0 + 0.3;

      return _Orb(
        color: color.withValues(alpha: alpha),
        center: center,
        radius: radius,
        speed: speed,
        direction: direction,
        wobble: wobble,
        bounds: size,
      );
    });
  }
}

class _BokehPainter extends CustomPainter {
  final double time; // 0..1 repeating
  final List<_Orb> orbs;

  _BokehPainter({required this.time, required this.orbs});

  @override
  void paint(Canvas canvas, Size size) {
    // Dark base fill for better bokeh visibility
    final bgPaint = Paint()..color = const Color(0xFF0F1115);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final outerPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    final innerPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    for (final orb in orbs) {
      final pos = orb.positionAt(time);
      // Outer soft glow
      outerPaint.color = orb.color;
      canvas.drawCircle(pos, orb.radius, outerPaint);
      // Inner brighter core to make the bokeh stand out in screenshots
      innerPaint.color = orb.color.withValues(
        alpha: (orb.alpha + 0.22).clamp(0.0, 0.6),
      );
      canvas.drawCircle(pos, orb.radius * 0.45, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BokehPainter oldDelegate) {
    return oldDelegate.time != time || !listEquals(oldDelegate.orbs, orbs);
  }
}

class _Orb {
  final Color color;
  final Offset center;
  final double radius;
  final double speed; // units per cycle
  final double direction; // radians
  final double wobble; // amplitude factor
  final Size bounds;

  const _Orb({
    required this.color,
    required this.center,
    required this.radius,
    required this.speed,
    required this.direction,
    required this.wobble,
    required this.bounds,
  });

  double get alpha => color.a / 255.0;

  Offset positionAt(double t) {
    // Seamless loop: use periodic Lissajous-like path that matches at t=0 and t=1
    // t in [0,1]; convert to angle for periodic motion
    final angle = 2 * math.pi * t * speed;
    final driftX = math.cos(direction) * 60.0 * math.sin(angle);
    final driftY = math.sin(direction) * 60.0 * math.cos(angle);

    // Additional periodic wobble that also loops perfectly
    final wobbleX =
        math.cos(2 * math.pi * t * (1.0 + wobble) + direction) * 14.0;
    final wobbleY =
        math.sin(2 * math.pi * t * (1.0 + wobble) + direction) * 14.0;

    final x = center.dx + driftX + wobbleX;
    final y = center.dy + driftY + wobbleY;

    return Offset(x, y);
  }
}

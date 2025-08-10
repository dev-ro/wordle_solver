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
      duration: const Duration(seconds: 60),
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
          color: Colors.white,
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

    // Adapt orb count to size
    final baseCount = size.shortestSide < 500
        ? 7
        : (size.shortestSide < 900 ? 10 : 12);

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
      final speed = lerpDouble(0.6, 1.2, rand.nextDouble())!; // very slow
      final alpha = lerpDouble(0.08, 0.16, rand.nextDouble())!;
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
    // White base fill to ensure a clean background
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Offset.zero & size, bgPaint);

    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);

    for (final orb in orbs) {
      final pos = orb.positionAt(time);
      paint.color = orb.color;
      canvas.drawCircle(pos, orb.radius, paint);
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

  Offset positionAt(double t) {
    // Slow drift with slight circular wobble
    final driftX = math.cos(direction) * speed * 40.0 * t;
    final driftY = math.sin(direction) * speed * 40.0 * t;
    final wobbleX = math.cos(2 * math.pi * t + direction) * wobble * 10.0;
    final wobbleY = math.sin(2 * math.pi * t + direction) * wobble * 10.0;

    var x = center.dx + driftX + wobbleX;
    var y = center.dy + driftY + wobbleY;

    // Wrap around to avoid hitting edges visibly
    if (x < -radius) x = bounds.width + radius;
    if (x > bounds.width + radius) x = -radius;
    if (y < -radius) y = bounds.height + radius;
    if (y > bounds.height + radius) y = -radius;

    return Offset(x, y);
  }
}

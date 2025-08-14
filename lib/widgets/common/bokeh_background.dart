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

    // Adapt orb count to size with a lighter default for all platforms
    final baseCount = size.shortestSide < 500
        ? 6
        : (size.shortestSide < 900 ? 10 : 12);

    // Use a jittered grid layout to avoid visible clustering
    final cols = (math.sqrt(baseCount)).ceil();
    final rows = (baseCount / cols).ceil();
    final cellW = size.width / cols;
    final cellH = size.height / rows;

    final orbs = <_Orb>[];
    for (int i = 0; i < baseCount; i++) {
      final r = i ~/ cols;
      final c = i % cols;

      final jitterX = (rand.nextDouble() - 0.5) * cellW * 0.6;
      final jitterY = (rand.nextDouble() - 0.5) * cellH * 0.6;

      final center = Offset(
        (c + 0.5) * cellW + jitterX,
        (r + 0.5) * cellH + jitterY,
      );

      final color = colors[i % colors.length];
      final radius = lerpDouble(
        48,
        size.shortestSide * 0.18,
        rand.nextDouble(),
      )!;
      final alpha = lerpDouble(0.10, 0.20, rand.nextDouble())!;

      // Seamless periodic motion parameters (integer frequencies)
      final freqX = 1 + rand.nextInt(3); // 1..3
      final freqY = 1 + rand.nextInt(3); // 1..3
      final phaseX = rand.nextDouble() * 2 * math.pi;
      final phaseY = rand.nextDouble() * 2 * math.pi;
      final amplitude = lerpDouble(40, 85, rand.nextDouble())!;
      final wobbleAmp = lerpDouble(8, 16, rand.nextDouble())!;
      final wobbleFreq = 2 + rand.nextInt(3); // 2..4
      final wobblePhase = rand.nextDouble() * 2 * math.pi;

      orbs.add(
        _Orb(
          color: color.withValues(alpha: alpha),
          center: center,
          radius: radius,
          freqX: freqX,
          freqY: freqY,
          phaseX: phaseX,
          phaseY: phaseY,
          amplitude: amplitude,
          wobbleAmp: wobbleAmp,
          wobbleFreq: wobbleFreq,
          wobblePhase: wobblePhase,
          bounds: size,
        ),
      );
    }

    return orbs;
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
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (final orb in orbs) {
      final pos = orb.positionAt(time);
      // Outer soft glow (softer than before)
      outerPaint.color = orb.color;
      canvas.drawCircle(pos, orb.radius, outerPaint);
      // Subtle ring to add structure without a harsh solid core
      ringPaint.color = orb.color.withValues(
        alpha: (orb.alpha * 0.6).clamp(0.0, 0.24),
      );
      canvas.drawCircle(pos, orb.radius * 0.52, ringPaint);
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
  final int freqX;
  final int freqY;
  final double phaseX;
  final double phaseY;
  final double amplitude;
  final double wobbleAmp;
  final int wobbleFreq;
  final double wobblePhase;
  final Size bounds;

  const _Orb({
    required this.color,
    required this.center,
    required this.radius,
    required this.freqX,
    required this.freqY,
    required this.phaseX,
    required this.phaseY,
    required this.amplitude,
    required this.wobbleAmp,
    required this.wobbleFreq,
    required this.wobblePhase,
    required this.bounds,
  });

  double get alpha => color.a / 255.0;

  Offset positionAt(double t) {
    // Perfectly seamless periodic motion; t in [0,1]
    final dx = amplitude * math.cos(2 * math.pi * (freqX * t) + phaseX);
    final dy = amplitude * math.sin(2 * math.pi * (freqY * t) + phaseY);

    final wx =
        wobbleAmp * math.cos(2 * math.pi * (wobbleFreq * t) + wobblePhase);
    final wy =
        wobbleAmp *
        math.sin(2 * math.pi * (wobbleFreq * t) + wobblePhase + math.pi / 2);

    return Offset(center.dx + dx + wx, center.dy + dy + wy);
  }
}

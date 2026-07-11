import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.logged, required this.target, this.size = 180});
  final int logged;
  final int target;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(target == 0 ? 0 : (logged / target).clamp(0, 1).toDouble()),
          child: Center(
            child: Text('$logged / $target',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: kInk)),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction);
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 10;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = kInk.withValues(alpha: 0.10);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = kCoral;
    canvas.drawCircle(center, radius, track);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), -pi / 2,
        2 * pi * fraction, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}

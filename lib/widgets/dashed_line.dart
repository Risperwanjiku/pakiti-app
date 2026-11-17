import 'dart:math' as math;

import 'package:flutter/material.dart';

// Flutter has no dashed border, so the trip line and the history draw their own.
class DashedLine extends StatelessWidget {
  const DashedLine({super.key, required this.color, this.axis = Axis.horizontal});

  final Color color;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: axis == Axis.horizontal
          ? const Size(double.infinity, 2)
          : const Size(2, double.infinity),
      painter: _DashPainter(color, axis),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.axis);

  final Color color;
  final Axis axis;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    final across = axis == Axis.horizontal;
    final length = across ? size.width : size.height;

    for (var start = 0.0; start < length; start += 7) {
      final end = math.min(start + 4, length);

      canvas.drawLine(
        across ? Offset(start, size.height / 2) : Offset(size.width / 2, start),
        across ? Offset(end, size.height / 2) : Offset(size.width / 2, end),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.axis != axis;
  }
}
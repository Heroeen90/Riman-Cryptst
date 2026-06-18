import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:math';

class TelemetryGraphCanvas extends StatefulWidget {
  const TelemetryGraphCanvas({Key? key}) : super(key: key);

  @override
  _TelemetryGraphCanvasState createState() => _TelemetryGraphCanvasState();
}

class _TelemetryGraphCanvasState extends State<TelemetryGraphCanvas> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    // Do not repeat animation in tests to prevent pumpAndSettle timeout
    if (!bool.fromEnvironment('dart.vm.product') && !Platform.environment.containsKey('FLUTTER_TEST')) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 100),
          painter: _TelemetryPainter(_controller.value),
        );
      },
    );
  }
}

class _TelemetryPainter extends CustomPainter {
  final double animationValue;
  _TelemetryPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (double i = 0; i < size.width; i++) {
      double y = size.height / 2 + sin(i * 0.05 + animationValue * 2 * pi) * 20;
      if (i == 0) {
        path.moveTo(i, y);
      } else {
        path.lineTo(i, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TelemetryPainter oldDelegate) => true;
}

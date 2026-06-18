import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';

class VisualFilterChips extends StatefulWidget {
  final double frequency; // Scaled by parent
  const VisualFilterChips({Key? key, this.frequency = 1.0}) : super(key: key);

  @override
  _VisualFilterChipsState createState() => _VisualFilterChipsState();
}

class _VisualFilterChipsState extends State<VisualFilterChips> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<String> _filters = ['Secure', 'Encrypted', 'Locked', 'Monitor'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
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
    return Column(
      children: [
        Wrap(
          spacing: 8,
          children: _filters.map((f) => FilterChip(label: Text(f), onSelected: (_) {})).toList(),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            size: const Size(double.infinity, 50),
            painter: _WaveformPainter(_controller.value, widget.frequency),
          ),
        ),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final double animationValue;
  final double frequency;
  _WaveformPainter(this.animationValue, this.frequency);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.cyan..strokeWidth = 2..style = PaintingStyle.stroke;
    final path = Path();
    for (double i = 0; i < size.width; i++) {
        double y = size.height / 2 + sin(i * 0.05 * frequency + animationValue * 2 * pi) * 10;
        i == 0 ? path.moveTo(i, y) : path.lineTo(i, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => true;
}

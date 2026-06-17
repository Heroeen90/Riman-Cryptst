import 'package:flutter/material.dart';

class DeceptionRadarWidget extends StatelessWidget {
  const DeceptionRadarWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyan.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          'DECEPTION GRID ACTIVE',
          style: TextStyle(color: Colors.cyan[200], fontFamily: 'JetBrains Mono'),
        ),
      ),
    );
  }
}

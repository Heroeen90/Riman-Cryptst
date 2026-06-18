import 'package:flutter/material.dart';

class DynamicThemePanel extends StatefulWidget {
  final Function(Color) onColorChanged;
  final Color currentColor;

  const DynamicThemePanel({
    Key? key,
    required this.onColorChanged,
    required this.currentColor,
  }) : super(key: key);

  @override
  _DynamicThemePanelState createState() => _DynamicThemePanelState();
}

class _DynamicThemePanelState extends State<DynamicThemePanel> {
  final List<Color> _colors = [
    Colors.cyan,
    Colors.purple,
    Colors.amber,
    Colors.teal,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _colors.map((color) {
          return GestureDetector(
            onTap: () => widget.onColorChanged(color),
            child: CircleAvatar(
              backgroundColor: color,
              radius: 20,
              child: widget.currentColor == color
                  ? const Icon(Icons.check, color: Colors.white)
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

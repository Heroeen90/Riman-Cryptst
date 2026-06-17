import 'package:flutter/material.dart';

class SmartCategorySelector extends StatefulWidget {
  final String filePath;
  const SmartCategorySelector({Key? key, required this.filePath}) : super(key: key);

  @override
  _SmartCategorySelectorState createState() => _SmartCategorySelectorState();
}

class _SmartCategorySelectorState extends State<SmartCategorySelector> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<String> _categories = ['Documents', 'Media', 'System'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
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
          children: _categories.map((c) => ChoiceChip(
            label: Text(c),
            selected: false,
            onSelected: (_) {},
          )).toList(),
        ),
        FadeTransition(
          opacity: _controller,
          child: const Text('Erasing Original...', style: TextStyle(color: Colors.rose)),
        ),
      ],
    );
  }
}

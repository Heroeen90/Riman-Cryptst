import 'package:flutter/material.dart';

class FloatingActionDock extends StatefulWidget {
  final List<Widget> actions;
  const FloatingActionDock({Key? key, required this.actions}) : super(key: key);

  @override
  _FloatingActionDockState createState() => _FloatingActionDockState();
}

class _FloatingActionDockState extends State<FloatingActionDock> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isExpanded) ...widget.actions.map((a) => Padding(padding: const EdgeInsets.only(bottom: 8), child: ScaleTransition(scale: _controller, child: a))),
        FloatingActionButton(
          backgroundColor: Colors.cyan,
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
              _isExpanded ? _controller.forward() : _controller.reverse();
            });
          },
          child: Icon(_isExpanded ? Icons.close : Icons.add, color: Colors.white),
        ),
      ],
    );
  }
}

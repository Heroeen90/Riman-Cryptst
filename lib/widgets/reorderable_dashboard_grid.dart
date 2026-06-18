import 'package:flutter/material.dart';

class ReorderableDashboardGrid extends StatefulWidget {
  const ReorderableDashboardGrid({Key? key}) : super(key: key);

  @override
  _ReorderableDashboardGridState createState() => _ReorderableDashboardGridState();
}

class _ReorderableDashboardGridState extends State<ReorderableDashboardGrid> {
  final List<String> _items = ['Telemetry', 'Storage', 'Security', 'Hardware'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: ReorderableListView(
        children: _items.map((item) {
          return Card(
            key: ValueKey(item),
            color: const Color(0xFF334155),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.blueGrey, width: 1),
            ),
            child: ListTile(
              title: Text(item, style: const TextStyle(color: Colors.white, fontFamily: 'JetBrains Mono')),
              trailing: const Icon(Icons.drag_handle, color: Colors.cyan),
            ),
          );
        }).toList(),
        onReorder: (int oldIndex, int newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final String item = _items.removeAt(oldIndex);
            _items.insert(newIndex, item);
          });
        },
      ),
    );
  }
}

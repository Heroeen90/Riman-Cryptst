import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class BatchShareQueueView extends StatelessWidget {
  final List<SharedMediaFile> files;

  const BatchShareQueueView({Key? key, required this.files}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return Card(
          color: const Color(0xFF1E293B),
          child: ListTile(
            leading: const Icon(Icons.insert_drive_file, color: Colors.cyan),
            title: Text(file.path.split('/').last, style: const TextStyle(color: Colors.white)),
            subtitle: Text('Size: Unknown', style: const TextStyle(color: Colors.blueGrey)),
          ),
        );
      },
    );
  }
}

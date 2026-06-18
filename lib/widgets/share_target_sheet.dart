import 'package:flutter/material.dart';

/// ShareTargetSheet - displays received shared file information
class ShareTargetSheet extends StatelessWidget {
  final String file;

  const ShareTargetSheet({Key? key, required this.file}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF030712),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shared File Received',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            file,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
              ),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

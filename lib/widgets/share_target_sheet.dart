import 'package:flutter/material.dart';
import '../utils/share_intent_service.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ShareTargetSheet extends StatefulWidget {
  final SharedMediaFile file;
  const ShareTargetSheet({Key? key, required this.file}) : super(key: key);

  @override
  _ShareTargetSheetState createState() => _ShareTargetSheetState();
}

class _ShareTargetSheetState extends State<ShareTargetSheet> {
  double _progress = 0.0;
  final List<String> _vaults = ['Vault Alpha', 'Vault Beta', 'Vault Gamma'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Secure Share Target', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          CircularProgressIndicator(value: _progress, color: Colors.cyan),
          const SizedBox(height: 16),
          ..._vaults.map((v) => ListTile(
            title: Text(v, style: const TextStyle(color: Colors.white)),
            onTap: () async {
              setState(() => _progress = 0.5);
              // In production, encrypt and map to vault
              await Future.delayed(const Duration(seconds: 2));
              await ShareIntentService.shredFile(widget.file.path);
              Navigator.pop(context);
            },
          )).toList(),
        ],
      ),
    );
  }
}

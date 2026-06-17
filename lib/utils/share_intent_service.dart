import 'dart:io';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ShareIntentService {
  static void initialize(Function(SharedMediaFile) onFileReceived) {
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) onFileReceived(value.first);
      ReceiveSharingIntent.instance.reset();
    });

    ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) onFileReceived(value.first);
    });
  }

  static Future<void> shredFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final length = await file.length();
      final raf = await file.open(mode: FileMode.writeOnly);
      await raf.writeFrom(List.generate(length, (index) => 0));
      await raf.close();
      await file.delete();
    }
  }
}

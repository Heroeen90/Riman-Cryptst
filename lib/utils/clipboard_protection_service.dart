import 'package:flutter/services.dart';
import 'dart:async';

class ClipboardProtectionService {
  static Timer? _timer;

  static void startMonitoring() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null && data.text!.isNotEmpty) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
    });
  }

  static void stopMonitoring() {
    _timer?.cancel();
  }
}

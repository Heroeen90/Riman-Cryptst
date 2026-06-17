import 'package:flutter_windowmanager/flutter_windowmanager.dart';

class WindowSecurityService {
  static Future<void> secureScreen() async {
    // Adding the FLAG_SECURE prevents screenshots and screen recordings
    await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  }
}

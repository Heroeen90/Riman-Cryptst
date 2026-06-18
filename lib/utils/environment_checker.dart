import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

class EnvironmentChecker {
  static Future<bool> isTampered() async {
    bool jailbroken = await FlutterJailbreakDetection.jailbroken;
    return jailbroken;
  }
}

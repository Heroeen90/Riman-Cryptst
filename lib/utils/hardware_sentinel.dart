import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

class HardwareSentinel {
  static Future<Map<String, dynamic>> getHardwareMetrics() async {
    final battery = Battery();
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    return {
      'batteryLevel': await battery.batteryLevel,
      'isCharging': await battery.batteryState == BatteryState.charging,
      'deviceModel': androidInfo.model,
    };
  }
}

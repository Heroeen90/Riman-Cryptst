import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';

class AndroidKeystoreService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> saveKey(String key, String value) async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final hardwareId = androidInfo.id;
    await _storage.write(key: '${key}_$hardwareId', value: value);
  }

  static Future<String?> getKey(String key) async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final hardwareId = androidInfo.id;
    return await _storage.read(key: '${key}_$hardwareId');
  }
}

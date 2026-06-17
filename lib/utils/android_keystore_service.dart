import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AndroidKeystoreService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static Future<void> saveKey(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  static Future<String?> getKey(String key) async {
    return await _storage.read(key: key);
  }
}

import 'dart:collection';

class EncryptedCache {
  static final Map<String, String> _cache = HashMap();

  static void store(String key, String value) {
    _cache[key] = value;
  }

  static String? retrieve(String key) => _cache[key];
}

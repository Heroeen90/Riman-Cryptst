import 'package:encrypt/encrypt.dart' as encrypt;

class CryptoEngine {
  static String encryptAES(String plainText, String key256) {
    final key = encrypt.Key.fromUtf8(key256.padRight(32, '0').substring(0, 32));
    final iv = encrypt.IV.fromSecureRandom(12); // GCM standard is 12 bytes
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  static String decryptAES(String encryptedData, String key256) {
    final parts = encryptedData.split(':');
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
    final key = encrypt.Key.fromUtf8(key256.padRight(32, '0').substring(0, 32));
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.gcm));
    
    return encrypter.decrypt(encrypted, iv: iv);
  }
}

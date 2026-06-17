import 'package:encrypt/encrypt.dart' as encrypt;

class InMemoryCryptoWrapper {
  final encrypt.Key _key;
  final encrypt.IV _iv;
  final encrypt.Encrypter _encrypter;

  InMemoryCryptoWrapper(String keyString)
      : _key = encrypt.Key.fromUtf8(keyString.padRight(32, '0').substring(0, 32)),
        _iv = encrypt.IV.fromLength(16),
        _encrypter = encrypt.Encrypter(encrypt.AES(encrypt.Key.fromUtf8(keyString.padRight(32, '0').substring(0, 32))));

  String encryptData(String data) {
    return _encrypter.encrypt(data, iv: _iv).base64;
  }

  String decryptData(String encryptedData) {
    return _encrypter.decrypt(encrypt.Encrypted.fromBase64(encryptedData), iv: _iv);
  }
}

import 'package:flutter/services.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class SecurePlatformChannel {
  static const _channel = MethodChannel('com.riman.cryptst/secure_channel');
  final _key = encrypt.Key.fromLength(32);
  final _iv = encrypt.IV.fromLength(16);

  Future<dynamic> invokeSecureMethod(String method, Map<String, dynamic> args) async {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));
    final encodedArgs = base64.encode(utf8.encode(args.toString())); // Simplified
    final encryptedArgs = encrypter.encrypt(encodedArgs, iv: _iv).base64;

    return await _channel.invokeMethod(method, {'data': encryptedArgs});
  }
}
import 'dart:convert';

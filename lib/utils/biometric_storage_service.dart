import 'package:local_auth/local_auth.dart';
import 'package:flutter/material.dart';

class BiometricStorageService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

    if (!canAuthenticate) return false;

    try {
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access the application keys pool',
        options: const AuthenticationOptions(biometricOnly: true),
      );
    } catch (e) {
      debugPrint('Biometric error: $e');
      return false;
    }
  }
}

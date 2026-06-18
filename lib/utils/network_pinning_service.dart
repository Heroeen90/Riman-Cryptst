import 'package:dio/dio.dart';
import 'package:http_certificate_pinning/http_certificate_pinning.dart';

class NetworkPinningService {
  static Future<void> checkConnection(String url, String fingerprint) async {
    try {
      await HttpCertificatePinning.check(
        serverURL: url,
        headerHttp: {"accept": "application/json"},
        sha: SHA.SHA256,
        allowedSHAFingerprints: [fingerprint],
        timeout: 50,
      );
    } catch (e) {
      throw Exception('Certificate pinning validation failed: $e');
    }
  }
}

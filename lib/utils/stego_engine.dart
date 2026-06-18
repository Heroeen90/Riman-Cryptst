import 'dart:typed_data';

class StegoEngine {
  static Uint8List encode(String hexToken, Uint8List coverBytes) {
    // Basic steganography simulation by embedding hex in the first N bytes
    Uint8List data = Uint8List.fromList(coverBytes);
    List<int> tokenBytes = hexToken.codeUnits;
    for (int i = 0; i < tokenBytes.length && i < data.length; i++) {
      data[i] = (data[i] & 0xFE) | (tokenBytes[i] % 2);
    }
    return data;
  }

  static String decode(Uint8List encodedBytes) {
    // Extract data from the LSB
    List<int> result = [];
    for (int i = 0; i < 32 && i < encodedBytes.length; i++) {
        result.add(encodedBytes[i] & 0x01);
    }
    return result.map((e) => e.toString()).join();
  }
}

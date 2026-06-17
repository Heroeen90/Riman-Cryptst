import 'dart:typed_data';

class RuntimeObfuscator {
  static Uint8List obfuscateState(Uint8List state) {
    // Mimic memory mapping obfuscation
    final obfuscated = Uint8List.fromList(state);
    for(int i = 0; i < obfuscated.length; i++) {
      obfuscated[i] = obfuscated[i] ^ 0x5A;
    }
    return obfuscated;
  }
}

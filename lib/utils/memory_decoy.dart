import 'dart:math';

class MemoryDecoy {
  static List<int> generateObfuscationBuffer(int size) {
    final random = Random();
    return List.generate(size, (_) => random.nextInt(256));
  }
}

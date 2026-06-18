import 'package:flutter/material.dart';

class MemoryShredderService extends ChangeNotifier {
  static final MemoryShredderService _instance = MemoryShredderService._internal();
  factory MemoryShredderService() => _instance;
  MemoryShredderService._internal();

  void shredMemory() {
    debugPrint('Volatile memory shredding initiated.');
    // Simulated clearing of volatile data
    notifyListeners();
  }
}

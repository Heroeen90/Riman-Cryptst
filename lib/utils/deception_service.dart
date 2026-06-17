import 'package:flutter/material.dart';

class DeceptionService extends ChangeNotifier {
  static final DeceptionService _instance = DeceptionService._internal();
  factory DeceptionService() => _instance;
  DeceptionService._internal();

  bool _isActive = false;
  bool get isActive => _isActive;

  void toggleDeception(bool active) {
    _isActive = active;
    notifyListeners();
  }
}

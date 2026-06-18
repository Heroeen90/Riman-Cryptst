import 'package:flutter/foundation.dart';

/// VaultService - manages application security lock state and notifications
class VaultService extends ChangeNotifier {
  static final VaultService _instance = VaultService._internal();

  factory VaultService() {
    return _instance;
  }

  VaultService._internal();

  bool _isLocked = false;

  bool get isLocked => _isLocked;

  void setLocked(bool locked) {
    if (_isLocked != locked) {
      _isLocked = locked;
      notifyListeners();
    }
  }

  void lock() {
    setLocked(true);
  }

  void unlock() {
    setLocked(false);
  }
}

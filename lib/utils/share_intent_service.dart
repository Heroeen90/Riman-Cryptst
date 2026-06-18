import 'dart:async';

/// ShareIntentService - handles incoming file sharing from other applications
class ShareIntentService {
  static final StreamController<String> _shareStream =
      StreamController<String>.broadcast();

  static StreamSubscription<String>? _subscription;
  static Function(String)? _callback;

  /// Initialize share intent listener
  static void initialize(Function(String) onFileReceived) {
    _callback = onFileReceived;
  }

  /// Emit a file path to the share stream
  static void emitFile(String filePath) {
    _shareStream.add(filePath);
    _callback?.call(filePath);
  }

  /// Get the share stream for listening to incoming files
  static Stream<String> get shareStream => _shareStream.stream;

  /// Dispose resources
  static void dispose() {
    _subscription?.cancel();
    _shareStream.close();
  }
}

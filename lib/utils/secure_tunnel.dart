import 'dart:async';

class SecureTunnel {
  final _controller = StreamController<String>.broadcast();

  Stream<String> get pipe => _controller.stream;

  void send(String data) {
    _controller.add(data);
  }

  void dispose() {
    _controller.close();
  }
}

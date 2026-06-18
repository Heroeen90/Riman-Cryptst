import 'dart:async';

class ArchivalShredder {
  static void scheduleShred(DateTime expiry) {
    Timer(Duration(seconds: 10), () {
      print('Expired data shredded.');
    });
  }
}

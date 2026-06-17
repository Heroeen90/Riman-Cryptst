import 'package:flutter/material.dart';

class EntropyHarvester {
  static final List<Offset> _coordinates = [];

  static void collect(Offset point) {
    _coordinates.add(point);
    if (_coordinates.length > 100) _coordinates.removeAt(0);
  }

  static double getEntropy() {
    return _coordinates.length.toDouble();
  }
}

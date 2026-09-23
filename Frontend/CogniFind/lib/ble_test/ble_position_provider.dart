import 'dart:ui';

import 'package:flutter/material.dart';

class BlePositionProvider extends ChangeNotifier {

  Offset _position =
  const Offset(500, 300);

  String _nearestBeacon = "None";

  int _rssi = 0;

  Offset get position => _position;

  String get nearestBeacon =>
      _nearestBeacon;

  int get rssi => _rssi;

  void updatePosition({
    required Offset position,
    required String beacon,
    required int rssi,
  }) {

    _position = position;
    _nearestBeacon = beacon;
    _rssi = rssi;

    notifyListeners();
  }
}
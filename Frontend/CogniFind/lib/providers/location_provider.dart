import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:cognifind/core/config/demo_config.dart';
import 'package:cognifind/core/data/campus_boundary.dart';

/// Provides the user's current location as a continuously updated stream.
///
/// This centralizes all Geolocator usage so widgets and services can read
/// `currentLocation` without making their own location calls.
class LocationProvider extends ChangeNotifier {
  LocationProvider();

  LatLng? _currentLocation;
  double? _currentHeading;
  StreamSubscription<Position>? _positionSub;

  LatLng? get currentLocation => _currentLocation;

  /// Direction of travel in degrees clockwise from north, or null when it
  /// isn't known yet. Mirrors `Position.heading` from the GPS stream; the
  /// outdoor map uses it to orient the camera the way the user is walking.
  double? get currentHeading => _currentHeading;

  /// Demo mode: inject a simulated position in place of a GPS fix. This is the
  /// SAME assignment the Geolocator stream below performs, so every consumer
  /// (route progression, instruction banner, camera, blue dot) is reading
  /// ordinary `currentLocation` and cannot tell the two apart.
  void injectDemoPosition(LatLng position, {double? heading}) {
    _currentLocation = position;
    if (heading != null) _currentHeading = heading;
    notifyListeners();
  }

  /// Request permissions (if needed) and start listening for location updates.
  Future<void> initializeLocation() async {
    /// DEMO MODE — no GPS hardware is consulted. Seeding the campus gate gives
    /// the map and the route source a sane starting fix; from there every
    /// update comes from [DemoPositionDriver] via [injectDemoPosition].
    if (kDemoNavigationMode) {
      _currentLocation = campusGate;
      notifyListeners();
      return;
    }

    try {
      final permission = await _ensurePermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        // Permissions denied; keep location null.
        return;
      }

      // Try to get an initial fix quickly.
      Position? initial;
      try {
        initial = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
      } catch (_) {
        // Best‑effort only; it's fine if this fails – the stream will update.
      }

      if (initial != null) {
        _currentLocation =
            LatLng(initial.latitude, initial.longitude);
        _currentHeading = initial.heading;
        notifyListeners();
      }

      // Subscribe to continuous updates.
      _positionSub?.cancel();
      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 2, // meters
        ),
      ).listen((position) {
        _currentLocation =
            LatLng(position.latitude, position.longitude);
        _currentHeading = position.heading;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('LocationProvider.initializeLocation error: $e');
    }
  }

  Future<LocationPermission> _ensurePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}


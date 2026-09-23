import 'dart:async';

import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';

import '../models/beacon_scan.dart';

import '../services/beacon_service.dart';

import '../services/location_api_service.dart';


import 'package:cognifind/indoor_engine/models/indoor_position.dart';

import 'package:cognifind/indoor_engine/providers/indoor_navigation_provider.dart';

import 'package:cognifind/providers/navigation_provider.dart';

import 'package:cognifind/core/enums/navigation_mode.dart';

import 'package:cognifind/core/data/campus_buildings.dart';

import 'package:cognifind/models/navigation/building.dart';

import 'package:cognifind/features/navigation/transition/auto_transition_evaluator.dart';

import 'package:cognifind/core/config/demo_config.dart';

class RealtimePositionProvider
    extends ChangeNotifier {

  /// Building id sent with every /api/location poll.
  ///
  /// Intentionally FIXED, not building-aware: the realtime engine has no
  /// reliable per-building signal at poll time. Polling runs continuously and
  /// independently of navigation state (so [NavigationProvider.selectedBuildingId]
  /// — a String like "AB-IV", and null when not navigating — is neither the
  /// right type nor reliably set here), the backend identifies the physical
  /// building from the reported beacon ids, and the /api/location RESPONSE
  /// carries no building id for the frontend to key off (see LocationResponse).
  ///
  /// Isolated as a single named constant so it can be replaced with a
  /// building-aware value the moment the backend exposes building information
  /// at this layer. Do NOT invent a String→int mapping here.
  static const int _kLocationBuildingId = 1;

  IndoorNavigationProvider
  indoorNavigationProvider;

  /// Injected via the proxy (see app.dart). Used read-only to feed the
  /// auto-transition evaluator; this provider never mutates navigation
  /// lifecycle itself — it only calls navigationProvider.evaluateAutoTransition.
  NavigationProvider? navigationProvider;

  late final BeaconService
  _beaconService;

  late final LocationApiService
  _locationApiService;

  /// =====================================
  /// LIVE BEACONS
  /// =====================================

  List<BeaconScan>
  _nearbyBeacons = [];

  List<BeaconScan>
  get nearbyBeacons =>
      _nearbyBeacons;

  /// =====================================
  /// BACKEND-OWNED INDOOR CONTEXT
  /// =====================================
  ///
  /// The latest backend truth about whether the user is indoors and, when so,
  /// which indoor node they are nearest. Surfaced read-only so the routing
  /// decision can distinguish Case 2 (already inside the destination building →
  /// route indoors directly from [currentIndoorNode]) from Case 1 (outdoors →
  /// hybrid). Never estimated here — mirrored straight from the /api/location
  /// response.

  bool _isIndoor = false;

  bool get isIndoor => _isIndoor;

  String? _currentIndoorNode;

  String? get currentIndoorNode => _currentIndoorNode;

  /// =====================================
  /// TIMER
  /// =====================================

  Timer? _pollingTimer;

  /// TEMP TRACE state (observation only — no behavior).
  DateTime? _lastPollAt;
  bool _wasIndoor = false;
  int _pollSeq = 0;
  double? _prevX;
  double? _prevY;
  String? _prevNode;

  RealtimePositionProvider({
    required this.indoorNavigationProvider,
  }) {

    // ── DEMO MODE: skip BLE scanning and backend polling entirely.
    // The DemoPositionDriver feeds IndoorNavigationProvider directly. ──
    if (kDemoNavigationMode) {
      _locationApiService = LocationApiService();
      return;
    }

    debugPrint(
      "REALTIME PROVIDER CREATED",
    );

    debugPrint(
      "RealtimePositionProvider STARTED",
    );

    _locationApiService =
        LocationApiService();

    _beaconService =
        BeaconService(

          onReadingsUpdated:
              (readings) {

            debugPrint(
              "BLE CALLBACK RUNNING",
            );

            _nearbyBeacons =
                readings;

            notifyListeners();
          },
        );

    _beaconService.start();

    /// START REALTIME ENGINE
    startRealtimeTracking();
  }

  /// =====================================
  /// TEMP POSITIONING
  /// =====================================


  void updateIndoorProvider(
      IndoorNavigationProvider provider,
      ) {
    indoorNavigationProvider = provider;
  }

  void updateNavigationProvider(
      NavigationProvider provider,
      ) {
    navigationProvider = provider;
  }
  /// =====================================
  /// REALTIME ENGINE
  /// =====================================

  void startRealtimeTracking() {

    _pollingTimer?.cancel();

    _pollingTimer =
        Timer.periodic(

          const Duration(
            seconds: 1,
          ),

              (_) {

            _sendLocationUpdate();
          },
        );

    debugPrint(
      "[POLL] started (cadence=1s)",
    );
  }

  void stopRealtimeTracking() {

    _pollingTimer?.cancel();

    debugPrint(
      "[POLL] stopped",
    );
  }

  /// =====================================
  /// APP-LIFECYCLE PAUSE / RESUME
  /// =====================================
  ///
  /// Stops/restarts BLE scanning and the backend polling timer when the app
  /// is backgrounded/foregrounded, to avoid background battery drain and
  /// platform background-execution restrictions.
  ///
  /// GPS / outdoor location (LocationProvider) is intentionally NOT affected.
  /// The [_isPaused] guard makes both calls idempotent and ensures a
  /// launch-time "resumed" event (with no prior pause) is a no-op, so the
  /// scan + timer started in the constructor are never duplicated.

  bool _isPaused = false;

  void pauseRealtimeTracking() {

    if (_isPaused) return;

    _isPaused = true;

    stopRealtimeTracking();

    _beaconService.stop();

    debugPrint(
      "[POLL] paused (REALTIME TRACKING PAUSED)",
    );
  }

  void resumeRealtimeTracking() {

    if (!_isPaused) return;

    _isPaused = false;

    _beaconService.start();

    startRealtimeTracking();

    debugPrint(
      "[POLL] resumed (REALTIME TRACKING RESUMED)",
    );
  }

  /// =====================================
  /// BACKEND UPDATE
  /// =====================================

  Future<void>
  _sendLocationUpdate() async {

    /// TEMP TRACE: actual poll cadence (should be ~1000ms).
    final now = DateTime.now();
    final deltaMs = _lastPollAt == null
        ? 0
        : now.difference(_lastPollAt!).inMilliseconds;
    _lastPollAt = now;
    _pollSeq++;
    debugPrint(
      "[POLL] #$_pollSeq tick (Δ=${deltaMs}ms)",
    );

    try {

      final position =
      await Geolocator
          .getCurrentPosition();

      /// Feed the auto-transition evaluator with this fresh fix (runs
      /// regardless of the backend call below). Telemetry only — firing is
      /// gated OFF inside NavigationProvider.
      _feedAutoTransition(position);

      final response =
      await _locationApiService
          .fetchRealtimeLocation(

        buildingId: _kLocationBuildingId,

        latitude:
        position.latitude,

        longitude:
        position.longitude,

        accuracy:
        position.accuracy,

        speed:
        position.speed,

        heading:
        position.heading,

        beacons:
        _nearbyBeacons,
      );

      /// Observational telemetry only (single line for easy log parsing).
      /// No behavior/rendering change — read during field calibration to
      /// study confidence collapse, node oscillation, floor stability, and
      /// map-matching readiness.
      final dx = _prevX != null ? (response.x - _prevX!).abs() : 0.0;
      final dy = _prevY != null ? (response.y - _prevY!).abs() : 0.0;
      final nodeChanged = _prevNode != null && _prevNode != response.nearestNode;
      final ts = now.toIso8601String().substring(11, 23); // HH:mm:ss.SSS
      debugPrint(
        "[LOCATION RESPONSE]"
            " t=$ts"
            " #$_pollSeq"
            " x=${response.x}"
            " y=${response.y}"
            " Δx=${dx.toStringAsFixed(1)}"
            " Δy=${dy.toStringAsFixed(1)}"
            " floor=${response.floor}"
            " confidence=${response.confidence}"
            " nearestNode=${response.nearestNode}"
            " nodeChanged=$nodeChanged"
            " isIndoor=${response.isIndoor}",
      );

      /// ── TEMP TRACE: jump correlation ──
      /// When position jumps > 10 units, dump the current beacon state so
      /// we can see if RSSI changed right before the jump.
      if (_prevX != null && (dx > 10 || dy > 10)) {
        final minew = _nearbyBeacons
            .where((b) => b.id.startsWith("ER-BLEV2.3"))
            .toList();
        debugPrint(
          "⚠ [JUMP DETECTED]"
          " t=$ts"
          " #$_pollSeq"
          " Δx=${dx.toStringAsFixed(1)}"
          " Δy=${dy.toStringAsFixed(1)}"
          " prevNode=$_prevNode"
          " newNode=${response.nearestNode}"
          " confidence=${response.confidence}"
          " minewCount=${minew.length}"
          " minew=${minew.map((b) => '${b.id}(${b.rssi})').join(', ')}",
        );
      }

      _prevX = response.x;
      _prevY = response.y;
      _prevNode = response.nearestNode;

      /// TEMP TRACE: the moment indoor realtime becomes active (isIndoor
      /// flips false -> true). Polling itself is always running; this marks
      /// when the backend starts returning an indoor fix.
      if (response.isIndoor && !_wasIndoor) {
        final nav = navigationProvider;
        debugPrint(
          "[REALTIME] Indoor realtime activated"
          " mode=${nav?.navigationMode.name}"
          " buildingId=$_kLocationBuildingId"
          " transitionPhase=${nav?.transitionPhase.name}",
        );
      }
      _wasIndoor = response.isIndoor;

      /// Backend-owned indoor context for the context-aware routing decision
      /// (Case 2). Read imperatively at route-request time, so no notify.
      _isIndoor = response.isIndoor;
      _currentIndoorNode =
          response.isIndoor ? response.nearestNode : null;

      /// =================================
      /// REAL BACKEND POSITION UPDATE
      /// =================================

      if (response.isIndoor) {

        indoorNavigationProvider
            .updatePosition(

          IndoorPosition(

            x: response.x,

            y: response.y,

            floor:
            response.floor,

            heading:
            response.heading,
          ),
        );
      }

    } catch (e) {

      debugPrint(
        "Realtime engine error: $e",
      );
    }
  }

  /// =====================================
  /// AUTO-TRANSITION DRIVER (feed only)
  /// =====================================
  ///
  /// Computes the realtime inputs (strongest beacon RSSI + GPS distance to the
  /// selected building's nearest entrance) and hands a snapshot to
  /// NavigationProvider, which owns all debounce/fire/lifecycle decisions.
  /// This provider never switches modes.

  void _feedAutoTransition(Position position) {

    final nav = navigationProvider;
    if (nav == null) return;

    /// Strongest nearby beacon (robust to list ordering).
    int? strongestRssi;
    for (final beacon in _nearbyBeacons) {
      if (strongestRssi == null || beacon.rssi > strongestRssi) {
        strongestRssi = beacon.rssi;
      }
    }

    final entrance = _nearestEntrance(
      nav.selectedBuildingId,
      position.latitude,
      position.longitude,
    );

    final double? distanceToEntranceMeters = entrance == null
        ? null
        : Geolocator.distanceBetween(
            position.latitude,
            position.longitude,
            entrance.latitude,
            entrance.longitude,
          );

    nav.evaluateAutoTransition(
      AutoTransitionInputs(
        isOutdoor: nav.navigationMode ==
            AppNavigationMode.outdoor,
        transitionIdle: nav.transitionPhase ==
            IndoorTransitionPhase.none,
        alreadyFired: nav.autoTransitionFired,
        hasIndoorDestination:
            nav.transitionIndoorNode != null,
        indoorPathReady:
            nav.hybridIndoorPath.isNotEmpty,
        distanceToEntranceMeters:
            distanceToEntranceMeters,
        strongestRssi: strongestRssi,
      ),
    );
  }

  /// Nearest [Entrance] of the building with [buildingId] from the static
  /// campus data, or null if unknown / no entrances.
  Entrance? _nearestEntrance(
      String? buildingId,
      double lat,
      double lng,
      ) {

    if (buildingId == null) return null;

    Building? building;
    for (final b in campusBuildings) {
      if (b.id == buildingId) {
        building = b;
        break;
      }
    }

    if (building == null ||
        building.entrances.isEmpty) {
      return null;
    }

    Entrance? nearest;
    double best = double.infinity;
    for (final e in building.entrances) {
      final d = Geolocator.distanceBetween(
        lat,
        lng,
        e.latitude,
        e.longitude,
      );
      if (d < best) {
        best = d;
        nearest = e;
      }
    }

    return nearest;
  }

  @override
  void dispose() {

    _pollingTimer?.cancel();

    _beaconService.dispose();

    super.dispose();
  }
}
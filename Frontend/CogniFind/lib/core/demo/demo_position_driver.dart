import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:cognifind/core/config/demo_config.dart';
import 'package:cognifind/core/enums/navigation_mode.dart';
import 'package:cognifind/indoor_engine/models/indoor_position.dart';
import 'package:cognifind/indoor_engine/providers/indoor_navigation_provider.dart';
import 'package:cognifind/models/navigation/indoor_node.dart';
import 'package:cognifind/providers/location_provider.dart';
import 'package:cognifind/providers/navigation_provider.dart';

/// ============================================================================
/// DEMO POSITION DRIVER
/// ============================================================================
///
/// The demo-mode stand-in for the two things that produce a position in
/// production: the Geolocator stream (outdoor) and RealtimePositionProvider's
/// BLE/backend poll (indoor). It writes through the SAME two entry points those
/// drivers use — [LocationProvider.injectDemoPosition] and
/// [IndoorNavigationProvider.updatePosition] — so routing, route progression,
/// instruction banners, floor synchronisation, stair handling, camera follow,
/// transitions and arrival detection all run as the untouched production code
/// they already are.
///
/// It has NO opinion about the journey. It never picks a destination, never
/// fetches a route, never switches modes on its own and never renders anything.
/// It observes the providers, walks whichever route they currently expose, and
/// hands control back at the seams:
///
///   * outdoor polyline exhausted + an indoor leg is loaded
///       → [NavigationProvider.enterIndoorTransition] (the same call the
///         "Enter Building" button and the BLE auto-trigger make);
///   * indoor path exhausted
///       → nothing. Arrival latches in IndoorNavigationProvider exactly as it
///         does from a BLE position, and the existing leg-aware orchestration
///         in NavigationScreen decides whether that means "you have arrived" or
///         "exit this building and continue".
///
/// Everything is compiled out when [kDemoNavigationMode] is false: the driver
/// is simply never constructed.
class DemoPositionDriver {
  DemoPositionDriver({
    required this.locationProvider,
    required this.navigationProvider,
    required this.indoorNavigationProvider,
  }) {
    navigationProvider.addListener(_sync);
    indoorNavigationProvider.addListener(_sync);
  }

  final LocationProvider locationProvider;
  final NavigationProvider navigationProvider;
  final IndoorNavigationProvider indoorNavigationProvider;

  Timer? _ticker;
  final Stopwatch _clock = Stopwatch();

  /// ==========================================================
  /// OUTDOOR LEG
  /// ==========================================================

  /// Identity of the polyline currently being walked. Compared by identity
  /// (never by value): every fetch/rebuild produces a NEW list, so a changed
  /// reference means "a different leg" and progress resets — while unrelated
  /// notifications leave it untouched and movement simply continues.
  List<LatLng>? _outdoorRoute;
  int _outdoorSegment = 0;
  double _outdoorMeters = 0;
  bool _outdoorDone = false;

  /// ==========================================================
  /// INDOOR LEG
  /// ==========================================================

  List<IndoorNode>? _indoorPath;
  int _indoorNode = 0;
  double _indoorUnits = 0;
  bool _indoorDone = false;

  /// True while the simulated walker is standing still on a staircase, so the
  /// floor change reads as a deliberate pause rather than a jump.
  bool _changingFloor = false;

  /// Smoothed course, in degrees. Raw segment bearings step discontinuously at
  /// every route vertex; the camera and the blue dot both read this, so it is
  /// eased toward the segment bearing instead of snapping.
  double _heading = 0;

  void dispose() {
    _stopTicker();
    navigationProvider.removeListener(_sync);
    indoorNavigationProvider.removeListener(_sync);
  }

  /// ==========================================================
  /// STATE SYNC
  /// ==========================================================
  ///
  /// The whole lifecycle. Called on every provider notification; it derives
  /// what should be happening from provider state alone, so there is no
  /// separate demo state machine to fall out of step with the app.

  void _sync() {
    /// The gate is the UI state, not the isNavigating flag. They differ in one
    /// case that matters: opening a route PREVIEW for the next trip while the
    /// previous one is still active leaves isNavigating true, and the preview
    /// fetch loads a new route — so a flag-gated driver starts walking the new
    /// route while the user is still looking at the preview card, and by the
    /// time they press Start the journey is half over. uiState is exactly
    /// "navigating right now": startNavigationMode() sets it, showRoutePreview()
    /// and stopNavigation() clear it.
    if (navigationProvider.uiState != NavigationUiState.navigating) {
      _reset();
      return;
    }

    /// Movement pauses for the whole transition animation, in both directions,
    /// and resumes by itself when the phase clears.
    if (navigationProvider.transitionPhase != IndoorTransitionPhase.none) {
      _stopTicker();
      return;
    }

    if (_changingFloor) return;

    if (navigationProvider.navigationMode == AppNavigationMode.indoor) {
      final path = indoorNavigationProvider.indoorPath;
      if (path.length < 2) {
        _stopTicker();
        return;
      }
      if (!identical(path, _indoorPath)) {
        _startIndoorLeg(path);
      } else if (!_indoorDone) {
        _resumeTicker(_tickIndoor);
      }
      return;
    }

    final route = navigationProvider.outdoorRoute;
    if (route.length < 2) {
      _stopTicker();
      return;
    }
    if (!identical(route, _outdoorRoute)) {
      _startOutdoorLeg(route);
    } else if (!_outdoorDone) {
      _resumeTicker(_tickOutdoor);
    }
  }

  void _reset() {
    _stopTicker();
    _outdoorRoute = null;
    _indoorPath = null;
    _outdoorSegment = 0;
    _outdoorMeters = 0;
    _indoorNode = 0;
    _indoorUnits = 0;
    _outdoorDone = false;
    _indoorDone = false;
    _changingFloor = false;
  }

  void _startOutdoorLeg(List<LatLng> route) {
    debugPrint('[DEMO] outdoor leg: ${route.length} points');
    _outdoorRoute = route;
    _outdoorSegment = 0;
    _outdoorMeters = 0;
    _outdoorDone = false;

    /// Seed at the first vertex so the leg starts exactly on the route rather
    /// than sliding in from wherever the previous leg left the position.
    _heading = _bearing(route.first, route[1]);
    locationProvider.injectDemoPosition(route.first, heading: _heading);

    _resumeTicker(_tickOutdoor);
  }

  void _startIndoorLeg(List<IndoorNode> path) {
    debugPrint('[DEMO] indoor leg: ${path.length} nodes'
        ' (${path.first.id} → ${path.last.id})');
    _indoorPath = path;
    _indoorNode = 0;
    _indoorUnits = 0;
    _indoorDone = false;

    _heading = _headingBetween(path.first, path[1]);
    _publishIndoor(path.first.x, path.first.y, path.first.floor);

    _resumeTicker(_tickIndoor);
  }

  void _resumeTicker(void Function() tick) {
    if (_ticker != null) return;
    _clock
      ..reset()
      ..start();
    _ticker = Timer.periodic(kDemoTickInterval, (_) => tick());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    _clock.stop();
  }

  /// Seconds since the previous tick. Elapsed-time based rather than
  /// per-tick-constant, so a dropped frame or a busy main thread stretches the
  /// step instead of stalling the walker.
  double _elapsed() {
    final seconds = _clock.elapsedMicroseconds / 1e6;
    _clock
      ..reset()
      ..start();

    /// Clamp so a long stall (route fetch, SVG decode) can never teleport the
    /// walker across half the route in one step.
    return seconds.clamp(0.0, 0.25);
  }

  /// ==========================================================
  /// OUTDOOR MOVEMENT
  /// ==========================================================

  void _tickOutdoor() {
    final route = _outdoorRoute;
    if (route == null || route.length < 2) return;

    var remaining = _elapsed() * kOutdoorDemoSpeed;

    while (remaining > 0) {
      final a = route[_outdoorSegment];
      final b = route[_outdoorSegment + 1];

      final segmentLength = _metersBetween(a, b);
      final toSegmentEnd = segmentLength - _outdoorMeters;

      if (remaining < toSegmentEnd) {
        _outdoorMeters += remaining;
        remaining = 0;
      } else {
        remaining -= toSegmentEnd;
        _outdoorSegment++;
        _outdoorMeters = 0;

        if (_outdoorSegment >= route.length - 1) {
          _finishOutdoorLeg(route.last);
          return;
        }
      }
    }

    final a = route[_outdoorSegment];
    final b = route[_outdoorSegment + 1];
    final length = _metersBetween(a, b);
    final t = length == 0 ? 0.0 : (_outdoorMeters / length).clamp(0.0, 1.0);

    _heading = _easeAngle(_heading, _bearing(a, b));

    locationProvider.injectDemoPosition(
      LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      ),
      heading: _heading,
    );
  }

  void _finishOutdoorLeg(LatLng end) {
    _outdoorDone = true;
    _stopTicker();
    locationProvider.injectDemoPosition(end, heading: _heading);

    /// The outdoor polyline of a hybrid route terminates at the building
    /// entrance node, so running out of polyline IS arriving at the door.
    /// Handing over to the provider-owned transition keeps the demo on the one
    /// enter-building path the manual button and the BLE trigger also use.
    if (navigationProvider.hybridIndoorPath.isNotEmpty) {
      debugPrint('[DEMO] reached entrance → enterIndoorTransition()');
      navigationProvider.enterIndoorTransition();
    } else {
      debugPrint('[DEMO] outdoor destination reached');
    }
  }

  /// ==========================================================
  /// INDOOR MOVEMENT
  /// ==========================================================

  void _tickIndoor() {
    final path = _indoorPath;
    if (path == null || path.length < 2) return;

    var remaining = _elapsed() * kIndoorDemoSpeed;

    while (remaining > 0) {
      final a = path[_indoorNode];
      final b = path[_indoorNode + 1];

      /// STAIRS. A segment spanning two floors is a flight of stairs, not a
      /// corridor: stand still, let the existing floor synchronisation in
      /// IndoorNavigationProvider swap the rendered floor, then continue on the
      /// new floor. Interpolating across it would drag the blue dot through
      /// walls on both floors.
      if (a.floor != b.floor) {
        _climb(b);
        return;
      }

      final segmentLength = _distance(a, b);
      final toSegmentEnd = segmentLength - _indoorUnits;

      if (remaining < toSegmentEnd) {
        _indoorUnits += remaining;
        remaining = 0;
      } else {
        remaining -= toSegmentEnd;
        _indoorNode++;
        _indoorUnits = 0;

        if (_indoorNode >= path.length - 1) {
          _finishIndoorLeg(path.last);
          return;
        }
      }
    }

    final a = path[_indoorNode];
    final b = path[_indoorNode + 1];
    final length = _distance(a, b);
    final t = length == 0 ? 0.0 : (_indoorUnits / length).clamp(0.0, 1.0);

    _heading = _easeAngle(_heading, _headingBetween(a, b));

    /// Interpolating strictly along the route polyline is what keeps the blue
    /// dot inside corridors — the route is the corridor centre line, so the
    /// walker can never cross a wall.
    _publishIndoor(
      a.x + (b.x - a.x) * t,
      a.y + (b.y - a.y) * t,
      a.floor,
    );
  }

  /// Pauses on the staircase, then reappears at the landing on the next floor.
  void _climb(IndoorNode landing) {
    _stopTicker();
    _changingFloor = true;
    debugPrint('[DEMO] stairs → floor ${landing.floor}');

    Future.delayed(kFloorChangePause, () {
      _changingFloor = false;

      /// The journey may have been cancelled or re-routed while we waited.
      if (navigationProvider.uiState != NavigationUiState.navigating ||
          !identical(_indoorPath, indoorNavigationProvider.indoorPath)) {
        return;
      }

      _indoorNode++;
      _indoorUnits = 0;

      /// Arrival floor synchronisation is IndoorNavigationProvider's job — it
      /// follows the floor of whatever position it is given.
      _publishIndoor(landing.x, landing.y, landing.floor);

      final path = _indoorPath;
      if (path == null || _indoorNode >= path.length - 1) {
        _finishIndoorLeg(landing);
        return;
      }

      _resumeTicker(_tickIndoor);
    });
  }

  void _finishIndoorLeg(IndoorNode end) {
    _indoorDone = true;
    _stopTicker();

    /// Land exactly on the final node so arrival latches on the destination
    /// itself rather than a fraction short of it.
    _publishIndoor(end.x, end.y, end.floor);
    debugPrint('[DEMO] indoor leg complete at ${end.id}');
  }

  void _publishIndoor(double x, double y, int floor) {
    indoorNavigationProvider.updatePosition(
      IndoorPosition(x: x, y: y, floor: floor, heading: _heading),
    );
  }

  /// ==========================================================
  /// GEOMETRY
  /// ==========================================================

  /// Equirectangular approximation — sub-metre accurate at campus scale, and
  /// the same approximation NavigationProvider uses for its route metrics.
  static double _metersBetween(LatLng a, LatLng b) {
    const metersPerDegree = 111320.0;
    final dLat = (b.latitude - a.latitude) * metersPerDegree;
    final dLng = (b.longitude - a.longitude) *
        metersPerDegree *
        math.cos(a.latitude * math.pi / 180.0);
    return math.sqrt(dLat * dLat + dLng * dLng);
  }

  static double _distance(IndoorNode a, IndoorNode b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  static double _bearing(LatLng a, LatLng b) {
    final lat1 = a.latitude * math.pi / 180.0;
    final lat2 = b.latitude * math.pi / 180.0;
    final dLon = (b.longitude - a.longitude) * math.pi / 180.0;

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    return (math.atan2(y, x) * 180.0 / math.pi + 360.0) % 360.0;
  }

  static double _headingBetween(IndoorNode a, IndoorNode b) {
    /// SVG y grows downward, so screen-up is -y; atan2(dx, -dy) gives a
    /// compass-style heading where 0° points up the floor plan.
    final angle = math.atan2(b.x - a.x, -(b.y - a.y));
    return (angle * 180.0 / math.pi + 360.0) % 360.0;
  }

  /// Eases [from] toward [to] along the SHORT way round the compass, so a
  /// turn through north (350° → 10°) sweeps 20° instead of unwinding 340°.
  static double _easeAngle(double from, double to) {
    var delta = (to - from + 540.0) % 360.0 - 180.0;
    return (from + delta * kHeadingEase + 360.0) % 360.0;
  }
}

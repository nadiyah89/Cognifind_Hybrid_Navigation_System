import 'package:flutter/material.dart';

import 'package:cognifind/models/navigation/indoor_node.dart';

import '../models/indoor_position.dart';

class IndoorNavigationProvider extends ChangeNotifier {

  /// =========================
  /// FLOOR & AUTO-FOLLOW STATE
  /// =========================

  int _selectedFloor = 0;

  int get selectedFloor => _selectedFloor;

  bool _autoFollow = true;

  bool get autoFollow => _autoFollow;

  void changeFloor(int floor) {

    _selectedFloor = floor;
    
    _autoFollow = false;

    notifyListeners();
  }

  void enableAutoFollow() {

    _autoFollow = true;
    
    _selectedFloor = _position.floor;

    notifyListeners();
  }

  /// =========================
  /// INDOOR ROUTE STATE
  /// =========================

  List<IndoorNode> _indoorPath = [];

  List<IndoorNode> get indoorPath => _indoorPath;

  List<IndoorNode> indoorPathForFloor(
      int floor,
      ) {

    return _indoorPath
        .where((n) => n.floor == floor)
        .toList();
  }

  void setIndoorPath(
      List<IndoorNode> path,
      ) {

    _indoorPath = path;

    /// New route → clear any prior arrival + step so the fresh journey starts
    /// from the beginning.
    _arrived = false;
    _currentIndoorIndex = 0;

    notifyListeners();
  }

  /// =========================
  /// CURRENT NODE
  /// =========================

  int _currentIndoorIndex = 0;

  int get currentIndoorIndex =>
      _currentIndoorIndex;

  IndoorNode? get currentIndoorNode {

    if (_indoorPath.isEmpty) {
      return null;
    }

    return _indoorPath[
    _currentIndoorIndex
    ];
  }

  /// The final node of the route — the destination room. Null until a path is
  /// loaded. Used to render the distinct indoor destination marker.
  IndoorNode? get destinationNode {

    if (_indoorPath.isEmpty) {
      return null;
    }

    return _indoorPath.last;
  }

  /// =========================
  /// INDOOR POSITION
  /// =========================

  IndoorPosition _position =
  const IndoorPosition(
    x: 300,
    y: 300,
    floor: 0,
    heading: 0,
  );

  IndoorPosition get position =>
      _position;

  void updatePosition(
      IndoorPosition newPosition,
      ) {

    _position = newPosition;

    if (_autoFollow && _selectedFloor != _position.floor) {
      _selectedFloor = _position.floor;
    }

    _syncStepToPosition();

    notifyListeners();
  }

  /// Advances the current step so the instruction card always reflects where
  /// the user is: find the nearest route SEGMENT ON THE CURRENT FLOOR (route
  /// coordinates are per-floor SVG units, so only same-floor geometry is
  /// comparable) and take its nearer endpoint. Since instruction[i] is 1:1
  /// with path node[i], this also keeps the highlighted current node in sync.
  /// Presentation only — it reads the backend-owned position, it never
  /// computes it.
  ///
  /// Segments rather than bare nodes because indoor routes double back on
  /// themselves (e.g. … N221 → N228 → N229 …, where N229 sits beside the
  /// N221→N228 corridor). Matching the nearest NODE then jumps several steps
  /// ahead while the user is still mid-corridor — and when the node it jumps to
  /// is the last one, arrival latches metres before the user gets there.
  /// Perpendicular distance to a segment has no such ambiguity.
  void _syncStepToPosition() {
    if (_indoorPath.isEmpty) return;

    int? step;
    double bestSq = double.infinity;

    for (var i = 0; i < _indoorPath.length - 1; i++) {
      final a = _indoorPath[i];
      final b = _indoorPath[i + 1];

      /// Skip stair segments (they span two floors) and segments belonging to
      /// another floor entirely.
      if (a.floor != _position.floor || b.floor != _position.floor) continue;

      final abx = b.x - a.x;
      final aby = b.y - a.y;
      final lenSq = abx * abx + aby * aby;

      /// Position of the closest point on segment a→b, as a 0..1 fraction.
      final t = lenSq == 0
          ? 0.0
          : (((_position.x - a.x) * abx + (_position.y - a.y) * aby) / lenSq)
              .clamp(0.0, 1.0);

      final dx = a.x + abx * t - _position.x;
      final dy = a.y + aby * t - _position.y;
      final distSq = dx * dx + dy * dy;

      if (distSq < bestSq) {
        bestSq = distSq;
        step = t < 0.5 ? i : i + 1;
      }
    }

    /// A floor reached only by a stair node (the landing at the top of a
    /// flight) has no same-floor segment yet; fall back to the nearest node on
    /// that floor so the step still tracks the user.
    if (step == null) {
      for (var i = 0; i < _indoorPath.length; i++) {
        final n = _indoorPath[i];
        if (n.floor != _position.floor) continue;

        final dx = n.x - _position.x;
        final dy = n.y - _position.y;
        final distSq = dx * dx + dy * dy;
        if (distSq < bestSq) {
          bestSq = distSq;
          step = i;
        }
      }
    }

    if (step != null) {
      _currentIndoorIndex = step;

      /// Arrival latches once the user reaches the final route node (whose
      /// instruction is already "Arrived at destination"). Latched so brief
      /// position jitter can't drop the arrival state; reset per-route in
      /// [setIndoorPath] / [resetIndoor].
      if (step >= _indoorPath.length - 1) {
        _arrived = true;
      }
    }
  }

  /// =========================
  /// ARRIVAL
  /// =========================
  ///
  /// True once the live indoor position has reached the destination (final
  /// route node). Derived from the existing position-driven step index — no
  /// separate navigation pipeline.

  bool _arrived = false;

  bool get hasArrived => _arrived;

  /// =========================
  /// INDOOR INSTRUCTIONS
  /// =========================

  List<String> _instructions = [];

  List<String> get instructions =>
      _instructions;

  String? get currentInstruction {

    if (_instructions.isEmpty) {
      return null;
    }

    final i = _currentIndoorIndex.clamp(
      0,
      _instructions.length - 1,
    );

    return _instructions[i];
  }

  void setInstructions(
      List<String> instructions,
      ) {

    _instructions = instructions;

    notifyListeners();
  }

  /// =========================
  /// STEP NAVIGATION
  /// =========================

  void nextIndoorStep() {

    if (_indoorPath.isEmpty) {
      return;
    }

    if (_currentIndoorIndex <
        _indoorPath.length - 1) {

      _currentIndoorIndex++;

      final floor =
          _indoorPath[
          _currentIndoorIndex
          ].floor;

      if (floor != _selectedFloor) {

        _selectedFloor = floor;
        _autoFollow = false;
      }

      notifyListeners();
    }
  }

  void previousIndoorStep() {

    if (_indoorPath.isEmpty) {
      return;
    }

    if (_currentIndoorIndex == 0) {
      return;
    }

    _currentIndoorIndex--;

    final floor =
        _indoorPath[
        _currentIndoorIndex
        ].floor;

    if (floor != _selectedFloor) {

      _selectedFloor = floor;
      _autoFollow = false;
    }

    notifyListeners();
  }

  /// =========================
  /// RESET
  /// =========================

  void resetIndoor() {

    _selectedFloor = 0;

    _indoorPath = [];

    _instructions = [];

    _currentIndoorIndex = 0;

    _arrived = false;

    _position =
    const IndoorPosition(
      x: 300,
      y: 300,
      floor: 0,
      heading: 0,
    );

    _autoFollow = true;

    notifyListeners();
  }
}
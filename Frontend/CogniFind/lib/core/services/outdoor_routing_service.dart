import 'dart:math' as math;

import 'package:cognifind/models/navigation/building.dart';
import 'package:cognifind/navigation_graph/campus_graph.dart';
import 'package:cognifind/navigation_graph/pathfinding_service.dart';

/// Pure outdoor routing utilities used by multiple widgets.
///
/// Responsibilities:
/// - choose nearest entrance for a building
/// - compute realistic outdoor paths over the campus graph
/// - generate encoded polylines for Google Maps
class OutdoorRoutingService {
  OutdoorRoutingService({
    CampusGraph? campusGraph,
    PathfindingService? pathfindingService,
  })  : _campusGraph = campusGraph ?? CampusGraph.defaultGraph(),
        _pathfindingService = pathfindingService ?? const PathfindingService();

  final CampusGraph _campusGraph;
  final PathfindingService _pathfindingService;

  /// Returns the entrance on [building] that is closest to [sourceLat]/[sourceLng].
  ///
  /// If the building has no entrances, this returns `null`.
  Entrance? findNearestEntrance(
    Building building, {
    required double sourceLat,
    required double sourceLng,
  }) {
    if (building.entrances.isEmpty) return null;

    Entrance? best;
    double? bestDistance;

    for (final entrance in building.entrances) {
      final d = distanceMeters(
        sourceLat,
        sourceLng,
        entrance.latitude,
        entrance.longitude,
      );

      if (best == null || d < bestDistance!) {
        best = entrance;
        bestDistance = d;
      }
    }

    return best;
  }

  /// Builds a realistic walking route over the campus graph from the given
  /// [sourceLat]/[sourceLng] to [targetLat]/[targetLng].
  ///
  /// The algorithm:
  /// - snap source to nearest graph node A
  /// - snap target to nearest graph node B
  /// - run Dijkstra over the graph from A → B
  /// - construct a polyline: source → nodes along path → target
  ///
  /// If the graph cannot provide a path for some reason, this falls back
  /// to a straight‑line polyline between source and target.
  String buildCampusRoutePolyline({
    required double sourceLat,
    required double sourceLng,
    required double targetLat,
    required double targetLng,
  }) {
    final startNode = _campusGraph.findNearestNode(sourceLat, sourceLng);
    final endNode = _campusGraph.findNearestNode(targetLat, targetLng);

    if (startNode == null || endNode == null) {
      return _buildStraightLinePolyline(
        sourceLat: sourceLat,
        sourceLng: sourceLng,
        targetLat: targetLat,
        targetLng: targetLng,
      );
    }

    final pathNodes = _pathfindingService.shortestPath(
      _campusGraph,
      startNodeId: startNode.id,
      endNodeId: endNode.id,
    );

    if (pathNodes.isEmpty) {
      return _buildStraightLinePolyline(
        sourceLat: sourceLat,
        sourceLng: sourceLng,
        targetLat: targetLat,
        targetLng: targetLng,
      );
    }

    final points = <List<double>>[];
    points.add([sourceLat, sourceLng]);
    for (final node in pathNodes) {
      points.add([node.latitude, node.longitude]);
    }
    points.add([targetLat, targetLng]);

    return _encodePolyline(points);
  }

  /// Great‑circle distance in meters between two WGS84 coordinates.
  double distanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0; // meters
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * math.pi / 180.0;

  /// Internal helper used as a robust fallback when the graph cannot
  /// provide a path (or during early development).
  String _buildStraightLinePolyline({
    required double sourceLat,
    required double sourceLng,
    required double targetLat,
    required double targetLng,
  }) {
    return _encodePolyline([
      [sourceLat, sourceLng],
      [targetLat, targetLng],
    ]);
  }

  /// Encode a list of `[lat, lng]` pairs into an encoded polyline string
  /// compatible with Google Maps.
  String _encodePolyline(List<List<double>> points) {
    String encodeValue(int value) {
      value = value < 0 ? ~(value << 1) : (value << 1);
      String chunked = '';
      while (value >= 0x20) {
        final charCode = (0x20 | (value & 0x1f)) + 63;
        chunked += String.fromCharCode(charCode);
        value >>= 5;
      }
      chunked += String.fromCharCode(value + 63);
      return chunked;
    }

    int lastLat = 0;
    int lastLng = 0;
    String result = '';

    for (final pair in points) {
      final lat = (pair[0] * 1e5).round();
      final lng = (pair[1] * 1e5).round();

      final dLat = lat - lastLat;
      final dLng = lng - lastLng;

      result += encodeValue(dLat);
      result += encodeValue(dLng);

      lastLat = lat;
      lastLng = lng;
    }

    return result;
  }
}

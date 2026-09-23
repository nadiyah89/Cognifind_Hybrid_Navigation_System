import 'dart:math' as math;

import 'package:cognifind/navigation_graph/edge.dart';
import 'package:cognifind/navigation_graph/node.dart';

/// In‑memory graph of campus walkways.
///
/// Nodes represent points on walkable paths; edges connect adjacent nodes
/// with pre‑computed distances in meters.
class CampusGraph {
  CampusGraph({
    required this.nodes,
    required this.edges,
  }) {
    _buildIndex();
  }

  final List<NavNode> nodes;
  final List<NavEdge> edges;

  final Map<String, NavNode> _nodeById = {};
  final Map<String, List<NavEdge>> _adjacency = {};

  void _buildIndex() {
    for (final n in nodes) {
      _nodeById[n.id] = n;
    }
    for (final e in edges) {
      _adjacency.putIfAbsent(e.fromId, () => []).add(e);
      // Treat walkways as bidirectional by default.
      _adjacency.putIfAbsent(e.toId, () => []).add(
            NavEdge(
              fromId: e.toId,
              toId: e.fromId,
              distanceMeters: e.distanceMeters,
            ),
          );
    }
  }

  NavNode? nodeById(String id) => _nodeById[id];

  List<NavEdge> edgesFrom(String nodeId) =>
      _adjacency[nodeId] ?? const <NavEdge>[];

  /// Returns the node closest (by straight‑line distance) to the given
  /// latitude/longitude.
  NavNode? findNearestNode(double lat, double lng) {
    NavNode? best;
    double? bestDist;

    for (final n in nodes) {
      final d = _haversineMeters(lat, lng, n.latitude, n.longitude);
      if (best == null || d < bestDist!) {
        best = n;
        bestDist = d;
      }
    }

    return best;
  }

  /// Small handcrafted default graph approximating the main campus walkways.
  ///
  /// You can refine or extend this with more precise survey data over time.
  factory CampusGraph.defaultGraph() {
    const nodes = <NavNode>[
      // Main spine running roughly north‑south through campus.
      NavNode(id: 'N1', latitude: 33.926900, longitude: 75.018900),
      NavNode(id: 'N2', latitude: 33.926400, longitude: 75.018900),
      NavNode(id: 'N3', latitude: 33.925900, longitude: 75.018900),
      NavNode(id: 'N4', latitude: 33.925400, longitude: 75.018900),
      NavNode(id: 'N5', latitude: 33.924900, longitude: 75.018900),

      // Branch towards AB‑I / AB‑II cluster.
      NavNode(id: 'N10', latitude: 33.926450, longitude: 75.019050), // near AB‑I
      NavNode(id: 'N11', latitude: 33.925750, longitude: 75.018830), // near AB‑II

      // Branch towards AB‑IV / AB‑VI / east side.
      NavNode(id: 'N20', latitude: 33.925350, longitude: 75.019600), // near AB‑VI
      NavNode(id: 'N21', latitude: 33.925330, longitude: 75.020200), // near AB‑IV

      // Branch towards library and admin.
      NavNode(id: 'N30', latitude: 33.927120, longitude: 75.018980), // near LIB
      NavNode(id: 'N31', latitude: 33.926630, longitude: 75.018570), // near AD1
    ];

    // Helper to compute edge distance between two nodes by index.
    double d(int i, int j) => _haversineMeters(
          nodes[i].latitude,
          nodes[i].longitude,
          nodes[j].latitude,
          nodes[j].longitude,
        );

    final edges = <NavEdge>[
      // Spine
      NavEdge(fromId: 'N1', toId: 'N2', distanceMeters: d(0, 1)),
      NavEdge(fromId: 'N2', toId: 'N3', distanceMeters: d(1, 2)),
      NavEdge(fromId: 'N3', toId: 'N4', distanceMeters: d(2, 3)),
      NavEdge(fromId: 'N4', toId: 'N5', distanceMeters: d(3, 4)),

      // Branch: spine to AB‑I / AB‑II
      NavEdge(fromId: 'N2', toId: 'N10', distanceMeters: d(1, 5)),
      NavEdge(fromId: 'N3', toId: 'N11', distanceMeters: d(2, 6)),
      NavEdge(fromId: 'N10', toId: 'N11', distanceMeters: d(5, 6)),

      // Branch: spine to AB‑VI / AB‑IV
      NavEdge(fromId: 'N3', toId: 'N20', distanceMeters: d(2, 7)),
      NavEdge(fromId: 'N20', toId: 'N21', distanceMeters: d(7, 8)),

      // Branch: spine to Library / Admin
      NavEdge(fromId: 'N1', toId: 'N30', distanceMeters: d(0, 9)),
      NavEdge(fromId: 'N2', toId: 'N31', distanceMeters: d(1, 10)),
      NavEdge(fromId: 'N30', toId: 'N31', distanceMeters: d(9, 10)),
    ];

    return CampusGraph(nodes: nodes, edges: edges);
  }
}

double _haversineMeters(
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


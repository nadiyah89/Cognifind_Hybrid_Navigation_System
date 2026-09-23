import 'dart:collection';

import 'package:cognifind/navigation_graph/campus_graph.dart';
import 'package:cognifind/navigation_graph/node.dart';

/// Dijkstra‑based pathfinding over the campus graph.
///
/// For the relatively small campus graphs we expect here, a simple
/// O(N^2) implementation is sufficient and easy to reason about.
class PathfindingService {
  const PathfindingService();

  /// Computes the shortest path (by edge distance) between [startNodeId]
  /// and [endNodeId]. Returns an ordered list of nodes, or an empty list
  /// if no path exists.
  List<NavNode> shortestPath(
    CampusGraph graph, {
    required String startNodeId,
    required String endNodeId,
  }) {
    final Map<String, double> dist = {};
    final Map<String, String?> prev = {};

    final Set<String> unvisited = {};

    for (final node in graph.nodes) {
      dist[node.id] = double.infinity;
      prev[node.id] = null;
      unvisited.add(node.id);
    }
    if (!unvisited.contains(startNodeId) || !unvisited.contains(endNodeId)) {
      return const [];
    }

    dist[startNodeId] = 0;

    while (unvisited.isNotEmpty) {
      // Pick node with smallest tentative distance.
      String? currentId;
      double currentDist = double.infinity;
      for (final id in unvisited) {
        final d = dist[id] ?? double.infinity;
        if (d < currentDist) {
          currentDist = d;
          currentId = id;
        }
      }

      if (currentId == null) {
        break;
      }

      if (currentId == endNodeId) {
        break; // Reached destination.
      }

      unvisited.remove(currentId);

      final edges = graph.edgesFrom(currentId);
      for (final edge in edges) {
        if (!unvisited.contains(edge.toId)) continue;

        final alt = (dist[currentId] ?? double.infinity) + edge.distanceMeters;
        if (alt < (dist[edge.toId] ?? double.infinity)) {
          dist[edge.toId] = alt;
          prev[edge.toId] = currentId;
        }
      }
    }

    // Reconstruct path.
    final List<String> reversedIds = [];
    String? cur = endNodeId;
    if ((prev[cur] == null) && cur != startNodeId) {
      // No path.
      return const [];
    }

    while (cur != null) {
      reversedIds.add(cur);
      cur = prev[cur];
    }
    final ids = reversedIds.reversed.toList();

    final List<NavNode> path = [];
    for (final id in ids) {
      final node = graph.nodeById(id);
      if (node != null) {
        path.add(node);
      }
    }

    return path;
  }
}


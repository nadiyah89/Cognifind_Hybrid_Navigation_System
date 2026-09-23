import 'package:meta/meta.dart';

/// Represents a physical entrance to a campus building.
///
/// This is intentionally UI‑agnostic (no `LatLng` dependency) so it can be
/// reused by routing logic and any mapping layer.
@immutable
class Entrance {
  final String id;
  final double latitude;
  final double longitude;

  const Entrance({
    required this.id,
    required this.latitude,
    required this.longitude,
  });
}

/// Represents a campus building on the outdoor map.
///
/// - `centerLat` / `centerLng` → visible marker location
/// - `entrances`              → one or more routing targets
/// - `destinationNodeId`      → optional indoor backend node
@immutable
class Building {
  final String id;
  final String name;
  final double centerLat;
  final double centerLng;
  final String? destinationNodeId;
  final List<Entrance> entrances;


  const Building({
    required this.id,
    required this.name,
    required this.centerLat,
    required this.centerLng,
    required this.entrances,
    this.destinationNodeId,
  });

  /// Whether this building has at least one entrance available for routing.
  bool get hasEntrances => entrances.isNotEmpty;
}


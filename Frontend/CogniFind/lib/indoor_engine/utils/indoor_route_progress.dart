import 'package:cognifind/models/navigation/indoor_node.dart';

/// The single definition of "how far along the indoor route the user is",
/// mapped into one floor's coordinate space.
///
/// The indoor route is rendered one floor at a time, but progress is tracked
/// with a single app-wide index into the full multi-floor path
/// ([IndoorNavigationProvider.currentIndoorIndex] — the position-driven
/// nearest route node that also drives the instruction card). This returns
/// that progress as a LOCAL index within [floor]'s contiguous slice of
/// [fullPath]:
///
///  * `< 0`                    → the user hasn't reached this floor yet
///                               (the floor's whole route is still remaining);
///  * `0 .. sliceLength - 1`   → the current node is on this floor;
///  * `>= sliceLength`         → the user has already passed this floor
///                               (the floor's whole route is traversed).
///
/// Mirrors the outdoor [nearestRouteIndex] helper so indoor and outdoor
/// progression share the same "current progress" philosophy and can never
/// disagree. Presentation-layer geometry only — it reads the backend-owned
/// position index, it never computes positioning.
///
/// Assumes each floor's nodes are contiguous in [fullPath] (the standard
/// monotonic floor-by-floor route, e.g. floor 0 → 1 → 2).
int indoorCurrentLocalIndex(
  List<IndoorNode> fullPath,
  int currentIndex,
  int floor,
) {
  final floorStart = fullPath.indexWhere((n) => n.floor == floor);
  if (floorStart < 0) return -1;
  return currentIndex - floorStart;
}

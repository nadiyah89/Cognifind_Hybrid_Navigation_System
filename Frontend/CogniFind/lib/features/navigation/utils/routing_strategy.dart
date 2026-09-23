/// Context-aware routing decision (Phase 4.1 · Priority 5).
///
/// Decides whether a trip to an indoor room should route INDOORS DIRECTLY from
/// the user's current indoor node (Case 2), instead of building a hybrid
/// outdoor → enter-building → indoor route (Case 1).
///
/// It returns true only when ALL of the following hold, using backend-owned
/// truth (never frontend estimation):
///
///  * the backend says the user is currently indoors (`isIndoor`);
///  * the backend gave a current indoor node to start from
///    (`currentIndoorNode`) — this becomes the indoor route origin;
///  * the destination is an indoor room (`destinationNodeId` present); and
///  * that room is in the SAME building the user is already inside
///    (`destinationBuildingId == indoorBuildingId`).
///
/// When it returns false the caller falls back to the existing hybrid/outdoor
/// decision — so Case 1 (outside → room) and Case 3 (inside → a different
/// building) keep their current behaviour untouched.
bool shouldRouteIndoorOnly({
  required bool isIndoor,
  required String? currentIndoorNode,
  required String? destinationNodeId,
  required String? destinationBuildingId,
  required String indoorBuildingId,
}) {
  return isIndoor &&
      currentIndoorNode != null &&
      currentIndoorNode.isNotEmpty &&
      destinationNodeId != null &&
      destinationBuildingId == indoorBuildingId;
}

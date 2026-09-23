import 'package:google_maps_flutter/google_maps_flutter.dart';

/// The single definition of "how far along the outdoor route the user is":
/// the index of the route vertex nearest [position].
///
/// Shared so the traversed/remaining polyline split AND the current outdoor
/// instruction derive from the SAME progress index and can never disagree.
/// Squared planar distance — cheap, and only ordering matters at campus scale.
/// Presentation-layer geometry only; the backend still owns positioning.
int nearestRouteIndex(List<LatLng> route, LatLng position) {
  var nearest = 0;
  var bestSq = double.infinity;

  for (var i = 0; i < route.length; i++) {
    final dLat = route[i].latitude - position.latitude;
    final dLng = route[i].longitude - position.longitude;
    final distSq = dLat * dLat + dLng * dLng;
    if (distSq < bestSq) {
      bestSq = distSq;
      nearest = i;
    }
  }

  return nearest;
}

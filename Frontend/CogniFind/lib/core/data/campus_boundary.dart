import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

class CampusPoint {
  final double lat;
  final double lng;

  const CampusPoint(this.lat, this.lng);
}

/// Polygon approximating the campus boundary, reused for:
/// - Map camera bounds
/// - Clamping user position to campus edge when routing.
const List<CampusPoint> campusBoundaryPoints = [
  CampusPoint(33.926424, 75.016884),
  CampusPoint(33.932259, 75.012641),
  CampusPoint(33.932779, 75.016422),
  CampusPoint(33.933436, 75.015651),
  CampusPoint(33.933506, 75.015909),
  CampusPoint(33.933769, 75.016016),
  CampusPoint(33.933996, 75.016382),
  CampusPoint(33.934207, 75.016536),
  CampusPoint(33.934475, 75.016597),
  CampusPoint(33.934443, 75.017211),
  CampusPoint(33.934764, 75.017513),
  CampusPoint(33.934944, 75.017565),
  CampusPoint(33.935055, 75.017857),
  CampusPoint(33.934800, 75.019154),
  CampusPoint(33.929024, 75.022757),
  CampusPoint(33.925189, 75.022055),
  CampusPoint(33.923927, 75.020853),
  CampusPoint(33.923447, 75.018389),
  CampusPoint(33.923378, 75.018144),
  CampusPoint(33.923611, 75.017677),
  CampusPoint(33.924111, 75.015100),
];

/// Campus boundary as Google Maps [LatLng] points, derived 1:1 from
/// [campusBoundaryPoints] (single source of truth). Reused by the outdoor map
/// for camera bounds. Deriving avoids duplicating coordinates.
final List<LatLng> campusBoundaryLatLng = campusBoundaryPoints
    .map((p) => LatLng(p.lat, p.lng))
    .toList();

/// Neutral overview target for the outdoor map's default/return-from-indoor
/// camera. Not derived from the boundary — a hand-picked visual center.
const LatLng campusCenter = LatLng(33.925902, 75.018993);

/// Main campus entry gate. When the user is still OUTSIDE the campus boundary,
/// outdoor navigation logically begins here, so the focus button targets the
/// gate rather than the user's distant GPS position.
const LatLng campusGate = LatLng(33.9266629, 75.0171057);

class CampusBoundary {
  /// Returns true if the given coordinate lies inside the campus polygon.
  static bool contains(double lat, double lng) {
    bool inside = false;
    for (int i = 0, j = campusBoundaryPoints.length - 1;
        i < campusBoundaryPoints.length;
        j = i++) {
      final xi = campusBoundaryPoints[i].lat;
      final yi = campusBoundaryPoints[i].lng;
      final xj = campusBoundaryPoints[j].lat;
      final yj = campusBoundaryPoints[j].lng;

      final intersect = ((yi > lng) != (yj > lng)) &&
          (lat <
              (xj - xi) * (lng - yi) / ((yj - yi) + 1e-12) +
                  xi); // small epsilon to avoid div-by-zero
      if (intersect) inside = !inside;
    }
    return inside;
  }

  /// If [lat,lng] is inside campus, returns it unchanged.
  /// Otherwise returns the closest point on the campus boundary polygon.
  static CampusPoint clampToCampus(double lat, double lng) {
    if (contains(lat, lng)) {
      return CampusPoint(lat, lng);
    }

    CampusPoint? closestPoint;
    double closestDistSq = double.infinity;

    for (int i = 0; i < campusBoundaryPoints.length; i++) {
      final a = campusBoundaryPoints[i];
      final b = campusBoundaryPoints[(i + 1) % campusBoundaryPoints.length];

      final candidate = _closestPointOnSegment(a, b, CampusPoint(lat, lng));
      final dSq = _distSq(candidate, CampusPoint(lat, lng));

      if (dSq < closestDistSq) {
        closestDistSq = dSq;
        closestPoint = candidate;
      }
    }

    return closestPoint ?? CampusPoint(lat, lng);
  }

  static CampusPoint _closestPointOnSegment(
    CampusPoint a,
    CampusPoint b,
    CampusPoint p,
  ) {
    final ax = a.lat;
    final ay = a.lng;
    final bx = b.lat;
    final by = b.lng;
    final px = p.lat;
    final py = p.lng;

    final abx = bx - ax;
    final aby = by - ay;
    final apx = px - ax;
    final apy = py - ay;

    final abLenSq = abx * abx + aby * aby;
    if (abLenSq == 0) return a;

    final t = ((apx * abx) + (apy * aby)) / abLenSq;
    final clampedT = t.clamp(0.0, 1.0);

    return CampusPoint(
      ax + abx * clampedT,
      ay + aby * clampedT,
    );
  }

  static double _distSq(CampusPoint a, CampusPoint b) {
    final dx = a.lat - b.lat;
    final dy = a.lng - b.lng;
    return dx * dx + dy * dy;
  }
}


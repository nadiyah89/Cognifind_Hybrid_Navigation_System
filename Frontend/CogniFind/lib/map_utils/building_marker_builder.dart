import 'package:cognifind/models/navigation/building.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Builds Google Maps markers for the given [buildings].
///
/// - One marker per building, positioned at the building center.
/// - Each marker shows the building name.
/// - All markers use a blue hue, consistent with outdoor navigation.
/// - Tapping a marker invokes [onTap] with the tapped [Building].
Set<Marker> buildBuildingMarkers(
  List<Building> buildings,
  void Function(Building) onTap,
) {
  return buildings
      .map(
        (b) => Marker(
          markerId: MarkerId(b.id),
          position: LatLng(b.centerLat, b.centerLng),
          infoWindow: InfoWindow(title: b.name),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          onTap: () => onTap(b),
        ),
      )
      .toSet();
}


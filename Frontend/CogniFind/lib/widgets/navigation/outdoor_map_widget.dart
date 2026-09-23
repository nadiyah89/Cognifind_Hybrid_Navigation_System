
import 'package:cognifind/core/data/campus_boundary.dart';
import 'package:cognifind/core/data/campus_buildings.dart';
import 'package:cognifind/core/config/demo_config.dart';
import 'package:cognifind/map_utils/building_marker_builder.dart';
import 'package:cognifind/models/navigation/building.dart';
import 'package:cognifind/providers/location_provider.dart';
import 'package:cognifind/providers/navigation_provider.dart';
import 'package:cognifind/features/navigation/utils/route_progress.dart';

import 'package:cognifind/widgets/navigation/map_controls_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:cognifind/models/navigation/search_place.dart';

/// OutdoorMapWidget
///
/// Handles ONLY outdoor map rendering:
/// - Google Map
/// - Campus markers
/// - Map tap detection
///
/// No routing logic here.
/// No backend calls here.
class OutdoorMapWidget extends StatefulWidget {
  const OutdoorMapWidget({super.key});

  @override
  State<OutdoorMapWidget> createState() => _OutdoorMapWidgetState();
}

class _OutdoorMapWidgetState extends State<OutdoorMapWidget> {
  GoogleMapController? _mapController;

  MapType _mapType = MapType.satellite;
  List<LatLng> _lastRoute = [];

  /// Last camera-follow position in demo mode (prevents redundant animations).
  LatLng? _lastDemoCameraTarget;

  /// Last place the camera was focused on, so selecting the same place
  /// repeatedly (or unrelated rebuilds) doesn't re-animate the camera.
  String? _lastFocusedPlaceId;




  /// Campus center — neutral overview target (single source in campus data).
  static const LatLng _campusCenter = campusCenter;

  /// Initial camera position. CASE 1 (default outdoor entry + return from
  /// indoor): the map opens on the campus overview, never on the user's GPS.
  /// The widget is rebuilt fresh on every outdoor entry (AnimatedSwitcher),
  /// so this alone satisfies both startup and return-from-indoor centering.
  static const CameraPosition _initialCameraPosition =
      CameraPosition(
        target: _campusCenter,
        zoom: 21,
      );

  LatLngBounds get _campusBounds {
    double south = campusBoundaryLatLng.first.latitude;
    double north = campusBoundaryLatLng.first.latitude;
    double west = campusBoundaryLatLng.first.longitude;
    double east = campusBoundaryLatLng.first.longitude;

    for (final point in campusBoundaryLatLng) {
      if (point.latitude < south) south = point.latitude;
      if (point.latitude > north) north = point.latitude;
      if (point.longitude < west) west = point.longitude;
      if (point.longitude > east) east = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  /// Markers shown on the map
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _addBuildingMarkers();
  }

  /// Add static building reference markers using shared helper.
  void _addBuildingMarkers() {
    final markers = buildBuildingMarkers(campusBuildings, _onBuildingTap);
    setState(() {
      _markers.addAll(markers);
    });
  }

  Future<void> _onBuildingTap(Building building) async {

    debugPrint("Tapped building: ${building.name}");
    debugPrint("Destination node: ${building.destinationNodeId}");

    final navProvider = context.read<NavigationProvider>();
    final locationProvider = context.read<LocationProvider>();

    final raw = locationProvider.currentLocation ?? _campusCenter;
    final clamped =
        CampusBoundary.clampToCampus(raw.latitude, raw.longitude);

    // STEP 1 — Set user source location
    navProvider.setSourceLocation(
      latitude: clamped.lat,
      longitude: clamped.lng,
    );

    // STEP 2 — Select building
    navProvider.selectOutdoorBuilding(building.id);

    // STEP 3 — Select place: uiState → placeSelected. The build method
    // reacts to this (camera focus + arrival circle), same as a
    // search-selected place.
    final place = SearchPlace(
      id: building.id,
      name: building.name,
      subtitle: "Campus building",
      category: PlaceCategory.academic,
      latitude: building.centerLat,
      longitude: building.centerLng,
      destinationNodeId: building.destinationNodeId,
    );
    navProvider.selectPlace(place);
  }

  /// Arrival radius circle around the selected place, derived from provider
  /// state so search selections and marker taps render identically.
  Set<Circle> _buildArrivalCircle(NavigationProvider provider) {
    final place = provider.selectedPlace;
    if (place == null) return {};

    return {
      Circle(
        circleId: CircleId('arrival_${place.id}'),
        center: LatLng(place.latitude, place.longitude),
        // Radius in meters (adjust later)
        radius: 25,
        strokeWidth: 2,
        strokeColor: Colors.orange,
        fillColor: Colors.orange.withOpacity(0.25),
      ),
    };
  }

  /// Animates the camera to a newly selected place (marker tap or search).
  void _focusOnSelectedPlace(NavigationProvider provider) {
    final place = provider.selectedPlace;

    if (place == null) {
      _lastFocusedPlaceId = null;
      return;
    }

    if (provider.uiState != NavigationUiState.placeSelected ||
        place.id == _lastFocusedPlaceId) {
      return;
    }

    _lastFocusedPlaceId = place.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController?.animateCamera(
        /// Flat + north-up, matching the route-preview overview. The previous
        /// tilt/bearing rotated the map ~30° on place selection and then
        /// snapped back to flat north-up for Directions — two disorienting
        /// camera swings with no navigational purpose. Keeping one consistent
        /// north-up orientation makes the camera feel calm and predictable.
        CameraUpdate.newLatLngZoom(
          LatLng(place.latitude, place.longitude),
          18,
        ),
      );
    });
  }


  /// Called when user taps on the map (not a building). Dismisses the place
  /// sheet only — a tap must not tear down an open route preview or an
  /// active navigation.
  void _onMapTap(LatLng position) {

    final nav = context.read<NavigationProvider>();

    if (nav.uiState == NavigationUiState.placeSelected) {
      nav.clearSelection();
    }
  }

  /// Zoom in
  void _zoomIn() {
    _mapController?.animateCamera(CameraUpdate.zoomIn());
  }

  /// Zoom out
  void _zoomOut() {
    _mapController?.animateCamera(CameraUpdate.zoomOut());
  }

  void _toggleMapType() {
    setState(() {
      _mapType =
          _mapType == MapType.satellite ? MapType.normal : MapType.satellite;
    });
  }

  /// Context-aware focus button (the second side control).
  ///
  /// CASE 2 — user OUTSIDE campus: navigation begins at the entry gate, so
  ///          focus the gate (not the user's distant GPS).
  /// CASE 4 — user INSIDE campus: the gate is no longer relevant; behave like
  ///          Locate Me and recenter on the user's current position.
  ///
  /// Falls back to the campus overview when there's no GPS fix yet.
  void _onFocusPressed() {
    final userLoc = context.read<LocationProvider>().currentLocation;

    if (userLoc == null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(_campusBounds, 60),
      );
      return;
    }

    final inside =
        CampusBoundary.contains(userLoc.latitude, userLoc.longitude);

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        inside ? userLoc : campusGate,
        18,
      ),
    );
  }

  /// Locate Me — recenter on the user's current GPS position.
  void _goToMyLocation() {
    final userLoc = context.read<LocationProvider>().currentLocation;

    if (userLoc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Waiting for your location…'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(userLoc, 18),
    );
  }

  Set<Polyline> _buildPolylines(BuildContext context) {
    final provider = context.watch<NavigationProvider>();
    final route = provider.outdoorRoute;

    if (route.isEmpty) {
      return {};
    }

    /// Google Maps-style route progression: while actively navigating, the
    /// segment already walked dims and the remaining segment stays bright.
    /// Outside active navigation (idle / preview) the whole route is bright.
    final userLoc = context.watch<LocationProvider>().currentLocation;

    if (provider.isNavigating && userLoc != null && route.length >= 2) {
      final splitIndex = nearestRouteIndex(route, userLoc);

      /// Overlap by one point so the two polylines meet with no visual gap.
      final traversed = route.sublist(0, splitIndex + 1);
      final remaining = route.sublist(splitIndex);

      return {
        if (traversed.length >= 2)
          Polyline(
            polylineId: const PolylineId('route_traversed'),
            color: Colors.blue.withOpacity(0.25),
            width: 5,
            points: traversed,
          ),
        Polyline(
          polylineId: const PolylineId('route_remaining'),
          color: Colors.blue,
          width: 5,
          points: remaining,
        ),
      };
    }

    return {
      Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.blue,
        width: 5,
        points: route,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    /// STEP 1: listen to navigation mode
    final navigationProvider = context.watch<NavigationProvider>();

    if (navigationProvider.uiState == NavigationUiState.routePreview) {
      final currentRoute = navigationProvider.outdoorRoute;
      if (currentRoute.isNotEmpty && currentRoute != _lastRoute) {
        _lastRoute = List.from(currentRoute);
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_mapController == null) return;
          
          double minLat = currentRoute.first.latitude;
          double maxLat = currentRoute.first.latitude;
          double minLng = currentRoute.first.longitude;
          double maxLng = currentRoute.first.longitude;

          for (final p in currentRoute) {
            if (p.latitude < minLat) minLat = p.latitude;
            if (p.latitude > maxLat) maxLat = p.latitude;
            if (p.longitude < minLng) minLng = p.longitude;
            if (p.longitude > maxLng) maxLng = p.longitude;
          }

          _mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(
              LatLngBounds(
                southwest: LatLng(minLat, minLng),
                northeast: LatLng(maxLat, maxLng),
              ),
              80,
            ),
          );
        });
      }
    } else {
      _lastRoute = [];
    }

    /// Focus the camera on a newly selected place (marker tap or search).
    _focusOnSelectedPlace(navigationProvider);

    /// NAVIGATION CAMERA — follows the user while a route is being walked.
    ///
    /// moveCamera, not animateCamera: the position already arrives as a smooth
    /// continuous stream, so each frame is a small step and the map glides.
    /// Animating every update would instead queue overlapping tweens that
    /// fight each other and stutter. Tilted and turned to the direction of
    /// travel (LocationProvider smooths the heading), which is what makes a
    /// navigation view readable — the road ahead is up.
    if (kDemoNavigationMode && navigationProvider.isNavigating) {
      final location = context.watch<LocationProvider>();
      final pos = location.currentLocation;
      if (pos != null && pos != _lastDemoCameraTarget) {
        _lastDemoCameraTarget = pos;
        final bearing = location.currentHeading ?? 0;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController?.moveCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: pos,
                zoom: 18.5,
                tilt: 50,
                bearing: bearing,
              ),
            ),
          );
        });
      }
    }

    // Base building markers
    final markers = <Marker>{..._markers};

    // Optional highlighted entrance marker during active navigation.
    final entranceLat = navigationProvider.activeEntranceLat;
    final entranceLng = navigationProvider.activeEntranceLng;
    if (entranceLat != null && entranceLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('target_entrance'),
          position: LatLng(entranceLat, entranceLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Entrance'),
        ),
      );
    }


    return Stack(
      children: [

        GoogleMap(
          initialCameraPosition: _initialCameraPosition,
          cameraTargetBounds: CameraTargetBounds(_campusBounds),
          minMaxZoomPreference: const MinMaxZoomPreference(14, 19),
          mapType: _mapType,
          onMapCreated: (controller) {
            _mapController = controller;
          },
          markers: markers,
          polylines: _buildPolylines(context),
          /// Arrival radius circle (derived from the selected place)
          circles: {
            ..._buildArrivalCircle(navigationProvider),
            // ── DEMO MODE: custom blue user-position circle ──
            if (kDemoNavigationMode)
              ..._buildDemoUserCircle(context),
          },
          onTap: _onMapTap,
          myLocationEnabled: !kDemoNavigationMode,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),

        /// Bottom place card removed (now in NavigationScreen)

        /// Right-side map controls
        Positioned(
          right: 12,
          bottom: 100,
          child: MapControlsWidget(
            onToggleMapType: _toggleMapType,
            isSatellite: _mapType == MapType.satellite,
            onMyLocation: _goToMyLocation,
            onCenter: _onFocusPressed,
            onZoomIn: _zoomIn,
            onZoomOut: _zoomOut,
          ),
        ),

        // Lightweight loading hint while route is being fetched.
        if (navigationProvider.isFetchingRoute)
          Positioned(
            left: 16,
            bottom: 24,
            child: Card(
              elevation: 4,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Calculating route…',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// The user dot, drawn for demo mode only.
  ///
  /// The native `myLocationEnabled` dot renders the platform's own GPS fix and
  /// has no way to show an injected position, so it is switched off and this
  /// stands in for it: a solid core inside a soft accuracy halo, the same
  /// reading as the system dot.
  Set<Circle> _buildDemoUserCircle(BuildContext context) {
    final pos = context.watch<LocationProvider>().currentLocation;
    if (pos == null) return {};
    return {
      Circle(
        circleId: const CircleId('demo_user_halo'),
        center: pos,
        radius: 11,
        fillColor: Colors.blue.withOpacity(0.18),
        strokeColor: Colors.blue.withOpacity(0.35),
        strokeWidth: 1,
        zIndex: 998,
      ),
      Circle(
        circleId: const CircleId('demo_user'),
        center: pos,
        radius: 3,
        fillColor: Colors.blue.shade600,
        strokeColor: Colors.white,
        strokeWidth: 3,
        zIndex: 999,
      ),
    };
  }
}

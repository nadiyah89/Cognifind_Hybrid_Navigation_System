import 'dart:ui' show Size;

import 'package:cognifind/core/data/indoor_places.dart';

/// ============================================================================
/// CENTRAL INDOOR-BUILDING CONFIGURATION
/// ============================================================================
///
/// Single source of truth for everything the frontend needs to render and
/// search an indoor building: its id, display name, per-floor SVG assets and
/// viewBox sizes, and (via [IndoorBuildingConfig.places]) its searchable
/// indoor destinations.
///
/// Widgets and providers must read from here instead of hardcoding a building
/// id, SVG path, viewBox, or floor list. Adding a new indoor building (e.g.
/// AB-III) is then a matter of dropping its floor-plan SVGs into `assets/` and
/// appending one [IndoorBuildingConfig] entry to [indoorBuildingConfigs] — no
/// widget changes required.
///
/// The backend currently only returns the default building ([AB-IV]); this
/// configuration changes nothing about that. AB-IV remains the default and its
/// behaviour is unchanged.

/// Per-floor rendering configuration for one indoor floor.
class IndoorFloorConfig {
  /// Floor level as used by the backend node graph (0 = ground, 1, 2, ...).
  final int level;

  /// Human-readable label for the floor chip / selector (e.g. "Ground Floor").
  final String label;

  /// SVG floor-plan asset path bundled with the app.
  final String svgAsset;

  /// Canvas size that MUST equal the SVG's declared `viewBox`. The backend's
  /// route node coordinates are in SVG user space, so the route overlay only
  /// aligns with the floor plan when the CustomPaint size matches the viewBox
  /// exactly. (AB-IV floor 1's viewBox is 1554.0925×1100, not its 1588×1124
  /// width/height attributes — using the latter shifted the route ~1.3×
  /// down-right of the plan.)
  final Size viewBox;

  /// Optional vertical framing nudge applied on the initial centered zoom,
  /// expressed as a fraction of viewport height (negative lifts the plan up).
  /// 0 means no nudge. AB-IV's floor 1 renders slightly low, so it uses a
  /// small negative factor.
  final double initialPanFactor;

  const IndoorFloorConfig({
    required this.level,
    required this.label,
    required this.svgAsset,
    required this.viewBox,
    this.initialPanFactor = 0,
  });
}

/// Full configuration for one indoor building.
class IndoorBuildingConfig {
  /// Backend building id (also the key in [indoorBuildingConfigs]).
  final String id;

  /// Display name (e.g. "CSE").
  final String name;

  /// Floors this building exposes, in display order.
  final List<IndoorFloorConfig> floors;

  const IndoorBuildingConfig({
    required this.id,
    required this.name,
    required this.floors,
  });

  /// Floor levels available for this building (drives the floor selector).
  List<int> get floorLevels => [for (final f in floors) f.level];

  /// Per-floor config for [level], or null when the building has no such floor.
  IndoorFloorConfig? floor(int level) {
    for (final f in floors) {
      if (f.level == level) return f;
    }
    return null;
  }

  /// Searchable indoor destinations for this building. Delegates to the
  /// existing dataset registry so place data keeps a single home in
  /// [indoorPlacesForBuilding].
  List<IndoorPlace> get places => indoorPlacesForBuilding(id);
}

/// The building the backend returns today and the frontend's default. Widgets
/// and providers that previously hardcoded "AB-IV" reference this instead.
const String kDefaultIndoorBuildingId = 'AB-IV';

/// AB-IV (CSE) — the one building with indoor floor plans + node graph today.
const IndoorBuildingConfig _abIvConfig = IndoorBuildingConfig(
  id: 'AB-IV',
  name: 'CSE',
  floors: [
    IndoorFloorConfig(
      level: 0,
      label: 'Ground Floor',
      svgAsset: 'assets/indoor/0_floor_cse.svg',
      viewBox: Size(1588, 1124),
    ),
    IndoorFloorConfig(
      level: 1,
      label: 'Floor 1',
      svgAsset: 'assets/indoor/1_floor_cse.svg',
      viewBox: Size(1554.0925, 1100),
      initialPanFactor: -0.04,
    ),
    IndoorFloorConfig(
      level: 2,
      label: 'Floor 2',
      svgAsset: 'assets/indoor/2_floor_cse.svg',
      viewBox: Size(1588, 1122.6667),
    ),
  ],
);

/// AB-III (ECE / Electrical / Mech) — floor plans bundled; indoor node graph
/// still pending backend coverage.
///
/// viewBox values are taken verbatim from each SVG's root `<svg viewBox>` and
/// MUST match it exactly (the route/blue-dot overlays are drawn in SVG user
/// space). All three floors share the same pixel-space canvas
/// (1588 × 1122.6667), matching the ECE SVGs and the CSE convention, so backend
/// node coordinates for AB-III must be expressed in that same 1588 × 1122.6667
/// space to align.
const IndoorBuildingConfig _abIiiConfig = IndoorBuildingConfig(
  id: 'AB-III',
  name: 'ECE',
  floors: [
    IndoorFloorConfig(
      level: 0,
      label: 'Ground Floor',
      svgAsset: 'assets/indoor/0_floor_ECE.svg',
      viewBox: Size(1588, 1122.6667),
    ),
    IndoorFloorConfig(
      level: 1,
      label: 'Floor 1',
      svgAsset: 'assets/indoor/1_floor_ECE.svg',
      viewBox: Size(1588, 1122.6667),
    ),
    IndoorFloorConfig(
      level: 2,
      label: 'Floor 2',
      svgAsset: 'assets/indoor/2_floor_ECE.svg',
      viewBox: Size(1588, 1122.6667),
    ),
  ],
);

/// Registry of indoor buildings keyed by backend building id.
///
/// To add another building later: bundle its floor SVGs and append its
/// [IndoorBuildingConfig] here (plus its rooms in [indoorPlacesByBuilding]).
const Map<String, IndoorBuildingConfig> indoorBuildingConfigs = {
  'AB-IV': _abIvConfig,
  'AB-III': _abIiiConfig,
};

/// Config for [buildingId], or null when the building has no indoor map yet.
IndoorBuildingConfig? indoorBuildingConfigFor(String? buildingId) {
  if (buildingId == null) return null;
  return indoorBuildingConfigs[buildingId];
}

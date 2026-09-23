import 'dart:math' as math;

import 'package:cognifind/core/config/indoor_building_config.dart';

import 'package:cognifind/core/enums/navigation_mode.dart';

import 'package:cognifind/core/services/hybrid_route_service.dart';

import 'package:cognifind/features/navigation/transition/auto_transition_evaluator.dart';

import 'package:cognifind/models/navigation/indoor_node.dart';
import 'package:cognifind/models/navigation/search_place.dart';
import 'package:cognifind/models/navigation/hybrid_route_result.dart';

import 'package:flutter/foundation.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// ======================================================
/// NavigationProvider
/// ======================================================
///
/// GLOBAL NAVIGATION CONTROLLER
///
/// RESPONSIBILITIES:
/// - Outdoor navigation
/// - Hybrid transitions
/// - Navigation lifecycle
/// - Outdoor instructions
/// - Selected building
/// - Route state
///
/// DOES NOT HANDLE:
/// - Indoor blue dot
/// - Indoor path
/// - Indoor instructions
/// - Indoor floor state
/// - Indoor realtime positioning
///
/// Those are handled by:
/// IndoorNavigationProvider
///
/// ======================================================

enum NavigationUiState {
  idle,
  placeSelected,
  routePreview,
  navigating,
}

enum RouteStatus {

  /// No route selected
  idle,

  /// Destination selected
  destinationSelected,

  /// Outdoor route completed
  outdoorCompleted,

  /// Indoor navigation active
  indoorActive,

  /// ----------------------------------------------------------------------
  /// NEW MULTI-BUILDING JOURNEY STAGES (Phase 4 — REPRESENTATION ONLY)
  ///
  /// These make the state machine capable of representing the new
  /// indoor → outdoor → indoor journey:
  ///   indoorStartActive → exitingBuilding → outdoorActive →
  ///   enteringBuilding → indoorDestinationActive → arrived
  ///
  /// They are declared ONLY. No transition assigns or reads them yet, so the
  /// existing flow (idle/destinationSelected/outdoorCompleted/indoorActive)
  /// and all behaviour are unchanged. Wiring happens in a later phase.
  /// ----------------------------------------------------------------------

  /// Navigating indoors inside the SOURCE building (indoorStart segment).
  indoorStartActive,

  /// Exit-building transition: source building → outdoor.
  exitingBuilding,

  /// Navigating the OUTDOOR middle leg between the two buildings.
  outdoorActive,

  /// Enter-building transition: outdoor → destination building.
  enteringBuilding,

  /// Navigating indoors inside the DESTINATION building (indoorDestination).
  indoorDestinationActive,

  /// Journey complete — arrived at the final destination.
  arrived,
}

/// Lifecycle phase of an outdoor↔indoor transition.
///
/// [none] means stable in a mode (fully outdoor or fully indoor). The other
/// phases mark a transition in flight — the seam that future animation and
/// automatic-trigger (GPS threshold / BLE) work will hook into, without any
/// further navigation-lifecycle surgery. Today the phase pulses
/// synchronously (none → entering/exiting → none).
enum IndoorTransitionPhase {
  none,
  enteringIndoor,
  exitingIndoor,
}

class NavigationProvider extends ChangeNotifier {

  /// ======================================================
  /// UI OVERLAY STATE
  /// ======================================================

  NavigationUiState _uiState = NavigationUiState.idle;

  NavigationUiState get uiState => _uiState;

  SearchPlace? _selectedPlace;

  SearchPlace? get selectedPlace => _selectedPlace;

  void selectPlace(SearchPlace place) {
    _selectedPlace = place;
    _uiState = NavigationUiState.placeSelected;
    notifyListeners();
  }

  /// ======================================================
  /// INDOOR SOURCE (origin node)
  /// ======================================================
  ///
  /// The indoor node the NEXT route should start from, i.e. the indoor
  /// counterpart of [setSourceLocation]. Null means "start outdoors from the
  /// GPS source". Set by the call-site (which owns the live indoor context)
  /// before Directions/Start, so the route PREVIEW and the actual navigation
  /// always request the same route shape. When it is set alongside an indoor
  /// destination the backend decides the shape: same building → an indoor-only
  /// route, different building → the multi-segment
  /// indoorStart → outdoor → indoorDestination hybrid.
  String? _indoorOriginNode;

  String? get indoorOriginNode => _indoorOriginNode;

  void setIndoorOrigin(String? nodeId) {
    _indoorOriginNode = nodeId;
  }

  Future<void> showRoutePreview() async {
    if (_selectedPlace != null) {
      _uiState = NavigationUiState.routePreview;
      notifyListeners();

      debugPrint("[ROUTE PREVIEW] Fetching route...");

      if (_selectedPlace!.destinationNodeId != null) {
        await fetchHybridRoute(
          startIndoorNode: _indoorOriginNode,
          destinationIndoorNode: _selectedPlace!.destinationNodeId,
          isPreview: true,
        );
      } else {
        await fetchOutdoorRoute(
          destinationLat: _selectedPlace!.latitude,
          destinationLng: _selectedPlace!.longitude,
          isPreview: true,
        );
      }

      debugPrint("[ROUTE PREVIEW] Route received: pointsCount=${_outdoorRoute.length}");
    }
  }

  /// Average walking speed used for duration estimates (~5 km/h).
  static const double _walkingMetersPerMinute = 83.0;

  /// Distance/duration of the current outdoor route polyline. Recomputed on
  /// every fetch; drives both the route preview card and the active
  /// navigation stats card.
  double _routeDistanceMeters = 0.0;
  double _routeDurationMinutes = 0.0;

  double get routeDistanceMeters => _routeDistanceMeters;
  double get routeDurationMinutes => _routeDurationMinutes;

  void _calculateRouteMetrics() {
    if (_outdoorRoute.length < 2) {
      _routeDistanceMeters = 0.0;
      _routeDurationMinutes = 0.0;
      return;
    }

    double distance = 0.0;
    for (int i = 0; i < _outdoorRoute.length - 1; i++) {
      distance += _segmentMeters(_outdoorRoute[i], _outdoorRoute[i + 1]);
    }

    _routeDistanceMeters = distance;
    _routeDurationMinutes = distance / _walkingMetersPerMinute;
  }

  /// Equirectangular approximation — accurate to well under a meter at
  /// campus scale.
  static double _segmentMeters(LatLng a, LatLng b) {
    const metersPerDegree = 111320.0;
    final latDiff = (a.latitude - b.latitude) * metersPerDegree;
    final lngDiff = (a.longitude - b.longitude) *
        metersPerDegree *
        math.cos(a.latitude * math.pi / 180.0);
    return math.sqrt(latDiff * latDiff + lngDiff * lngDiff);
  }

  void clearSelection() {
    _selectedPlace = null;
    _uiState = NavigationUiState.idle;
    notifyListeners();
  }

  /// System back while the route preview sheet is open: step back to the
  /// place sheet (the selection is kept), instead of leaving the map.
  void backToPlaceSelected() {
    if (_selectedPlace == null) {
      clearSelection();
      return;
    }
    _uiState = NavigationUiState.placeSelected;
    notifyListeners();
  }

  /// Applies the navigation-state transitions that a non-preview fetch would
  /// have applied, reusing the route already fetched by [showRoutePreview] —
  /// so Start from the preview doesn't re-fetch the same route.
  void promotePreviewRoute() {
    /// A multi-segment hybrid BEGINS inside the source building, so promoting
    /// its preview must start indoors — mirroring the same decision the
    /// non-preview fetch makes (see [fetchHybridRoute]). Otherwise the journey
    /// would open on the outdoor map while the user is standing in a corridor.
    if (_indoorStartRoute != null) {
      _navigationMode = AppNavigationMode.indoor;
      _routeStatus = RouteStatus.indoorStartActive;
      notifyListeners();
      return;
    }

    _navigationMode = AppNavigationMode.outdoor;
    if (_hybridIndoorPath.isNotEmpty) {
      _routeStatus = RouteStatus.outdoorCompleted;
    }
    notifyListeners();
  }

  /// ======================================================
  /// BACKEND COMMUNICATION
  /// ======================================================
  ///
  /// Networking + JSON decoding only. Payload interpretation and
  /// all navigation state transitions stay in this provider.

  final HybridRouteService _routeService = HybridRouteService();

  /// ======================================================
  /// NAVIGATION MODE
  /// ======================================================
  ///
  /// The app starts in OUTDOOR mode (fullscreen Google Maps). Indoor mode is
  /// entered only via the hybrid transition (e.g. "Enter Building"), never at
  /// startup. (Previously defaulted to indoor for BLE/indoor debugging.)

  AppNavigationMode _navigationMode =
      AppNavigationMode.outdoor;

  AppNavigationMode get navigationMode =>
      _navigationMode;

  /// ======================================================
  /// NAVIGATION STATE
  /// ======================================================

  bool isNavigating = false;

  /// First backend outdoor instruction — the initial banner text / fallback.
  String currentOutdoorInstruction = "";

  /// Full backend outdoor turn-by-turn list, 1:1 with [outdoorRoute] nodes
  /// (instruction[i] is the maneuver at route node[i]). The banner derives the
  /// live instruction from this by the user's nearest route index. Stored data
  /// only — no navigation-state mutation.
  List<String> _outdoorInstructions = [];

  List<String> get outdoorInstructions =>
      _outdoorInstructions;

  /// ======================================================
  /// ROUTE STATUS
  /// ======================================================

  RouteStatus _routeStatus =
      RouteStatus.idle;

  RouteStatus get routeStatus =>
      _routeStatus;

  bool get isOutdoorCompleted =>
      _routeStatus ==
          RouteStatus.outdoorCompleted;

  /// ======================================================
  /// BUILDING STATE
  /// ======================================================

  String? _selectedBuildingId = kDefaultIndoorBuildingId;

  String? get selectedBuildingId =>
      _selectedBuildingId;

  /// ======================================================
  /// LOADING + ERROR
  /// ======================================================

  bool _isFetchingRoute = false;

  bool get isFetchingRoute =>
      _isFetchingRoute;

  String? _lastErrorMessage;

  String? get lastErrorMessage =>
      _lastErrorMessage;

  /// ======================================================
  /// SOURCE LOCATION
  /// ======================================================

  double? _sourceLat;

  double? _sourceLng;

  double? get sourceLat =>
      _sourceLat;

  double? get sourceLng =>
      _sourceLng;

  /// Set GPS source location
  void setSourceLocation({
    required double latitude,
    required double longitude,
  }) {

    _sourceLat = latitude;

    _sourceLng = longitude;

    notifyListeners();
  }

  /// ======================================================
  /// OUTDOOR ROUTE
  /// ======================================================

  List<LatLng> _outdoorRoute = [];

  List<LatLng> get outdoorRoute =>
      _outdoorRoute;

  void setOutdoorRoute(
      List<LatLng> route,
      ) {

    _outdoorRoute = route;

    notifyListeners();
  }

  /// ======================================================
  /// HYBRID INDOOR PATH (preloaded)
  /// ======================================================
  ///
  /// Indoor route nodes parsed from a "hybrid" backend response, kept here
  /// so the call-site can hand them to IndoorNavigationProvider right after
  /// the fetch. This preloads the indoor route for the manual
  /// "Enter Building" transition; it does NOT auto-switch modes.

  List<IndoorNode> _hybridIndoorPath = [];

  List<IndoorNode> get hybridIndoorPath =>
      _hybridIndoorPath;

  /// Backend indoor turn-by-turn text, 1:1 with [hybridIndoorPath] nodes
  /// (instruction[i] is the maneuver at node[i], e.g. "Go to floor 1" at a
  /// stair node). Preloaded with the path so the indoor instruction card is
  /// ready on "Enter Building".
  List<String> _hybridIndoorInstructions = [];

  List<String> get hybridIndoorInstructions =>
      _hybridIndoorInstructions;

  /// ======================================================
  /// TRANSITION INSTRUCTION (backend-authored)
  /// ======================================================
  ///
  /// The "enter the building" text from a hybrid response's transition
  /// node, surfaced on the Enter Building control. Null when absent.

  String? _transitionInstruction;

  String? get transitionInstruction =>
      _transitionInstruction;

  /// ======================================================
  /// TRANSITION CONTEXT + PHASE
  /// ======================================================
  ///
  /// Anchors for the outdoor↔indoor transition, taken from a hybrid
  /// response's transition node: the outdoor entrance node and the indoor
  /// start node. These are future anchors for threshold activation, entrance
  /// snapping, indoor continuity, and blue-dot handoff. Null when absent.

  String? _transitionOutdoorNode;

  String? get transitionOutdoorNode =>
      _transitionOutdoorNode;

  String? _transitionIndoorNode;

  String? get transitionIndoorNode =>
      _transitionIndoorNode;

  /// ======================================================
  /// NEW MULTI-SEGMENT HYBRID DATA (Phase 3 — STORAGE ONLY)
  /// ======================================================
  ///
  /// Segments from the new hybrid response
  /// (indoorStart → exitTransition → outdoor → enterTransition →
  /// indoorDestination), reusing the existing route/transition models. These
  /// are STORED ONLY: nothing consumes them yet, so the live navigation flow,
  /// rendering, building selection and Enter Building are all unchanged. They
  /// stay null for old-format responses, preserving backward compatibility.

  IndoorRoute? _indoorStartRoute;
  IndoorRoute? get indoorStartRoute => _indoorStartRoute;

  OutdoorRoute? _outdoorSegment;
  OutdoorRoute? get outdoorSegment => _outdoorSegment;

  IndoorRoute? _indoorDestinationRoute;
  IndoorRoute? get indoorDestinationRoute => _indoorDestinationRoute;

  ExitTransition? _exitTransition;
  ExitTransition? get exitTransition => _exitTransition;

  EnterTransition? _enterTransition;
  EnterTransition? get enterTransition => _enterTransition;

  double? _totalIndoorDistance;
  double? get totalIndoorDistance => _totalIndoorDistance;

  /// ======================================================
  /// ACTIVE INDOOR ROUTE (Phase 5A — abstraction only)
  /// ======================================================
  ///
  /// The single "active" indoor route the app is (conceptually) navigating.
  /// Introduced so later phases can switch this from the source-building route
  /// to the destination-building route WITHOUT any renderer knowing there are
  /// two. It is initialised from [indoorStartRoute] when a new multi-segment
  /// hybrid arrives; otherwise it stays null and the existing behaviour is
  /// preserved. NOTHING consumes it yet — the indoor rendering pipeline still
  /// reads [hybridIndoorPath] exactly as before, so nothing visible changes.
  IndoorRoute? _currentIndoorRoute;
  IndoorRoute? get currentIndoorRoute => _currentIndoorRoute;

  /// Which indoor leg the NEXT enter-building transition activates. Provider-
  /// only state — NOT a RouteStatus value and NOT exposed to the UI; used
  /// solely to decide which prepared indoor route becomes active. 0 = first
  /// indoor segment (source / indoorStart), 1 = second (destination /
  /// indoorDestination). Advanced once per completed enter transition; reset on
  /// each route load.
  int _indoorLegIndex = 0;

  /// Rebuilds the single rendered indoor path ([hybridIndoorPath]) from the
  /// active indoor route ([_currentIndoorRoute]). [legacyFallback] is used only
  /// when no active route is set (old-format hybrids with no indoorStart). This
  /// is the ONE place the rendered indoor path is derived — shared by the
  /// initial route load (Phase 5B) and the Phase 6 route switch — so there is
  /// no duplicated logic. The renderer keeps consuming [hybridIndoorPath] and
  /// never learns more than one indoor route exists.
  void _rebuildHybridIndoorPath({IndoorRoute? legacyFallback}) {
    final active = _currentIndoorRoute ?? legacyFallback;
    _hybridIndoorPath = active?.path ?? <IndoorNode>[];
  }

  /// Current transition lifecycle phase (see [IndoorTransitionPhase]).
  IndoorTransitionPhase _transitionPhase =
      IndoorTransitionPhase.none;

  IndoorTransitionPhase get transitionPhase =>
      _transitionPhase;

  /// Shared timing for the transition scrim. The provider sequences the
  /// lifecycle against these; the overlay animates its opacity over
  /// [transitionScrimFade]. Single source of truth so "swap at peak opacity"
  /// stays coordinated without any widget→provider animation callbacks.
  static const Duration transitionScrimFade =
      Duration(milliseconds: 260);

  static const Duration transitionHold =
      Duration(milliseconds: 140);

  /// Guards against overlapping transitions (rapid re-taps / a trigger firing
  /// mid-animation). Only one enter transition may be in flight.
  bool _transitionInFlight = false;

  /// Whether to offer manual "Enter Building" right now: actively navigating a
  /// hybrid route (indoor destination + preloaded indoor path) while still
  /// outdoors and not mid-transition. Shown from the moment hybrid navigation
  /// starts, at ANY distance — it doubles as the "this route continues
  /// indoors" indicator, and lets the user open the indoor view early.
  ///
  /// Tapping it runs the same provider-owned [enterIndoorTransition]; the
  /// near-threshold auto-transition still fires on its own if the user never
  /// taps (the two are parallel paths into one transition lifecycle).
  bool get canEnterBuilding =>
      isNavigating &&
      _navigationMode == AppNavigationMode.outdoor &&
      _transitionPhase == IndoorTransitionPhase.none &&
      _transitionIndoorNode != null &&
      _hybridIndoorPath.isNotEmpty;

  /// ======================================================
  /// AUTO-TRANSITION TRIGGER
  /// ======================================================
  ///
  /// Owns the debounce + single-fire lifecycle around the pure
  /// [AutoTransitionEvaluator]. The driver (RealtimePositionProvider) feeds
  /// live inputs via [evaluateAutoTransition]; only this provider decides
  /// whether the transition lifecycle proceeds.
  ///
  /// MASTER FLAG is ON: near-threshold auto-transition fires on its own
  /// (conservative guards: within entranceRadiusMeters of the entrance, a
  /// strong beacon, and requiredConsecutiveHits ticks). The manual "Enter
  /// Building" control in the nav card is the earlier/explicit path; both
  /// drive the same provider-owned [enterIndoorTransition]. Can be toggled off
  /// via [setAutoTransitionEnabled] for field calibration.

  /// Entrance radius tightened from the evaluator's 15 m default to 8 m: at
  /// 15 m the user is still on the outdoor approach (and a -70 dBm beacon is
  /// detectable ~15-25 m out), so the transition fired while they were clearly
  /// still outdoors. 8 m corresponds to being genuinely AT the entrance. The
  /// beacon-strength (-70) and 3-consecutive-hit guards are unchanged, so the
  /// trigger order/lifecycle is identical — only the proximity gate is tighter.
  /// Field-tunable.
  final AutoTransitionEvaluator _autoTransitionEvaluator =
      const AutoTransitionEvaluator(
    config: AutoTransitionConfig(
      entranceRadiusMeters: 8,
    ),
  );

  /// Auto-fire enabled: manual + automatic transition coexist (whichever
  /// threshold is crossed first).
  bool _autoTransitionEnabled = true;

  /// Consecutive eligible evaluations (debounce). Reset on any ineligible
  /// tick; fires only at [AutoTransitionConfig.requiredConsecutiveHits].
  int _autoTransitionHits = 0;

  /// Single-fire protection for the current route.
  bool _autoTransitionFired = false;

  bool get autoTransitionFired =>
      _autoTransitionFired;

  void _resetAutoTransition() {
    _autoTransitionHits = 0;
    _autoTransitionFired = false;
  }

  /// ======================================================
  /// ACTIVE ENTRANCE
  /// ======================================================

  double? _activeEntranceLat;

  double? _activeEntranceLng;

  double? get activeEntranceLat =>
      _activeEntranceLat;

  double? get activeEntranceLng =>
      _activeEntranceLng;

  /// Highlight active entrance
  void setActiveEntrance({
    required double latitude,
    required double longitude,
  }) {

    _activeEntranceLat = latitude;

    _activeEntranceLng = longitude;

    notifyListeners();
  }

  void clearActiveEntrance() {

    _activeEntranceLat = null;

    _activeEntranceLng = null;

    notifyListeners();
  }

  /// ======================================================
  /// BUILDING SELECTION
  /// ======================================================

  void selectOutdoorBuilding(
      String buildingId,
      ) {

    _selectedBuildingId =
        buildingId;

    _routeStatus =
        RouteStatus.destinationSelected;

    notifyListeners();
  }

  /// ======================================================
  /// OUTDOOR COMPLETION
  /// ======================================================

  void markOutdoorCompleted() {

    _routeStatus =
        RouteStatus.outdoorCompleted;

    notifyListeners();
  }

  /// ======================================================
  /// RESET OUTDOOR STATE
  /// ======================================================

  void resetOutdoor() {

    _selectedBuildingId = null;

    _routeStatus =
        RouteStatus.idle;

    _uiState = NavigationUiState.idle;
    _selectedPlace = null;

    _sourceLat = null;

    _sourceLng = null;

    _activeEntranceLat = null;

    _activeEntranceLng = null;

    _outdoorRoute = [];

    _isFetchingRoute = false;

    _lastErrorMessage = null;

    _resetAutoTransition();

    notifyListeners();
  }

  /// Full backend instruction list from a raw JSON `instructions` value, or an
  /// empty list when absent. Each entry is 1:1 with a route node.
  static List<String> _instructionsList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  /// Returns the first backend instruction string from a raw JSON
  /// `instructions` value, or null when absent/empty.
  static String? _firstInstruction(dynamic raw) {
    if (raw is List && raw.isNotEmpty) {
      return raw.first.toString();
    }
    return null;
  }

  /// ======================================================
  /// FETCH OUTDOOR ROUTE
  /// ======================================================

  Future<void> fetchOutdoorRoute({
    required double destinationLat,
    required double destinationLng,
    bool isPreview = false,
  }) async {

    final lat = sourceLat;

    final lng = sourceLng;

    if (lat == null || lng == null) {
      return;
    }

    try {

      _isFetchingRoute = true;

      /// Clear any prior failure so a fresh fetch starts clean (mirrors the
      /// hybrid path). Set again in catch if this request fails/times out.
      _lastErrorMessage = null;

      notifyListeners();

      final json =
      await _routeService.fetchRouteJson(
        userLat: lat,
        userLng: lng,
        endLat: destinationLat,
        endLng: destinationLng,
      );

      final path =
      json["path"] as List;

      _outdoorRoute =
          path.map((node) {

            return LatLng(
              node["latitude"],
              node["longitude"],
            );

          }).toList();

      /// Surface backend turn-by-turn text when provided.
      _outdoorInstructions = _instructionsList(json["instructions"]);
      final firstInstruction =
          _firstInstruction(json["instructions"]);
      if (firstInstruction != null) {
        currentOutdoorInstruction = firstInstruction;
      }

      _calculateRouteMetrics();

    } catch (e) {

      debugPrint(
        "Outdoor route error: $e",
      );

      /// Surface the failure (incl. request timeout) so the loading overlay is
      /// replaced by the error banner instead of silently returning to the map.
      _lastErrorMessage = "Route failed";

    } finally {

      _isFetchingRoute = false;

      notifyListeners();
    }
  }

  /// ======================================================
  /// FETCH HYBRID ROUTE
  /// ======================================================

  Future<void> fetchHybridRoute({
    String? destinationIndoorNode,
    String? startIndoorNode,
    double? endLat,
    double? endLng,
    bool isPreview = false,
  }) async {

    debugPrint(
      "🚀 fetchHybridRoute CALLED",
    );

    if (_sourceLat == null ||
        _sourceLng == null) {

      debugPrint(
        "Source location not set.",
      );

      return;
    }

    /// The building the user is currently INSIDE, captured before the response
    /// overwrites the selection. A multi-segment hybrid's first leg is walked
    /// inside this building, so it — not the destination — must stay selected
    /// until the enter-building transition (otherwise the source building's
    /// route would be drawn on the destination building's floor plan).
    final previousBuildingId = _selectedBuildingId;

    try {

      _isFetchingRoute = true;

      _lastErrorMessage = null;

      notifyListeners();

      /// ==================================================
      /// BACKEND CALL
      /// ==================================================
      ///
      /// Source + (optional) outdoor destination + (optional)
      /// indoor destination. Networking/decoding is delegated;
      /// payload interpretation stays here, unchanged.

      final json =
      await _routeService.fetchRouteJson(
        userLat: _sourceLat,
        userLng: _sourceLng,
        endLat: endLat,
        endLng: endLng,
        startIndoorNode: startIndoorNode,
        destinationIndoorNode: destinationIndoorNode,
      );

      final type =
      json["type"];

      debugPrint(
        "Route type: $type",
      );

      /// Clear previous outdoor route
      _outdoorRoute = [];
      _outdoorInstructions = [];

      /// Clear previous hybrid indoor path (set again only for "hybrid")
      _hybridIndoorPath = [];
      _hybridIndoorInstructions = [];

      /// Clear previous transition text + context (set again only for "hybrid")
      _transitionInstruction = null;
      _transitionOutdoorNode = null;
      _transitionIndoorNode = null;

      /// Clear previous new multi-segment hybrid data (set again only for
      /// "hybrid"). Storage only — nothing consumes these yet.
      _indoorStartRoute = null;
      _outdoorSegment = null;
      _indoorDestinationRoute = null;
      _exitTransition = null;
      _enterTransition = null;
      _totalIndoorDistance = null;

      /// Clear the active indoor route (set again below only when a new
      /// multi-segment hybrid provides an indoorStart). Storage only.
      _currentIndoorRoute = null;

      /// New trip → the next enter-building transition activates the FIRST
      /// indoor leg again.
      _indoorLegIndex = 0;

      /// A new route resets the auto-transition trigger (debounce + fired).
      _resetAutoTransition();

      /// ==================================================
      /// OUTDOOR ROUTE
      /// ==================================================

      if (type == "outdoor") {

        final path =
        json["path"] as List;

        _outdoorRoute =
            path.map((node) {

              return LatLng(
                node["latitude"],
                node["longitude"],
              );

            }).toList();

        /// Surface backend turn-by-turn text when provided.
        _outdoorInstructions = _instructionsList(json["instructions"]);
        final firstInstruction =
            _firstInstruction(json["instructions"]);
        if (firstInstruction != null) {
          currentOutdoorInstruction = firstInstruction;
        }

        if (!isPreview) {
          _navigationMode = AppNavigationMode.outdoor;
        }
      }

      /// ==================================================
      /// INDOOR ROUTE
      /// ==================================================

      else if (type == "indoor") {

        /// Context-aware indoor-only route (Case 2: the user is already inside
        /// the destination building). The backend returns the indoor path +
        /// turn-by-turn at the TOP level (same node shape as a hybrid's
        /// indoor.path), starting at the requested startIndoorNode — so the
        /// user's current node becomes the route origin. Parsed into the same
        /// _hybridIndoorPath / _hybridIndoorInstructions the call-site hands to
        /// IndoorNavigationProvider, reusing the existing indoor pipeline.
        final indoorPath = json["path"] as List?;

        _hybridIndoorPath = indoorPath == null
            ? []
            : indoorPath
                .map((n) => IndoorNode.fromJson(
                      n as Map<String, dynamic>,
                    ))
                .toList();

        _hybridIndoorInstructions =
            _instructionsList(json["instructions"]);

        /// TARGET BUILDING — Case 2 routes WITHIN the building the user is
        /// already inside, which is the one currently rendered
        /// ([_selectedBuildingId]); keep it so the indoor SVG stays correct.
        /// It can be null here only after a resetOutdoor, so fall back to the
        /// selected destination's building id and finally the default, so the
        /// indoor renderer always has a building to select (otherwise the map
        /// shows "coming soon"). No node-prefix parsing, no new state.
        _selectedBuildingId =
            _selectedBuildingId ??
                _selectedPlace?.id ??
                kDefaultIndoorBuildingId;

        if (!isPreview) {
          /// Straight into indoor mode — no outdoor map, no "Enter Building".
          _navigationMode = AppNavigationMode.indoor;
          _routeStatus = RouteStatus.indoorActive;
        }
      }

      /// ==================================================
      /// HYBRID ROUTE
      /// ==================================================

      else if (type == "hybrid") {

        /// OUTDOOR PATH
        final outdoor =
        json["outdoor"]["path"] as List;

        _outdoorRoute =
            outdoor.map((node) {

              return LatLng(
                node["latitude"],
                node["longitude"],
              );

            }).toList();

        /// INDOOR INSTRUCTIONS (Phase 8). Unchanged in this phase — Phase 5B
        /// re-sources only the indoor PATH (see below), not the instructions,
        /// which still come from the legacy `indoor` segment.
        _hybridIndoorInstructions =
            _instructionsList(json["indoor"]?["instructions"]);

        /// Surface backend outdoor turn-by-turn + transition text (Phase 8).
        _outdoorInstructions =
            _instructionsList(json["outdoor"]?["instructions"]);
        final firstInstruction =
            _firstInstruction(json["outdoor"]?["instructions"]);
        if (firstInstruction != null) {
          currentOutdoorInstruction = firstInstruction;
        }

        _transitionInstruction =
            json["transition"]?["instruction"] as String?;

        /// Transition anchors (entrance + indoor start) for the
        /// outdoor->indoor handoff. Future threshold/BLE activation and
        /// transition animations key off these.
        _transitionOutdoorNode =
            json["transition"]?["outdoorNode"] as String?;
        _transitionIndoorNode =
            json["transition"]?["indoorNode"] as String?;

        /// A multi-segment hybrid carries no legacy `transition` key — its
        /// outdoor->indoor handoff lives in `enterTransition`. Fill the SAME
        /// anchors from it so the enter-building lifecycle (Enter Building
        /// control, transition scrim label, auto-transition anchors) behaves
        /// identically on a cross-building trip. Old-format responses are
        /// untouched: enterTransition is null for them.
        final enterJson =
            json["enterTransition"] as Map<String, dynamic>?;
        if (enterJson != null) {
          _transitionInstruction ??= enterJson["instruction"] as String?;
          _transitionOutdoorNode ??= enterJson["outdoorNode"] as String?;
          _transitionIndoorNode ??= enterJson["indoorNode"] as String?;
        }

        /// NEW MULTI-SEGMENT HYBRID DATA (Phase 3 — STORAGE ONLY).
        /// Parse the full response once via HybridRouteResult (Phase 2) and
        /// store each new segment. Nothing reads these yet — the existing
        /// hybrid parsing above and all downstream behaviour are unchanged;
        /// old-format responses leave every field null.
        final hybridResult = HybridRouteResult.fromJson(json);
        _indoorStartRoute = hybridResult.indoorStart;
        _outdoorSegment = hybridResult.outdoor;
        _indoorDestinationRoute = hybridResult.indoorDestination;
        _exitTransition = hybridResult.exitTransition;
        _enterTransition = hybridResult.enterTransition;
        _totalIndoorDistance = hybridResult.totalIndoorDistance;

        /// ACTIVE INDOOR ROUTE (Phase 5A). Initialise the single active indoor
        /// route to the SOURCE-building leg when the new multi-segment hybrid
        /// provides one. Assigned exactly once here, during route loading. When
        /// indoorStart is absent (old-format hybrid) this is skipped and the
        /// existing behaviour is preserved. Not consumed by any renderer yet.
        if (_indoorStartRoute != null) {
          _currentIndoorRoute = _indoorStartRoute;
        }

        /// INDOOR PATH (Phase 5B). The ONE rendered indoor path is now sourced
        /// from the single active indoor route [currentIndoorRoute] (set just
        /// above from indoorStart). For legacy old-format hybrids that carry no
        /// indoorStart — so currentIndoorRoute stays null and, per plan, is not
        /// assigned elsewhere — it falls back to the existing `indoor` segment,
        /// keeping old-format rendering byte-for-byte unchanged. One assignment,
        /// one code path; the `??` is null-coalescing, not start/destination
        /// branching. Preloaded so the route is ready when the user taps "Enter
        /// Building"; mode/status unchanged here. The renderer still consumes
        /// [hybridIndoorPath] and remains unaware two indoor routes exist.
        _rebuildHybridIndoorPath(legacyFallback: hybridResult.indoor);

        /// TARGET BUILDING — the destination the user selected drives which
        /// indoor building (and thus which SVG) the renderer loads. SearchPlace
        /// ids ARE building ids (unified search preserves the id via copyWith),
        /// so an AB-III destination selects AB-III instead of the default. Falls
        /// back to the default only when no destination place is set. No
        /// node-prefix parsing, no new state — reuses the existing selection.
        ///
        /// EXCEPTION — a multi-segment hybrid starts INSIDE the source
        /// building, so its first leg must keep rendering that building. The
        /// destination building is selected later, by the enter-building
        /// transition (the one place that already switches indoor legs).
        _selectedBuildingId = _indoorStartRoute != null
            ? (previousBuildingId ?? kDefaultIndoorBuildingId)
            : (_selectedPlace?.id ?? kDefaultIndoorBuildingId);

        /// INDOOR LEG BOOKKEEPING. [_indoorLegIndex] names the leg the NEXT
        /// enter-building transition activates. A journey that begins indoors
        /// consumes its first indoor leg here, at load, without a transition —
        /// so the next enter transition is already the SECOND leg. Old-format
        /// hybrids still begin outdoors and leave it at 0.
        if (_indoorStartRoute != null) {
          _indoorLegIndex = 1;
        }

        if (!isPreview) {
          if (_indoorStartRoute != null) {
            /// Journey begins inside the source building.
            _navigationMode = AppNavigationMode.indoor;
            _routeStatus = RouteStatus.indoorStartActive;
          } else {
            /// Start outdoors first
            _navigationMode = AppNavigationMode.outdoor;

            /// Outdoor active initially
            _routeStatus = RouteStatus.outdoorCompleted;
          }
        }
      }

      _calculateRouteMetrics();

    } catch (e) {

      debugPrint(
        "🔥 ERROR in fetchHybridRoute: $e",
      );

      _lastErrorMessage =
      "Route failed";

    } finally {

      _isFetchingRoute = false;

      notifyListeners();
    }
  }

  /// ======================================================
  /// MODE SWITCHING
  /// ======================================================

  void switchToOutdoor() {

    _navigationMode =
        AppNavigationMode.outdoor;

    resetOutdoor();
  }

  void switchToIndoor() {

    _navigationMode =
        AppNavigationMode.indoor;

    _routeStatus =
        RouteStatus.indoorActive;

    notifyListeners();
  }

  /// ======================================================
  /// TRANSITION LIFECYCLE
  /// ======================================================
  ///
  /// Single entrypoints for the outdoor↔indoor transition. They wrap the
  /// existing [switchToIndoor] / [switchToOutdoor] (unchanged) and pulse the
  /// transition phase around them. Today the switch is synchronous, so the
  /// phase pulses none → entering/exiting → none. This is the seam that the
  /// future automatic trigger (GPS threshold / BLE) and transition animations
  /// will call/observe — without further lifecycle changes. No trigger logic
  /// or animation timing lives here yet.

  void enterIndoorTransition() {

    /// Single in-flight transition (rapid re-taps / auto-trigger mid-anim).
    if (_transitionInFlight) return;
    _transitionInFlight = true;

    /// TEMP TRACE
    debugPrint(
      "[TRANSITION] enterIndoorTransition() called"
      " (phase=enteringIndoor)",
    );

    /// 1) Begin — scrim fades in over [transitionScrimFade].
    _transitionPhase =
        IndoorTransitionPhase.enteringIndoor;
    notifyListeners();

    /// 2) Swap at peak opacity — the scrim now covers the scene, so the map
    ///    rebuild / SVG layout / overlay-condition changes are hidden. Timing
    ///    is provider-owned; the overlay independently interpolates opacity
    ///    over the same shared duration.
    Future.delayed(transitionScrimFade, () {

      /// TEMP TRACE
      debugPrint(
        "[TRANSITION] switchToIndoor() at peak opacity"
        " (mode=indoor)",
      );

      /// INDOOR-ROUTE ACTIVATION. At peak opacity (hidden by the scrim), pick
      /// which prepared indoor route becomes active for this leg and rebuild
      /// the rendered path through the single shared helper. First enter →
      /// indoorStart, second → indoorDestination. The null guards leave
      /// old-format hybrids (both routes null) on their existing path — never
      /// wiping it. Reuses currentIndoorRoute + _rebuildHybridIndoorPath: one
      /// renderer-update path, no duplicated transition, no building switch.
      if (_indoorLegIndex == 0) {
        if (_indoorStartRoute != null) {
          _currentIndoorRoute = _indoorStartRoute;
          _rebuildHybridIndoorPath();
        }
      } else {
        if (_indoorDestinationRoute != null) {
          _currentIndoorRoute = _indoorDestinationRoute;
          _rebuildHybridIndoorPath();
        }

        /// Entering the DESTINATION building of a cross-building journey — the
        /// one moment the rendered building legitimately changes, so the indoor
        /// renderer loads its floor plans (e.g. ECE instead of CSE). Guarded on
        /// a destination leg actually existing, so single-building trips (which
        /// never reach leg 1 with a destination route) are unaffected.
        if (_indoorDestinationRoute != null && _selectedPlace != null) {
          _selectedBuildingId = _selectedPlace!.id;
        }
      }
      _indoorLegIndex++;

      switchToIndoor();

      /// 3) Hold briefly, then clear — scrim fades out, revealing indoor.
      Future.delayed(transitionHold, () {

        _transitionPhase =
            IndoorTransitionPhase.none;

        _transitionInFlight = false;

        notifyListeners();
      });
    });
  }

  void exitIndoorTransition() {

    /// Single in-flight transition. The caller re-checks its own guard each
    /// build, and the route switch below only lands at peak opacity, so
    /// without this a second build could re-enter mid-animation.
    if (_transitionInFlight) return;
    _transitionInFlight = true;

    debugPrint(
      "[TRANSITION] exitIndoorTransition() called"
      " (phase=exitingIndoor)",
    );

    /// The scrim reads its label from [transitionInstruction]; while exiting,
    /// the backend-authored exit text ("Exit the building") is the correct one.
    _transitionInstruction =
        _exitTransition?.instruction ?? _transitionInstruction;

    /// 1) Begin — scrim fades in over [transitionScrimFade].
    _transitionPhase =
        IndoorTransitionPhase.exitingIndoor;

    notifyListeners();

    /// 2) Swap at peak opacity, mirroring [enterIndoorTransition] so both
    ///    directions of the seam are hidden by the same scrim timing.
    Future.delayed(transitionScrimFade, () {

      /// PHASE 6 — FIRST ROUTE SWITCH. At the exit-building transition (first
      /// indoor segment done → heading outdoors), if the new multi-segment
      /// hybrid provided a destination-building indoor route, make it the active
      /// indoor route and rebuild the rendered path through the SAME shared
      /// helper used at load. ONLY the active indoor route changes — no building,
      /// no selectedBuildingId, no floor, no SVG reload. The renderer just
      /// receives the updated hybridIndoorPath as before and stays unaware two
      /// indoor routes exist.
      if (_indoorDestinationRoute != null) {
        _currentIndoorRoute = _indoorDestinationRoute;
        _rebuildHybridIndoorPath();
      }

      /// MODE ONLY — deliberately NOT [switchToOutdoor], which calls
      /// resetOutdoor() and would wipe the selected place, the source location
      /// and the outdoor polyline. That is the right behaviour for the user
      /// leaving indoor mode (back gesture / Done), but here the journey is
      /// mid-flight: the outdoor middle leg and the destination indoor leg are
      /// still ahead, and the outdoor route already loaded at fetch time is
      /// exactly the polyline the user now walks.
      _navigationMode = AppNavigationMode.outdoor;
      _routeStatus = RouteStatus.outdoorActive;

      /// The next transition is an ENTER, so restore its label for the scrim.
      _transitionInstruction =
          _enterTransition?.instruction ?? _transitionInstruction;

      notifyListeners();

      /// 3) Hold briefly, then clear — scrim fades out, revealing outdoor.
      Future.delayed(transitionHold, () {

        _transitionPhase =
            IndoorTransitionPhase.none;

        _transitionInFlight = false;

        notifyListeners();
      });
    });
  }

  /// Enables/disables automatic firing. OFF by default this phase; a later
  /// phase (and tests) can turn it on after threshold tuning.
  void setAutoTransitionEnabled(bool value) {
    _autoTransitionEnabled = value;
  }

  /// Feeds one realtime snapshot into the auto-transition pipeline. Called by
  /// the driver (RealtimePositionProvider) every tick. Runs the pure
  /// evaluator, maintains the debounce counter, always logs telemetry, and —
  /// only when debounced AND enabled — fires the transition exactly once.
  ///
  /// This is the SOLE entrypoint by which realtime inputs may influence the
  /// transition lifecycle; the driver never switches modes itself.
  void evaluateAutoTransition(AutoTransitionInputs inputs) {

    final decision =
        _autoTransitionEvaluator.evaluate(inputs);

    if (decision.eligible) {
      _autoTransitionHits++;
    } else {
      _autoTransitionHits = 0;
    }

    /// Telemetry — invaluable for threshold/BLE tuning while auto-fire is off.
    debugPrint(
      "AUTO-TRANSITION eval="
      "${decision.eligible ? 'ELIGIBLE' : decision.reason.name}"
      " hits=$_autoTransitionHits"
      " dist=${inputs.distanceToEntranceMeters?.toStringAsFixed(1)}"
      " rssi=${inputs.strongestRssi}",
    );

    final shouldFire = decision.eligible &&
        _autoTransitionHits >=
            _autoTransitionEvaluator
                .config.requiredConsecutiveHits;

    if (!shouldFire) return;

    if (!_autoTransitionEnabled) {
      debugPrint(
        "AUTO-TRANSITION would fire now "
        "(disabled by flag — no-op)",
      );
      return;
    }

    _autoTransitionFired = true;
    enterIndoorTransition();
  }

  /// ======================================================
  /// NAVIGATION MODE CONTROL
  /// ======================================================

  void startNavigationMode() {

    isNavigating = true;
    _uiState = NavigationUiState.navigating;

    notifyListeners();
  }

  void stopNavigationMode() {

    isNavigating = false;
    _uiState = NavigationUiState.idle;

    notifyListeners();
  }

  /// ======================================================
  /// OUTDOOR INSTRUCTION
  /// ======================================================

  void updateOutdoorInstruction(
      String instruction,
      ) {

    currentOutdoorInstruction =
        instruction;

    notifyListeners();
  }

  /// ======================================================
  /// STOP NAVIGATION
  /// ======================================================

  void stopNavigation() {

    isNavigating = false;
    _uiState = NavigationUiState.idle;

    currentOutdoorInstruction = "";
    _outdoorInstructions = [];

    notifyListeners();
  }
}
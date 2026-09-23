import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:provider/provider.dart';

import 'package:cognifind/core/enums/navigation_mode.dart';

import 'package:cognifind/providers/navigation_provider.dart';
import 'package:cognifind/providers/location_provider.dart';

import 'package:cognifind/core/data/campus_boundary.dart';

import 'package:cognifind/indoor_engine/providers/indoor_navigation_provider.dart';
import 'package:cognifind/ble_engine/providers/realtime_position_provider.dart';
import 'package:cognifind/features/navigation/utils/routing_strategy.dart';

import 'package:cognifind/screens/search/unified_search_screen.dart';

import 'package:cognifind/indoor_engine/widgets/indoor_map_widget.dart';
import 'package:cognifind/indoor_engine/widgets/floor_selector_widget.dart';
import 'package:cognifind/core/config/indoor_building_config.dart';

import 'package:cognifind/widgets/navigation/outdoor_map_widget.dart';
import 'package:cognifind/widgets/navigation/search_bar_widget.dart';
import 'package:cognifind/widgets/navigation/place_bottom_card.dart';
import 'package:cognifind/widgets/navigation/route_preview_card.dart';

import 'package:cognifind/features/navigation/presentation/widgets/navigation_instruction_banner.dart';
import 'package:cognifind/features/navigation/presentation/widgets/navigation_stats_card.dart';
import 'package:cognifind/features/navigation/presentation/widgets/navigation_error_banner.dart';
import 'package:cognifind/features/navigation/presentation/widgets/navigation_loading_overlay.dart';
import 'package:cognifind/features/navigation/presentation/widgets/transition_overlay.dart';

import 'package:cognifind/core/storage/token_storage.dart';

import 'package:cognifind/features/auth/presentation/login_screen.dart';

/// ======================================================
/// NAVIGATION SCREEN
/// ======================================================

class NavigationScreen extends StatelessWidget {

  const NavigationScreen({
    super.key,
  });

  /// ======================================================
  /// LOGOUT
  /// ======================================================

  Future<void> _logout(
      BuildContext context,
      ) async {

    final shouldLogout =
    await showDialog<bool>(

      context: context,

      builder: (context) {

        return AlertDialog(

          title: const Text(
            "Logout",
          ),

          content: const Text(
            "Are you sure you want to logout?",
          ),

          actions: [

            TextButton(

              onPressed: () {

                Navigator.pop(
                  context,
                  false,
                );
              },

              child: const Text(
                "Cancel",
              ),
            ),

            TextButton(

              onPressed: () {

                Navigator.pop(
                  context,
                  true,
                );
              },

              child: const Text(
                "Logout",
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    await TokenStorage.deleteToken();

    Navigator.pushAndRemoveUntil(

      context,

      MaterialPageRoute(
        builder: (_) =>
        const LoginScreen(),
      ),

          (route) => false,
    );
  }

  /// ======================================================
  /// ROUTE SOURCE + START (shared by both bottom sheets)
  /// ======================================================

  /// Sets the route source from live GPS, clamped to the campus boundary
  /// (same treatment as building-marker taps). Route fetches abort without a
  /// source, so this must run before Directions/Start — search-selected
  /// places never pass through the marker-tap path.
  ///
  /// Falls back to the campus center when there's no GPS fix yet (mirrors
  /// _onBuildingTap), so routing always has a valid source rather than
  /// silently producing an empty route.
  void _setRouteSource(BuildContext context) {

    final nav = context.read<NavigationProvider>();

    final raw =
        context.read<LocationProvider>().currentLocation ??
            campusCenter;

    final clamped = CampusBoundary.clampToCampus(
      raw.latitude,
      raw.longitude,
    );

    nav.setSourceLocation(
      latitude: clamped.lat,
      longitude: clamped.lng,
    );

    /// The indoor half of the source. Set on the SAME call that sets the GPS
    /// source, so the route preview and the actual navigation always request
    /// the same route — whether the trip starts on a path or in a corridor.
    nav.setIndoorOrigin(_currentIndoorNode(context));
  }

  /// The indoor node the user is standing on, or null when they are outdoors.
  ///
  /// Prefers the backend's own indoor fix (RealtimePositionProvider, driven by
  /// BLE trilateration) — that is the authoritative answer and works anywhere
  /// in a building, on-route or off. Falls back to the node the live indoor
  /// position has been snapped to on the rendered route, which is what is
  /// available whenever the indoor engine is supplying the position instead of
  /// the location API. Either way this is read, never estimated here.
  String? _currentIndoorNode(BuildContext context) {
    final realtime = context.read<RealtimePositionProvider>();
    if (realtime.isIndoor && realtime.currentIndoorNode != null) {
      return realtime.currentIndoorNode;
    }

    if (context.read<NavigationProvider>().navigationMode !=
        AppNavigationMode.indoor) {
      return null;
    }

    return context.read<IndoorNavigationProvider>().currentIndoorNode?.id;
  }

  /// Case 2: the user is already inside the destination building, so
  /// navigation should route indoors directly from their current node rather
  /// than building a hybrid outdoor→enter route — and there is no outdoor leg
  /// to preview, so Directions starts navigation immediately.
  ///
  /// A destination in a DIFFERENT building fails this check and keeps the
  /// normal preview→start flow; the backend then answers with the multi-segment
  /// indoor → outdoor → indoor route. Pure decision in [shouldRouteIndoorOnly];
  /// the context only supplies the inputs.
  bool _isIndoorOnlyTrip(BuildContext context) {
    final nav = context.read<NavigationProvider>();
    final place = nav.selectedPlace;
    final node = _currentIndoorNode(context);

    return shouldRouteIndoorOnly(
      isIndoor: node != null,
      currentIndoorNode: node,
      destinationNodeId: place?.destinationNodeId,
      destinationBuildingId: place?.id,

      /// The building the user is inside is the one currently rendered.
      indoorBuildingId:
          nav.selectedBuildingId ?? kDefaultIndoorBuildingId,
    );
  }

  /// Starts navigation for the currently selected place. If a route preview
  /// was already fetched, promotes it instead of re-fetching; otherwise
  /// fetches fresh. Hybrid indoor paths are handed to
  /// IndoorNavigationProvider so "Enter Building" shows them immediately.
  Future<void> _startNavigation(BuildContext context) async {

    final nav = context.read<NavigationProvider>();

    final indoorNav =
        context.read<IndoorNavigationProvider>();

    final place = nav.selectedPlace;
    if (place == null) return;

    _setRouteSource(context);

    /// Set by _setRouteSource above: non-null only while the user is indoors.
    /// Passing it lets the BACKEND choose the route shape — same building →
    /// an indoor-only route, different building → the multi-segment
    /// indoor → outdoor → indoor hybrid. The frontend never makes that call.
    final indoorOrigin = nav.indoorOriginNode;

    /// Captured before startNavigationMode() flips uiState to navigating.
    /// An indoor-only route carries no outdoor polyline, so this is false for
    /// Case 2 and the fetch below runs, as before.
    final hasPreviewRoute =
        nav.uiState == NavigationUiState.routePreview &&
            nav.outdoorRoute.isNotEmpty;

    nav.startNavigationMode();

    if (hasPreviewRoute) {
      nav.promotePreviewRoute();
    } else if (place.destinationNodeId != null) {
      await nav.fetchHybridRoute(
        startIndoorNode: indoorOrigin,
        destinationIndoorNode: place.destinationNodeId,
      );
    } else {
      await nav.fetchOutdoorRoute(
        destinationLat: place.latitude,
        destinationLng: place.longitude,
      );
    }

    final indoorPath = nav.hybridIndoorPath;
    if (indoorPath.isNotEmpty) {
      indoorNav.setIndoorPath(indoorPath);
      indoorNav.setInstructions(nav.hybridIndoorInstructions);
    }
  }

  /// ======================================================
  /// BUILD
  /// ======================================================

  @override
  Widget build(
      BuildContext context,
      ) {

    final navigationProvider =
    context.watch<NavigationProvider>();

    /// REACTIVE INDOOR-PATH BRIDGE.
    ///
    /// This build re-runs whenever NavigationProvider notifies (it is watched
    /// above), including when the active indoor route switches and
    /// hybridIndoorPath is rebuilt. Re-run the SAME handoff used at start —
    /// setIndoorPath / setInstructions — so IndoorNavigationProvider (and thus
    /// IndoorMapCanvas) picks up the new route. Dedup without any extra state:
    /// _rebuildHybridIndoorPath produces a NEW list on change, and after a push
    /// IndoorNavigationProvider holds that exact instance, so an identity check
    /// against its current path fires the push ONLY on a genuine change — never
    /// on unrelated rebuilds. Deferred to post-frame because setIndoorPath
    /// notifies listeners, which is illegal during build. No polling, no timers.
    final indoorNav =
    context.read<IndoorNavigationProvider>();
    final latestIndoorPath = navigationProvider.hybridIndoorPath;
    if (latestIndoorPath.isNotEmpty &&
        !identical(latestIndoorPath, indoorNav.indoorPath)) {
      final latestIndoorInstructions =
          navigationProvider.hybridIndoorInstructions;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        /// Re-check identity: another change may have landed between schedule
        /// and frame, and the guard keeps the push idempotent.
        if (!identical(latestIndoorPath, indoorNav.indoorPath)) {
          indoorNav.setIndoorPath(latestIndoorPath);
          indoorNav.setInstructions(latestIndoorInstructions);
        }
      });
    }

    return PopScope(

      /// Always intercept the system back gesture; the decision to actually
      /// leave the screen is made below based on navigation state. (Migrated
      /// from the deprecated WillPopScope, which Android 13+ predictive back
      /// no longer honors — back was exiting the app instead of switching
      /// to outdoor mode.)
      canPop: false,

      onPopInvokedWithResult: (didPop, result) {

        if (didPop) return;

        final nav =
        context.read<NavigationProvider>();

        /// STOP NAVIGATION
        if (nav.isNavigating) {

          nav.stopNavigation();

          return;
        }

        /// STEP BACK THROUGH SELECTION OVERLAYS
        /// (route preview → place sheet → clean map)
        if (nav.uiState ==
            NavigationUiState.routePreview) {

          nav.backToPlaceSelected();

          return;
        }

        if (nav.uiState ==
            NavigationUiState.placeSelected) {

          nav.clearSelection();

          return;
        }

        /// SWITCH BACK TO OUTDOOR
        if (nav.navigationMode ==
            AppNavigationMode.indoor) {

          nav.switchToOutdoor();

          return;
        }

        /// Already outdoor and idle → leave the app, as before.
        SystemNavigator.pop();
      },

      child: Scaffold(

        /// ======================================================
        /// BODY — fullscreen map with floating overlays
        /// ======================================================
        ///
        /// Map-first architecture (Google Maps style): the map is the base
        /// layer and every control/card floats over it. No AppBar; the single
        /// account avatar lives in the floating search bar. Only overlays
        /// respect SafeArea — the map extends edge-to-edge.

        body: Stack(

          children: [

            /// ==================================================
            /// FULLSCREEN MAP (base layer)
            /// ==================================================

            Positioned.fill(

              child: AnimatedSwitcher(

                duration:
                const Duration(
                  milliseconds: 600,
                ),

                switchInCurve:
                Curves.easeIn,

                switchOutCurve:
                Curves.easeOut,

                child: _buildMapArea(
                  context,
                  navigationProvider,
                ),
              ),
            ),

            /// ==================================================
            /// TOP: FLOATING SEARCH BAR (single avatar)
            /// ==================================================

            if (!navigationProvider.isNavigating ||
                navigationProvider.navigationMode ==
                    AppNavigationMode.indoor)

              Positioned(

                top: 0,
                left: 0,
                right: 0,

                child: SafeArea(

                  bottom: false,

                  child: Padding(

                    padding:
                    const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      0,
                    ),

                    child: SearchBarWidget(

                      userName: "Farhan",

                      onProfile: () {},

                      onLogout: () =>
                          _logout(context),

                      /// ONE SEARCH, BOTH MODES. The unified screen searches
                      /// every building AND every room on campus, so it answers
                      /// indoor questions too — including the one the old
                      /// indoor-only screen could not: a room in a DIFFERENT
                      /// building than the one you are standing in. Keeping a
                      /// single entry point is also what makes the search feel
                      /// like one place rather than two that disagree about
                      /// what exists.
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const UnifiedSearchScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),

            /// ==================================================
            /// TOP: OUTDOOR INSTRUCTION BANNER
            /// ==================================================

            if (navigationProvider
                .isNavigating &&
                navigationProvider
                    .navigationMode ==
                    AppNavigationMode
                        .outdoor)

              const Positioned(

                top: 0,
                left: 0,
                right: 0,

                child: SafeArea(

                  bottom: false,

                  child: Padding(

                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      0,
                    ),

                    child:
                    NavigationInstructionBanner(),
                  ),
                ),
              ),

            /// ==================================================
            /// TOP: ERROR BANNER
            /// ==================================================

            if (navigationProvider
                .lastErrorMessage !=
                null)

              Positioned(

                top: 0,
                left: 0,
                right: 0,

                child: SafeArea(

                  bottom: false,

                  child: Padding(

                    padding: const EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      0,
                    ),

                    child: NavigationErrorBanner(
                      message: navigationProvider
                          .lastErrorMessage!,
                    ),
                  ),
                ),
              ),

            /// ==================================================
            /// BOTTOM: OUTDOOR STATS CARD
            /// ==================================================
            /// (The "Enter Building" control now lives inside this card and
            /// appears while approaching the destination — see
            /// NavigationStatsCard + NavigationProvider.canEnterBuilding.)

            if (navigationProvider
                .isNavigating &&
                navigationProvider
                    .navigationMode ==
                    AppNavigationMode
                        .outdoor)

              const Positioned(

                left: 0,
                right: 0,
                bottom: 0,

                child: SafeArea(

                  top: false,

                  child: Padding(

                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      20,
                    ),

                    child:
                    NavigationStatsCard(),
                  ),
                ),
              ),

            /// ==================================================
            /// BOTTOM SHEET OVERLAYS (Google Maps Style)
            /// ==================================================

            if (navigationProvider.uiState == NavigationUiState.placeSelected ||
                navigationProvider.uiState == NavigationUiState.routePreview)
              Positioned.fill(
                child: DraggableScrollableSheet(
                  initialChildSize: 0.22,
                  minChildSize: 0.18,
                  maxChildSize: 0.55,
                  builder: (context, scrollController) {
                    return SingleChildScrollView(
                      controller: scrollController,
                      child: navigationProvider.uiState == NavigationUiState.placeSelected
                          ? PlaceBottomCard(
                              place: navigationProvider.selectedPlace!,
                              onDirections: () {
                                _setRouteSource(context);

                                /// Case 2: already inside the destination
                                /// building — there is no outdoor leg to
                                /// preview, so start indoor navigation directly
                                /// instead of the outdoor route-preview card.
                                if (_isIndoorOnlyTrip(context)) {
                                  _startNavigation(context);
                                  return;
                                }

                                context
                                    .read<NavigationProvider>()
                                    .showRoutePreview();
                              },
                              onStart: () => _startNavigation(context),
                            )
                          : RoutePreviewCard(
                              distanceMeters: navigationProvider.routeDistanceMeters,
                              durationMinutes: navigationProvider.routeDurationMinutes,
                              includesIndoor: navigationProvider
                                  .hybridIndoorPath.isNotEmpty,
                              onStart: () => _startNavigation(context),
                            ),
                    );
                  },
                ),
              ),

            /// ==================================================
            /// LOADING OVERLAY (above everything)
            /// ==================================================

            if (navigationProvider
                .isFetchingRoute)

              const Positioned.fill(

                child: NavigationLoadingOverlay(),
              ),

            /// ==================================================
            /// TRANSITION SCRIM (topmost — bridges the mode swap)
            /// ==================================================
            ///
            /// Always present; self-manages visibility via opacity + input
            /// blocking based on transitionPhase.

            const Positioned.fill(

              child: TransitionOverlay(),
            ),
          ],
        ),
      ),
    );
  }

  /// ======================================================
  /// MAP AREA
  /// ======================================================

  Widget _buildMapArea(

      BuildContext context,

      NavigationProvider provider,
      ) {

    final indoorProvider =
    context.watch<
        IndoorNavigationProvider>();

    /// LEG-AWARE EXIT ORCHESTRATION.
    ///
    /// hasArrived only means "the active indoor path reached its final node" —
    /// it fires for BOTH the indoorStart leg and the final destination. Fire
    /// exitIndoorTransition() ONLY when the completed leg is the FIRST one:
    /// the active route is still indoorStartRoute (identity) AND a destination
    /// leg is pending. exitIndoorTransition() switches currentIndoorRoute to
    /// indoorDestinationRoute, so this condition immediately stops being true —
    /// giving exactly-once without any new state. The final destination arrival
    /// (currentIndoorRoute == indoorDestinationRoute, or no destination for
    /// legacy/Case-2) fails the guard, so "You have arrived" is untouched.
    /// Deferred to post-frame (exitIndoorTransition notifies listeners, illegal
    /// during build); the re-check keeps it idempotent if multiple builds queue.
    if (indoorProvider.hasArrived &&
        provider.indoorStartRoute != null &&
        identical(provider.currentIndoorRoute, provider.indoorStartRoute) &&
        provider.indoorDestinationRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (indoorProvider.hasArrived &&
            identical(provider.currentIndoorRoute, provider.indoorStartRoute) &&
            provider.indoorDestinationRoute != null) {
          provider.exitIndoorTransition();
        }
      });
    }

    /// OUTDOOR
    if (provider.navigationMode ==
        AppNavigationMode.outdoor) {

      return const OutdoorMapWidget();
    }

    /// INDOOR
    return Stack(

      children: [

        IndoorMapWidget(

          buildingId:
          provider.selectedBuildingId,

          floor:
          indoorProvider.selectedFloor,
        ),

        Positioned(

          right: 12,

          /// Sit below the floating search bar (status bar + bar height),
          /// which now overlays the fullscreen map in indoor mode too.
          top: MediaQuery.of(context).padding.top + 76,

          child: FloorSelectorWidget(

            selectedFloor:
            indoorProvider.selectedFloor,

            onFloorSelected:
            indoorProvider.changeFloor,

            /// Floors come from the active building's central config, so a
            /// building with a different floor count works without edits here.
            floors: indoorBuildingConfigFor(
                        provider.selectedBuildingId)
                    ?.floorLevels ??
                const [0, 1, 2],
          ),
        ),

        /// ======================================================
        /// INDOOR INSTRUCTIONS (hidden once arrived)
        /// ======================================================

        if (provider.navigationMode ==
            AppNavigationMode.indoor &&
            indoorProvider.instructions
                .isNotEmpty &&
            !indoorProvider.hasArrived)

          Positioned(

            left: 16,

            right: 16,

            bottom: 24,

            child:
            _IndoorInstructionsBar(
              provider: indoorProvider,
            ),
          ),

        /// ======================================================
        /// ARRIVAL CARD (destination reached)
        /// ======================================================

        if (provider.navigationMode ==
            AppNavigationMode.indoor &&
            indoorProvider.hasArrived)

          Positioned(

            left: 16,

            right: 16,

            bottom: 24,

            child: _ArrivalCard(
              destinationName:
                  provider.selectedPlace?.name,
              onDone: () {
                provider.stopNavigation();
                provider.switchToOutdoor();
              },
            ),
          ),
      ],
    );
  }
}

/// ======================================================
/// ARRIVAL CARD
/// ======================================================
///
/// Shown when the user reaches the indoor destination. Route, destination
/// marker and blue dot stay on screen behind it; navigation is only cleared
/// when the user taps Done (never automatically).
class _ArrivalCard extends StatelessWidget {
  const _ArrivalCard({
    required this.destinationName,
    required this.onDone,
  });

  final String? destinationName;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.green.shade700,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.white,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'You have arrived',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    destinationName == null || destinationName!.isEmpty
                        ? 'Destination reached'
                        : 'Destination reached · $destinationName',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onDone,
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ======================================================
/// INDOOR INSTRUCTIONS BAR
/// ======================================================

class _IndoorInstructionsBar
    extends StatelessWidget {

  const _IndoorInstructionsBar({
    required this.provider,
  });

  final IndoorNavigationProvider provider;

  @override
  Widget build(
      BuildContext context,
      ) {

    final total =
        provider.instructions.length;

    final currentIndex =
    provider.currentIndoorIndex.clamp(
      0,
      total == 0
          ? 0
          : total - 1,
    );

    final currentInstruction =
    total == 0

        ? null

        : provider.instructions[
    currentIndex
    ];

    if (currentInstruction == null) {

      return const SizedBox.shrink();
    }

    return Card(

      elevation: 6,

      shape: RoundedRectangleBorder(

        borderRadius:
        BorderRadius.circular(14),
      ),

      child: Padding(

        padding:
        const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),

        /// Position-driven: the current step follows the user's live indoor
        /// position (see IndoorNavigationProvider._syncStepToPosition), so this
        /// is a read-only status card rather than a manual stepper.
        child: Row(

          children: [

            Icon(
              _indoorInstructionIcon(currentInstruction),
              color: Colors.indigo,
            ),

            const SizedBox(width: 12),

            Expanded(

              child: Column(

                crossAxisAlignment:
                CrossAxisAlignment.start,

                mainAxisSize:
                MainAxisSize.min,

                children: [

                  Text(

                    'Step ${currentIndex + 1} of $total',

                    style:
                    const TextStyle(

                      fontWeight:
                      FontWeight.w600,

                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(
                    height: 2,
                  ),

                  Text(

                    currentInstruction,

                    style:
                    const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Leading icon derived from the backend instruction text (stairs / arrival /
  /// directional). Text-only mapping — no routing logic.
  IconData _indoorInstructionIcon(String instruction) {
    final t = instruction.toLowerCase();
    if (t.contains('floor') || t.contains('stair')) {
      return Icons.stairs;
    }
    if (t.contains('arriv') || t.contains('destination')) {
      return Icons.flag;
    }
    if (t.contains('left')) return Icons.turn_left;
    if (t.contains('right')) return Icons.turn_right;
    return Icons.navigation;
  }
}


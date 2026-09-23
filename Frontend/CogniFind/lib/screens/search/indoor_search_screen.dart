import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cognifind/core/data/indoor_places.dart';
import 'package:cognifind/providers/navigation_provider.dart';
import 'package:cognifind/indoor_engine/providers/indoor_navigation_provider.dart';
import 'package:cognifind/ble_engine/providers/realtime_position_provider.dart';

/// IndoorSearchScreen
/// Used when user is inside a building
/// Allows searching indoor rooms / labs / nodes
class IndoorSearchScreen extends StatefulWidget {
  const IndoorSearchScreen({super.key});

  @override
  State<IndoorSearchScreen> createState() => _IndoorSearchScreenState();
}

class _IndoorSearchScreenState extends State<IndoorSearchScreen> {

  /// Controller for search field
  final TextEditingController _controller = TextEditingController();

  /// Searchable rooms for the building the user is currently inside, sourced
  /// from the central per-building registry rather than the single global
  /// list. Populated in [initState] from the selected building id.
  List<IndoorPlace> _buildingPlaces = const [];

  /// Filtered results list
  List<IndoorPlace> _filtered = const [];

  @override
  void initState() {
    super.initState();

    /// Rooms for the active indoor building (defaults handled by the registry
    /// when no specific building is selected yet).
    _buildingPlaces = indoorPlacesForBuilding(
      context.read<NavigationProvider>().selectedBuildingId,
    );
    _filtered = _buildingPlaces;

    /// Listen to typing in search field
    _controller.addListener(_filter);
  }

  @override
  void dispose() {
    _controller.removeListener(_filter);
    _controller.dispose();
    super.dispose();
  }

  /// Filters indoor places based on search text
  void _filter() {

    final query = _controller.text.trim().toLowerCase();

    setState(() {

      /// If search empty → show all nodes
      if (query.isEmpty) {
        _filtered = _buildingPlaces;
        return;
      }

      /// Filter by room name
      _filtered = _buildingPlaces.where((place) {

        return place.name.toLowerCase().contains(query) ||
            place.nodeId.toLowerCase().contains(query);

      }).toList();

    });
  }

  /// Indoor-only re-route (Case 2) from the user's current node to the
  /// selected room, staying in indoor mode. Mirrors the outdoor-entry Case 2
  /// core in NavigationScreen._startNavigation: fetch with startIndoorNode =
  /// current node, then hand the returned indoor path + instructions to
  /// IndoorNavigationProvider (whose setIndoorPath also clears any prior
  /// arrival/step state). Providers are passed in (already captured) so no
  /// disposed-screen context is used after the await.
  Future<void> _startIndoorRoute(
    NavigationProvider nav,
    IndoorNavigationProvider indoorNav,
    String startNode,
    String destinationNode,
  ) async {

    nav.startNavigationMode();

    await nav.fetchHybridRoute(
      startIndoorNode: startNode,
      destinationIndoorNode: destinationNode,
    );

    final indoorPath = nav.hybridIndoorPath;
    if (indoorPath.isNotEmpty) {
      indoorNav.setIndoorPath(indoorPath);
      indoorNav.setInstructions(nav.hybridIndoorInstructions);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Search inside building"),
      ),

      body: Column(
        children: [

          /// SEARCH FIELD
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Search rooms, labs, offices...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          /// SEARCH RESULTS
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (context, index) {

                final place = _filtered[index];

                return ListTile(

                  leading: const Icon(Icons.meeting_room),

                  title: Text(place.name),

                  subtitle: Text("Node ${place.nodeId}"),

                  onTap: () {

                    /// Captured before pop so the async work below never
                    /// touches this (about-to-be-disposed) screen's context.
                    final nav =
                        context.read<NavigationProvider>();
                    final indoorNav =
                        context.read<IndoorNavigationProvider>();
                    final startNode = context
                        .read<RealtimePositionProvider>()
                        .currentIndoorNode;

                    /// close search screen
                    Navigator.pop(context);

                    /// Guard on a known current indoor node: without a
                    /// startIndoorNode (but with the GPS source that is always
                    /// set while indoors) the backend returns a HYBRID route
                    /// and the app would flip to outdoor mode. If the backend
                    /// hasn't reported an indoor node yet, leave the current
                    /// route untouched rather than route incorrectly.
                    if (startNode == null) return;

                    _startIndoorRoute(
                      nav,
                      indoorNav,
                      startNode,
                      place.nodeId,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
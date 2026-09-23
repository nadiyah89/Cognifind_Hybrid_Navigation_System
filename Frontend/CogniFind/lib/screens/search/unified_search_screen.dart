import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cognifind/core/data/campus_places.dart';
import 'package:cognifind/core/data/indoor_places.dart';
import 'package:cognifind/models/navigation/search_place.dart';
import 'package:cognifind/providers/navigation_provider.dart';

/// UnifiedSearchScreen
///
/// One search for every hybrid case, with two ways through it:
///
///   DIRECT     — type anything into FIELD 1 and the results list every match
///                across the whole campus, buildings AND rooms together:
///                "CSE" finds the building, "N229" finds the lab inside it,
///                "ECE" the building, "E102" the room. Picking a room commits
///                the building it belongs to along with it, so the common case
///                ("I know the room number") is a single tap.
///
///   BROWSE     — pick a building first and FIELD 2 lists that building's
///                rooms, for when the user knows the department but not the
///                room. This is the original building-first flow, unchanged.
///
/// Room names are NOT globally unique ("Dean", "Faculty-Room" and the like
/// recur across buildings), which is why a room result always carries its
/// building with it and is shown qualified by it — never as a bare name.
///
/// Selections are handed to the existing hybrid pipeline via
/// [NavigationProvider.selectPlace]: this screen only sets the destination
/// context, it never starts navigation.
class UnifiedSearchScreen extends StatefulWidget {
  const UnifiedSearchScreen({super.key});

  @override
  State<UnifiedSearchScreen> createState() => _UnifiedSearchScreenState();
}

/// One row of the global result list: a building, optionally narrowed to a
/// room inside it. A room hit always carries its building because the pair is
/// what routing needs — the room supplies the indoor destination node, the
/// building supplies the outdoor anchor.
class _SearchHit {
  const _SearchHit({
    required this.building,
    this.room,
    this.rank = 0,
  });

  final SearchPlace building;
  final IndoorPlace? room;

  /// Match quality; lower sorts first. See `_buildingRank` / `_roomRank`.
  final int rank;
}

class _UnifiedSearchScreenState extends State<UnifiedSearchScreen> {
  final TextEditingController _buildingController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();

  /// The chosen building (FIELD 1). Null until a building is selected; while
  /// null, FIELD 2 stays disabled.
  SearchPlace? _building;

  @override
  void initState() {
    super.initState();
    _buildingController.addListener(_onChanged);
    _roomController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _buildingController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  /// FIELD 1 results: every campus match for the query — buildings and rooms
  /// in one ranked list.
  ///
  /// An empty query lists the buildings alone (the campus directory), because
  /// dumping several hundred rooms on an untouched field is noise, not a
  /// starting point. As soon as the user types, rooms join in: a room whose
  /// node id is exactly what was typed sorts to the top, so "N229" resolves in
  /// one tap while "N2" still shows the whole family.
  List<_SearchHit> get _globalResults {
    final q = _buildingController.text.trim().toLowerCase();

    if (q.isEmpty) {
      return [for (final b in campusPlaces) _SearchHit(building: b)];
    }

    final hits = <_SearchHit>[];

    for (final building in campusPlaces) {
      final rank = _buildingRank(building, q);
      if (rank != null) {
        hits.add(_SearchHit(building: building, rank: rank));
      }

      for (final room in indoorPlacesForBuilding(building.id)) {
        final roomRank = _roomRank(room, q);
        if (roomRank != null) {
          hits.add(_SearchHit(building: building, room: room, rank: roomRank));
        }
      }
    }

    /// Stable sort: equally-ranked results keep campus/dataset order, so the
    /// list never reshuffles unpredictably as the user types.
    hits.sort((a, b) => a.rank.compareTo(b.rank));
    return hits;
  }

  /// Match rank for a building, or null when it doesn't match. Lower is better;
  /// the bands are shared with [_roomRank] so buildings and rooms interleave by
  /// how well each matches rather than by which kind it is.
  static int? _buildingRank(SearchPlace building, String q) {
    final id = building.id.toLowerCase();
    final name = building.name.toLowerCase();

    if (id == q || name == q) return 0;
    if (name.startsWith(q) || id.startsWith(q)) return 2;
    if (name.contains(q) ||
        id.contains(q) ||
        building.subtitle.toLowerCase().contains(q)) {
      return 4;
    }
    return null;
  }

  static int? _roomRank(IndoorPlace room, String q) {
    final node = room.nodeId.toLowerCase();
    final label = room.label.toLowerCase();

    if (node == q) return 0;
    if (node.startsWith(q)) return 1;
    if (label.startsWith(q)) return 3;
    if (node.contains(q) || label.contains(q)) return 5;
    return null;
  }

  /// FIELD 2 results: indoor destinations of the selected building filtered
  /// by the room query. Empty when the building has no indoor dataset.
  List<IndoorPlace> get _roomResults {
    final building = _building;
    if (building == null) return const [];

    final all = indoorPlacesForBuilding(building.id);
    final q = _roomController.text.trim().toLowerCase();
    if (q.isEmpty) return all;

    return all
        .where((p) =>
            p.label.toLowerCase().contains(q) ||
            p.name.toLowerCase().contains(q) ||
            p.nodeId.toLowerCase().contains(q))
        .toList(growable: false);
  }

  void _selectBuilding(SearchPlace building) {
    setState(() {
      _building = building;
      _buildingController.text = building.name;
      _roomController.clear();
    });
  }

  void _clearBuilding() {
    setState(() {
      _building = null;
      _buildingController.clear();
      _roomController.clear();
    });
  }

  /// Commits the destination and returns to the persistent map. [room] null
  /// means "just the building" (outdoor / building-default routing); a room
  /// overrides the building's node with that room's node.
  ///
  /// [building] defaults to the browsed selection, and is passed explicitly by
  /// direct room hits — which commit a building the user never had to pick.
  void _finalize({SearchPlace? building, IndoorPlace? room}) {
    final target = building ?? _building;
    if (target == null) return;

    final place = target.copyWith(destinationNodeId: room?.nodeId);

    context.read<NavigationProvider>().selectPlace(place);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasBuilding = _building != null;

    return Scaffold(
      backgroundColor: Colors.white54,
      body: SafeArea(
        child: Column(
          children: [
            /// FIELD 1 — BUILDING (mandatory)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 10, 12, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: _fieldContainer(
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.white70),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _buildingController,
                              autofocus: true,
                              enabled: !hasBuilding,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText:
                                    'Search buildings or rooms (CSE, N229, E102)',
                                hintStyle: TextStyle(color: Colors.white54),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          if (hasBuilding)
                            IconButton(
                              onPressed: _clearBuilding,
                              icon: const Icon(Icons.close,
                                  color: Colors.white70),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// FIELD 2 — INDOOR DESTINATION (optional; enabled after a building)
            Padding(
              padding: const EdgeInsets.fromLTRB(52, 0, 12, 8),
              child: _fieldContainer(
                enabled: hasBuilding,
                child: Row(
                  children: [
                    Icon(Icons.meeting_room,
                        color:
                            hasBuilding ? Colors.white70 : Colors.white24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _roomController,
                        enabled: hasBuilding,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: hasBuilding
                              ? 'Room / destination (optional)'
                              : 'Select a building first',
                          hintStyle: TextStyle(
                            color: hasBuilding
                                ? Colors.white54
                                : Colors.white38,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: Colors.white24),

            /// RESULTS
            Expanded(
              child: hasBuilding
                  ? _buildRoomResults()
                  : _buildGlobalResults(),
            ),
          ],
        ),
      ),
    );
  }

  /// FIELD 1 stage: campus-wide suggestions — buildings and rooms together.
  Widget _buildGlobalResults() {
    final results = _globalResults;

    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Nothing on campus matches that.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: results.length,
      itemBuilder: (context, i) {
        final hit = results[i];
        final room = hit.room;

        /// BUILDING — tapping it browses that building's rooms (FIELD 2).
        if (room == null) {
          return ListTile(
            leading: Icon(
              _buildingIcon(hit.building.category),
              color: Colors.white70,
            ),
            title: Text(hit.building.name,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text(hit.building.subtitle,
                style: const TextStyle(color: Colors.white54)),
            trailing: hit.building.supportsHybridRoute
                ? const Icon(Icons.meeting_room,
                    color: Colors.white38, size: 18)
                : null,
            onTap: () => _selectBuilding(hit.building),
          );
        }

        /// ROOM — a complete destination on its own, so tapping it commits
        /// building + room and returns straight to the map.
        return ListTile(
          leading: Icon(_indoorIcon(room.type), color: Colors.white70),
          title: Text(room.label,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text(
            [
              hit.building.name,
              if (room.floorTag != null) _floorName(room.floorTag!),
              room.nodeId,
            ].join(' • '),
            style: const TextStyle(color: Colors.white54),
          ),
          onTap: () => _finalize(building: hit.building, room: room),
        );
      },
    );
  }

  /// FIELD 2 stage: the "just the building" action plus indoor destinations.
  Widget _buildRoomResults() {
    final building = _building!;
    final rooms = _roomResults;
    final hasIndoor = indoorPlacesForBuilding(building.id).isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        /// Outdoor / building-default option (skip indoor).
        Card(
          color: Colors.indigo,
          child: ListTile(
            leading: const Icon(Icons.directions_walk, color: Colors.white),
            title: Text('Go to ${building.name}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
            subtitle: Text(
              building.supportsHybridRoute
                  ? 'Route to the building (no specific room)'
                  : 'Outdoor route to the building',
              style: const TextStyle(color: Colors.white70),
            ),
            onTap: () => _finalize(),
          ),
        ),

        const SizedBox(height: 8),

        if (!hasIndoor)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No indoor destinations available for this building yet.',
              style: TextStyle(color: Colors.white70),
            ),
          )
        else if (rooms.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No matching rooms in this building.',
              style: TextStyle(color: Colors.white70),
            ),
          )
        else
          ...rooms.map(
            (room) => ListTile(
              leading: Icon(_indoorIcon(room.type), color: Colors.white70),
              title: Text(room.label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: Text(
                [
                  if (room.floorTag != null) _floorName(room.floorTag!),
                  'Node ${room.nodeId}',
                ].join(' • '),
                style: const TextStyle(color: Colors.white54),
              ),
              onTap: () => _finalize(room: room),
            ),
          ),
      ],
    );
  }

  Widget _fieldContainer({required Widget child, bool enabled = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: enabled ? Colors.grey.shade900 : Colors.grey.shade900.withOpacity(0.5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
    );
  }

  String _floorName(String tag) {
    switch (tag) {
      case 'F0':
        return 'Ground Floor';
      case 'F1':
        return 'Floor 1';
      case 'F2':
        return 'Floor 2';
      default:
        return tag;
    }
  }

  IconData _buildingIcon(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.library:
        return Icons.local_library_outlined;
      case PlaceCategory.academic:
        return Icons.school_outlined;
      case PlaceCategory.administration:
        return Icons.apartment_outlined;
      case PlaceCategory.other:
        return Icons.place_outlined;
    }
  }

  /// Indoor destination type → icon (1 classroom, 2 lab, 3 office/faculty,
  /// 4 washroom, 5 hall/common, 6 entrance).
  IconData _indoorIcon(int type) {
    switch (type) {
      case 1:
        return Icons.class_outlined;
      case 2:
        return Icons.science_outlined;
      case 3:
        return Icons.badge_outlined;
      case 4:
        return Icons.wc_outlined;
      case 5:
        return Icons.groups_outlined;
      case 6:
        return Icons.door_front_door_outlined;
      default:
        return Icons.meeting_room_outlined;
    }
  }
}

import 'package:cognifind/core/data/campus_places.dart';

import 'package:cognifind/models/navigation/search_place.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cognifind/providers/navigation_provider.dart';

/// SearchScreen
/// Allows users to search campus places and open route preview
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {

  /// Controller for the search text field
  final TextEditingController _controller = TextEditingController();

  /// Filtered results shown in the list
  List<SearchPlace> _filtered = campusPlaces;

  @override
  void initState() {
    super.initState();

    /// Listen for changes in search text
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    super.dispose();
  }

  /// Called whenever the user types in the search field
  void _onQueryChanged() {

    final query = _controller.text.trim().toLowerCase();

    setState(() {

      /// If search is empty → show all places
      if (query.isEmpty) {
        _filtered = campusPlaces;
        return;
      }

      /// Filter by name, subtitle, or building ID
      /// filter campus places
      _filtered = campusPlaces.where((place) {

        return place.name.toLowerCase().contains(query) ||
            place.subtitle.toLowerCase().contains(query) ||
            place.id.toLowerCase().contains(query);

      }).toList(growable: false);

    });
  }

  /// Opens the route preview screen
  Future<void> _openRoutePreview(SearchPlace place) async {

    context.read<NavigationProvider>().selectPlace(place);

    /// Return to map
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white54,

      body: SafeArea(
        child: Column(
          children: [

            /// TOP SEARCH BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [

                  /// Back button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),

                  const SizedBox(width: 6),

                  /// Search input container
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: Colors.white12),
                      ),

                      child: Row(
                        children: [

                          const Icon(Icons.search, color: Colors.white70),
                          const SizedBox(width: 10),

                          /// SEARCH FIELD
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              style: const TextStyle(color: Colors.white),

                              decoration: const InputDecoration(
                                hintText: 'Search here',
                                hintStyle: TextStyle(color: Colors.white54),
                                border: InputBorder.none,
                              ),
                            ),
                          ),

                          /// Clear search button
                          IconButton(
                            onPressed: () => _controller.clear(),
                            icon: const Icon(Icons.close, color: Colors.white70),
                          ),

                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),



            const SizedBox(height: 8),

            /// SEARCH RESULTS LIST
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                /// number of filtered results
                itemCount: _filtered.length,

                itemBuilder: (context, index) {

                  final place = _filtered[index];

                  return _SearchResultTile(
                    place: place,
                    onTap: () => _openRoutePreview(place),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// SEARCH CATEGORY CHIP
class _SearchChip extends StatelessWidget {

  final IconData icon;
  final String label;

  const _SearchChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {

    return Padding(
      padding: const EdgeInsets.only(right: 10),

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),

        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white12),
        ),

        child: Row(
          children: [

            Icon(icon, color: Colors.white70, size: 18),

            const SizedBox(width: 8),

            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// SEARCH RESULT TILE
class _SearchResultTile extends StatelessWidget {

  const _SearchResultTile({
    required this.place,
    required this.onTap,
  });

  final SearchPlace place;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {

    return Material(
      color: Colors.transparent,

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),

        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),

          child: Row(
            children: [

              /// Category icon
              Icon(
                _categoryIcon(place.category),
                color: Colors.white54,
              ),

              const SizedBox(width: 12),

              /// Place name and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      place.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      place.subtitle,
                      style: const TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),

              /// Direction arrow
              const Icon(Icons.north_west, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns icon based on place category
  IconData _categoryIcon(PlaceCategory category) {
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
}
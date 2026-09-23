import 'package:flutter/material.dart';
import 'package:cognifind/models/navigation/search_place.dart';

class PlaceBottomCard extends StatelessWidget {
  final SearchPlace place;
  final VoidCallback onDirections;
  final VoidCallback onStart;

  const PlaceBottomCard({
    super.key,
    required this.place,
    required this.onDirections,
    required this.onStart,
  });


  @override
  Widget build(BuildContext context) {
    final scheme = Theme
        .of(context)
        .colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black26,
          )
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            /// Place name
            Text(
              place.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),

            const SizedBox(height: 4),

            /// Subtitle
            Text(
              place.subtitle,
              style: TextStyle(
                fontSize: 14,
                color: scheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 16),

            /// Buttons row
            Row(
              children: [

                /// Directions button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDirections,
                    icon: const Icon(Icons.directions),
                    label: const Text("Directions"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                /// Start button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.navigation),
                    label: const Text("Start"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            /// Building images section
            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _getBuildingImages(place.id)
                    .map((img) => _imageCard(img))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),

          ],
        ),
      ),
    );
  }

  List<String> _getBuildingImages(String id) {
    switch (id) {
      case 'LIB':
        return [
          'assets/images/buildings/lib1.jpg',
          'assets/images/buildings/lib2.jpg',
          // 'assets/images/buildings/lib3.jpg',
        ];

      case 'AB-IV':
        return [
          'assets/images/buildings/ab1_1.jpg',
          // 'assets/images/buildings/ab1_2.jpg',
        ];


      default:
        return [
          'assets/images/buildings/default.jpg',
        ];
    }
  }


  Widget _imageCard(String path) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          path,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
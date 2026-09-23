import 'package:flutter/material.dart';

/// SourceDestinationCard
///
/// This widget represents the top navigation card
/// similar to Google Maps:
/// - Source (from)
/// - Destination (to)
///
/// For now:
/// - UI only
/// - No logic
/// - No API calls
class SourceDestinationCard extends StatelessWidget {
  const SourceDestinationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          /// SOURCE ROW
          _buildRow(
            icon: Icons.my_location,
            iconColor: Colors.green,
            text: 'Your location',
            trailing: Icons.arrow_drop_down,
          ),

          const SizedBox(height: 8),

          /// SWAP ICON
          const Icon(
            Icons.swap_vert,
            color: Colors.blue,
          ),

          const SizedBox(height: 8),

          /// DESTINATION ROW
          _buildRow(
            icon: Icons.location_on,
            iconColor: Colors.red,
            text: 'Search destination',
            trailing: Icons.arrow_drop_down,
          ),
        ],
      ),
    );
  }

  /// Builds a single row (source / destination)
  Widget _buildRow({
    required IconData icon,
    required Color iconColor,
    required String text,
    required IconData trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Icon(trailing, color: Colors.grey),
        ],
      ),
    );
  }
}

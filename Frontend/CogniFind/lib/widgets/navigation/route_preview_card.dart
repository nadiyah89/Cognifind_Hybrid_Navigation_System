import 'package:flutter/material.dart';

class RoutePreviewCard extends StatelessWidget {
  final double distanceMeters;
  final double durationMinutes;

  /// True when the previewed route continues indoors (hybrid route).
  final bool includesIndoor;

  final VoidCallback onStart;

  const RoutePreviewCard({
    super.key,
    required this.distanceMeters,
    required this.durationMinutes,
    this.includesIndoor = false,
    required this.onStart,
  });

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000.0;
      return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
    }
    return '${meters.round()} m';
  }

  String _formatDuration(double minutes) {
    final totalMinutes = minutes.round();
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours > 0) {
      if (mins == 0) return '$hours hr';
      return '$hours hr $mins min';
    }
    return '$totalMinutes min';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
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
          
          Text(
            includesIndoor ? "Walk • continues indoors" : "Walk",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "${_formatDuration(durationMinutes)} (${_formatDistance(distanceMeters)})",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onStart,
              icon: const Icon(Icons.navigation),
              label: const Text("Start navigation"),
            ),
          ),
        ],
      ),
    );
  }
}

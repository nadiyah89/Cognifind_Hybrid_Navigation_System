import 'package:flutter/material.dart';

/// MapControlsWidget
///
/// Vertical floating buttons shown on the right side of the map.
/// This widget is UI-only and calls callbacks passed from parent.
///
/// Buttons:
/// - My location
/// - Center map
/// - Zoom in
/// - Zoom out
class MapControlsWidget extends StatelessWidget {
  final VoidCallback onMyLocation;
  final VoidCallback onCenter;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback? onToggleMapType;
  final bool isSatellite;

  const MapControlsWidget({
    super.key,
    required this.onMyLocation,
    required this.onCenter,
    required this.onZoomIn,
    required this.onZoomOut,
    this.onToggleMapType,
    this.isSatellite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (onToggleMapType != null) ...[
          _roundButton(
            icon: isSatellite ? Icons.layers_clear : Icons.layers,
            onTap: onToggleMapType!,
          ),
          const SizedBox(height: 10),
        ],
        _roundButton(
          icon: Icons.my_location,
          onTap: onMyLocation,
        ),
        const SizedBox(height: 10),
        _roundButton(
          icon: Icons.center_focus_strong,
          onTap: onCenter,
        ),
        const SizedBox(height: 10),
        _roundButton(
          icon: Icons.add,
          onTap: onZoomIn,
        ),
        const SizedBox(height: 10),
        _roundButton(
          icon: Icons.remove,
          onTap: onZoomOut,
        ),
      ],
    );
  }

  /// Reusable circular button
  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.indigo,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

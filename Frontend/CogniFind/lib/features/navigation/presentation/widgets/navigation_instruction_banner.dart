import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cognifind/providers/navigation_provider.dart';
import 'package:cognifind/providers/location_provider.dart';
import 'package:cognifind/features/navigation/utils/route_progress.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Green outdoor turn-by-turn banner shown during outdoor navigation.
///
/// The live instruction is derived from the user's progress along the route:
/// the nearest-route-index (the SAME function that drives the traversed/
/// remaining polyline split) selects instruction[i], which is 1:1 with route
/// node[i]. Presentation only — it reads the backend-owned position and
/// instructions; it never mutates navigation state or computes routing.
class NavigationInstructionBanner extends StatelessWidget {
  const NavigationInstructionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();
    final position =
        context.watch<LocationProvider>().currentLocation;

    final text = _currentInstruction(nav, position);

    return Card(
      color: Colors.green.shade700,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.arrow_upward,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Instruction for the user's current position along the outdoor route,
  /// falling back to the first instruction (or a starting placeholder) before
  /// the route/position/instructions are available.
  String _currentInstruction(NavigationProvider nav, LatLng? position) {
    final route = nav.outdoorRoute;
    final instructions = nav.outdoorInstructions;

    if (nav.isNavigating &&
        position != null &&
        route.length >= 2 &&
        instructions.isNotEmpty) {
      final i = nearestRouteIndex(route, position)
          .clamp(0, instructions.length - 1);
      return instructions[i];
    }

    return nav.currentOutdoorInstruction.isEmpty
        ? "Starting navigation..."
        : nav.currentOutdoorInstruction;
  }
}

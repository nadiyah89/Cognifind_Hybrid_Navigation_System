import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cognifind/providers/navigation_provider.dart';
import 'package:cognifind/features/navigation/presentation/widgets/enter_building_button.dart';

/// Floating ETA / stats card shown during outdoor navigation, with a
/// cancel button that stops navigation.
///
/// Distance/duration come from the provider's computed route metrics
/// (walking-speed estimate over the outdoor polyline).
class NavigationStatsCard extends StatelessWidget {
  const NavigationStatsCard({super.key});

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000.0;
      return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
    }
    return '${meters.round()} m';
  }

  String _formatEta(double durationMinutes) {
    final eta = DateTime.now().add(
      Duration(minutes: durationMinutes.round()),
    );
    final hh = eta.hour.toString().padLeft(2, '0');
    final mm = eta.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    /// watch: metrics arrive after the route fetch completes.
    final nav = context.watch<NavigationProvider>();

    final minutes = nav.routeDurationMinutes;
    final meters = nav.routeDistanceMeters;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    nav.stopNavigation();
                  },
                ),
                Text(
                  "${minutes.round()} min",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Icon(Icons.alt_route),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "${_formatDistance(meters)} • ETA ${_formatEta(minutes)}",
              style: const TextStyle(fontSize: 14),
            ),

            /// Manual hybrid transition — appears only while approaching the
            /// destination building (nav.canEnterBuilding). Reuses the same
            /// provider-owned transition as auto-transition; auto still fires
            /// on its own if the user never taps.
            if (nav.canEnterBuilding) ...[
              const SizedBox(height: 12),
              const SizedBox(
                width: double.infinity,
                child: EnterBuildingButton(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

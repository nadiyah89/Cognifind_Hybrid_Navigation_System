import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cognifind/providers/navigation_provider.dart';

/// Full-screen scrim that bridges the outdoor↔indoor mode swap.
///
/// Rendering-only: it observes [NavigationProvider.transitionPhase] and
/// interpolates its own opacity over the shared [NavigationProvider
/// .transitionScrimFade]. The provider owns the lifecycle timing (it swaps
/// modes at peak opacity); this widget never drives that timing.
///
/// Restrained by design (Google-Maps-subtle, not cinematic): a soft branded
/// veil + a lightweight centered label, no spinners or heavy motion.
class TransitionOverlay extends StatelessWidget {
  const TransitionOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();

    final active =
        nav.transitionPhase != IndoorTransitionPhase.none;

    /// Prefer the backend-authored transition text; fall back to a neutral
    /// default so the automatic-transition flow (no button press) still reads
    /// clearly.
    final label = nav.transitionInstruction ?? 'Entering the building…';

    return IgnorePointer(
      ignoring: !active,
      child: AnimatedOpacity(
        opacity: active ? 1 : 0,
        duration: NavigationProvider.transitionScrimFade,
        curve: Curves.easeInOut,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1E3A8A),
                Color(0xFF2563EB),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.meeting_room_outlined,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 14),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Dimmed full-screen overlay with a spinner shown while a route is being
/// fetched.
///
/// Extracted verbatim from navigation_screen.dart (Phase 10). Layout is
/// unchanged; the isFetchingRoute condition and Positioned.fill remain in
/// navigation_screen.dart.
class NavigationLoadingOverlay extends StatelessWidget {
  const NavigationLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color.fromARGB(120, 0, 0, 0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

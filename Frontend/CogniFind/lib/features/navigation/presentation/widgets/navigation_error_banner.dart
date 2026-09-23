import 'package:flutter/material.dart';

/// Red error banner shown when a route request fails.
///
/// Extracted verbatim from navigation_screen.dart (Phase 10). Layout is
/// unchanged; the message is passed in and the null-check + positioning
/// remain in navigation_screen.dart.
class NavigationErrorBanner extends StatelessWidget {
  const NavigationErrorBanner({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade700,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

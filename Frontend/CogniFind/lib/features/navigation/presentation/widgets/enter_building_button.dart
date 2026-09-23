import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cognifind/providers/navigation_provider.dart';

/// Full-width button that switches from outdoor to indoor mode. Its label is
/// the backend transition instruction when present, else "Enter Building".
///
/// Extracted verbatim from navigation_screen.dart (Phase 10). Behavior,
/// state access (watch), and styling are unchanged; the visibility condition
/// remains in navigation_screen.dart.
class EnterBuildingButton extends StatelessWidget {
  const EnterBuildingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final navigationProvider = context.watch<NavigationProvider>();

    return ElevatedButton(
      onPressed: () {
        navigationProvider.enterIndoorTransition();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        navigationProvider.transitionInstruction ?? 'Enter Building',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

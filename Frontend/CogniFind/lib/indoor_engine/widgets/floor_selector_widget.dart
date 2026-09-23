import 'package:flutter/material.dart';

/// FloorSelectorWidget
///
/// Shows vertical floor buttons for the active building's floors.
/// Used only in Indoor navigation mode.
class FloorSelectorWidget extends StatelessWidget {
  final int selectedFloor;
  final Function(int) onFloorSelected;

  /// Floor levels to show, in display order. Defaults to the historic
  /// three-floor layout; callers pass the active building's floors from the
  /// central indoor-building config.
  final List<int> floors;

  const FloorSelectorWidget({
    super.key,
    required this.selectedFloor,
    required this.onFloorSelected,
    this.floors = const [0, 1, 2],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: floors.map((floor) {
        final isSelected = floor == selectedFloor;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: GestureDetector(
            onTap: () => onFloorSelected(floor),
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.indigo : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Text(
                floor.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.indigo,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

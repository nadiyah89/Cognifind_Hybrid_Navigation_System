import 'package:flutter_test/flutter_test.dart';

import 'package:cognifind/indoor_engine/utils/indoor_route_progress.dart';
import 'package:cognifind/models/navigation/indoor_node.dart';

void main() {
  IndoorNode node(String id, int floor) =>
      IndoorNode(id: id, floor: floor, x: 0, y: 0, type: 'corridor');

  // A hybrid indoor route climbing floor 0 -> 1 -> 2, contiguous per floor.
  // Global indices:  0     1     2     3     4     5
  final path = [
    node('N001', 0), // 0
    node('N002', 0), // 1
    node('L001', 1), // 2  (stair landing)
    node('N101', 1), // 3
    node('L201', 2), // 4
    node('N217', 2), // 5  (destination)
  ];

  group('indoorCurrentLocalIndex', () {
    test('maps global progress to a floor-local index on the current floor', () {
      // Progress at global 1 (N002, floor 0): local index 1 on floor 0.
      expect(indoorCurrentLocalIndex(path, 1, 0), 1);
      // Progress at global 3 (N101, floor 1): floor 1 starts at global 2, so
      // local index 1 on floor 1.
      expect(indoorCurrentLocalIndex(path, 3, 1), 1);
      // Progress at global 5 (N217, floor 2): floor 2 starts at global 4, so
      // local index 1 on floor 2.
      expect(indoorCurrentLocalIndex(path, 5, 2), 1);
    });

    test('is negative for a floor the user has not reached yet', () {
      // Standing on floor 0 (global 1), floor 2 is still ahead → whole floor
      // remaining (negative local index).
      expect(indoorCurrentLocalIndex(path, 1, 2), lessThan(0));
    });

    test('is >= slice length for a floor the user has already passed', () {
      // Standing on floor 2 (global 5), floor 0 is behind. Floor 0 has 2 nodes
      // (local 0..1); the returned index must be >= 2 so the whole floor reads
      // as traversed.
      const floor0Slice = 2;
      expect(
        indoorCurrentLocalIndex(path, 5, 0),
        greaterThanOrEqualTo(floor0Slice),
      );
    });

    test('start of a floor maps to local 0 (nothing traversed on it yet)', () {
      // Global 2 is the first node of floor 1.
      expect(indoorCurrentLocalIndex(path, 2, 1), 0);
    });

    test('returns -1 for a floor with no nodes in the path', () {
      expect(indoorCurrentLocalIndex(path, 3, 7), -1);
    });
  });
}

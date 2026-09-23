import 'package:flutter_test/flutter_test.dart';

import 'package:cognifind/indoor_engine/models/indoor_position.dart';
import 'package:cognifind/indoor_engine/providers/indoor_navigation_provider.dart';
import 'package:cognifind/models/navigation/indoor_node.dart';

void main() {
  IndoorNode node(String id, int floor, double x, double y) =>
      IndoorNode(id: id, floor: floor, x: x, y: y, type: 'corridor');

  // Mirrors a hybrid indoor route: floor 0 -> floor 2 destination.
  List<IndoorNode> path() => [
        node('N001', 0, 100, 100),
        node('N002', 0, 200, 100),
        node('N217', 2, 900, 700), // destination
      ];

  group('IndoorNavigationProvider arrival', () {
    test('starts not-arrived', () {
      final p = IndoorNavigationProvider()..setIndoorPath(path());
      expect(p.hasArrived, isFalse);
    });

    test('stays not-arrived mid-route', () {
      final p = IndoorNavigationProvider()..setIndoorPath(path());
      p.updatePosition(
        const IndoorPosition(x: 100, y: 100, floor: 0, heading: 0),
      );
      expect(p.hasArrived, isFalse);
    });

    test('arrives at the final route node', () {
      final p = IndoorNavigationProvider()..setIndoorPath(path());
      p.updatePosition(
        const IndoorPosition(x: 900, y: 700, floor: 2, heading: 0),
      );
      expect(p.hasArrived, isTrue);
    });

    test('latches through position jitter back to an earlier node', () {
      final p = IndoorNavigationProvider()..setIndoorPath(path());
      p.updatePosition(
        const IndoorPosition(x: 900, y: 700, floor: 2, heading: 0),
      );
      p.updatePosition(
        const IndoorPosition(x: 100, y: 100, floor: 0, heading: 0),
      );
      expect(p.hasArrived, isTrue);
    });

    test('a new route resets arrival', () {
      final p = IndoorNavigationProvider()..setIndoorPath(path());
      p.updatePosition(
        const IndoorPosition(x: 900, y: 700, floor: 2, heading: 0),
      );
      expect(p.hasArrived, isTrue);

      p.setIndoorPath(path());
      expect(p.hasArrived, isFalse);
    });
  });
}

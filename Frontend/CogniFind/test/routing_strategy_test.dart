import 'package:flutter_test/flutter_test.dart';

import 'package:cognifind/features/navigation/utils/routing_strategy.dart';

void main() {
  const cse = 'AB-IV'; // the one building with indoor positioning today

  group('shouldRouteIndoorOnly', () {
    test('Case 2: inside CSE, destination is another CSE room -> indoor only',
        () {
      expect(
        shouldRouteIndoorOnly(
          isIndoor: true,
          currentIndoorNode: 'N101',
          destinationNodeId: 'N112',
          destinationBuildingId: cse,
          indoorBuildingId: cse,
        ),
        isTrue,
      );
    });

    test('Case 1: user is outdoors -> not indoor only (stays hybrid)', () {
      expect(
        shouldRouteIndoorOnly(
          isIndoor: false,
          currentIndoorNode: null,
          destinationNodeId: 'N112',
          destinationBuildingId: cse,
          indoorBuildingId: cse,
        ),
        isFalse,
      );
    });

    test('Case 3: inside CSE, destination in a different building -> not indoor '
        'only (unchanged)', () {
      expect(
        shouldRouteIndoorOnly(
          isIndoor: true,
          currentIndoorNode: 'N101',
          destinationNodeId: 'LIB-101',
          destinationBuildingId: 'LIB',
          indoorBuildingId: cse,
        ),
        isFalse,
      );
    });

    test('outdoor destination (no indoor room) -> not indoor only', () {
      expect(
        shouldRouteIndoorOnly(
          isIndoor: true,
          currentIndoorNode: 'N101',
          destinationNodeId: null,
          destinationBuildingId: cse,
          indoorBuildingId: cse,
        ),
        isFalse,
      );
    });

    test('indoors but backend gave no current node -> not indoor only', () {
      expect(
        shouldRouteIndoorOnly(
          isIndoor: true,
          currentIndoorNode: null,
          destinationNodeId: 'N112',
          destinationBuildingId: cse,
          indoorBuildingId: cse,
        ),
        isFalse,
      );

      expect(
        shouldRouteIndoorOnly(
          isIndoor: true,
          currentIndoorNode: '',
          destinationNodeId: 'N112',
          destinationBuildingId: cse,
          indoorBuildingId: cse,
        ),
        isFalse,
      );
    });
  });
}

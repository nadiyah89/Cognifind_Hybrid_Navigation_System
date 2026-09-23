import 'dart:convert';

import 'package:cognifind/core/services/hybrid_route_service.dart';
import 'package:cognifind/providers/navigation_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  HybridRouteService _buildMockService({
    required http.Response Function(Uri uri) responder,
  }) {
    final client = MockClient((request) async => responder(request.url));
    return HybridRouteService(client: client);
  }

  group('NavigationProvider.fetchHybridRoute', () {
    test('happy path updates outdoor and indoor state', () async {
      final service = _buildMockService(
        responder: (uri) {
          expect(uri.toString(), contains('userLat=10.0'));
          expect(uri.toString(), contains('userLng=20.0'));
          expect(uri.toString(), contains('destinationNode=DEST'));

          final body = jsonEncode({
            'outdoor': {
              'polyline': 'encoded_polyline_string',
            },
            'indoor': {
              'path': [
                {
                  'node': 'N1',
                  'floor': 0,
                  'x': 10.0,
                  'y': 20.0,
                  'type': 'start',
                },
                {
                  'node': 'N2',
                  'floor': 1,
                  'x': 30.0,
                  'y': 40.0,
                  'type': 'end',
                },
              ],
              'instructions': [
                'Go straight',
                'Take the stairs to floor 1',
              ],
            },
          });

          return http.Response(body, 200);
        },
      );

      final provider = NavigationProvider(hybridRouteService: service);

      provider.setSourceLocation(latitude: 10.0, longitude: 20.0);

      await provider.fetchHybridRoute(destinationNodeId: 'DEST');

      expect(provider.isFetchingRoute, false);
      expect(provider.lastErrorMessage, isNull);
      expect(provider.outdoorPolyline, isNotNull);
      expect(provider.indoorPath, isNotEmpty);
      expect(provider.indoorInstructions.length, 2);
      expect(provider.routeStatus, RouteStatus.outdoorCompleted);
    });

    test('error response sets error state and does not crash', () async {
      final service = _buildMockService(
        responder: (uri) => http.Response('server error', 500),
      );

      final provider = NavigationProvider(hybridRouteService: service);
      provider.setSourceLocation(latitude: 10.0, longitude: 20.0);

      await provider.fetchHybridRoute(destinationNodeId: 'DEST');

      expect(provider.isFetchingRoute, false);
      expect(provider.lastErrorMessage, isNotNull);
      expect(provider.outdoorPolyline, isNull);
      expect(provider.indoorPath, isEmpty);
      expect(provider.indoorInstructions, isEmpty);
    });
  });

  group('NavigationProvider mode and floor transitions', () {
    test('switchToIndoor and switchToOutdoor toggle mode and reset state', () {
      final provider = NavigationProvider();

      expect(provider.navigationMode, AppNavigationMode.outdoor);
      expect(provider.routeStatus, RouteStatus.idle);

      provider.switchToIndoor(floor: 1);
      expect(provider.navigationMode, AppNavigationMode.indoor);
      expect(provider.selectedFloor, 1);
      expect(provider.routeStatus, RouteStatus.indoorActive);

      provider.switchToOutdoor();
      expect(provider.navigationMode, AppNavigationMode.outdoor);
      expect(provider.routeStatus, RouteStatus.idle);
      expect(provider.selectedBuildingId, isNull);
      expect(provider.outdoorPolyline, isNull);
    });

    test('nextIndoorStep and previousIndoorStep advance along path and floors',
        () {
      final provider = NavigationProvider();

      provider.switchToIndoor(floor: 0);

      provider.setIndoorPath([
        const IndoorNode(
          id: 'N1',
          floor: 0,
          x: 0,
          y: 0,
          type: 'start',
        ),
        const IndoorNode(
          id: 'N2',
          floor: 1,
          x: 10,
          y: 10,
          type: 'middle',
        ),
      ]);

      expect(provider.currentIndoorIndex, 0);
      expect(provider.selectedFloor, 0);

      provider.nextIndoorStep();
      expect(provider.currentIndoorIndex, 1);
      expect(provider.selectedFloor, 1);

      provider.previousIndoorStep();
      expect(provider.currentIndoorIndex, 0);
      expect(provider.selectedFloor, 0);
    });
  });
}


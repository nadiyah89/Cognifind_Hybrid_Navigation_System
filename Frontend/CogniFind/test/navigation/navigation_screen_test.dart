import 'dart:convert';

import 'package:cognifind/core/services/hybrid_route_service.dart';
import 'package:cognifind/features/navigation/presentation/navigation_screen.dart';
import 'package:cognifind/providers/navigation_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  HybridRouteService _buildMockServiceWithIndoorData() {
    final client = MockClient((request) async {
      final body = jsonEncode({
        'outdoor': {
          'polyline': '',
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
          ],
          'instructions': ['Walk to the main corridor'],
        },
      });

      return http.Response(body, 200);
    });

    return HybridRouteService(client: client);
  }

  testWidgets('NavigationScreen shows OutdoorMapWidget in outdoor mode',
      (tester) async {
    final provider = NavigationProvider();

    await tester.pumpWidget(
      ChangeNotifierProvider<NavigationProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: NavigationScreen(),
        ),
      ),
    );

    // By default app starts in outdoor mode, so OutdoorMapWidget should be present.
    expect(find.byType(OutdoorMapWidget), findsOneWidget);
    expect(find.byType(IndoorMapWidget), findsNothing);
  });

  testWidgets(
      'NavigationScreen in indoor mode shows IndoorMapWidget and instructions bar when instructions exist',
      (tester) async {
    final service = _buildMockServiceWithIndoorData();
    final provider = NavigationProvider(hybridRouteService: service);

    provider.setSourceLocation(latitude: 10.0, longitude: 20.0);
    provider.switchToIndoor(floor: 0);

    await provider.fetchHybridRoute(destinationNodeId: 'DEST');

    await tester.pumpWidget(
      ChangeNotifierProvider<NavigationProvider>.value(
        value: provider,
        child: const MaterialApp(
          home: NavigationScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(IndoorMapWidget), findsOneWidget);
    expect(find.textContaining('Step 1 of'), findsOneWidget);
    expect(find.text('Walk to the main corridor'), findsOneWidget);
  });
}


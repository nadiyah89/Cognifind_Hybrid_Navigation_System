import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:cognifind/models/navigation/hybrid_route_result.dart';

class HybridRouteService {
  HybridRouteService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl =
      'https://cognifind-backend2.onrender.com/api/route';

  /// Bounds every /api/route request so an unreachable backend or an unstable
  /// campus network can never leave the caller — and its loading overlay —
  /// waiting forever. On timeout the request throws TimeoutException, handled
  /// by NavigationProvider's existing try/catch/finally (loading cleared, error
  /// surfaced, state consistent).
  ///
  /// 45 s, not 15 s: the backend is hosted on a tier that suspends idle
  /// instances, and a cold start measures ~25-30 s. At 15 s the FIRST route
  /// request after a quiet period always failed with "Route failed" — the app
  /// timing out on a backend that was about to answer. Warm requests return in
  /// well under a second, so this ceiling only ever applies to the cold case.
  static const Duration _requestTimeout = Duration(seconds: 45);

  Future<HybridRouteResult> fetchHybridRoute({
    double? userLat,
    double? userLng,
    String? startIndoorNode,
    String? destinationIndoorNode,
    double? endLat,
    double? endLng,
  }) async {

    final params = <String, String>{};

    if (userLat != null) params["startLat"] = userLat.toString();
    if (userLng != null) params["startLng"] = userLng.toString();
    if (startIndoorNode != null) params["startIndoorNode"] = startIndoorNode;

    if (destinationIndoorNode != null) {
      params["destinationIndoorNode"] = destinationIndoorNode;
    }

    if (endLat != null) params["endLat"] = endLat.toString();
    if (endLng != null) params["endLng"] = endLng.toString();

    final uri = Uri.parse(_baseUrl).replace(queryParameters: params);

    debugPrint("🌍 Calling backend: $uri");

    final response = await _client.get(uri).timeout(_requestTimeout);

    debugPrint("📡 Response code: ${response.statusCode}");
    debugPrint("📦 Response body: ${response.body}");

    if (response.statusCode != 200) {
      throw HybridRouteException(
        "Hybrid route request failed with status ${response.statusCode}",
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return HybridRouteResult.fromJson(decoded);
  }

  /// Builds the /api/route request, performs the GET, validates the status,
  /// and returns the raw decoded JSON map.
  ///
  /// Interpretation of the payload (route type, path extraction, state
  /// transitions) deliberately remains the caller's responsibility — this is
  /// the backend communication + decoding layer only. Used by
  /// NavigationProvider, which keeps owning all navigation state semantics.
  Future<Map<String, dynamic>> fetchRouteJson({
    double? userLat,
    double? userLng,
    String? startIndoorNode,
    String? destinationIndoorNode,
    double? endLat,
    double? endLng,
  }) async {

    final params = <String, String>{};

    if (userLat != null) params["startLat"] = userLat.toString();
    if (userLng != null) params["startLng"] = userLng.toString();
    if (startIndoorNode != null) params["startIndoorNode"] = startIndoorNode;

    if (destinationIndoorNode != null) {
      params["destinationIndoorNode"] = destinationIndoorNode;
    }

    if (endLat != null) params["endLat"] = endLat.toString();
    if (endLng != null) params["endLng"] = endLng.toString();

    final uri = Uri.parse(_baseUrl).replace(queryParameters: params);

    debugPrint("🌍 Calling backend: $uri");

    final response = await _client.get(uri).timeout(_requestTimeout);

    debugPrint("📡 Response code: ${response.statusCode}");

    if (response.statusCode != 200) {
      throw HybridRouteException(
        "Route request failed with status ${response.statusCode}",
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
} // ← THIS BRACE WAS MISSING


class HybridRouteException implements Exception {
  HybridRouteException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'HybridRouteException($message, cause: $cause)';
}
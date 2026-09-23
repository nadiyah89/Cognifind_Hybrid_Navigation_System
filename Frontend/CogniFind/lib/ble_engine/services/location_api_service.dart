import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:http/http.dart'
as http;

import '../models/beacon_scan.dart';

import '../models/location_response.dart';

class LocationApiService {

  static const String _baseUrl =
      "https://cognifind-backend2.onrender.com/api/location";

  /// Bounds every /api/location poll so a sleeping/unreachable backend or an
  /// unstable network can't leave a realtime request pending forever. On
  /// timeout the poll throws TimeoutException (caught by
  /// RealtimePositionProvider), and the next 1s tick simply retries.
  static const Duration _requestTimeout = Duration(seconds: 10);

  Future<LocationResponse>
  fetchRealtimeLocation({

    required int buildingId,

    required double latitude,

    required double longitude,

    required double accuracy,

    required double speed,

    required double heading,

    required List<BeaconScan> beacons,
  }) async {

    final body = {

      "buildingId": buildingId,

      "gps": {

        "latitude": latitude,

        "longitude": longitude,

        "accuracy": accuracy,

        "speed": speed,
      },

      "heading": heading,

      "beacons":
      beacons.map((b) {

        return {

          "id": b.id,

          "rssi": b.rssi,
        };

      }).toList(),
    };

    /// TEMP TRACE: structured request summary (human-readable).
    final minewBeacons = beacons
        .where((b) => b.id.startsWith("ER-BLEV2.3"))
        .toList();
    final otherCount = beacons.length - minewBeacons.length;
    final minewLines = minewBeacons
        .map((b) => "  ${b.id}  ${b.rssi}")
        .join("\n");
    debugPrint(
      "[LOCATION REQUEST]\n"
      "  totalDevices=${beacons.length}\n"
      "  minewDevices=${minewBeacons.length}\n"
      "  otherDevices=$otherCount\n"
      "$minewLines",
    );

    /// Full payload (for copy-paste debugging if needed).
    debugPrint(
      "[LOCATION REQUEST JSON] ${jsonEncode(body)}",
    );

    final response =
    await http.post(

      Uri.parse(_baseUrl),

      headers: {
        "Content-Type":
        "application/json",
      },

      body: jsonEncode(body),
    ).timeout(_requestTimeout);

    if (response.statusCode != 200) {

      debugPrint(
        "[LOCATION API ERROR]"
        " status=${response.statusCode}"
        " body=${response.body}",
      );

      throw Exception(
        "Location API failed",
      );
    }

    /// ── TEMP TRACE: raw backend response ──
    debugPrint(
      "[LOCATION RAW RESPONSE] ${response.body}",
    );

    final json =
    jsonDecode(response.body);

    return LocationResponse
        .fromJson(json);
  }
}
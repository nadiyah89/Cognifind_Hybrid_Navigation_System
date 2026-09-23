import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BeaconService {

  StreamSubscription? _scanSubscription;

  Timer? _restartTimer;

  void startScanning({
    required Function(
        String beaconId,
        int rssi,
        ) onBeaconDetected,
  }) async {

    await _startScan(
      onBeaconDetected,
    );

    /// Restart scanning every 12 seconds
    _restartTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) async {

        debugPrint(
          "RESTARTING BLE SCAN",
        );

        await FlutterBluePlus.stopScan();

        await _startScan(
          onBeaconDetected,
        );
      },
    );
  }

  Future<void> _startScan(
      Function(
          String beaconId,
          int rssi,
          )
      onBeaconDetected,
      ) async {

    await FlutterBluePlus.startScan(
      timeout: const Duration(
        seconds: 7,
      ),
    );

    _scanSubscription?.cancel();

    _scanSubscription =
        FlutterBluePlus.scanResults.listen(
              (results) {

            if (results.isEmpty) return;

            ScanResult? strongest;

            for (final result in results) {

              final deviceName =
                  result.advertisementData
                      .advName;

              debugPrint(
                "DEVICE: $deviceName "
                    "RSSI: ${result.rssi}",
              );

              /// ONLY OUR BEACONS
              if (!deviceName.startsWith(
                  "ER-BLEV2.3")) {
                continue;
              }

              if (strongest == null ||
                  result.rssi >
                      strongest.rssi) {

                strongest = result;
              }
            }

            if (strongest == null) {
              debugPrint(
                  "NO BEACON FOUND");
              return;
            }

            final name =
                strongest
                    .advertisementData
                    .advName;

            debugPrint(
                "DETECTED: $name");

            onBeaconDetected(
              name,
              strongest.rssi,
            );
          },
        );
  }

  void dispose() {

    _restartTimer?.cancel();

    _scanSubscription?.cancel();

    FlutterBluePlus.stopScan();
  }
}
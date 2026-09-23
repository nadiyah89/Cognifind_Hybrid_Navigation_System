import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'package:permission_handler/permission_handler.dart';

import '../models/beacon_scan.dart';

import '../utils/rssi_smoother.dart';

class BeaconService {

  StreamSubscription<List<ScanResult>>?
  _scanSubscription;

  bool _isScanning = false;

  final List<BeaconScan>
  _latestReadings = [];

  final Function(
      List<BeaconScan>
      )
  onReadingsUpdated;

  BeaconService({
    required this.onReadingsUpdated,
  });

  /// =====================================
  /// START BLE ENGINE
  /// =====================================

  Future<void> start() async {
    debugPrint(
      "BLE START RUNNING",
    );
    if (_isScanning) {
      return;
    }

    /// Runtime Bluetooth permissions (Android 12+ / API 31+). The app launches
    /// straight into NavigationScreen, bypassing SplashScreen where these used
    /// to be requested, so request here — the single point where BLE scanning
    /// begins (constructor start + lifecycle resume) — to guarantee the grant
    /// on the real launch path BEFORE startScan(). Fail-soft: on denial the
    /// scan simply won't start, exactly as before (GPS-only navigation).
    await _ensureBluetoothPermissions();

    /// Bluetooth auto-enable (activation UX only). Ensures the adapter is on
    /// before scanning — on Android this prompts the system enable dialog.
    /// The scan pipeline below is unchanged.
    final ready = await _ensureBluetoothOn();
    if (!ready) {
      debugPrint(
        "[BLE] adapter not on — scan not started"
        " (retries on next start())",
      );
      return;
    }

    _isScanning = true;

    try {

      _scanSubscription?.cancel();

      _scanSubscription =
          FlutterBluePlus.scanResults.listen(

                (results) {

              final totalDevices = results.length;
              int ignoredDevices = 0;

              _latestReadings.clear();

              for (final result in results) {

                final name =
                    result
                        .advertisementData
                        .advName;

                /// ── MINEW FILTER ──
                /// Only accept beacons with our registered prefix.
                /// All other BLE devices are ignored immediately.
                if (!name.startsWith("ER-BLEV2.3")) {
                  ignoredDevices++;
                  continue;
                }

                final beaconId = name;
                final rawRssi = result.rssi;

                final smoothRssi =
                RssiSmoother.smooth(
                  beaconId,
                  rawRssi,
                );

                _latestReadings.add(

                  BeaconScan(

                    id: beaconId,

                    rssi: smoothRssi,

                    timestamp:
                    DateTime.now(),
                  ),
                );
              }

              /// SORT STRONGEST FIRST
              _latestReadings.sort(

                    (a, b) =>

                    b.rssi.compareTo(
                        a.rssi),
              );

              /// ── BLE CALLBACK SUMMARY ──
              debugPrint(
                "BLE CALLBACK"
                " | Detected Devices: $totalDevices"
                " | Minew Accepted: ${_latestReadings.length}"
                " | Ignored Devices: $ignoredDevices"
                " | Sending ${_latestReadings.length} beacons to backend",
              );

              /// ── EACH BEACON SENT ──
              for (final b in _latestReadings) {
                debugPrint(
                  "Sending Beacon"
                  " | ID: ${b.id}"
                  " | RSSI: ${b.rssi}",
                );
              }

              onReadingsUpdated(
                List.from(
                    _latestReadings),
              );
            },
          );

      /// Start AFTER listener is attached so no
      /// results are missed. continuousUpdates
      /// re-emits the full device list every scan
      /// cycle so _latestReadings stays fresh.
      debugPrint(
        "[BLE] starting continuous scan",
      );

      await FlutterBluePlus.startScan(
        continuousUpdates: true,
        removeIfGone: const Duration(
          seconds: 5,
        ),
      );

    } catch (e) {

      debugPrint(
        "BLE START ERROR: $e",
      );
    }
  }

  /// =====================================
  /// BLUETOOTH RUNTIME PERMISSIONS (Android 12+)
  /// =====================================
  ///
  /// Requests BLUETOOTH_SCAN / BLUETOOTH_CONNECT, required before any scan on
  /// API 31+. No-op on iOS; on Android < 12 the plugin resolves these as
  /// granted automatically, so no prompt is shown. Fails soft — on denial or
  /// any error the app continues in GPS-only mode.

  Future<void> _ensureBluetoothPermissions() async {
    if (!Platform.isAndroid) return;
    try {
      await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
    } catch (_) {
      // BLE is optional — outdoor GPS navigation works without it.
    }
  }

  /// =====================================
  /// BLUETOOTH AUTO-ENABLE (activation UX)
  /// =====================================
  ///
  /// Ensures the Bluetooth adapter is on before scanning:
  /// - already on → proceed.
  /// - off on Android → request the system enable dialog (turnOn), then wait
  ///   for the adapter to report on.
  /// - off on iOS → cannot force-enable; the OS surfaces its own prompt, so we
  ///   just wait (bounded) for the user to enable it.
  ///
  /// Returns true once the adapter is on, false if it stays off / is denied /
  /// is unsupported. Does not touch the scan pipeline.

  Future<bool> _ensureBluetoothOn() async {

    if (!await FlutterBluePlus.isSupported) {
      debugPrint(
        "[BLE] bluetooth not supported on this device",
      );
      return false;
    }

    var state = FlutterBluePlus.adapterStateNow;
    debugPrint(
      "[BLE] adapterState=${state.name}",
    );

    if (state == BluetoothAdapterState.on) {
      return true;
    }

    if (Platform.isAndroid) {
      debugPrint(
        "[BLE] requesting bluetooth enable",
      );
      try {
        await FlutterBluePlus.turnOn();
      } catch (e) {
        debugPrint(
          "[BLE] enable request failed/denied: $e",
        );
      }
    } else {
      debugPrint(
        "[BLE] bluetooth off"
        " (iOS cannot auto-enable; awaiting user)",
      );
    }

    /// Wait (bounded) for the adapter to actually reach 'on'. The stream emits
    /// the current state immediately, so this resolves instantly if already on.
    try {
      state = await FlutterBluePlus.adapterState
          .firstWhere(
            (s) => s == BluetoothAdapterState.on,
          )
          .timeout(
            const Duration(seconds: 15),
          );
    } catch (_) {
      state = FlutterBluePlus.adapterStateNow;
    }

    debugPrint(
      "[BLE] adapterState=${state.name}",
    );

    return state == BluetoothAdapterState.on;
  }

  /// =====================================
  /// STOP (pause-safe; reversible via start())
  /// =====================================
  ///
  /// Cancels the active scan + subscription and resets [_isScanning] so a
  /// later call to [start] resumes scanning cleanly. Used for app-lifecycle
  /// pause/resume. Idempotent — safe to call when already stopped.

  Future<void> stop() async {
    debugPrint(
      "BLE STOP RUNNING",
    );

    _isScanning = false;

    await _scanSubscription?.cancel();

    _scanSubscription = null;

    await FlutterBluePlus.stopScan();
  }

  /// =====================================
  /// DISPOSE
  /// =====================================

  Future<void> dispose() async {

    _isScanning = false;

    await _scanSubscription?.cancel();

    await FlutterBluePlus.stopScan();
  }
}
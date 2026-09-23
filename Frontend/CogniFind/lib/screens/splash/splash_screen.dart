import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cognifind/features/auth/presentation/login_screen.dart';

import 'package:cognifind/core/storage/token_storage.dart';
import 'package:cognifind/features/navigation/presentation/navigation_screen.dart';

/// SplashScreen
///
/// Shows app logo/name for a short time
/// then navigates to NavigationScreen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleStartup();
  }

  Future<void> _handleStartup() async {

    /// Step 1: Check location permission logic (your existing feature)
    await _checkAndRequestCampusLocationAtStartup();

    /// Step 1b: Request Android 12+ Bluetooth permissions for BLE scanning.
    await _requestBluetoothPermissionsAtStartup();

    /// Step 2: Keep splash visible for 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    /// Step 3: Get stored JWT token
    final token = await TokenStorage.getToken();

    if (!mounted) return;

    /// Step 4: Decide where to go
    if (token != null) {

      /// User already logged in → go to main app
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const NavigationScreen(),
        ),
      );

    } else {

      /// No token → go to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );

    }
  }

  Future<void> _checkAndRequestCampusLocationAtStartup() async {
    final permission = await Geolocator.checkPermission();
    final isGranted = permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
    if (isGranted) return;

    final prefs = await SharedPreferences.getInstance();
    final previouslyAsked = prefs.getBool('asked_location_permission') ?? false;

    // Show the campus-scoped explainer (and re-show if still not granted).
    if (!context.mounted) return;
    final shouldProceed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Use your location on campus'),
            content: Text(
              previouslyAsked
                  ? 'To show your position on campus maps, please allow location access.'
                  : 'Cognifind uses your location only while you are on campus, '
                      'to show your position on the indoor and outdoor maps.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Not now'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;

    await prefs.setBool('asked_location_permission', true);
    if (!shouldProceed) return;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }

    await Geolocator.requestPermission();
  }

  /// Requests the Android 12+ runtime Bluetooth permissions
  /// (BLUETOOTH_SCAN / BLUETOOTH_CONNECT) required for BLE beacon scanning,
  /// alongside the existing location flow.
  ///
  /// Fails soft: on denial or any error the app continues normally in
  /// GPS-only mode. No-op on iOS; on Android < 12 the permission_handler
  /// plugin resolves these as granted automatically, so no prompt is shown.
  Future<void> _requestBluetoothPermissionsAtStartup() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade600,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icon/cognifind_full.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 20),
            const Text(
              'Cognifind',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

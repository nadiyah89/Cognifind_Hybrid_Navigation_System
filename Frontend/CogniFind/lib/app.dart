import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:cognifind/providers/location_provider.dart';
import 'package:cognifind/providers/navigation_provider.dart';

import 'package:cognifind/indoor_engine/providers/indoor_navigation_provider.dart';

import 'package:cognifind/ble_engine/providers/realtime_position_provider.dart';

import 'package:cognifind/ble_test/ble_position_provider.dart';

import 'package:cognifind/core/config/demo_config.dart';
import 'package:cognifind/core/demo/demo_position_driver.dart';

import 'package:cognifind/features/navigation/presentation/navigation_screen.dart';

/// ======================================================
/// ROOT APP
/// ======================================================

class CognifindApp extends StatelessWidget {

  const CognifindApp({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    debugPrint(
      "COGNIFIND APP BUILDING",
    );

    return MultiProvider(

      providers: [

        /// ==================================================
        /// NAVIGATION PROVIDER
        /// ==================================================

        ChangeNotifierProvider(

          create: (_) =>
              NavigationProvider(),
        ),

        /// ==================================================
        /// LOCATION PROVIDER
        /// ==================================================

        ChangeNotifierProvider(

          create: (_) {

            final provider =
            LocationProvider();

            provider.initializeLocation();

            return provider;
          },
        ),

        /// ==================================================
        /// INDOOR NAVIGATION PROVIDER
        /// ==================================================

        ChangeNotifierProvider(

          create: (_) =>
              IndoorNavigationProvider(),
        ),

        /// ==================================================
        /// REALTIME POSITION PROVIDER
        /// ==================================================
        ///
        /// Uses SAME IndoorNavigationProvider
        /// instance as UI.
        ///
        /// Backend controls:
        /// - x,y
        /// - floor
        /// - heading
        /// - indoor detection
        ///
        /// Flutter only renders UI.
        /// ==================================================

        ChangeNotifierProxyProvider2<
            IndoorNavigationProvider,
            NavigationProvider,
            RealtimePositionProvider>(

          /// Eagerly instantiated: RealtimePositionProvider is now core
          /// infrastructure (BLE scan + realtime poll + auto-transition
          /// driver) and must run deterministically from cold launch, not
          /// only after the first background/foreground cycle. Duplicate
          /// scans/timers are already guarded internally.
          lazy: false,

          create: (_) =>

              RealtimePositionProvider(

                indoorNavigationProvider:
                IndoorNavigationProvider(),
              ),

          update: (
              _,
              indoorProvider,
              navProvider,
              realtimeProvider,
              ) {

            realtimeProvider!
                .updateIndoorProvider(
              indoorProvider,
            );

            /// Read-only reference so the realtime driver can feed the
            /// auto-transition evaluator (Priority #5). Transition authority
            /// stays in NavigationProvider.
            realtimeProvider
                .updateNavigationProvider(
              navProvider,
            );

            return realtimeProvider;
          },
        ),

        /// ==================================================
        /// BLE TEST PROVIDER
        /// ==================================================

        ChangeNotifierProvider(

          create: (_) =>
              BlePositionProvider(),
        ),

        /// ==================================================
        /// DEMO POSITION DRIVER
        /// ==================================================
        ///
        /// Demo mode only, and the ONLY thing demo mode adds to the tree.
        /// It stands in for the two production position sources (the
        /// Geolocator stream and RealtimePositionProvider's BLE poll), writing
        /// through the same provider entry points they do. It exposes no state
        /// and no UI — it observes the navigation providers and injects
        /// positions — so nothing below it depends on, or can see, demo mode.
        ///
        /// Eager: it must be listening before the first route starts.

        if (kDemoNavigationMode)
          Provider<DemoPositionDriver>(
            lazy: false,
            create: (context) => DemoPositionDriver(
              locationProvider: context.read<LocationProvider>(),
              navigationProvider: context.read<NavigationProvider>(),
              indoorNavigationProvider:
                  context.read<IndoorNavigationProvider>(),
            ),
            dispose: (_, driver) => driver.dispose(),
          ),
      ],

      /// ==================================================
      /// BLE LIFECYCLE OBSERVER
      /// ==================================================
      ///
      /// Placed BELOW MultiProvider so it can read
      /// RealtimePositionProvider. Pauses BLE scan + backend
      /// polling when the app is backgrounded and resumes them
      /// on foreground. GPS/outdoor location is unaffected.

      child: _BleLifecycleObserver(

        child: MaterialApp(

          title: 'Cognifind',

          debugShowCheckedModeBanner: false,

          theme: ThemeData(

            colorScheme: ColorScheme.fromSeed(

              seedColor: Colors.indigo,
            ),

            useMaterial3: true,
          ),

          /// ==================================================
          /// START MAIN NAVIGATION SYSTEM
          /// ==================================================

          home: NavigationScreen(),
        ),
      ),
    );
  }
}

/// ======================================================
/// BLE LIFECYCLE OBSERVER
/// ======================================================
///
/// Single app-lifecycle manager. Lives as a child of
/// MultiProvider so its context can read
/// RealtimePositionProvider. On background it pauses BLE
/// scanning + the backend polling timer; on foreground it
/// resumes them. LocationProvider (GPS/outdoor) is never
/// touched.

class _BleLifecycleObserver extends StatefulWidget {

  final Widget child;

  const _BleLifecycleObserver({
    required this.child,
  });

  @override
  State<_BleLifecycleObserver> createState() =>
      _BleLifecycleObserverState();
}

class _BleLifecycleObserverState
    extends State<_BleLifecycleObserver>
    with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    super.didChangeAppLifecycleState(state);

    if (!mounted) return;

    final realtime =
        context.read<RealtimePositionProvider>();

    if (state == AppLifecycleState.resumed) {

      realtime.resumeRealtimeTracking();

    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {

      realtime.pauseRealtimeTracking();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
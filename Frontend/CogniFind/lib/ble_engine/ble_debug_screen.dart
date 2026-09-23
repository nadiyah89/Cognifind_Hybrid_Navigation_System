import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'providers/realtime_position_provider.dart';

class BleDebugScreen
    extends StatelessWidget {

  const BleDebugScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {

    final provider =
    context.watch<
        RealtimePositionProvider>();

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Realtime BLE Engine",
        ),
      ),

      body: ListView.builder(

        itemCount:
        provider
            .nearbyBeacons
            .length,

        itemBuilder: (_, index) {

          final beacon =
          provider
              .nearbyBeacons[index];

          return ListTile(

            leading: CircleAvatar(
              child: Text(
                "${index + 1}",
              ),
            ),

            title: Text(
              beacon.id,
            ),

            subtitle: Text(
              "RSSI: ${beacon.rssi}",
            ),
          );
        },
      ),
    );
  }
}
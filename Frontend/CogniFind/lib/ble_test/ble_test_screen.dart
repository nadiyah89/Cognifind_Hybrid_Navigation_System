import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import 'beacon_mapper.dart';
import 'beacon_service.dart';
import 'ble_position_provider.dart';

class BleTestScreen extends StatefulWidget {
  const BleTestScreen({super.key});

  @override
  State<BleTestScreen> createState() =>
      _BleTestScreenState();
}

class _BleTestScreenState
    extends State<BleTestScreen> {

  final BeaconService _service =
  BeaconService();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback((_) {

      _service.startScanning(
        onBeaconDetected:
            (beaconId, rssi) {

          final provider =
          context.read<
              BlePositionProvider>();

          final mappedPosition =
          BeaconMapper
              .beaconPositions[
          beaconId];

          debugPrint(
              "DETECTED: $beaconId"
          );

          debugPrint(
              "MAPPED POSITION: $mappedPosition"
          );

          if (mappedPosition == null) {
            debugPrint("NO POSITION FOUND");
            return;
          }

          provider.updatePosition(
            position: mappedPosition,
            beacon: beaconId,
            rssi: rssi,
          );
        },
      );
    });
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final provider =
    context.watch<
        BlePositionProvider>();

    return Scaffold(
      appBar: AppBar(
        title:
        const Text("BLE Test"),
      ),

      body: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: 1588,
            height: 1124,
            child: Stack(
              children: [

                /// SVG MAP
                Positioned.fill(
                  child: SvgPicture.asset(
                    "assets/indoor/0_floor_cse.svg",
                    fit: BoxFit.fill,
                  ),
                ),

                /// BLUE DOT
                Positioned(
                  left: provider.position.dx - 14,
                  top: provider.position.dy - 14,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),

                /// DEBUG CARD
                Positioned(
                  left: 20,
                  bottom: 20,
                  child: Card(
                    child: Padding(
                      padding:
                      const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [

                          Text(
                            "Beacon: ${provider.nearestBeacon}",
                          ),

                          Text(
                            "RSSI: ${provider.rssi}",
                          ),

                          Text(
                            "X: ${provider.position.dx}",
                          ),

                          Text(
                            "Y: ${provider.position.dy}",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
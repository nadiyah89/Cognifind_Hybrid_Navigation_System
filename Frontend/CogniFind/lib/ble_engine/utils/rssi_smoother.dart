import 'package:flutter/foundation.dart';

class RssiSmoother {

  static final Map<
      String,
      List<int>
  > _history = {};

  static int smooth(
      String beaconId,
      int newRssi,
      ) {

    _history.putIfAbsent(
      beaconId,
          () => [],
    );

    final values =
    _history[beaconId]!;

    values.add(newRssi);

    /// Keep only latest 5 values
    if (values.length > 5) {
      values.removeAt(0);
    }

    final avg =
        values.reduce(
              (a, b) => a + b,
        ) ~/
            values.length;

    /// ── TEMP TRACE: smoother buffer (Minew beacons only) ──
    if (beaconId.startsWith("ER-BLEV2.3")) {
      debugPrint(
        "[RSSI SMOOTHER]"
        " beacon=$beaconId"
        " input=$newRssi"
        " buffer=$values"
        " avg=$avg",
      );
    }

    return avg;
  }
}

class BeaconScan {

  final String id;

  final int rssi;

  final DateTime timestamp;

  BeaconScan({
    required this.id,
    required this.rssi,
    required this.timestamp,
  });
}
class LocationResponse {

  final double x;

  final double y;

  final int floor;

  final double heading;

  final String nearestNode;

  final double confidence;

  final bool isIndoor;

  /// Map-matched (snapped) coordinates, when the backend provides them; null
  /// otherwise. Parsed for telemetry/observation only.
  final double? snappedX;

  final double? snappedY;

  const LocationResponse({
    required this.x,
    required this.y,
    required this.floor,
    required this.heading,
    required this.nearestNode,
    required this.confidence,
    required this.isIndoor,
    this.snappedX,
    this.snappedY,
  });

  factory LocationResponse.fromJson(
      Map<String, dynamic> json,
      ) {

    return LocationResponse(

      x: (json['x'] as num).toDouble(),

      y: (json['y'] as num).toDouble(),

      floor: json['floor'],

      heading:
      (json['heading'] as num).toDouble(),

      nearestNode:
      json['nearestNode'] ?? "",

      confidence:
      (json['confidence'] as num)
          .toDouble(),

      isIndoor:
      json['isIndoor'] ?? false,

      snappedX:
      (json['snappedX'] as num?)?.toDouble(),

      snappedY:
      (json['snappedY'] as num?)?.toDouble(),
    );
  }
}
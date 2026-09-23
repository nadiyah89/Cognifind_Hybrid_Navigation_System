class IndoorPosition {

  final double x;
  final double y;

  final int floor;

  final double heading;

  const IndoorPosition({
    required this.x,
    required this.y,
    required this.floor,
    required this.heading,
  });

  IndoorPosition copyWith({
    double? x,
    double? y,
    int? floor,
    double? heading,
  }) {
    return IndoorPosition(
      x: x ?? this.x,
      y: y ?? this.y,
      floor: floor ?? this.floor,
      heading: heading ?? this.heading,
    );
  }
}
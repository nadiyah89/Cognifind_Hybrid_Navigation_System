class IndoorNode {
  final String id;
  final int floor;
  final double x;
  final double y;
  final String type;

  IndoorNode({
    required this.id,
    required this.floor,
    required this.x,
    required this.y,
    required this.type,
  });

  factory IndoorNode.fromJson(Map<String, dynamic> json) {
    return IndoorNode(
      id: json['nodeId'],   // IMPORTANT
      floor: json['floor'],
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      type: json['type'],
    );
  }
}
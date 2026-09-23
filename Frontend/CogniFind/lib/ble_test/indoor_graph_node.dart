class IndoorGraphNode {

  final String nodeId;
  final int floorId;
  final double x;
  final double y;
  final String nodeType;

  IndoorGraphNode({
    required this.nodeId,
    required this.floorId,
    required this.x,
    required this.y,
    required this.nodeType,
  });

  factory IndoorGraphNode.fromCsv(
      Map<String, dynamic> row) {

    return IndoorGraphNode(
      nodeId: row['node_id'],
      floorId: row['floor_id'],
      x: double.parse(
          row['x'].toString()),
      y: double.parse(
          row['y'].toString()),
      nodeType: row['node_type'],
    );
  }
}
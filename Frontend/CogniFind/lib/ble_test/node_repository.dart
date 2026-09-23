import 'package:flutter/services.dart';

import 'package:csv/csv.dart';

import 'indoor_graph_node.dart';

class NodeRepository {

  static Future<
      List<IndoorGraphNode>>
  loadNodes() async {

    final raw =
    await rootBundle.loadString(
      'assets/indoor/nodes.csv',
    );

    final rows =
    const CsvToListConverter()
        .convert(raw);

    final headers =
        rows.first;

    final List<
        IndoorGraphNode> nodes = [];

    for (final row in rows.skip(1)) {

      final map =
      <String, dynamic>{};

      for (int i = 0;
      i < headers.length;
      i++) {

        map[
        headers[i].toString()
        ] = row[i];
      }

      nodes.add(
        IndoorGraphNode
            .fromCsv(map),
      );
    }

    return nodes;
  }
}
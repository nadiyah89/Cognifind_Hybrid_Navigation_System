import 'package:cognifind/models/navigation/indoor_node.dart';

/// Outdoor node coming from backend
class OutdoorNode {
  final String nodeId;
  final double latitude;
  final double longitude;

  OutdoorNode({
    required this.nodeId,
    required this.latitude,
    required this.longitude,
  });

  factory OutdoorNode.fromJson(Map<String, dynamic> json) {
    return OutdoorNode(
      nodeId: json['nodeId'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

/// Outdoor route
class OutdoorRoute {
  final String startNode;
  final String endNode;
  final List<OutdoorNode> path;
  final List<String>? instructions;

  OutdoorRoute({
    required this.startNode,
    required this.endNode,
    required this.path,
    this.instructions,
  });

  factory OutdoorRoute.fromJson(Map<String, dynamic> json) {
    final nodes = (json['path'] as List<dynamic>? ?? [])
        .map((e) => OutdoorNode.fromJson(e))
        .toList();

    final rawInstructions = json['instructions'] as List<dynamic>?;

    return OutdoorRoute(
      startNode: json['startNode'] ?? '',
      endNode: json['endNode'] ?? '',
      path: nodes,
      instructions:
          rawInstructions?.map((e) => e.toString()).toList(),
    );
  }
}

/// Indoor route
class IndoorRoute {
  final String sourceNode;
  final String destinationNode;
  final List<IndoorNode> path;
  final List<String>? instructions;
  final double? distance;

  IndoorRoute({
    required this.sourceNode,
    required this.destinationNode,
    required this.path,
    this.instructions,
    this.distance,
  });

  factory IndoorRoute.fromJson(Map<String, dynamic> json) {
    final nodes = (json['path'] as List<dynamic>? ?? [])
        .map((e) => IndoorNode.fromJson(e))
        .toList();

    final rawInstructions = json['instructions'] as List<dynamic>?;
    final rawDistance = json['distance'] as num?;

    return IndoorRoute(
      sourceNode: json['sourceNode'] ?? '',
      destinationNode: json['destinationNode'] ?? '',
      path: nodes,
      instructions:
          rawInstructions?.map((e) => e.toString()).toList(),
      distance: rawDistance?.toDouble(),
    );
  }
}

/// Transition between indoor and outdoor
class TransitionNode {
  final String outdoorNode;
  final String indoorNode;
  final String? instruction;

  TransitionNode({
    required this.outdoorNode,
    required this.indoorNode,
    this.instruction,
  });

  factory TransitionNode.fromJson(Map<String, dynamic> json) {
    return TransitionNode(
      outdoorNode: json['outdoorNode'] ?? '',
      indoorNode: json['indoorNode'] ?? '',
      instruction: json['instruction'] as String?,
    );
  }
}

/// Transition when LEAVING the source building (indoor → outdoor), from the new
/// multi-segment hybrid response. Mirrors [TransitionNode]'s style.
class ExitTransition {
  final String indoorNode;
  final String outdoorNode;
  final String instruction;

  ExitTransition({
    required this.indoorNode,
    required this.outdoorNode,
    required this.instruction,
  });

  factory ExitTransition.fromJson(Map<String, dynamic> json) {
    return ExitTransition(
      indoorNode: json['indoorNode'] ?? '',
      outdoorNode: json['outdoorNode'] ?? '',
      instruction: json['instruction'] ?? '',
    );
  }
}

/// Transition when ENTERING the destination building (outdoor → indoor), from
/// the new multi-segment hybrid response. Mirrors [TransitionNode]'s style.
class EnterTransition {
  final String outdoorNode;
  final String indoorNode;
  final String instruction;

  EnterTransition({
    required this.outdoorNode,
    required this.indoorNode,
    required this.instruction,
  });

  factory EnterTransition.fromJson(Map<String, dynamic> json) {
    return EnterTransition(
      outdoorNode: json['outdoorNode'] ?? '',
      indoorNode: json['indoorNode'] ?? '',
      instruction: json['instruction'] ?? '',
    );
  }
}

/// Main hybrid route result
class HybridRouteResult {
  final String type;
  final OutdoorRoute? outdoor;
  final IndoorRoute? indoor;
  final TransitionNode? transition;

  /// New multi-segment hybrid fields (indoor → outdoor → indoor). All optional
  /// and null by default so the existing single-indoor hybrid stays intact.
  /// Parsed in [fromJson] only when present (backward compatible with the old
  /// outdoor/transition/indoor format). [indoorStart] and [indoorDestination]
  /// reuse the existing [IndoorRoute] model. Consumed by later phases.
  final IndoorRoute? indoorStart;
  final ExitTransition? exitTransition;
  final EnterTransition? enterTransition;
  final IndoorRoute? indoorDestination;
  final double? totalIndoorDistance;

  HybridRouteResult({
    required this.type,
    this.outdoor,
    this.indoor,
    this.transition,
    this.indoorStart,
    this.exitTransition,
    this.enterTransition,
    this.indoorDestination,
    this.totalIndoorDistance,
  });

  factory HybridRouteResult.fromJson(Map<String, dynamic> json) {
    return HybridRouteResult(
      type: json['type'] ?? '',
      outdoor: json['outdoor'] != null
          ? OutdoorRoute.fromJson(json['outdoor'])
          : null,
      indoor: json['indoor'] != null
          ? IndoorRoute.fromJson(json['indoor'])
          : null,
      transition: json['transition'] != null
          ? TransitionNode.fromJson(json['transition'])
          : null,

      /// New multi-segment hybrid fields. Each is populated only when present,
      /// so old-format responses (outdoor/transition/indoor) and new-format
      /// responses (indoorStart/exitTransition/enterTransition/indoorDestination)
      /// both deserialize; absent keys stay null. [indoorStart] and
      /// [indoorDestination] reuse the existing [IndoorRoute.fromJson].
      indoorStart: json['indoorStart'] != null
          ? IndoorRoute.fromJson(json['indoorStart'])
          : null,
      exitTransition: json['exitTransition'] != null
          ? ExitTransition.fromJson(json['exitTransition'])
          : null,
      enterTransition: json['enterTransition'] != null
          ? EnterTransition.fromJson(json['enterTransition'])
          : null,
      indoorDestination: json['indoorDestination'] != null
          ? IndoorRoute.fromJson(json['indoorDestination'])
          : null,
      totalIndoorDistance:
          (json['totalIndoorDistance'] as num?)?.toDouble(),
    );
  }
}
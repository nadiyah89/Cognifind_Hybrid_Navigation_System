enum PlaceCategory {
  library,
  academic,
  administration,
  other,
}

class SearchPlace {
  final String id; // building ID like 'AB-I'
  final String name;
  final String subtitle;
  final PlaceCategory category;
  final double latitude;
  final double longitude;

  /// Optional indoor node for hybrid routing
  final String? destinationNodeId;

  const SearchPlace({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.destinationNodeId,
  });

  /// Whether this place supports indoor routing
  bool get supportsHybridRoute => destinationNodeId != null;

  /// Returns a copy with [destinationNodeId] overridden — used by the unified
  /// search to point a building at a specific indoor room node while keeping
  /// its outdoor anchor (id/name/coordinates) intact.
  SearchPlace copyWith({String? destinationNodeId}) {
    return SearchPlace(
      id: id,
      name: name,
      subtitle: subtitle,
      category: category,
      latitude: latitude,
      longitude: longitude,
      destinationNodeId: destinationNodeId ?? this.destinationNodeId,
    );
  }
}
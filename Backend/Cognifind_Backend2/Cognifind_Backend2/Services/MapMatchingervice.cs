using Cognifind_Backend2.Services;

public class MapMatchingService
{
    private readonly GraphService _graphService;
    private readonly LocalizationStateService _state;

    private const int RequiredConfirmations = 3;
    private const double MaxNodeSnapDistance = 120;

    public MapMatchingService(
        GraphService graphService,
        LocalizationStateService state)
    {
        _graphService = graphService;
        _state = state;
    }

    public MapMatchedPosition? SnapToNearestNode(
      double estimatedX,
      double estimatedY,
      int floorId,
      int buildingId)
    {
        Console.WriteLine("========================================");
        Console.WriteLine("MAP MATCHING");
        Console.WriteLine($"Estimated Position : {estimatedX:F2}, {estimatedY:F2}");
        Console.WriteLine($"Estimated Floor    : {floorId}");
        Console.WriteLine($"Graph Nodes        : {_graphService.NodeCoordinateMap.Count}");
        Console.WriteLine($"Floor Map          : {_graphService.NodeFloorMap.Count}");

        if (_graphService.NodeCoordinateMap.Count == 0)
        {
            Console.WriteLine("ERROR: Graph is empty.");
            return null;
        }

        MapMatchedPosition? nearest = null;
        double shortestDistance = double.MaxValue;

        foreach (var node in _graphService.NodeCoordinateMap)
        {
            string nodeId = node.Key;

            if (!_graphService.NodeFloorMap.TryGetValue(nodeId, out int nodeFloor))
                continue;

            if (!_graphService.NodeBuildingMap.TryGetValue(nodeId, out int nodeBuilding))
                continue;

            if (nodeFloor != floorId)
                continue;

            if (nodeBuilding != buildingId)
                continue;
            var (nodeX, nodeY) = node.Value;

            double distance = Math.Sqrt(
                Math.Pow(nodeX - estimatedX, 2) +
                Math.Pow(nodeY - estimatedY, 2));

            if (distance < shortestDistance)
            {
                shortestDistance = distance;

                nearest = new MapMatchedPosition
                {
                    NodeId = nodeId,
                    X = nodeX,
                    Y = nodeY,
                    FloorId = nodeFloor,
                    Distance = distance
                };
            }
        }

        if (nearest == null)
        {
            Console.WriteLine("No node found on this floor.");
            return null;
        }

        Console.WriteLine(
            $"Nearest Node = {nearest.NodeId}  Distance = {nearest.Distance:F2}");

        // Don't snap if estimated position is too far away
        if (nearest.Distance > MaxNodeSnapDistance)
        {
            Console.WriteLine(
                $"Nearest node too far ({nearest.Distance:F2}px)");

            // Keep previous node if available
            if (!string.IsNullOrEmpty(_state.LastNodeId) &&
                _graphService.NodeCoordinateMap.ContainsKey(_state.LastNodeId))
            {
                var coords = _graphService.NodeCoordinateMap[_state.LastNodeId];

                return new MapMatchedPosition
                {
                    NodeId = _state.LastNodeId,
                    X = coords.X,
                    Y = coords.Y,
                    FloorId = _graphService.NodeFloorMap[_state.LastNodeId],
                    Distance = nearest.Distance
                };
            }

            return null;
        }

        // First localization
        if (string.IsNullOrEmpty(_state.LastNodeId))
        {
            Console.WriteLine($"Initial Node = {nearest.NodeId}");

            _state.LastNodeId = nearest.NodeId;
            return nearest;
        }

        // Same node
        if (nearest.NodeId == _state.LastNodeId)
        {
            _state.PendingNodeId = null;
            _state.PendingNodeCount = 0;

            return nearest;
        }

        // Candidate node
        if (_state.PendingNodeId == nearest.NodeId)
        {
            _state.PendingNodeCount++;
        }
        else
        {
            _state.PendingNodeId = nearest.NodeId;
            _state.PendingNodeCount = 1;
        }

        Console.WriteLine(
            $"Candidate Node = {_state.PendingNodeId}  Count = {_state.PendingNodeCount}");

        // Confirm switch
        if (_state.PendingNodeCount >= RequiredConfirmations)
        {
            Console.WriteLine(
                $"Switching Node {_state.LastNodeId} -> {nearest.NodeId}");

            _state.LastNodeId = nearest.NodeId;
            _state.PendingNodeId = null;
            _state.PendingNodeCount = 0;

            return nearest;
        }

        // Keep previous node
        Console.WriteLine($"Keeping Previous Node = {_state.LastNodeId}");

        if (_graphService.NodeCoordinateMap.TryGetValue(_state.LastNodeId, out var previousCoords))
        {
            return new MapMatchedPosition
            {
                NodeId = _state.LastNodeId,
                X = previousCoords.X,
                Y = previousCoords.Y,
                FloorId = _graphService.NodeFloorMap[_state.LastNodeId],
                Distance = nearest.Distance
            };
        }

        return nearest;
    }
}
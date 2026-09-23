using Cognifind_Backend2.Services;
using Cognifind_Backend2.Models;
using System;
using System.Collections.Generic;

public class MapMatchingService
{
    private readonly GraphService _graphService;

    public MapMatchingService(GraphService graphService)
    {
        _graphService = graphService;
    }

    public MapMatchedPosition? ProjectOntoRoute(
        double estimatedX,
        double estimatedY,
        int floorId,
        List<string>? routeNodeIds)
    {
        if (routeNodeIds == null || routeNodeIds.Count < 2)
        {
            return null;
        }

        MapMatchedPosition? bestMatch = null;
        double shortestDistance = double.MaxValue;

        for (int i = 0; i < routeNodeIds.Count - 1; i++)
        {
            string nodeAId = routeNodeIds[i];
            string nodeBId = routeNodeIds[i + 1];

            if (!_graphService.NodeCoordinateMap.TryGetValue(nodeAId, out var nodeA) ||
                !_graphService.NodeCoordinateMap.TryGetValue(nodeBId, out var nodeB) ||
                !_graphService.NodeFloorMap.TryGetValue(nodeAId, out int floorA) ||
                !_graphService.NodeFloorMap.TryGetValue(nodeBId, out int floorB))
            {
                continue;
            }

            if (floorA != floorId || floorB != floorId)
            {
                continue;
            }

            var (projX, projY) = ProjectPointOntoSegment(estimatedX, estimatedY, nodeA.X, nodeA.Y, nodeB.X, nodeB.Y);

            double distance = Math.Sqrt(Math.Pow(projX - estimatedX, 2) + Math.Pow(projY - estimatedY, 2));

            if (distance < shortestDistance)
            {
                shortestDistance = distance;

                double distToA = Math.Sqrt(Math.Pow(projX - nodeA.X, 2) + Math.Pow(projY - nodeA.Y, 2));
                double distToB = Math.Sqrt(Math.Pow(projX - nodeB.X, 2) + Math.Pow(projY - nodeB.Y, 2));
                string nearestNodeId = distToA < distToB ? nodeAId : nodeBId;

                bestMatch = new MapMatchedPosition
                {
                    NodeId = nearestNodeId,
                    X = projX,
                    Y = projY,
                    FloorId = floorId,
                    Distance = distance
                };
            }
        }

        if (shortestDistance > 120)
        {
            return null;
        }

        return bestMatch;
    }

    private (double X, double Y) ProjectPointOntoSegment(double px, double py, double ax, double ay, double bx, double by)
    {
        double dx = bx - ax;
        double dy = by - ay;

        if (dx == 0 && dy == 0)
        {
            return (ax, ay);
        }

        double t = ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy);
        t = Math.Max(0, Math.Min(1, t)); 

        return (ax + t * dx, ay + t * dy);
    }
}
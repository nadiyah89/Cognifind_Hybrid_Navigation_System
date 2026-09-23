
//this file contains the both dijkistras and a* earlier we used dijkistras so keeping both
// a* and dijkistras there and can use one among the two 
using Cognifind_Backend2.DTOs.Indoor;
using Cognifind_Backend2.Models;

namespace Cognifind_Backend2.Services
{
    public class DijkstraService
    {
        private readonly GraphService _graphService;

        public DijkstraService(GraphService graphService)
        {
            _graphService = graphService;
        }

        // Heuristic function for A*
        private double Heuristic(string a, string b)
        {
            var (x1, y1) = _graphService.NodeCoordinateMap[a];
            var (x2, y2) = _graphService.NodeCoordinateMap[b];

            return Math.Sqrt(Math.Pow(x1 - x2, 2) + Math.Pow(y1 - y2, 2));
        }

        //public (List<PathNode> path, double distance)
        //    FindPath(string start, string end)
        //{
        //    var graph = _graphService.Graph;

        //    var dist = new Dictionary<string, double>();
        //    var prev = new Dictionary<string, string>();
        //    var pq = new PriorityQueue<string, double>();

        //    foreach (var node in graph.Keys)
        //        dist[node] = double.MaxValue;

        //    dist[start] = 0;
        //    pq.Enqueue(start, 0);

        //    while (pq.Count > 0)
        //    {
        //        var curr = pq.Dequeue();

        //        if (curr == end)
        //            break;

        //        foreach (var (next, weight) in graph[curr])
        //        {
        //            var alt = dist[curr] + weight;

        //            if (alt < dist[next])
        //            {
        //                dist[next] = alt;
        //                prev[next] = curr;
        //                pq.Enqueue(next, alt);
        //            }
        //        }
        //    }

        //    var path = new List<PathNode>();
        //    var c = end;

        //    while (prev.ContainsKey(c))
        //    {
        //        path.Insert(0, new PathNode
        //        {
        //            NodeId = c,
        //            Floor = _graphService.NodeFloorMap[c],
        //            X = _graphService.NodeCoordinateMap[c].X,
        //            Y = _graphService.NodeCoordinateMap[c].Y,
        //            Type = _graphService.NodeTypeMap[c]
        //        });

        //        c = prev[c];
        //    }

        //    path.Insert(0, new PathNode
        //    {
        //        NodeId = start,
        //        Floor = _graphService.NodeFloorMap[start],
        //        X = _graphService.NodeCoordinateMap[start].X,
        //        Y = _graphService.NodeCoordinateMap[start].Y,
        //        Type = _graphService.NodeTypeMap[start]
        //    });

        //    return (path, dist[end]);
        //}

        public (List<PathNode> path, double distance)
            FindPath(string start, string end)
        {
            var graph = _graphService.Graph;

            // Safety check
            if (!graph.ContainsKey(start) || !graph.ContainsKey(end))
            {
                return (new List<PathNode>(), double.MaxValue);
            }

            var gScore = new Dictionary<string, double>();
            var prev = new Dictionary<string, string>();
            var pq = new PriorityQueue<string, double>();

            foreach (var node in graph.Keys)
                gScore[node] = double.MaxValue;

            gScore[start] = 0;

            pq.Enqueue(start, Heuristic(start, end));

            while (pq.Count > 0)
            {
                var curr = pq.Dequeue();

                if (curr == end)
                    break;

                foreach (var (next, weight) in graph[curr])
                {
                    var tentative = gScore[curr] + weight;

                    if (tentative < gScore[next])
                    {
                        prev[next] = curr;
                        gScore[next] = tentative;

                        var fScore = tentative + Heuristic(next, end);

                        pq.Enqueue(next, fScore);
                    }
                }
            }

            var path = new List<PathNode>();
            var c = end;

            while (prev.ContainsKey(c))
            {
                path.Insert(0, new PathNode
                {
                    NodeId = c,
                    Floor = _graphService.NodeFloorMap[c],
                    X = _graphService.NodeCoordinateMap[c].X,
                    Y = _graphService.NodeCoordinateMap[c].Y,
                    Type = _graphService.NodeTypeMap[c]
                });

                c = prev[c];
            }

            path.Insert(0, new PathNode
            {
                NodeId = start,
                Floor = _graphService.NodeFloorMap[start],
                X = _graphService.NodeCoordinateMap[start].X,
                Y = _graphService.NodeCoordinateMap[start].Y,
                Type = _graphService.NodeTypeMap[start]
            });

            return (path, gScore[end]);
        }
    }
}
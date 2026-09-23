public class OutdoorRoutingService
{
    private readonly OutdoorGraphLoader _graph;

    public OutdoorRoutingService(OutdoorGraphLoader graph)
    {
        _graph = graph;
    }

    public List<string> FindPath(string startNode, string goalNode)
    {
        var openSet = new PriorityQueue<string, double>();

        var cameFrom = new Dictionary<string, string>();

        var gScore = new Dictionary<string, double>();
        var fScore = new Dictionary<string, double>();

        foreach (var node in _graph.Graph.Keys)
        {
            gScore[node] = double.MaxValue;
            fScore[node] = double.MaxValue;
        }

        gScore[startNode] = 0;
        fScore[startNode] = Heuristic(startNode, goalNode);

        openSet.Enqueue(startNode, fScore[startNode]);

        while (openSet.Count > 0)
        {
            var current = openSet.Dequeue();

            if (current == goalNode)
                return ReconstructPath(cameFrom, current);

            foreach (var (neighbor, distance) in _graph.Graph[current])
            {
                double tentative = gScore[current] + distance;

                if (tentative < gScore[neighbor])
                {
                    cameFrom[neighbor] = current;
                    gScore[neighbor] = tentative;

                    fScore[neighbor] =
                        tentative + Heuristic(neighbor, goalNode);

                    openSet.Enqueue(neighbor, fScore[neighbor]);
                }
            }
        }

        return new List<string>();
    }

    private double Heuristic(string a, string b)
    {
        if (!_graph.NodeCoords.ContainsKey(a))
            throw new Exception($"Outdoor node '{a}' not found.");

        if (!_graph.NodeCoords.ContainsKey(b))
            throw new Exception($"Outdoor node '{b}' not found.");

        var nodeA = _graph.NodeCoords[a];
        var nodeB = _graph.NodeCoords[b];

        return Haversine(
            nodeA.lat,
            nodeA.lng,
            nodeB.lat,
            nodeB.lng);
    }

    private double Haversine(double lat1, double lon1, double lat2, double lon2)
    {
        double R = 6371000;

        double dLat = (lat2 - lat1) * Math.PI / 180;
        double dLon = (lon2 - lon1) * Math.PI / 180;

        lat1 *= Math.PI / 180;
        lat2 *= Math.PI / 180;

        double a = Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
                   Math.Sin(dLon / 2) * Math.Sin(dLon / 2) *
                   Math.Cos(lat1) * Math.Cos(lat2);

        double c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));

        return R * c;
    }

    private List<string> ReconstructPath(
        Dictionary<string, string> cameFrom,
        string current)
    {
        var totalPath = new List<string> { current };

        while (cameFrom.ContainsKey(current))
        {
            current = cameFrom[current];
            totalPath.Insert(0, current);
        }

        return totalPath;
    }
}
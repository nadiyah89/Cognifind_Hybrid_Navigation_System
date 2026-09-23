using Microsoft.EntityFrameworkCore;

public class OutdoorGraphLoader
{
    private readonly AppDbContext _context;

    public Dictionary<string, List<(string neighbor, double distance)>> Graph
        = new();

    public Dictionary<string, (double lat, double lng)> NodeCoords
        = new();

    // Indicates whether the graph has already been loaded
    public bool IsLoaded { get; private set; }

    public OutdoorGraphLoader(AppDbContext context)
    {
        _context = context;
    }

    public async Task LoadGraphAsync()
    {
        // Already loaded
        if (IsLoaded)
            return;

        Graph.Clear();
        NodeCoords.Clear();

        var nodes = await _context.OutdoorNodes.ToListAsync();
        var edges = await _context.OutdoorEdges.ToListAsync();

        // -----------------------------
        // Load Nodes
        // -----------------------------
        foreach (var node in nodes)
        {
            NodeCoords[node.NodeId] = (node.Latitude, node.Longitude);

            Graph[node.NodeId] = new List<(string, double)>();
        }

        // -----------------------------
        // Load Database Edges
        // -----------------------------
        foreach (var edge in edges)
        {
            if (Graph.ContainsKey(edge.FromNode) &&
                Graph.ContainsKey(edge.ToNode))
            {
                Graph[edge.FromNode].Add((edge.ToNode, edge.Distance));
                Graph[edge.ToNode].Add((edge.FromNode, edge.Distance));
            }
        }

        // -----------------------------
        // OPTIONAL
        // Auto-connect nearby nodes
        // Remove this after your map is complete.
        // -----------------------------
        foreach (var nodeA in nodes)
        {
            foreach (var nodeB in nodes)
            {
                if (nodeA.NodeId == nodeB.NodeId)
                    continue;

                double distance = Haversine(
                    nodeA.Latitude,
                    nodeA.Longitude,
                    nodeB.Latitude,
                    nodeB.Longitude);

                if (distance < 15)
                {
                    bool exists = Graph[nodeA.NodeId]
                        .Any(x => x.neighbor == nodeB.NodeId);

                    if (!exists)
                    {
                        Graph[nodeA.NodeId]
                            .Add((nodeB.NodeId, distance));
                    }
                }
            }
        }

        IsLoaded = true;

        Console.WriteLine("--------------------------------");
        Console.WriteLine($"Outdoor Nodes : {nodes.Count}");
        Console.WriteLine($"Outdoor Edges : {edges.Count}");
        Console.WriteLine("--------------------------------");
    }

    private double Haversine(
        double lat1,
        double lon1,
        double lat2,
        double lon2)
    {
        const double R = 6371000;

        double dLat = (lat2 - lat1) * Math.PI / 180.0;
        double dLon = (lon2 - lon1) * Math.PI / 180.0;

        lat1 *= Math.PI / 180.0;
        lat2 *= Math.PI / 180.0;

        double a =
            Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
            Math.Sin(dLon / 2) * Math.Sin(dLon / 2) *
            Math.Cos(lat1) * Math.Cos(lat2);

        double c =
            2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));

        return R * c;
    }
}
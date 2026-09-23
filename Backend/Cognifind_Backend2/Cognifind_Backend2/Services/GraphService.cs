using Microsoft.EntityFrameworkCore;

namespace Cognifind_Backend2.Services
{
    public class GraphService
    {
        private readonly AppDbContext _context;
        private readonly IConfiguration _config;

        public Dictionary<string, List<(string to, double weight)>> Graph
            = new();

        public Dictionary<string, int> NodeFloorMap
            = new();

        public Dictionary<string, int> NodeBuildingMap = new();

        public Dictionary<string, (double X, double Y)> NodeCoordinateMap
            = new();

        public Dictionary<string, string> NodeTypeMap
            = new();

        public bool IsLoaded { get; private set; }

        public GraphService(AppDbContext context, IConfiguration config)
        {
            _context = context;
            _config = config;
        }

        public async Task LoadGraphAsync()
        {
            // Already loaded
            if (IsLoaded)
                return;

            Graph.Clear();
            NodeFloorMap.Clear();
            NodeCoordinateMap.Clear();
            NodeTypeMap.Clear();

            var nodes = await _context.Nodes.ToListAsync();
            var edges = await _context.Edges.ToListAsync();

            // -----------------------------
            // Load Nodes
            // -----------------------------
            foreach (var node in nodes)
            {
                NodeFloorMap[node.NodeId] = node.FloorId;

                NodeBuildingMap[node.NodeId] = node.BuildingId;

                NodeCoordinateMap[node.NodeId] =
                    (node.X, node.Y);

                NodeTypeMap[node.NodeId] =
                    node.NodeType ?? "normal";

                if (!Graph.ContainsKey(node.NodeId))
                {
                    Graph[node.NodeId] =
                        new List<(string, double)>();
                }
            }

            // Read scale from appsettings (kept for future use)
            double scale =
                _config.GetValue<double>("IndoorMap:MetersPerPixel");

            // -----------------------------
            // Load Edges
            // -----------------------------
            foreach (var edge in edges)
            {
                if (!Graph.ContainsKey(edge.FromNode))
                    Graph[edge.FromNode] =
                        new List<(string, double)>();

                if (!Graph.ContainsKey(edge.ToNode))
                    Graph[edge.ToNode] =
                        new List<(string, double)>();

                double weight = edge.DistanceM;

                // Optional penalties
                if (edge.EdgeType == "stairs")
                    weight += 10;

                if (edge.EdgeType == "elevator")
                    weight += 2;

                Graph[edge.FromNode]
                    .Add((edge.ToNode, weight));

                Graph[edge.ToNode]
                    .Add((edge.FromNode, weight));
            }

            // Mark graph as loaded
            IsLoaded = true;

            // -----------------------------
            // Debug Information
            // -----------------------------
            Console.WriteLine("--------------------------------");
            Console.WriteLine("Indoor Graph Loaded Successfully");
            Console.WriteLine($"Indoor Nodes : {nodes.Count}");
            Console.WriteLine($"Indoor Edges : {edges.Count}");
            Console.WriteLine($"Graph Nodes  : {Graph.Count}");
            Console.WriteLine("--------------------------------");
        }
    }
}
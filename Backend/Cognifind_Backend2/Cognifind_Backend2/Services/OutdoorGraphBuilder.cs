using Cognifind_Backend2.Models.Outdoor_Navigation;

namespace Cognifind_Backend2.Services
{
    public class OutdoorGraphBuilder
    {
        private readonly AppDbContext _context;

        public OutdoorGraphBuilder(AppDbContext context)
        {
            _context = context;
        }

        public async Task BuildGraph(List<List<(double lat, double lng)>> paths)
        {
            var nodeMap = new Dictionary<string, string>();
            int counter = 1;

            foreach (var path in paths)
            {
                string previousNode = null;

                foreach (var point in path)
                {
                    var key = $"{Math.Round(point.lat, 6)}_{Math.Round(point.lng, 6)}";

                    if (!nodeMap.ContainsKey(key))
                    {
                        var nodeId = $"O{counter:0000}";

                        nodeMap[key] = nodeId;

                        _context.OutdoorNodes.Add(new OutdoorNode
                        {
                            NodeId = nodeId,
                            Latitude = point.lat,
                            Longitude = point.lng
                        });

                        counter++;
                    }

                    var currentNode = nodeMap[key];

                    if (previousNode != null)
                    {
                        var prev = _context.OutdoorNodes
                            .Local
                            .First(n => n.NodeId == previousNode);

                        double distance = Haversine(
                            prev.Latitude,
                            prev.Longitude,
                            point.lat,
                            point.lng
                        );

                        _context.OutdoorEdges.Add(new OutdoorEdge
                        {
                            FromNode = previousNode,
                            ToNode = currentNode,
                            Distance = distance
                        });
                    }

                    previousNode = currentNode;
                }
            }

            await _context.SaveChangesAsync();
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
    }
}

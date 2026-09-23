using Microsoft.EntityFrameworkCore;

public class OutdoorGraphService
{
    private readonly AppDbContext _context;

    public OutdoorGraphService(AppDbContext context)
    {
        _context = context;
    }
    //finds the closest node to the users gps 
    public async Task<OutdoorNode?> FindNearestNode(double lat, double lng)
    {
        var nodes = await _context.OutdoorNodes.ToListAsync();

        OutdoorNode? nearest = null;
        double minDistance = double.MaxValue;

        foreach (var node in nodes)
        {
            double distance = Haversine(
                lat,
                lng,
                node.Latitude,
                node.Longitude
            );

            if (distance < minDistance)
            {
                minDistance = distance;
                nearest = node;
            }
        }

        return nearest;
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
    public async Task RecalculateAllEdgeDistances()
    {
        var nodes = await _context.OutdoorNodes
            .ToDictionaryAsync(n => n.NodeId);

        var edges = await _context.OutdoorEdges.ToListAsync();

        foreach (var edge in edges)
        {
            var nodeA = nodes[edge.FromNode];
            var nodeB = nodes[edge.ToNode];

            edge.Distance = Haversine(
                nodeA.Latitude, nodeA.Longitude,
                nodeB.Latitude, nodeB.Longitude
            );
        }

        await _context.SaveChangesAsync();
    }
}
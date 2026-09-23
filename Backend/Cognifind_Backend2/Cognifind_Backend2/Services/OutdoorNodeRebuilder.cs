public class OutdoorNodeRebuilder
{
    private readonly AppDbContext _context;

    public OutdoorNodeRebuilder(AppDbContext context)
    {
        _context = context;
    }

    public async Task RebuildNodes(List<List<(double lat, double lng)>> paths)
    {
        var nodeMap = new Dictionary<string, string>();

        int counter = 1;

        foreach (var path in paths)
        {
            foreach (var point in path)
            {
                var key =
                    $"{Math.Round(point.lat, 6)}_{Math.Round(point.lng, 6)}";

                if (nodeMap.ContainsKey(key))
                    continue;

                string nodeId = $"O{counter:0000}";
                nodeMap[key] = nodeId;

                _context.OutdoorNodes.Add(new OutdoorNode
                {
                    NodeId = nodeId,
                    Latitude = point.lat,
                    Longitude = point.lng
                });

                counter++;
            }
        }

        await _context.SaveChangesAsync();
    }
}
using Cognifind_Backend2.DTOs.Indoor;

public class NavigationInstructionService
{
    private readonly IConfiguration _config;

    public NavigationInstructionService(IConfiguration config)
    {
        _config = config;
    }

    // ------------------------------------------------
    // INDOOR INSTRUCTIONS
    // ------------------------------------------------
    public Task<List<string>> GenerateIndoor(List<PathNode> path)
    {
        var instructions = new List<string>();

        if (path == null || path.Count < 2)
            return Task.FromResult(instructions);

        double scale = _config.GetValue<double>("IndoorMap:MetersPerPixel");

        for (int i = 0; i < path.Count - 1; i++)
        {
            var current = path[i];
            var next = path[i + 1];

            if (current.Floor != next.Floor)
            {
                if (current.Type == "stairs")
                    instructions.Add($"Take stairs to floor {next.Floor}");
                else if (current.Type == "elevator")
                    instructions.Add($"Take elevator to floor {next.Floor}");
                else
                    instructions.Add($"Go to floor {next.Floor}");

                continue;
            }

            double dx = next.X - current.X;
            double dy = next.Y - current.Y;

            double pixelDistance = Math.Sqrt(dx * dx + dy * dy);
            double distance = pixelDistance * scale;

            if (distance < 1)
                continue;

            string direction;

            if (Math.Abs(dx) > Math.Abs(dy))
                direction = dx > 0 ? "east" : "west";
            else
                direction = dy > 0 ? "south" : "north";

            instructions.Add($"Go {direction} for {Math.Round(distance, 1)} meters");
        }

        instructions.Add("Arrived at destination");

        return Task.FromResult(instructions);
    }

    // ------------------------------------------------
    // OUTDOOR INSTRUCTIONS
    // ------------------------------------------------
    public List<string> GenerateOutdoor(
    List<string> path,
    Dictionary<string, (double lat, double lng)> coords)
    {
        var instructions = new List<string>();

        if (path == null || path.Count < 2)
            return instructions;

        for (int i = 0; i < path.Count - 1; i++)
        {
            var current = coords[path[i]];
            var next = coords[path[i + 1]];

            double distance = Haversine(
                current.lat,
                current.lng,
                next.lat,
                next.lng);

            double dx = next.lng - current.lng;
            double dy = next.lat - current.lat;

            string direction;

            if (Math.Abs(dx) > Math.Abs(dy))
                direction = dx > 0 ? "east" : "west";
            else
                direction = dy > 0 ? "north" : "south";

            instructions.Add(
                $"Go {direction} for {Math.Round(distance, 1)} meters");
        }

        instructions.Add("Arrived at destination");

        return instructions;
    }
    private double Haversine(
    double lat1,
    double lon1,
    double lat2,
    double lon2)
    {
        double R = 6371000; // meters

        double dLat = ToRad(lat2 - lat1);
        double dLon = ToRad(lon2 - lon1);

        lat1 = ToRad(lat1);
        lat2 = ToRad(lat2);

        double a =
            Math.Sin(dLat / 2) * Math.Sin(dLat / 2) +
            Math.Cos(lat1) * Math.Cos(lat2) *
            Math.Sin(dLon / 2) * Math.Sin(dLon / 2);

        double c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));

        return R * c;
    }

    private double ToRad(double val)
    {
        return val * Math.PI / 180;
    }
}
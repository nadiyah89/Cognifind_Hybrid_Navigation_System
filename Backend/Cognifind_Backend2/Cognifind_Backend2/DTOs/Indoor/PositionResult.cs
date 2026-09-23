public class PositionResult
{
    // Position used for drawing blue dot
    public double X { get; set; }

    public double Y { get; set; }

    // Routing information
    public string NearestNode { get; set; } = string.Empty;

    public int Floor { get; set; }

    public double Confidence { get; set; }

    public double Heading { get; set; }

    public bool IsIndoor { get; set; }

    // Optional debug information
    public double? SnappedX { get; set; }

    public double? SnappedY { get; set; }
}
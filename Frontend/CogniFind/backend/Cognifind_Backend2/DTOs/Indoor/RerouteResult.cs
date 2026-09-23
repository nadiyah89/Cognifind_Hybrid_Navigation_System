public class RerouteResult
{
    public bool IsOffRoute { get; set; }

    public bool ShouldReroute { get; set; }

    public string CurrentNode { get; set; } = string.Empty;

    public string ExpectedNode { get; set; } = string.Empty;

    public string? UpcomingNode { get; set; }

    public string Message { get; set; } = string.Empty;
}
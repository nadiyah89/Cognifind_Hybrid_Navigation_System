public class NavigationSessionResult
{
    public PositionResult Position { get; set; } = new();

    public NavigationProgress Progress { get; set; } = new();

    public RerouteResult Reroute { get; set; } = new();
}
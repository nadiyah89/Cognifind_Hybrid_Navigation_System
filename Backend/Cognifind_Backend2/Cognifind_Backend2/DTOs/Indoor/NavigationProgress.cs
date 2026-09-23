public class NavigationProgress
{
    // Current graph position
    public string CurrentNode { get; set; } = string.Empty;

    // Next waypoint
    public string NextNode { get; set; } = string.Empty;

    // One more waypoint ahead
    public string? UpcomingNode { get; set; }

    // Current position inside the route
    public int CurrentStepIndex { get; set; }

    // Number of nodes in the route
    public int TotalSteps { get; set; }

    // Remaining nodes
    public int RemainingSteps { get; set; }

    // Remaining distance
    public double RemainingDistance { get; set; }

    // Navigation instruction
    public string Instruction { get; set; } = string.Empty;

    // Navigation status
    public bool DestinationReached { get; set; }
}
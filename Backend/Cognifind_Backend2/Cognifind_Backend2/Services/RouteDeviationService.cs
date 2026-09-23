public class RouteDeviationService
{
    /// <summary>
    /// Checks whether the user has deviated from the expected route.
    /// </summary>
    public RerouteResult CheckDeviation(
        NavigationProgress progress)
    {
        // Destination already reached
        if (progress.DestinationReached)
        {
            return new RerouteResult
            {
                IsOffRoute = false,
                ShouldReroute = false,
                CurrentNode = progress.CurrentNode,
                ExpectedNode = progress.CurrentNode,
                UpcomingNode = null,
                Message = "Destination reached."
            };
        }

        // If we have no next node something is wrong
        if (string.IsNullOrWhiteSpace(progress.NextNode))
        {
            return new RerouteResult
            {
                IsOffRoute = true,
                ShouldReroute = true,
                CurrentNode = progress.CurrentNode,
                ExpectedNode = string.Empty,
                UpcomingNode = null,
                Message = "Navigation state is invalid."
            };
        }

        // User is still following the route
        return new RerouteResult
        {
            IsOffRoute = false,
            ShouldReroute = false,
            CurrentNode = progress.CurrentNode,
            ExpectedNode = progress.NextNode,
            UpcomingNode = progress.UpcomingNode,
            Message = "Continue on current route."
        };
    }
}
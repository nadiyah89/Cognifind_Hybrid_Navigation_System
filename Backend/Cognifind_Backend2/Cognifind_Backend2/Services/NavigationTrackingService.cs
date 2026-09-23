using Cognifind_Backend2.DTOs.Indoor;

namespace Cognifind_Backend2.Services
{
    public class NavigationTrackingService
    {
        private readonly NavigationInstructionService _instructionService;

        public NavigationTrackingService(
            NavigationInstructionService instructionService)
        {
            _instructionService = instructionService;
        }

        public async Task<NavigationProgress> TrackProgressAsync(
            NavigationUpdateRequest request)
        {
            // ------------------------------------------
            // Validate Request
            // ------------------------------------------
            if (request.Route == null || request.Route.Count == 0)
            {
                throw new Exception("Route is empty.");
            }

            // ------------------------------------------
            // Find Current Node Index
            // ------------------------------------------
            int currentIndex = request.Route.FindIndex(
                n => n.NodeId == request.CurrentNode);

            if (currentIndex == -1)
            {
                throw new Exception(
                    $"Current node '{request.CurrentNode}' is not part of the route.");
            }

            // ------------------------------------------
            // Destination Reached
            // ------------------------------------------
            bool destinationReached =
                currentIndex == request.Route.Count - 1;

            // ------------------------------------------
            // Next Node
            // ------------------------------------------

            string nextNode = destinationReached
                ? request.CurrentNode
                : request.Route[currentIndex + 1].NodeId;

            // ------------------------------------------
            // Upcoming Node
            // ------------------------------------------

            string? upcomingNode = null;

            if (!destinationReached &&
                currentIndex + 2 < request.Route.Count)
            {
                upcomingNode = request.Route[currentIndex + 2].NodeId;
            }

            // ------------------------------------------
            // Remaining Distance
            // ------------------------------------------
            double remainingDistance = 0;

            for (int i = currentIndex; i < request.Route.Count - 1; i++)
            {
                double dx =
                    request.Route[i + 1].X - request.Route[i].X;

                double dy =
                    request.Route[i + 1].Y - request.Route[i].Y;

                remainingDistance += Math.Sqrt(
                    dx * dx + dy * dy);
            }

            // ------------------------------------------
            // Current Remaining Path
            // ------------------------------------------
            var remainingPath =
                request.Route
                    .Skip(currentIndex)
                    .ToList();

            // ------------------------------------------
            // Navigation Instruction
            // ------------------------------------------
            string instruction = "Destination Reached";

            if (!destinationReached)
            {
                var instructions =
                    await _instructionService.GenerateIndoor(
                        remainingPath);

                if (instructions.Any())
                {
                    instruction = instructions.First();
                }
                else
                {
                    instruction = "Continue Straight";
                }
            }

            // ------------------------------------------
            // Return Progress
            // ------------------------------------------
            return new NavigationProgress
            {
                CurrentNode = request.CurrentNode,

                NextNode = nextNode,

                UpcomingNode = upcomingNode,

                CurrentStepIndex = currentIndex,

                TotalSteps = request.Route.Count,

                RemainingSteps = request.Route.Count - currentIndex - 1,

                DestinationReached = destinationReached,

                RemainingDistance = Math.Round(remainingDistance, 2),

                Instruction = instruction
            };
        }
    }
}
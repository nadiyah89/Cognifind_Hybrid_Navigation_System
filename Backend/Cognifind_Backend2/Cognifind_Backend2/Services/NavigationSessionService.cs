using Cognifind_Backend2.Services;

public class NavigationSessionService
{
    private readonly LocalizationService _localization;
    private readonly NavigationTrackingService _tracking;
    private readonly RouteDeviationService _deviation;

    public NavigationSessionService(
        LocalizationService localization,
        NavigationTrackingService tracking,
        RouteDeviationService deviation)
    {
        _localization = localization;
        _tracking = tracking;
        _deviation = deviation;
    }

    public async Task<NavigationSessionResult> UpdateAsync(
        NavigationSessionRequest request)
    {
        var position =
            await _localization.EstimatePositionAsync(
                request.Location);

        request.Navigation.CurrentNode =
            position.NearestNode;

        var progress =
            await _tracking.TrackProgressAsync(
                request.Navigation);

        var reroute =
            _deviation.CheckDeviation(progress);

        return new NavigationSessionResult
        {
            Position = position,
            Progress = progress,
            Reroute = reroute
        };
    }
}
using Cognifind_Backend.Api.Models;

namespace Cognifind.Api.Services;

public interface IGoogleDirectionsService
{
    Task<RouteResponse> GetWalkingRouteAsync(
        double srcLat, double srcLng,
        double dstLat, double dstLng,
        CancellationToken ct = default);
}

namespace Cognifind_Backend.Api.Models;

public class RouteResponse
{

    public List<LatLngDto> route { get; set; } = new();
    public int distance { get; set; } // in meters
    public int duration { get; set; } // in seconds
    public string summary { get; set; } // route summary
    public string mode { get; set; } // walking, driving, etc.

}

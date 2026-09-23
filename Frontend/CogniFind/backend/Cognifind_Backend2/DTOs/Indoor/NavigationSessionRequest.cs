public class NavigationSessionRequest
{
    public LocationRequest Location { get; set; } = new();

    public NavigationUpdateRequest Navigation { get; set; } = new();
}
using System.ComponentModel.DataAnnotations;

public class LocationRequest
{
    public int? BuildingId { get; set; }

    [Required]
    public GpsDto Gps { get; set; } = new();

    public double Heading { get; set; }

    public List<BeaconReadingDto> Beacons { get; set; } = new();

    public List<string>? RouteNodeIds { get; set; }
}
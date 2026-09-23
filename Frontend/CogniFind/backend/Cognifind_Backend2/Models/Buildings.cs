using System.ComponentModel.DataAnnotations;

public class Building
{
    [Key]
    public int BuildingId { get; set; }

    public string BuildingName { get; set; }

    public double Latitude { get; set; }
    public double Longitude { get; set; }


}

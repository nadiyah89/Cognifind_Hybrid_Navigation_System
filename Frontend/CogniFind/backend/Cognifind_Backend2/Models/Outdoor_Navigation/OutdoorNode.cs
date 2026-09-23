using System.ComponentModel.DataAnnotations;

public class OutdoorNode
{
    [Key]
    public string NodeId { get; set; }

    public double Latitude { get; set; }

    public double Longitude { get; set; }
}
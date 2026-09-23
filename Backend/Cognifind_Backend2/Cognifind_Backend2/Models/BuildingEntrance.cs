using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

[Table("building_entrances")]
public class BuildingEntrance
{
    [Key]
    public int Id { get; set; }

    public int  BuildingId { get; set; }

    // Outdoor graph node
    public string OutdoorNodeId { get; set; }

    // Indoor graph node
    public string IndoorNodeId { get; set; }

    public double Latitude { get; set; }
    public double Longitude { get; set; }


    [ForeignKey("BuildingId")]
    public Building Building { get; set; }
}
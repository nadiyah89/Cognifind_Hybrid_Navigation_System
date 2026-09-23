using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

[Table("floors")]
public class Floor
{
    [Key]
    [Column("floor_id")]
    public int FloorId { get; set; }

    [Column("floor_name")]
    public string FloorName { get; set; }

    [Column("level_number")]
    public int LevelNumber { get; set; }

    [Column("building_id")]
    public int BuildingId { get; set; }

    [ForeignKey("BuildingId")]
    public Building Building { get; set; }
}
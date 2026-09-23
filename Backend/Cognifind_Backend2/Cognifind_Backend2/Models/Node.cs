using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

[Table("nodes")]
public class Node
{
    [Key]
    [Column("node_id")]
    public string NodeId { get; set; }

    [Column("floor_id")]
    public int FloorId { get; set; }

    [Column("x")]
    public double X { get; set; }

    [Column("y")]
    public double Y { get; set; }

    [Column("node_type")]
    public string NodeType { get; set; }

    [ForeignKey("FloorId")]
    public Floor Floor { get; set; }

    [Column("building_id")]
    public int BuildingId { get; set; }

    [ForeignKey("BuildingId")]
    public Building Building { get; set; }
}
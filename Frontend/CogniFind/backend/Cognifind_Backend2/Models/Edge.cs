using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

[Table("edges")]
public class Edge
{
    [Key]
    public int Id { get; set; }  

    [Column("from_node")]
    public string FromNode { get; set; }

    [Column("to_node")]
    public string ToNode { get; set; }

    [Column("distance_m")]
    public double DistanceM { get; set; }

    [Column("edge_type")]
    public string EdgeType { get; set; }
}

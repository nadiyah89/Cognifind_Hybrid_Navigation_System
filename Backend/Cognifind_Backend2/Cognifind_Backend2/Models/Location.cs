using Cognifind_Backend2.Constants;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Cognifind_Backend2.Models
{
    [Table("locations")]
    public class Location
    {
        [Key]
        public int Id { get; set; }

        [Column("name")]
        public string Name { get; set; }

        [Column("node_id")]
        public string NodeId { get; set; }

        [Column("type")]
        public LocationType Type { get; set; }

        [ForeignKey("NodeId")]
        public Node Node { get; set; }
    }
}
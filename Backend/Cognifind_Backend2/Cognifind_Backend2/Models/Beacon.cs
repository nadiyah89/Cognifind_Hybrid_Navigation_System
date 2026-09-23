using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Cognifind_Backend2.Models
{
    [Table("beacons")]
    public class Beacon
    {
        [Key]
        public string BeaconId { get; set; } = string.Empty;

        public double X { get; set; }

        public double Y { get; set; }

        public int FloorId { get; set; }

        [MaxLength(50)]
        public string NearestNodeId { get; set; } = string.Empty;

        public int BuildingId { get; set; }

        public bool IsActive { get; set; } = true;

        // Navigation Properties
        public virtual Floor? Floor { get; set; }

        public virtual Building? Building { get; set; }
    }
}
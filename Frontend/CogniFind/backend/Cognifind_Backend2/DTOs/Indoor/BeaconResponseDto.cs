namespace Cognifind_Backend2.DTOs
{
    public class BeaconResponseDto
    {
        public string BeaconId { get; set; } = string.Empty;
        public double X { get; set; }
        public double Y { get; set; }
        public int Floor { get; set; }
        public string NearestNode { get; set; } = string.Empty;
    }
}
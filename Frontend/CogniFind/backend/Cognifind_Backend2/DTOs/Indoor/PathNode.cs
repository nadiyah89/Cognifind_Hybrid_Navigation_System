namespace Cognifind_Backend2.DTOs.Indoor
{
    public class PathNode
    {
        public required string NodeId { get; set; } = string.Empty;
        public int Floor { get; set; }
        public double X { get; set; }
        public double Y { get; set; }
        public required string Type { get; set; } = string.Empty;
    }
}

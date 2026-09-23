namespace Cognifind_Backend2.Models.Outdoor_Navigation
{
    public class OutdoorEdge
    {
        public int Id { get; set; }

        public string FromNode { get; set; } = string.Empty;

        public string ToNode { get; set; } = string.Empty;

        public double Distance { get; set; }
    }
}

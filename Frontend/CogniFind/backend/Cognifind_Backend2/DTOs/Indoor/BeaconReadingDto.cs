using System.ComponentModel.DataAnnotations;

public class BeaconReadingDto
{
    [Required]
    public string Id { get; set; } = string.Empty;

    public int Rssi { get; set; }
}
namespace Cognifind.Api.Dtos.Admin
{
    public class UserSummaryDto
    {
        public int Id { get; set; }
        public string? Name { get; set; }
        public string Email { get; set; } = string.Empty;
        public string Role { get; set; } = string.Empty;
        public DateTime CreatedAt { get; set; }
    }
}

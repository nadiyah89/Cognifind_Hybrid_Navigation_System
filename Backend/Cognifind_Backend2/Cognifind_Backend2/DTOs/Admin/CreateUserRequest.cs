namespace Cognifind.Api.Dtos.Admin
{
    public class CreateUserRequest
    {
        public string? Name { get; set; }
        public string Email { get; set; } = string.Empty;
        public string Role { get; set; } = "User";  // "User" or "Admin"
        public string Password { get; set; } = string.Empty;
    }
}



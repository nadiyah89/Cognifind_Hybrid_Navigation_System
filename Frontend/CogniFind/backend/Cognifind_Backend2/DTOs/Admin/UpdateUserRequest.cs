namespace Cognifind.Api.Dtos.Admin
{
    public class UpdateUserRequest
    {
        public string? Name { get; set; }
        public string? Email { get; set; }
        public string? Role { get; set; }          // "User" or "Admin"
        public string? Password { get; set; }      // optional password reset
    }
}

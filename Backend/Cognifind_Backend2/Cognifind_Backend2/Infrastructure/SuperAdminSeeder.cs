
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Cognifind_Backend
{
    public static class SuperAdminSeeder
    {
        public static async Task SeedSuperAdminAsync(IServiceProvider services, IConfiguration config)
        {
            using var scope = services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            if (await db.Users.AnyAsync(u => u.Role == UserRole.SuperAdmin))
                return;

            var section = config.GetSection("SuperAdmin");
            var email = section["Email"];
            var password = section["Password"];
            var name = section["Name"] ?? "Super Admin";

            if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(password))
                return;

            var user = new User
            {
                Name = name,
                Email = email.Trim(),
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(password),
                Role = UserRole.SuperAdmin,
                CreatedAt = DateTime.UtcNow
            };

            db.Users.Add(user);
            await db.SaveChangesAsync();
        }
    }
}

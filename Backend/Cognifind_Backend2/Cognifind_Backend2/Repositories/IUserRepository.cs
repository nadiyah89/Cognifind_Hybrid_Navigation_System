

namespace Cognifind_Backend.Api.Repositories
{
    public interface IUserRepository
    {
        Task<User?> GetByEmailAsync(string email);
        Task<User?> GetByIdAsync(int id);

        Task<int> CreateAsync(User user);

        Task<List<User>> GetAllAsync();
        Task<List<User>> GetByRoleAsync(UserRole role);

        Task<User> AddAsync(User user);

        Task UpdateAsync(User user);
        Task DeleteAsync(User user);

        Task<bool> EmailExistsAsync(string email, int? excludeUserId = null);
    }
}

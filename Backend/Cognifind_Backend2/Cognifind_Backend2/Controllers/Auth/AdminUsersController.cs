using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Cognifind.Api.Dtos.Admin;
using Cognifind_Backend.Api.Repositories;


namespace Cognifind_Backend.Api.Controllers
{
    [ApiController]
    [Route("api/admin/users")]
    public class AdminUsersController : ControllerBase
    {
        private readonly IUserRepository _userRepo;

        public AdminUsersController(IUserRepository userRepo)
        {
            _userRepo = userRepo;
        }

        [Authorize(Roles = "Admin,SuperAdmin")]
        [HttpGet]
        public async Task<IActionResult> GetUsers([FromQuery] string? role = null)
        {
            var currentRole = GetCurrentUserRole();

            if (currentRole == UserRole.Admin)
            {
                var users = await _userRepo.GetByRoleAsync(UserRole.User);
                return Ok(users.Select(ToSummaryDto));
            }

            if (currentRole == UserRole.SuperAdmin)
            {
                List<User> users;

                if (!string.IsNullOrWhiteSpace(role) &&
                    Enum.TryParse<UserRole>(role, true, out var parsedRole) &&
                    (parsedRole == UserRole.User || parsedRole == UserRole.Admin))
                {
                    users = await _userRepo.GetByRoleAsync(parsedRole);
                }
                else
                {
                    var all = await _userRepo.GetAllAsync();
                    users = all
                        .Where(u => u.Role == UserRole.User || u.Role == UserRole.Admin)
                        .ToList();
                }

                return Ok(users.Select(ToSummaryDto));
            }

            return Forbid();
        }

        [Authorize(Roles = "Admin,SuperAdmin")]
        [HttpGet("{id:int}")]
        public async Task<IActionResult> GetUserById(int id)
        {
            var currentRole = GetCurrentUserRole();

            var user = await _userRepo.GetByIdAsync(id);
            if (user == null)
                return NotFound();

            if (user.Role == UserRole.SuperAdmin)
                return Forbid();

            if (currentRole == UserRole.Admin && user.Role != UserRole.User)
                return Forbid();

            return Ok(ToSummaryDto(user));
        }

        [Authorize(Roles = "Admin,SuperAdmin")]
        [HttpPost]
        public async Task<IActionResult> CreateUser([FromBody] CreateUserRequest request)
        {
            var currentRole = GetCurrentUserRole();

            if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
                return BadRequest(new { message = "Email and password are required." });

            UserRole targetRole;

            if (currentRole == UserRole.Admin)
            {
                targetRole = UserRole.User;
            }
            else if (currentRole == UserRole.SuperAdmin)
            {
                if (!Enum.TryParse<UserRole>(request.Role, true, out targetRole))
                    return BadRequest(new { message = "Invalid role. Allowed: User, Admin." });

                if (targetRole == UserRole.SuperAdmin)
                    return BadRequest(new { message = "Cannot create SuperAdmin via this endpoint." });
            }
            else
            {
                return Forbid();
            }

            var emailExists = await _userRepo.EmailExistsAsync(request.Email, null);
            if (emailExists)
                return Conflict(new { message = "Email is already registered." });

            var user = new User
            {
                Name = request.Name?.Trim(),
                Email = request.Email.Trim(),
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
                Role = targetRole,
                CreatedAt = DateTime.UtcNow
            };

            user = await _userRepo.AddAsync(user);

            var dto = ToSummaryDto(user);
            return CreatedAtAction(nameof(GetUserById), new { id = dto.Id }, dto);
        }

        [Authorize(Roles = "Admin,SuperAdmin")]
        [HttpPut("{id:int}")]
        public async Task<IActionResult> UpdateUser(int id, [FromBody] UpdateUserRequest request)
        {
            var currentRole = GetCurrentUserRole();

            var user = await _userRepo.GetByIdAsync(id);
            if (user == null)
                return NotFound();

            if (user.Role == UserRole.SuperAdmin)
                return BadRequest(new { message = "Cannot modify SuperAdmin via this endpoint." });

            if (currentRole == UserRole.Admin && user.Role != UserRole.User)
                return Forbid();

            if (!string.IsNullOrWhiteSpace(request.Email) && request.Email.Trim() != user.Email)
            {
                var exists = await _userRepo.EmailExistsAsync(request.Email, id);
                if (exists)
                    return Conflict(new { message = "Email is already in use by another user." });

                user.Email = request.Email.Trim();
            }

            if (!string.IsNullOrWhiteSpace(request.Name))
                user.Name = request.Name.Trim();

            if (!string.IsNullOrWhiteSpace(request.Role))
            {
                if (!Enum.TryParse<UserRole>(request.Role, true, out var newRole))
                    return BadRequest(new { message = "Invalid role. Allowed: User, Admin." });

                if (newRole == UserRole.SuperAdmin)
                    return BadRequest(new { message = "Cannot set role to SuperAdmin via this endpoint." });

                if (currentRole == UserRole.Admin)
                {
                    if (newRole != user.Role)
                        return Forbid();
                }
                else if (currentRole == UserRole.SuperAdmin)
                {
                    user.Role = newRole;
                }
            }

            if (!string.IsNullOrWhiteSpace(request.Password))
                user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);

            await _userRepo.UpdateAsync(user);

            return Ok(ToSummaryDto(user));
        }

        [Authorize(Roles = "Admin,SuperAdmin")]
        [HttpDelete("{id:int}")]
        public async Task<IActionResult> DeleteUser(int id)
        {
            var currentRole = GetCurrentUserRole();
            var currentUserId = GetCurrentUserId();

            var user = await _userRepo.GetByIdAsync(id);
            if (user == null)
                return NotFound();

            if (user.Role == UserRole.SuperAdmin)
                return BadRequest(new { message = "Cannot delete a SuperAdmin via this endpoint." });

            if (currentUserId.HasValue && currentUserId.Value == user.Id)
                return BadRequest(new { message = "You cannot delete your own account." });

            if (currentRole == UserRole.Admin && user.Role != UserRole.User)
                return Forbid();

            await _userRepo.DeleteAsync(user);

            return NoContent();
        }

        private UserRole GetCurrentUserRole()
        {
            var roleString = User.FindFirst(ClaimTypes.Role)?.Value;
            if (string.IsNullOrWhiteSpace(roleString) || !Enum.TryParse<UserRole>(roleString, out var role))
                throw new UnauthorizedAccessException("Invalid or missing role claim.");

            return role;
        }

        private int? GetCurrentUserId()
        {
            var idClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            return int.TryParse(idClaim, out var id) ? id : null;
        }

        private static UserSummaryDto ToSummaryDto(User u) =>
            new UserSummaryDto
            {
                Id = u.Id,
                Name = u.Name,
                Email = u.Email,
                Role = u.Role.ToString(),
                CreatedAt = u.CreatedAt
            };

        // GET: api/admin/users/all
        // SuperAdmin: get all Users + Admins, optionally filtered by role
        [Authorize(Roles = "SuperAdmin")]
        [HttpGet("all")]
        public async Task<IActionResult> GetAllUsersAndAdminsForSuperAdmin([FromQuery] string? role = "All")
        {
            List<User> users;

            var normalized = role?.Trim().ToLowerInvariant();

            if (normalized == "user")
            {
                users = await _userRepo.GetByRoleAsync(UserRole.User);
            }
            else if (normalized == "admin")
            {
                users = await _userRepo.GetByRoleAsync(UserRole.Admin);
            }
            else
            {
                // "all" or anything else -> return Users + Admins
                var all = await _userRepo.GetAllAsync();
                users = all
                    .Where(u => u.Role == UserRole.User || u.Role == UserRole.Admin)
                    .ToList();
            }

            var result = users
                .OrderBy(u => u.Role)
                .ThenBy(u => u.Name)
                .Select(u => new UserSummaryDto
                {
                    Id = u.Id,
                    Name = u.Name,
                    Email = u.Email,
                    Role = u.Role.ToString(),
                    CreatedAt = u.CreatedAt
                })
                .ToList();

            return Ok(result);
        }


    }


    }  
   
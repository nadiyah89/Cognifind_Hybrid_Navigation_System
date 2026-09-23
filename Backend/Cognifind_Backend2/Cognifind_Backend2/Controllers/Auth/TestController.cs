using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Cognifind.Api.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class RoleTestController : ControllerBase
    {
        [HttpGet("public")]
        public IActionResult Public()
        {
            return Ok("Public endpoint: no authentication required.");
        }

        [Authorize]
        [HttpGet("user")]
        public IActionResult UserAccess()
        {
            var name = User.Identity?.Name ?? "(no name)";
            var role = User.FindFirst(ClaimTypes.Role)?.Value ?? "(no role)";
            return Ok($"User endpoint: you are {name} with role {role}.");
        }

        [Authorize(Roles = "Admin,SuperAdmin")]
        [HttpGet("admin")]
        public IActionResult AdminAccess()
        {
            return Ok("Admin endpoint: only Admin and SuperAdmin can access this.");
        }

        [Authorize(Roles = "SuperAdmin")]
        [HttpGet("superadmin")]
        public IActionResult SuperAdminAccess()
        {
            return Ok("SuperAdmin endpoint: only SuperAdmin can access this.");
        }

        [Authorize]
        [HttpGet("me")]
        public IActionResult Me()
        {
            return Ok(new
            {
                UserId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value,
                Name = User.Identity?.Name,
                Email = User.FindFirst(ClaimTypes.Email)?.Value,
                Role = User.FindFirst(ClaimTypes.Role)?.Value
            });
        }
    }
}

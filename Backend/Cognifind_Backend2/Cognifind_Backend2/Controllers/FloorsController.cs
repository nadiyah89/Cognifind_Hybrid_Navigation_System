using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

[ApiController]
[Route("api/floors")]
public class FloorsController : ControllerBase
{
    private readonly AppDbContext _context;

    public FloorsController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> Get()
        => Ok(await _context.Floors.ToListAsync());
}

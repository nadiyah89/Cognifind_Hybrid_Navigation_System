using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

[ApiController]
[Route("api/edges")]
public class EdgesController : ControllerBase
{
    private readonly AppDbContext _context;

    public EdgesController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> Get()
        => Ok(await _context.Edges.ToListAsync());
}

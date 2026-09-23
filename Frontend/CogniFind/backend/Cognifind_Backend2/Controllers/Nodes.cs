using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

[ApiController]
[Route("api/nodes")]
public class NodesController : ControllerBase
{
    private readonly AppDbContext _context;

    public NodesController(AppDbContext context)
    {
        _context = context;
    }

    [HttpGet("floor/{floorId}")]
    public async Task<IActionResult> GetByFloor(int floorId)
        => Ok(await _context.Nodes
            .Where(n => n.FloorId == floorId)
            .ToListAsync());
}

using Cognifind_Backend2.Services;
using Cognifind_Backend2.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

[ApiController]
[Route("api/route")]
public class RouteController : ControllerBase
{
    private readonly GraphService _graph;
    private readonly DijkstraService _dijkstra;
    private readonly AppDbContext _context;

    public RouteController(
        GraphService graph,
        DijkstraService dijkstra,
        AppDbContext context)
    {
        _graph = graph;
        _dijkstra = dijkstra;
        _context = context;
    }

    // ==========================================
    // 1️⃣ OLD API (NodeId → NodeId)
    // ==========================================

    [HttpGet("nodes")]
    public async Task<IActionResult> GetByNodes(string from, string to)
    {
        await _graph.LoadGraphAsync();

        if (!_graph.Graph.ContainsKey(from) || !_graph.Graph.ContainsKey(to))
            return BadRequest("Invalid nodes");

        var (path, distance) = _dijkstra.FindPath(from, to);

        return Ok(new
        {
            sourceNode = from,
            destinationNode = to,
            path,
            distance
        });
    }


    // ==========================================
    // 2️⃣ NEW API (Location Name → Location Name)
    // ==========================================

    [HttpGet("locations")]
    public async Task<IActionResult> GetByLocationNames(string from, string to)
    {
        await _graph.LoadGraphAsync();

        var sourceLocation = await _context.Locations
            .FirstOrDefaultAsync(l => l.Name == from);

        var destinationLocation = await _context.Locations
            .FirstOrDefaultAsync(l => l.Name == to);

        if (sourceLocation == null || destinationLocation == null)
            return BadRequest("Location not found");

        var fromNode = sourceLocation.NodeId;
        var toNode = destinationLocation.NodeId;

        if (!_graph.Graph.ContainsKey(fromNode) || !_graph.Graph.ContainsKey(toNode))
            return BadRequest("Invalid nodes");

        var (path, distance) = _dijkstra.FindPath(fromNode, toNode);

        return Ok(new
        {
            source = from,
            destination = to,
            sourceNode = fromNode,
            destinationNode = toNode,
            path,
            distance
        });
    }
}
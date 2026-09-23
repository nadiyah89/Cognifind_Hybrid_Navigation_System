using Cognifind_Backend2.Services;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

[ApiController]
[Route("api/test-outdoor")]
public class TestOutdoorController : ControllerBase
{
    private readonly OutdoorGraphService _graph;
    private readonly OutdoorRoutingService _router;
    private readonly OutdoorGraphLoader _loader;
    private readonly AppDbContext _context;
    public TestOutdoorController(
      AppDbContext context,
      OutdoorGraphService graph,
      OutdoorRoutingService router,
      OutdoorGraphLoader loader)
    {
        _context = context;
        _graph = graph;
        _router = router;
        _loader = loader;
    }

    // Find nearest node from coordinates
    [HttpGet("nearest-node")]
    public async Task<IActionResult> Test(double lat, double lng)
    {
        var node = await _graph.FindNearestNode(lat, lng);

        if (node == null)
            return NotFound();

        return Ok(new
        {
            nodeId = node.NodeId,
            latitude = node.Latitude,
            longitude = node.Longitude
        });
    }

    [HttpGet("path")]
    public async Task<IActionResult> Get(string startNode, string endNode)
    {
        await _loader.LoadGraphAsync();

        var path = _router.FindPath(startNode, endNode);

        if (path.Count == 0)
            return NotFound("No path found");

        var result = path.Select(nodeId =>
        {
            var coord = _loader.NodeCoords[nodeId];

            return new
            {
                nodeId = nodeId,
                latitude = coord.lat,
                longitude = coord.lng
            };
        });

        return Ok(result);
    }

    [HttpGet("debug")]
    public async Task<IActionResult> Debug()
    {
        await _loader.LoadGraphAsync();

        return Ok(new
        {
            nodes = _loader.NodeCoords.Count,
            edges = _loader.Graph.Count
        });
    }

    [HttpGet("check-node")]
    public async Task<IActionResult> CheckNode(string id)
    {
        await _loader.LoadGraphAsync();

        bool exists = _loader.Graph.ContainsKey(id);

        return Ok(new { id, exists });
    }

    [HttpGet("graph-info")]
    public async Task<IActionResult> GraphInfo()
    {
        await _loader.LoadGraphAsync();

        return Ok(new
        {
            totalNodes = _loader.Graph.Count,
            totalEdges = _loader.Graph.Sum(x => x.Value.Count)
        });
    }

    [HttpGet("route")]
    public async Task<IActionResult> GetRoute(
        double startLat,
        double startLng,
        double endLat,
        double endLng)
    {
        await _loader.LoadGraphAsync();

        // find nearest nodes
        var startNode = await _graph.FindNearestNode(startLat, startLng);
        var endNode = await _graph.FindNearestNode(endLat, endLng);

        if (startNode == null || endNode == null)
            return NotFound("Could not find nearest nodes");

        // run A*
        var path = _router.FindPath(startNode.NodeId, endNode.NodeId);

        if (path.Count == 0)
            return NotFound("No path found");

        var result = path.Select(nodeId =>
        {
            var coord = _loader.NodeCoords[nodeId];

            return new
            {
                nodeId = nodeId,
                latitude = coord.lat,
                longitude = coord.lng
            };
        });

        return Ok(new
        {
            startNode = startNode.NodeId,
            endNode = endNode.NodeId,
            path = result
        });
    }

    // Export entire graph to KML for Google Earth debugging
    [HttpGet("export-graph")]
    public async Task<IActionResult> ExportGraph()
    {
        await _loader.LoadGraphAsync();

        var kml = new System.Text.StringBuilder();

        kml.AppendLine("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
        kml.AppendLine("<kml xmlns=\"http://www.opengis.net/kml/2.2\">");
        kml.AppendLine("<Document>");

        foreach (var node in _loader.NodeCoords)
        {
            var id = node.Key;
            var lat = node.Value.lat;
            var lng = node.Value.lng;

            kml.AppendLine($@"
            <Placemark>
                <name>{id}</name>
                <Point>
                    <coordinates>{lng},{lat},0</coordinates>
                </Point>
            </Placemark>");
        }

        kml.AppendLine("</Document>");
        kml.AppendLine("</kml>");

        return File(
            System.Text.Encoding.UTF8.GetBytes(kml.ToString()),
            "application/vnd.google-earth.kml+xml",
            "graph.kml");
    }
    [HttpGet("recalculate-distances")]
    public async Task<IActionResult> RecalculateDistances()
    {
        await _graph.RecalculateAllEdgeDistances();
        return Ok("Distances updated successfully");
    }
    [HttpGet("rebuild-nodes")]
    public async Task<IActionResult> RebuildNodes()
    {
        var parser = new KmlParserService();

        var filePath = Path.Combine(
            Directory.GetCurrentDirectory(),
            "Resources",
            "campus_paths.kml");

        var paths = parser.Parse(filePath);
        var rebuilder = new OutdoorNodeRebuilder(_context);

        await rebuilder.RebuildNodes(paths);

        return Ok("Nodes rebuilt");
    }
}
using Cognifind_Backend2.Services;
using Cognifind_Backend2.DTOs.Indoor;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

[ApiController]
[Route("api/route")]
public class HybridRouteController : ControllerBase
{
    private readonly AppDbContext _context;

    private readonly OutdoorGraphLoader _loader;
    private readonly OutdoorGraphService _outdoorGraph;
    private readonly OutdoorRoutingService _router;

    private readonly GraphService _indoorGraph;
    private readonly DijkstraService _dijkstra;

    private readonly NavigationInstructionService _instructionService;

    public HybridRouteController(
        AppDbContext context,
        OutdoorGraphLoader loader,
        OutdoorGraphService outdoorGraph,
        OutdoorRoutingService router,
        GraphService indoorGraph,
        DijkstraService dijkstra,
        NavigationInstructionService instructionService)
    {
        _context = context;
        _loader = loader;
        _outdoorGraph = outdoorGraph;
        _router = router;

        _indoorGraph = indoorGraph;
        _dijkstra = dijkstra;

        _instructionService = instructionService;
    }
    private async Task<int> GetBuildingIdFromNode(string nodeId)
    {
        return await _context.Nodes
            .Where(n => n.NodeId == nodeId)
            .Select(n => n.BuildingId)
            .FirstAsync();
    }

    private async Task<BuildingEntrance> GetEntrance(int buildingId)
    {
        return await _context.BuildingEntrances
            .FirstAsync(e => e.BuildingId == buildingId);
    }
    [HttpGet]
    public async Task<IActionResult> GetRoute(
    double? startLat,
    double? startLng,
    string? startIndoorNode,
    double? endLat,
    double? endLng,
    string? destinationIndoorNode)
    {
        // Load indoor graph if needed
        if (!_indoorGraph.IsLoaded)
        {
            await _indoorGraph.LoadGraphAsync();

            Console.WriteLine(
                $"Indoor Graph Loaded : {_indoorGraph.Graph.Count}");
        }

        // Load outdoor graph if needed
        if (!_loader.IsLoaded)
        {
            await _loader.LoadGraphAsync();

            Console.WriteLine(
                $"Outdoor Graph Loaded : {_loader.Graph.Count}");
        }

        bool startIndoor = !string.IsNullOrEmpty(startIndoorNode);
        bool endIndoor = !string.IsNullOrEmpty(destinationIndoorNode);

        // ----------------------------------------------------
        // CASE 1 : OUTDOOR → OUTDOOR
        // ----------------------------------------------------
        if (!startIndoor && !endIndoor)
        {
            var startNode = await _outdoorGraph.FindNearestNode(startLat.Value, startLng.Value);
            var endNode = await _outdoorGraph.FindNearestNode(endLat.Value, endLng.Value);

            var path = _router.FindPath(startNode.NodeId, endNode.NodeId);

            var outdoorInstructions =
                _instructionService.GenerateOutdoor(path, _loader.NodeCoords);

            var result = path.Select(nodeId =>
            {
                var coord = _loader.NodeCoords[nodeId];

                return new
                {
                    nodeId,
                    latitude = coord.lat,
                    longitude = coord.lng
                };
            });

            return Ok(new
            {
                type = "outdoor",
                startNode = startNode.NodeId,
                endNode = endNode.NodeId,
                path = result,
                instructions = outdoorInstructions
            });
        }

        // ----------------------------------------------------
        // CASE 2 : INDOOR → INDOOR
        // ----------------------------------------------------
        // ----------------------------------------------------
        // CASE 2 : INDOOR → INDOOR
        // ----------------------------------------------------
        if (startIndoor && endIndoor)
        {
            int startBuilding =
                await GetBuildingIdFromNode(startIndoorNode);

            int destinationBuilding =
                await GetBuildingIdFromNode(destinationIndoorNode);

            // ----------------------------------------------------
            // SAME BUILDING
            // ----------------------------------------------------
            if (startBuilding == destinationBuilding)
            {
                var (path, distance) =
                    _dijkstra.FindPath(startIndoorNode, destinationIndoorNode);

                var indoorInstructions =
                    await _instructionService.GenerateIndoor(path);

                return Ok(new
                {
                    type = "indoor",
                    buildingId = startBuilding,
                    sourceNode = startIndoorNode,
                    destinationNode = destinationIndoorNode,
                    path,
                    instructions = indoorInstructions,
                    distance
                });
            }

            // ----------------------------------------------------
            // DIFFERENT BUILDINGS
            // ----------------------------------------------------

            var startEntrance =
                await GetEntrance(startBuilding);

            var destinationEntrance =
                await GetEntrance(destinationBuilding);

            // Indoor path to exit
            var (indoorPath1, distance1) =
                _dijkstra.FindPath(
                    startIndoorNode,
                    startEntrance.IndoorNodeId);

            var indoorInstructions1 =
                await _instructionService.GenerateIndoor(indoorPath1);

            // Outdoor path
            var outdoorPath =
                _router.FindPath(
                    startEntrance.OutdoorNodeId,
                    destinationEntrance.OutdoorNodeId);

            var outdoorInstructions =
                _instructionService.GenerateOutdoor(
                    outdoorPath,
                    _loader.NodeCoords);

            var outdoorResult =
                outdoorPath.Select(nodeId =>
                {
                    var coord = _loader.NodeCoords[nodeId];

                    return new
                    {
                        nodeId,
                        latitude = coord.lat,
                        longitude = coord.lng
                    };
                });

            // Indoor path inside destination building
            var (indoorPath2, distance2) =
                _dijkstra.FindPath(
                    destinationEntrance.IndoorNodeId,
                    destinationIndoorNode);

            var indoorInstructions2 =
                await _instructionService.GenerateIndoor(indoorPath2);

            return Ok(new
            {
                type = "hybrid",
                indoorStart = new
                {
                    buildingId = startBuilding,
                    sourceNode = startIndoorNode,
                    destinationNode = startEntrance.IndoorNodeId,
                    path = indoorPath1,
                    instructions = indoorInstructions1,
                    distance = distance1
                },

                exitTransition = new
                {
                    buildingId = startBuilding,
                    indoorNode = startEntrance.IndoorNodeId,
                    outdoorNode = startEntrance.OutdoorNodeId,
                    instruction = "Exit the building"
                },

                outdoor = new
                {
                    startNode = startEntrance.OutdoorNodeId,
                    endNode = destinationEntrance.OutdoorNodeId,
                    path = outdoorResult,
                    instructions = outdoorInstructions
                },

                enterTransition = new
                {
                    buildingId = destinationBuilding,
                    outdoorNode = destinationEntrance.OutdoorNodeId,
                    indoorNode = destinationEntrance.IndoorNodeId,
                    instruction = "Enter the destination building"
                },

                indoorDestination = new
                {
                    buildingId = destinationBuilding,
                    sourceNode = destinationEntrance.IndoorNodeId,
                    destinationNode = destinationIndoorNode,
                    path = indoorPath2,
                    instructions = indoorInstructions2,
                    distance = distance2
                },

                totalIndoorDistance = distance1 + distance2
            });
        }

        // ----------------------------------------------------
        // CASE 3 : OUTDOOR → INDOOR
        // ----------------------------------------------------
        if (!startIndoor && endIndoor)
        {
            int buildingId =
        await GetBuildingIdFromNode(destinationIndoorNode);

            var entrance =
                await GetEntrance(buildingId);
            var startNode =
                await _outdoorGraph.FindNearestNode(startLat.Value, startLng.Value);

            var outdoorPath =
                _router.FindPath(startNode.NodeId, entrance.OutdoorNodeId);

            var outdoorInstructions =
                _instructionService.GenerateOutdoor(outdoorPath, _loader.NodeCoords);

            var outdoorResult = outdoorPath.Select(nodeId =>
            {
                var coord = _loader.NodeCoords[nodeId];

                return new
                {
                    nodeId,
                    latitude = coord.lat,
                    longitude = coord.lng
                };
            });

            var (indoorPath, distance) =
                _dijkstra.FindPath(
                    entrance.IndoorNodeId,
                    destinationIndoorNode);

            var indoorInstructions =
                await _instructionService.GenerateIndoor(indoorPath);

            return Ok(new
            {
                type = "hybrid",

                outdoor = new
                {
                    startNode = startNode.NodeId,
                    endNode = entrance.OutdoorNodeId,
                    path = outdoorResult,
                    instructions = outdoorInstructions
                },

                transition = new
                {
                    outdoorNode = entrance.OutdoorNodeId,
                    indoorNode = entrance.IndoorNodeId,
                    instruction = "Enter the building"
                },

                indoor = new
                {
                    sourceNode = entrance.IndoorNodeId,
                    destinationNode = destinationIndoorNode,
                    path = indoorPath,
                    instructions = indoorInstructions,
                    distance
                }
            });
        }

        // ----------------------------------------------------
        // CASE 4 : INDOOR → OUTDOOR
        // ----------------------------------------------------
        if (startIndoor && !endIndoor)
        {
            int buildingId =
      await GetBuildingIdFromNode(startIndoorNode);



            var entrance =
                await GetEntrance(buildingId);
            var (indoorPath, distance) =
                _dijkstra.FindPath(
                    startIndoorNode,
                    entrance.IndoorNodeId);

            var indoorInstructions =
                await _instructionService.GenerateIndoor(indoorPath);

            var endNode =
                await _outdoorGraph.FindNearestNode(endLat.Value, endLng.Value);

            var outdoorPath =
                _router.FindPath(
                    entrance.OutdoorNodeId,
                    endNode.NodeId);

            var outdoorInstructions =
                _instructionService.GenerateOutdoor(outdoorPath, _loader.NodeCoords);

            var outdoorResult = outdoorPath.Select(nodeId =>
            {
                var coord = _loader.NodeCoords[nodeId];

                return new
                {
                    nodeId,
                    latitude = coord.lat,
                    longitude = coord.lng
                };
            });

            return Ok(new
            {
                type = "hybrid",

                indoor = new
                {
                    sourceNode = startIndoorNode,
                    destinationNode = entrance.IndoorNodeId,
                    path = indoorPath,
                    instructions = indoorInstructions,
                    distance
                },

                transition = new
                {
                    outdoorNode = entrance.OutdoorNodeId,
                    indoorNode = entrance.IndoorNodeId,
                    instruction = "Exit the building"
                },

                outdoor = new
                {
                    startNode = entrance.OutdoorNodeId,
                    endNode = endNode.NodeId,
                    path = outdoorResult,
                    instructions = outdoorInstructions
                }
            });
        }

        return BadRequest("Invalid route request");
    }

}

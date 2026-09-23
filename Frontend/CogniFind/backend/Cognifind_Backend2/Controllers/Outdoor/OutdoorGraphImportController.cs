//using Microsoft.AspNetCore.Mvc;
//using System.IO;
//using Cognifind_Backend2.Services;

//[ApiController]
//[Route("api/import-outdoor-graph")]
//public class OutdoorGraphImportController : ControllerBase
//{
//    private readonly AppDbContext _context;

//    public OutdoorGraphImportController(AppDbContext context)
//    {
//        _context = context;
//    }

//    [HttpPost]
//    public async Task<IActionResult> Import()
//    {
//        try
//        {
//            // 1️⃣ Get KML file path
//            var filePath = Path.Combine(
//                Directory.GetCurrentDirectory(),
//                "Resources",
//                "campus_paths.kml"
//            );

//            if (!System.IO.File.Exists(filePath))
//                return BadRequest("KML file not found");

//            // 2️⃣ Parse KML
//            var parser = new KmlParserService();

//            var paths = parser.Parse(filePath);

//            if (paths == null || paths.Count == 0)
//                return BadRequest("No paths found in KML");

//            // 3️⃣ Build outdoor graph
//            var builder = new OutdoorGraphBuilder(_context);

//            await builder.BuildGraph(paths);

//            // 4️⃣ Return result
//            return Ok(new
//            {
//                message = "Outdoor graph imported successfully",
//                pathsParsed = paths.Count
//            });
//        }
//        catch (Exception ex)
//        {
//            return BadRequest(new
//            {
//                error = ex.Message
//            });
//        }
//    }
//}
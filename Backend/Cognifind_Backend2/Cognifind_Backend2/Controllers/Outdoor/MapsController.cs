using Microsoft.AspNetCore.Mvc;
using System.Net.Http;
using System.Text.Json;
using System.Threading.Tasks;

namespace CognifindAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class MapsController : ControllerBase
    {
        private readonly HttpClient _httpClient;
        private readonly IConfiguration _config;

        public MapsController(HttpClient httpClient, IConfiguration config)
        {
            _httpClient = httpClient;
            _config = config;
        }

        [HttpGet("directions")]
        public async Task<IActionResult> GetDirections(double srcLat, double srcLng, double dstLat, double dstLng)
        {
            var apiKey = _config["GoogleMaps:ApiKey"];
            if (string.IsNullOrWhiteSpace(apiKey))
                return BadRequest(new { error = "Google API key not configured" });

            string url =
                $"https://maps.googleapis.com/maps/api/directions/json" +
                $"?origin={srcLat},{srcLng}&destination={dstLat},{dstLng}&mode=walking&key={apiKey}";

            using var response = await _httpClient.GetAsync(url);
            var json = await response.Content.ReadAsStringAsync();

            if (!response.IsSuccessStatusCode)
                return StatusCode((int)response.StatusCode, json);

            var doc = JsonDocument.Parse(json);
            var root = doc.RootElement;

            if (root.GetProperty("status").GetString() != "OK")
                return BadRequest(new { error = root.GetProperty("status").GetString() });

            var route = root.GetProperty("routes")[0];
            var leg = route.GetProperty("legs")[0];

            var distance = leg.GetProperty("distance").GetProperty("text").GetString();
            var duration = leg.GetProperty("duration").GetProperty("text").GetString();
            var polyline = route.GetProperty("overview_polyline").GetProperty("points").GetString();

            return Ok(new
            {
                Distance = distance,
                Duration = duration,
                Polyline = polyline
            });
        }
    }
}



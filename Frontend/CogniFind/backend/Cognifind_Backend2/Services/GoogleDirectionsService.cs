
using System.Text.Json;
using Cognifind_Backend.Api.Models;
using Cognifind_Backend.Api.Utils;

namespace Cognifind.Api.Services
{
    public class GoogleDirectionsService : IGoogleDirectionsService
    {
        private readonly HttpClient _http;
        private readonly IConfiguration _config;

        public GoogleDirectionsService(HttpClient http, IConfiguration config)
        {
            _http = http;
            _config = config;
        }

        public async Task<RouteResponse> GetWalkingRouteAsync(
            double srcLat, double srcLng,
            double dstLat, double dstLng,
            CancellationToken ct = default)
        {
            var key = _config["GoogleMaps:ApiKey"];
            if (string.IsNullOrWhiteSpace(key))
                throw new InvalidOperationException("Google:DirectionsApiKey not configured.");

            var url =
                $"https://maps.googleapis.com/maps/api/directions/json" +
                $"?origin={srcLat},{srcLng}&destination={dstLat},{dstLng}&mode=walking&key={key}";

            using var res = await _http.GetAsync(url, ct);
            res.EnsureSuccessStatusCode();

            using var stream = await res.Content.ReadAsStreamAsync(ct);
            using var doc = await JsonDocument.ParseAsync(stream, cancellationToken: ct);

            var root = doc.RootElement;
            var status = root.GetProperty("status").GetString();

            if (!string.Equals(status, "OK", StringComparison.OrdinalIgnoreCase))
                throw new InvalidOperationException($"Google Directions status: {status}");

            var route0 = root.GetProperty("routes")[0];
            var legs0 = route0.GetProperty("legs")[0];

            var distanceMeters = legs0.GetProperty("distance").GetProperty("value").GetInt32();
            var durationSecs = legs0.GetProperty("duration").GetProperty("value").GetInt32();

            var encoded = route0.GetProperty("overview_polyline").GetProperty("points").GetString()!;
            var points = PolylineDecoder.Decode(encoded)
                .Select(p => new LatLngDto { lat = p.lat, lng = p.lng })
                .ToList();

            return new RouteResponse
            {
                route = points,
                distance = distanceMeters,
                duration = durationSecs
            };
        }
    }
}


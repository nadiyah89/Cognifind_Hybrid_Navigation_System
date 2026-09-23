using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/location")]
public class LocationController : ControllerBase
{
    private readonly LocalizationService _localizationService;

    public LocationController(LocalizationService localizationService)
    {
        _localizationService = localizationService;
    }

    [HttpPost]
    public async Task<IActionResult> UpdateLocation([FromBody] LocationRequest request)
    {
        var result = await _localizationService.EstimatePositionAsync(request);
        return Ok(result);
    }
}
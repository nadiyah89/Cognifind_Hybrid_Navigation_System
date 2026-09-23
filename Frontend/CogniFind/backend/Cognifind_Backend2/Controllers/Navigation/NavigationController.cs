using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("api/navigation")]
public class NavigationSessionController : ControllerBase
{
    private readonly NavigationSessionService _session;

    public NavigationSessionController(
        NavigationSessionService session)
    { 
        _session = session;
    }

    [HttpPost("session")]
    public async Task<IActionResult> Update(
        NavigationSessionRequest request)
    {
        var result =
            await _session.UpdateAsync(request);

        return Ok(result);
    }
}
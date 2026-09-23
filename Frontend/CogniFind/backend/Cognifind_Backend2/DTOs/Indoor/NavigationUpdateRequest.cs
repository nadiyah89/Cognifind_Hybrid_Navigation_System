using Cognifind_Backend2.DTOs.Indoor;

public class NavigationUpdateRequest
{
    public string CurrentNode { get; set; } = string.Empty;

    public int CurrentStepIndex { get; set; }

    public List<PathNode> Route { get; set; } = new();
}
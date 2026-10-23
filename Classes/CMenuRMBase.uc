// Shared behaviour for the Realism Match menu and its submenus
class CMenuRMBase extends CMenu
    abstract;

function Initialize()
{
    if (bIsAuthorized == false)
    {
        MessageSelf("You are not authorized to use this menu.");
        GoToState('');
        return;
    }

    SetTeamDisplayNames();
    super.Initialize();
}

// Menus that list the two teams override this to rename their entries
function SetTeamDisplayNames()
{
}

function GetTeamNames(out string NorthName, out string SouthName)
{
    local string MapName;

    MapName = PC.WorldInfo.GetMapName(true);
    NorthName = "North";
    SouthName = "South";

    if (InStr(MapName, "WWTE",,true) != -1 || InStr(MapName, "WWSU",,true) != -1)
    {
        NorthName = "Finnish";
        SouthName = "Soviets";
    }
    else if (InStr(MapName, "RR",,true) != -1 || InStr(MapName, "DR",,true) != -1)
    {
        NorthName = "Axis";
        SouthName = "Allies";
    }
}

defaultproperties
{
}

// Realism Match: swapping teams and the weapon safeties
class CMenuRMTeams extends CMenuRMBase;

function SetTeamDisplayNames()
{
    local string NorthName, SouthName;

    GetTeamNames(NorthName, SouthName);
    MenuText[1] = "Swap "$NorthName$" to "$SouthName;
    MenuText[2] = "Swap "$SouthName$" to "$NorthName;
}

defaultproperties
{
    MenuName="TEAMS AND WEAPONS"

    MenuText.add("Swap Teams")
    MenuText.add("Swap North to South")
    MenuText.add("Swap South to North")
    MenuText.add("Weapons Hold")
    MenuText.add("Weapons Free")

    MenuCommand.add("SWAPTEAMS")
    MenuCommand.add("SWAPNORTH")
    MenuCommand.add("SWAPSOUTH")
    MenuCommand.add("WEAPONSHOLD")
    MenuCommand.add("WEAPONSFREE")
}

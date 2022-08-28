class CMenuPlayer extends CMenuBase;

// Updates a global array of playernames (used for kick & ban menus)
function UpdatePlayerList()
{
    local int i;
	super.UpdatePlayerList();

    MenuText = PlayerList;

    for (i = 0; i < MenuText.Length; i++)
    {
        MenuCommand[i] = "CMENUPCMANAGER "$PlayerList[i];
    }
}

defaultproperties
{
    MenuName="PLAYERS"

    bCMenuDebug=true
}
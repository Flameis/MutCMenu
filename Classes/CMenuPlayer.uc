class CMenuPlayer extends CMenu;

function Initialize()
{
    if (bIsAuthorized == false)
    {
        MessageSelf("You are not authorized to use this menu.");
        GoToState('');
        return;
    }

    UpdatePlayerList(); // Do this here because doing it in PostRender() repeats it over & over
	super.Initialize();
}

// Updates a global array of playernames (used for player manager menu)
function UpdatePlayerList()
{
	local array<PlayerReplicationInfo> PRIArray;
	local ROPlayerReplicationInfo ROPRI;
    local ROGameReplicationInfo ROGRI;
    local int i;

	PlayerList.Length = 0;

	ROGRI = ROGameReplicationInfo(PC.WorldInfo.GRI);
	ROGRI.GetPRIArray(PRIArray, true);

    // Loops through all PRIs
	for ( i = 0; i < PRIArray.Length; i++ )
	{
		ROPRI = ROPlayerReplicationInfo(PRIArray[i]);
		
		// This check is to verify if we should be on the list & !ROPRI.bIsInactive if we're a legit player and not '<<TeamChatProx>>' or '<<WebAdmin>>' or 'Player'
		if (ROPRI != none && !ROPRI.bIsInactive)
		{
			PlayerList.AddItem(ROPRI.PlayerName);
		}
        if(bCMenuDebug) `Log("UpdatePlayerList()"$ROPRI.PlayerName);
	}

    MenuText = PlayerList;

    for (i = 0; i < MenuText.Length; i++)
    {
        MenuCommand[i] = "CMENUPCMANAGER "$PlayerList[i];
    }
}

defaultproperties
{
    MenuName="PLAYERS"
}
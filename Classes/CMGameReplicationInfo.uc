class CMGameReplicationInfo extends ROGameReplicationInfo;

var repnotify CMAObjective NewObj;

simulated event ReplicatedEvent(name VarName)
{
	local ROPlayerController ROPC;

	//`log(VarName);

	if ( VarName == 'NewObj' )
	{
		AddObjective(NewObj, true);

		foreach LocalPlayerControllers(class'ROPlayerController', ROPC)
		{
			ROPC.ObjectivesUpdated();
			ROPC.ObjectiveStatusChanged(self);
		}
	}
	else if( VarName == 'CampaignFactionOverrides' )
	{
		if( ROMapInfo(WorldInfo.GetMapInfo()) != none )
		{
			if( CampaignFactionOverrides[0] < NFOR_Max )
				ROMapInfo(WorldInfo.GetMapInfo()).NorthernForce = ENorthernForces(CampaignFactionOverrides[0]);
			if( CampaignFactionOverrides[1] < SFOR_Max )
				ROMapInfo(WorldInfo.GetMapInfo()).SouthernForce = ESouthernForces(CampaignFactionOverrides[1]);

			ROMapInfo(WorldInfo.GetMapInfo()).bInitializedRoles = false;
			ROMapInfo(WorldInfo.GetMapInfo()).InitRolesForGametype(WorldInfo.GetGameClass(), MaxPlayers, bReverseRolesAndSpawns);

			// Force all the team icons to update
			foreach LocalPlayerControllers(class'ROPlayerController', ROPC)
			{
				ROPC.MyROHUD.SetTeamColoursForWidgets(ROPC.GetTeamNum());
			}
		}
	}
	else
	{
		super.ReplicatedEvent(VarName);
	}
}

//ROPC.ObjectivesUpdated()
class CMHUDWidgetOverheadMap extends ROHUDWidgetOverheadMap;

var int StartIndex; // The index of the first component in the HUDComponents array that is used by this widget

/** This should only be called once to get the Widget into a good starting state */
function Initialize(PlayerController HUDPlayerOwner)
{
    local int i, HUDComponentIndex;
    
    super.Initialize(HUDPlayerOwner);

    StartIndex = HUDComponents.Length;

    for ( i = 0; i < 96; i++ )
	{
        HUDComponentIndex = StartIndex + i;

		HUDComponents[HUDComponentIndex] = new class'ROHUDWidgetComponent';
		HUDComponents[HUDComponentIndex].X = HUDComponents[ROOMT_FriendlyPlayerStart].X;
		HUDComponents[HUDComponentIndex].Y = HUDComponents[ROOMT_FriendlyPlayerStart].Y;
		HUDComponents[HUDComponentIndex].Width = HUDComponents[ROOMT_FriendlyPlayerStart].Width;
		HUDComponents[HUDComponentIndex].Height = HUDComponents[ROOMT_FriendlyPlayerStart].Height;
		HUDComponents[HUDComponentIndex].TexWidth = HUDComponents[ROOMT_FriendlyPlayerStart].TexWidth;
		HUDComponents[HUDComponentIndex].TexHeight = HUDComponents[ROOMT_FriendlyPlayerStart].TexHeight;
		HUDComponents[HUDComponentIndex].Tex = HUDComponents[ROOMT_FriendlyPlayerStart].Tex;
		HUDComponents[HUDComponentIndex].DrawColor = HUDComponents[ROOMT_FriendlyPlayerStart].DrawColor;
		HUDComponents[HUDComponentIndex].bFadedOut = true;
		HUDComponents[HUDComponentIndex].FadeOutTime = HUDComponents[ROOMT_FriendlyPlayerStart].FadeOutTime;
		HUDComponents[HUDComponentIndex].SortPriority = HUDComponents[ROOMT_FriendlyPlayerStart].SortPriority;
		HUDComponents[HUDComponentIndex].bVisible = false;
    }
}

function UpdateWidget()
{
    super.UpdateWidget();

    if (PlayerOwner.PlayerReplicationInfo.bIsSpectator)
    {
        UpdatePlayerIcons();
    }
}

function UpdatePlayerIcons()
{
	local int i, ComponentIndex;
	local ROTeamInfo Team;
	local float TeamLocationX, TeamLocationY, TeamLocationZ;

    ComponentIndex = StartIndex;
    
    Team = ROTeamInfo(WorldInfo.GRI.Teams[0]);

    for ( i = 0; i < 32; i++ )
	{
		Team.GetTeamLocationEntry(i, TeamLocationX, TeamLocationY, TeamLocationZ);
		// Show only Player tags from the same team and ignore own pawn
		if ( Team.TeamPRIArray[i] != none && Team.TeamPRIArray[i] != PlayerOwner.PlayerReplicationInfo &&
			 TeamLocationX > MinVisibleWorldX && TeamLocationX < MaxVisibleWorldX &&
			 TeamLocationY > MinVisibleWorldY && TeamLocationY < MaxVisibleWorldY &&
			 Team.TeamPRIArray[i].RoleInfo != none )
		{
			if ( Team.TeamPRIArray[i].bDead )
			{
                HUDComponents[ComponentIndex].bFadedOut = true;
				HUDComponents[ComponentIndex].bVisible = false;
			}
			else
			{
                HUDComponents[ComponentIndex].Tex = FriendlyPlayerIconRifle;
                HUDComponents[ComponentIndex].DrawColor = ROHUD(PlayerOwner.MyHUD).GetTeamColor(0);
                HUDComponents[ComponentIndex].SetScreenLocation(HUDComponents[ROOMT_Map].CurX + ((TeamLocationY - MinVisibleWorldY) * (HUDComponents[ROOMT_Map].CurWidth / (MaxVisibleWorldY - MinVisibleWorldY)) - (HUDComponents[ComponentIndex].CurWidth / 2)), HUDComponents[ROOMT_Map].CurY + HUDComponents[ROOMT_Map].CurHeight - ((TeamLocationX - MinVisibleWorldX) * (HUDComponents[ROOMT_Map].CurHeight / (MaxVisibleWorldX - MinVisibleWorldX)) + (HUDComponents[ComponentIndex].CurHeight / 2)), true, true);
                HUDComponents[ComponentIndex].bFadedOut = false;
				HUDComponents[ComponentIndex].bVisible = true;

                if ( CurrentZoom < 1.75f )
				{
					HUDComponents[ComponentIndex].CurWidth = PlayerSizeUnzoomed * 3.0 * HUDComponents[ComponentIndex].ScaleX;
					HUDComponents[ComponentIndex].CurHeight = PlayerSizeUnzoomed * 3.0 * HUDComponents[ComponentIndex].ScaleY;
				}
				else
				{
					HUDComponents[ComponentIndex].CurWidth = PlayerSizeZoomed * 3.0 * HUDComponents[ComponentIndex].ScaleX;
					HUDComponents[ComponentIndex].CurHeight = PlayerSizeZoomed * 3.0 * HUDComponents[ComponentIndex].ScaleY;
				}
            }

		    ComponentIndex++;
	    }
    }

    Team = ROTeamInfo(WorldInfo.GRI.Teams[1]);

    for ( i = 0; i < 32; i++ )
	{
		Team.GetTeamLocationEntry(i, TeamLocationX, TeamLocationY, TeamLocationZ);
		// Show only Player tags from the same team and ignore own pawn
		if ( Team.TeamPRIArray[i] != none && Team.TeamPRIArray[i] != PlayerOwner.PlayerReplicationInfo &&
			 TeamLocationX > MinVisibleWorldX && TeamLocationX < MaxVisibleWorldX &&
			 TeamLocationY > MinVisibleWorldY && TeamLocationY < MaxVisibleWorldY &&
			 Team.TeamPRIArray[i].RoleInfo != none )
		{
			if ( Team.TeamPRIArray[i].bDead )
			{
                HUDComponents[ComponentIndex].bFadedOut = true;
				HUDComponents[ComponentIndex].bVisible = false;
			}
			else
			{
                HUDComponents[ComponentIndex].Tex = FriendlyPlayerIconRifle;
                HUDComponents[ComponentIndex].DrawColor = ROHUD(PlayerOwner.MyHUD).GetTeamColor(1);
                HUDComponents[ComponentIndex].SetScreenLocation(HUDComponents[ROOMT_Map].CurX + ((TeamLocationY - MinVisibleWorldY) * (HUDComponents[ROOMT_Map].CurWidth / (MaxVisibleWorldY - MinVisibleWorldY)) - (HUDComponents[ComponentIndex].CurWidth / 2)), HUDComponents[ROOMT_Map].CurY + HUDComponents[ROOMT_Map].CurHeight - ((TeamLocationX - MinVisibleWorldX) * (HUDComponents[ROOMT_Map].CurHeight / (MaxVisibleWorldX - MinVisibleWorldX)) + (HUDComponents[ComponentIndex].CurHeight / 2)), true, true);
                HUDComponents[ComponentIndex].bFadedOut = false;
				HUDComponents[ComponentIndex].bVisible = true;

                if ( CurrentZoom < 1.75f )
				{
					HUDComponents[ComponentIndex].CurWidth = PlayerSizeUnzoomed * 3.0 * HUDComponents[ComponentIndex].ScaleX;
					HUDComponents[ComponentIndex].CurHeight = PlayerSizeUnzoomed * 3.0 * HUDComponents[ComponentIndex].ScaleY;
				}
				else
				{
					HUDComponents[ComponentIndex].CurWidth = PlayerSizeZoomed * 3.0 * HUDComponents[ComponentIndex].ScaleX;
					HUDComponents[ComponentIndex].CurHeight = PlayerSizeZoomed * 3.0 * HUDComponents[ComponentIndex].ScaleY;
				}
            }

		    ComponentIndex++;
	    }
    }
}
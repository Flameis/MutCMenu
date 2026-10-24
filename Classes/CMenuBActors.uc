class CMenuBActors extends CMenuB;

function Initialize()
{
	// Capture the Flag flags for either team, labelled with the team's faction ("CTF Flag: DAK (Axis)"). The server checks
	// for admins again.
	if (bIsAuthorized && PC != None)
	{
		MenuText.AddItem("CTF Flag: "$FlagEntry(`AXIS_TEAM_INDEX));
		MenuText.AddItem("CTF Flag: "$FlagEntry(`ALLIES_TEAM_INDEX));
		MenuCommand.AddItem("CTFFLAGNORTH");
		MenuCommand.AddItem("CTFFLAGSOUTH");
		// No preview: types the command in the console with the options explained, for flags the entries above can't make
		MenuText.AddItem("CTF Flag: Command Line");
		MenuCommand.AddItem("CTFFLAGCMD");
		MenuText.AddItem("Reset Flags");
		MenuText.AddItem("Remove Flags");
		MenuCommand.AddItem("RESETFLAGS");
		MenuCommand.AddItem("REMOVEFLAGS");
	}

	super.Initialize();
}

function string FlagEntry(int Team)
{
	return class'CMAFlag'.default.Factions[class'CMAFlag'.static.FactionForTeam(PC.WorldInfo, Team)].Label
		$" ("$class'CMAFlag'.static.TeamWord(PC.WorldInfo, Team)$")";
}

function bool CheckExceptions(string Command)
{
	local StaticMeshComponent SMC;
	local int i, j;

	ReferenceSkeletalMesh[0] = none;
	
    switch (command)
	{
		case "NORTHSPAWN":
		case "SOUTHSPAWN":
			ReferenceStaticMesh[0] = class'CMASpawn'.default.StaticMeshComponent.StaticMesh;
	
			if (Command ~= "NorthSpawn")
				SpawnTeamIndex = 0;
			else 
			 	SpawnTeamIndex = 1;
            GoToState('ReadyToPlace',, true);
			return true;

		case "SETCORNER":
		case "SPAWNOBJ":
		case "REDDECAL": 
		case "YELLOWDECAL":
			ReferenceStaticMesh[0] = StaticMesh'ENV_VN_Flags.Meshes.S_VN_Flagpole';
            GoToState('ReadyToPlace',, true);
			return true;

        case "CLEARALLACTORS":
            MyDA.ClearAllActors();
			MessageSelf("All actors have been cleared.");
            return true;

        case "TURRETM2":
            ReferenceSkeletalMesh[0] = class'CMATurret_M2_HMG_Destroyable'.Default.Mesh.SkeletalMesh;
            GoToState('ReadyToPlace',, true);
            return true;

		case "TURRETDSHK":
			ReferenceSkeletalMesh[0] = class'ROTurret_DShK_HMG_Destroyable'.Default.Mesh.SkeletalMesh;
			GoToState('ReadyToPlace',, true);
			return true;

		case "CTFFLAGCMD":
			PromptForText("CTF Flag|Places a flag where you are looking. Add options after the command, or just press Enter for your own team's flag.|"
				$"--team / -t : whose flag it is: north, south, axis, allies, finnish, soviet, 0 or 1 (spectators must give --team or --flag)|"
				$"--flag / -f : exactly one flag by name, even if no team on the map has it. Names: "$class'CMAFlag'.static.FactionNames()$"|"
				$"--nobeam / -n : leave out the beam above the flag|"
				$"Example: --team south|Example: --flag dak|Example: --flag ss --nobeam|Example: -t 1 -n|"
				$"WW2 and Winter War flags on a map from another game need bLoadWW2 / bLoadWW.", "mutate spawnflag ");
			return true;

		case "CTFFLAGNORTH":
		case "CTFFLAGSOUTH":
			ReferenceStaticMesh[0] = class'CMAFlag'.default.PoleMesh.StaticMesh;
			SpawnTeamIndex = (Command ~= "CTFFLAGNORTH") ? `AXIS_TEAM_INDEX : `ALLIES_TEAM_INDEX;
			GoToState('ReadyToPlace',, true);
			return true;

		case "RESUPPLYPOINT":
			j = 0;
			for (i = 0; i < class'CMAResupplyPoint'.Default.StaticMeshComponents.Length; i++)
			{
				SMC = class'CMAResupplyPoint'.Default.StaticMeshComponents[i];
				if (SMC != none)
				{
					ReferenceStaticMesh[j] = SMC.StaticMesh;
					j += 1;
				}
			}
			GoToState('ReadyToPlace',, true);
			return true;
    }
    return false;
}

function DoPlace()
{
	local Vector2D Point2D;

	switch (LastCmd)
	{
		case "NORTHSPAWN":
			MyDA.PlaceSpawn(class'CMASpawn',,, PlaceLoc, PlaceRot,,, SpawnTeamIndex);
			return;

		case "SOUTHSPAWN":
			MyDA.PlaceSpawn(class'CMASpawn',,, PlaceLoc, PlaceRot,,, SpawnTeamIndex);
			return;

		case "SETCORNER":
			Point2D.X = PlaceLoc.X;
			Point2D.Y = PlaceLoc.Y;
			Corners.AddItem(Point2D);
			MyDA.SetCorner(PlaceLoc, PlaceRot);
			return;

		case "SPAWNOBJ":
			MyDA.ServerSpawnObjective(PlaceLoc, Corners);
			Corners.Remove(0, Corners.Length);
			return;

		case "REDDECAL":
			MyDA.SpawnDecal(DecalMaterial'Effects_Mats.FX_Gore.BloodPool_001_DM', PlaceLoc, PlaceRot);
			return;

		case "YELLOWDECAL":
			MyDA.SpawnDecal(DecalMaterial'FX_VN_Materials.Materials.D_CommanderMark', PlaceLoc, PlaceRot);
			return;

		case "TURRETM2":
			MyDA.SpawnActor(class'CMATurret_M2_HMG_Destroyable',, 'Turret', PlaceLoc, PlaceRot,, true, LastCmd, ModifyScale.x, ModifyTime*10);
			return;

		case "TURRETDSHK":
			MyDA.SpawnActor(class'ROTurret_DShK_HMG_Destroyable',, 'Turret', PlaceLoc, PlaceRot,, true, LastCmd, ModifyScale.x, ModifyTime*10);
			return;

		case "RESUPPLYPOINT":
			MyDA.Spawn(class'CMAResupplyPoint',, 'ResupplyPoint', PlaceLoc, PlaceRot,, true);
			return;

		case "CTFFLAGNORTH":
		case "CTFFLAGSOUTH":
			MyDA.ServerPlaceFlag(PlaceLoc, SpawnTeamIndex);
			return;
	}
}

defaultproperties
{
    MenuName="ACTORS"

    MenuText.Add("Set North Spawn")
    MenuText.Add("Set South Spawn")
    MenuText.Add("Delete North Spawns")
    MenuText.Add("Delete South Spawns")
	MenuText.Add("Mark Corner")
	MenuText.Add("Spawn Obj")
	// MenuText.Add("Clear Corners")
    // MenuText.Add("Clear Objs")
    MenuText.Add("Clear All")
    MenuText.Add("M2 Turret")
	MenuText.Add("DShK Turret")
	MenuText.Add("Resupply Point")

    // MenuText.Add("Red Decal")
    // MenuText.Add("Yellow Decal")
    
    MenuCommand.Add("NORTHSPAWN")
    MenuCommand.Add("SOUTHSPAWN")
    MenuCommand.Add("DELNORTHSPAWNS")
    MenuCommand.Add("DELSOUTHSPAWNS")
	MenuCommand.Add("SETCORNER")
	MenuCommand.Add("SPAWNOBJ")
	// MenuCommand.Add("CLEARCORNERS")
    // MenuCommand.Add("CLEAROBJS")
    MenuCommand.Add("CLEARALLACTORS")
	MenuCommand.Add("TURRETM2")
	MenuCommand.Add("TURRETDSHK")
	MenuCommand.Add("RESUPPLYPOINT")

    // MenuCommand.Add("REDDECAL")
    // MenuCommand.Add("YELLOWDECAL")
}
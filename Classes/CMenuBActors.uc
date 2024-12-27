class CMenuBActors extends CMenuB;

function bool CheckExceptions(string Command)
{
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
            ClearAllActors();
            return true;
    }
    return false;
}

function DoPlace()
{
	if (LastCmd == "SETCORNER")
	{
        MyDA.SetCorners(PlaceLoc, PlaceRot);
	}
	else if (LastCmd == "NORTHSPAWN" || LastCmd == "SOUTHSPAWN")
	{
		MyDA.PlaceSpawn(class'CMASpawn',,, PlaceLoc, PlaceRot,,, SpawnTeamIndex);
	}
	/* else if (LastCmd == "SPAWNOBJ")
	{
    	MyDA.ServerSpawnOBJ(class'CMAObjective',,, PlaceLoc);
	} */
	else if (LastCmd == "REDDECAL")
	{
    	MyDA.SpawnDecal(DecalMaterial'Effects_Mats.FX_Gore.BloodPool_001_DM', PlaceLoc, PlaceRot);
	}
	else if (LastCmd == "YELLOWDECAL")
	{
    	MyDA.SpawnDecal(DecalMaterial'FX_VN_Materials.Materials.D_CommanderMark', PlaceLoc, PlaceRot);
	}
}

function ClearAllActors()
{
    local Actor ActorToClear;

    foreach MyDA.AllActors(class'Actor', ActorToClear)
    {
        if (ActorToClear.IsA('CMASpawn') || ActorToClear.IsA('CMAObjective') || ActorToClear.IsA('DecalActor'))
        {
            ActorToClear.Destroy();
        }
    }
    `log("All actors have been cleared.");
}

defaultproperties
{
    MenuName="ACTORS"

    MenuText.Add("Set North Spawn")
    MenuText.Add("Set South Spawn")
    MenuText.Add("Delete North Spawns")
    MenuText.Add("Delete South Spawns")
    // MenuText.Add("Mark Corner")
    // MenuText.Add("Spawn Obj")
	// MenuText.Add("Clear Corners")
    // MenuText.Add("Clear Objs")
    MenuText.Add("Clear All")

    // MenuText.Add("Red Decal")
    // MenuText.Add("Yellow Decal")
    
    MenuCommand.Add("NORTHSPAWN")
    MenuCommand.Add("SOUTHSPAWN")
    MenuCommand.Add("DELNORTHSPAWNS")
    MenuCommand.Add("DELSOUTHSPAWNS")
    // MenuCommand.Add("SETCORNER")
    // MenuCommand.Add("SPAWNOBJ")
	// MenuCommand.Add("CLEARCORNERS")
    // MenuCommand.Add("CLEAROBJS")
    MenuCommand.Add("CLEARALLACTORS")

    // MenuCommand.Add("REDDECAL")
    // MenuCommand.Add("YELLOWDECAL")
}
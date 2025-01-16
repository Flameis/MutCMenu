class CMenuBActors extends CMenuB;

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
	switch (LastCmd)
	{
		case "NORTHSPAWN":
			MyDA.PlaceSpawn(class'CMASpawn',,, PlaceLoc, PlaceRot,,, SpawnTeamIndex);
			return;

		case "SOUTHSPAWN":
			MyDA.PlaceSpawn(class'CMASpawn',,, PlaceLoc, PlaceRot,,, SpawnTeamIndex);
			return;

		case "SETCORNER":
			MyDA.SetCorner(PlaceLoc, PlaceRot);
			return;

		// case "SPAWNOBJ":
		// 	MyDA.ServerSpawnOBJ(class'CMAObjective',,, PlaceLoc);
		// 	return;

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
	}
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
    MenuText.Add("M2 Turret")
	MenuText.Add("DShK Turret")
	MenuText.Add("Resupply Point")

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
	MenuCommand.Add("TURRETM2")
	MenuCommand.Add("TURRETDSHK")
	MenuCommand.Add("RESUPPLYPOINT")

    // MenuCommand.Add("REDDECAL")
    // MenuCommand.Add("YELLOWDECAL")
}
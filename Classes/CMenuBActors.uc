class CMenuBActors extends CMenuB;

// The preview is made of the item's own meshes, where they sit on it, so each entry looks like what it places: a flag is
// its small pole with the cloth, the resupply point its stack of crates. With one mesh for everything most entries showed
// the same big flagpole, so picking another one looked like the preview never changed.
struct PreviewPart
{
	var StaticMesh		StaticMesh;		// One of these two
	var SkeletalMesh	SkeletalMesh;
	var vector			Offset;			// From the spot it goes at, turned with the item
	var rotator			Rotation;
	var vector			Scale;
};

var array<PreviewPart>				Parts;
var array<MeshComponent>			PartComps;		// The component showing each part, in the same order
var array<StaticMeshComponent>		StaticPool;		// Made when first needed and reused
var array<SkeletalMeshComponent>	SkeletalPool;
var bool							bFixedRotation;	// The item is placed facing north whatever way the player looks (flags)
var MaterialInterface				PlaceableMaterial;

// How far up the turrets start, so their legs are not in the ground. The arrow keys still move them from there.
const M2_RAISE = 20;
const DSHK_RAISE = 60;

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

// ====================================================
// What each entry previews
// ====================================================

// A new item: no parts yet, back on the spot the player aims at, facing where they look
function StartParts()
{
	Parts.Length = 0;
	ModifyLoc = vect(0, 0, 0);
	bFixedRotation = false;
}

function AddPart(StaticMesh SM, SkeletalMesh SkM, vector Offset, rotator Rot, vector Scale)
{
	local PreviewPart P;

	if (SM == None && SkM == None)
		return;

	P.StaticMesh = SM;
	P.SkeletalMesh = SkM;
	P.Offset = Offset;
	P.Rotation = Rot;
	P.Scale = Scale;
	Parts.AddItem(P);
}

// A part copied from one of the item's own components, as it sits on the item, with Lift added to its height
function AddComponentPart(MeshComponent C, optional float Lift)
{
	local vector Offset;

	if (C == None)
		return;

	Offset = C.Translation;
	Offset.Z += Lift;
	if (StaticMeshComponent(C) != None)
		AddPart(StaticMeshComponent(C).StaticMesh, None, Offset, C.Rotation, C.Scale3D * C.Scale);
	else if (SkeletalMeshComponent(C) != None)
		AddPart(None, SkeletalMeshComponent(C).SkeletalMesh, Offset, C.Rotation, C.Scale3D * C.Scale);
}

function bool CheckExceptions(string Command)
{
	local int i;

    switch (command)
	{
		case "NORTHSPAWN":
		case "SOUTHSPAWN":
			StartParts();
			AddComponentPart(class'CMASpawn'.default.StaticMeshComponent);
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
			StartParts();
			AddPart(StaticMesh'ENV_VN_Flags.Meshes.S_VN_Flagpole', None, vect(0, 0, 0), rot(0, 0, 0), vect(1, 1, 1));
            GoToState('ReadyToPlace',, true);
			return true;

        case "CLEARALLACTORS":
            MyDA.ClearAllActors();
			MessageSelf("All actors have been cleared.");
            return true;

        case "TURRETM2":
			StartParts();
			ModifyLoc.Z = M2_RAISE;
			AddPart(None, class'CMATurret_M2_HMG_Destroyable'.default.Mesh.SkeletalMesh, vect(0, 0, 0), rot(0, 0, 0), vect(1, 1, 1));
            GoToState('ReadyToPlace',, true);
            return true;

		case "TURRETDSHK":
			StartParts();
			ModifyLoc.Z = DSHK_RAISE;
			AddPart(None, class'ROTurret_DShK_HMG_Destroyable'.default.Mesh.SkeletalMesh, vect(0, 0, 0), rot(0, 0, 0), vect(1, 1, 1));
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
			// The flag drops onto the ground, so it stands on the bottom of its collision, and is placed facing north
			StartParts();
			bFixedRotation = true;
			AddComponentPart(class'CMAFlag'.default.PoleMesh, CylinderComponent(class'CMAFlag'.default.CollisionComponent).CollisionHeight);
			AddComponentPart(class'CMAFlag'.default.FlagMesh, CylinderComponent(class'CMAFlag'.default.CollisionComponent).CollisionHeight);
			SpawnTeamIndex = (Command ~= "CTFFLAGNORTH") ? `AXIS_TEAM_INDEX : `ALLIES_TEAM_INDEX;
			GoToState('ReadyToPlace',, true);
			return true;

		case "RESUPPLYPOINT":
			StartParts();
			for (i = 0; i < class'CMAResupplyPoint'.default.StaticMeshComponents.Length; i++)
				AddComponentPart(class'CMAResupplyPoint'.default.StaticMeshComponents[i]);
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
			MyDA.SpawnActor(class'CMATurret_M2_HMG_Destroyable',, 'Turret', PlaceLoc, PlaceRot,, true, LastCmd, 1.0, ModifyTime*10);
			return;

		case "TURRETDSHK":
			MyDA.SpawnActor(class'ROTurret_DShK_HMG_Destroyable',, 'Turret', PlaceLoc, PlaceRot,, true, LastCmd, 1.0, ModifyTime*10);
			return;

		case "RESUPPLYPOINT":
			// Through the server: spawned here, it only ever existed on this player's screen
			MyDA.SpawnActor(class'CMAResupplyPoint',, 'ResupplyPoint', PlaceLoc, PlaceRot,, true);
			return;

		case "CTFFLAGNORTH":
		case "CTFFLAGSOUTH":
			MyDA.ServerPlaceFlag(PlaceLoc, SpawnTeamIndex);
			return;
	}
}

// ====================================================
// The preview
// ====================================================

function MeshComponent PartComponent(int Index, out int NumStatic, out int NumSkeletal)
{
	if (Parts[Index].SkeletalMesh != None)
	{
		if (NumSkeletal >= SkeletalPool.Length)
			SkeletalPool.AddItem(new(PC) class'SkeletalMeshComponent'(PreviewSkeletalMesh[0]));
		SkeletalPool[NumSkeletal].SetSkeletalMesh(Parts[Index].SkeletalMesh);
		return SkeletalPool[NumSkeletal++];
	}

	if (NumStatic >= StaticPool.Length)
		StaticPool.AddItem(new(PC) class'StaticMeshComponent'(PreviewStaticMesh[0]));
	StaticPool[NumStatic].SetStaticMesh(Parts[Index].StaticMesh);
	return StaticPool[NumStatic++];
}

function InitializePreview()
{
	local int i, j, NumStatic, NumSkeletal;

	PartComps.Length = 0;
	for (i = 0; i < Parts.Length; i++)
	{
		PartComps.AddItem(PartComponent(i, NumStatic, NumSkeletal));
		for (j = 0; j < Max(PartComps[i].GetNumElements(), 1); j++)
			PartComps[i].SetMaterial(j, PlaceableMaterial);
	}
	bPreviewIsSkeletal = NumSkeletal > 0 && NumStatic == 0;
}

simulated function ShowPreviewMesh()
{
	local Actor Host;
	local int i;

	Host = GetPreviewHost();
	if (Host == None)
		return;

	for (i = 0; i < PartComps.Length; i++)
	{
		Host.AttachComponent(PartComps[i]);
		PartComps[i].SetHidden(false);
	}

	PreviewHost = Host;
	bShowPreviewMesh = true;
	UpdatePreviewMesh(); // Where it goes straight away, not where the last item was for a frame
}

simulated function UpdatePreviewMesh()
{
	local rotator ItemRot;
	local int i;

	ItemRot = bFixedRotation ? rot(0, 0, 0) : PlaceRot;
	for (i = 0; i < PartComps.Length; i++)
	{
		PartComps[i].SetTranslation(PlaceLoc + (Parts[i].Offset >> ItemRot));
		PartComps[i].SetRotation(ItemRot + Parts[i].Rotation);
		PartComps[i].SetScale3D(Parts[i].Scale);
	}
}

simulated function HidePreviewMesh()
{
	local StaticMeshComponent PSM;
	local SkeletalMeshComponent PSkM;

	if (!bShowPreviewMesh)
		return;

	// Every pooled component, so nothing from an earlier item is left behind
	foreach StaticPool(PSM)
	{
		PSM.SetHidden(true);
		if (PreviewHost != None)
			PreviewHost.DetachComponent(PSM);
	}
	foreach SkeletalPool(PSkM)
	{
		PSkM.SetHidden(true);
		if (PreviewHost != None)
			PreviewHost.DetachComponent(PSkM);
	}
	PreviewHost = None;
	bShowPreviewMesh = false;
}

defaultproperties
{
    MenuName="ACTORS"

	bCanScale=false // Actors are always placed at their own size
	PlaceableMaterial=MaterialInstanceConstant'FX_VN_Materials.Materials.M_PlaceableItem'

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

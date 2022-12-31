class DummyActor extends actor;

var MutCMenu                     MyMut;

var bool bIsAuthorized, bNewTankPhys, bLoadGOM3, bLoadGOM4, bLoadWW;
var string TargetName;

var array<vector2d>				Corners;

replication
{
    if (bNetDirty)
        bIsAuthorized, bNewTankPhys, bLoadGOM3, bLoadGOM4, bLoadWW;
}

reliable client function CMenuSetup()
{
    local PlayerController PC;
    local int i;

    PC = PlayerController(Owner);

    pc.Interactions.additem(new(pc) class'CMenuMain');
    pc.Interactions.additem(new(pc) class'CMenuGeneral');
    pc.Interactions.additem(new(pc) class'CMenuSettings');

    pc.Interactions.additem(new(pc) class'CMenuParadrops');
    pc.Interactions.additem(new(pc) class'CMenuRealismMatch');
    pc.Interactions.additem(new(pc) class'CMenuPlayer');
    pc.Interactions.additem(new(pc) class'CMenuPCManager');

    pc.Interactions.additem(new(pc) class'CMenuBuilder');
    pc.Interactions.additem(new(pc) class'CMenuBSM');
    pc.Interactions.additem(new(pc) class'CMenuBPrefab');
    pc.Interactions.additem(new(pc) class'CMenuBVehicles');

    pc.Interactions.additem(new(pc) class'CMenuWeapons');
    
    pc.Interactions[pc.Interactions.Length] = pc.Interactions[0];
    pc.Interactions.remove(0, 1);
    
    for (i = 0; i < PC.Interactions.Length; i++)
    {
        if (InStr(PC.Interactions[i].name, "CMenu",,true) != -1)
        {
            CMenuBase(PC.Interactions[i]).PC = PC;
            CMenuBase(PC.Interactions[i]).MyDA = self;
        }
    }
}

reliable client function ToggleCMenuVisiblity(string CMenu, bool bAuthorized, string TName)
{
    local PlayerController PC;
    local int i;

    `log(TName);

    PC = PlayerController(Owner);

    for (i = 0; i < PC.Interactions.Length; i++)
    {
        if (InStr(PC.Interactions[i].name, CMenu,,true) != -1)
        {
            if (CMenuBase(PC.Interactions[i]).GetStateName() == 'MenuVisible')
            {
                CMenuBase(PC.Interactions[i]).GoToState('');
            }
            else 
            {
                CMenuBase(PC.Interactions[i]).bIsAuthorized = bAuthorized;
                CMenuBase(PC.Interactions[i]).TargetName = TName;
                CMenuBase(PC.Interactions[i]).GoToState('MenuVisible');
            }    
        }
        else if (InStr(PC.Interactions[i].name, "CMenu",,true) != -1)
        {
            PC.Interactions[i].GoToState('');
        }
    }
}

simulated function CMConsoleCommand(string Command)
{
    local PlayerController PC;
    PC = PlayerController(Owner);

    PC.ConsoleCommand(Command);
    `log (Command);
}

reliable client function ClientCMConsoleCommand(string Command)
{
    CMConsoleCommand(Command);
}

reliable client function SetCMenuColor(string InColor, string type)
{
    local PlayerController PC;
    local Color CMenuColor;
    local array<string> Colors;
    local int i;

    Colors = SplitString(InColor, " ", true);
    PC = PlayerController(Owner);

    if (Colors[3] == "")
    {
        Colors[3] = "255";
    }

    CMenuColor.r = int(Colors[0]);
    CMenuColor.g = int(Colors[1]);
    CMenuColor.b = int(Colors[2]);
    CMenuColor.a = int(Colors[3]);

    for (i = 0; i < PC.Interactions.Length; i++)
    {
        if (InStr(PC.Interactions[i].name, "CMenu",,true) != -1)
        {
            CMenuBase(PC.Interactions[i]).SetCMenuColor(CMenuColor, Type);
        }
    }
}

simulated function FactionSetup(ENorthernForces MyNorthForce, ESouthernForces MySouthForce)
{
    local ROMapInfo ROMI;
	
	ROMI = ROMapInfo(WorldInfo.GetMapInfo());

    `log(MyNorthForce);
    `log(MySouthForce);

    if( MyNorthForce < 2 )
	{
		ROMI.NorthernForce = ENorthernForces(MyNorthForce);
		CMGameReplicationInfo(WorldInfo.GRI).CampaignFactionOverrides[0] = MyNorthForce;
	}

	if( MySouthForce < 4 )
	{
		ROMI.SouthernForce = ESouthernForces(MySouthForce);
		CMGameReplicationInfo(WorldInfo.GRI).CampaignFactionOverrides[1] = MySouthForce;
	}

    ROMI.bInitializedRoles = false;
	ROMI.InitRolesForGametype(WorldInfo.GetGameClass(), 64, false);
}

reliable client function ClientFactionSetup(ENorthernForces MyNorthForce, ESouthernForces MySouthForce)
{
    FactionSetup(MyNorthForce, MySouthForce);
}

reliable server function ServerSetCorners(Vector PlaceLoc, rotator PlaceRot)
{
    local vector2d Point2d;

    Point2d.x = PlaceLoc.x;
    Point2d.y = PlaceLoc.y;
    Corners.AddItem(Point2d);

    ServerSpawnActor(class'CMSM',,'StaticMesh', PlaceLoc, PlaceRot,,, "ENV_VN_Flags.Meshes.S_VN_Flagpole");
}

reliable server function ServerSpawnOBJ(
    class<actor>      SpawnClass,
	optional actor	  SpawnOwner,
	optional name     SpawnTag,
	optional vector   SpawnLocation,
	optional rotator  SpawnRotation,
	optional Actor    ActorTemplate,
	optional bool	  bNoCollisionFail)
{
    local CMAObjective CMPO, ObjTemplate;
    local DummyActor DA;

    SpawnLocation.z = SpawnLocation.z + 200;
	ObjTemplate = CMAObjective(DynamicLoadObject("MutCMenuTBPkg.Objectives.OBJ"$MyMut.NumObjs+1, class'CMAObjective'));
	MyMut.NumObjs++;
    `log(ObjTemplate);
	CMPO = Spawn(class'CMAObjective', SpawnOwner, SpawnTag, SpawnLocation, SpawnRotation, ObjTemplate);
	CMPO.Init(Corners);
	Corners.Remove(0, Corners.Length);

    foreach AllActors(class'DummyActor', DA)
    {
        DA.ClientSetupObj(CMPO);
    }
}

reliable client function ClientSetupObj(CMAObjective CMPO)
{
    local ROGameReplicationInfo ROGRI;
    local int i;

    ROGRI = ROGameReplicationInfo(WorldInfo.GRI);
    ROGRI.AddObjective(CMPO, true);

    for (i=0; I < 16; i++)
    {
        `log(ROGameReplicationInfo(WorldInfo.GRI).ObjectiveShortNames[i]);
    }
}

reliable server function ServerPlaceSpawn(
    class<actor>        SpawnClass,
	optional actor	    SpawnOwner,
	optional name       SpawnTag,
	optional vector     SpawnLocation,
	optional rotator    SpawnRotation,
	optional Actor      ActorTemplate,
	optional bool	    bNoCollisionFail,
    optional int        TeamIdx)
{
    local CMSMSpawn SMS;

    SMS = Spawn(class'CMSMSpawn', SpawnOwner, SpawnTag, SpawnLocation, SpawnRotation, ActorTemplate, bNoCollisionFail);
	SMS.TeamIndex = TeamIdx;
}

reliable server function ServerSpawnActor(
    class<actor>        SpawnClass,
	optional actor	    SpawnOwner,
	optional name       SpawnTag,
	optional vector     SpawnLocation,
	optional rotator    SpawnRotation,
	optional Actor      ActorTemplate,
	optional bool	    bNoCollisionFail,
    optional string     SMesh)
{
    local CMSM CMSM;  

    CMSM = CMSM(Spawn(SpawnClass, SpawnOwner, SpawnTag, SpawnLocation, SpawnRotation, ActorTemplate, bNoCollisionFail));

    if (SpawnTag == 'StaticMesh')
        CMSM.SetStaticMesh(StaticMesh(DynamicLoadObject(SMesh, class'StaticMesh')));
    /* else 
        CMSM.SetSkeletalMesh(SkeletalMesh(DynamicLoadObject(SMesh, class'SkeletalMesh'))); */
}

reliable server function ServerSpawnDecal(
    MaterialInterface DecalMaterial,
	vector DecalLocation,
	rotator DecalOrientation)
{
    // local DecalComponent Decal;
    local CMADecal Decal;
	local float Height;

    DecalLocation.x = FMin(Corners[1].x, Corners[0].x) + (Abs(Corners[1].x - Corners[0].x)/2);
	DecalLocation.y = FMin(Corners[1].y, Corners[0].y) + (Abs(Corners[1].y - Corners[0].y)/2);
	DecalLocation.z = DecalLocation.z;
	DecalOrientation.Yaw = (atan2(Corners[1].y - Corners[0].y , Corners[1].x - Corners[0].x)*RadToUnrRot);
	DecalOrientation.Pitch = 270*DegToUnrRot;
	DecalOrientation.Roll = 0;
	Height = V2DSize(Corners[0] - Corners[1]);


    Decal = Spawn(class'CMADecal', Owner,, DecalLocation, DecalOrientation);

    Decal.DetachComponent(Decal.MyDecal);
	Decal.MyDecal.TileX = 0.2;
	Decal.MyDecal.TileY = 0.2;
    Decal.MyDecal.Location = DecalLocation;
	Decal.MyDecal.Orientation = DecalOrientation;
	Decal.MyDecal.Width = 10;
	Decal.MyDecal.Height = Height;
    Decal.MyDecal.FarPlane = 5000;
	Decal.MyDecal.NearPlane = -5000;
	Decal.MyDecal.SetDecalMaterial(DecalMaterial);
    Decal.MyDecal.bProjectOnTerrain = true;
	Decal.MyDecal.bProjectOnSkeletalMeshes = true;
	WorldInfo.MyDecalManager.AttachComponent(Decal.MyDecal);
	Corners.Remove(0, Corners.Length);
	`log(Decal.MyDecal.Location);
	`log(Decal.MyDecal.Height);
    // Decal = WorldInfo.MyDecalManager.SpawnDecal(DecalMaterial, DecalLocation, DecalOrientation, 10, Height, 10000, false, 0,, True, True,,,, 100000);
	
    /* WorldInfo.MyDecalManager.DetachComponent(Decal.Decal);
	Decal.TileX = 0.2;
	Decal.TileY = 0.2;
	WorldInfo.MyDecalManager.AttachComponent(Decal);
	Corners.Remove(0, Corners.Length);
	`log(Decal.Location);
	`log(Decal.Height); */
}

reliable server function SpawnVehicle(string VehicleName, vector PlaceLoc, rotator PlaceRot)
{
    local class<ROVehicle>          VehicleClass;
	local ROVehicle                 ROV;
    local ROPawn                    ROP;
    local bool                      bLandVic;

    ROP = ROPawn(PlayerController(Owner).Pawn);

	switch (VehicleName)
    {
        case "GOM3.GOMVehicle_M113_ACAV_ActualContent":
        bLandVic = true;
        break;

        case "GOM4.GOMVehicle_M113_ACAV_ActualContent":
        bLandVic = true;
        break;

        case "GOM4.GOMVehicle_M113_APC_ARVN":
        bLandVic = true;
        break;

        case "GOM4.GOMVehicle_M151_MUTT_US":
        bLandVic = true;
        break;

        case "GOM4.GOMVehicle_T34_ActualContent":
        bLandVic = true;
        break;

        case "WinterWar.WWVehicle_T20_ActualContent":
        bLandVic = true;
        break;

        case "WinterWar.WWVehicle_T26_EarlyWar_ActualContent":
        bLandVic = true;
        break;

        case "WinterWar.WWVehicle_T28_ActualContent":
        bLandVic = true;
        break;

        case "WinterWar.WWVehicle_HT130_ActualContent":
        bLandVic = true;
        break;

        case "WinterWar.WWVehicle_Vickers_ActualContent":
        bLandVic = true;
        break;

        case "WinterWar.WWVehicle_Skis_ActualContent":
        bLandVic = true;
        break;
    }

    VehicleClass = class<ROVehicle>(DynamicLoadObject(VehicleName, class'Class'));

    if (VehicleClass != none)
    {
        ROV = Spawn(VehicleClass, , , PlaceLoc, PlaceRot);
        ROV.Mesh.AddImpulse(vect(0,0,1), ROV.Location);
        ROV.bTeamLocked = false;

        // ROV.GroundSpeed=520
	    // ROV.MaxSpeed=940 //67 km/h

        if (bLandVic && bNewTankPhys)
        {
            ROV.Mesh.SetRBCollidesWithChannel(RBCC_Default, false);
            ROV.Mesh.SetRBCollidesWithChannel(RBCC_BlockingVolume, false);
        }

        if (VehicleName ~= "WinterWar.WWVehicle_Skis_ActualContent")
        {
            ROV.TryToDrive(ROP);
        }
    }
}

function string IntToString(int Int)
{
    switch(Int)
    {
        case 0:
        return "A";

        case 1:
        return "B";

        case 2:
        return "C";

        case 3:
        return "D";

        case 4:
        return "E";

        case 5:
        return "F";

        case 6:
        return "G";

        case 7:
        return "H";

        case 8:
        return "I";

        case 9:
        return "J";

        case 10:
        return "K";

        case 11:
        return "L";

        case 12:
        return "M";

        case 13:
        return "N";

        case 14:
        return "O";

        case 15:
        return "P";
    }
}
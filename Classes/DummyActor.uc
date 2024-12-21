class DummyActor extends actor;

var MutCMenu                     MyMut;

var bool bIsAuthorized, bNewTankPhys, bLoadExtras, bLoadGOM3, bLoadGOM4, bLoadWW;
var string TargetName;

var array<vector2d>				Corners;

replication
{
    if (bNetDirty)
        bIsAuthorized, bNewTankPhys, bLoadExtras, bLoadGOM3, bLoadGOM4, bLoadWW;
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
    // pc.Interactions.additem(new(pc) class'CMenuMap');

    pc.Interactions.additem(new(pc) class'CMenuBMain');
    pc.Interactions.additem(new(pc) class'CMenuBActors');
    pc.Interactions.additem(new(pc) class'CMenuBMeshes');
    pc.Interactions.additem(new(pc) class'CMenuBStructures');
    pc.Interactions.additem(new(pc) class'CMenuBVehicles');
    pc.Interactions.additem(new(pc) class'CMenuBWeapons');

    pc.Interactions.additem(new(pc) class'CMenuWeapons');

    pc.Interactions[pc.Interactions.Length] = pc.Interactions[0];
    pc.Interactions.remove(0, 1);
    
    for (i = 0; i < PC.Interactions.Length; i++)
    {
        if (InStr(PC.Interactions[i].name, "CMenu",,true) != -1)
        {
            CMenu(PC.Interactions[i]).PC = PC;
            CMenu(PC.Interactions[i]).MyDA = self;
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
            if (CMenu(PC.Interactions[i]).GetStateName() == 'MenuVisible')
            {
                CMenu(PC.Interactions[i]).GoToState('');
            }
            else 
            {
                CMenu(PC.Interactions[i]).bIsAuthorized = bAuthorized;
                CMenu(PC.Interactions[i]).TargetName = TName;
                CMenu(PC.Interactions[i]).GoToState('MenuVisible');
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
            CMenu(PC.Interactions[i]).SetCMenuColor(CMenuColor, Type);
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

reliable server function DeleteActor(actor ActorToDelete)
{
    `log("Deleting:"@ActorToDelete);
    //TraceGeometryWorldActors

    if(ActorToDelete == none)
        return;

    if(ActorToDelete.IsA('Terrain'))
        return;

    ActorToDelete.ShutDown();
    ActorToDelete.Destroy();
}

reliable server function SetActorCollision(actor ActorToDo)
{
    `log("Ghosting:"@ActorToDo);
    
    if(ActorToDo == none)
        return;

    if(ActorToDo.IsA('Terrain'))
        return;

    ActorToDo.SetCollision(false, false);
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
	CMPO = Spawn(class'CMAObjective',, SpawnTag, SpawnLocation, SpawnRotation, ObjTemplate);
	CMPO.Init(Corners);
	Corners.Remove(0, Corners.Length);

    foreach AllActors(class'DummyActor', DA)
    {
        DA.ClientSetupObj(CMPO);
    }
}

reliable server function ClientSetupObj(CMAObjective CMPO)
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
    local CMASpawn SMS;

    SMS = Spawn(class'CMASpawn', SpawnOwner, SpawnTag, SpawnLocation, SpawnRotation, ActorTemplate, bNoCollisionFail);
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
    optional string     SMesh,
    optional float      Scale)
{
    local CMSM CMSM;

    if (SpawnTag == 'StaticMesh')
    {
        CMSM =  CMSM(Spawn(SpawnClass, SpawnOwner, SpawnTag, SpawnLocation, SpawnRotation, ActorTemplate, bNoCollisionFail));
        CMSM.SetStaticMesh(StaticMesh(DynamicLoadObject(SMesh, class'StaticMesh')),,, CMSM.StaticMeshComponent.Scale3D*Scale);
    }
    /* else 
        CMSM.SetSkeletalMesh(SkeletalMesh(DynamicLoadObject(SMesh, class'SkeletalMesh'))); */
}

reliable server function ServerSpawnPickup(
    class<ROWeapon>    WeaponClass,
	optional vector     SpawnLocation,
	optional rotator    SpawnRotation,
    optional int        RespawnTime)
{
    local CMAPickupFactory CMAPF;

    CMAPF = Spawn(class'CMAPickupFactory',,, SpawnLocation, SpawnRotation);
    CMAPF.Time = RespawnTime;
    CMAPF.WPClass = WeaponClass;
    CMAPF.InitializePickup();
}

reliable server function ServerSpawnDecal(
    MaterialInterface DecalMaterial,
	vector DecalLocation,
	rotator DecalOrientation)
{
    local CMADecal Decal;
	local float Height;

    DecalLocation.x = FMin(Corners[Corners.Length-1].x, Corners[Corners.Length-2].x) + (Abs(Corners[Corners.Length-1].x - Corners[Corners.Length-2].x)/2);
	DecalLocation.y = FMin(Corners[Corners.Length-1].y, Corners[Corners.Length-2].y) + (Abs(Corners[Corners.Length-1].y - Corners[Corners.Length-2].y)/2);
	DecalLocation.z = DecalLocation.z;

	DecalOrientation.Yaw = (atan2(Corners[Corners.Length-1].y - Corners[Corners.Length-2].y , Corners[Corners.Length-1].x - Corners[Corners.Length-2].x)*RadToUnrRot);
	DecalOrientation.Pitch = 270*DegToUnrRot;
	DecalOrientation.Roll = 0;

	Height = V2DSize(Corners[Corners.Length-2] - Corners[Corners.Length-1]);

	Corners.Remove(0, Corners.Length);

    Decal = Spawn(class'CMADecal',,, DecalLocation, DecalOrientation);
    /* Decal.DecalLocation = DecalLocation;
    Decal.DecalOrientation = DecalOrientation;
    Decal.DecalLength = Height;
    Decal.DecalMaterial = DecalMaterial; */
    Decal.Initialize(DecalMaterial, DecalLocation, DecalOrientation, Height);

	`log(Decal);

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
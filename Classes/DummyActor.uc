class DummyActor extends actor;

var MutCMenu                     MyMut;

var bool bIsAuthorized, bNewTankPhys, bLoadExtras, bLoadGOM3, bLoadGOM4, bLoadWW, bLoadWW2;
var string TargetName;

var array<vector2d>				Corners;

replication
{
    if (bNetDirty)
        bIsAuthorized, bNewTankPhys, bLoadExtras, bLoadGOM3, bLoadGOM4, bLoadWW, bLoadWW2;
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
    pc.Interactions.additem(new(pc) class'CMenuFireSupport');

    pc.Interactions.additem(new(pc) class'CMenuBMain');
    pc.Interactions.additem(new(pc) class'CMenuBActors');
    pc.Interactions.additem(new(pc) class'CMenuBMeshes');
    pc.Interactions.additem(new(pc) class'CMenuBStructures');
    pc.Interactions.additem(new(pc) class'CMenuBVehicles');
    pc.Interactions.additem(new(pc) class'CMenuBPickups');

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

    // `log(TName);

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
    // `log (Command);
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
		ROMI.NorthernForce = MyNorthForce;
		CMGameReplicationInfo(WorldInfo.GRI).CampaignFactionOverrides[0] = MyNorthForce;
	}

	if( MySouthForce < 4 )
	{
		ROMI.SouthernForce = MySouthForce;
		CMGameReplicationInfo(WorldInfo.GRI).CampaignFactionOverrides[1] = MySouthForce;
	}

    ROMI.bInitializedRoles = false;
	ROMI.InitRolesForGametype(WorldInfo.GetGameClass(), 64, false);
}

reliable client function ClientFactionSetup(ENorthernForces MyNorthForce, ESouthernForces MySouthForce)
{
    FactionSetup(MyNorthForce, MySouthForce);
}

unreliable server function SpawnActor(
    class<actor>        SpawnClass,
	optional actor	    SpawnOwner,
	optional name       SpawnTag,
	optional vector     SpawnLocation,
	optional rotator    SpawnRotation,
	optional Actor      ActorTemplate,
	optional bool	    bNoCollisionFail,
    optional string     SMesh,
    optional float      Scale,
    optional int        ModifyTime)
{
    local CMAStaticMesh CMAStaticMesh;

    if (SpawnTag == 'StaticMesh')
    {
        CMAStaticMesh =  CMAStaticMesh(Spawn(SpawnClass, SpawnOwner, SpawnTag, SpawnLocation, SpawnRotation, ActorTemplate, bNoCollisionFail));
        CMAStaticMesh.ServerSetStaticMesh(StaticMesh(DynamicLoadObject(SMesh, class'StaticMesh')));
        CMAStaticMesh.ServerSetScale3D(CMAStaticMesh.StaticMeshComponent.Scale3D*Scale);
        CMAStaticMesh.Health = ModifyTime;
    }
    else if (SpawnTag == 'Turret')
    {
        Spawn(SpawnClass, SpawnOwner, SpawnTag, SpawnLocation, SpawnRotation, ActorTemplate, bNoCollisionFail);
    }
}

unreliable server function DeleteActor(actor ActorToDelete)
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

unreliable server function SetActorCollision(actor ActorToDo)
{
    `log("Ghosting:"@ActorToDo);
    
    if(ActorToDo == none)
        return;

    if(ActorToDo.IsA('Terrain'))
        return;

    ActorToDo.SetCollision(false, false);
}

unreliable server function ClearAllMeshes()
{
    local CMAStaticMesh MeshToClear;

    foreach AllActors(class'CMAStaticMesh', MeshToClear)
    {
        MeshToClear.Destroy();
    }
    `log("All static meshes have been cleared.");
}

unreliable server function SpawnVehicle(string VehicleName, vector PlaceLoc, rotator PlaceRot)
{
    local class<ROVehicle>          VehicleClass;
	local ROVehicle                 ROV;
    local ROPawn                    ROP;
    local bool                      bLandVic;

    ROP = ROPawn(PlayerController(Owner).Pawn);

    VehicleClass = class<ROVehicle>(DynamicLoadObject(VehicleName, class'Class'));
    
    if (ClassIsChildOf(VehicleClass, class'ROVehicleTreaded') || ClassIsChildOf(VehicleClass, class'ROVehicleWheeled'))
    {
        bLandVic = true;
    }
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

unreliable server function EnterVehicle()
{
    local ROVehicle                 ROV;
    local PlayerController          PC;
    local Pawn                      P;
    local vector                    ViewDirection, StartTrace, EndTrace, HitLocation, HitNormal;
    local rotator                   PRot;
    local actor                     TracedActor;
    local bool                      bEnteredVehicle;
    local float                     TraceLength;

    PC = PlayerController(Owner);

    PC.GetPlayerViewPoint(StartTrace, PRot);
    ViewDirection = Vector(PC.Pawn.GetViewRotation());
    TraceLength = 2000;
    EndTrace = StartTrace + ViewDirection * TraceLength;

    P = PC.Pawn;

    // Trace for nearest vehicle
	TracedActor = PC.trace(HitLocation, HitNormal, EndTrace, StartTrace, true);

    ROV = ROVehicle(TracedActor);

    if (ROV == none)
    {
        return;
    }

    if (!ROV.bIsDisabled && (!ROV.bTeamLocked || !WorldInfo.Game.bTeamGame || WorldInfo.GRI.OnSameTeam(self, P)))
	{

		if( !ROV.AnySeatAvailable() )
		{
			return;
		}

		bEnteredVehicle = (ROV.Driver == None) ? ROV.DriverEnter(P) : ROV.PassengerEnter(P, ROV.GetFirstAvailableSeat());

		if( bEnteredVehicle )
		{
			ROV.SetTexturesToBeResident( true );
		}

		return;
	}
}

reliable server function ClearAllVehicles()
{
    local ROVehicle VehicleToClear;

    foreach AllActors(class'ROVehicle', VehicleToClear)
    {
        VehicleToClear.Destroy();
    }
    `log("All vehicles have been cleared.");
}

reliable server function SpawnPickup(class<ROWeapon> WeaponClass, float ModifyTime, vector PlaceLoc, rotator PlaceRot)
{
    local CMAPickupFactory CMAPF;

    CMAPF = Spawn(class'CMAPickupFactory',,, PlaceLoc, PlaceRot);
    CMAPF.Time = ModifyTime;
    CMAPF.WPClass = WeaponClass;
    if (WorldInfo.NetMode == NM_Standalone)
        CMAPF.InitializePickup();
}

reliable server function ClearAllPickups()
{
    local CMAPickupFactory WeaponToClear;

    foreach AllActors(class'CMAPickupFactory', WeaponToClear)
    {
        WeaponToClear.Destroy();
    }
    `log("All weapon pickups have been cleared.");
}

function SetCorner(vector PlaceLoc, rotator PlaceRot)
{
    local vector2d Point2d;

    Point2d.x = PlaceLoc.x;
    Point2d.y = PlaceLoc.y;
    Corners.AddItem(Point2d);

    SpawnActor(class'CMAStaticMesh',,'StaticMesh', PlaceLoc, PlaceRot,,, "ENV_VN_Flags.Meshes.S_VN_Flagpole");
}

unreliable server function PlaceSpawn(
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

unreliable server function SpawnDecal(
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

unreliable server function ClearAllActors()
{
    local Actor ActorToClear;

    foreach AllActors(class'Actor', ActorToClear)
    {
        if (ActorToClear.IsA('CMASpawn') || ActorToClear.IsA('CMAObjective') || ActorToClear.IsA('DecalActor'))
        {
            ActorToClear.Destroy();
        }
    }
    `log("All actors have been cleared.");
}

/* reliable server function ServerSpawnOBJ(
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
	ObjTemplate = CMAObjective(DynamicLoadObject("MutCMenuPkg.Objectives.OBJ"$MyMut.NumObjs+1, class'CMAObjective'));
	MyMut.NumObjs++;
    `log(ObjTemplate);
	CMPO = Spawn(class'CMAObjective',, SpawnTag, SpawnLocation, SpawnRotation, ObjTemplate);
	CMPO.Init(Corners);
	Corners.Remove(0, Corners.Length);

    foreach AllActors(class'DummyActor', DA)
    {
        DA.ClientSetupObj(CMPO);
    }
} */

function ClientSetupObj(CMAObjective CMPO)
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
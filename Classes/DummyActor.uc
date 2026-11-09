class DummyActor extends actor
    dependson(CMBuilderCatalogue);

var MutCMenu                     MyMut;

// The Builder (see the server side further down)
const MIN_PIECE_SCALE = 0.1;
const MAX_PIECE_SCALE = 10.0;
const BUILT_VEHICLE_TAG = 'CMBuilderVehicle'; // vehicles placed with the Builder, which players may remove again
const MAX_PIECE_HEALTH = 100000;
var string LastTold;         // Server side: the last Builder refusal this player was told, and when (the same one only once a second)
var float LastToldTime;

// The Builder's match rules, sent by the server for this player's preview and hints panel (MutCMenu.UpdateBuilderInfo)
var byte BuilderMode;
var bool bBuildPhaseOpen, bBuilderPiecesOnly, bBuilderBudgets, bBuilderZones;
var int BuildPointsLeft, BuildPointsTotal;

var bool bIsAuthorized, bNewTankPhys, bLoadExtras, bLoadGOM3, bLoadGOM4, bLoadWW, bLoadWW2, bFSPlayersCanCall;
var bool bClickModeActive;
var bool bTankPromptForAll; // the server lets anyone use the tank entry prompt, not only tank crew
var vector2D ClickCursor;     // where the menus' mouse pointer was left, so the next menu opens with it there
var bool bClickCursorKnown;
var string TargetName;

// var CMenuTextEntryScene TextEntryScene; // text-entry dialog disabled for now

var array<vector2d>				Corners;               // Server side: the corners this player has marked so far
var array<CMAStaticMesh>			CornerMarkers;         // and the poles standing on them
var float                       LastFlagTime;          // Server side: when this player last placed a CTF flag (for the wait between flags)

var string PendingHelp; // client-side: help received in pieces, waiting for ClientShowHelp
var string PendingLookCommand; // server-side: the command waiting for ServerLookTarget (MutCMenu.AskClientForLook)

// Client side: the Builder's catalogue the server sent, when it has its own (otherwise the built-in one is used)
var array<BuilderPiece> ServerCatalogue;
var bool bServerCatalogue;

replication
{
    if (bNetDirty)
        bIsAuthorized, bNewTankPhys, bLoadExtras, bLoadGOM3, bLoadGOM4, bLoadWW, bLoadWW2, bFSPlayersCanCall, bTankPromptForAll,
        BuilderMode, bBuildPhaseOpen, bBuilderPiecesOnly, bBuilderBudgets, bBuilderZones, BuildPointsLeft, BuildPointsTotal;
}

// Guidance up to this size goes to the chat and the mini console; anything longer goes to the large console
const HELP_MAX_SHORT_LINES = 4;
const HELP_MAX_SHORT_CHARS = 320;

// Shows guidance for a command and pre-types the command. Prompt lines are separated by "|".
// Short guidance: private chat messages (they also land in the console history) and the one-line mini console.
// Long guidance: written to the console history and shown in the large console, where it can be scrolled while typing.
simulated function ShowHelp(string Prompt, string Prefix, string Suffix, string LinePrefix)
{
    local PlayerController PC;
    local array<string> Lines;
    local GameViewportClient VC;
    local Console ViewConsole;
    local int i;

    PC = PlayerController(Owner);
    if (PC == None)
        return;

    Lines = SplitString(Prompt, "|", true);

    if (LocalPlayer(PC.Player) != None)
        VC = LocalPlayer(PC.Player).ViewportClient;
    if (VC != None)
        ViewConsole = VC.ViewportConsole;

    if (ViewConsole == None)
    {
        // No console to drive: fall back to chat lines
        for (i = 0; i < Lines.Length; i++)
            PC.ClientMessage(i == 0 ? LinePrefix$Lines[i] : Lines[i]);
        if (Prefix != "")
            PC.ClientMessage("Type in the console (~):  "$Prefix$Suffix);
        return;
    }

    if (Lines.Length > HELP_MAX_SHORT_LINES || Len(Prompt) > HELP_MAX_SHORT_CHARS)
    {
        ViewConsole.OutputText("");
        for (i = 0; i < Lines.Length; i++)
            ViewConsole.OutputText(i == 0 ? LinePrefix$Lines[i] : "    "$Lines[i]);

        // The same state the console key opens (the large console, with history)
        ViewConsole.GotoState('Open');
    }
    else
    {
        for (i = 0; i < Lines.Length; i++)
            PC.ClientMessage(i == 0 ? LinePrefix$Lines[i] : Lines[i]);

        // The one-line typing bar
        ViewConsole.GotoState('Typing');
    }

    ViewConsole.SetInputText(Prefix$Suffix);
    ViewConsole.SetCursorPos(Len(Prefix));
}

// Server to client: used for help from the mutators, so they don't have to flood the chat
// Long help arrives in pieces (MutCMenu.ShowHelpToPlayer): one function call can only carry so much over the network,
// and a longer one is dropped ("RPC bunch overflowed"). The pieces are kept here until ClientShowHelp shows them.
reliable client function ClientAddHelpPart(string Part)
{
    PendingHelp $= Part;
}

reliable client function ClientShowHelp(string Prompt, string Prefix, string Suffix, string LinePrefix)
{
    Prompt = PendingHelp$Prompt;
    PendingHelp = "";
    ShowHelp(Prompt, Prefix, Suffix, LinePrefix);
}

// A command needs to know where the player is looking. Their own game knows where its camera really is (the server's
// idea of a spectator's view is the watched player), so it is asked.
function RequestLookTarget(string Command)
{
    PendingLookCommand = Command;
    ClientSendLookTarget();
}

// The spot the camera's line first hits on the ground or a building (players and vehicles are passed through, so a
// spectator's line isn't stopped by the player they watch)
reliable client function ClientSendLookTarget()
{
    local PlayerController PC;
    local vector ViewLoc, HitLoc, HitNormal;
    local rotator ViewRot;

    PC = PlayerController(Owner);
    if (PC == None)
        return;
    PC.GetPlayerViewPoint(ViewLoc, ViewRot);
    if (Trace(HitLoc, HitNormal, ViewLoc + vector(ViewRot) * 100000.0, ViewLoc, false) != None)
        ServerLookTarget(true, HitLoc, HitNormal);
    else
        ServerLookTarget(false, vect(0, 0, 0), vect(0, 0, 1));
}

reliable server function ServerLookTarget(bool bHit, vector Target, vector Normal)
{
    local string Command;

    Command = PendingLookCommand;
    PendingLookCommand = "";
    if (Command != "" && MyMut != None && PlayerController(Owner) != None)
        MyMut.RunWithClientLook(PlayerController(Owner), Command, bHit, Target, Normal);
}

reliable client function ClientClearCatalogue()
{
    ServerCatalogue.Length = 0;
    bServerCatalogue = true;
}

reliable client function ClientAddCataloguePiece(string Category, string Label, string Mesh, int Cost, int Health)
{
    local BuilderPiece P;

    if (ServerCatalogue.Length >= class'CMBuilderCatalogue'.const.MAX_PIECES)
        return;
    P.Category = Category;
    P.Label = Label;
    P.Mesh = Mesh;
    P.Cost = Cost;
    P.Health = Health;
    ServerCatalogue.AddItem(P);
    bServerCatalogue = true;
}

// The Builder's catalogue in this player's game: the server's, or the built-in one
simulated function GetBuilderPieces(out array<BuilderPiece> List)
{
    if (bServerCatalogue)
        List = ServerCatalogue;
    else
        List = class'CMBuilderCatalogue'.default.Pieces;
}

reliable client function CMenuSetup()
{
    local PlayerController PC;
    local TankEntryInteraction TankEntry;
    local FlagCarrierInteraction FlagCarrier;
    local int i;

    PC = PlayerController(Owner);

    // A repeat call (a new level, a re-login) must not stack a second copy of every menu on top of the first
    for (i = PC.Interactions.Length - 1; i >= 0; i--)
    {
        if (CMenu(PC.Interactions[i]) != None || TankEntryInteraction(PC.Interactions[i]) != None
            || FlagCarrierInteraction(PC.Interactions[i]) != None)
            PC.Interactions.Remove(i, 1);
    }

    pc.Interactions.additem(new(pc) class'CMenuMain');
    pc.Interactions.additem(new(pc) class'CMenuGeneral');
    pc.Interactions.additem(new(pc) class'CMenuSettings');

    pc.Interactions.additem(new(pc) class'CMenuParadrops');
    pc.Interactions.additem(new(pc) class'CMenuRealismMatch');
    pc.Interactions.additem(new(pc) class'CMenuRMControl');
    pc.Interactions.additem(new(pc) class'CMenuRMRound');
    pc.Interactions.additem(new(pc) class'CMenuRMObjectives');
    pc.Interactions.additem(new(pc) class'CMenuRMTeams');
    pc.Interactions.additem(new(pc) class'CMenuPlayer');
    pc.Interactions.additem(new(pc) class'CMenuPCManager');
    pc.Interactions.additem(new(pc) class'CMenuFireSupport');

    pc.Interactions.additem(new(pc) class'CMenuBMain');
    pc.Interactions.additem(new(pc) class'CMenuBActors');
    pc.Interactions.additem(new(pc) class'CMenuBFlags');
    pc.Interactions.additem(new(pc) class'CMenuBMeshes');
    pc.Interactions.additem(new(pc) class'CMenuBStructures');
    pc.Interactions.additem(new(pc) class'CMenuBVehicles');
    pc.Interactions.additem(new(pc) class'CMenuBPickups');

    pc.Interactions.additem(new(pc) class'CMenuWeapons');

    TankEntry = new(pc) class'TankEntryInteraction';
    TankEntry.PC = PC;
    TankEntry.MyDA = self;
    pc.Interactions.additem(TankEntry);

    FlagCarrier = new(pc) class'FlagCarrierInteraction';
    FlagCarrier.PC = PC;
    FlagCarrier.MyDA = self;
    pc.Interactions.additem(FlagCarrier);

    // The game's own input goes last, so the menus see their keys first. It is found by name: something else (the
    // MutExtras map drawing tool) may already sit in front of it, and moving that instead would leave the menus behind.
    i = pc.Interactions.Find(pc.PlayerInput);
    if (i == INDEX_NONE)
        i = 0;
    pc.Interactions[pc.Interactions.Length] = pc.Interactions[i];
    pc.Interactions.remove(i, 1);

    for (i = 0; i < PC.Interactions.Length; i++)
    {
        if (InStr(PC.Interactions[i].name, "CMenu",,true) != -1)
        {
            CMenu(PC.Interactions[i]).PC = PC;
            CMenu(PC.Interactions[i]).MyDA = self;
            // CMenu(PC.Interactions[i]).TextEntryScene = TextEntryScene; // text-entry dialog disabled for now
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

// ====================================================
// The Builder's server side
// ====================================================
// Everything the Builder does arrives here from the player's game, so everything is checked here: the menu only hides
// the entries a player may not use. Placing follows the server's build rules (MutCMenu.MayBuild); clearing, deleting
// what isn't a Builder piece and collision are for admins. All of it is reliable: a placement or a clear sent
// unreliably could be lost on a bad connection (a pasted structure arrived with pieces missing).

function bool CallerIsAdmin()
{
    return MyMut != None && MyMut.IsAuthorized(PlayerController(Owner));
}

// True when the caller may place things now; otherwise they are told why
function bool CallerMayBuild(optional name What, optional vector Loc, optional bool bAtLoc)
{
    local string Why;

    if (MyMut == None)
        return false;
    if (MyMut.MayBuild(PlayerController(Owner), Why, What, Loc, bAtLoc))
        return true;
    TellBuilder(Why);
    return false;
}

// A Builder refusal, told once: a pasted structure's pieces would otherwise repeat it for every piece
function TellBuilder(string Why)
{
    if (Why == LastTold && WorldInfo.TimeSeconds - LastToldTime < 1.0)
        return;
    LastTold = Why;
    LastToldTime = WorldInfo.TimeSeconds;
    MyMut.PrivateMessage(PlayerController(Owner), "[CMenu] "$Why);
}

// True when the caller is an admin; otherwise they are told that What is for admins
function bool CallerIsAdminFor(string What)
{
    if (CallerIsAdmin())
        return true;
    if (MyMut != None)
        MyMut.PrivateMessage(PlayerController(Owner), "[CMenu] Only admins can "$What$".");
    return false;
}

// The client sends what to spawn, so only the Builder's own classes are taken; the owner and template it sends are not
reliable server function SpawnActor(
    class<actor>        SpawnClass,
	optional actor	    SpawnOwner,
	optional name       SpawnTag,
	optional vector     SpawnLocation,
	optional rotator    SpawnRotation,
	optional Actor      ActorTemplate,
	optional bool	    bNoCollisionFail,
    optional string     SMesh,
    optional float      Scale,
    optional int        ModifyTime,
    optional vector     Scale3D)    // a mesh's own scale on each axis (a pasted structure's pieces); Scale when not given
{
    local CMAStaticMesh Piece;
    local StaticMesh SM;
    local int Cost, CatalogueHealth;
    local byte Team;
    local string Why;

    if (!CallerMayBuild(SpawnTag == 'StaticMesh' ? 'Mesh' : 'Turret', SpawnLocation, true))
        return;

    if (SpawnTag == 'StaticMesh')
    {
        SM = StaticMesh(DynamicLoadObject(SMesh, class'StaticMesh', true));
        if (SM == None)
        {
            MyMut.PrivateMessage(PlayerController(Owner), "[CMenu] There is no mesh called "$SMesh$".");
            return;
        }
        if (!MyMut.MayPlacePiece(PlayerController(Owner), PathName(SM), Cost, CatalogueHealth, Team, Why))
        {
            TellBuilder(Why);
            return;
        }
        if (Scale <= 0.0)
            Scale = 1.0;
        Scale = FClamp(Scale, MIN_PIECE_SCALE, MAX_PIECE_SCALE);

        Piece = Spawn(class'CMAStaticMesh',, 'StaticMesh', SpawnLocation, SpawnRotation,, true);
        if (Piece == None)
        {
            MyMut.PrivateMessage(PlayerController(Owner), "[CMenu] That can't be placed there.");
            return;
        }
        Piece.bBuilderPiece = true;
        Piece.PlacedByID = (PlayerController(Owner).PlayerReplicationInfo != None) ? PlayerController(Owner).PlayerReplicationInfo.PlayerID : -1;
        Piece.ServerSetStaticMesh(SM);
        if (VSizeSq(Scale3D) > 0)
        {
            Scale3D.X = FClamp(Abs(Scale3D.X), MIN_PIECE_SCALE, MAX_PIECE_SCALE);
            Scale3D.Y = FClamp(Abs(Scale3D.Y), MIN_PIECE_SCALE, MAX_PIECE_SCALE);
            Scale3D.Z = FClamp(Abs(Scale3D.Z), MIN_PIECE_SCALE, MAX_PIECE_SCALE);
            Piece.ServerSetScale3D(Scale3D);
        }
        else
            Piece.ServerSetScale3D(Piece.StaticMeshComponent.Scale3D * Scale);
        Piece.Health = (CatalogueHealth >= 0) ? CatalogueHealth : Clamp(ModifyTime, 0, MAX_PIECE_HEALTH);

        // Never on top of a soldier: they would be stuck inside it
        Piece.ForceUpdateComponents(true, false);
        if (SoldierInside(Piece))
        {
            Piece.Destroy();
            TellBuilder("That can't go there: a soldier is in the way.");
            return;
        }
        Piece.BuiltByTeam = Team;
        Piece.PaidCost = Cost;
        Piece.StartHealth = Piece.Health;
        if (Cost > 0)
            MyMut.UpdateBuilderInfo();
    }
    else if ((SpawnTag == 'Turret' && (SpawnClass == class'CMATurret_M2_HMG_Destroyable' || SpawnClass == class'ROTurret_DShK_HMG_Destroyable'))
        || (SpawnTag == 'ResupplyPoint' && SpawnClass == class'CMAResupplyPoint'))
    {
        Spawn(SpawnClass,, SpawnTag, SpawnLocation, SpawnRotation,, true);
    }
}

// A living soldier (or vehicle) stands where the piece is: their body overlaps its collision. A little smaller than the
// body, so a wall built right up against someone is still fine. Used by the server (the placed piece) and by the
// player's game for the red preview (C is the preview); Tester is any actor (the check doesn't depend on it).
static function bool PawnInPiece(Actor Tester, Pawn P, PrimitiveComponent C)
{
    local vector Extent;
    local float Radius, Height;

    if (Tester == None || P == None || P.bDeleteMe || P.Health <= 0 || C == None)
        return false;
    P.GetBoundingCylinder(Radius, Height);
    Extent.X = Radius * 0.75;
    Extent.Y = Extent.X;
    Extent.Z = Height * 0.9;
    return Tester.PointCheckComponent(C, P.Location, Extent);
}

function bool SoldierInside(CMAStaticMesh Piece)
{
    local Pawn P;

    foreach WorldInfo.AllPawns(class'Pawn', P, Piece.StaticMeshComponent.Bounds.Origin, Piece.StaticMeshComponent.Bounds.SphereRadius + 200)
    {
        if (PawnInPiece(self, P, Piece.StaticMeshComponent))
            return true;
    }
    return false;
}

// What may be removed with the Builder's delete entries: a Builder piece or a vehicle the Builder placed, by anyone who
// may build (a vehicle only while nobody is in it); anything else that isn't part of the map, by an admin. Never a
// soldier, a controller, the game's own actors or a part of the map: a map part can't be removed for the players at all
// (it isn't replicated), so the server would only have turned it into an invisible hole for itself.
function bool MayDelete(Actor A, bool bAdmin, out string Why)
{
    local Vehicle V;

    V = Vehicle(A);
    if (A == None || A.bDeleteMe)
    {
        Why = "There is nothing there to remove.";
        return false;
    }
    if ((Pawn(A) != None && V == None) || Controller(A) != None || Info(A) != None || A.IsA('Terrain'))
    {
        Why = "That can't be removed.";
        return false;
    }
    if (A.bStatic || A.bNoDelete)
    {
        Why = "That is part of the map, so it can't be removed.";
        return false;
    }
    if (bAdmin)
        return true;
    if (CMAStaticMesh(A) != None && CMAStaticMesh(A).bBuilderPiece)
    {
        // With the match rules on, only your own team's pieces
        if (MyMut.BuilderMatchRules() && CMAStaticMesh(A).BuiltByTeam != 255
            && CMAStaticMesh(A).BuiltByTeam != class'CMMapInfo'.static.PlayingTeam(PlayerController(Owner).PlayerReplicationInfo))
        {
            Why = "That piece belongs to the other team.";
            return false;
        }
        return true;
    }
    if (V != None && V.Tag == BUILT_VEHICLE_TAG)
    {
        if (V.Driver == None && (ROVehicle(V) == None || ROVehicle(V).NumPassengers() == 0))
            return true;
        Why = "Someone is in that vehicle.";
        return false;
    }
    Why = "Only admins can remove that.";
    return false;
}

reliable server function DeleteActor(actor ActorToDelete)
{
    local string Why;
    local bool bAdmin;

    bAdmin = CallerIsAdmin();
    if (!bAdmin && !CallerMayBuild('Delete'))
        return;
    if (!MayDelete(ActorToDelete, bAdmin, Why))
    {
        MyMut.PrivateMessage(PlayerController(Owner), "[CMenu] "$Why);
        return;
    }
    ActorToDelete.ShutDown();
    ActorToDelete.Destroy();
    MyMut.UpdateBuilderInfo(); // a piece's points go back to its team
}

// Admins: a Builder piece stops (or starts again) blocking players and bullets, for every player (the actor's collision
// replicates). Parts of the map are refused: changed on the server only, players' games kept colliding and rubber-banded.
reliable server function SetActorCollision(actor ActorToDo)
{
    local CMAStaticMesh Piece;

    if (!CallerIsAdminFor("change collision"))
        return;
    Piece = CMAStaticMesh(ActorToDo);
    if (Piece == None || !Piece.bBuilderPiece)
    {
        MyMut.PrivateMessage(PlayerController(Owner), "[CMenu] Collision can only be changed on pieces placed with the Builder.");
        return;
    }
    Piece.SetCollision(!Piece.bCollideActors, !Piece.bBlockActors);
    MyMut.PrivateMessage(PlayerController(Owner), "[CMenu] Collision "$(Piece.bCollideActors ? "on" : "off")$" for that piece.");
}

// Admins: every mesh piece placed with the Builder; resupply points, spawns and objective corner poles stay
reliable server function ClearAllMeshes()
{
    local CMAStaticMesh MeshToClear;
    local int Count;

    if (!CallerIsAdminFor("clear all meshes"))
        return;
    foreach AllActors(class'CMAStaticMesh', MeshToClear)
    {
        if (MeshToClear.bBuilderPiece && MeshToClear.Class == class'CMAStaticMesh')
        {
            MeshToClear.Destroy();
            Count++;
        }
    }
    MyMut.PrivateMessage(PlayerController(Owner), "[CMenu] Cleared "$Count$" mesh piece"$(Count == 1 ? "" : "s")$".");
    MyMut.UpdateBuilderInfo();
}

reliable server function SpawnVehicle(string VehicleName, vector PlaceLoc, rotator PlaceRot)
{
    local class<ROVehicle>          VehicleClass;
	local ROVehicle                 ROV;
    local ROPawn                    ROP;
    local bool                      bLandVic;

    if (!CallerMayBuild('Vehicle', PlaceLoc, true))
        return;
    ROP = ROPawn(PlayerController(Owner).Pawn);

    VehicleClass = class<ROVehicle>(DynamicLoadObject(VehicleName, class'Class', true));
    if (VehicleClass == None)
    {
        MyMut.PrivateMessage(PlayerController(Owner), "[CMenu] There is no vehicle called "$VehicleName$".");
        return;
    }

    if (ClassIsChildOf(VehicleClass, class'ROVehicleTreaded') || ClassIsChildOf(VehicleClass, class'ROVehicleWheeled'))
    {
        bLandVic = true;
    }
    if (VehicleClass != none)
    {
        ROV = Spawn(VehicleClass, , BUILT_VEHICLE_TAG, PlaceLoc, PlaceRot);
        if (ROV == None)
        {
            MyMut.PrivateMessage(PlayerController(Owner), "[CMenu] That vehicle can't be placed there.");
            return;
        }
        ROV.Mesh.AddImpulse(vect(0,0,1), ROV.Location);
        ROV.bTeamLocked = false;

        // ROV.GroundSpeed=520
	    // ROV.MaxSpeed=940 //67 km/h

        if (bLandVic && bNewTankPhys)
        {
            ROV.Mesh.SetRBCollidesWithChannel(RBCC_Default, false);
            ROV.Mesh.SetRBCollidesWithChannel(RBCC_BlockingVolume, false);
        }

        if (VehicleName ~= "WinterWar.WWVehicle_Skis_ActualContent" && ROP != None)
        {
            ROV.TryToDrive(ROP);
        }
    }
}

// The role class a tank lets in, for the tanks that let in only one: WW2's (9) and Winter War's (8). 255 for the rest.
static function byte CrewClassIndexFor(ROVehicle ROV)
{
    if (ROV == None)
        return 255;
    if (ROV.IsA('WW2VehicleTank'))
        return 9;
    if (ROV.IsA('WWVehicleTank'))
        return 8;
    return 255;
}

// Server side of the flag carrier's drop key (FlagCarrierInteraction): the same as "mutate dropflag"
reliable server function DropCarriedFlag()
{
    if (MyMut != None && PlayerController(Owner) != None)
        MyMut.DropFlagCommand(PlayerController(Owner));
}

// Server side of the tank entry prompt (TankEntryInteraction). Gets past the game's gates on tanks (bInfantryCanUse, and
// the one role class WW2 and Winter War tanks let in) but keeps the normal TryToDrive checks: a free seat, no enemies
// aboard, not prone, the vehicle's own team lock. Returns whether the player got in.
reliable server function EnterVehicle(ROVehicle ROV)
{
    local ROPlayerController ROPC;

    ROPC = ROPlayerController(Owner);
    if (ROPC != None && TryEnterVehicle(ROPC, ROV))
    {
        ROPC.ClientStartExitVehicleFadeOut();
        ROPC.SetTimer(0.25, false, 'ClientStartExitVehicleFadeIn');
    }
}

function bool TryEnterVehicle(ROPlayerController ROPC, ROVehicle ROV)
{
    local ROPawn ROP;
    local ROPlayerReplicationInfo ROPRI;
    local byte CrewIndex, OldIndex;
    local bool bEntered;

    ROP = (ROPC != none) ? ROPawn(ROPC.Pawn) : none;
    if (ROP == none || ROP.Health <= 0 || ROP.bIsProning || ROP.IsProneTransitioning())
        return false;
    if (!class'TankEntryInteraction'.static.AllowedToUse(ROPC.PlayerReplicationInfo, MyMut != None && MyMut.bTankPromptForAll))
        return false;

    // The client picks the tank, so everything is checked again here
    if (ROV == none || ROV.bDeadVehicle || VSize(ROV.Location - ROP.Location) > 1000
        || VSizeSq(ROV.Velocity) >= class'ROVehicle'.const.MAX_SPEED_FOR_ENTRY_SQ)
        return false;
    if (ROV.Team != ROPC.GetTeamNum() && !class'TankEntryInteraction'.static.IsEmpty(ROV))
        return false;

    // A WW2 or Winter War tank asks for its crew class: the player's role has it for the moment of getting in only. The
    // role is shared by everyone playing it, and nothing else runs in between, so nobody else ever sees the change.
    ROPRI = ROPlayerReplicationInfo(ROPC.PlayerReplicationInfo);
    CrewIndex = CrewClassIndexFor(ROV);
    if (CrewIndex != 255 && ROPRI != None && ROPRI.RoleInfo != None)
    {
        OldIndex = ROPRI.RoleInfo.ClassIndex;
        ROPRI.RoleInfo.ClassIndex = CrewIndex;
        bEntered = ROV.TryToDrive(ROP);
        ROPRI.RoleInfo.ClassIndex = OldIndex;
        return bEntered;
    }
    return ROV.TryToDrive(ROP);
}

reliable server function ClearAllVehicles()
{
    local ROVehicle VehicleToClear;

    if (!CallerIsAdminFor("clear all vehicles"))
        return;

    foreach AllActors(class'ROVehicle', VehicleToClear)
    {
        VehicleToClear.Destroy();
    }
    `log("All vehicles have been cleared.");
}

reliable server function SpawnPickup(class<ROWeapon> WeaponClass, float ModifyTime, vector PlaceLoc, rotator PlaceRot)
{
    local CMAPickupFactory CMAPF;

    if (WeaponClass == None || !CallerMayBuild('Pickup', PlaceLoc, true))
        return;
    CMAPF = Spawn(class'CMAPickupFactory',,, PlaceLoc, PlaceRot);
    if (CMAPF == None)
        return;
    CMAPF.Time = ModifyTime;
    CMAPF.WPClass = WeaponClass;
    if (WorldInfo.NetMode == NM_Standalone)
        CMAPF.InitializePickup();
}

reliable server function ClearAllPickups()
{
    local CMAPickupFactory WeaponToClear;

    if (!CallerIsAdminFor("clear all pickups"))
        return;

    foreach AllActors(class'CMAPickupFactory', WeaponToClear)
    {
        WeaponToClear.Destroy();
    }
    `log("All weapon pickups have been cleared.");
}

// Marks one corner for an objective (or the ends of a decal): a flagpole stands there for everyone to see, and the caller is told.
// It runs on the server. It used to run on the player's own game, where the pole could not be placed for anyone.
reliable server function ServerMarkCorner(vector PlaceLoc, rotator PlaceRot)
{
    local vector2d Point2d;
    local CMAStaticMesh Marker;
    local PlayerController PC;

    PC = PlayerController(Owner);
    if (MyMut == None || PC == None)
        return;

    // Only admins build objectives, so only they mark corners (each one stands a pole for everyone)
    if (!MyMut.IsAuthorized(PC))
    {
        MyMut.PrivateMessage(PC, "[CMenu] Only admins can mark objective corners");
        return;
    }
    if (Corners.Length >= class'CMAObjective'.const.MAX_CORNER_COUNT)
    {
        MyMut.PrivateMessage(PC, "[CMenu] An objective can have at most "$class'CMAObjective'.const.MAX_CORNER_COUNT$" corners. Use Spawn Obj, or Clear Corners to start again");
        return;
    }

    Point2d.x = PlaceLoc.x;
    Point2d.y = PlaceLoc.y;

    // Marking the same spot again does not count as a new corner
    if (Corners.Length > 0 && V2DSize(Corners[Corners.Length - 1] - Point2d) < class'CMAObjective'.const.MIN_CORNER_GAP)
    {
        MyMut.PrivateMessage(PC, "[CMenu] That is the same spot as your last corner. Move to the next corner and mark it");
        return;
    }

    Marker = Spawn(class'CMAStaticMesh',, 'StaticMesh', PlaceLoc, PlaceRot,, true);
    if (Marker == None)
    {
        MyMut.PrivateMessage(PC, "[CMenu] The corner marker could not be placed there. Try a spot nearby");
        return;
    }
    Marker.ServerSetStaticMesh(StaticMesh'ENV_VN_Flags.Meshes.S_VN_Flagpole');
    Marker.SetCollision(false, false); // So it never gets in the way of the next corner
    Marker.Health = 0;

    Corners.AddItem(Point2d);
    CornerMarkers.AddItem(Marker);

    if (Corners.Length < class'CMAObjective'.const.MIN_CORNER_COUNT)
        MyMut.PrivateMessage(PC, "[CMenu] Corner "$Corners.Length$" marked. Mark at least "$(class'CMAObjective'.const.MIN_CORNER_COUNT - Corners.Length)$" more, then use Spawn Objective");
    else
        MyMut.PrivateMessage(PC, "[CMenu] Corner "$Corners.Length$" marked. Mark more corners, or use Spawn Objective to build the objective");
}

// Takes away the corner poles and forgets the corners
function ClearCornerMarkers()
{
    local int I;

    for (I = 0; I < CornerMarkers.Length; I++)
    {
        if (CornerMarkers[I] != None)
            CornerMarkers[I].Destroy();
    }
    CornerMarkers.Remove(0, CornerMarkers.Length);
    Corners.Remove(0, Corners.Length);
}

// The Builder's Clear Corners (and mutate clearcorners): start the corners again
reliable server function ServerClearCorners()
{
    local PlayerController PC;
    local int Count;

    PC = PlayerController(Owner);
    if (MyMut == None || PC == None)
        return;
    Count = Corners.Length;
    ClearCornerMarkers();
    MyMut.PrivateMessage(PC, "[CMenu] Cleared "$Count$" marked corner"$(Count == 1 ? "" : "s"));
}

event Destroyed()
{
    ClearCornerMarkers();
    Super.Destroyed();
}

reliable server function PlaceSpawn(
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

    if (!CallerMayBuild('Spawn', SpawnLocation, true))
        return;
    SMS = Spawn(class'CMASpawn',, SpawnTag, SpawnLocation, SpawnRotation,, bNoCollisionFail);
	if (SMS != None)
		SMS.SetSpawnTeam(TeamIdx);
}

reliable server function ClearAllActors()
{
    local Actor ActorToClear;

    if (!CallerIsAdminFor("clear all actors"))
        return;

    foreach AllActors(class'Actor', ActorToClear)
    {
        if (ActorToClear.IsA('CMASpawn') || ActorToClear.IsA('CMAObjective') || ActorToClear.IsA('CMAFlag'))
        {
            ActorToClear.Destroy();
        }
    }
    `log("All actors have been cleared.");
}

// The Builder's Capture the Flag entries. Anyone can place a flag; only clearing them is for admins. TeamIdx 0 or 1 is
// that team's flag, anything else the neutral flag. The rest are the flag's options from the CTF Flags menu's switches.
reliable server function ServerPlaceFlag(vector PlaceLoc, int TeamIdx, optional bool bBeam, optional bool bAnnounce,
    optional byte MapTeams, optional int MapDelay, optional bool bMapWhileCarried)
{
    local PlayerController PC;
    local int Faction;

    PC = PlayerController(Owner);
    if (MyMut == None || PC == None)
        return;

    if (TeamIdx == `AXIS_TEAM_INDEX || TeamIdx == `ALLIES_TEAM_INDEX)
        Faction = class'CMAFlag'.static.FactionForTeam(WorldInfo, TeamIdx);
    else
        Faction = class'CMAFlag'.const.FAC_NEUTRAL;
    MyMut.PlaceFlag(PC, PlaceLoc, Faction, bBeam, bAnnounce, MapTeams, Clamp(MapDelay, 0, 3600), bMapWhileCarried);
}

// Builds a capture objective from the corners the builder marked. Checked here too: anyone can open the Builder and call this.
// The name, capture time and starting owner are as for CMAObjective.Init (blank, 0 and -1 are the defaults).
reliable server function ServerSpawnObjective(vector SpawnLocation, array<Vector2D> ObjectiveCorners, optional string ObjName,
    optional int CapTime, optional int OwnerTeam = -1)
{
    local CMAObjective CMPO;
    local PlayerController PC;

    PC = PlayerController(Owner);
    if (MyMut == None || PC == None)
        return;

    if (!MyMut.IsAuthorized(PC))
    {
        MyMut.PrivateMessage(PC, "[CMenu] Only admins can build objectives");
        return;
    }

    // The corners marked on the server are the ones that count; the list sent is for callers that never marked any
    if (Corners.Length >= class'CMAObjective'.const.MIN_CORNER_COUNT)
        ObjectiveCorners = Corners;

    if (ObjectiveCorners.Length < 3)
    {
        MyMut.PrivateMessage(PC, "[CMenu] An objective needs at least three marked corners; you have marked "$Corners.Length$". Use Mark Corner at each corner first");
        return;
    }

    CMPO = Spawn(class'CMAObjective',,, SpawnLocation,,, true);
    if (CMPO == none)
    {
        MyMut.PrivateMessage(PC, "[CMenu] The objective could not be placed");
        return;
    }

    CMPO.Init(ObjectiveCorners, ObjName, CapTime, OwnerTeam);
    if (!CMPO.bObjectiveReady)
    {
        MyMut.PrivateMessage(PC, "[CMenu] The objective could not be built: the corners are too close together, or all the objective slots are in use");
        return;
    }

    ClearCornerMarkers();
    MyMut.PrivateMessage(PC, "[CMenu] Built objective "$CMPO.ObjShortName$", \""$CMPO.DisplayName$"\" ("$ObjectiveCorners.Length$" corners, "
        $CMPO.MinimumCaptureTime$" seconds to capture, held by "$MyMut.ObjectiveOwnerWord(CMPO)$"). Realism Match commands such as openobj and setobjnorth work on it");
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
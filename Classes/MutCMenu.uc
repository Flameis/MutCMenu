// Command Menu Mutator
// Created by T/4 Scovel for the 29th Infantry Division Realism Unit
// =================================================================
// Version 2.1
// =================================================================
// Code tech: T/4 Scovel
// =================================================================
class MutCMenu extends ROMutator
    dependson(ROMapInfo)
    config(MutCMenu_Server);

// Help longer than this goes to the player in pieces (ShowHelpToPlayer); one network call can only carry so much
const HELP_PART_CHARS = 400;

var array<DummyActor>           DummyActors;

var array<string>               LoggedInMutatorAdmins; // list of the names of all the players that are currently logged in as a mutator admin
var int                         NumObjs;

var config bool                 bLoadExtras, bLoadGOM3, bLoadGOM4, bLoadWW, bLoadWW2, bNewTankPhys;
var config bool                 bDebugStandalone;   // In a standalone (single player) game, load every mod's content, for testing
var bool                        bForceModLoads;     // bDebugStandalone is on and this is a standalone game: every bLoad option counts as on (not saved to the ini)
var config array<string>        MutatorAdmins; // A list of all mutator admins and their passwords
var config array<string>        ExtrasToLoad, GOM3ToLoad, GOM4ToLoad, WWToLoad, WW2ToLoad; // Lists of all the objects to load

struct WeaponMapping
{
    var string FriendlyName;
    var string ClassPath;
};

var config array<WeaponMapping> WeaponMappings;

// Fire support settings (see the Fire Support section)
struct FSProfile
{
    var string StrikeType;  // MORTAR, ARTILLERY, AIRBURST, ROCKET, WP or MIXED
    var int Salvos;         // Number of salvos
    var int Shells;         // Shells per salvo
    var int Spread;         // Radius in unreal units (50 = 1 meter) that shells scatter within; commands and messages use meters
    var int Interval;       // Seconds between salvos
    var int Delay;          // Seconds between the call and the first salvo
};

struct FSActiveStrike
{
    var Controller Caller;
    var int Team;
    var float ExpireTime;
    var bool bNoOwner;      // The strike was started without the caller as its owner (a spectator's, or for the other team), so its damage has no instigator
};

var config array<FSProfile>     FSProfiles;
var config bool                 bFSPlayersCanCall;  // Non-admin players may use the fire support menu
var config bool                 bTankPromptForAll;  // Anyone gets the tank entry prompt, not only tank crew roles
var config bool                 bFSNoFriendlyFire;  // On: strikes never hurt the caller's own team. Off (the default): the server's friendly fire setting decides, as for any weapon
var config bool                 bFSSilent;          // Set true to not broadcast strike calls to everyone
var config bool                 bCTFSilent;         // Set true to not announce Capture the Flag flags being placed, picked up, dropped, reset or removed
var config int                  FSPlayerCooldown;   // Per-team seconds between player-called strikes, 0 = none (admins ignore it)
var config int                  FSBomberCount;      // Aircraft per Canberra bombing run (1-2), 0 uses 2
var config int                  FSGunshipDuration;  // Seconds the gunship orbits, 0 uses the map's value

// The overhead map (CMMapManager): spectator overlay, teammates past 32 per team, objective borders and map drawing.
// The off switches are negative so the features are on by default: a missing ini entry loads as false.
var config bool                 bDisableEnhancedSpectator;     // Turn off the spectator overlay (every player on the map, coloured names, head triangles)
var config bool                 bDisableSpectatorTracers;      // Turn off the bullet and shell paths spectators see
var config bool                 bDisableMapDrawing;            // Turn off drawing on the overhead map
var config bool                 bKeepMapDrawingsBetweenRounds; // Keep drawings when a new round starts (they are cleared by default)
var config int                  MaxMapDrawingsPerPlayer;       // Drawings one player can have at once before their oldest goes; 0 or missing means 60
var config int                  CTFMaxFlagsPerPlayer;          // Flags one player (not an admin) can have placed at once; 0 or missing means 4
var config int                  CTFPlaceCooldown;              // Seconds a player (not an admin) waits between placing flags; 0 or missing means 5
var CMMapManager                MapManager;

// An aircraft strike waiting out its first strike delay
struct FSPendingStrike
{
    var PlayerController Caller;
    var string StrikeType;
    var vector Target;
    var vector2D StrikeDir;
    var bool bForceBearing;
    var float Bearing;
    var bool bIgnoreNoArty;
    var float FireTime;
    var int Team;           // The team the strike is for (a spectator has none of their own)
};

// A barrage or aircraft this mod started, so it can be cancelled later
struct FSTrackedStrike
{
    var Actor Strike;
    var int Team;
};

var array<FSTrackedStrike>      FSTrackedStrikes;

// A strike shown on the overhead map the way the game shows the commander's: the target, the salvos left and the aircraft
struct FSMapStrike
{
    var Actor Strike;
    var int Team;
    var bool bBothTeams;    // A spectator called it, so both teams see it
    var vector Target;
    var vector2D Dir;
};

var array<FSMapStrike>          FSMapStrikes;
var vector                      FSMapShown[2];  // The location this mod last put on each team's map
var array<FSActiveStrike>       FSActiveStrikes;
var array<FSPendingStrike>      FSPendingStrikes;
var string                      CurrentMutateString; // The command being processed, so argument errors can put it back in the console for editing
// Where a player is looking, as their own game saw it (see AskClientForLook); set only while their command runs again
var PlayerController            LookCaller;
var vector                      LookFromClient, LookNormalFromClient;
var bool                        bLookFromClientHit;
var float                       FSNextCallTime[2];

const DELETE_OBJ_RANGE = 2500.0; // 50 meters: how far from where an admin looks deleteobj finds an objective
// =================================================================
// Initialization
// =================================================================
function PreBeginPlay()
{
    local Mutator mut;
    super.PreBeginPlay();

    ApplyMapModLoads();
    InitFireSupportConfig();

    // Not written into bLoadExtras and the rest, so the saved settings stay as they were
    bForceModLoads = ShouldForceModLoads();
    if (bForceModLoads)
        `log("[MutCMenu] bDebugStandalone: standalone game, every mod's content is loaded");

    // Clean up duplicate MutCMenu instances
    for (mut = ROGameInfo(WorldInfo.Game).BaseMutator; mut != none; mut = mut.NextMutator)
    {
        if (mut == ROGameInfo(WorldInfo.Game).BaseMutator && InStr(string(mut.name), "MutCMenu",,true) != -1 && mut != self)
        {
            ROGameInfo(WorldInfo.Game).BaseMutator = mut.NextMutator;
            mut.Destroy();
        }
        else if (InStr(string(mut.NextMutator.name), "MutCMenu",,true) != -1 && mut.NextMutator != self) 
        {
            mut.NextMutator = mut.NextMutator.NextMutator;
            mut.NextMutator.Destroy();
        }
    }

    if (ROGameInfo(WorldInfo.Game).GameReplicationInfoClass == class'ROGameReplicationInfo')
    {
        ROGameInfo(WorldInfo.Game).GameReplicationInfoClass = class'CMGameReplicationInfo';
    }

    MapManager = Spawn(class'CMMapManager', self);
    MapManager.Mut = self;
}

// bDebugStandalone only counts in a standalone (single player) game, never on a server
function bool ShouldForceModLoads()
{
    return bDebugStandalone && WorldInfo.NetMode == NM_Standalone;
}

// A WW2 or Winter War map has that mod's content loaded anyway, so its vehicles and weapons can be used. Read from the
// map name's prefix (WW2: RRTE, RRSU, RRSK, DRTE, DRSU; Winter War: WWTE, WWSU), the way the game picks the game mode.
function ApplyMapModLoads()
{
    local string Prefix;

    Prefix = Caps(Left(WorldInfo.GetMapName(true), 4));

    if (Prefix == "WWTE" || Prefix == "WWSU")
        bLoadWW = true;

    if (Prefix == "RRTE" || Prefix == "RRSU" || Prefix == "RRSK" || Prefix == "DRTE" || Prefix == "DRSU")
        bLoadWW2 = true;
}

auto state StartUp
{
    Begin:
    SetTimer(1, false, 'LoadObjects');
}

// =================================================================
// Login/Logout Handling
// =================================================================
simulated function NotifyLogin(Controller NewPlayer)
{
    local DummyActor DA;
    
    //Spawn a dummyactor to do client side functions without replacing the playercontroller
    DA = spawn(class'DummyActor', NewPlayer); 
    DummyActors.AddItem(DA);

    DA.MyMut = self;
    DA.bNewTankPhys = bNewTankPhys;
    DA.bLoadExtras = bLoadExtras || bForceModLoads;
    DA.bLoadGOM3 = bLoadGOM3 || bForceModLoads;
    DA.bLoadGOM4 = bLoadGOM4 || bForceModLoads;
    DA.bLoadWW = bLoadWW || bForceModLoads;
    DA.bLoadWW2 = bLoadWW2 || bForceModLoads;
    DA.bFSPlayersCanCall = bFSPlayersCanCall;
    DA.bTankPromptForAll = bTankPromptForAll;

    DA.CMenuSetup();

    if (MapManager != None && PlayerController(NewPlayer) != None)
        MapManager.AddPlayer(PlayerController(NewPlayer));

    super.NotifyLogin(NewPlayer);
}

// Settings each player's game needs, sent again after they are changed on the settings page
function SendClientSettings()
{
    local DummyActor DA;

    foreach DummyActors(DA)
    {
        if (DA == None || DA.bDeleteMe)
            continue;
        DA.bFSPlayersCanCall = bFSPlayersCanCall;
        DA.bTankPromptForAll = bTankPromptForAll;
    }
}

simulated function NotifyLogout(Controller Exiting)
{
    local DummyActor DA;

    //Destroy the players dummyactor when they leave the server
    foreach DummyActors(DA)
    {
        if (DA.Owner == Exiting)
        {
            DA.Destroy();
            break;
        }
    }

    if (MapManager != None)
        MapManager.RemovePlayer(Exiting);

    super.NotifyLogout(Exiting);
}

// =================================================================
// Player Start Override
// =================================================================
function NavigationPoint FindPlayerStart(Controller Player, optional byte InTeam, optional string incomingName)
{
    local CMASpawn SMS;
    local NavigationPoint SpawnPoint;
    local ROGameInfo ROGI;
    local vector SpawnLoc;
    
    ROGI = ROGameInfo(WorldInfo.Game);

    // Check for custom spawn points defined by CMASpawn actors
    foreach AllActors(class'CMASpawn', SMS)
    {
        if (SMS.TeamIndex == Player.GetTeamNum())
        {
            ROGI.FindSpawnablePointForTunnel(SMS.PSP, SpawnLoc);
            SpawnPoint = Spawn(class'ROSpawnNavigationPoint',,, SpawnLoc);
            SMS.MySpawns.AddItem(SpawnPoint);
            return SpawnPoint;
        }
    }
    return super.FindPlayerStart(Player, InTeam, incomingName);
}

// =================================================================
// Console Commands
// =================================================================
simulated function Mutate(string mutateString, PlayerController sender)
{
    local DummyActor DA, DASender, DAFound;
    local CMASpawn SMS;

    local array<string> params;
    local string        command;
    local string        secondaryparam, tertiaryparam;
    local int           i;

    // `log("mutateString = "$mutateString);
    CurrentMutateString = mutateString;

    // Map drawing commands (mapundo, mapclear, mapdrawing) are for everyone; the map manager checks who may do what
    if (MapManager != None && MapManager.HandleCommand(sender, SplitString(mutateString, " ", true)))
    {
        if (LookCaller == None)
            super.Mutate(mutateString, sender);
        return;
    }

    // Parse the mutate string into command and parameters
    params = SplitString(mutateString, " ", true);
    command = Caps(params[0]);

    if (class'CmdOptions'.static.AnyOptions(params))
    {
        // "--option value" / "-o value" syntax
        ResolveOptionArgs(sender, command, params, secondaryparam, tertiaryparam);
    }
    else
    {
        // Legacy syntax: "command value" and "command value to value"
        params = SplitString(mutateString, " to ", false);
        tertiaryparam = params[1];
        params = SplitString(params[0], " ", true);

        // Reconstruct secondary parameter from remaining parts
        for(i = 1; i < params.Length; i++)
        {
            if(i == 1)
            {
                secondaryparam = params[i];
            }
            else
            {
                secondaryparam = secondaryparam$" "$params[i];
            }
        }
    }

    // Find the DummyActor for the sender and the target player (if any)
    foreach DummyActors(DA)
    {
        if (DA.Owner == sender)
        {
            DASender = DA;
        }
        if (DA.Owner == FindPlayer(secondaryparam))
        {
            DAFound = DA;
        }
    }
    
    switch (command) // Commands that do not need admin
    {
        case "GIVEWEAPON":
            GiveWeapon(sender, secondaryparam, false, 100);
            break;

        case "GIVEWEAPONALL":
            GiveWeapon(sender, secondaryparam, true, 100);
            break;

        case "GIVEWEAPONNORTH":
            GiveWeapon(sender, secondaryparam, false, `AXIS_TEAM_INDEX);
            break;

        case "GIVEWEAPONSOUTH":
            GiveWeapon(sender, secondaryparam, false, `ALLIES_TEAM_INDEX);
            break;

        case "CLEARWEAPONS":
            ClearWeapons(sender, false, 100);
            break;
    
        case "CLEARWEAPONSALL":
            ClearWeapons(sender, true);
            WorldInfo.Game.Broadcast(self, "[CMenu] "$sender.PlayerReplicationInfo.PlayerName$" cleared all weapons");
            break;
    
        case "CLEARWEAPONSNORTH":
            ClearWeapons(sender, false, `AXIS_TEAM_INDEX);
            Worldinfo.game.broadcast(self, "[CMenu] "$sender.PlayerReplicationInfo.PlayerName$" cleared north weapons");
            break;
    
        case "CLEARWEAPONSSOUTH":
            ClearWeapons(sender, false, `ALLIES_TEAM_INDEX);
            WorldInfo.Game.Broadcast(self, "[CMenu] "$sender.PlayerReplicationInfo.PlayerName$" cleared south weapons");
            break;

        case "SETCMENUTEXTCOLOR":
            DASender.SetCMenuColor(secondaryparam, "Text");
            break;

        case "SETCMENUBGCOLOR":
            DASender.SetCMenuColor(secondaryparam, "Background");
            break;

        case "SETCMENUBORDERCOLOR":
            DASender.SetCMenuColor(secondaryparam, "Border");
            break;

        case "SETCMENUCOLOR":
            SetCMenuColors(sender, DASender, params);
            break;

        case "CMENU":
            // The setting can be changed from the mutator settings page while the player is connected
            if (DASender != None)
                DASender.bFSPlayersCanCall = bFSPlayersCanCall;

            if (secondaryparam != "")
            {
                ToggleCMenuVisiblity(sender, secondaryparam, tertiaryparam);
            }
            else
            {
                ToggleCMenuVisiblity(sender, "CMENUMAIN");
            }
            break;

        case "SWITCHTEAM":
            ROPlayerController(Sender).SwapTeam(1);
            break;

        case "SCRIMADMINLOGIN":
            LogInAdmin(sender, secondaryparam);
            break;
            
        case "SCRIMADMINLOGOUT":
            LogOutAdmin(sender);
            break;

        case "FIRESUPPORT":
            FireSupportCommand(sender, secondaryparam, params);
            break;

        case "FIRESUPPORTHELP":
            FireSupportHelp(sender);
            break;

        case "CANCELFIRESUPPORT":
            CancelFireSupportCommand(sender, params);
            break;

        case "CLEAROBJS":
            ClearObjectivesCommand(sender);
            break;

        case "SPAWNOBJ":
            SpawnObjectiveCommand(sender, params);
            break;

        case "DELETEOBJ":
            DeleteObjectiveCommand(sender, params);
            break;

        case "CLEARCORNERS":
            if (FindDummyActor(sender) != None)
                FindDummyActor(sender).ServerClearCorners();
            break;

        case "DELNORTHSPAWNS":
            foreach AllActors(class'CMASpawn', SMS)
            {
                if (SMS.TeamIndex == 0)
                {
                    SMS.Destroy();
                }
            }
            break;

        case "DELSOUTHSPAWNS":
            foreach AllActors(class'CMASpawn', SMS)
            {
                if (SMS.TeamIndex == 1)
                {
                    SMS.Destroy();
                }
            }
            break;

        // Anyone can place a flag; resetting and removing them check for admins themselves, so a refused player is told why
        case "SPAWNFLAG":
            SpawnFlagCommand(sender, params);
            break;

        case "DROPFLAG":
            DropFlagCommand(sender);
            break;

        case "RESETFLAGS":
        case "REMOVEFLAGS":
            FlagAdminCommand(sender, command);
            break;
    }
    if (IsAuthorized(sender))
    {
        switch (command)
        {
            case "CMENUPCMANAGER":
                ToggleCMenuVisiblity(sender, "CMENUPCMANAGER", secondaryparam);
                break;

            case "KILLPLAYER":
                FindPlayer(secondaryparam).Pawn.Suicide();
                break;

            case "TELEPORTTOME":
                FindPlayer(secondaryparam).Pawn.SetLocation(Sender.Pawn.Location);
                break;

            case "FORCESWITCHTEAM":
                FindPlayer(secondaryparam).SwapTeam(1);
                break;

            case "TEMPADMINLOGIN":
                DAFound.ClientCMConsoleCommand("mutate scrimadminlogin "$MutRealismMatch(WorldInfo.Game.BaseMutator).MutatorAdmins[0]);
                WorldInfo.Game.Broadcast(self, "[CMenu] "$sender.PlayerReplicationInfo.PlayerName$" gave temporary admin powers to "$secondaryparam);
                break;

            case "TEMPADMINLOGOUT":
                DAFound.ClientCMConsoleCommand("mutate scrimadminlogout");
                WorldInfo.Game.Broadcast(self, "[CMenu] "$sender.PlayerReplicationInfo.PlayerName$" revoked temporary admin powers from "$secondaryparam);
                break;

            case "FORCERESPAWN":
                DAFound.ClientCMConsoleCommand("mutate respawn");
                break;

            case "FDAO": //ForceDropAtObj
                DAFound.ClientCMConsoleCommand("mutate dropatobj "$tertiaryparam);
                break;

            case "FDAG": //ForceDropAtGrid
                DAFound.ClientCMConsoleCommand("mutate dropatgrid "$tertiaryparam);
                break;
            
            case "FORCESAFETYON":
                DAFound.ClientCMConsoleCommand("mutate safetyon");
                break;

            case "FORCESAFETYOFF":
                DAFound.ClientCMConsoleCommand("mutate safetyoff");
                break;

            case "FORCEUNITPATCH":
                DAFound.ClientCMConsoleCommand("mutate changeunit "$tertiaryparam);
                break;

            case "FORCERANKPATCH":
                DAFound.ClientCMConsoleCommand("mutate changerank "$tertiaryparam);
                break;

        }
    }
    // A command run again with the player's own view (AskClientForLook) has already been passed on the first time
    if (LookCaller == None)
        super.Mutate(MutateString, sender);
}

// Commands that act where the player is looking ask the player's own game where that is, then run again with the
// answer. The server's idea of a player's view is wrong for a spectator watching someone (it is that player's
// position, and its line hits that player), so --look fire support landed on the watched player. True when the
// question was sent and the command should stop for now.
function bool AskClientForLook(PlayerController Caller)
{
    local DummyActor DA;

    if (LookCaller == Caller)
        return false; // this is the run with the answer
    DA = FindDummyActor(Caller);
    if (DA == None)
        return false;
    DA.RequestLookTarget(CurrentMutateString);
    return true;
}

// The answer from the player's game: their command runs again with it
function RunWithClientLook(PlayerController Caller, string Command, bool bHit, vector Target, vector Normal)
{
    LookCaller = Caller;
    LookFromClient = Target;
    LookNormalFromClient = Normal;
    bLookFromClientHit = bHit;
    Mutate(Command, Caller);
    LookCaller = None;
}

// =================================================================
// Custom objectives (CMAObjective), built from the corners marked with the Builder
// =================================================================
// mutate spawnobj [--name <text>] [--time <seconds>] [--owner north|south|neutral] (-n, -t, -o): builds an objective from
// the corners the sender marked with Mark Corner (admins). It stands at the height of the corner poles.
function SpawnObjectiveCommand(PlayerController Sender, array<string> Tokens)
{
    local DummyActor DA;
    local array<Vector2D> NoCorners;
    local string TimeText, OwnerText;
    local int CapTime, OwnerTeam, i, Poles;
    local vector Where, ViewLoc;
    local rotator ViewRot;

    DA = FindDummyActor(Sender);
    if (DA == None)
        return;

    TimeText = class'CmdOptions'.static.Get(Tokens, "time", "t");
    if (TimeText != "")
    {
        CapTime = int(TimeText);
        if (CapTime <= 0)
        {
            PrivateMessage(Sender, "[CMenu] --time is the seconds it takes to capture, above 0 (up to "$class'CMAObjective'.const.MAX_CAPTURE_TIME$")");
            return;
        }
    }

    OwnerTeam = -1;
    OwnerText = class'CmdOptions'.static.Get(Tokens, "owner", "o");
    if (OwnerText != "" && !(OwnerText ~= "neutral") && !(OwnerText ~= "none") && !(OwnerText ~= "nobody"))
    {
        OwnerTeam = class'CmdOptions'.static.ParseTeam(OwnerText);
        if (OwnerTeam != `AXIS_TEAM_INDEX && OwnerTeam != `ALLIES_TEAM_INDEX)
        {
            PrivateMessage(Sender, "[CMenu] --owner must be north, south or neutral");
            return;
        }
    }

    // The height of the corner poles, or else where the builder is
    for (i = 0; i < DA.CornerMarkers.Length; i++)
    {
        if (DA.CornerMarkers[i] != None && !DA.CornerMarkers[i].bDeleteMe)
        {
            Where += DA.CornerMarkers[i].Location;
            Poles++;
        }
    }
    if (Poles > 0)
        Where /= Poles;
    else if (Sender.Pawn != None)
        Where = Sender.Pawn.Location;
    else
    {
        Sender.GetPlayerViewPoint(ViewLoc, ViewRot);
        Where = ViewLoc;
    }

    NoCorners.Length = 0;
    DA.ServerSpawnObjective(Where, NoCorners, class'CmdOptions'.static.GetOrPositional(Tokens, "name", "n"), CapTime, OwnerTeam);
}

// mutate deleteobj [--obj <letter or name>] (-o): removes one custom objective (admins). Without --obj, the one the sender
// looks at: the one whose shape the spot is in, or else the nearest within 50 meters of it.
function DeleteObjectiveCommand(PlayerController Sender, array<string> Tokens)
{
    local CMAObjective O, Best;
    local string Which, What;
    local vector Target;
    local float D, BestD;

    if (!IsAuthorized(Sender))
    {
        PrivateMessage(Sender, "[CMenu] Only admins can remove objectives");
        return;
    }

    Which = class'CmdOptions'.static.GetOrPositional(Tokens, "obj", "o");
    if (Which != "")
    {
        foreach DynamicActors(class'CMAObjective', O)
        {
            if (O.bObjectiveReady && !O.bDeleteMe && (O.ObjShortName ~= Which || O.DisplayName ~= Which))
            {
                Best = O;
                break;
            }
        }
        if (Best == None)
        {
            PrivateMessage(Sender, "[CMenu] There is no custom objective '"$Which$"'. Custom objectives: "$CustomObjectiveList());
            return;
        }
    }
    else
    {
        // Where they are looking (their own game says where, for spectators)
        if (AskClientForLook(Sender))
            return;
        if (!GetLookTarget(Sender, Target))
        {
            if (Sender.Pawn == None)
            {
                PrivateMessage(Sender, "[CMenu] Look at a custom objective, or name one with --obj. Custom objectives: "$CustomObjectiveList());
                return;
            }
            Target = Sender.Pawn.Location;
        }

        BestD = DELETE_OBJ_RANGE;
        foreach DynamicActors(class'CMAObjective', O)
        {
            if (!O.bObjectiveReady || O.bDeleteMe)
                continue;
            if (O.ContainsLocation(Target))
            {
                Best = O;
                break;
            }
            D = VSize2D(O.Location - Target);
            if (D < BestD)
            {
                BestD = D;
                Best = O;
            }
        }
        if (Best == None)
        {
            PrivateMessage(Sender, "[CMenu] There is no custom objective where you are looking. Name one with --obj. Custom objectives: "$CustomObjectiveList());
            return;
        }
    }

    What = Best.ObjShortName$" (\""$Best.DisplayName$"\")";
    Best.Destroy();
    PrivateMessage(Sender, "[CMenu] Removed custom objective "$What);
}

// mutate clearobjs: removes every custom objective (admins)
function ClearObjectivesCommand(PlayerController Sender)
{
    local CMAObjective O;
    local int Count;

    if (!IsAuthorized(Sender))
    {
        PrivateMessage(Sender, "[CMenu] Only admins can remove objectives");
        return;
    }

    foreach DynamicActors(class'CMAObjective', O)
    {
        if (O.bDeleteMe)
            continue;
        O.Destroy();
        Count++;
    }
    PrivateMessage(Sender, "[CMenu] Removed "$Count$" custom objective"$(Count == 1 ? "" : "s"));
}

// "A (Village), B (Custom Objective B)", or "none"
function string CustomObjectiveList()
{
    local CMAObjective O;
    local string List;

    foreach DynamicActors(class'CMAObjective', O)
    {
        if (!O.bObjectiveReady || O.bDeleteMe)
            continue;
        if (List != "")
            List $= ", ";
        List $= O.ObjShortName$" ("$O.DisplayName$")";
    }
    return (List != "") ? List : "none";
}

// Who holds an objective, in words: "North", "South" or "nobody"
function string ObjectiveOwnerWord(ROObjective O)
{
    if (O.ObjState == OBJ_Axis)
        return "North";
    if (O.ObjState == OBJ_Allies)
        return "South";
    return "nobody";
}

// =================================================================
// Capture the Flag flags (CMAFlag)
// =================================================================
// mutate spawnflag [--team <team>] [--flag <faction>] [--nobeam] (-t, -f, -n): a flag where the sender is looking. Anyone can place one. It shows
// the flag of the sender's team, the team named with --team (north/south, axis/allies, finnish/soviet or 0/1, so either
// team's flag can be placed), or exactly the faction named with --flag. A spectator has no team, so they name one.
function SpawnFlagCommand(PlayerController Sender, array<string> Tokens)
{
    local vector ViewLoc, HitLoc, HitNorm, Loc;
    local rotator ViewRot;
    local string TeamText, FlagText;
    local int Team, Faction;

    FlagText = class'CmdOptions'.static.Get(Tokens, "flag", "f");
    if (FlagText != "")
    {
        Faction = class'CMAFlag'.static.FindFaction(FlagText);
        if (Faction == -1)
        {
            PrivateMessage(Sender, "[CMenu] Unknown flag '"$FlagText$"'. Flags: "$class'CMAFlag'.static.FactionNames());
            return;
        }
    }
    else
    {
        Team = Sender.GetTeamNum();
        TeamText = class'CmdOptions'.static.GetOrPositional(Tokens, "team", "t");
        if (TeamText != "")
            Team = ParseFlagTeam(TeamText);

        if (Team != `AXIS_TEAM_INDEX && Team != `ALLIES_TEAM_INDEX)
        {
            if (TeamText == "")
                PrivateMessage(Sender, "[CMenu] You are not on a team: say whose flag it is with --team "$FlagTeamChoices()$", or pick one with --flag");
            else
                PrivateMessage(Sender, "[CMenu] Usage: mutate spawnflag [--team "$FlagTeamChoices()$"] [--flag <name>] [--nobeam]");
            return;
        }
        Faction = class'CMAFlag'.static.FactionForTeam(WorldInfo, Team);
    }

    // Where they are looking (their own game says where, for spectators), otherwise just in front of them
    if (AskClientForLook(Sender))
        return;
    if (LookCaller == Sender)
    {
        // A little out from the surface, so a flag put against a wall isn't inside it
        if (bLookFromClientHit)
            Loc = LookFromClient + LookNormalFromClient * 20;
        else
        {
            PrivateMessage(Sender, "[CMenu] There is nothing in view to put the flag on. Look at the ground.");
            return;
        }
    }
    else
    {
        Sender.GetPlayerViewPoint(ViewLoc, ViewRot);
        if (Trace(HitLoc, HitNorm, ViewLoc + vector(ViewRot) * 5000, ViewLoc, false) != None)
            Loc = HitLoc + HitNorm * 20;
        else
            Loc = ViewLoc + vector(ViewRot) * 100;
    }

    PlaceFlag(Sender, Loc, Faction, !class'CmdOptions'.static.Has(Tokens, "nobeam", "n"));
}

// north/south, axis/allies, 0/1, and on Winter War maps finnish/soviet. -1 when it is none of them
function int ParseFlagTeam(string Text)
{
    switch (Caps(Text))
    {
        case "FINNISH":
        case "FINLAND":
            return `AXIS_TEAM_INDEX;
        case "SOVIET":
        case "SOVIETS":
            return `ALLIES_TEAM_INDEX;
    }
    return class'CmdOptions'.static.ParseTeam(Text);
}

// The team names to type on this map, for messages
function string FlagTeamChoices()
{
    return Locs(class'CMAFlag'.static.TeamWord(WorldInfo, `AXIS_TEAM_INDEX))$"|"$Locs(class'CMAFlag'.static.TeamWord(WorldInfo, `ALLIES_TEAM_INDEX))$"|0|1";
}

// Places a flag of that faction just above Loc, and it falls to the ground. Used by spawnflag and the Builder's Actors
// menu.
function CMAFlag PlaceFlag(PlayerController Sender, vector Loc, int Faction, optional bool bBeam = true)
{
    local CMAFlag F;
    local DummyActor DA;

    if (!FlagAllowed(Sender, Faction) || !FlagLimitAllows(Sender))
        return None;

    F = Spawn(class'CMAFlag',,, Loc + vect(0, 0, 50),,, true);
    if (F == None)
    {
        PrivateMessage(Sender, "[CMenu] A flag can't be placed there");
        return None;
    }

    F.MyMut = self;
    F.PlacerID = (Sender.PlayerReplicationInfo != None) ? Sender.PlayerReplicationInfo.PlayerID : -1;
    DA = FindDummyActor(Sender);
    if (DA != None)
        DA.LastFlagTime = WorldInfo.TimeSeconds;
    F.SetBeam(bBeam);
    F.SetFaction(Faction);
    F.SetPhysics(PHYS_Falling);

    FlagAnnounce(Sender.PlayerReplicationInfo.PlayerName$" placed the "$F.Label()$" flag");
    return F;
}

// Anyone can place flags, so players (not admins) have a limit on how many they have out and a wait between them
function int FlagLimit()
{
    return CTFMaxFlagsPerPlayer > 0 ? CTFMaxFlagsPerPlayer : 4;
}

function int FlagCooldown()
{
    return CTFPlaceCooldown > 0 ? CTFPlaceCooldown : 5;
}

function bool FlagLimitAllows(PlayerController Sender)
{
    local CMAFlag F;
    local DummyActor DA;
    local int Count;
    local float Wait;

    if (IsAuthorized(Sender) || Sender.PlayerReplicationInfo == None)
        return true;

    DA = FindDummyActor(Sender);
    if (DA != None && DA.LastFlagTime > 0)
    {
        Wait = DA.LastFlagTime + FlagCooldown() - WorldInfo.TimeSeconds;
        if (Wait > 0)
        {
            PrivateMessage(Sender, "[CMenu] Wait "$(int(Wait) + 1)$" more second"$(int(Wait) + 1 == 1 ? "" : "s")$" before placing another flag");
            return false;
        }
    }

    foreach DynamicActors(class'CMAFlag', F)
    {
        if (F.PlacerID == Sender.PlayerReplicationInfo.PlayerID)
            Count++;
    }
    if (Count >= FlagLimit())
    {
        PrivateMessage(Sender, "[CMenu] You already have "$Count$" flags out, the most a player can have. An admin can remove them with Remove Flags");
        return false;
    }
    return true;
}

// A WW2 or Winter War flag needs bLoadWW2 / bLoadWW, unless the map is from that mod (then its content is loaded anyway).
// Vietnam flags are always allowed.
function bool FlagAllowed(PlayerController Sender, int Faction)
{
    local int Mod;

    Mod = class'CMAFlag'.default.Factions[Faction].Mod;
    if (Mod == class'CMAFlag'.const.MOD_VN || Mod == class'CMAFlag'.static.ModOfMap(WorldInfo))
        return true;
    if (Mod == class'CMAFlag'.const.MOD_WW2 && (bLoadWW2 || bForceModLoads))
        return true;
    if (Mod == class'CMAFlag'.const.MOD_WW && (bLoadWW || bForceModLoads))
        return true;

    PrivateMessage(Sender, "[CMenu] "$(Mod == class'CMAFlag'.const.MOD_WW2 ? "bLoadWW2" : "bLoadWW")
        $" must be enabled in the WebAdmin mutators settings for you to place the "$class'CMAFlag'.default.Factions[Faction].Label$" flag on this map!");
    return false;
}

// Every flag message to the whole server goes through here, so bCTFSilent (also on the settings page) silences them all
function FlagAnnounce(string Msg)
{
    if (!bCTFSilent)
        WorldInfo.Game.Broadcast(self, "[CMenu] "$Msg);
}

// mutate dropflag: anyone carrying a flag throws it down in front of them
function DropFlagCommand(PlayerController Sender)
{
    local CMAFlag F;

    foreach DynamicActors(class'CMAFlag', F)
    {
        if (F.Carrier != None && F.Carrier == Sender.Pawn)
        {
            F.Drop(true);
            return;
        }
    }
    PrivateMessage(Sender, "[CMenu] You are not carrying a flag");
}

// mutate resetflags (every flag back where it was placed) / mutate removeflags
function FlagAdminCommand(PlayerController Sender, string Command)
{
    local CMAFlag F;

    if (!IsAuthorized(Sender))
    {
        PrivateMessage(Sender, "[CMenu] Only admins can reset or remove flags");
        return;
    }

    foreach DynamicActors(class'CMAFlag', F)
    {
        if (Command == "RESETFLAGS")
            F.ReturnHome();
        else
            F.Destroy();
    }

    if (Command == "RESETFLAGS")
        FlagAnnounce(Sender.PlayerReplicationInfo.PlayerName$" sent the flags back to where they were placed");
    else
        FlagAnnounce(Sender.PlayerReplicationInfo.PlayerName$" removed the flags");
}

// =================================================================
// Option syntax ("--option value" / "-o value")
// =================================================================
// Maps the options of a command onto the primary/secondary arguments the command handlers use, so
// "killplayer --player Name" and the older "killplayer Name" behave the same. Team options on the weapon
// commands turn into the matching legacy command (giveweapon --team north -> GIVEWEAPONNORTH).
function ResolveOptionArgs(PlayerController Sender, out string Command, array<string> Tokens, out string Primary, out string Secondary)
{
    local string TeamText, Rest, Grid;
    local array<string> TeamParts;
    local int TeamIndex;

    switch (Command)
    {
        case "CMENU":
            Primary = class'CmdOptions'.static.GetOrPositional(Tokens, "menu", "m");
            Secondary = class'CmdOptions'.static.Get(Tokens, "player", "p");
            // The Builder's custom vehicle and pickup: the thing to place
            if (Secondary == "")
                Secondary = class'CmdOptions'.static.Get(Tokens, "item", "i");
            break;

        case "GIVEWEAPON":
        case "CLEARWEAPONS":
            Primary = class'CmdOptions'.static.Get(Tokens, "weapon", "w");
            if (Primary == "")
                Primary = class'CmdOptions'.static.Positional(Tokens);

            if (class'CmdOptions'.static.Has(Tokens, "team", "t"))
            {
                // "--team north L1A1": the first word is the team, anything after it can still be the weapon
                TeamText = class'CmdOptions'.static.Get(Tokens, "team", "t");
                TeamParts = SplitString(TeamText, " ", true);
                Rest = (TeamParts.Length > 1) ? Mid(TeamText, Len(TeamParts[0]) + 1) : "";
                if (Primary == "")
                    Primary = Rest;

                TeamIndex = class'CmdOptions'.static.ParseTeam(TeamParts.Length > 0 ? TeamParts[0] : "");
                switch (TeamIndex)
                {
                    case 0:
                        Command = Command$"NORTH";
                        break;
                    case 1:
                        Command = Command$"SOUTH";
                        break;
                    case 100:
                        Command = Command$"ALL";
                        break;
                    default:
                        PrivateMessage(Sender, "[CMenu] --team must be north, south or all");
                        Command = "";
                        break;
                }
            }
            break;

        case "FIRESUPPORT":
            Primary = class'CmdOptions'.static.Get(Tokens, "type", "t");
            if (Primary == "")
                Primary = class'CmdOptions'.static.Positional(Tokens);

            if (class'CmdOptions'.static.Has(Tokens, "mark", "m"))
            {
                // "--mark" alone is the caller's own/selected mark, "--mark SL3" picks squad 3's mark
                Grid = "MARK "$class'CmdOptions'.static.Get(Tokens, "mark", "m");
            }
            else if (class'CmdOptions'.static.Has(Tokens, "sl", "l"))
            {
                // "--SL" is the caller's own squad mark, "--SL 3" is squad 3's
                Grid = Caps(class'CmdOptions'.static.Get(Tokens, "sl", "l"));
                if (Left(Grid, 2) == "SL")
                    Grid = Mid(Grid, 2);
                Grid = "MARK SL"$Grid;
            }
            else
                Grid = class'CmdOptions'.static.Get(Tokens, "grid", "g");

            Primary = Primary@Grid;
            break;

        case "FDAO":
            Primary = class'CmdOptions'.static.GetOrPositional(Tokens, "player", "p");
            Secondary = class'CmdOptions'.static.Get(Tokens, "obj", "o");
            break;

        case "FDAG":
            Primary = class'CmdOptions'.static.GetOrPositional(Tokens, "player", "p");
            Secondary = class'CmdOptions'.static.Get(Tokens, "grid", "g");
            break;

        case "FORCEUNITPATCH":
            Primary = class'CmdOptions'.static.GetOrPositional(Tokens, "player", "p");
            Secondary = class'CmdOptions'.static.Get(Tokens, "unit", "u");
            break;

        case "FORCERANKPATCH":
            Primary = class'CmdOptions'.static.GetOrPositional(Tokens, "player", "p");
            Secondary = class'CmdOptions'.static.Get(Tokens, "rank", "r");
            break;

        case "SCRIMADMINLOGIN":
            Primary = class'CmdOptions'.static.Get(Tokens, "user", "u")@class'CmdOptions'.static.Get(Tokens, "password", "p");
            break;

        case "CMENUPCMANAGER":
        case "KILLPLAYER":
        case "TELEPORTTOME":
        case "FORCESWITCHTEAM":
        case "TEMPADMINLOGIN":
        case "TEMPADMINLOGOUT":
        case "FORCERESPAWN":
        case "FORCESAFETYON":
        case "FORCESAFETYOFF":
            Primary = class'CmdOptions'.static.GetOrPositional(Tokens, "player", "p");
            break;

        default:
            Primary = class'CmdOptions'.static.Positional(Tokens);
            break;
    }
}

// mutate setcmenucolor --text 255 128 0 255 --background 0 0 0 200 --border 255 255 255 255 (-t -b -o)
function SetCMenuColors(PlayerController Sender, DummyActor DASender, array<string> Tokens)
{
    local bool bAny;

    if (DASender == None)
        return;

    if (class'CmdOptions'.static.Has(Tokens, "text", "t"))
    {
        DASender.SetCMenuColor(class'CmdOptions'.static.Get(Tokens, "text", "t"), "Text");
        bAny = true;
    }
    if (class'CmdOptions'.static.Has(Tokens, "background", "b"))
    {
        DASender.SetCMenuColor(class'CmdOptions'.static.Get(Tokens, "background", "b"), "Background");
        bAny = true;
    }
    if (class'CmdOptions'.static.Has(Tokens, "border", "o"))
    {
        DASender.SetCMenuColor(class'CmdOptions'.static.Get(Tokens, "border", "o"), "Border");
        bAny = true;
    }

    if (!bAny)
        PrivateMessage(Sender, "[CMenu] Usage: mutate setcmenucolor --text R G B A --background R G B A --border R G B A (-t -b -o)");
}

// =================================================================
// Menu Visibility
// =================================================================
function ToggleCMenuVisiblity(PlayerController PC, string CMenu, optional string TargetName)
{
    local DummyActor DA, DASender;

    // Find the DummyActor associated with the player
    foreach DummyActors(DA)
    {
        if (DA.Owner == PC)
        {
            DASender = DA;
        }
    }

    DASender.ToggleCMenuVisiblity(CMenu, IsAuthorized(PC), TargetName);
}

// =================================================================
// Admin Management
// =================================================================
function LogInAdmin(PlayerController sender, string MyAdminInfo)
{
    local string PlayerName;
    local string AdminInfo;
    local bool AlreadyAdmin;
    local int i;
    
    PlayerName = sender.PlayerReplicationInfo.PlayerName;
    AlreadyAdmin = False;
    
    // Check if the provided password matches any admin password
    foreach MutatorAdmins(AdminInfo)
    if(MyAdminInfo == AdminInfo)
    {
        // Check if the player is already logged in as admin
        for(i = 0; i < LoggedInMutatorAdmins.Length; i++)
        {
            if(PlayerName == LoggedInMutatorAdmins[i])
            {
                AlreadyAdmin = True;
            }
        }
        if(!AlreadyAdmin)
        {
            LoggedInMutatorAdmins.AddItem(PlayerName);
        }
    }
}

function LogOutAdmin(PlayerController sender)
{
    local string PlayerName;
    local int i;
    local array<string> MyArray;
    
    PlayerName = sender.PlayerReplicationInfo.PlayerName;
    
    // Rebuild the list of logged-in admins, excluding the logging-out player
    for(i = 0; i < LoggedInMutatorAdmins.Length; i++)
    {
        if(PlayerName != LoggedInMutatorAdmins[i])
        {
            MyArray.AddItem(LoggedInMutatorAdmins[i]);
        }
    }
    LoggedInMutatorAdmins = MyArray;
}

function bool IsAuthorized(PlayerController Sender)
{
    local bool IsServerAdmin;
    local bool IsMutatorAdmin;
    local int i;
    local string PlayerName;
    
    PlayerName = sender.PlayerReplicationInfo.PlayerName;
    IsServerAdmin = self.WorldInfo.Game.AccessControl.IsAdmin(Sender);
    
    IsMutatorAdmin = False;
    // Check if the player is in the list of logged-in mutator admins
    for(i = 0; i < LoggedInMutatorAdmins.Length; i++)
    {
        if(LoggedInMutatorAdmins[i] == PlayerName)
        {
            IsMutatorAdmin = True;
        }
    }
    return IsServerAdmin || IsMutatorAdmin;
}

// =================================================================
// Utility Functions
// =================================================================
function ROPlayerController FindPlayer(string PlayerName)
{
    local ROPlayerController PC;

    if(PlayerName != "")
    {
        // Search for a player controller with a matching name
        foreach WorldInfo.AllControllers(class'ROPlayerController', PC)
        {
            if (PC.PlayerReplicationInfo.PlayerName ~= PlayerName)
            {
                return PC;
            }
        }
    }
}

function PrivateMessage(PlayerController receiver, coerce string msg)
{
    // Send a private message to a specific player
    // Sent as an 'Event' from the receiver's own PRI, the same way ClientMessage does, so it shows in the chat feed
    // as well as the console (an untyped message with no PRI could be missed)
    receiver.TeamMessage(receiver.PlayerReplicationInfo, msg, 'Event');
}

// =================================================================
// Weapon Management
// =================================================================
function GiveWeapon(PlayerController PC, string WeaponName, optional bool bGiveAll, optional int TeamIndex)
{
	local ROInventoryManager        InvManager;
    local ROPawn                    ROP;
    local bool                    bSuccess;

    if (PC != none)
    {
        if (bGiveAll)
        { 
            // Give weapon to all pawns
            foreach worldinfo.allpawns(class'ROPawn', ROP)
            {
                InvManager = ROInventoryManager(ROP.InvManager);

                bSuccess = DoGiveWeapon(PC, InvManager, WeaponName);
                if (!bSuccess)
                    break;
            }
            if (bSuccess)
                WorldInfo.Game.Broadcast(self, "[CMenu] "$PC.PlayerReplicationInfo.PlayerName$" gave a "$WeaponName$" to everyone");
        }   
        else if (TeamIndex == `AXIS_TEAM_INDEX)
        {
            // Give weapon to all Axis pawns
            foreach worldinfo.allpawns(class'ROPawn', ROP)
            {
                if (ROP.GetTeamNum() == `AXIS_TEAM_INDEX)
                {
                    InvManager = ROInventoryManager(ROP.InvManager);

                    bSuccess = DoGiveWeapon(PC, InvManager, WeaponName);
                    if (!bSuccess)
                        break;
                }
            }
            if (bSuccess)
                WorldInfo.Game.Broadcast(self, "[CMenu] "$PC.PlayerReplicationInfo.PlayerName$" gave a "$WeaponName$" to the north");
        }
        else if (TeamIndex == `ALLIES_TEAM_INDEX)
        {
            // Give weapon to all Allies pawns
            foreach worldinfo.allpawns(class'ROPawn', ROP)
            {
                if (ROP.GetTeamNum() == `ALLIES_TEAM_INDEX)
                {
                    InvManager = ROInventoryManager(ROP.InvManager);

                    bSuccess = DoGiveWeapon(PC, InvManager, WeaponName);
                    if (!bSuccess)
                        break;
                }
            }
            if (bSuccess)
                WorldInfo.Game.Broadcast(self, "[CMenu] "$PC.PlayerReplicationInfo.PlayerName$" gave a "$WeaponName$" to the south");
        }
        else if (TeamIndex == 100)
        {
            // Give weapon to the sender
            InvManager = ROInventoryManager(PC.Pawn.InvManager);

            bSuccess = DoGiveWeapon(PC, InvManager, WeaponName);
            if (bSuccess)
                WorldInfo.Game.Broadcast(self, "[CMenu] "$PC.PlayerReplicationInfo.PlayerName$" spawned a "$WeaponName);
        }
    }
    else
    {
        // `log ("[MutExtras Debug] Error: GW PlayerController is none!");
    }
}

// =================================================================
// Helper: DoGiveWeapon
// =================================================================
// Performs the actual weapon giving logic.
// Checks if the weapon name is valid and if the required content package is loaded.
// If valid, it attempts to load and create the inventory item for the player.
// =================================================================
function bool DoGiveWeapon(PlayerController PC, ROInventoryManager InvManager, string WeaponName)
{
    local int i;

    // Search in config array for friendly name match
    for (i = 0; i < WeaponMappings.Length; i++)
    {
        if (WeaponMappings[i].FriendlyName ~= WeaponName)
        {
            WeaponName = WeaponMappings[i].ClassPath;
            break;
        }
    }

    // Check if it is a valid path
    if (InStr(WeaponName, "Weap") != -1 || InStr(WeaponName, "Item") != -1)
    {
        // Check for specific mod content requirements
        if (InStr(WeaponName, "WinterWar") != -1 && !(bLoadWW || bForceModLoads))
        {
            PrivateMessage(PC, "bLoadWinterWar must be enabled in the WebAdmin mutators settings for you to spawn this weapon!");
            return false;
        }
        else if (InStr(WeaponName, "GOM4") != -1 && !(bLoadGOM4 || bForceModLoads))
        {
            PrivateMessage(PC, "bLoadGOM4 must be enabled in the WebAdmin mutators settings for you to spawn this weapon!");
            return false;
        }
        else if (InStr(WeaponName, "GOM3") != -1 && !(bLoadGOM3 || bForceModLoads))
        {
            PrivateMessage(PC, "bLoadGOM3 must be enabled in the WebAdmin mutators settings for you to spawn this weapon!");
            return false;
        }
        else if (InStr(WeaponName, "WW2") != -1 && !(bLoadWW2 || bForceModLoads))
        {
            PrivateMessage(PC, "bLoadWW2 must be enabled in the WebAdmin mutators settings for you to spawn this weapon!");
            return false;
        }
        else if (InStr(WeaponName, "AC") != -1 && !(bLoadExtras || bForceModLoads))
        {
            PrivateMessage(PC, "bLoadExtras must be enabled in the WebAdmin mutators settings for you to spawn this weapon!");
            return false;
        }
        
        // Attempt to load
        InvManager.LoadAndCreateInventory(WeaponName, false, true);
        return true;
    }
    else
    {
        PrivateMessage(PC, "Not a valid weapon name.");
        return false;
    }
}

function ClearWeapons(PlayerController PC, bool ClearAll, optional int TeamIndex)
{
    local array<ROWeapon>       WeaponsToRemove;
    local ROWeapon              Weapon;
    local ROInventoryManager    ROIM;
    local ROPawn                ROP;

    if (ClearAll)
    { 
        // Remove weapons from all pawns
        foreach worldinfo.allpawns(class'ROPawn', ROP)
        {
            ROIM = ROInventoryManager(ROP.InvManager);
            ROIM.GetWeaponList(WeaponsToRemove);

            foreach WeaponsToRemove(Weapon)
            {
                ROIM.RemoveFromInventory(Weapon);
            }
        }
    }   
    else if (TeamIndex != 100)
    {
        // Remove weapons from pawns of a specific team
        foreach worldinfo.allpawns(class'ROPawn', ROP)
        {
            if (ROP.GetTeamNum() == TeamIndex)
            {
                ROIM = ROInventoryManager(ROP.InvManager);
                ROIM.GetWeaponList(WeaponsToRemove);

                foreach WeaponsToRemove(Weapon)
                {
                    ROIM.RemoveFromInventory(Weapon);
                }
            }
        }
    }
    else if (TeamIndex == 100)
    {
        // Remove weapons from the sender
        ROIM = ROInventoryManager(PC.Pawn.InvManager);
        ROIM.GetWeaponList(WeaponsToRemove);

        foreach WeaponsToRemove(Weapon)
        {
            ROIM.RemoveFromInventory(Weapon);
        }
    }
}

// =================================================================
// Fire Support
// =================================================================
// Usage: mutate FIRESUPPORT --type <MORTAR|ARTILLERY|AIRBURST|ROCKET|WP|MIXED|NAPALM|CANBERRA|SPOOKY> --grid <grid> (or --mark)
// Short options: -t -g -m. The older "FIRESUPPORT <type> <grid | MARK>" form still works.
// Grid format matches the paradrop commands (e.g. "E 5 kp 5", "E5"); MARK uses the team's base game arty marker.
// Shell strikes are tuned per type through FSProfiles in MutCMenu_Server.ini.
function InitFireSupportConfig()
{
    local int Before;

    Before = FSProfiles.Length;

    AddMissingFSProfile("MORTAR", 4, 4, 600, 6, 5);
    AddMissingFSProfile("ARTILLERY", 3, 3, 1250, 10, 8);
    AddMissingFSProfile("AIRBURST", 3, 3, 1250, 10, 8);
    AddMissingFSProfile("ROCKET", 3, 6, 1500, 8, 6);
    AddMissingFSProfile("WP", 2, 3, 500, 6, 4);
    AddMissingFSProfile("MIXED", 3, 6, 1250, 8, 6);

    // Servers that already have a profile list pick up types added later, without touching their own values
    if (FSProfiles.Length != Before)
        SaveConfig();
}

function AddMissingFSProfile(string InType, int InSalvos, int InShells, int InSpread, int InInterval, int InDelay)
{
    local FSProfile Existing;

    if (!FindFSProfile(InType, Existing))
        AddFSProfile(InType, InSalvos, InShells, InSpread, InInterval, InDelay);
}

function AddFSProfile(string InType, int InSalvos, int InShells, int InSpread, int InInterval, int InDelay)
{
    local FSProfile NewProfile;

    NewProfile.StrikeType = InType;
    NewProfile.Salvos = InSalvos;
    NewProfile.Shells = InShells;
    NewProfile.Spread = InSpread;
    NewProfile.Interval = InInterval;
    NewProfile.Delay = InDelay;
    FSProfiles.AddItem(NewProfile);
}

function bool FindFSProfile(string StrikeType, out FSProfile OutProfile)
{
    local int i;

    for (i = 0; i < FSProfiles.Length; i++)
    {
        if (FSProfiles[i].StrikeType ~= StrikeType)
        {
            OutProfile = FSProfiles[i];
            return true;
        }
    }
    return false;
}

function bool IsValidFSType(string StrikeType)
{
    switch (StrikeType)
    {
        case "MORTAR":
        case "ARTILLERY":
        case "AIRBURST":
        case "ROCKET":
        case "WP":
        case "MIXED":
        case "NAPALM":
        case "CANBERRA":
        case "SPOOKY":
            return true;
    }
    return false;
}

function string FSDisplayName(string StrikeType)
{
    switch (StrikeType)
    {
        case "MORTAR":    return "mortar barrage";
        case "ARTILLERY": return "artillery barrage";
        case "AIRBURST":  return "airburst artillery barrage";
        case "ROCKET":    return "rocket barrage";
        case "WP":        return "white phosphorus barrage";
        case "MIXED":     return "mixed barrage";
        case "NAPALM":    return "napalm strike";
        case "CANBERRA":  return "bombing run";
        case "SPOOKY":    return "AC-47 gunship strike";
    }
    return StrikeType;
}

function class<ROArtilleryShell> GetFSShellClass(string StrikeType)
{
    switch (StrikeType)
    {
        case "MORTAR":    return class'ROMortarShell';
        case "ARTILLERY": return class'ROArtilleryShell';
        case "AIRBURST":  return class'ROArtilleryShellAirburst';
        case "ROCKET":    return class'RORocketShell';
        case "WP":        return class'ROMortarShellWP';
    }
    return None;
}

// Every shell a barrage type fires. MIXED is the NLF barrage: each shell is picked at random from heavy artillery,
// rockets, mortars and white phosphorus (what ROArtillerySpawner gives the NLF)
function bool GetFSShellClasses(string StrikeType, out array<class<ROArtilleryShell> > Classes)
{
    Classes.Length = 0;

    if (StrikeType == "MIXED")
    {
        Classes.AddItem(class'ROArtilleryShell');
        Classes.AddItem(class'RORocketShell');
        Classes.AddItem(class'ROMortarShell');
        Classes.AddItem(class'ROMortarShellWP');
        return true;
    }

    if (GetFSShellClass(StrikeType) == None)
        return false;

    Classes.AddItem(GetFSShellClass(StrikeType));
    return true;
}

function DummyActor FindDummyActor(PlayerController PC)
{
    local DummyActor DA;

    foreach DummyActors(DA)
    {
        if (DA.Owner == PC)
            return DA;
    }
    return None;
}

// Shows guidance on the player's screen: short guidance in the chat and the mini console, long guidance in the large
// console (see DummyActor.ShowHelp). Prompt lines are separated by "|". Also bound to the other mutators' help output.
// Returns false when the player has no DummyActor to show it with.
function bool ShowHelpToPlayer(PlayerController PC, string Prompt, string Prefix)
{
    local DummyActor DA;

    DA = FindDummyActor(PC);
    if (DA == None)
        return false;

    // Long help goes in pieces: on a server one call can only carry so much, and a longer one never arrives
    while (Len(Prompt) > HELP_PART_CHARS)
    {
        DA.ClientAddHelpPart(Left(Prompt, HELP_PART_CHARS));
        Prompt = Mid(Prompt, HELP_PART_CHARS);
    }
    DA.ClientShowHelp(Prompt, Prefix, "", "");
    return true;
}

// A command was typed wrongly: say why in the chat and put the command back in the mini console to edit
function ArgError(PlayerController Caller, string Message)
{
    if (!ShowHelpToPlayer(Caller, "[CMenu] "$Message, "mutate "$CurrentMutateString))
        PrivateMessage(Caller, "[CMenu] "$Message);
}

function FireSupportHelp(PlayerController PC)
{
    local string Help;

    Help = "[CMenu] Fire support: mutate firesupport --type <type> --grid <grid>   (short: -t -g)";
    Help = Help$"|Types: Mortar, Artillery, Airburst, Rocket, WP, Mixed (random mix of artillery, rocket, mortar and WP shells), Napalm, Canberra, Spooky";
    Help = Help$"|Target: --grid E 5 kp 5 (or E5) for a grid square; --mark (-m) for your mark";
    Help = Help$"|Marks: with --mark a squad leader uses their own squad mark and the commander uses the mark selected on their map; anyone else uses the team's";
    Help = Help$"|    --mark SL3 (or --SL 3, -l 3) picks squad 3's mark, --mark CMD the commander's. Squad leaders can only pick their own squad, admins and the commander any";
    Help = Help$"|Napalm/Canberra heading: --direction -b <N, NE, ESE, ... or a 0-360 bearing> = the way the aircraft flies, e.g. --direction SW or -b 225";
    Help = Help$"|--delay -d <10-300 seconds> waits that long before the first strike (all types)";
    Help = Help$"|Barrages (mortar/artillery/airburst/rocket/wp/mixed): --salvos -s, --shells -n, --spread -r (meters), --interval -i = seconds between salvos. Admins can add --persist -p to save them as the new profile";
    Help = Help$"|Napalm/Canberra/Spooky: --salvos -s <1-10> repeats the strike that many times in all, --interval -i <1-300 seconds> is the time between each strike after the first (30 if left out)";
    Help = Help$"|--suppress -q skips the server-wide announcement for this call";
    Help = Help$"|--look -k targets the spot you are looking at (a spectator's camera too). Spectators, and admins calling for the other team, add --team north or --team south";
    Help = Help$"|mutate cancelfiresupport stops your team's fire support (barrages, shells in the air, aircraft and strikes still waiting). Admins can add --all (-a) to stop every team's";
    Help = Help$"|Admins: strikes can land inside no-artillery zones, including outside the combat area, and ignore the player cooldown";

    if (!ShowHelpToPlayer(PC, Help, "mutate firesupport "))
        PrivateMessage(PC, Repl(Help, "|", " "));
}

// Resolves which arty mark a "--mark [selector]" / "--SL [n]" call refers to. Selector is "", "SL", "SL<n>" (n = 1-10) or "CMD".
// "" means the caller's own mark: a squad leader's squad mark, the commander's selected mark, or the team's saved mark for anyone else.
function bool ResolveMarkTarget(PlayerController Caller, bool bAdmin, ROTeamInfo ROTI, string Selector, out vector Target, out vector2D Dir, out string Where)
{
    local ROPlayerReplicationInfo ROPRI;
    local bool bCommander, bSquadLeader, bOwnSquad;
    local int Idx, SquadNum;
    local string Sel;
    local vector Mark;

    ROPRI = ROPlayerReplicationInfo(Caller.PlayerReplicationInfo);
    bCommander = ROPRI != None && ROPRI.RoleInfo != None && ROPRI.RoleInfo.bIsTeamLeader;
    bSquadLeader = ROPRI != None && ROPRI.bIsSquadLeader;

    Sel = Caps(Repl(Selector, " ", ""));
    Idx = -1;

    if (Sel == "")
    {
        if (bCommander)
        {
            // The mark selected on the commander's map; falls back to the team's saved one
            if (ROTI.SelectedArtyIndex < `MAX_ARTY_TARGETS)
                Idx = ROTI.SelectedArtyIndex;
            else
                Idx = `MAX_SQUADS;
            if (!ROTI.GetArtyRequestValid(Idx))
                Idx = -1;
        }
        else if (bSquadLeader)
        {
            Idx = ROPRI.SquadIndex;
            if (Idx < 0 || Idx >= `MAX_SQUADS || !ROTI.GetArtyRequestValid(Idx))
            {
                ArgError(Caller, "Your squad has no arty mark. Mark one with the binoculars or map, or specify a grid.");
                return false;
            }
        }

        if (Idx == -1)
        {
            Mark = ROTI.SavedArtilleryCoords;
            if (Mark == vect(-999999.0,-999999.0,-999999.0) || Mark == vect(0,0,0))
            {
                ArgError(Caller, "No arty position is marked for your team. Mark one or specify a grid.");
                return false;
            }
            Target = Mark;
            Dir = ROTI.SavedStrikeDirection;
            Where = "the marked position";
            return true;
        }
    }
    else if (Sel == "CMD" || Sel == "CO" || Sel == "COMMANDER")
    {
        if (!bAdmin && !bCommander)
        {
            PrivateMessage(Caller, "[CMenu] Only admins and the commander can use the commander's mark.");
            return false;
        }
        Idx = `MAX_SQUADS;
    }
    else if (Left(Sel, 2) == "SL")
    {
        SquadNum = (Len(Sel) > 2) ? int(Mid(Sel, 2)) : ROPRI.SquadIndex + 1;
        if ((Len(Sel) > 2 && !IsNumeric(Mid(Sel, 2))) || SquadNum < 1 || SquadNum > `MAX_SQUADS)
        {
            ArgError(Caller, "Squad marks are SL1 to SL"$`MAX_SQUADS$" (--SL alone is your own squad).");
            return false;
        }
        Idx = SquadNum - 1;

        bOwnSquad = bSquadLeader && ROPRI.SquadIndex == Idx;
        if (!bAdmin && !bCommander && !bOwnSquad)
        {
            PrivateMessage(Caller, "[CMenu] You can only use your own squad's mark as a squad leader.");
            return false;
        }
    }
    else
    {
        ArgError(Caller, "Unknown mark '"$Selector$"'. Use SL1-SL"$`MAX_SQUADS$" or CMD, or leave it out for your own.");
        return false;
    }

    if (!ROTI.GetArtyRequestValid(Idx))
    {
        PrivateMessage(Caller, "[CMenu] "$MarkLabel(Idx)$" has no arty mark set.");
        return false;
    }

    Mark = ROTI.GetArtyRequestVector(Idx);
    if (Mark == vect(-999999.0,-999999.0,-999999.0) || Mark == vect(0,0,0))
    {
        PrivateMessage(Caller, "[CMenu] "$MarkLabel(Idx)$" has no arty mark set.");
        return false;
    }

    Target = Mark;
    // Only the commander's mark comes with a strike direction
    if (Idx == `MAX_SQUADS || Idx == ROTI.SelectedArtyIndex)
        Dir = ROTI.SavedStrikeDirection;
    Where = MarkLabel(Idx)$"'s mark";
    return true;
}

function string MarkLabel(int Idx)
{
    if (Idx == `MAX_SQUADS)
        return "The commander";
    return "Squad "$(Idx + 1);
}

// A tenth-of-a-unit count as text: 125 -> "12.5", 120 -> "12"
function string TenthsText(int Tenths)
{
    if (Tenths % 10 == 0)
        return string(Tenths / 10);
    return (Tenths / 10)$"."$(Tenths % 10);
}

// 50 unreal units = 1 meter
function string UUToMetersText(int UU)
{
    return TenthsText(Round(UU / 5.0));
}

// Digits with at most one decimal point, e.g. "12", "12.5"
function bool IsDecimal(string S)
{
    local int i, Dots;

    if (Len(S) == 0)
        return false;

    for (i = 0; i < Len(S); i++)
    {
        if (Mid(S, i, 1) == ".")
        {
            Dots++;
            if (Dots > 1)
                return false;
        }
        else if (InStr("0123456789", Mid(S, i, 1)) == -1)
            return false;
    }
    return Len(S) > Dots;
}

// Compass point (N, NE, ESE, ...) or a 0-360 bearing to degrees clockwise from north
function bool ParseBearing(string Text, out float Bearing)
{
    local string T;

    T = Caps(Repl(Text, " ", ""));
    switch (T)
    {
        case "N":   case "NORTH":      Bearing = 0.0;   return true;
        case "NNE":                    Bearing = 22.5;  return true;
        case "NE":  case "NORTHEAST":  Bearing = 45.0;  return true;
        case "ENE":                    Bearing = 67.5;  return true;
        case "E":   case "EAST":       Bearing = 90.0;  return true;
        case "ESE":                    Bearing = 112.5; return true;
        case "SE":  case "SOUTHEAST":  Bearing = 135.0; return true;
        case "SSE":                    Bearing = 157.5; return true;
        case "S":   case "SOUTH":      Bearing = 180.0; return true;
        case "SSW":                    Bearing = 202.5; return true;
        case "SW":  case "SOUTHWEST":  Bearing = 225.0; return true;
        case "WSW":                    Bearing = 247.5; return true;
        case "W":   case "WEST":       Bearing = 270.0; return true;
        case "WNW":                    Bearing = 292.5; return true;
        case "NW":  case "NORTHWEST":  Bearing = 315.0; return true;
        case "NNW":                    Bearing = 337.5; return true;
    }

    if (!IsDecimal(T))
        return false;

    Bearing = float(T);
    if (Bearing > 360.0)
        return false;
    if (Bearing == 360.0)
        Bearing = 0.0;
    return true;
}

// Where an aircraft must start to fly over Target on the given bearing (north = +X, east = +Y, matching the map grid):
// straight back along the flight path to the edge of the playable area plus the aircraft's usual spawn buffer
function bool GetDirectedSpawnLoc(vector Target, float Bearing, float HeightOffset, class<ROSupportAircraft> AircraftClass, out vector SpawnLoc)
{
    local array<actor> AllMapBounds;
    local float WorldMinX, WorldMinY, WorldMaxX, WorldMaxY, Buffer, Rad, BackX, BackY, DistX, DistY, Dist;

    if (!FindActorsOfClass(class'ROVolumeMapBounds', AllMapBounds)
        || !ROVolumeMapBounds(AllMapBounds[0]).GetBounds(WorldMinX, WorldMinY, WorldMaxX, WorldMaxY))
        return false;

    // A target outside the playable area still needs a run-in that starts beyond it
    WorldMinX = FMin(WorldMinX, Target.X);
    WorldMaxX = FMax(WorldMaxX, Target.X);
    WorldMinY = FMin(WorldMinY, Target.Y);
    WorldMaxY = FMax(WorldMaxY, Target.Y);

    Buffer = AircraftClass.static.GetWorldEdgeSpawnBuffer();
    Rad = Bearing * DegToRad;
    BackX = -Cos(Rad);
    BackY = -Sin(Rad);

    Dist = 10000000.0;
    if (Abs(BackX) > 0.0001)
    {
        DistX = ((BackX > 0 ? WorldMaxX + Buffer : WorldMinX - Buffer) - Target.X) / BackX;
        Dist = FMin(Dist, DistX);
    }
    if (Abs(BackY) > 0.0001)
    {
        DistY = ((BackY > 0 ? WorldMaxY + Buffer : WorldMinY - Buffer) - Target.Y) / BackY;
        Dist = FMin(Dist, DistY);
    }

    if (Dist <= 0.0 || Dist >= 10000000.0)
        return false;

    SpawnLoc.X = Target.X + BackX * Dist;
    SpawnLoc.Y = Target.Y + BackY * Dist;
    SpawnLoc.Z = AllMapBounds[0].Location.Z + HeightOffset;
    return true;
}

// Applies --salvos/-s, --shells/-n, --spread/-r and --interval/-i (and any --delay already put in the profile) on top of the strike type's profile for this
// call, and with --persist/-p (admins only, it rewrites the server's saved profile) stores the result as the saved profile. Returns false (after telling
// the caller) if the call must stop. Aircraft have no profile: their --salvos and --interval are read by ParseAircraftRepeat.
function bool ApplyProfileOverrides(PlayerController Caller, bool bAdmin, bool bShellType, string StrikeType, array<string> Tokens, out FSProfile Profile)
{
    local bool bSalvos, bShells, bSpread, bInterval, bPersist;
    local string Value;
    local int i;

    bSalvos = class'CmdOptions'.static.Has(Tokens, "salvos", "s");
    bShells = class'CmdOptions'.static.Has(Tokens, "shells", "n");
    bSpread = class'CmdOptions'.static.Has(Tokens, "spread", "r");
    bInterval = class'CmdOptions'.static.Has(Tokens, "interval", "i");
    bPersist = class'CmdOptions'.static.Has(Tokens, "persist", "p");

    if (!(bSalvos || bShells || bSpread || bInterval || bPersist))
        return true;

    if (!bShellType)
    {
        if (bShells || bSpread || bPersist)
        {
            PrivateMessage(Caller, "[CMenu] Shells, spread and persist only apply to mortar, artillery, airburst, rocket, wp and mixed.");
            return false;
        }
        return true;
    }
    if (bPersist && !bAdmin)
    {
        PrivateMessage(Caller, "[CMenu] Only admins can save a fire support profile with --persist.");
        return false;
    }

    if (bSalvos)
    {
        Value = class'CmdOptions'.static.Get(Tokens, "salvos", "s");
        if (!IsNumeric(Value)) { ArgError(Caller, "--salvos must be a whole number (1-20)"); return false; }
        Profile.Salvos = Clamp(int(Value), 1, 20);
    }
    if (bShells)
    {
        Value = class'CmdOptions'.static.Get(Tokens, "shells", "n");
        if (!IsNumeric(Value)) { ArgError(Caller, "--shells must be a whole number (1-100)"); return false; }
        Profile.Shells = Clamp(int(Value), 1, 100);
    }
    if (bSpread)
    {
        Value = class'CmdOptions'.static.Get(Tokens, "spread", "r");
        if (!IsDecimal(Value)) { ArgError(Caller, "--spread must be a number of meters (0-200)"); return false; }
        Profile.Spread = Clamp(Round(float(Value) * 50.0), 0, 10000);
    }
    if (bInterval)
    {
        Value = class'CmdOptions'.static.Get(Tokens, "interval", "i");
        if (!IsNumeric(Value)) { ArgError(Caller, "--interval must be a whole number of seconds (1-120)"); return false; }
        Profile.Interval = Clamp(int(Value), 1, 120);
    }

    if (bPersist)
    {
        for (i = 0; i < FSProfiles.Length; i++)
        {
            if (FSProfiles[i].StrikeType ~= StrikeType)
            {
                FSProfiles[i] = Profile;
                SaveConfig();
                PrivateMessage(Caller, "[CMenu] Saved "$StrikeType$" profile: "$Profile.Salvos$" salvos, "$Profile.Shells$" shells, spread "$UUToMetersText(Profile.Spread)$"m, interval "$Profile.Interval$"s, delay "$Profile.Delay$"s");
                break;
            }
        }
    }

    return true;
}

// Napalm, Canberra and gunship runs can be repeated: --salvos/-s is how many strikes in all (1-10) and --interval/-i the
// seconds between each strike after the first (1-300, 30 when only --salvos is given)
function bool ParseAircraftRepeat(PlayerController Caller, array<string> Tokens, out int Strikes, out int RepeatInterval)
{
    local string Value;
    local bool bInterval;

    Strikes = 1;
    RepeatInterval = 0;

    if (class'CmdOptions'.static.Has(Tokens, "salvos", "s"))
    {
        Value = class'CmdOptions'.static.Get(Tokens, "salvos", "s");
        if (!IsNumeric(Value))
        {
            ArgError(Caller, "--salvos must be a whole number of strikes (1-10)");
            return false;
        }
        Strikes = Clamp(int(Value), 1, 10);
    }

    bInterval = class'CmdOptions'.static.Has(Tokens, "interval", "i");
    if (bInterval)
    {
        Value = class'CmdOptions'.static.Get(Tokens, "interval", "i");
        if (!IsNumeric(Value))
        {
            ArgError(Caller, "--interval must be a whole number of seconds (1-300)");
            return false;
        }
        RepeatInterval = Clamp(int(Value), 1, 300);
        if (Strikes == 1)
            PrivateMessage(Caller, "[CMenu] --interval only matters with --salvos 2 or more, so this is a single strike.");
    }
    else if (Strikes > 1)
    {
        RepeatInterval = 30;
    }

    return true;
}

// The caller as the owner of a strike, when it is for their own team. Its damage is then the caller's, so the game's
// friendly fire rules apply to it as to any weapon: the server's friendly fire setting (and Realism Match's, which turns
// it off in the briefing and on at LIVE) decides whether it hurts the caller's team, and the caller is always hurt by it.
// A spectator, or an admin calling for the other team, has no team of their own on the strike, so it is started without
// an owner (no kill credit, and nothing in the commander's ability tracking).
function Actor StrikeOwner(PlayerController Caller, int Team)
{
    if (Caller != None && Caller.GetTeamNum() == Team)
        return Caller;
    return None;
}

// Which team a call is for: the caller's own, or --team north / south. Spectators have no team, so they must say which one.
// Admins can call for either team. Returns false (after telling the caller) when the call has to stop.
function bool ResolveStrikeTeam(PlayerController Caller, bool bAdmin, array<string> Tokens, out int Team)
{
    local string Text;
    local int Parsed, Own;

    Own = Caller.GetTeamNum();
    Team = Own;

    if (class'CmdOptions'.static.Has(Tokens, "team"))
    {
        Text = class'CmdOptions'.static.Get(Tokens, "team");
        Parsed = class'CmdOptions'.static.ParseTeam(Text);
        if (Parsed != `AXIS_TEAM_INDEX && Parsed != `ALLIES_TEAM_INDEX)
        {
            ArgError(Caller, "--team must be north or south");
            return false;
        }
        if (Own == `AXIS_TEAM_INDEX || Own == `ALLIES_TEAM_INDEX)
        {
            if (Parsed != Own && !bAdmin)
            {
                PrivateMessage(Caller, "[CMenu] Only admins can use fire support for the other team.");
                return false;
            }
        }
        Team = Parsed;
        return true;
    }

    if (Own != `AXIS_TEAM_INDEX && Own != `ALLIES_TEAM_INDEX)
    {
        PrivateMessage(Caller, "[CMenu] Spectators pick a side: add --team north or --team south.");
        return false;
    }
    return true;
}

// Where the caller is looking: the spot their view line first hits on the ground or a building. Their own game's answer
// when there is one (see AskClientForLook), otherwise the server's view of them (right for a player, not a spectator).
function bool GetLookTarget(PlayerController Caller, out vector Target)
{
    local vector ViewLoc, HitLoc, HitNormal;
    local rotator ViewRot;
    local Actor Hit;

    if (LookCaller == Caller)
    {
        Target = LookFromClient;
        return bLookFromClientHit;
    }

    Caller.GetPlayerViewPoint(ViewLoc, ViewRot);
    Hit = Trace(HitLoc, HitNormal, ViewLoc + vector(ViewRot) * 100000.0, ViewLoc, false);
    if (Hit == None)
        return false;

    Target = HitLoc;
    return true;
}

// ArgText is "<type> <grid | MARK>"; Tokens is the whole command, searched for the barrage setting options
function FireSupportCommand(PlayerController Caller, string ArgText, array<string> Tokens)
{
    local array<string> Args;
    local bool bAdmin, bUseMark, bShellType, bDirection, bSuppress, bLook;
    local array<class<ROArtilleryShell> > ShellClasses;
    local string StrikeType, GridText, Where, DirText, Value;
    local int Team, i, FirstDelay, Strikes, RepeatInterval;
    local float Remaining, Bearing;
    local vector Target;
    local vector2D StrikeDir;
    local ROTeamInfo ROTI;
    local ROGameInfo ROGI;
    local FSProfile Profile;
    local bool bFired;

    // --look: first ask the caller's game where they are looking (the command runs again with the answer)
    if (class'CmdOptions'.static.Has(Tokens, "look", "k") && AskClientForLook(Caller))
        return;

    Args = SplitString("FIRESUPPORT "$ArgText, " ", true);

    bAdmin = IsAuthorized(Caller);
    if (!bAdmin && !bFSPlayersCanCall)
    {
        PrivateMessage(Caller, "[CMenu] Fire support is not enabled for players.");
        return;
    }

    if (Args.Length < 2)
    {
        FireSupportHelp(Caller);
        return;
    }

    StrikeType = Caps(Args[1]);
    if (!IsValidFSType(StrikeType))
    {
        FireSupportHelp(Caller);
        return;
    }

    bShellType = GetFSShellClasses(StrikeType, ShellClasses);
    if (bShellType && !FindFSProfile(StrikeType, Profile))
    {
        PrivateMessage(Caller, "[CMenu] No fire support profile configured for "$StrikeType$".");
        return;
    }

    bSuppress = class'CmdOptions'.static.Has(Tokens, "suppress", "q");

    bDirection = class'CmdOptions'.static.Has(Tokens, "direction", "b") || class'CmdOptions'.static.Has(Tokens, "dir");
    if (bDirection)
    {
        if (StrikeType != "NAPALM" && StrikeType != "CANBERRA")
        {
            PrivateMessage(Caller, "[CMenu] --direction only applies to napalm and canberra.");
            return;
        }

        DirText = class'CmdOptions'.static.Get(Tokens, "direction", "b");
        if (DirText == "")
            DirText = class'CmdOptions'.static.Get(Tokens, "dir");
        if (!ParseBearing(DirText, Bearing))
        {
            ArgError(Caller, "--direction must be a compass point (N, NE, ESE, ...) or a bearing from 0 to 360, e.g. --direction SW or -b 225");
            return;
        }
    }

    // First strike delay: barrages hold their first salvo back, aircraft wait before taking off
    if (class'CmdOptions'.static.Has(Tokens, "delay", "d"))
    {
        Value = class'CmdOptions'.static.Get(Tokens, "delay", "d");
        if (!IsNumeric(Value))
        {
            ArgError(Caller, "--delay must be a whole number of seconds (10-300)");
            return;
        }

        FirstDelay = Clamp(int(Value), 10, 300);
        if (FirstDelay != int(Value))
            PrivateMessage(Caller, "[CMenu] The first strike delay is between 10 and 300 seconds, using "$FirstDelay$".");
        if (bShellType)
            Profile.Delay = FirstDelay;
    }

    if (!ApplyProfileOverrides(Caller, bAdmin, bShellType, StrikeType, Tokens, Profile))
        return;

    Strikes = 1;
    if (!bShellType && !ParseAircraftRepeat(Caller, Tokens, Strikes, RepeatInterval))
        return;

    if (!ResolveStrikeTeam(Caller, bAdmin, Tokens, Team))
        return;

    // Fire support does not wait for a round: it works between rounds, in the briefing and for spectators
    ROGI = ROGameInfo(WorldInfo.Game);
    ROTI = ROTeamInfo(WorldInfo.GRI.Teams[Team]);
    if (ROTI == None || ROGI == None || ROPlayerController(Caller) == None)
    {
        PrivateMessage(Caller, "[CMenu] Fire support is not available right now.");
        return;
    }

    if (!bAdmin && WorldInfo.TimeSeconds < FSNextCallTime[Team])
    {
        Remaining = FSNextCallTime[Team] - WorldInfo.TimeSeconds;
        PrivateMessage(Caller, "[CMenu] Fire support is on cooldown for "$int(Remaining + 0.99)$" more seconds.");
        return;
    }

    for (i = 2; i < Args.Length; i++)
    {
        if (GridText == "")
            GridText = Args[i];
        else
            GridText = GridText$" "$Args[i];
    }

    bLook = class'CmdOptions'.static.Has(Tokens, "look", "k");
    bUseMark = !bLook && (GridText == "" || IsMarkSelector(GridText));
    if (bLook)
    {
        if (!GetLookTarget(Caller, Target))
        {
            PrivateMessage(Caller, "[CMenu] There is nothing in view to target. Look at the ground, or give a grid.");
            return;
        }
        Where = "the spot "$Caller.PlayerReplicationInfo.PlayerName$" is looking at";
    }
    else if (bUseMark)
    {
        if (!ResolveMarkTarget(Caller, bAdmin, ROTI, MarkSelectorText(GridText), Target, StrikeDir, Where))
            return;
    }
    else
    {
        if (!GridToWorldLocation(GridText, Target))
        {
            ArgError(Caller, "Invalid grid. Use a letter A-J and number 1-10, e.g. E 5 kp 5");
            return;
        }
        Where = "grid "$Caps(GridText);
    }

    if (!bAdmin && IsInNoArtyVolume(Target))
    {
        PrivateMessage(Caller, "[CMenu] That location is protected from fire support.");
        return;
    }

    // Admin strikes ignore the no-artillery zones, which also fence off the area outside the combat area
    if (bShellType)
    {
        bFired = SpawnShellStrike(Caller, StrikeType, Target, Profile, Team);
        RegisterFSStrike(Caller, Team, Profile.Delay + (Profile.Salvos * (Profile.Interval + Profile.Shells)) + 30.0);
    }
    else
    {
        if (FirstDelay > 0)
        {
            QueueAircraftStrike(Caller, StrikeType, Target, StrikeDir, bDirection, Bearing, bAdmin, FirstDelay, Team);
            bFired = (ROPlayerController(Caller) != None);
        }
        else
        {
            bFired = LaunchAircraftStrike(Caller, StrikeType, Target, StrikeDir, bDirection, Bearing, bAdmin, Team);
        }

        // Every strike after the first waits its turn behind the first strike delay
        if (bFired)
        {
            for (i = 1; i < Strikes; i++)
                QueueAircraftStrike(Caller, StrikeType, Target, StrikeDir, bDirection, Bearing, bAdmin, FirstDelay + i * RepeatInterval, Team);
        }
        RegisterFSStrike(Caller, Team, 120.0 + FirstDelay + (Strikes - 1) * RepeatInterval + (StrikeType == "SPOOKY" ? FSGunshipDuration : 0));
    }

    if (!bFired)
    {
        PrivateMessage(Caller, "[CMenu] Fire support failed to spawn.");
        return;
    }

    if (!bAdmin)
        FSNextCallTime[Team] = WorldInfo.TimeSeconds + FSPlayerCooldown;

    if (bDirection)
        Where = Where$", flying on a heading of "$TenthsText(Round(Bearing * 10.0))$" degrees";
    if (FirstDelay > 0)
        Where = Where$", first strike in "$FirstDelay$" seconds";
    if (Strikes > 1)
        Where = Where$", "$Strikes$" strikes "$RepeatInterval$" seconds apart";

    if (Caller.GetTeamNum() != Team)
    {
        if (Team == `AXIS_TEAM_INDEX)
            Where = Where$" for the North";
        else
            Where = Where$" for the South";
    }

    if (!bFSSilent && !bSuppress)
        WorldInfo.Game.Broadcast(self, "[CMenu] "$Caller.PlayerReplicationInfo.PlayerName$" called in a "$FSDisplayName(StrikeType)$" at "$Where);
    else
        PrivateMessage(Caller, "[CMenu] Called in a "$FSDisplayName(StrikeType)$" at "$Where);
}

// Puts a strike on the map of the team it is for, or of both teams when a spectator called it. The game draws the target
// (with the salvos left and the heading) and the aircraft from the team's info, so this fills it in the way a commander's
// call does, and UpdateFSMap keeps it up to date and clears it when the strike is over.
function ShowOnMap(Actor Strike, int Team, PlayerController Caller, vector Target, vector2D Dir)
{
    local FSMapStrike Entry;
    local int Own;

    Own = 255;
    if (Caller != None)
        Own = Caller.GetTeamNum();

    Entry.Strike = Strike;
    Entry.Team = Team;
    Entry.bBothTeams = (Own != `AXIS_TEAM_INDEX && Own != `ALLIES_TEAM_INDEX);
    Entry.Target = Target;
    Entry.Dir = Dir;
    FSMapStrikes.AddItem(Entry);

    if (!IsTimerActive('UpdateFSMap'))
        SetTimer(1.0, true, 'UpdateFSMap');
    UpdateFSMap();
}

function bool IsNoStrikeLocation(vector V)
{
    return V == vect(-999999.0,-999999.0,-999999.0);
}

// Takes a strike off a team's map, unless the commander's own strike has taken the spot
function ClearMapFor(FSMapStrike Entry, int T)
{
    local ROTeamInfo ROTI;

    ROTI = ROTeamInfo(WorldInfo.GRI.Teams[T]);
    if (ROTI == None)
        return;

    if (ROTI.ArtyStrikeLocation == FSMapShown[T] && !IsNoStrikeLocation(FSMapShown[T]))
    {
        ROTI.ArtyStrikeLocation = vect(-999999.0,-999999.0,-999999.0);
        ROTI.StrikeDirection = vect2D(0,0);
        FSMapShown[T] = ROTI.ArtyStrikeLocation;
    }

    if (ROSupportAircraft(Entry.Strike) != None)
    {
        if (ROTI.ActiveSupportAircraft == ROSupportAircraft(Entry.Strike))
        {
            ROTI.ActiveSupportAircraft = ROTI.SecondarySupportAircraft;
            ROTI.SecondarySupportAircraft = None;
        }
        else if (ROTI.SecondarySupportAircraft == ROSupportAircraft(Entry.Strike))
            ROTI.SecondarySupportAircraft = None;
    }
}

function ApplyMapFor(FSMapStrike Entry, int T)
{
    local ROTeamInfo ROTI;
    local ROArtillerySpawner Spawner;
    local ROSupportAircraft Aircraft;

    ROTI = ROTeamInfo(WorldInfo.GRI.Teams[T]);
    if (ROTI == None)
        return;

    // The spot is free, or it is the one this mod put there; a commander's own strike is left alone
    if (IsNoStrikeLocation(ROTI.ArtyStrikeLocation) || ROTI.ArtyStrikeLocation == FSMapShown[T])
    {
        ROTI.ArtyStrikeLocation = Entry.Target;
        ROTI.StrikeDirection = Entry.Dir;
        FSMapShown[T] = Entry.Target;

        Spawner = ROArtillerySpawner(Entry.Strike);
        if (Spawner != None)
            ROTI.RemainingSalvos = Max(Spawner.SalvoAmount - Spawner.SalvoCounter, 0) + 1;
    }

    // Aircraft started without an owner are not tracked by the game, so show them here
    Aircraft = ROSupportAircraft(Entry.Strike);
    if (Aircraft != None && Aircraft.bNoGameTracking && ROTI.ActiveSupportAircraft != Aircraft && ROTI.SecondarySupportAircraft != Aircraft)
    {
        if (ROTI.ActiveSupportAircraft == None || ROTI.ActiveSupportAircraft.bDeleteMe)
            ROTI.ActiveSupportAircraft = Aircraft;
        else if (ROTI.SecondarySupportAircraft == None)
            ROTI.SecondarySupportAircraft = Aircraft;
    }
}

function UpdateFSMap()
{
    local int i, t;

    for (i = FSMapStrikes.Length - 1; i >= 0; i--)
    {
        if (FSMapStrikes[i].Strike == None || FSMapStrikes[i].Strike.bDeleteMe)
        {
            for (t = 0; t < 2; t++)
            {
                if (FSMapStrikes[i].bBothTeams || FSMapStrikes[i].Team == t)
                    ClearMapFor(FSMapStrikes[i], t);
            }
            FSMapStrikes.Remove(i, 1);
        }
    }

    for (i = 0; i < FSMapStrikes.Length; i++)
    {
        for (t = 0; t < 2; t++)
        {
            if (FSMapStrikes[i].bBothTeams || FSMapStrikes[i].Team == t)
                ApplyMapFor(FSMapStrikes[i], t);
        }
    }

    if (FSMapStrikes.Length == 0)
        ClearTimer('UpdateFSMap');
}

// Remembers a strike so CancelFireSupport can stop it
function TrackFSStrike(Actor Strike, int Team)
{
    local FSTrackedStrike Entry;
    local int i;

    for (i = FSTrackedStrikes.Length - 1; i >= 0; i--)
    {
        if (FSTrackedStrikes[i].Strike == None || FSTrackedStrikes[i].Strike.bDeleteMe)
            FSTrackedStrikes.Remove(i, 1);
    }

    Entry.Strike = Strike;
    Entry.Team = Team;
    FSTrackedStrikes.AddItem(Entry);
}

// Stops this mod's fire support: the barrages and shells already in the air, the aircraft and the strikes still waiting
// for their delay. Only one team's, or every team's with bAll. Returns how many strikes were stopped.
function int CancelFireSupport(int Team, bool bAll)
{
    local int i, Count;
    local ROArtillerySpawner Spawner;
    local ROSupportAircraft Aircraft;
    local ROArtilleryShell Shell;
    local Actor Strike;

    for (i = FSPendingStrikes.Length - 1; i >= 0; i--)
    {
        if (bAll || FSPendingStrikes[i].Caller == None || FSPendingStrikes[i].Team == Team)
        {
            FSPendingStrikes.Remove(i, 1);
            Count++;
        }
    }
    if (FSPendingStrikes.Length == 0)
        ClearTimer('ProcessPendingStrikes');

    for (i = FSTrackedStrikes.Length - 1; i >= 0; i--)
    {
        Strike = FSTrackedStrikes[i].Strike;
        if (Strike == None || Strike.bDeleteMe)
        {
            FSTrackedStrikes.Remove(i, 1);
            continue;
        }
        if (!bAll && FSTrackedStrikes[i].Team != Team)
            continue;

        Spawner = ROArtillerySpawner(Strike);
        if (Spawner != None)
        {
            foreach DynamicActors(class'ROArtilleryShell', Shell)
            {
                if (Shell.MyArtySpawner == Spawner)
                    Shell.Destroy();
            }
            if (Spawner.AvoidMarker != None)
                Spawner.AvoidMarker.Destroy();
            Spawner.Destroy();
        }
        else
        {
            Aircraft = ROSupportAircraft(Strike);
            if (Aircraft != None)
            {
                // Not refunded: the commander's own ability timers are not ours to change
                Aircraft.CallOffStrike(false);
                Aircraft.Destroy();
            }
        }

        FSTrackedStrikes.Remove(i, 1);
        Count++;
    }

    for (i = FSActiveStrikes.Length - 1; i >= 0; i--)
    {
        if (bAll || FSActiveStrikes[i].Team == Team)
            FSActiveStrikes.Remove(i, 1);
    }

    UpdateFSMap();
    return Count;
}

// mutate cancelfiresupport: stops your team's fire support. With --all (-a, admins only) stops every team's.
function CancelFireSupportCommand(PlayerController Caller, array<string> Tokens)
{
    local bool bAdmin, bAll;
    local int Team, Count;
    local string Who;

    bAdmin = IsAuthorized(Caller);
    if (!bAdmin && !bFSPlayersCanCall)
    {
        PrivateMessage(Caller, "[CMenu] Fire support is not enabled for players.");
        return;
    }

    bAll = class'CmdOptions'.static.Has(Tokens, "all", "a");
    if (bAll && !bAdmin)
    {
        PrivateMessage(Caller, "[CMenu] Only admins can cancel every team's fire support.");
        return;
    }

    if (!bAll && !ResolveStrikeTeam(Caller, bAdmin, Tokens, Team))
        return;

    Count = CancelFireSupport(Team, bAll);
    if (Count == 0)
    {
        PrivateMessage(Caller, bAll ? "[CMenu] There is no fire support in progress." : "[CMenu] Your team has no fire support in progress.");
        return;
    }

    Who = bAll ? "every team's" : "their team's";
    if (!bFSSilent)
        WorldInfo.Game.Broadcast(self, "[CMenu] "$Caller.PlayerReplicationInfo.PlayerName$" cancelled "$Who$" fire support ("$Count$" stopped)");
    else
        PrivateMessage(Caller, "[CMenu] Cancelled "$Who$" fire support ("$Count$" stopped)");
}

function bool SpawnShellStrike(PlayerController Caller, string StrikeType, vector Target, FSProfile Profile, int Team)
{
    local ROArtillerySpawner Spawner;
    local array<class<ROArtilleryShell> > ShellClasses;
    local vector SpawnLoc, MyGravity;
    local int i;

    if (!GetFSShellClasses(StrikeType, ShellClasses))
        return false;

    MyGravity.Z = WorldInfo.WorldGravityZ;

    SpawnLoc = Target;
    SpawnLoc.Z = ROGameReplicationInfo(WorldInfo.GRI).ArtySpawn.Z;
    if (SpawnLoc.Z < Target.Z + 1000)
        SpawnLoc.Z = Target.Z + 5000;

    // Spawned without an owner so the base game doesn't track it against the team commander's strike
    Spawner = Spawn(class'CMArtillerySpawner',,, SpawnLoc, rotator(MyGravity));
    if (Spawner == None)
        return false;

    Spawner.ClearTimer();
    Spawner.bValuesPreConfigured = true;
    Spawner.InstigatorController = Controller(StrikeOwner(Caller, Team));
    Spawner.OwningTeam = Team;
    Spawner.SpawnTeam = Team;
    Spawner.OriginalArtyLocation = Target;
    Spawner.BatterySize = Max(Profile.Shells, 1);
    Spawner.SalvoAmount = Max(Profile.Salvos - 1, 0);
    Spawner.SpreadAmount = Max(Profile.Spread, 0);
    Spawner.SalvoInterval = Max(Profile.Interval, 1);
    Spawner.StrikeDelay = Max(Profile.Delay, 1);

    Spawner.ArtilleryShellClassesAvailNorth.Length = 0;
    Spawner.ArtilleryShellClassesAvailSouth.Length = 0;
    for (i = 0; i < ShellClasses.Length; i++)
    {
        if (Team == `AXIS_TEAM_INDEX)
            Spawner.ArtilleryShellClassesAvailNorth.AddItem(ShellClasses[i]);
        else
            Spawner.ArtilleryShellClassesAvailSouth.AddItem(ShellClasses[i]);
    }

    TrackFSStrike(Spawner, Team);
    Spawner.StartBarrage();
    ShowOnMap(Spawner, Team, Caller, Target, vect2D(0, 0));
    return true;
}

// "--mark", "--mark SL3", "SL1" or "CMD" rather than a grid
function bool IsMarkSelector(string Text)
{
    local string T;

    T = Caps(Text);
    return Left(T, 4) == "MARK" || Left(T, 2) == "SL" || T == "CMD" || T == "CO" || T == "COMMANDER";
}

// The part of "MARK SL3" that picks the mark: "SL3"
function string MarkSelectorText(string Text)
{
    if (Caps(Left(Text, 4)) == "MARK")
        return Mid(Text, 4);
    return Text;
}

// Takes the aircraft off now; false if it couldn't be spawned
function bool LaunchAircraftStrike(PlayerController Caller, string StrikeType, vector Target, vector2D StrikeDir, bool bForceBearing, float Bearing, bool bIgnoreNoArty, int Team)
{
    local ROPlayerController ROPC;

    ROPC = ROPlayerController(Caller);
    if (ROPC == None)
        return false;

    switch (StrikeType)
    {
        case "NAPALM":
            return SpawnNapalmStrike(ROPC, Target, StrikeDir, bForceBearing, Bearing, bIgnoreNoArty, Team);
        case "CANBERRA":
            return SpawnBombingRun(ROPC, Target, StrikeDir, bForceBearing, Bearing, bIgnoreNoArty, Team);
        case "SPOOKY":
            return SpawnGunshipStrike(ROPC, Target, Team);
    }
    return false;
}

// Holds an aircraft strike back for the first strike delay
function QueueAircraftStrike(PlayerController Caller, string StrikeType, vector Target, vector2D StrikeDir, bool bForceBearing, float Bearing, bool bIgnoreNoArty, int Delay, int Team)
{
    local FSPendingStrike Pending;

    Pending.Caller = Caller;
    Pending.StrikeType = StrikeType;
    Pending.Target = Target;
    Pending.StrikeDir = StrikeDir;
    Pending.bForceBearing = bForceBearing;
    Pending.Bearing = Bearing;
    Pending.bIgnoreNoArty = bIgnoreNoArty;
    Pending.FireTime = WorldInfo.TimeSeconds + Delay;
    Pending.Team = Team;
    FSPendingStrikes.AddItem(Pending);

    if (!IsTimerActive('ProcessPendingStrikes'))
        SetTimer(1.0, true, 'ProcessPendingStrikes');
}

function ProcessPendingStrikes()
{
    local FSPendingStrike Pending;
    local ROGameInfo ROGI;
    local int i;

    ROGI = ROGameInfo(WorldInfo.Game);

    for (i = FSPendingStrikes.Length - 1; i >= 0; i--)
    {
        if (FSPendingStrikes[i].FireTime > WorldInfo.TimeSeconds)
            continue;

        Pending = FSPendingStrikes[i];
        FSPendingStrikes.Remove(i, 1);

        // The caller left while the strike was waiting
        if (Pending.Caller == None || ROGI == None)
            continue;

        if (!LaunchAircraftStrike(Pending.Caller, Pending.StrikeType, Pending.Target, Pending.StrikeDir, Pending.bForceBearing, Pending.Bearing, Pending.bIgnoreNoArty, Pending.Team))
            PrivateMessage(Pending.Caller, "[CMenu] Fire support failed to spawn.");
    }

    if (FSPendingStrikes.Length == 0)
        ClearTimer('ProcessPendingStrikes');
}

// Aircraft are despawned once they leave the map bounds after reaching their target, which would end a run on a
// target outside the combat area straight away. Make room around the target so they get to finish.
function WidenAircraftLimits(ROSupportAircraft Aircraft, vector Target)
{
    local float Margin;

    Margin = 12500.0; // 250 meters
    Aircraft.WorldMinX = FMin(Aircraft.WorldMinX, Target.X - Margin);
    Aircraft.WorldMaxX = FMax(Aircraft.WorldMaxX, Target.X + Margin);
    Aircraft.WorldMinY = FMin(Aircraft.WorldMinY, Target.Y - Margin);
    Aircraft.WorldMaxY = FMax(Aircraft.WorldMaxY, Target.Y + Margin);
}

function bool SpawnNapalmStrike(ROPlayerController Caller, vector Target, vector2D StrikeDir, bool bForceBearing, float Bearing, bool bIgnoreNoArty, int Team)
{
    local ROMapInfo ROMI;
    local ROGameReplicationInfo ROGRI;
    local class<RONapalmStrikeAircraft> AircraftClass;
    local RONapalmStrikeAircraft Aircraft;
    local vector SpawnLoc, AimTarget;

    ROMI = ROMapInfo(WorldInfo.GetMapInfo());
    ROGRI = ROGameReplicationInfo(WorldInfo.GRI);

    if (ROMI != None && ROMI.SouthernForce == SFOR_ARVN)
        AircraftClass = class'CMNapalmStrikeAircraftARVN';
    else
        AircraftClass = class'CMNapalmStrikeAircraft';

    if (!bForceBearing || !GetDirectedSpawnLoc(Target, Bearing, ROMI.NapalmStrikeHeightOffset, AircraftClass, SpawnLoc))
        SpawnLoc = Caller.GetBestAircraftSpawnLoc(Target, ROMI.NapalmStrikeHeightOffset, AircraftClass, StrikeDir);
    AimTarget = Target;
    AimTarget.Z = SpawnLoc.Z;

    Aircraft = Spawn(AircraftClass, StrikeOwner(Caller, Team),, SpawnLoc, rotator(AimTarget - SpawnLoc));
    if (Aircraft == None)
        return false;
    Aircraft.OwningTeam = Team;

    if (CMNapalmStrikeAircraft(Aircraft) != None)
        CMNapalmStrikeAircraft(Aircraft).bIgnoreNoArty = bIgnoreNoArty;
    else if (CMNapalmStrikeAircraftARVN(Aircraft) != None)
        CMNapalmStrikeAircraftARVN(Aircraft).bIgnoreNoArty = bIgnoreNoArty;
    WidenAircraftLimits(Aircraft, Target);

    Aircraft.TargetLocation = Target;
    Aircraft.CachedAirSupportTime = ROGRI.NextAbilityThreeTime[Team]; // Keeps the commander's ability timer unchanged if the strike is aborted
    Aircraft.SetDropPoint();
    TrackFSStrike(Aircraft, Team);
    ShowOnMap(Aircraft, Team, Caller, Target, StrikeDir);
    return true;
}

function bool SpawnBombingRun(ROPlayerController Caller, vector Target, vector2D StrikeDir, bool bForceBearing, float Bearing, bool bIgnoreNoArty, int Team)
{
    local ROMapInfo ROMI;
    local ROGameReplicationInfo ROGRI;
    local CMCarpetBomberAircraft Aircraft;
    local vector SpawnLoc, AimTarget;
    local float HeightOffset;
    local int i, NumBombers;

    ROMI = ROMapInfo(WorldInfo.GetMapInfo());
    ROGRI = ROGameReplicationInfo(WorldInfo.GRI);
    NumBombers = (FSBomberCount <= 0) ? 2 : Clamp(FSBomberCount, 1, 2);

    HeightOffset = ROMI.bUseNapalmHeightOffsetForAll ? ROMI.NapalmStrikeHeightOffset : ROMI.CarpetBomberHeightOffset;
    if (!bForceBearing || !GetDirectedSpawnLoc(Target, Bearing, HeightOffset, class'ROCarpetBomberAircraft', SpawnLoc))
        SpawnLoc = Caller.GetBestAircraftSpawnLoc(Target, HeightOffset, class'ROCarpetBomberAircraft', StrikeDir);

    AimTarget = Target;
    AimTarget.Z = SpawnLoc.Z;

    for (i = 1; i <= NumBombers; i++)
    {
        Aircraft = Spawn(class'CMCarpetBomberAircraft', StrikeOwner(Caller, Team),, SpawnLoc, rotator(AimTarget - SpawnLoc));
        if (Aircraft == None)
            return (i > 1);

        Aircraft.OwningTeam = Team;

        Aircraft.bIgnoreNoArty = bIgnoreNoArty;
        WidenAircraftLimits(Aircraft, Target);

        Aircraft.TargetLocation = Target;
        Aircraft.CachedAirSupportTime = ROGRI.NextAbilityOneTime[Team];
        if (i == 2)
            Aircraft.InboundDelay += 1;
        Aircraft.SetDropPoint();
        Aircraft.SetOffset(i);
        TrackFSStrike(Aircraft, Team);
        ShowOnMap(Aircraft, Team, Caller, Target, StrikeDir);
    }
    return true;
}

function bool SpawnGunshipStrike(ROPlayerController Caller, vector Target, int Team)
{
    local ROGameReplicationInfo ROGRI;
    local ROGunshipAircraft Aircraft;
    local vector SpawnLoc, AimTarget;

    ROGRI = ROGameReplicationInfo(WorldInfo.GRI);

    SpawnLoc = Caller.GetBestAircraftSpawnLoc(Target, class'ROGunshipAircraft'.default.Altitude, class'ROGunshipAircraft');
    AimTarget = Target;
    AimTarget.Z = SpawnLoc.Z;

    Aircraft = Spawn(class'ROGunshipAircraft', StrikeOwner(Caller, Team),, SpawnLoc, rotator(AimTarget - SpawnLoc));
    if (Aircraft == None)
        return false;
    Aircraft.OwningTeam = Team;

    WidenAircraftLimits(Aircraft, Target);

    Aircraft.TargetLocation = Target;
    Aircraft.CachedAirSupportTime = ROGRI.NextAbilityOneTime[Team];
    Aircraft.CalculateOrbit();
    if (FSGunshipDuration > 0)
        Aircraft.OrbitDuration = FSGunshipDuration;
    TrackFSStrike(Aircraft, Team);
    ShowOnMap(Aircraft, Team, Caller, Target, vect2D(0, 0));
    return true;
}

// Remembers who called a strike so friendly fire can be suppressed for it when bFSNoFriendlyFire is on (see NetDamage)
function RegisterFSStrike(PlayerController Caller, int Team, float Duration)
{
    local FSActiveStrike Entry;
    local int i;

    for (i = FSActiveStrikes.Length - 1; i >= 0; i--)
    {
        if (FSActiveStrikes[i].Caller == None || FSActiveStrikes[i].ExpireTime < WorldInfo.TimeSeconds)
            FSActiveStrikes.Remove(i, 1);
    }

    Entry.Caller = Caller;
    Entry.Team = Team;
    Entry.bNoOwner = (StrikeOwner(Caller, Team) == None);
    Entry.ExpireTime = WorldInfo.TimeSeconds + Duration;
    FSActiveStrikes.AddItem(Entry);
}

function bool IsFSStrikeDamage(class<DamageType> DamageType)
{
    return ClassIsChildOf(DamageType, class'RODmgTypeArtillery')
        || ClassIsChildOf(DamageType, class'RODmgType_Napalm')
        || ClassIsChildOf(DamageType, class'RODmgType_AC47Gunship');
}

function NetDamage(int OriginalDamage, out int Damage, Pawn Injured, Controller InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
    local int i;

    // Runs before the base game applies friendly fire punishment, so zeroed damage can't get the caller kicked
    if (bFSNoFriendlyFire && Damage > 0 && Injured != None && IsFSStrikeDamage(DamageType))
    {
        for (i = 0; i < FSActiveStrikes.Length; i++)
        {
            if (((FSActiveStrikes[i].bNoOwner && InstigatedBy == None) || (InstigatedBy != None && FSActiveStrikes[i].Caller == InstigatedBy))
                && FSActiveStrikes[i].ExpireTime >= WorldInfo.TimeSeconds
                && Injured.GetTeamNum() == FSActiveStrikes[i].Team)
            {
                Damage = 0;
                break;
            }
        }
    }

    super.NetDamage(OriginalDamage, Damage, Injured, InstigatedBy, HitLocation, Momentum, DamageType, DamageCauser);
}

function bool IsInNoArtyVolume(vector Loc)
{
    local ROVolumeTest RVT;
    local bool bResult;

    RVT = Spawn(class'ROVolumeTest',,, Loc);
    if (RVT == None)
        return false;

    bResult = RVT.IsInNoArtyVolume();
    RVT.Destroy();
    return bResult;
}

function bool IsNumeric(string S)
{
    local int i;

    if (Len(S) == 0)
        return false;

    for (i = 0; i < Len(S); i++)
    {
        if (InStr("0123456789", Mid(S, i, 1)) == -1)
            return false;
    }
    return true;
}

// Converts "E 5 kp 5" / "E5" / "E5 kp 5" to a world location, using the same grid math as MutParadrops
function bool GridToWorldLocation(string GridText, out vector OutLoc)
{
    local array<string> Parts;
    local array<actor> AllMapBounds;
    local float WorldMinX, WorldMinY, WorldMaxX, WorldMaxY, GridSizeX, GridSizeY, KeypadX, KeypadY;
    local int Letter, GridNum, KeyPad, i, Row, Col;
    local vector HitLocation, HitNormal, TraceStart, TraceEnd;
    local Actor HitActor;

    Parts = SplitString(Caps(GridText), " ", true);
    if (Parts.Length == 0)
        return false;

    // Split a combined token such as "E5" into "E" and "5"
    if (Len(Parts[0]) > 1 && IsNumeric(Mid(Parts[0], 1)))
    {
        Parts.InsertItem(1, Mid(Parts[0], 1));
        Parts[0] = Left(Parts[0], 1);
    }

    if (Parts.Length < 2 || Len(Parts[0]) != 1 || !IsNumeric(Parts[1]))
        return false;

    Letter = Asc(Parts[0]) - 64;
    GridNum = int(Parts[1]);
    if (Letter < 1 || Letter > 10 || GridNum < 1 || GridNum > 10)
        return false;

    for (i = 2; i < Parts.Length; i++)
    {
        if (IsNumeric(Parts[i]))
        {
            KeyPad = int(Parts[i]);
            break;
        }
    }

    if (!FindActorsOfClass(class'ROVolumeMapBounds', AllMapBounds)
        || !ROVolumeMapBounds(AllMapBounds[0]).GetBounds(WorldMinX, WorldMinY, WorldMaxX, WorldMaxY))
        return false;

    GridSizeX = Abs(WorldMaxX - WorldMinX) / 10;
    GridSizeY = Abs(WorldMaxY - WorldMinY) / 10;
    KeypadX = GridSizeX / 3;
    KeypadY = GridSizeY / 3;

    OutLoc.X = WorldMaxX - Letter * GridSizeX;
    OutLoc.Y = WorldMinY + GridNum * GridSizeY;

    if (KeyPad >= 1 && KeyPad <= 9)
    {
        Row = (KeyPad - 1) / 3;
        Col = (KeyPad - 1) % 3;
        OutLoc.X += (Row + 0.5) * KeypadX;
        OutLoc.Y -= (2.5 - Col) * KeypadY;
    }
    else
    {
        OutLoc.X += 1.5 * KeypadX;
        OutLoc.Y -= 1.5 * KeypadY;
    }

    // Drop onto the highest world geometry at that spot
    TraceStart = OutLoc;
    TraceStart.Z = 15000;
    TraceEnd = OutLoc;
    TraceEnd.Z = -15000;
    HitActor = Trace(HitLocation, HitNormal, TraceEnd, TraceStart, false);
    if (HitActor == None)
        return false;

    OutLoc.Z = HitLocation.Z;
    return true;
}

// =================================================================
// Content Loading
// =================================================================
// Long help from the other mutators opens in the large console instead of flooding the chat
function BindHelpOutput()
{
    local Mutator Mut;

    for (Mut = ROGameInfo(WorldInfo.Game).BaseMutator; Mut != None; Mut = Mut.NextMutator)
    {
        if (MutRealismMatch(Mut) != None)
            MutRealismMatch(Mut).OnShowHelp = ShowHelpToPlayer;
    }
}

// Smoke drifts with the wind, and a map without a wind direction gives it none. When the map has no wind source, one is
// added facing a random direction (a different one each time the map loads).
function EnsureWind()
{
    local WindDirectionalSource Wind;
    local rotator Direction;

    foreach AllActors(class'WindDirectionalSource', Wind)
        return;

    Direction.Yaw = Rand(65536);
    Wind = Spawn(class'CMWindSource',,, vect(0, 0, 0), Direction);
    `log("[CMenu] The map has no wind direction; added one facing yaw "$Direction.Yaw);
}

function LoadObjects()
{
    local ROMapInfo               ROMI;
    local string                  WeaponName;

    BindHelpOutput();
    EnsureWind();
    ROMI = ROMapInfo(WorldInfo.GetMapInfo());

    // Load settings object
    ROMI.SharedContentReferences.AddItem(class<Settings>(DynamicLoadObject("MutCMenu.MutCMenuSettings", class'Class')));

    // Load extra content if enabled
    if (bLoadExtras || bForceModLoads)
    {
        foreach ExtrasToLoad(WeaponName)
        {
            if (WeaponName == "") continue;
            if (InStr(WeaponName, "Vehicle") != -1)
                ROMI.SharedContentReferences.AddItem(class<ROVehicle>(DynamicLoadObject(WeaponName, class'Class'))); // Load the object
            else if (InStr(WeaponName, "Weap") != -1 || InStr(WeaponName, "Item") != -1)
                ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject(WeaponName, class'Class'))); // Load the object
            else
                ROMI.SharedContentReferences.AddItem(class<Object>(DynamicLoadObject(WeaponName, class'Class'))); // Load the object
        }
    }
    // Load GOM3 content if enabled
    if (bLoadGOM3 || bForceModLoads)
    {
        foreach GOM3ToLoad(WeaponName)
        {
            if (WeaponName == "") continue;
            if (InStr(WeaponName, "Vehicle") != -1)
                ROMI.SharedContentReferences.AddItem(class<ROVehicle>(DynamicLoadObject(WeaponName, class'Class'))); // Load the object
            else if (InStr(WeaponName, "Weap") != -1 || InStr(WeaponName, "Item") != -1)
                ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject(WeaponName, class'Class'))); // Load the object
            else
                ROMI.SharedContentReferences.AddItem(class<Object>(DynamicLoadObject(WeaponName, class'Class'))); // Load the object
        }
    }
    // Load GOM4 content if enabled
    if (bLoadGOM4 || bForceModLoads)
    {
        foreach GOM4ToLoad(WeaponName)
        {
            if (WeaponName == "") continue;
            if (InStr(WeaponName, "Vehicle") != -1)
                ROMI.SharedContentReferences.AddItem(class<ROVehicle>(DynamicLoadObject(WeaponName, class'Class'))); // Load the object
            else if (InStr(WeaponName, "Weap") != -1 || InStr(WeaponName, "Item") != -1)
                ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject(WeaponName, class'Class'))); // Load the object
            else
                ROMI.SharedContentReferences.AddItem(class<Object>(DynamicLoadObject(WeaponName, class'Class'))); // Load the object
        }
    }
    // Load Winter War content if enabled
    if (bLoadWW || bForceModLoads)
    {
        foreach WWToLoad(WeaponName)
        {
            if (WeaponName == "") continue;
            if (InStr(WeaponName, "Vehicle") != -1)
                ROMI.SharedContentReferences.AddItem(class<ROVehicle>(DynamicLoadObject(WeaponName, class'Class'))); // Load the object
            else if (InStr(WeaponName, "Weap") != -1 || InStr(WeaponName, "Item") != -1)
                ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject(WeaponName, class'Class'))); // Load the object
            else
                ROMI.SharedContentReferences.AddItem(class<Object>(DynamicLoadObject(WeaponName, class'Class'))); // Load the object
        }
    }
    // Load WW2 content if enabled
    if (bLoadWW2 || bForceModLoads)
    {
        foreach WW2ToLoad(WeaponName)
        {
            if (WeaponName == "") continue;
            if (InStr(WeaponName, "Vehicle") != -1)
                ROMI.SharedContentReferences.AddItem(class<ROVehicle>(DynamicLoadObject(WeaponName, class'Class'))); // Load the object
            else if (InStr(WeaponName, "Weap") != -1 || InStr(WeaponName, "Item") != -1)
                ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject(WeaponName, class'Class'))); // Load the object
            else
                ROMI.SharedContentReferences.AddItem(class<Object>(DynamicLoadObject(WeaponName, class'Class'))); // Load the object
            
        }
    }
}

defaultproperties
{
}

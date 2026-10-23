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

var array<DummyActor>           DummyActors;
var array<vector2d>			    Corners;

var array<string>               LoggedInMutatorAdmins; // list of the names of all the players that are currently logged in as a mutator admin
var int                         NumObjs;

var config bool                 bLoadExtras, bLoadGOM3, bLoadGOM4, bLoadWW, bLoadWW2, bNewTankPhys;
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
    var string StrikeType;  // MORTAR, ARTILLERY, AIRBURST, ROCKET or WP
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
};

var config array<FSProfile>     FSProfiles;
var config bool                 bFSPlayersCanCall;  // Non-admin players may use the fire support menu
var config bool                 bFSFriendlyFire;    // Strikes can damage the caller's own team
var config bool                 bFSSilent;          // Set true to not broadcast strike calls to everyone
var config bool                 bAllowIntroVO;      // Set true to keep the round-start commander speech (muted by default)
var config int                  FSPlayerCooldown;   // Per-team seconds between player-called strikes, 0 = none (admins ignore it)
var config int                  FSBomberCount;      // Aircraft per Canberra bombing run (1-2), 0 uses 2
var config int                  FSGunshipDuration;  // Seconds the gunship orbits, 0 uses the map's value

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
};

var array<FSActiveStrike>       FSActiveStrikes;
var array<FSPendingStrike>      FSPendingStrikes;
var string                      CurrentMutateString; // The command being processed, so argument errors can put it back in the console for editing
var float                       FSNextCallTime[2];

// =================================================================
// Initialization
// =================================================================
function PreBeginPlay()
{
    local Mutator mut;
    super.PreBeginPlay();

    ApplyMapModLoads();
    InitFireSupportConfig();

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

}

function ApplyMapModLoads()
{
    local string MapName;

    MapName = WorldInfo.GetMapName(true);

    if (InStr(MapName, "WWTE",,true) != -1 || InStr(MapName, "WWSU",,true) != -1)
        bLoadWW = true;

    if (InStr(MapName, "RR",,true) != -1 || InStr(MapName, "DR",,true) != -1)
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
    DA.bLoadExtras = bLoadExtras;
    DA.bLoadGOM3 = bLoadGOM3;
    DA.bLoadGOM4 = bLoadGOM4;
    DA.bLoadWW = bLoadWW;
    DA.bLoadWW2 = bLoadWW2;
    DA.bFSPlayersCanCall = bFSPlayersCanCall;

    DA.CMenuSetup();
    if (!bAllowIntroVO)
        DA.ClientMuteIntroVoice();


    super.NotifyLogin(NewPlayer);
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
	local CMAObjective CMPO;

    local array<string> params;
    local string        command;
    local string        secondaryparam, tertiaryparam;
    local int           i;

    // `log("mutateString = "$mutateString);
    CurrentMutateString = mutateString;

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

        case "CLEAROBJS":
            foreach AllActors(class'CMAObjective', CMPO)
            {
                CMPO.Destroy();
            }
            break;

        case "CLEARCORNERS":
            Corners.Remove(0, Corners.Length);
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
    super.Mutate(MutateString, sender);
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
        if (InStr(WeaponName, "WinterWar") != -1 && !bLoadWW)
        {
            PrivateMessage(PC, "bLoadWinterWar must be enabled in the WebAdmin mutators settings for you to spawn this weapon!");
            return false;
        }
        else if (InStr(WeaponName, "GOM4") != -1 && !bLoadGOM4)
        {
            PrivateMessage(PC, "bLoadGOM4 must be enabled in the WebAdmin mutators settings for you to spawn this weapon!");
            return false;
        }
        else if (InStr(WeaponName, "GOM3") != -1 && !bLoadGOM3)
        {
            PrivateMessage(PC, "bLoadGOM3 must be enabled in the WebAdmin mutators settings for you to spawn this weapon!");
            return false;
        }
        else if (InStr(WeaponName, "WW2") != -1 && !bLoadWW2)
        {
            PrivateMessage(PC, "bLoadWW2 must be enabled in the WebAdmin mutators settings for you to spawn this weapon!");
            return false;
        }
        else if (InStr(WeaponName, "AC") != -1 && !bLoadExtras)
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
// Usage: mutate FIRESUPPORT --type <MORTAR|ARTILLERY|AIRBURST|ROCKET|WP|NAPALM|CANBERRA|SPOOKY> --grid <grid> (or --mark)
// Short options: -t -g -m. The older "FIRESUPPORT <type> <grid | MARK>" form still works.
// Grid format matches the paradrop commands (e.g. "E 5 kp 5", "E5"); MARK uses the team's base game arty marker.
// Shell strikes are tuned per type through FSProfiles in MutCMenu_Server.ini.
function InitFireSupportConfig()
{
    if (FSProfiles.Length > 0)
        return;

    AddFSProfile("MORTAR", 4, 4, 600, 6, 5);
    AddFSProfile("ARTILLERY", 3, 3, 1250, 10, 8);
    AddFSProfile("AIRBURST", 3, 3, 1250, 10, 8);
    AddFSProfile("ROCKET", 3, 6, 1500, 8, 6);
    AddFSProfile("WP", 2, 3, 500, 6, 4);
    SaveConfig();
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
    Help = Help$"|Types: Mortar, Artillery, Airburst, Rocket, WP, Napalm, Canberra, Spooky";
    Help = Help$"|Target: --grid E 5 kp 5 (or E5) for a grid square; --mark (-m) for your mark";
    Help = Help$"|Marks: with --mark a squad leader uses their own squad mark and the commander uses the mark selected on their map; anyone else uses the team's";
    Help = Help$"|    --mark SL3 (or --SL 3, -l 3) picks squad 3's mark, --mark CMD the commander's. Squad leaders can only pick their own squad, admins and the commander any";
    Help = Help$"|Napalm/Canberra heading: --direction -b <N, NE, ESE, ... or a 0-360 bearing> = the way the aircraft flies, e.g. --direction SW or -b 225";
    Help = Help$"|Admins: --delay -d <10-300 seconds> waits that long before the first strike (all types)";
    Help = Help$"|Admins, barrages (mortar/artillery/airburst/rocket/wp): --salvos -s, --shells -n, --spread -r (meters), --interval -i. Add --persist -p to save them as the new profile";
    Help = Help$"|Admins: --suppress -q skips the server-wide announcement for this call";
    Help = Help$"|Admins: strikes can land inside no-artillery zones, including outside the combat area";

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
// call, and with --persist/-p stores the result as the saved profile. Returns false (after telling the caller) if the call must stop.
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

    if (!bAdmin)
    {
        PrivateMessage(Caller, "[CMenu] Only admins can change fire support settings.");
        return false;
    }
    if (!bShellType)
    {
        PrivateMessage(Caller, "[CMenu] Salvos, shells, spread, interval and persist only apply to mortar, artillery, airburst, rocket and wp.");
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

// ArgText is "<type> <grid | MARK>"; Tokens is the whole command, searched for the barrage setting options
function FireSupportCommand(PlayerController Caller, string ArgText, array<string> Tokens)
{
    local array<string> Args;
    local bool bAdmin, bUseMark, bShellType, bDirection, bSuppress;
    local string StrikeType, GridText, Where, DirText, Value;
    local int Team, i, FirstDelay;
    local float Remaining, Bearing;
    local vector Target;
    local vector2D StrikeDir;
    local ROTeamInfo ROTI;
    local ROGameInfo ROGI;
    local FSProfile Profile;
    local bool bFired;

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

    bShellType = (GetFSShellClass(StrikeType) != None);
    if (bShellType && !FindFSProfile(StrikeType, Profile))
    {
        PrivateMessage(Caller, "[CMenu] No fire support profile configured for "$StrikeType$".");
        return;
    }

    bSuppress = class'CmdOptions'.static.Has(Tokens, "suppress", "q");
    if (bSuppress && !bAdmin)
    {
        PrivateMessage(Caller, "[CMenu] Only admins can suppress the fire support announcement.");
        return;
    }

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
        if (!bAdmin)
        {
            PrivateMessage(Caller, "[CMenu] Only admins can set a first strike delay.");
            return;
        }

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

    Team = Caller.GetTeamNum();
    ROGI = ROGameInfo(WorldInfo.Game);
    if (Team == `AXIS_TEAM_INDEX || Team == `ALLIES_TEAM_INDEX)
        ROTI = ROTeamInfo(WorldInfo.GRI.Teams[Team]);

    if (ROTI == None || ROGI == None || !ROGI.bRoundActive || ROPlayerController(Caller) == None)
    {
        PrivateMessage(Caller, "[CMenu] Fire support is only available to a team while a round is active.");
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

    bUseMark = (GridText == "" || IsMarkSelector(GridText));
    if (bUseMark)
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
        bFired = SpawnShellStrike(Caller, StrikeType, Target, Profile);
        RegisterFSStrike(Caller, Team, Profile.Delay + (Profile.Salvos * (Profile.Interval + Profile.Shells)) + 30.0);
    }
    else
    {
        if (FirstDelay > 0)
        {
            QueueAircraftStrike(Caller, StrikeType, Target, StrikeDir, bDirection, Bearing, bAdmin, FirstDelay);
            bFired = (ROPlayerController(Caller) != None);
        }
        else
        {
            bFired = LaunchAircraftStrike(Caller, StrikeType, Target, StrikeDir, bDirection, Bearing, bAdmin);
        }
        RegisterFSStrike(Caller, Team, 120.0 + FirstDelay + (StrikeType == "SPOOKY" ? FSGunshipDuration : 0));
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

    if (!bFSSilent && !bSuppress)
        WorldInfo.Game.Broadcast(self, "[CMenu] "$Caller.PlayerReplicationInfo.PlayerName$" called in a "$FSDisplayName(StrikeType)$" at "$Where);
    else
        PrivateMessage(Caller, "[CMenu] Called in a "$FSDisplayName(StrikeType)$" at "$Where);
}

function bool SpawnShellStrike(PlayerController Caller, string StrikeType, vector Target, FSProfile Profile)
{
    local ROArtillerySpawner Spawner;
    local class<ROArtilleryShell> ShellClass;
    local vector SpawnLoc, MyGravity;
    local int Team;

    ShellClass = GetFSShellClass(StrikeType);
    if (ShellClass == None)
        return false;

    Team = Caller.GetTeamNum();
    MyGravity.Z = WorldInfo.WorldGravityZ;

    SpawnLoc = Target;
    SpawnLoc.Z = ROGameReplicationInfo(WorldInfo.GRI).ArtySpawn.Z;
    if (SpawnLoc.Z < Target.Z + 1000)
        SpawnLoc.Z = Target.Z + 5000;

    // Spawned without an owner so the base game doesn't track it against the team commander's strike
    Spawner = Spawn(class'ROArtillerySpawner',,, SpawnLoc, rotator(MyGravity));
    if (Spawner == None)
        return false;

    Spawner.ClearTimer();
    Spawner.bValuesPreConfigured = true;
    Spawner.InstigatorController = Caller;
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
    if (Team == `AXIS_TEAM_INDEX)
        Spawner.ArtilleryShellClassesAvailNorth.AddItem(ShellClass);
    else
        Spawner.ArtilleryShellClassesAvailSouth.AddItem(ShellClass);

    Spawner.StartBarrage();
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
function bool LaunchAircraftStrike(PlayerController Caller, string StrikeType, vector Target, vector2D StrikeDir, bool bForceBearing, float Bearing, bool bIgnoreNoArty)
{
    local ROPlayerController ROPC;

    ROPC = ROPlayerController(Caller);
    if (ROPC == None)
        return false;

    switch (StrikeType)
    {
        case "NAPALM":
            return SpawnNapalmStrike(ROPC, Target, StrikeDir, bForceBearing, Bearing, bIgnoreNoArty);
        case "CANBERRA":
            return SpawnBombingRun(ROPC, Target, StrikeDir, bForceBearing, Bearing, bIgnoreNoArty);
        case "SPOOKY":
            return SpawnGunshipStrike(ROPC, Target);
    }
    return false;
}

// Holds an aircraft strike back for the first strike delay
function QueueAircraftStrike(PlayerController Caller, string StrikeType, vector Target, vector2D StrikeDir, bool bForceBearing, float Bearing, bool bIgnoreNoArty, int Delay)
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

        // The caller left or the round ended while the strike was waiting
        if (Pending.Caller == None || ROGI == None || !ROGI.bRoundActive)
            continue;

        if (!LaunchAircraftStrike(Pending.Caller, Pending.StrikeType, Pending.Target, Pending.StrikeDir, Pending.bForceBearing, Pending.Bearing, Pending.bIgnoreNoArty))
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

function bool SpawnNapalmStrike(ROPlayerController Caller, vector Target, vector2D StrikeDir, bool bForceBearing, float Bearing, bool bIgnoreNoArty)
{
    local ROMapInfo ROMI;
    local ROGameReplicationInfo ROGRI;
    local class<RONapalmStrikeAircraft> AircraftClass;
    local RONapalmStrikeAircraft Aircraft;
    local vector SpawnLoc, AimTarget;
    local int Team;

    ROMI = ROMapInfo(WorldInfo.GetMapInfo());
    ROGRI = ROGameReplicationInfo(WorldInfo.GRI);
    Team = Caller.GetTeamNum();

    if (ROMI != None && ROMI.SouthernForce == SFOR_ARVN)
        AircraftClass = class'CMNapalmStrikeAircraftARVN';
    else
        AircraftClass = class'CMNapalmStrikeAircraft';

    if (!bForceBearing || !GetDirectedSpawnLoc(Target, Bearing, ROMI.NapalmStrikeHeightOffset, AircraftClass, SpawnLoc))
        SpawnLoc = Caller.GetBestAircraftSpawnLoc(Target, ROMI.NapalmStrikeHeightOffset, AircraftClass, StrikeDir);
    AimTarget = Target;
    AimTarget.Z = SpawnLoc.Z;

    Aircraft = Spawn(AircraftClass, Caller,, SpawnLoc, rotator(AimTarget - SpawnLoc));
    if (Aircraft == None)
        return false;

    if (CMNapalmStrikeAircraft(Aircraft) != None)
        CMNapalmStrikeAircraft(Aircraft).bIgnoreNoArty = bIgnoreNoArty;
    else if (CMNapalmStrikeAircraftARVN(Aircraft) != None)
        CMNapalmStrikeAircraftARVN(Aircraft).bIgnoreNoArty = bIgnoreNoArty;
    WidenAircraftLimits(Aircraft, Target);

    Aircraft.TargetLocation = Target;
    Aircraft.CachedAirSupportTime = ROGRI.NextAbilityThreeTime[Team]; // Keeps the commander's ability timer unchanged if the strike is aborted
    Aircraft.SetDropPoint();
    return true;
}

function bool SpawnBombingRun(ROPlayerController Caller, vector Target, vector2D StrikeDir, bool bForceBearing, float Bearing, bool bIgnoreNoArty)
{
    local ROMapInfo ROMI;
    local ROGameReplicationInfo ROGRI;
    local CMCarpetBomberAircraft Aircraft;
    local vector SpawnLoc, AimTarget;
    local float HeightOffset;
    local int Team, i, NumBombers;

    ROMI = ROMapInfo(WorldInfo.GetMapInfo());
    ROGRI = ROGameReplicationInfo(WorldInfo.GRI);
    Team = Caller.GetTeamNum();
    NumBombers = (FSBomberCount <= 0) ? 2 : Clamp(FSBomberCount, 1, 2);

    HeightOffset = ROMI.bUseNapalmHeightOffsetForAll ? ROMI.NapalmStrikeHeightOffset : ROMI.CarpetBomberHeightOffset;
    if (!bForceBearing || !GetDirectedSpawnLoc(Target, Bearing, HeightOffset, class'ROCarpetBomberAircraft', SpawnLoc))
        SpawnLoc = Caller.GetBestAircraftSpawnLoc(Target, HeightOffset, class'ROCarpetBomberAircraft', StrikeDir);

    AimTarget = Target;
    AimTarget.Z = SpawnLoc.Z;

    for (i = 1; i <= NumBombers; i++)
    {
        Aircraft = Spawn(class'CMCarpetBomberAircraft', Caller,, SpawnLoc, rotator(AimTarget - SpawnLoc));
        if (Aircraft == None)
            return (i > 1);

        Aircraft.bIgnoreNoArty = bIgnoreNoArty;
        WidenAircraftLimits(Aircraft, Target);

        Aircraft.TargetLocation = Target;
        Aircraft.CachedAirSupportTime = ROGRI.NextAbilityOneTime[Team];
        if (i == 2)
            Aircraft.InboundDelay += 1;
        Aircraft.SetDropPoint();
        Aircraft.SetOffset(i);
    }
    return true;
}

function bool SpawnGunshipStrike(ROPlayerController Caller, vector Target)
{
    local ROGameReplicationInfo ROGRI;
    local ROGunshipAircraft Aircraft;
    local vector SpawnLoc, AimTarget;

    ROGRI = ROGameReplicationInfo(WorldInfo.GRI);

    SpawnLoc = Caller.GetBestAircraftSpawnLoc(Target, class'ROGunshipAircraft'.default.Altitude, class'ROGunshipAircraft');
    AimTarget = Target;
    AimTarget.Z = SpawnLoc.Z;

    Aircraft = Spawn(class'ROGunshipAircraft', Caller,, SpawnLoc, rotator(AimTarget - SpawnLoc));
    if (Aircraft == None)
        return false;

    WidenAircraftLimits(Aircraft, Target);

    Aircraft.TargetLocation = Target;
    Aircraft.CachedAirSupportTime = ROGRI.NextAbilityOneTime[Caller.GetTeamNum()];
    Aircraft.CalculateOrbit();
    if (FSGunshipDuration > 0)
        Aircraft.OrbitDuration = FSGunshipDuration;
    return true;
}

// Remembers who called a strike so friendly fire can be suppressed for it (see NetDamage)
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
    if (!bFSFriendlyFire && Damage > 0 && InstigatedBy != None && Injured != None && IsFSStrikeDamage(DamageType))
    {
        for (i = 0; i < FSActiveStrikes.Length; i++)
        {
            if (FSActiveStrikes[i].Caller == InstigatedBy
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

function LoadObjects()
{
    local ROMapInfo               ROMI;
    local string                  WeaponName;

    BindHelpOutput();
    ROMI = ROMapInfo(WorldInfo.GetMapInfo());

    // Load settings object
    ROMI.SharedContentReferences.AddItem(class<Settings>(DynamicLoadObject("MutCMenu.MutCMenuSettings", class'Class')));

    // Load extra content if enabled
    if (bLoadExtras)
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
    if (bLoadGOM3)
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
    if (bLoadGOM4)
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
    if (bLoadWW)
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
    if (bLoadWW2)
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
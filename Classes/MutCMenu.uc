// Command Menu Mutator
// Created by T/4 Scovel for the 29th Infantry Division Realism Unit
// =================================================================
// Version 2.1
// =================================================================
// Code tech: T/4 Scovel
// =================================================================
class MutCMenu extends ROMutator
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

// =================================================================
// Initialization
// =================================================================
function PreBeginPlay()
{
    local Mutator mut;
    super.PreBeginPlay();

    ApplyMapModLoads();

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

    DA.CMenuSetup();


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

            /* case "CALLARTY":
                CallArtillery(sender, secondaryparam);
                break;

            case "CALLNAPALM":
                CallNapalm(sender, secondaryparam);
                break;

            case "CALLSPOOKY":
                CallSpooky(sender);
                break; */
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
    receiver.TeamMessage(None, msg, '');
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
// Content Loading
// =================================================================
// =================================================================
// Fire Support Commands
// =================================================================
/* function CallArtillery(PlayerController PC, string GridCoords)
{
    local int TeamIndex;
    
    TeamIndex = PC.GetTeamNum();
    
    if (GridCoords != "")
    {
        TargetLoc = GridToWorldLocation(GridCoords);
        
        if (TeamIndex == `AXIS_TEAM_INDEX)
        {
            // ROGRI.CallInNorthArtilleryStrike(TargetLoc, PC);
            WorldInfo.Game.Broadcast(self, "[CMenu] "$PC.PlayerReplicationInfo.PlayerName$" called North artillery at "$GridCoords);
        }
        else
        {
            // ROGRI.CallInSouthArtilleryStrike(TargetLoc, PC);
            WorldInfo.Game.Broadcast(self, "[CMenu] "$PC.PlayerReplicationInfo.PlayerName$" called South artillery at "$GridCoords);
        }
    }
}

function CallNapalm(PlayerController PC, string GridCoords)
{
    if (GridCoords != "" && PC.GetTeamNum() == `ALLIES_TEAM_INDEX)
    {
        TargetLoc = GridToWorldLocation(GridCoords);
        // ROGRI.CallInNapalmStrike(TargetLoc, PC);
        WorldInfo.Game.Broadcast(self, "[CMenu] "$PC.PlayerReplicationInfo.PlayerName$" called napalm strike at "$GridCoords);
    }
}

function CallSpooky(PlayerController PC)
{
    if (PC.GetTeamNum() == `ALLIES_TEAM_INDEX)
    {
        // ROGRI.CallInSpookyStrike(PC);
        WorldInfo.Game.Broadcast(self, "[CMenu] "$PC.PlayerReplicationInfo.PlayerName$" called AC-47 Spooky");
    }
}

function vector GridToWorldLocation(string GridCoords)
{
    local vector WorldLoc;
    local int GridX, GridY;
    local string X, Y;
    local array<string> Parts;
    
    Parts = SplitString(GridCoords, ",", true);
    if (Parts.Length >= 2)
    {
        X = Parts[0];
        Y = Parts[1];
        GridX = int(X);
        GridY = int(Y);
        
        // Convert grid coordinates to world location
        // Assuming standard RS2 grid conversion: each grid is 5000 units
        WorldLoc.X = GridX * 5000;
        WorldLoc.Y = GridY * 5000;
        WorldLoc.Z = 1000; // Default height
    }
    
    return WorldLoc;
} */

function LoadObjects()
{
    local ROMapInfo               ROMI;
    local string                  WeaponName;

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
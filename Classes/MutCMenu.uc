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

var config ENorthernForces      MyNorthForce;
var config ESouthernForces      MySouthForce;
var config bool                 bUseDefaultFactions, bLoadExtras, bLoadGOM3, bLoadGOM4, bLoadWW, bLoadWW2, bNewTankPhys;
var config array<string>        MutatorAdmins; // A list of all mutator admins and their passwords
var config array<string>        ExtrasToLoad, GOM3ToLoad, GOM4ToLoad, WWToLoad, WW2ToLoad; // Lists of all the objects to load

// =================================================================
// Initialization
// =================================================================
function PreBeginPlay()
{
    local Mutator mut;
    super.PreBeginPlay();

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

    ROGameInfo(WorldInfo.Game).GameReplicationInfoClass = class'CMGameReplicationInfo';
}

auto state StartUp
{
    Begin:
    SetTimer(1, false, 'LoadObjects');
}

function bool IsMutThere(string Mutator)
{
	local Mutator mut;

    for (mut = ROGameInfo(WorldInfo.Game).BaseMutator; mut != none; mut = mut.NextMutator)
    {
        if(InStr(string(mut.name), Mutator,,true) != -1) 
        {
            return true;
        }
    }
    return false;
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

    if (!bUseDefaultFactions)
    {
        if (WorldInfo.NetMode != NM_Standalone) DA.FactionSetup(MyNorthForce, MySouthForce);
        DA.ClientFactionSetup(MyNorthForce, MySouthForce);
    }

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
    params = SplitString(mutateString, " to ", false);
    tertiaryparam = params[1];
    params = SplitString(params[0], " ", true);
    command = Caps(params[0]);

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
            GiveWeapon(sender, params[1], false, 100);
            break;

        case "GIVEWEAPONALL":
            GiveWeapon(sender, params[1], true, 100);
            break;

        case "GIVEWEAPONNORTH":
            GiveWeapon(sender, params[1], false, `AXIS_TEAM_INDEX);
            break;

        case "GIVEWEAPONSOUTH":
            GiveWeapon(sender, params[1], false, `ALLIES_TEAM_INDEX);
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
        }
    }
    super.Mutate(MutateString, sender);
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
function bool bIsMutThere(string Mutator)
{
    local ROGameInfo ROGI;
	local Mutator mut;

    ROGI = ROGameInfo(WorldInfo.Game);

    mut = ROGI.BaseMutator;

    // Iterate through mutators to find if a specific one is present
    for (mut = ROGI.BaseMutator; mut != none; mut = mut.NextMutator)
    {
        if(InStr(string(mut.name), Mutator,,true) != -1) 
        {
            return true;
        }
    }
    return false;
}

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
    local string                    ActualName;

    if (PC != none)
    {
        if (bGiveAll)
        { 
            // Give weapon to all pawns
            foreach worldinfo.allpawns(class'ROPawn', ROP)
            {
                InvManager = ROInventoryManager(ROP.InvManager);

                ActualName = DoGiveWeapon(PC, InvManager, WeaponName);
                if (ActualName != "true")
                    break;
            }
            if (ActualName == "true")
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

                    ActualName = DoGiveWeapon(PC, InvManager, WeaponName);
                    if (ActualName != "true")
                        break;
                }
            }
            if (ActualName == "true")
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

                    ActualName = DoGiveWeapon(PC, InvManager, WeaponName);
                    if (ActualName != "true")
                        break;
                }
            }
            if (ActualName == "true")
                WorldInfo.Game.Broadcast(self, "[CMenu] "$PC.PlayerReplicationInfo.PlayerName$" gave a "$WeaponName$" to the south");
        }
        else if (TeamIndex == 100)
        {
            // Give weapon to the sender
            InvManager = ROInventoryManager(PC.Pawn.InvManager);

            ActualName = DoGiveWeapon(PC, InvManager, WeaponName);
            if (ActualName == "true")
                WorldInfo.Game.Broadcast(self, "[CMenu] "$PC.PlayerReplicationInfo.PlayerName$" spawned a "$WeaponName);
        }
    }
    else
    {
        // `log ("[MutExtras Debug] Error: GW PlayerController is none!");
    }

    if (ActualName == "false")
    {
        PrivateMessage(PC, "Not a valid weapon name.");
    }
    else if (InStr(ActualName, "WinterWar") != -1 && !bLoadWW)
    {
        PrivateMessage(PC, "bLoadWinterWar must be enabled in the WebAdmin mutators settings for you to spawn this weapon!");
    }
    else if (InStr(ActualName, "GOM4") != -1 && !bLoadGOM4)
    {
        PrivateMessage(PC, "bLoadGOM4 must be enabled in the WebAdmin mutators settings for you to spawn this weapon!");
    }
    else if (InStr(ActualName, "GOM3") != -1 && !bLoadGOM3)
    {
        PrivateMessage(PC, "bLoadGOM3 must be enabled in the WebAdmin mutators settings for you to spawn this weapon!");
    }
    else if (InStr(ActualName, "WW2") != -1 && !bLoadWW2)
    {
        PrivateMessage(PC, "bLoadWW2 must be enabled in the WebAdmin mutators settings for you to spawn this weapon!");
    }
}

// =================================================================
// Helper: DoGiveWeapon
// =================================================================
// Performs the actual weapon giving logic.
// Checks if the weapon name is valid and if the required content package is loaded.
// If valid, it attempts to load and create the inventory item for the player.
// =================================================================
/* function string DoGiveWeapon(PlayerController PC, ROInventoryManager InvManager, string WeaponName)
{
    // Check if it's a generic weapon or item path
    if (InStr(WeaponName, "Weap") != -1 || InStr(WeaponName, "Item") != -1)
    {
        InvManager.LoadAndCreateInventory(WeaponName, false, true);
        return "true";
    }
    else
        return "false";

    // Check for specific mod content requirements
    if (InStr(WeaponName, "WinterWar") != -1 && !bLoadWW)
    {
        return WeaponName;
    }
    else if (InStr(WeaponName, "GOM4") != -1 && !bLoadGOM4)
    {
        return WeaponName;
    }
    else if (InStr(WeaponName, "GOM3") != -1 && !bLoadGOM3)
    {
        return WeaponName;
    }
    else if (InStr(WeaponName, "WW2") != -1 && !bLoadWW2)
    {
        return WeaponName;
    }

    // Fallback attempt to load
    InvManager.LoadAndCreateInventory(WeaponName, false, true);
    return "true";
} */

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
function LoadObjects()
{
    local ROMapInfo               ROMI;
    local string                  WeaponName;

    ROMI = ROMapInfo(WorldInfo.GetMapInfo());

    // Load settings object
    ROMI.SharedContentReferences.AddItem(class<Settings>(DynamicLoadObject("MutCMenuTB.MutCMenuSettings", class'Class')));

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

`include(MutCMenuTB\Classes\WeaponNames.uci)

defaultproperties
{
    
}
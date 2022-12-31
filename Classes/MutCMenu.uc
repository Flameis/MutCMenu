// CMenu Mutator
// Created by T/5 Scovel for the 29th Infantry Division Realism Unit
// ====================================================
// Version 2.0
// ====================================================
// Code tech: T/5 Scovel
// ====================================================
class MutCMenu extends ROMutator
    config(MutCMenu_Server);

var array<DummyActor>           DummyActors;
var array<vector2d>			    Corners;

var array<string>               LoggedInMutatorAdmins; // list of the names of all the players that are currently logged in as a mutator admin
var int                         NumObjs;

var config ENorthernForces      MyNorthForce;
var config ESouthernForces      MySouthForce;
var config bool                 bUseDefaultFactions, bLoadGOM3, bLoadGOM4, bLoadWW, bNewTankPhys;
var config array<string>        MutatorAdmins; // A list of all mutator admins and their passwords

function PreBeginPlay()
{
    super.PreBeginPlay();

    ROGameInfo(WorldInfo.Game).GameReplicationInfoClass = class'CMGameReplicationInfo';
}

/* auto state StartUp
{
    Begin:
    SetTimer(1, false, 'LoadObjects');
} */

simulated function NotifyLogin(Controller NewPlayer)
{
    local DummyActor DA;
    
    //Spawn a dummyactor to do client side functions without replacing the playercontroller
    DA = spawn(class'DummyActor', NewPlayer); 
    DummyActors.AddItem(DA);

    DA.MyMut = self;
    DA.bNewTankPhys = bNewTankPhys;
    DA.bLoadGOM3 = bLoadGOM3;
    DA.bLoadGOM4 = bLoadGOM4;
    DA.bLoadWW = bLoadWW;

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

/* Override GameInfo FindPlayerStart() - called by GameInfo.FindPlayerStart()
if a NavigationPoint is returned, it will be used as the playerstart
*/
function NavigationPoint FindPlayerStart(Controller Player, optional byte InTeam, optional string incomingName)
{
    local CMSMSpawn SMS;
    local NavigationPoint SpawnPoint;
    local ROGameInfo ROGI;
    local vector SpawnLoc;
    
    super.FindPlayerStart(Player, InTeam, incomingName);

    ROGI = ROGameInfo(WorldInfo.Game);

    foreach AllActors(class'CMSMSpawn', SMS)
    {
        if (SMS.TeamIndex == Player.GetTeamNum())
        {
            ROGI.FindSpawnablePointForTunnel(SMS.PSP, SpawnLoc);
            SpawnPoint = Spawn(class'ROSpawnNavigationPoint',,, SpawnLoc);
            SMS.MySpawns.AddItem(SpawnPoint);
            return SpawnPoint;
        }
    }
    return none;
}

// Interprets commands and broadcasts their execution
simulated function Mutate(string mutateString, PlayerController sender)
{
    local DummyActor DA, DASender, DAFound;
    local CMSMSpawn SMS;
	local CMAObjective CMPO;

    local array<string> params;
    local string        command;
    local string        secondaryparam, tertiaryparam;
    local int           i;

    `log("mutateString = "$mutateString);

    params = SplitString(mutateString, " to ", false);
    tertiaryparam = params[1];
    params = SplitString(params[0], " ", true);
    command = Caps(params[0]);

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
            foreach AllActors(class'CMSMSpawn', SMS)
            {
                if (SMS.TeamIndex == 0)
                {
                    SMS.Destroy();
                }
            }
            break;

        case "DELSOUTHSPAWNS":
            foreach AllActors(class'CMSMSpawn', SMS)
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

function ToggleCMenuVisiblity(PlayerController PC, string CMenu, optional string TargetName)
{
    local DummyActor DA, DASender;

    foreach DummyActors(DA)
    {
        if (DA.Owner == PC)
        {
            DASender = DA;
        }
    }

    DASender.ToggleCMenuVisiblity(CMenu, IsAuthorized(PC), TargetName);
}

function LogInAdmin(PlayerController sender, string MyAdminInfo)
{
    local string PlayerName;
    local string AdminInfo;
    local bool AlreadyAdmin;
    local int i;
    
    PlayerName = sender.PlayerReplicationInfo.PlayerName;
    AlreadyAdmin = False;
    foreach MutatorAdmins(AdminInfo)
    if(MyAdminInfo == AdminInfo)
    {
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
    for(i = 0; i < LoggedInMutatorAdmins.Length; i++)
    {
        if(LoggedInMutatorAdmins[i] == PlayerName)
        {
            IsMutatorAdmin = True;
        }
    }
    return IsServerAdmin || IsMutatorAdmin;
}

function bool bIsMutThere(string Mutator)
{
    local ROGameInfo ROGI;
	local Mutator mut;

    ROGI = ROGameInfo(WorldInfo.Game);

    mut = ROGI.BaseMutator;

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
    receiver.TeamMessage(None, msg, '');
}

/* function LoadObjects()
{
    local ROMapInfo               ROMI;

    ROMI = ROMapInfo(WorldInfo.GetMapInfo());

    //`log ("[MutExtras LoadObjects]");
    ROMI.SharedContentReferences.AddItem(class<Settings>(DynamicLoadObject("MutExtrasTB.MutExtrasSettings", class'Class')));

    if (bLoadGOM3)
    {
        ROMI.SharedContentReferences.AddItem(class<ROVehicle>(DynamicLoadObject("GOM3.GOMVehicle_M113_ACAV_ActualContent", class'Class')));
    }
    if (bLoadGOM4)
    {
        ROMI.SharedContentReferences.AddItem(class<ROVehicle>(DynamicLoadObject("GOM4.GOMVehicle_M113_ACAV_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<ROVehicle>(DynamicLoadObject("GOM4.GOMVehicle_M113_APC_ARVN", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<ROVehicle>(DynamicLoadObject("GOM4.GOMVehicle_M151_MUTT_US", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<ROVehicle>(DynamicLoadObject("GOM4.GOMVehicle_T34_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_38Bodyguard_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_BarShotgun_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_Bayonet_M4_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_Bayonet_M5_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_Bayonet_M7_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_BowieKnife_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_Crossbow_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_DP27", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_DPM", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_F1_Grenade_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_FusilRobust_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_K50M_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_Kar98Scoped_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_Kar98k_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_L1A1_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_LPO50_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_M12_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_M14_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_M16A1_Scoped_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_M16A1_XM148_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_M1897_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_M18_Recoilless_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_M1911A1_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_M1A1_Stockless", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_M7RifleGrenade_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_M37_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_M37_Riot", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_M44_Carbine_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_M60_200", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_M72_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_MAC10_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_MAC10_Silenced", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_MG34_Drum", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_MG42_Drum", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_P38_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_PPS_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_RGD33_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_RPD_SawnOff_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_RPG2_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_SKS_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_SVD_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_Satchel_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_SodaGrenade_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_SodaMine_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_Stel_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_Sten_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_Stevens_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_Stoner63A_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_TUL_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_Type63_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_UZI_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_VCGrenade_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_VCKnife_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_VZ23", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_VZ25", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_VZ58_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_VZ61_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_XM177E2_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_XM177E2_30", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_XM21_Content", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("GOM4.GOMWeapon_XM21_Suppressed", class'Class')));
    }
    if (bLoadWW)
    {
        ROMI.SharedContentReferences.AddItem(class<ROVehicle>(DynamicLoadObject("WinterWar.WWVehicle_T20_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<ROVehicle>(DynamicLoadObject("WinterWar.WWVehicle_T26_EarlyWar_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<ROVehicle>(DynamicLoadObject("WinterWar.WWVehicle_T28_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<ROVehicle>(DynamicLoadObject("WinterWar.WWVehicle_HT130_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<ROVehicle>(DynamicLoadObject("WinterWar.WWVehicle_53K_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<ROVehicle>(DynamicLoadObject("WinterWar.WWVehicle_Vickers_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_AntiTankMine_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_AVS36_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_Binoculars_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_DP28_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_F1Grenade_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_Kasapanos_FactoryIssue_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_Kasapanos_Improvised_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_KP31_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_L35_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_LahtiSaloranta_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_Luger_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_M20_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_M32Grenade_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_Maxim_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_MN27_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_MN38_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_MN91_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_MN9130_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_MN9130_Dyakonov_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_MN9130_Scoped_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_Molotov_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_NagantRevolver_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_PPD34_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_QuadMaxims_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_RDG1_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_RGD33_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_Satchel_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_Skis_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_SVT38_ActualContent", class'Class')));
        ROMI.SharedContentReferences.AddItem(class<Inventory>(DynamicLoadObject("WinterWar.WWWeapon_TT33_ActualContent", class'Class')));
    }
} */
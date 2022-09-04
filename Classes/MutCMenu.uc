// CMenu Mutator
// Created by the 29th Infantry Division Engineer Corps
// ====================================================
// Revision 1 (8/27/22) //TODO
// ====================================================
// Code tech: T/5 Scovel
// ====================================================
class MutCMenu extends ROMutator
  config(MutCMenu);

var array<string>       LoggedInMutatorAdmins; // list of the names of all the players that are currently logged in as a mutator admin
var config array<string>  MutatorAdmins; // A list of all mutator admins and their passwords

simulated function NotifyLogin(Controller NewPlayer)
{
    local DummyActor DA;

    DA = spawn(class'DummyActor', NewPlayer); //Spawn a dummyactor to do client side functions without replacing the playercontroller
    if (WorldInfo.NetMode != NM_Standalone) DA.CMenuSetup(bIsMutThere("Commands"), bIsMutThere("Extras"));
    DA.ClientCMenuSetup(bIsMutThere("Commands"), bIsMutThere("Extras"));
    DA.Destroy();

    super.NotifyLogin(NewPlayer);
}

// Interprets commands and broadcasts their execution
simulated function Mutate(string mutateString, PlayerController sender)
{
    local DummyActor DA;
    /* local rotator PRot;
	local vector HitLocation, HitNormal, StartTrace, EndTrace, ViewDirection;
	local StaticMesh sm;
    local StaticMeshActor SMA;
    local float     TraceLength; */

    local array<string> params;
    local string        command;
    local string        secondaryparam, tertiaryparam;
    local int           i;
   

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
    
    switch (command) // Commands that do not need admin
    {
        case "SETCMENUTEXTCOLOR":
            DA = spawn(class'DummyActor', sender);
            DA.SetCMenuColor(secondaryparam, "Text");
            DA.Destroy();
            break;

        case "SETCMENUBGCOLOR":
            DA = spawn(class'DummyActor', sender);
            DA.SetCMenuColor(secondaryparam, "Background");
            DA.Destroy();
            break;

        case "SETCMENUBORDERCOLOR":
            DA = spawn(class'DummyActor', sender);
            DA.SetCMenuColor(secondaryparam, "Border");
            DA.Destroy();
            break;

        case "CMENU":
            if (secondaryparam != "")
            {
                ToggleCMenuVisiblity(sender, secondaryparam);
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

        /* case "SPAWNSM":
	        sender.GetPlayerViewPoint(StartTrace, PRot);
            ViewDirection = Vector(sender.Pawn.GetViewRotation());
            TraceLength = 40000;
            EndTrace = StartTrace + ViewDirection * TraceLength;
	        trace(HitLocation, HitNormal, EndTrace, StartTrace, false);

			SMA = Spawn(class'CMBuilderSM',,,HitLocation,sender.Pawn.Rotation);
			sm = StaticMesh(DynamicLoadObject(secondaryparam, class'StaticMesh'));
            SMA.StaticMeshComponent.SetStaticMesh(sm);
            break; */
    }
    if (IsAuthorized(sender))
    {
        switch (command)
        {
            case "CMENUPCMANAGER":
                ToggleCMenuVisiblity(sender, "CMENUPCMANAGER", secondaryparam);
                break;

            // Commands not in other mutators (I have to use the dummy actor to execute console commands on the target client)

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
                DA = spawn(class'DummyActor', FindPlayer(secondaryparam));
                DA.ClientCMConsoleCommand("mutate scrimadminlogin "$MutRealismMatch(WorldInfo.Game.BaseMutator).MutatorAdmins[0]);
                `log (MutRealismMatch(WorldInfo.Game.BaseMutator).MutatorAdmins[0]);
                DA.Destroy();
                WorldInfo.Game.Broadcast(self, "[CMenu] "$sender.PlayerReplicationInfo.PlayerName$" gave temporary scrim admin powers to "$secondaryparam);
                break;

            case "TEMPADMINLOGOUT":
                DA = spawn(class'DummyActor', FindPlayer(secondaryparam));
                DA.ClientCMConsoleCommand("mutate scrimadminlogout");
                DA.Destroy();
                WorldInfo.Game.Broadcast(self, "[CMenu] "$sender.PlayerReplicationInfo.PlayerName$" revoked temporary scrim admin powers from "$secondaryparam);
                break;

            case "FORCERESPAWN":
                DA = spawn(class'DummyActor', FindPlayer(secondaryparam));
                DA.ClientCMConsoleCommand("mutate respawn");
                DA.Destroy();
                break;

            case "FDAO": //ForceDropAtObj
                DA = spawn(class'DummyActor', FindPlayer(secondaryparam));
                DA.ClientCMConsoleCommand("mutate dropatobj "$tertiaryparam);
                DA.Destroy();
                break;

            case "FDAG": //ForceDropAtGrid
                DA = spawn(class'DummyActor', FindPlayer(secondaryparam));
                DA.ClientCMConsoleCommand("mutate dropatgrid "$tertiaryparam);
                DA.Destroy();
                break;
            
            case "FORCESAFETYON":
                DA = spawn(class'DummyActor', FindPlayer(secondaryparam));
                DA.ClientCMConsoleCommand("mutate safetyon");
                DA.Destroy();
                break;

            case "FORCESAFETYOFF":
                DA = spawn(class'DummyActor', FindPlayer(secondaryparam));
                DA.ClientCMConsoleCommand("mutate safetyoff");
                DA.Destroy();
                break;
        }
    }
    super.Mutate(MutateString, sender);
}

function ToggleCMenuVisiblity(PlayerController PC, string CMenu, optional string TargetName)
{
    local DummyActor DA;

    DA = spawn(class'DummyActor', PC); //Spawn a dummyactor to do client side functions without replacing the playercontroller
    if (WorldInfo.NetMode != NM_Standalone) DA.ToggleCMenuVisiblity(CMenu, IsAuthorized(PC), TargetName);
    DA.ClientToggleCMenuVisiblity(CMenu, IsAuthorized(PC), TargetName);
    DA.Destroy();
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
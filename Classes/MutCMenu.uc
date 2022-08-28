// CMenu Mutator
// Created by the 29th Infantry Division Engineer Corps
// ====================================================
// TODO: Initial Release (Released date)
// ====================================================
// Code tech: T/5 Scovel
// ====================================================
class MutCMenu extends ROMutator
  config(MutCMenu);

var string TempAdminPass;

simulated function NotifyLogin(Controller NewPlayer)
{
    local DummyActor DA;

    DA = spawn(class'DummyActor', NewPlayer); //Spawn a dummyactor to do client side functions without replacing the playercontroller
    //DA.bMutCommands = bIsMutThere("Commands");
    //DA.bMutExtras = bIsMutThere("Extras");
    if (WorldInfo.NetMode != NM_Standalone) DA.CMenuSetup(bIsMutThere("Commands"), bIsMutThere("Extras"));
    DA.ClientCMenuSetup(bIsMutThere("Commands"), bIsMutThere("Extras"));
    DA.Destroy();

    super.NotifyLogin(NewPlayer);
}

// Interprets commands and broadcasts their execution
simulated function Mutate(string mutateString, PlayerController sender)
{
    local DummyActor DA;
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

    /* `log (command);
    `log (secondaryparam);
    `log (tertiaryparam); */
    
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
                SetCMenuVisible(sender, secondaryparam);
            }
            else
            {
                SetCMenuVisible(sender, "CMENUMAIN");
            }
            break;

        case "SWITCHTEAM":
            ROPlayerController(Sender).SwapTeam(1);
            break;
    }
    if (IsAuthorized(sender))
    {
        switch (command)
        {
            case "CMENUPCMANAGER":
                SetCMenuVisible(sender, "CMENUPCMANAGER", secondaryparam);
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
                // DA.CMConsoleCommand("mutate scrimadminlogin "$TempAdminPass);
                DA.ClientCMConsoleCommand("mutate scrimadminlogin "$TempAdminPass);
                DA.Destroy();
                WorldInfo.Game.Broadcast(self, "[CMenu] "$sender.PlayerReplicationInfo.PlayerName$" gave temporary scrim admin powers to "$secondaryparam);
                break;

            case "TEMPADMINLOGOUT":
                DA = spawn(class'DummyActor', FindPlayer(secondaryparam));
                // DA.CMConsoleCommand("mutate scrimadminlogout");
                DA.ClientCMConsoleCommand("mutate scrimadminlogout");
                DA.Destroy();
                WorldInfo.Game.Broadcast(self, "[CMenu] "$sender.PlayerReplicationInfo.PlayerName$" revoked temporary scrim admin powers from "$secondaryparam);
                break;

            case "FORCERESPAWN":
                DA = spawn(class'DummyActor', FindPlayer(secondaryparam));
                // DA.CMConsoleCommand("mutate respawn");
                DA.ClientCMConsoleCommand("mutate respawn");
                DA.Destroy();
                break;

            case "FDAO": //ForceDropAtObj
                DA = spawn(class'DummyActor', FindPlayer(secondaryparam));
                // DA.CMConsoleCommand("mutate dropatobj "$tertiaryparam);
                DA.ClientCMConsoleCommand("mutate dropatobj "$tertiaryparam);
                DA.Destroy();
                break;

            case "FDAG": //ForceDropAtGrid
                DA = spawn(class'DummyActor', FindPlayer(secondaryparam));
                // DA.CMConsoleCommand("mutate dropatgrid "$tertiaryparam);
                DA.ClientCMConsoleCommand("mutate dropatgrid "$tertiaryparam);
                DA.Destroy();
                break;
            
            case "FORCESAFETYON":
                DA = spawn(class'DummyActor', FindPlayer(secondaryparam));
                // DA.CMConsoleCommand("mutate safetyon");
                DA.ClientCMConsoleCommand("mutate safetyon");
                DA.Destroy();
                break;

            case "FORCESAFETYOFF":
                DA = spawn(class'DummyActor', FindPlayer(secondaryparam));
                // DA.CMConsoleCommand("mutate safetyoff");
                DA.ClientCMConsoleCommand("mutate safetyoff");
                DA.Destroy();
                break;
        }
    }
    super.Mutate(MutateString, sender);
}

simulated function SetCMenuVisible(PlayerController PC, string CMenu, optional string TargetName)
{
    local DummyActor DA;

    DA = spawn(class'DummyActor', PC); //Spawn a dummyactor to do client side functions without replacing the playercontroller
    //DA.bIsAuthorized = IsAuthorized(PC);
    DA.SetCMenuVisible(CMenu, IsAuthorized(PC), TargetName);
    DA.ClientSetCMenuVisible(CMenu, IsAuthorized(PC), TargetName);
    DA.Destroy();
}

function bool IsAuthorized(PlayerController Sender)
{
    if (WorldInfo.NetMode == NM_Standalone) //In singleplayer IsAuthorized() doesn't work so just assume authorized
    {
        return true;
    }
    else
    {
        return MutRealismMatch(WorldInfo.Game.BaseMutator).IsAuthorized(Sender);
    }
}

function bool bIsMutThere(string Mutator)
{
    local ROGameInfo ROGI;
	local Mutator mut;

    ROGI = ROGameInfo(WorldInfo.Game);

    mut = ROGI.BaseMutator;

    //`Log("IsMutThere: "$Mutator);
    for (mut = ROGI.BaseMutator; mut != none; mut = mut.NextMutator)
    {
        if(InStr(string(mut.name), Mutator,,true) != -1) 
        {
            //`Log("IsMutThere: found "$mut.name);
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

defaultproperties
{
    TempAdminPass="Lev 1"
}
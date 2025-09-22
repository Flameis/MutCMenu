class CMenuRealismMatch extends CMenu;

function Initialize()
{
    if (bIsAuthorized == false)
    {
        MessageSelf("You are not authorized to use this menu.");
        GoToState('');
        return;
    }

	super.Initialize();
}

function bool CheckExceptions(string Command)
{
    
    switch (Caps(Command))
    {
        case "OPENOBJ":
        case "CLOSEOBJ":
        case "SETOBJNEUTRAL":
        case "SETOBJNORTH":
        case "SETOBJSOUTH":
            if(bCMenuDebug) `Log("DropAllAtObj");
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr="Mutate "$Command$" ";
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStrPos=Len(LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr); // set the value high in case name is quite long
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.GoToState('Typing');
            LocalPlayer(PC.Player).ViewportClient.ClearProgressMessages();
            LocalPlayer(PC.Player).ViewportClient.SetProgressTime(6);
            MessageSelf("Please Specify an Objective (Example: A or ALL)");
            return true;

        case "SETROUNDDURATION":
        case "SETNORTHREINFORCEMENTS":
        case "SETSOUTHREINFORCEMENTS":
            if(bCMenuDebug) `Log("SetRoundDuration");
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr="Mutate "$Command$" ";
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStrPos=Len(LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr); // set the value high in case name is quite long
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.GoToState('Typing');
            LocalPlayer(PC.Player).ViewportClient.ClearProgressMessages();
            LocalPlayer(PC.Player).ViewportClient.SetProgressTime(6);
            MessageSelf("Please Specify an integer (Example: 60)");
            return true;

        case "SETFF":
            if(bCMenuDebug) `Log("SETFF");
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr="Mutate "$Command$" ";
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStrPos=Len(LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr); // set the value high in case name is quite long
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.GoToState('Typing');
            LocalPlayer(PC.Player).ViewportClient.ClearProgressMessages();
            LocalPlayer(PC.Player).ViewportClient.SetProgressTime(6);
            MessageSelf("Please Specify a Decimal (Example: 0.5)");
            return true;

        case "SETCAPTIME":
            if(bCMenuDebug) `Log("SETCAPTIME");
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr="Mutate "$Command$" ";
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStrPos=Len(LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr); // set the value high in case name is quite long
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.GoToState('Typing');
            LocalPlayer(PC.Player).ViewportClient.ClearProgressMessages();
            LocalPlayer(PC.Player).ViewportClient.SetProgressTime(6);
            MessageSelf("Please specify a OBJ letter and a minimum capture timer in seconds (Example: A 45)");
            return true;

        default:
            return false;
    }
}

defaultproperties
{
    
    MenuName="REALISM MATCH"

    MenuText.add("Scrimmage Admin Help")
    MenuText.add("Enable Match")
    MenuText.add("Disable Match")
    MenuText.add("Force Match Live")
    MenuText.add("Reset Match Live")
    MenuText.add("Restart Round")
    MenuText.add("Suicide All / End Round")
    MenuText.add("Respawn All Dead Players")

    MenuText.add("Open Objective")
    MenuText.add("Close Objective")
    MenuText.add("Set Objective Neutral")
    MenuText.add("Set Objective North")
    MenuText.add("Set Objective South")
    MenuText.add("Set All Objectives Neutral")
    MenuText.add("Set All Objectives North")
    MenuText.add("Set All Objectives South")

    MenuText.add("Swap Teams")
    MenuText.add("Weapons Hold")
    MenuText.add("Weapons Free")
    MenuText.add("Toggle Auto Respawns")
    MenuText.add("Set Round Duration")
    MenuText.add("Set Friendly Fire Modifier")
    MenuText.add("Set North Reinforcements")
    MenuText.add("Set South Reinforcements")

    MenuText.add("Swap North to South")
    MenuText.add("Swap South to North")
    MenuText.add("Set Obj Minimum Capture Time")
    
    MenuCommand.add("SCRIMADMINHELP")
    MenuCommand.add("ENABLEMATCH")
    MenuCommand.add("DISABLEMATCH")
    MenuCommand.add("MATCHLIVE")
    MenuCommand.add("RESETLIVE")
    MenuCommand.add("RESTARTROUND")
    MenuCommand.add("ENDROUND")
    MenuCommand.add("RESPAWNALL")

    MenuCommand.add("OPENOBJ")
    MenuCommand.add("CLOSEOBJ")
    MenuCommand.add("SETOBJNEUTRAL")
    MenuCommand.add("SETOBJNORTH")
    MenuCommand.add("SETOBJSOUTH")
    MenuCommand.add("SETALLOBJNEUTRAL")
    MenuCommand.add("SETALLOBJNORTH")
    MenuCommand.add("SETALLOBJSOUTH")

    MenuCommand.add("SWAPTEAMS")
    MenuCommand.add("WEAPONSHOLD")
    MenuCommand.add("WEAPONSFREE")
    MenuCommand.add("TOGGLEAUTORESPAWNS")
    MenuCommand.add("SETROUNDDURATION")
    MenuCommand.add("SETFF")
    MenuCommand.add("SETNORTHREINFORCEMENTS")
    MenuCommand.add("SETSOUTHREINFORCEMENTS")

    MenuCommand.add("SWAPNORTH")
    MenuCommand.add("SWAPSOUTH")
    MenuCommand.add("SETCAPTIME")
}
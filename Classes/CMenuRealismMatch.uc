class CMenuRealismMatch extends CMenuBase;

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
            if(bCMenuDebug) `Log("SetRoundDuration");
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr="Mutate "$Command$" ";
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStrPos=Len(LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr); // set the value high in case name is quite long
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.GoToState('Typing');
            LocalPlayer(PC.Player).ViewportClient.ClearProgressMessages();
            LocalPlayer(PC.Player).ViewportClient.SetProgressTime(6);
            MessageSelf("Please Specify a Decimal (Example: 0.5)");
            return true;

        default:
            return false;
    }
}

defaultproperties
{
    bCMenuDebug=true
    MenuName="REALISM MATCH"

    MenuText(0)="Scrimmage Admin Help"
    MenuText(1)="Enable Match"
    MenuText(2)="Disable Match"
    MenuText(3)="Force Match Live"
    MenuText(4)="Reset Match Live"
    MenuText(5)="Restart Round"
    MenuText(6)="Suicide All / End Round"
    MenuText(7)="Respawn All Dead Players"

    MenuText(8)="Open Objective"
    MenuText(9)="Close Objective"
    MenuText(10)="Set Objective Neutral"
    MenuText(11)="Set Objective North"
    MenuText(12)="Set Objective South"
    MenuText(13)="Set All Objectives Neutral"
    MenuText(14)="Set All Objectives North"
    MenuText(15)="Set All Objectives South"

    MenuText(16)="Swap Teams"
    MenuText(17)="Weapons Hold"
    MenuText(18)="Weapons Free"
    MenuText(19)="Toggle Auto Respawns"
    MenuText(20)="Set Round Duration"
    MenuText(21)="Set Friendly Fire Modifier"
    MenuText(22)="Set North Reinforcements"
    MenuText(23)="Set South Reinforcements"

    MenuText(24)="Swap North to South"
    MenuText(25)="Swap South to North"

    
    MenuCommand(0)="SCRIMADMINHELP"
    MenuCommand(1)="ENABLEMATCH"
    MenuCommand(2)="DISABLEMATCH"
    MenuCommand(3)="MATCHLIVE"
    MenuCommand(4)="RESETLIVE"
    MenuCommand(5)="RESTARTROUND"
    MenuCommand(6)="ENDROUND"
    MenuCommand(7)="RESPAWNALL"

    MenuCommand(8)="OPENOBJ"
    MenuCommand(9)="CLOSEOBJ"
    MenuCommand(10)="SETOBJNEUTRAL"
    MenuCommand(11)="SETOBJNORTH"
    MenuCommand(12)="SETOBJSOUTH"
    MenuCommand(13)="SETALLOBJNEUTRAL"
    MenuCommand(14)="SETALLOBJNORTH"
    MenuCommand(15)="SETALLOBJSOUTH"

    MenuCommand(16)="SWAPTEAMS"
    MenuCommand(17)="WEAPONSHOLD"
    MenuCommand(18)="WEAPONSFREE"
    MenuCommand(19)="TOGGLEAUTORESPAWNS"
    MenuCommand(20)="SETROUNDDURATION"
    MenuCommand(21)="SETFF"
    MenuCommand(22)="SETNORTHREINFORCEMENTS"
    MenuCommand(23)="SETSOUTHREINFORCEMENTS"

    MenuCommand(24)="SWAPNORTH"
    MenuCommand(25)="SWAPSOUTH"
}
class CMenuPCManager extends CMenuBase;

function Initialize()
{
    local int i;

	super.Initialize();
    
    MenuName=TargetName;

    for (i = 0; i < MenuCommand.Length; i++)
    {
        MenuCommand[i] = default.menucommand[i]@TargetName;
        if(bCMenuDebug) `log(MenuCommand[i]);
    }
}

function bool CheckExceptions(string Command)
{
    local array<string> Params;
    Params = SplitString(Command, " ", true);
    switch (Caps(Params[0]))
    {
        case "FORCECHANGENAME":
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr="mutate "$Command$" to ";
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStrPos=Len(LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr); // set the value high in case name is quite long
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.GoToState('Typing');
            LocalPlayer(PC.Player).ViewportClient.ClearProgressMessages();
            LocalPlayer(PC.Player).ViewportClient.SetProgressTime(6);
            MessageSelf("Please Type Your Desired Name (Example: T/5 Scovel [29ID])");
            return true;

        case "FDAO":
            if(bCMenuDebug) `Log("DropAtObj");
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr="mutate "$Command$" to ";
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStrPos=Len(LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr); // set the value high in case name is quite long
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.GoToState('Typing');
            LocalPlayer(PC.Player).ViewportClient.ClearProgressMessages();
            LocalPlayer(PC.Player).ViewportClient.SetProgressTime(6);
            MessageSelf("Please Specify an Objective (Example: A)");
            return true;

        case "FDAG":
            if(bCMenuDebug) `Log("DropAtGrid");
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr="mutate "$Command$" to ";
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStrPos=Len(LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr); // set the value high in case name is quite long
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.GoToState('Typing');
            LocalPlayer(PC.Player).ViewportClient.ClearProgressMessages();
            LocalPlayer(PC.Player).ViewportClient.SetProgressTime(6);
            MessageSelf("Please Specify a Grid Location (Example: E 5 kp 5)");
            return true;

        default:
            return false;
    }
}

defaultproperties
{
    MenuText(0)="Respawn"
    MenuText(1)="Kill"
    MenuText(2)="Drop At Objective"
    MenuText(3)="Drop At Grid"
    MenuText(4)="Teleport To Me"
    MenuText(5)="Change Name"
    MenuText(6)="Find Original Name"
    MenuText(7)="Switch Team"

    MenuText(8)="Safety On"
    MenuText(9)="Safety Off"
    MenuText(10)="Give Temporary Scrimmage Admin Powers"
    MenuText(11)="Revoke Temporary Scrimmage Admin Powers"

    
    MenuCommand(0)="FORCERESPAWN"
    MenuCommand(1)="KILLPLAYER"
    MenuCommand(2)="FDAO"
    MenuCommand(3)="FDAG"
    MenuCommand(4)="TELEPORTTOME"
    MenuCommand(5)="FORCECHANGENAME"
    MenuCommand(6)="WHOIS"
    MenuCommand(7)="FORCESWITCHTEAM"

    MenuCommand(8)="FORCESAFETYON"
    MenuCommand(9)="FORCESAFETYOFF"
    MenuCommand(10)="TEMPADMINLOGIN"
    MenuCommand(11)="TEMPADMINLOGOUT"
}
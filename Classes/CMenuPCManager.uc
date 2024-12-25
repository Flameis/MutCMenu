class CMenuPCManager extends CMenu;

simulated state MenuVisible
{
	function BeginState(name PreviousStateName)
	{
        if (bIsAuthorized == false)
        {
            MessageSelf("You are not authorized to use this menu.");
            GoToState('');
            return;
        }
		else
        {
            super.BeginState(PreviousStateName);
        }
	}
}

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
    MenuText.add("Respawn")
    MenuText.add("Kill")
    MenuText.add("Drop At Objective")
    MenuText.add("Drop At Grid")
    MenuText.add("Teleport To Me")
    MenuText.add("Change Name")
    MenuText.add("Find Original Name")
    MenuText.add("Switch Team")

    MenuText.add("Safety On")
    MenuText.add("Safety Off")
    MenuText.add("Give Temporary Scrimmage Admin Powers")
    MenuText.add("Revoke Temporary Scrimmage Admin Powers")

    MenuCommand.add("FORCERESPAWN")
    MenuCommand.add("KILLPLAYER")
    MenuCommand.add("FDAO")
    MenuCommand.add("FDAG")
    MenuCommand.add("TELEPORTTOME")
    MenuCommand.add("FORCECHANGENAME")
    MenuCommand.add("WHOIS")
    MenuCommand.add("FORCESWITCHTEAM")

    MenuCommand.add("FORCESAFETYON")
    MenuCommand.add("FORCESAFETYOFF")
    MenuCommand.add("TEMPADMINLOGIN")
    MenuCommand.add("TEMPADMINLOGOUT")
}
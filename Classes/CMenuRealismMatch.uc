class CMenuRealismMatch extends CMenu;

function Initialize()
{
    if (bIsAuthorized == false)
    {
        MessageSelf("You are not authorized to use this menu.");
        GoToState('');
        return;
    }

    SetTeamDisplayNames();

	super.Initialize();
}

function SetTeamDisplayNames()
{
    local string MapName;
    local string NorthTeamName, SouthTeamName;

    MapName = PC.WorldInfo.GetMapName(true);
    NorthTeamName = "North";
    SouthTeamName = "South";

    if (InStr(MapName, "WWTE",,true) != -1 || InStr(MapName, "WWSU",,true) != -1)
    {
        NorthTeamName = "Finnish";
        SouthTeamName = "Soviets";
    }
    else if (InStr(MapName, "RR",,true) != -1 || InStr(MapName, "DR",,true) != -1)
    {
        NorthTeamName = "Axis";
        SouthTeamName = "Allies";
    }

    MenuText[15] = "Set Objective "$NorthTeamName;
    MenuText[16] = "Set Objective "$SouthTeamName;
    MenuText[18] = "Set All Objectives "$NorthTeamName;
    MenuText[19] = "Set All Objectives "$SouthTeamName;
    MenuText[26] = "Set "$NorthTeamName$" Reinforcements";
    MenuText[27] = "Set "$SouthTeamName$" Reinforcements";
    MenuText[28] = "Swap "$NorthTeamName$" to "$SouthTeamName;
    MenuText[29] = "Swap "$SouthTeamName$" to "$NorthTeamName;
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
            PromptForText("Please Specify an Objective (Example: A or ALL)", "Mutate "$Command$" ");
            return true;

        case "SETROUNDDURATION":
        case "SETNORTHREINFORCEMENTS":
        case "SETSOUTHREINFORCEMENTS":
            if(bCMenuDebug) `Log("SetRoundDuration");
            PromptForText("Please Specify an integer (Example: 60)", "Mutate "$Command$" ");
            return true;

        case "SETFF":
            if(bCMenuDebug) `Log("SETFF");
            PromptForText("Please Specify a Decimal (Example: 0.5)", "Mutate "$Command$" ");
            return true;

        case "SETCAPTIME":
            if(bCMenuDebug) `Log("SETCAPTIME");
            PromptForText("Please specify a OBJ letter and a minimum capture timer in seconds (Example: A 45)", "Mutate "$Command$" ");
            return true;

        case "COUNTDOWN":
            if(bCMenuDebug) `Log("COUNTDOWN");
            PromptForText("Please specify countdown duration in seconds (Example: 10)", "Mutate "$Command$" ");
            return true;

        case "ROUNDTIMER":
            if(bCMenuDebug) `Log("ROUNDTIMER");
            PromptForText("Please specify round timer duration in minutes, 0 to disable (Example: 20)", "Mutate "$Command$" ");
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
    MenuText.add("Countdown")
    MenuText.add("Cancel Live Countdown")
    MenuText.add("Round Timer")
    MenuText.add("Cancel Round Timer")
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
    MenuCommand.add("COUNTDOWN")
    MenuCommand.add("CANCELCOUNT")
    MenuCommand.add("ROUNDTIMER")
    MenuCommand.add("CANCELROUNDTIMER")
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
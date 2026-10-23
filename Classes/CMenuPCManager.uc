class CMenuPCManager extends CMenu;

function Initialize()
{
    local int i;

    if (bIsAuthorized == false)
    {
        MessageSelf("You are not authorized to use this menu.");
        GoToState('');
        return;
    }

    MenuName=TargetName;

    for (i = 0; i < MenuCommand.Length; i++)
    {
        MenuCommand[i] = default.menucommand[i]$" --player "$TargetName;
        if(bCMenuDebug) `log(MenuCommand[i]);
    }

    super.Initialize();
}

function bool CheckExceptions(string Command)
{
    local array<string> Params;
    Params = SplitString(Command, " ", true);
    switch (Caps(Params[0]))
    {
        case "FORCECHANGENAME":
            PromptForText("Force Name Change|Type the new name for this player, e.g. T/5 Scovel [29ID]|Full syntax: mutate forcechangename --player Old Name --name New Name|Short: -p -n   (older form: forcechangename Old Name to New Name)", "mutate "$Command$" --name ");
            return true;

        case "FDAO":
            if(bCMenuDebug) `Log("DropAtObj");
            PromptForText("Drop Player At Objective|Type the objective letter, e.g. A|Full syntax: mutate fdao --player Name --obj A   (short: -p -o)", "mutate "$Command$" --obj ");
            return true;

        case "FDAG":
            if(bCMenuDebug) `Log("DropAtGrid");
            PromptForText("Drop Player At Grid|Type a grid, e.g. E 5 kp 5|Full syntax: mutate fdag --player Name --grid E 5 kp 5   (short: -p -g)", "mutate "$Command$" --grid ");
            return true;

        case "FORCEUNITPATCH":
            if(bCMenuDebug) `Log("ForceUnitPatch");
            PromptForText("Change Unit Patch|Type a unit, e.g. DP2S4|Full syntax: mutate forceunitpatch --player Name --unit DP2S4   (short: -p -u)", "mutate "$Command$" --unit ");
            return true;

        case "FORCERANKPATCH":
            if(bCMenuDebug) `Log("ForceRankPatch");
            PromptForText("Change Rank Patch|Type a rank, e.g. sgtmaj|Full syntax: mutate forcerankpatch --player Name --rank sgtmaj   (short: -p -r)", "mutate "$Command$" --rank ");
            return true;

        default:
            return false;
    }
}

defaultproperties
{
    MenuText.add("Drop At Objective")
    MenuText.add("Drop At Grid")
    MenuText.add("Teleport To Me")
    MenuText.add("Change Name")
    MenuText.add("Find Original Name")
    MenuText.add("Switch Team")
    MenuText.add("Change Unit Patch")
    MenuText.add("Change Rank Patch")

    MenuText.add("Safety On")
    MenuText.add("Safety Off")
    MenuText.add("Respawn")
    MenuText.add("Kill")
    MenuText.add("Give Temporary Scrimmage Admin Powers")
    MenuText.add("Revoke Temporary Scrimmage Admin Powers")

    
    MenuCommand.add("FDAO")
    MenuCommand.add("FDAG")
    MenuCommand.add("TELEPORTTOME")
    MenuCommand.add("FORCECHANGENAME")
    MenuCommand.add("WHOIS")
    MenuCommand.add("FORCESWITCHTEAM")
    MenuCommand.add("FORCEUNITPATCH")
    MenuCommand.add("FORCERANKPATCH")


    MenuCommand.add("FORCESAFETYON")
    MenuCommand.add("FORCESAFETYOFF")
    MenuCommand.add("FORCERESPAWN")
    MenuCommand.add("KILLPLAYER")
    MenuCommand.add("TEMPADMINLOGIN")
    MenuCommand.add("TEMPADMINLOGOUT")
}
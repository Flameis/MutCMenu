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
            PromptForText("Change Name|--name / -n : the new name for this player (already typed for you, add the name)|Example: --name T/5 Scovel [29ID]|Full command: mutate forcechangename --player Old Name --name New Name   (short -p -n; older form: forcechangename Old Name to New Name)", "mutate "$Command$" --name ");
            return true;

        case "FDAO":
            if(bCMenuDebug) `Log("DropAtObj");
            PromptForText("Drop Player At Objective|--obj / -o : the objective letter (already typed for you, add the letter)|Example: --obj A|Full command: mutate fdao --player Name --obj A   (short -p -o; older form: fdao Name to A)", "mutate "$Command$" --obj ");
            return true;

        case "FDAG":
            if(bCMenuDebug) `Log("DropAtGrid");
            PromptForText("Drop Player At Grid|--grid / -g : the grid square (already typed for you, add the grid)|Example: --grid E 5 kp 5|Full command: mutate fdag --player Name --grid E 5 kp 5   (short -p -g; older form: fdag Name to E 5 kp 5)", "mutate "$Command$" --grid ");
            return true;

        case "FORCEUNITPATCH":
            if(bCMenuDebug) `Log("ForceUnitPatch");
            PromptForText("Change Unit Patch|--unit / -u : the unit (already typed for you, add the unit)|Example: --unit DP2S4|Full command: mutate forceunitpatch --player Name --unit DP2S4   (short -p -u; older form: forceunitpatch Name to DP2S4)", "mutate "$Command$" --unit ");
            return true;

        case "FORCERANKPATCH":
            if(bCMenuDebug) `Log("ForceRankPatch");
            PromptForText("Change Rank Patch|--rank / -r : the rank (already typed for you, add the rank)|Example: --rank sgtmaj|Full command: mutate forcerankpatch --player Name --rank sgtmaj   (short -p -r; older form: forcerankpatch Name to sgtmaj)", "mutate "$Command$" --rank ");
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
    MenuText.add("Give Temp Scrim Admin")
    MenuText.add("Revoke Temp Scrim Admin")

    
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
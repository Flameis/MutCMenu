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
        MenuCommand[i] = default.menucommand[i]@TargetName;
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
            PromptForText("Please Type Your Desired Name (Example: T/5 Scovel [29ID])", "mutate "$Command$" to ");
            return true;

        case "FDAO":
            if(bCMenuDebug) `Log("DropAtObj");
            PromptForText("Please Specify an Objective (Example: A)", "mutate "$Command$" to ");
            return true;

        case "FDAG":
            if(bCMenuDebug) `Log("DropAtGrid");
            PromptForText("Please Specify a Grid Location (Example: E 5 kp 5)", "mutate "$Command$" to ");
            return true;

        case "FORCEUNITPATCH":
            if(bCMenuDebug) `Log("ForceUnitPatch");
            PromptForText("Please Specify a Unit (Example: DP2S4)", "mutate "$Command$" to ");
            return true;

        case "FORCERANKPATCH":
            if(bCMenuDebug) `Log("ForceRankPatch");
            PromptForText("Please Specify a Rank (Example: sgtmaj)", "mutate "$Command$" to ");
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
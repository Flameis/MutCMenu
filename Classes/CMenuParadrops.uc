class CMenuParadrops extends CMenu;

function bool CheckExceptions(string Command)
{
    switch (Caps(Command))
    {
        case "DROPALLATGRID":
        case "DROPNORTHATGRID":
        case "DROPSOUTHATGRID":
            if(bCMenuDebug) `Log("DropAtGrid");
            PromptForText("Please Specify a Grid Location (Example: E 5 kp 5)", "Mutate "$Command$" ");
            return true;
            
        case "DROPALLATOBJ":
        case "DROPNORTHATOBJ":
        case "DROPSOUTHATOBJ":
            if(bCMenuDebug) `Log("DropAtObj");
            PromptForText("Please Specify an Objective (Example: A)", "Mutate "$Command$" ");
            return true;

        default:
            return false;
    }
}

defaultproperties
{
    MenuName="PARADROPS"

    MenuText.add("Drop All At Obj")
    MenuText.add("Drop North At Obj")
    MenuText.add("Drop South At Obj")
    MenuText.add("Drop All At Grid")
    MenuText.add("Drop North At Grid")
    MenuText.add("Drop South At Grid")
    
    MenuCommand.add("DROPALLATOBJ")
    MenuCommand.add("DROPNORTHATOBJ")
    MenuCommand.add("DROPSOUTHATOBJ")
    MenuCommand.add("DROPALLATGRID")
    MenuCommand.add("DROPNORTHATGRID")
    MenuCommand.add("DROPSOUTHATGRID")
}
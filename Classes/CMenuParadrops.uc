class CMenuParadrops extends CMenu;

function bool CheckExceptions(string Command)
{
    switch (Caps(Command))
    {
        case "DROPALLATGRID":
        case "DROPNORTHATGRID":
        case "DROPSOUTHATGRID":
            if(bCMenuDebug) `Log("DropAtGrid");
            PromptForText("Drop At Grid|--grid / -g : grid letter A-J, number 1-10 and an optional keypad 1-9|Example: --grid E 5 kp 5   (or just E 5 kp 5)", "Mutate "$Command$" ", , "grid");
            return true;
            
        case "DROPALLATOBJ":
        case "DROPNORTHATOBJ":
        case "DROPSOUTHATOBJ":
            if(bCMenuDebug) `Log("DropAtObj");
            PromptForText("Drop At Objective|--obj / -o : the objective letter|Example: --obj A   (or just A)", "Mutate "$Command$" ", , "obj");
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
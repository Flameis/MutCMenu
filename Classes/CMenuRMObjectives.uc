// Realism Match: objective states, owners, capture times and the random objective draw
class CMenuRMObjectives extends CMenuRMBase;

function SetTeamDisplayNames()
{
    local string NorthName, SouthName;

    GetTeamNames(NorthName, SouthName);
    MenuText[5] = "Set Objective "$NorthName;
    MenuText[6] = "Set Objective "$SouthName;
    MenuText[8] = "Set All Objectives "$NorthName;
    MenuText[9] = "Set All Objectives "$SouthName;
}

function bool CheckExceptions(string Command)
{
    switch (Caps(Command))
    {
        case "OPENOBJ":
        case "CLOSEOBJ":
            PromptForText("Objective|--obj / -o : objective letter A-P, or ALL|Example: --obj A   (or just A)", "Mutate "$Command$" ");
            return true;

        case "SETOBJNEUTRAL":
        case "SETOBJNORTH":
        case "SETOBJSOUTH":
            PromptForText("Set Objective Owner|--obj / -o : objective letter A-P, or ALL|Example: --obj C   (or just C)", "Mutate "$Command$" ");
            return true;

        case "RANDOMOBJ":
            PromptForText("Random Objective|Opens one of the listed objectives at random when the time is up (others are left as they are)|--obj / -o : objectives to pick from, e.g. a,b,c (default: all)|--time / -t : seconds until one opens (default: 0 = right away)|--live / -l : start the countdown when the match goes LIVE|Example: --obj a,b,c --time 60 --live", "Mutate "$Command$" ");
            return true;

        case "SETCAPTIME":
            PromptForText("Minimum Capture Time|--obj / -o : objective letter A-P, or ALL|--time / -t : seconds to capture (greater than 0)|Example: --obj A --time 45   (or just: A 45)", "Mutate "$Command$" ");
            return true;

        default:
            return false;
    }
}

defaultproperties
{
    MenuName="OBJECTIVES"

    MenuText.add("Open Objective")
    MenuText.add("Close Objective")
    MenuText.add("Random Objective")
    MenuText.add("Cancel Random Objective")
    MenuText.add("Set Objective Neutral")
    MenuText.add("Set Objective North")
    MenuText.add("Set Objective South")
    MenuText.add("Set All Objectives Neutral")
    MenuText.add("Set All Objectives North")
    MenuText.add("Set All Objectives South")
    MenuText.add("Set Obj Minimum Capture Time")

    MenuCommand.add("OPENOBJ")
    MenuCommand.add("CLOSEOBJ")
    MenuCommand.add("RANDOMOBJ")
    MenuCommand.add("RANDOMOBJ --cancel")
    MenuCommand.add("SETOBJNEUTRAL")
    MenuCommand.add("SETOBJNORTH")
    MenuCommand.add("SETOBJSOUTH")
    MenuCommand.add("SETALLOBJNEUTRAL")
    MenuCommand.add("SETALLOBJNORTH")
    MenuCommand.add("SETALLOBJSOUTH")
    MenuCommand.add("SETCAPTIME")
}

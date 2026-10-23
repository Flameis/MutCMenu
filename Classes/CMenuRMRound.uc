// Realism Match: round timer, round duration, friendly fire, reinforcements and respawns
class CMenuRMRound extends CMenuRMBase;

function SetTeamDisplayNames()
{
    local string NorthName, SouthName;

    GetTeamNames(NorthName, SouthName);
    MenuText[6] = "Set "$NorthName$" Reinforcements";
    MenuText[7] = "Set "$SouthName$" Reinforcements";
}

function bool CheckExceptions(string Command)
{
    switch (Caps(Command))
    {
        case "ROUNDTIMER":
            PromptForText("Round Timer|--time / -t : minutes after LIVE until the match resets to the briefing (0 disables it)|Example: --time 20   (or just 20)", "Mutate "$Command$" ");
            return true;

        case "SETROUNDDURATION":
            PromptForText("Round Duration|--time / -t : round length in minutes, also applied to the round in progress|Example: --time 60   (or just 60)", "Mutate "$Command$" ");
            return true;

        case "SETRESPAWNTIME":
            PromptForText("Respawn Deployment Time|--time / -t : seconds both teams wait to respawn after dying, 0 to 600 (0 = the map's own times). Applies to deaths from now on|Example: --time 15   (or just 15)", "Mutate "$Command$" ");
            return true;

        case "SETFF":
            PromptForText("Friendly Fire Modifier|--value / -v : friendly fire scale from 0.0 (off) to 1.0 (full)|Example: --value 0.5   (or just 0.5)", "Mutate "$Command$" ");
            return true;

        case "SETNORTHREINFORCEMENTS":
        case "SETSOUTHREINFORCEMENTS":
            PromptForText("Reinforcements|--count / -c : number of reinforcement tickets|Example: --count 100   (or just 100)", "Mutate "$Command$" ");
            return true;

        default:
            return false;
    }
}

defaultproperties
{
    MenuName="ROUND SETTINGS"

    MenuText.add("Round Timer")
    MenuText.add("Cancel Round Timer")
    MenuText.add("Set Round Duration")
    MenuText.add("Set Respawn Deployment Time")
    MenuText.add("Set Friendly Fire Modifier")
    MenuText.add("Toggle Auto Respawns")
    MenuText.add("Set North Reinforcements")
    MenuText.add("Set South Reinforcements")

    MenuCommand.add("ROUNDTIMER")
    MenuCommand.add("CANCELROUNDTIMER")
    MenuCommand.add("SETROUNDDURATION")
    MenuCommand.add("SETRESPAWNTIME")
    MenuCommand.add("SETFF")
    MenuCommand.add("TOGGLEAUTORESPAWNS")
    MenuCommand.add("SETNORTHREINFORCEMENTS")
    MenuCommand.add("SETSOUTHREINFORCEMENTS")
}

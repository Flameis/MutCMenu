// Realism Match: enabling the match, going LIVE and restarting rounds
class CMenuRMControl extends CMenuRMBase;

function bool CheckExceptions(string Command)
{
    switch (Caps(Command))
    {
        case "COUNTDOWN":
            PromptForText("Countdown to LIVE|--time / -t : seconds until the match goes LIVE|Example: --time 10   (or just 10)", "Mutate "$Command$" ", , "time");
            return true;

        default:
            return false;
    }
}

defaultproperties
{
    MenuName="MATCH CONTROL"

    MenuText.add("Enable Match")
    MenuText.add("Disable Match")
    MenuText.add("Force Match Live")
    MenuText.add("Countdown To Live")
    MenuText.add("Cancel Live Countdown")
    MenuText.add("Reset Match Live")
    MenuText.add("Restart Round")
    MenuText.add("Suicide All / End Round")
    MenuText.add("Respawn All Dead Players")

    MenuCommand.add("ENABLEMATCH")
    MenuCommand.add("DISABLEMATCH")
    MenuCommand.add("MATCHLIVE")
    MenuCommand.add("COUNTDOWN")
    MenuCommand.add("CANCELCOUNT")
    MenuCommand.add("RESETLIVE")
    MenuCommand.add("RESTARTROUND")
    MenuCommand.add("ENDROUND")
    MenuCommand.add("RESPAWNALL")
}

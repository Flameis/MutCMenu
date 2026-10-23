class CMenuFireSupport extends CMenu;

function Initialize()
{
    if (!bIsAuthorized && (MyDA == None || !MyDA.bFSPlayersCanCall))
    {
        MessageSelf("Fire support is not available to you.");
        GoToState('');
        return;
    }

    // Stopping every team's fire support is for admins
    if (bIsAuthorized)
    {
        MenuText.AddItem("Cancel All Fire Support");
        MenuCommand.AddItem("CANCELFIRESUPPORT --all");
    }

    super.Initialize();
}

function bool CheckExceptions(string Command)
{
    if (InStr(Caps(Command), "FIRESUPPORT ") == 0)
    {
        if (bCMenuDebug) `Log("FireSupport");
        PromptForText("Fire Support|--grid / -g : the grid to hit, e.g. E 5 kp 5 (or E5)   --mark / -m : your team's marked arty position|Example: E 5 kp 5   or   MARK|Admin barrage settings: --salvos -s, --shells -n, --spread -r (meters), --interval -i, --delay -d, --persist -p (saves them)|Napalm/Canberra: --direction -b <N, NE, ... or 0-360> = the way they fly   Admins: --suppress -q hides the announcement|Example: E5 --salvos 5 --shells 8 --spread 8   or   napalm E5 --direction SW", "Mutate "$Command$" ");
        return true;
    }

    return false;
}

defaultproperties
{
    MenuName="FIRE SUPPORT"

    MenuText.add("Mortar Barrage")
    MenuText.add("Artillery Barrage")
    MenuText.add("Airburst Artillery")
    MenuText.add("Rocket Barrage")
    MenuText.add("White Phosphorus Barrage")
    MenuText.add("Mixed Barrage")
    MenuText.add("Napalm Strike")
    MenuText.add("Canberra Bombing Run")
    MenuText.add("AC-47 Gunship")
    MenuText.add("Cancel Fire Support (My Team)")

    MenuCommand.add("FIRESUPPORT --type mortar --grid")
    MenuCommand.add("FIRESUPPORT --type artillery --grid")
    MenuCommand.add("FIRESUPPORT --type airburst --grid")
    MenuCommand.add("FIRESUPPORT --type rocket --grid")
    MenuCommand.add("FIRESUPPORT --type wp --grid")
    MenuCommand.add("FIRESUPPORT --type mixed --grid")
    MenuCommand.add("FIRESUPPORT --type napalm --grid")
    MenuCommand.add("FIRESUPPORT --type canberra --grid")
    MenuCommand.add("FIRESUPPORT --type spooky --grid")
    MenuCommand.add("CANCELFIRESUPPORT")
}

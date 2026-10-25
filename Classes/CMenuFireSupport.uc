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
        PromptForText("Fire Support|Where (--grid is already typed for you, add the grid, or replace it with one of the others):|--grid / -g : a grid square, e.g. E 5 kp 5 or E5|--mark / -m : your squad's mark (squad leaders) or the mark selected on your map (commander); --mark SL3 or --SL 3 picks squad 3's, --mark CMD the commander's|--look / -k : the spot you are looking at|Options: --salvos -s, --shells -n, --spread -r (meters), --interval -i (seconds after the first), --delay -d (10-300 s), --suppress -q (no announcement), --direction -b (napalm and Canberra: N, SW, ... or 0-360)|--team north / south : the side the call is for (spectators must give one)   Admins only: --persist -p saves the settings as the new default|Example: --grid E5 --salvos 5 --shells 8 --spread 8|Example: --look --team south   or   --mark SL2 --delay 30|Older form: firesupport mortar E 5 kp 5   (mutate firesupporthelp lists everything)", "Mutate "$Command$" ", , "grid,mark,look!,salvos,shells,spread,interval,delay,direction,suppress!,team,persist!");
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

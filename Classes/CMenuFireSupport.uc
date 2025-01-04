class CMenuFireSupport extends CMenu;

function Initialize()
{
    super.Initialize();

    if (bIsAuthorized)
    {
        MenuText.AddItem("Call Artillery");
        MenuCommand.AddItem("CALLARTILLERY");

        MenuText.AddItem("Call Mortar");
        MenuCommand.AddItem("CALLMORTAR");

        MenuText.AddItem("Call Airstrike");
        MenuCommand.AddItem("CALLAIRSTRIKE");
    }
}

function bool CheckExceptions(string Command)
{
    switch (Caps(Command))
    {
        case "CALLARTILLERY":
            PC.ConsoleCommand("mutate CALLARTILLERY");
            return true;

        case "CALLMORTAR":
            PC.ConsoleCommand("mutate CALLMORTAR");
            return true;

        case "CALLAIRSTRIKE":
            PC.ConsoleCommand("mutate CALLAIRSTRIKE");
            return true;

        default:
            return false;
    }
}

defaultproperties
{
    MenuName="FIRESUPPORT"

    MenuText(0)="Call Artillery"
    MenuText(1)="Call Mortar"
    MenuText(2)="Call Airstrike"

    MenuCommand(0)="CALLARTILLERY"
    MenuCommand(1)="CALLMORTAR"
    MenuCommand(2)="CALLAIRSTRIKE"
}

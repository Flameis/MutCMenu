class CMenuMain extends CMenu;

function Initialize()
{
    MessageSelf("Welcome to CMenu, login to scrim admin to see all the options.");

    if (bIsAuthorized)
    {
        MenuText.additem("Realism Match Menu");
        MenuText.additem("Paradrop Menu");
        MenuText.additem("Manage Players");
        MenuCommand.additem("CMENU CMENUREALISMMATCH");
        MenuCommand.additem("CMENU CMENUPARADROPS");
        MenuCommand.additem("CMENU CMENUPLAYER");
    }

    MenuText.AddItem("CMenu Settings");
    MenuCommand.AddItem("CMENU CMENUSETTINGS");

    MenuText.AddItem("Toggle Mouse Click Mode");
    MenuCommand.AddItem("TOGGLECLICKMODE");

	super.Initialize();
}

function bool CheckExceptions(string Command)
{
    switch (Caps(Command))
    {
        case "TOGGLECLICKMODE":
            MyDA.bClickModeActive = !MyDA.bClickModeActive;
            MessageSelf(MyDA.bClickModeActive ? "Mouse click mode enabled" : "Mouse click mode disabled");
            RebuildClickOverlay();
            return true;

        default:
            return false;
    }
}

defaultproperties
{
    MenuName="MAIN MENU"

    MenuText.add("General Commands")
    MenuText.add("Builder Menu")
    MenuText.add("Weapon Menu")
    MenuCommand.add("CMENU CMENUGENERAL")
    MenuCommand.add("CMENU CMENUBMAIN")
    MenuCommand.add("CMENU CMENUWEAPONS")
}
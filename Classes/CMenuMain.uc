class CMenuMain extends CMenuBase;

function Initialize()
{
    if (bMutExtras || bMutCommands)
    {
        MenuText.AddItem("Weapon Menu");
        MenuText.AddItem("Vehicle Menu");
        MenuCommand.AddItem("CMENU CMENUWEAPONS");
        MenuCommand.AddItem("CMENU CMENUVEHICLES");

        /* if (bMutExtras)
        {
            MenuText.AddItem("Builder Menu");
            MenuCommand.AddItem("CMENUBUILDER");
        } */
    }

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

	super.Initialize();
}

simulated state MenuVisible
{
    function EndState(name PreviousStateName)
	{
        MenuText.Remove(default.MenuCommand.Length, MenuText.Length-default.MenuCommand.Length);
        MenuCommand.Remove(default.MenuCommand.Length, MenuCommand.Length-default.MenuCommand.Length);
	}
}

defaultproperties
{
    bCMenuDebug=true

    MenuName="MAIN MENU"

    MenuText(0)="General Commands"
    MenuText(1)="Static Mesh Builder Menu"
    MenuCommand(0)="CMENU CMENUGENERAL"
    MenuCommand(1)="CMENU CMENUBUILDER"
}
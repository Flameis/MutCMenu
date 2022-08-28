class CMenuMain extends CMenuBase;

simulated state MenuVisible
{
    function BeginState(name PreviousStateName)
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

        super.BeginState(PreviousStateName);
	}

    function EndState(name PreviousStateName)
	{
        MenuText.Remove(1, MenuText.Length-1);
        MenuCommand.Remove(1, MenuCommand.Length-1);
        super.EndState(PreviousStateName);
	}
}

defaultproperties
{
    bCMenuDebug=true

    MenuName="MAIN MENU"

    MenuText(0)="General Commands"
    MenuCommand(0)="CMENU CMENUGENERAL"
}
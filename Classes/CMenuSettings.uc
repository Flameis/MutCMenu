class CMenuSettings extends CMenu;

function bool CheckExceptions(string Command)
{
    switch (Caps(Command))
    {
        case "SETCMENUTEXTCOLOR":
        case "SETCMENUBGCOLOR":
        case "SETCMENUBORDERCOLOR":
            if(bCMenuDebug) `Log("DropAtGrid");
            PromptForText("Please Specify a Color in RGBA Format (Example: 255 128 0 255(Optional Transparency) for Orange)", "Mutate "$Command$" ");
            return true;

        case "TOGGLECMENUBACKGROUND":
            ToggleCMenuBackground();
            return true;

        case "TOGGLECMENUSTAY":
            ToggleCMenuStay();
            return true;

        default:
            return false;
    }
}

defaultproperties
{
    MenuName="SETTINGS"

    MenuText.add("Set CMenu Text Color")
    MenuText.add("Set CMenu Background Color")
    MenuText.add("Set CMenu Border Color")
    MenuText.add("Toggle CMenu Background")
    MenuText.add("Toggle CMenu Stay")
    
    MenuCommand.add("SETCMENUTEXTCOLOR")
    MenuCommand.add("SETCMENUBGCOLOR")
    MenuCommand.add("SETCMENUBORDERCOLOR")
    MenuCommand.add("TOGGLECMENUBACKGROUND")
    MenuCommand.add("TOGGLECMENUSTAY")
}
class CMenuSettings extends CMenu;

function bool CheckExceptions(string Command)
{
    local array<string> Params;

    Params = SplitString(Command, " ", true);
    switch (Caps(Params[0]))
    {
        case "SETCMENUCOLOR":
            if(bCMenuDebug) `Log("SetCMenuColor");
            PromptForText("CMenu Color|Type the color as R G B A (alpha is optional), e.g. 255 128 0 255 for orange|Full syntax: mutate setcmenucolor --text R G B A --background R G B A --border R G B A|Short: -t -b -o", "Mutate "$Command$" ");
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
    
    MenuCommand.add("SETCMENUCOLOR --text")
    MenuCommand.add("SETCMENUCOLOR --background")
    MenuCommand.add("SETCMENUCOLOR --border")
    MenuCommand.add("TOGGLECMENUBACKGROUND")
    MenuCommand.add("TOGGLECMENUSTAY")
}
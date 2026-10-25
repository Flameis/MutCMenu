class CMenuSettings extends CMenu;

function bool CheckExceptions(string Command)
{
    local array<string> Params;

    Params = SplitString(Command, " ", true);
    switch (Caps(Params[0]))
    {
        case "SETCMENUCOLOR":
            if(bCMenuDebug) `Log("SetCMenuColor");
            PromptForText("CMenu Color|--text / -t, --background / -b, --border / -o : the colour as R G B A, alpha optional (the option is already typed for you, add the colour)|Example: --text 255 128 0 255 (orange)|Several at once: --text 255 128 0 --background 0 0 0 200 --border 255 255 255|Older form: setcmenutextcolor 255 128 0 255", "Mutate "$Command$" ", , "text,background,border");
            return true;

        case "TOGGLECMENUBACKGROUND":
            ToggleCMenuBackground();
            return true;

        case "TOGGLECMENUSTAY":
            ToggleCMenuStay();
            return true;

        case "TOGGLECLICKMODE":
            ToggleClickMode();
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
    MenuText.add("Toggle Mouse Click Mode")
    
    MenuCommand.add("SETCMENUCOLOR --text")
    MenuCommand.add("SETCMENUCOLOR --background")
    MenuCommand.add("SETCMENUCOLOR --border")
    MenuCommand.add("TOGGLECMENUBACKGROUND")
    MenuCommand.add("TOGGLECMENUSTAY")
    MenuCommand.add("TOGGLECLICKMODE")
}
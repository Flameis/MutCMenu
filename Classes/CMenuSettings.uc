class CMenuSettings extends CMenu;

function bool CheckExceptions(string Command)
{
    switch (Caps(Command))
    {
        case "SETCMENUTEXTCOLOR":
        case "SETCMENUBGCOLOR":
        case "SETCMENUBORDERCOLOR":
            if(bCMenuDebug) `Log("DropAtGrid");
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr="Mutate "$Command$" ";
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStrPos=Len(LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr); // set the value high in case name is quite long
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.GoToState('Typing');
            LocalPlayer(PC.Player).ViewportClient.ClearProgressMessages();
            LocalPlayer(PC.Player).ViewportClient.SetProgressTime(6);
            MessageSelf("Please Specify a Color in RGBA Format (Example: 255 128 0 255(Optional Transparency) for Orange)");
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
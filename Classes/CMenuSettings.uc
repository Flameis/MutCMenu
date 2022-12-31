class CMenuSettings extends CMenuBase;

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

    MenuText(0)="Set CMenu Text Color"
    MenuText(1)="Set CMenu Background Color"
    MenuText(2)="Set CMenu Border Color"
    MenuText(3)="Toggle CMenu Background"
    MenuText(4)="Toggle CMenu Stay"
    
    MenuCommand(0)="SETCMENUTEXTCOLOR"
    MenuCommand(1)="SETCMENUBGCOLOR"
    MenuCommand(2)="SETCMENUBORDERCOLOR"
    MenuCommand(3)="TOGGLECMENUBACKGROUND"
    MenuCommand(4)="TOGGLECMENUSTAY"
}
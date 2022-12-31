class CMenuParadrops extends CMenuBase;

function bool CheckExceptions(string Command)
{
    switch (Caps(Command))
    {
        case "DROPALLATGRID":
        case "DROPNORTHATGRID":
        case "DROPSOUTHATGRID":
            if(bCMenuDebug) `Log("DropAtGrid");
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr="Mutate "$Command$" ";
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStrPos=Len(LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr); // set the value high in case name is quite long
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.GoToState('Typing');
            LocalPlayer(PC.Player).ViewportClient.ClearProgressMessages();
            LocalPlayer(PC.Player).ViewportClient.SetProgressTime(6);
            MessageSelf("Please Specify a Grid Location (Example: E 5 kp 5)");
            return true;
            
        case "DROPALLATOBJ":
        case "DROPNORTHATOBJ":
        case "DROPSOUTHATOBJ":
            if(bCMenuDebug) `Log("DropAtObj");
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr="Mutate "$Command$" ";
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStrPos=Len(LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr); // set the value high in case name is quite long
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.GoToState('Typing');
            LocalPlayer(PC.Player).ViewportClient.ClearProgressMessages();
            LocalPlayer(PC.Player).ViewportClient.SetProgressTime(6);
            MessageSelf("Please Specify an Objective (Example: A)");
            return true;

        default:
            return false;
    }
}

defaultproperties
{
    

    MenuName="PARADROPS"

    MenuText(0)="Drop All At Obj"
    MenuText(1)="Drop North At Obj"
    MenuText(2)="Drop South At Obj"
    MenuText(3)="Drop All At Grid"
    MenuText(4)="Drop North At Grid"
    MenuText(5)="Drop South At Grid"
    
    MenuCommand(0)="DROPALLATOBJ"
    MenuCommand(1)="DROPNORTHATOBJ"
    MenuCommand(2)="DROPSOUTHATOBJ"
    MenuCommand(3)="DROPALLATGRID"
    MenuCommand(4)="DROPNORTHATGRID"
    MenuCommand(5)="DROPSOUTHATGRID"
}
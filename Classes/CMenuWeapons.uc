class CMenuWeapons extends CMenu;

function bool CheckExceptions(string Command)
{
    switch (Caps(Command))
    {
        case "GIVEWEAPON":
        case "GIVEWEAPONNORTH":
        case "GIVEWEAPONSOUTH":
        case "GIVEWEAPONALL":
            if(bCMenuDebug) `Log("GIVEWEAPON");
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr="Mutate "$Command$" ";
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStrPos=Len(LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr); // set the value high in case name is quite long
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.GoToState('Typing');
            LocalPlayer(PC.Player).ViewportClient.ClearProgressMessages();
            LocalPlayer(PC.Player).ViewportClient.SetProgressTime(6);
            MessageSelf("Please Specify a Weapon (Example: L1A1)");
            return true;

        default:
            return false;
    }
}

defaultproperties
{
    MenuName="WEAPONS"

    MenuText(0)="GIVE WEAPON SELF"
    MenuText(1)="GIVE WEAPON NORTH"
    MenuText(2)="GIVE WEAPON SOUTH"
    MenuText(3)="GIVE WEAPON All"
    MenuText(4)="Clear Weapons From Self"
    MenuText(5)="Clear Weapons From North Team"
    MenuText(6)="Clear Weapons From South Team"
    MenuText(7)="Clear Weapons From All"
    
    MenuCommand(0)="GIVEWEAPON"
    MenuCommand(1)="GIVEWEAPONNORTH"
    MenuCommand(2)="GIVEWEAPONSOUTH"
    MenuCommand(3)="GIVEWEAPONALL"
    MenuCommand(4)="CLEARWEAPONS"
    MenuCommand(5)="CLEARWEAPONSNORTH"
    MenuCommand(6)="CLEARWEAPONSSOUTH"
    MenuCommand(7)="CLEARWEAPONSALL"
}
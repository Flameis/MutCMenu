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

    MenuText(0)="Give Weapon SELF"
    MenuText(1)="Give Weapon NORTH"
    MenuText(2)="Give Weapon SOUTH"
    MenuText(3)="Give Weapon All"
    MenuText(4)="Clear Weapons SELF"
    MenuText(5)="Clear Weapons NORTH"
    MenuText(6)="Clear Weapons SOUTH"
    MenuText(7)="Clear Weapons All"
    
    MenuCommand(0)="GIVEWEAPON"
    MenuCommand(1)="GIVEWEAPONNORTH"
    MenuCommand(2)="GIVEWEAPONSOUTH"
    MenuCommand(3)="GIVEWEAPONALL"
    MenuCommand(4)="CLEARWEAPONS"
    MenuCommand(5)="CLEARWEAPONSNORTH"
    MenuCommand(6)="CLEARWEAPONSSOUTH"
    MenuCommand(7)="CLEARWEAPONSALL"
}
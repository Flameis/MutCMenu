class CMenuWeapons extends CMenu;

function Initialize()
{
    MessageSelf("Welcome to the Weapons Menu, login to scrim admin to see all the options.");

    if (bIsAuthorized)
    {
        MenuText.additem("Give Weapon NORTH");
        MenuText.additem("Give Weapon SOUTH");
        MenuText.additem("Give Weapon All");
        MenuText.additem("Clear Weapons NORTH");
        MenuText.additem("Clear Weapons SOUTH");
        MenuText.additem("Clear Weapons All");
        MenuCommand.additem("GIVEWEAPONNORTH");
        MenuCommand.additem("GIVEWEAPONSOUTH");
        MenuCommand.additem("GIVEWEAPONALL");
        MenuCommand.additem("CLEARWEAPONSNORTH");
        MenuCommand.additem("CLEARWEAPONSSOUTH");
        MenuCommand.additem("CLEARWEAPONSALL");
    }
    Super.Initialize();
}

function bool CheckExceptions(string Command)
{
    local string WeaponPackage, FullWepPath;

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

        case "COPY":
            if (InStr(string(PC.Pawn.Weapon), "RO",,true) != -1)
            {
                WeaponPackage = "ROGameContent.";
            }
            else if (InStr(string(PC.Pawn.Weapon), "GOM",,true) != -1)
            {
                WeaponPackage = "GOM4.";
            }
            else if (InStr(string(PC.Pawn.Weapon), "WW",,true) != -1)
            {
                WeaponPackage = "WinterWar.";
            }
            else if (InStr(string(PC.Pawn.Weapon), "AC",,true) != -1)
            {
                WeaponPackage = "MutExtras.";
            }
            else if (InStr(string(PC.Pawn.Weapon), "GM",,true) != -1)
            {
                WeaponPackage = "GreenMenMod.";
            }
            else if (InStr(string(PC.Pawn.Weapon), "BO",,true) != -1)
            {
                WeaponPackage = "BlackOrchestra.";
            }

            FullWepPath = WeaponPackage $ Repl(string(PC.Pawn.Weapon), Right(string(PC.Pawn.Weapon), 2), "", false);

            MessageSelf("Weapon Copied to Clipboard: " $ FullWepPath);
            PC.CopyToClipboard(FullWepPath);
            return true;
    }
    return false;
}

defaultproperties
{
    MenuName="WEAPONS"

    MenuText.add("Copy Held Weapon To Clipboard")
    MenuText.add("Give Weapon SELF")
    MenuText.add("Clear Weapons SELF")

    MenuCommand.add("COPY")
    MenuCommand.add("GIVEWEAPON")
    MenuCommand.add("CLEARWEAPONS")
}
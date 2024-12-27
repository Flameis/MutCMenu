class CMenuWeapons extends CMenu;

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
                WeaponPackage = "MutExtrasTB.";
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

            MessageSelf("Weapon Copied to ClipboardL: " $ FullWepPath);
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
    MenuText.add("Give Weapon NORTH")
    MenuText.add("Give Weapon SOUTH")
    MenuText.add("Give Weapon All")
    MenuText.add("Clear Weapons SELF")
    MenuText.add("Clear Weapons NORTH")
    MenuText.add("Clear Weapons SOUTH")
    MenuText.add("Clear Weapons All")
    
    MenuCommand.add("COPY")
    MenuCommand.add("GIVEWEAPON")
    MenuCommand.add("GIVEWEAPONNORTH")
    MenuCommand.add("GIVEWEAPONSOUTH")
    MenuCommand.add("GIVEWEAPONALL")
    MenuCommand.add("CLEARWEAPONS")
    MenuCommand.add("CLEARWEAPONSNORTH")
    MenuCommand.add("CLEARWEAPONSSOUTH")
    MenuCommand.add("CLEARWEAPONSALL")
}
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
        MenuCommand.additem("GIVEWEAPON --team north --weapon");
        MenuCommand.additem("GIVEWEAPON --team south --weapon");
        MenuCommand.additem("GIVEWEAPON --team all --weapon");
        MenuCommand.additem("CLEARWEAPONS --team north");
        MenuCommand.additem("CLEARWEAPONS --team south");
        MenuCommand.additem("CLEARWEAPONS --team all");
    }
    Super.Initialize();
}

function bool CheckExceptions(string Command)
{
    local string WeaponPath;
    local array<string> Params;

    Params = SplitString(Command, " ", true);
    switch (Caps(Params[0]))
    {
        case "GIVEWEAPON":
            if(bCMenuDebug) `Log("GIVEWEAPON");
            PromptForText("Give Weapon|--weapon / -w : a short name such as L1A1 or BHP, or a full weapon path (already typed for you, add the weapon)|--team / -t : north, south or all (leave it out to give it to yourself; admins only)|Example: --weapon L1A1   or   --team north --weapon L1A1|Older form: giveweapon L1A1, giveweaponnorth L1A1", "Mutate "$Command$" ");
            return true;

        case "COPY":
            WeaponPath = PC.Pawn.Weapon.Class.Outer.name$"."$PC.Pawn.Weapon.Class.name;
            PC.CopyToClipboard(WeaponPath);

            MessageSelf("Weapon Copied to Clipboard: " $ WeaponPath);
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
    MenuCommand.add("GIVEWEAPON --weapon")
    MenuCommand.add("CLEARWEAPONS")
}
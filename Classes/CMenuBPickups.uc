class CMenuBPickups extends CMenuB;

var class<ROWeapon>          WeaponClass;

function Initialize()
{
    super.Initialize();

    if (InStr(TargetName, "Weap",,true) != -1)
	{
        if (CheckMutsLoaded(TargetName) == false)
            return;
        LastCmd = TargetName;
        WeaponClass = class<ROWeapon>(DynamicLoadObject(LastCmd, class'Class'));
        ReferenceSkeletalMesh[0] = SkeletalMeshComponent(WeaponClass.default.Mesh).SkeletalMesh;
        ModifyLoc.z = 5;
        GoToState('ReadyToPlace',, true);
	}
}

function bool CheckExceptions(string Command)
{
    local string WeaponPackage, FullWepPath;

    switch (Caps(Command))
    {
        case "CUSTOM":
            PromptForText("Please Type Your Desired Weapon (Example: ROGameContent.ROWeap_Owen_SMG_Content)", "mutate CMENU CMenuBPickups to ");
            GoToState('ReadyToPlace',, true);
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
            PC.CopyToClipboard(FullWepPath);
            WeaponClass = class<ROWeapon>(DynamicLoadObject(FullWepPath, class'Class'));
            
            ReferenceSkeletalMesh[0] = SkeletalMeshComponent(WeaponClass.default.Mesh).SkeletalMesh;
            ModifyLoc.z = 5;
            GoToState('ReadyToPlace',, true);
            return true;

        case "CLEARALLPICKUPS":
            MyDA.ClearAllPickups();
            return true;
    }
    return false;
}

function DoPlace()
{
	MyDA.SpawnPickup(WeaponClass, ModifyTime, PlaceLoc, PlaceRot);
}

defaultproperties
{
    MenuName="WEAPON PICKUPS"

    MenuText.add("Custom")
    MenuText.add("Copy Held Weapon")
    MenuText.add("Clear All Pickups")
    
    MenuCommand.add("CUSTOM")
    MenuCommand.add("COPY")
    MenuCommand.add("CLEARALLPICKUPS")
}
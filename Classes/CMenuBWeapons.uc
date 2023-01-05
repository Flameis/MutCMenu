class CMenuBWeapons extends CMenuBBase;

var class<ROWeapon>          WeaponClass;

simulated state MenuVisible
{
	function BeginState(name PreviousStateName)
	{
        super.BeginState(PreviousStateName);

		if (InStr(TargetName, "Weap",,true) != -1)
		{
            LastCmd = TargetName;
            WeaponClass = class<ROWeapon>(DynamicLoadObject(LastCmd, class'Class'));
            ReferenceSkeletalMesh[0] = SkeletalMeshComponent(WeaponClass.default.Mesh).SkeletalMesh;
            ModifyLoc.z = 5;
            GoToState('ReadyToPlace',, true);
		}
	}
}

function bool CheckExceptions(string Command)
{
    if (Command == "CUSTOM")
    {
        LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr="mutate CMENU CMenuBWeapons to ";
        LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStrPos=Len(LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr); // set the value high in case name is quite long
        LocalPlayer(PC.Player).ViewportClient.ViewportConsole.GoToState('Typing');
        LocalPlayer(PC.Player).ViewportClient.ClearProgressMessages();
        LocalPlayer(PC.Player).ViewportClient.SetProgressTime(6);
        MessageSelf("Please Type Your Desired Weapon (Example: ROGameContent.ROWeap_Owen_SMG_Content)");
        GoToState('ReadyToPlace',, true);
        return true;
    }
    else if (Command == "COPY")
    {
        WeaponClass = class<ROWeapon>(DynamicLoadObject("ROGameContent."$Repl(string(PC.Pawn.Weapon), Right(string(PC.Pawn.Weapon), 2), "", false), class'Class'));
        ReferenceSkeletalMesh[0] = SkeletalMeshComponent(WeaponClass.default.Mesh).SkeletalMesh;
        ModifyLoc.z = 5;
        GoToState('ReadyToPlace',, true);
        return true;
    }
    return false;
}

function DoPlace()
{
	MyDA.ServerSpawnPickup(WeaponClass, PlaceLoc, PlaceRot, ModifyTime);
}

defaultproperties
{
    MenuName="WEAPON PICKUPS"

    MenuText(0)="Custom"
    MenuText(1)="Copy Held Weapon"
    
    MenuCommand(0)="CUSTOM"
    MenuCommand(1)="COPY"
}
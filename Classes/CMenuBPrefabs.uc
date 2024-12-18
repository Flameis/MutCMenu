class CMenuBPrefabs extends CMenuB;

function bool CheckExceptions(string Command)
{
	local int i;

	PreviewMeshMIC = new class'MaterialInstanceConstant';
	PreviewMeshMIC.SetParent(MaterialInstanceConstant(PreviewStaticMesh[0].GetMaterial(0)));

	switch (Command)
	{
		case "PFSANDBAGCR":
			for ( i = 1; i < class'CMSMPrefab'.default.PFStaticMeshComponent.Length; i++ )
			{
				PreviewStaticMesh[i] = class'CMSMPrefab'.default.PFStaticMeshComponent[I];

				PreviewStaticMesh[i].SetStaticMesh(class'CMSMPrefab'.default.PFStaticMeshComponent[I].StaticMesh);
				PC.Pawn.AttachComponent(PreviewSkeletalMesh[i]);
				PreviewStaticMesh[i].SetHidden(false);
			}
			break;
	}
    
    GoToState('ReadyToPlace',, true);

    return true;
}

function DoPlace()
{
	MyDA.ServerSpawnActor(class'CMSMPrefab',,'StaticMesh', PlaceLoc, PlaceRot,,, LastCmd);
}

simulated function UpdatePreviewMesh() // Update the postion of the Preview Mesh
{
	local StaticMeshComponent PSM;
	local Vector AbsVDiff;
	local Rotator AbsRDiff;

	AbsVDiff.x = Abs(PC.Location.x - PlaceLoc.x);
	AbsVDiff.y = Abs(PC.Location.y - PlaceLoc.y);
	AbsVDiff.z = Abs(PC.Location.z - PlaceLoc.z);

	AbsRDiff.Pitch = Abs(PC.Rotation.Pitch - PlaceRot.Pitch);
	AbsRDiff.Yaw = Abs(PC.Rotation.Yaw - PlaceRot.Yaw);
	AbsRDiff.Roll = Abs(PC.Rotation.Roll - PlaceRot.Roll);

	foreach PreviewStaticMesh(PSM)
	{
		PSM.SetTranslation(AbsVDiff + PSM.Default.Translation);
		PSM.SetRotation(AbsRDiff + PSM.Default.Rotation);
	}
}

defaultproperties
{
    MenuName="PREFABS"

    MenuText.add("Sandbag Crescent")

    MenuCommand.add("PFSANDBAGCR")
}
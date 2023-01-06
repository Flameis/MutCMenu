class CMenuBMeshes extends CMenuBBase;

simulated state MenuVisible
{
	function BeginState(name PreviousStateName)
	{
        super.BeginState(PreviousStateName);

		if (InStr(TargetName, "_",,true) != -1)
		{
            LastCmd = TargetName;
            if (bPreviewIsSkeletal)
                ReferenceSKeletalMesh[0] = SkeletalMesh(DynamicLoadObject(TargetName, class'SkeletalMesh'));
            else
                ReferenceStaticMesh[0] = StaticMesh(DynamicLoadObject(TargetName, class'StaticMesh'));
            GoToState('ReadyToPlace',, true);
		}
	}
}

function bool CheckExceptions(string Command)
{
	switch (Command)
    {
        case "CUSTOMSM":
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr="mutate CMENU CMenuBSM to ";
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStrPos=Len(LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr); // set the value high in case name is quite long
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.GoToState('Typing');
            LocalPlayer(PC.Player).ViewportClient.ClearProgressMessages();
            LocalPlayer(PC.Player).ViewportClient.SetProgressTime(6);
            MessageSelf("Please Type Your Desired Static Mesh (Example: ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_112uu)");
            GoToState('ReadyToPlace',, true);
            return true;

        case "COPY":
            Command = PathName(StaticMeshActor(TracedActor).StaticMeshComponent.StaticMesh);
            LastCmd = Command;
            if(LastCmd != "None")
            {
                PC.CopyToClipboard(LastCmd);
                MessageSelf("Copied Mesh Name To Clipboard:"@LastCmd);
            }
            else MessageSelf("No Mesh Found");
            break;
    }
    if (InStr(Command, "_",,true) != -1)
    {
        if (bPreviewIsSkeletal)
            ReferenceSKeletalMesh[0] = SkeletalMesh(DynamicLoadObject(Command, class'SkeletalMesh'));
        else
            ReferenceStaticMesh[0] = StaticMesh(DynamicLoadObject(Command, class'StaticMesh'));
        GoToState('ReadyToPlace',, true);
        return true;
    }
	return false;  
}

function DoPlace()
{
	if (InStr(LastCmd, "_",, true) != -1)
	{
		MyDA.ServerSpawnActor(class'CMSM',,'StaticMesh', PlaceLoc, PlaceRot,,, LastCmd, ModifyScale);
	}
}

defaultproperties
{
    MenuName="STATIC MESHES"

    MenuText.add("Custom")
    MenuText.add("Copy Mesh")
    MenuText.add("Sandbags Straight")
    MenuText.add("F4 Phantom")

    MenuCommand.add("CUSTOMSM")
    MenuCommand.add("COPY")
    MenuCommand.add("ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_112uu")
    MenuCommand.add("VH_VN_US_F4Phantom.Mesh.F4_Phantom_SM")
}
class CMenuBMeshes extends CMenuB;

function Initialize()
{
    if (bIsAuthorized)
    {
        MenuText.additem("Clear All Meshes");
        MenuCommand.additem("CLEARALLMESHES");

        MenuText.additem("WARNING Toggle Collision");
        MenuCommand.additem("TOGGLECOLLISION");

        MenuText.additem("WARNING Delete Any Object");
        MenuCommand.additem("ADMINDELETE");
    }

	super.Initialize();
}

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
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr="mutate CMENU CMenuBMeshes to ";
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStrPos=Len(LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr); // set the value high in case name is quite long
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.GoToState('Typing');
            LocalPlayer(PC.Player).ViewportClient.ClearProgressMessages();
            LocalPlayer(PC.Player).ViewportClient.SetProgressTime(6);
            MessageSelf("Please Type Your Desired Static Mesh (Example: ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_112uu)");
            // GoToState('ReadyToPlace',, true);
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

        case "PASTE":
            Command = PC.PasteFromClipboard();
            LastCmd = Command;
            if (bPreviewIsSkeletal)
                ReferenceSKeletalMesh[0] = SkeletalMesh(DynamicLoadObject(LastCmd, class'SkeletalMesh'));
            else
                ReferenceStaticMesh[0] = StaticMesh(DynamicLoadObject(LastCmd, class'StaticMesh'));
            if (ReferenceStaticMesh[0] != None || ReferenceSKeletalMesh[0] != None)
                GoToState('ReadyToPlace',, true);
            else
                MessageSelf("No Mesh Name In Clipboard");
            break;

        case "DELETE":
            MyDA.DeleteActor(CMSM(TraceActors()));
            break;

        case "CLEARALLMESHES":
            ClearAllMeshes();
            break;

        case "TOGGLECOLLISION":
            MyDA.SetActorCollision(TraceActors());
            break;

        case "ADMINDELETE":
            MyDA.DeleteActor(TraceActors());
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
		MyDA.ServerSpawnActor(class'CMSM',,'StaticMesh', PlaceLoc, PlaceRot,, true, LastCmd, ModifyScale.x);
	}
}

function ClearAllMeshes()
{
    local CMSM MeshToClear;

    foreach MyDA.AllActors(class'CMSM', MeshToClear)
    {
        MeshToClear.Destroy();
    }
    `log("All static meshes have been cleared.");
}

defaultproperties
{
    MenuName="STATIC MESHES"

    MenuText.add("Copy Mesh")
    MenuText.add("Paste Mesh")
    MenuText.add("Delete Mesh")
    MenuText.add("Sandbags Straight")
    MenuText.add("F4 Phantom")

    MenuCommand.add("COPY")
    MenuCommand.add("PASTE")
    MenuCommand.add("DELETE")
    MenuCommand.add("ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_112uu")
    MenuCommand.add("VH_VN_US_F4Phantom.Mesh.F4_Phantom_SM")
}
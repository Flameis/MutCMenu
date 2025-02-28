class CMenuBMeshes extends CMenuB;

function Initialize()
{
    if (bIsAuthorized)
    {
        MenuText.additem("Clear All Meshes");
        MenuCommand.additem("CLEARCMAStaticMesh");

        MenuText.additem("WARNING Toggle Collision");
        MenuCommand.additem("TOGGLECOLLISION");

        MenuText.additem("WARNING Delete Any Object");
        MenuCommand.additem("ADMINDELETE");
    }

    if (InStr(TargetName, "_",,true) != -1)
	{
        LastCmd = TargetName;
        if (bPreviewIsSkeletal)
            ReferenceSKeletalMesh[0] = SkeletalMesh(DynamicLoadObject(TargetName, class'SkeletalMesh'));
        else
            ReferenceStaticMesh[0] = StaticMesh(DynamicLoadObject(TargetName, class'StaticMesh'));
        GoToState('ReadyToPlace',, true);
	}

	super.Initialize();
}

function bool CheckExceptions(string Command)
{
	switch (Command)
    {
        case "COPY":
            CopyMesh();
            break;

        case "PASTE":
            PasteMesh();
            break;

        case "DELETE":
            MyDA.DeleteActor(CMAStaticMesh(TraceActors()));
            break;

        case "CLEARCMAStaticMesh":
            GoToState('MenuVisible',, true);
            MyDA.ClearAllMeshes();
            MessageSelf("All meshes have been cleared.");
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

function CopyMesh()
{
    if (StaticMeshActor(TracedActor) != none)
    {
        LastCmd = PathName(StaticMeshActor(TracedActor).StaticMeshComponent.StaticMesh);
        if(LastCmd != "None")
        {
            PC.CopyToClipboard(LastCmd);
            MessageSelf("Copied Mesh Name To Clipboard:"@LastCmd);
        }
        else MessageSelf("No Mesh Found");
    }
    else if (CMAStaticMesh(TracedActor) != none)
    {
        LastCmd = PathName(CMAStaticMesh(TracedActor).StaticMeshComponent.StaticMesh);
        if(LastCmd != "None")
        {
            PC.CopyToClipboard(LastCmd);
            MessageSelf("Copied Mesh Name To Clipboard:"@LastCmd);
        }
        else MessageSelf("No Mesh Found");
    }
    else MessageSelf("No Mesh Found");
}

function PasteMesh()
{
    LastCmd = PC.PasteFromClipboard();
    if (bPreviewIsSkeletal)
        ReferenceSKeletalMesh[0] = SkeletalMesh(DynamicLoadObject(LastCmd, class'SkeletalMesh'));
    else
        ReferenceStaticMesh[0] = StaticMesh(DynamicLoadObject(LastCmd, class'StaticMesh'));
    if (ReferenceStaticMesh[0] != None || ReferenceSKeletalMesh[0] != None)
        GoToState('ReadyToPlace',, true);
    else
        MessageSelf("No Mesh Name In Clipboard");
}

function DoPlace()
{
	if (InStr(LastCmd, "_",, true) != -1)
	{
        MyDA.SpawnActor(class'CMAStaticMesh',,'StaticMesh', PlaceLoc, PlaceRot,, true, LastCmd, ModifyScale.x, ModifyTime*10);
	}
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
class CMenuBMeshes extends CMenuB;

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

        case "DELETE":
            MyDA.DeleteActor(TraceActors());
            break;

        case "COLLISION":
            MyDA.SetActorCollision(TraceActors());
            break;

        case "COPYSTRUCT":
            CopyStructure();
            break;

        case "PASTESTRUCT":
            PasteStructure();
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

function string ParseStaticMesh(string Data)
{
    local string Mesh;
    Mesh = SplitString(SplitString(Data, "&")[0], "=")[1];
    if (Mesh == "") {
        `log("StaticMesh Parsing Failed for Data: " $ Data);
    }
    return Mesh;
}

function vector ParseVector(string Data)
{
    local vector Vec;
    local array<string> VecData;

    `log("ParseVector Input Data: " $ Data);
    VecData = SplitString(SplitString(SplitString(Data, "&")[1], "=")[1], ",");

    if (VecData.Length == 3)
    {
        Vec.X = float(VecData[0]);
        Vec.Y = float(VecData[1]);
        Vec.Z = float(VecData[2]);
    }
    else
    {
        `log("ParseVector Failed - Incorrect VecData Length: " $ VecData.Length);
    }

    return Vec;
}

function rotator ParseRotator(string Data)
{
    local rotator Rota;
    local array<string> RotData;

    `log("ParseRotator Input Data: " $ Data);
    RotData = SplitString(SplitString(SplitString(Data, "&")[2], "=")[1], ",");

    if (RotData.Length == 3)
    {
        Rota.Pitch = float(RotData[0]);
        Rota.Yaw = float(RotData[1]);
        Rota.Roll = float(RotData[2]);
    }
    else
    {
        `log("ParseRotator Failed - Incorrect RotData Length: " $ RotData.Length);
    }

    return Rota;
}

function array<StaticMeshActor> RecursiveCopyMesh(StaticMeshActor RecursedActor, optional int MaxDepth, optional float MaxDistance, optional array<StaticMeshActor> ProcessedActors)
{
    local array<StaticMeshActor> NearbyActors, NewActors;
    local StaticMeshActor Actor;

    // Default parameters
    if (MaxDepth == 0) { MaxDepth = 6; }
    if (MaxDistance == 0) { MaxDistance = 400; }

    // Termination conditions
    if (MaxDepth <= 0 || RecursedActor == None || RecursedActor.IsPendingKill() || ProcessedActors.Length > 50) {
        return NearbyActors;
    }

    // Avoid reprocessing the same actor
    if (ProcessedActors.Find(RecursedActor) != -1) {
        return NearbyActors;
    }
    ProcessedActors.AddItem(RecursedActor);

    // On the first run, add the original actor
    if (ProcessedActors.Length == 1) {
        NearbyActors.AddItem(RecursedActor);
    }

    foreach RecursedActor.CollidingActors(class'StaticMeshActor', Actor, MaxDistance,, True) {
        if (Actor != None && !Actor.IsPendingKill() &&
            Actor.StaticMeshComponent.StaticMesh != None &&
            VSize(Actor.Location - ProcessedActors[0].Location) < MaxDistance &&
            ProcessedActors.Find(Actor) == -1) {

            NearbyActors.AddItem(Actor);
            NewActors = RecursiveCopyMesh(Actor, MaxDepth - 1, MaxDistance, ProcessedActors);

            foreach NewActors(Actor) {
                if (NearbyActors.Find(Actor) == -1) {
                    NearbyActors.AddItem(Actor);
                }
            }
        }
    }

    return NearbyActors;
}

function array<StaticMeshActor> CopyStructureSimple()
{
    local StaticMeshActor Actor;
    local array<StaticMeshActor> NearbyActors;

    if (StaticMeshActor(TracedActor) != none)
    {
        NearbyActors.AddItem(StaticMeshActor(TracedActor));

        foreach TracedActor.CollidingActors(class'StaticMeshActor', Actor, 500,, True)
        {
            if (Actor != none && Actor.StaticMeshComponent.StaticMesh != none)
            {
                NearbyActors.AddItem(Actor);
            }
        }
    }
    return NearbyActors;
}

function CopyStructure()
{
    local array<StaticMeshActor> NearbyActors;
    local string StructureData;
    local vector Origin;
    local rotator Rotation;
    local int i;

    // NearbyActors = RecursiveCopyMesh(StaticMeshActor(TracedActor));
    NearbyActors = CopyStructureSimple();

    // Get the origin and rotation of the first actor
    if (NearbyActors.Length > 0)
    {
        Origin = NearbyActors[0].Location;
        Rotation = NearbyActors[0].Rotation;
    }

    for (i = 0; i < NearbyActors.Length; i++)
    {
        if (NearbyActors[i] != none)
        {
            StructureData $= "StaticMesh=" $ PathName(NearbyActors[i].StaticMeshComponent.StaticMesh) $ "&Translation=" $ (NearbyActors[i].Location - Origin) $ "&Rotation=" $ (NearbyActors[i].Rotation) $ ";";
        }
    }
    
    PC.CopyToClipboard(StructureData);
    MessageSelf("Copied Structure To Clipboard");
}

function PasteStructure(optional string StructureData)
{
    local string ClipboardData;
    local array<string> MeshData, MeshLine, MeshLine2;
    local string Line;
    local int i;
    local string Mesh;
    local vector Vec, PlaceLocNew;
    local rotator Rota, BaseRotation;
    local array<string> VecData;
    local array<string> RotData;

    if (StructureData != "") {
        ClipboardData = StructureData;
    } else {
        ClipboardData = PC.PasteFromClipboard();
    }
    MeshData = SplitString(ClipboardData, ";", True);

    for (i = 0; i < MeshData.Length; i++)
    {
        `log("MeshData: " $ MeshData[i]);

        MeshLine = SplitString(MeshData[i], "&");
        foreach MeshLine(Line) {
            `log("MeshLine: " $ Line);
        }

        // Parse StaticMesh
        MeshLine2 = SplitString(MeshLine[0], "=");
        Mesh = MeshLine2[1];
        if (MeshLine2[1] == "") {
            `log("StaticMesh Parsing Failed for Data: " $ MeshData[i]);
        }

        // Parse Vector (position)
        MeshLine2 = SplitString(MeshLine[1], "=");
        VecData = SplitString(MeshLine2[1], ",");
        if (VecData.Length == 3)
        {
            Vec.X = float(VecData[0]);
            Vec.Y = float(VecData[1]);
            Vec.Z = float(VecData[2]);
        }
        else
        {
            `log("ParseVector Failed - Incorrect VecData Length: " $ VecData.Length);
        }

        // Parse Rotator (rotation)
        MeshLine2 = SplitString(MeshLine[2], "=");
        RotData = SplitString(MeshLine2[1], ",");
        if (RotData.Length == 3)
        {
            Rota.Pitch = float(RotData[0]);
            Rota.Yaw = float(RotData[1]);
            Rota.Roll = float(RotData[2]);
        }
        else
        {
            `log("ParseRotator Failed - Incorrect RotData Length: " $ RotData.Length);
        }

        // Adjust PlaceLoc based on original mesh's relative position
        PlaceLocNew = PlaceLoc + Vec;

        // Spawn actor with calculated location and rotation
        `log("NewMesh: " $ Mesh);
        `log("Translation: " $ Vec);
        `log("Rotation: " $ Rota);

        MyDA.ServerSpawnActor(class'CMSM',,'StaticMesh', PlaceLocNew, Rota,,, Mesh, ModifyScale);
        `log ("Spawned: " $ Mesh);
        `log ("Location: " $ PlaceLoc);
    }
}


defaultproperties
{
    MenuName="STATIC MESHES"

    MenuText.add("Custom")
    MenuText.add("Copy Mesh")
    MenuText.add("Copy Structure")
    MenuText.add("Paste Structure")
    MenuText.add("Delete Actor")
    MenuText.add("Toggle Collision")
    MenuText.add("Sandbags Straight")
    MenuText.add("F4 Phantom")

    MenuCommand.add("CUSTOMSM")
    MenuCommand.add("COPY")
    MenuCommand.add("COPYSTRUCT")
    MenuCommand.add("PASTESTRUCT")
    MenuCommand.add("DELETE")
    MenuCommand.add("COLLISION")
    MenuCommand.add("ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_112uu")
    MenuCommand.add("VH_VN_US_F4Phantom.Mesh.F4_Phantom_SM")
}
class CMenuBPrefabs extends CMenuB;

var array<Vector> VecArray;
var array<Rotator> RotArray;
var array<Vector> OriginalVecArray;
var array<Rotator> OriginalRotArray;
var array<StaticMeshActor> SelectedActors;
var array<MaterialInterface> OriginalMaterials;

function bool CheckExceptions(string Command)
{
	local int i;

	PreviewMeshMIC = new class'MaterialInstanceConstant';
	PreviewMeshMIC.SetParent(MaterialInstanceConstant(PreviewStaticMesh[0].GetMaterial(0)));

	switch (Command)
	{
		case "PFSANDBAGCR":
            GarbageCollection();
			for ( i = 1; i < class'CMSMPrefab'.default.PFStaticMeshComponent.Length; i++ )
			{
				PreviewStaticMesh[i] = class'CMSMPrefab'.default.PFStaticMeshComponent[I];

				PreviewStaticMesh[i].SetStaticMesh(class'CMSMPrefab'.default.PFStaticMeshComponent[I].StaticMesh);
				PC.Pawn.AttachComponent(PreviewStaticMesh[i]);
				PreviewStaticMesh[i].SetHidden(false);
			}
    		GoToState('ReadyToPlace',, true);
			return true;

		case "COPYSTRUCT":
            CopyStructure();
            break;

        case "PASTESTRUCT":
            PasteStructure();
            GoToState('ReadyToPlace',, true);
            return true;

        case "CLEARCMSM":
            ClearAllCMSM();
            return true;

        case "SELECTMESH":
            SelectMesh();
            return true;

        case "STOPSELECT":
            CopySelectedMeshesToClipboard();
            return true;

        case "REMOVESELECTED":
            RemoveLastSelectedMesh();
            return true;

        case "CLEARSELECTED":
            ClearSelectedMeshes();
            return true;
	}
    return false;
}

function DoPlace()
{
	local string Mesh;
	local int i;

	if (LastCmd == "PFSANDBAGCR")
	{
		MyDA.ServerSpawnActor(class'CMSMPrefab',,'StaticMesh', PlaceLoc, PlaceRot,,, LastCmd);
	}
	else
	{
		for ( i = 0; i < PreviewStaticMesh.Length; i++ )
		{
			Mesh = PathName(PreviewStaticMesh[i].StaticMesh);

			// Ensure the mesh is valid before attempting to spawn
			if (Mesh != "None")
			{
				// Remove or adjust collision checks here
				MyDA.ServerSpawnActor(class'CMSM',,'StaticMesh', PreviewStaticMesh[i].GetPosition(), PreviewStaticMesh[i].GetRotation(),, true, Mesh, ModifyScale);

				`log("NewMesh: " $ Mesh);
				`log("Translation: " $ VecArray[i]);
				`log("Rotation: " $ RotArray[i]);
			}
			else
			{
				`log("Warning: Invalid mesh at index " $ i);
			}
		}
	}
}

function GarbageCollection()
{
    local StaticMeshComponent PSM;

    foreach PreviewStaticMesh(PSM)
    {
        PSM.SetHidden(true);
        PC.Pawn.DetachComponent(PSM);
    }
    PreviewStaticMesh.Remove(0, PreviewStaticMesh.Length);
    VecArray.Remove(0, VecArray.Length);
    RotArray.Remove(0, RotArray.Length);
    OriginalVecArray.Remove(0, OriginalVecArray.Length);
    OriginalRotArray.Remove(0, OriginalRotArray.Length);

    SelectedActors.Remove(0, SelectedActors.Length);
    OriginalMaterials.Remove(0, OriginalMaterials.Length);
}

function ClearAllCMSM()
{
    local CMSM ActorToClear;

    foreach MyDA.AllActors(class'CMSM', ActorToClear)
    {
        ActorToClear.Destroy();
    }
    `log("All CMSM actors have been cleared.");
}

simulated function UpdatePreviewMesh() // Update the position of the Preview Mesh
{
    local StaticMeshComponent PSM;
    local Vector /* DiffVector,  */TranslatedVec, Origin;
    local Rotator /* DiffRotator,  */TranslatedRot, OriginRot;
    local int i;

    // Calculate the difference between the player's current location/rotation and the desired preview location/rotation
    // DiffVector = PC.Location - PlaceLoc;

    if (LastCmd == "PFSANDBAGCR")
    {
        foreach PreviewStaticMesh(PSM)
        {
            PSM.SetTranslation(PlaceLoc + PSM.Default.Translation);
            PSM.SetRotation(PlaceRot + PSM.Default.Rotation);
        }
    }
    else
    {
        if (PreviewStaticMesh.Length > 0)
        {
            Origin = VecArray[0];
            OriginRot = RotArray[0];
        }

        for ( i = 0; i < PreviewStaticMesh.Length; i++ )
        {
            // Translate and rotate each mesh based on the first mesh's position and rotation
            TranslatedVec = Origin + (VecArray[i] - Origin) >> ModifyRot;
            TranslatedRot = OriginRot + RotArray[i] + ModifyRot;

            PreviewStaticMesh[i].SetTranslation(TranslatedVec + PlaceLoc);
            PreviewStaticMesh[i].SetRotation(TranslatedRot);
            PreviewStaticMesh[i].SetScale(ModifyScale);

            // VecArray[i] = OriginalVecArray[i] + DiffVector;
            // RotArray[i].Yaw = OriginalRotArray[i].Yaw + PlaceRot.yaw;
        }
    }
}

function array<StaticMeshActor> CopyStructureSimple()
{
    local StaticMeshActor Actor;
    local array<StaticMeshActor> NearbyActors;

    if (StaticMeshActor(TracedActor) != none)
    {
        NearbyActors.AddItem(StaticMeshActor(TracedActor));

        foreach TracedActor.CollidingActors(class'StaticMeshActor', Actor, 250,, True)
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
    local vector Origin, RelativeLocation;
    local rotator OriginRot, RelativeRotation;
    local int i;

    // NearbyActors = RecursiveCopyMesh(StaticMeshActor(TracedActor));
    NearbyActors = CopyStructureSimple();

    // Get the origin and rotation of the first actor
    if (NearbyActors.Length > 0)
    {
        Origin = NearbyActors[0].Location;
        OriginRot = NearbyActors[0].Rotation;
    }

    for (i = 0; i < NearbyActors.Length; i++)
    {
        if (NearbyActors[i] != none)
        {
            // Adjust the translation and rotation based on the origin's rotation
            RelativeLocation = NearbyActors[i].Location - Origin;
            RelativeRotation = NearbyActors[i].Rotation - OriginRot;

            // RelativeLocation = RelativeLocation >> OriginRot;
            // RelativeRotation = RelativeRotation >> OriginRot;

            StructureData $= "StaticMesh=" $ PathName(NearbyActors[i].StaticMeshComponent.StaticMesh) $ "&Translation=" $ RelativeLocation $ "&Rotation=" $ RelativeRotation $ ";";
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
    local vector Vec;
    local rotator Rota;
    local array<string> VecData;
    local array<string> RotData;
    local StaticMeshComponent PreviewComponent;

    if (StructureData != "") {
        ClipboardData = StructureData;
    } else {
        ClipboardData = PC.PasteFromClipboard();
    }
    MeshData = SplitString(ClipboardData, ";", True);

	GarbageCollection();

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
            continue;
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
            continue;
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
            continue;
        }

        // Adjust PlaceLoc based on original mesh's relative position
        VecArray.AddItem(Vec);
        RotArray.AddItem(Rota);

        // Create and show preview
        PreviewComponent = new class'StaticMeshComponent';
        PreviewComponent.SetStaticMesh(StaticMesh(DynamicLoadObject(Mesh, class'StaticMesh')));
		PreviewComponent.SetScale(ModifyScale > 0.0 ? ModifyScale : 1.0);
        PreviewComponent.SetActorCollision(false, false);
   		PreviewComponent.SetNotifyRigidBodyCollision(false);
    	PreviewComponent.SetTraceBlocking(false, false);
        PreviewComponent.SetAbsolute(true, true, true);
        // PreviewComponent.SetMaterial(0, PreviewMeshMIC);
        // PreviewComponent.SetMaterial(1, PreviewMeshMIC);
        // PreviewComponent.SetMaterial(2, PreviewMeshMIC);
        // PreviewComponent.SetMaterial(3, PreviewMeshMIC);
        // PreviewComponent.SetMaterial(4, PreviewMeshMIC);
        // PreviewComponent.SetMaterial(5, PreviewMeshMIC);
		PC.Pawn.AttachComponent(PreviewComponent);
        PreviewComponent.SetHidden(false);
        
        PreviewStaticMesh.AddItem(PreviewComponent);
    }
}

function SelectMesh()
{
    local StaticMeshActor SelectedActor;
    local int i;

    SelectedActor = StaticMeshActor(TracedActor);
    if (SelectedActor != none)
    {
        SelectedActors.AddItem(SelectedActor);
        for (i = 0; i < SelectedActor.StaticMeshComponent.Materials.Length; i++)
        {
            OriginalMaterials.AddItem(SelectedActor.StaticMeshComponent.GetMaterial(i));
            SelectedActor.StaticMeshComponent.SetMaterial(i, PreviewMeshMIC);
        }
        SelectedActor.StaticMeshComponent.ForceUpdate(false);
        MessageSelf("Selected Mesh: " $ PathName(SelectedActor.StaticMeshComponent.StaticMesh));
    }
    else
    {
        MessageSelf("No Mesh Found");
    }
}

function ClearSelectedMeshes()
{
    local StaticMeshActor SelectedActor;
    local int i, j;

    for (i = 0; i < SelectedActors.Length; i++)
    {
        SelectedActor = SelectedActors[i];
        for (j = 0; j < SelectedActor.StaticMeshComponent.Materials.Length; j++)
        {
            SelectedActor.StaticMeshComponent.SetMaterial(j, OriginalMaterials[i * SelectedActor.StaticMeshComponent.Materials.Length + j]);
        }
        SelectedActor.StaticMeshComponent.ForceUpdate(false);
    }
    MessageSelf("Cleared Selected Meshes");

    GarbageCollection();
}

function RemoveLastSelectedMesh()
{
    local StaticMeshActor SelectedActor;
    local int i;

    if (SelectedActors.Length > 0)
    {
        SelectedActor = SelectedActors[SelectedActors.Length - 1];
        for (i = 0; i < SelectedActor.StaticMeshComponent.Materials.Length; i++)
        {
            SelectedActor.StaticMeshComponent.SetMaterial(i, OriginalMaterials[(SelectedActors.Length - 1) * SelectedActor.StaticMeshComponent.Materials.Length + i]);
        }
        SelectedActor.StaticMeshComponent.ForceUpdate(false);
        SelectedActors.Remove(SelectedActors.Length - 1, 1);
        OriginalMaterials.Remove(OriginalMaterials.Length - SelectedActor.StaticMeshComponent.Materials.Length, SelectedActor.StaticMeshComponent.Materials.Length);
        MessageSelf("Removed Last Selected Mesh");
    }
    else
    {
        MessageSelf("No Meshes Selected");
    }
}

function CopySelectedMeshesToClipboard()
{
    local string StructureData;
    local vector Origin;
    local int i;

    if (SelectedActors.Length > 0)
    {
        Origin = SelectedActors[0].Location;
    }

    for (i = 0; i < SelectedActors.Length; i++)
    {
        if (SelectedActors[i] != none)
        {
            StructureData $= "StaticMesh=" $ PathName(SelectedActors[i].StaticMeshComponent.StaticMesh) $ "&Translation=" $ (SelectedActors[i].Location - Origin) $ "&Rotation=" $ (SelectedActors[i].Rotation) $ ";";
        }
    }

    PC.CopyToClipboard(StructureData);
    MessageSelf("Copied Selected Meshes To Clipboard");
    ClearSelectedMeshes();
}

defaultproperties
{
    MenuName="PREFABS"

	MenuText.add("Copy Structure")
    MenuText.add("Paste Structure")
    MenuText.add("Clear All")
    MenuText.add("Sandbag Crescent")
    MenuText.add("Select Mesh")
    MenuText.add("Stop Selecting")
    MenuText.add("Remove Last Selected")
    MenuText.add("Clear Selected")

	MenuCommand.add("COPYSTRUCT")
    MenuCommand.add("PASTESTRUCT")
    MenuCommand.add("CLEARCMSM")
    MenuCommand.add("PFSANDBAGCR")
    MenuCommand.add("SELECTMESH")
    MenuCommand.add("STOPSELECT")
    MenuCommand.add("REMOVESELECTED")
    MenuCommand.add("CLEARSELECTED")
}
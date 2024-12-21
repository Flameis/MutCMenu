class CMenuBStructures extends CMenuB;

var array<Vector> VecArray;
var array<Rotator> RotArray;
var array<StaticMeshActor> SelectedActors;
var array<MaterialInterface> OriginalMaterials;

function bool CheckExceptions(string Command)
{
	local int i;

    LastCmd = Command;

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
            GarbageCollection();
            GoToState('ReadyToPlace',, true);
            return true;

        case "PASTESTRUCT":
            // Enter the desired radius
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

    `log("DoPlace called. PreviewStaticMesh length: " $ PreviewStaticMesh.Length);
	if (LastCmd == "PFSANDBAGCR")
	{
		MyDA.ServerSpawnActor(class'CMSMPrefab',,'StaticMesh', PlaceLoc, PlaceRot,,, LastCmd);
	}
	else if (LastCmd == "COPYSTRUCT")
    {
        CopyStructure();
    }
    else
	{
		for ( i = 0; i < PreviewStaticMesh.Length; i++ )
		{
			// Ensure the mesh is valid before attempting to spawn
			if (PreviewStaticMesh[i] != none)
			{
                `log("PreviewStaticMesh[i].StaticMesh: " $ PreviewStaticMesh[i].StaticMesh);
			    Mesh = PathName(PreviewStaticMesh[i].StaticMesh);
                if (Mesh == "None")
                {
                    // Try again
                    Mesh = PathName(PreviewStaticMesh[i].StaticMesh);
                }
				// Remove or adjust collision checks here
				MyDA.ServerSpawnActor(class'CMSM',,'StaticMesh', PreviewStaticMesh[i].GetPosition(), PreviewStaticMesh[i].GetRotation(),, true, Mesh, ModifyScale.x);

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

    `log("GarbageCollection called. Clearing PreviewStaticMesh.");
    foreach PreviewStaticMesh(PSM)
    {
        PSM.SetHidden(true);
        PC.Pawn.DetachComponent(PSM);
    }
    PreviewStaticMesh.Remove(0, PreviewStaticMesh.Length);
    VecArray.Remove(0, VecArray.Length);
    RotArray.Remove(0, RotArray.Length);
    // OriginalVecArray.Remove(0, OriginalVecArray.Length);
    // OriginalRotArray.Remove(0, OriginalRotArray.Length);

    SelectedActors.Remove(0, SelectedActors.Length);
    OriginalMaterials.Remove(0, OriginalMaterials.Length);
    `log("GarbageCollection completed. PreviewStaticMesh length: " $ PreviewStaticMesh.Length);
}

function ClearAllCMSM()
{
    local CMSM ActorToClear;

    GarbageCollection();

    foreach MyDA.AllActors(class'CMSM', ActorToClear)
    {
        ActorToClear.Destroy();
    }
    `log("All CMSM actors have been cleared.");
}

simulated function UpdatePreviewMesh() // Update the position of the Preview Mesh
{
    local StaticMeshComponent PSM;
    local Vector TranslatedVec;
    local Rotator TranslatedRot, OriginRot;
    local int i;

    if (LastCmd == "PFSANDBAGCR")
    {
        foreach PreviewStaticMesh(PSM)
        {
            PSM.SetTranslation(PlaceLoc + PSM.Default.Translation);
            PSM.SetRotation(PlaceRot + PSM.Default.Rotation);
        }
    }
    else if (LastCmd == "COPYSTRUCT")
    {
        MyDA.DrawDebugSphere(PlaceLoc, ModifyScale.X * 250, 50, 0, 0, 255, false);
    }
    else
    {
        if (PreviewStaticMesh.Length > 0)
        {
            OriginRot = RotArray[0];
        }

        for ( i = 0; i < PreviewStaticMesh.Length; i++ )
        {
            if (i == 0)
            {
                TranslatedRot = OriginRot + ModifyRot;

                PreviewStaticMesh[i].SetTranslation(PlaceLoc);
                PreviewStaticMesh[i].SetRotation(TranslatedRot);
                PreviewStaticMesh[i].SetScale3D(ModifyScale);
            }
            else 
            {
                // Translate and rotate each mesh based on the first mesh's position and rotation
                TranslatedVec = VecArray[i] >> ModifyRot;
                TranslatedRot = OriginRot + RotArray[i] + ModifyRot;

                PreviewStaticMesh[i].SetTranslation(TranslatedVec + PlaceLoc);
                PreviewStaticMesh[i].SetRotation(TranslatedRot);
                PreviewStaticMesh[i].SetScale3D(ModifyScale);

                // VecArray[i] = OriginalVecArray[i] + DiffVector;
                // RotArray[i].Yaw = OriginalRotArray[i].Yaw + PlaceRot.yaw;
            }
        }
    }
}

function CopyStructure()
{
    local array<StaticMeshActor> NearbyActors;
    local StaticMeshActor Actor;
    local string StructureData;
    local vector Origin, RelativeLocation;
    local rotator OriginRot;
    local vector RelativeScale;
    local int i;

    foreach MyDA.VisibleActors(class'StaticMeshActor', Actor, ModifyScale.x*250, PlaceLoc, /* True */)
    {
        if (Actor != none && Actor.StaticMeshComponent.StaticMesh != none)
        {
            NearbyActors.AddItem(Actor);
        }
    }

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
            RelativeLocation = RelativeLocation >> OriginRot;

            // Calculate the relative scale based on the bounds
            RelativeScale = NearbyActors[i].StaticMeshComponent.Bounds.BoxExtent;

            StructureData $= "StaticMesh=" $ PathName(NearbyActors[i].StaticMeshComponent.StaticMesh) $ "&Translation=" $ RelativeLocation $ "&Rotation=" $ NearbyActors[i].Rotation $ "&Scale=" $ RelativeScale $ ";";
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
    local vector Vec, Scale;
    local rotator Rota;
    local array<string> VecData, RotData, ScaleData;
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
        `log ("Mesh: " $ Mesh);
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

        // Parse Scale
        MeshLine2 = SplitString(MeshLine[3], "=");
        ScaleData = SplitString(MeshLine2[1], ",");
        if (ScaleData.Length == 3)
        {
            Scale.X = float(ScaleData[0]);
            Scale.Y = float(ScaleData[1]);
            Scale.Z = float(ScaleData[2]);
        }
        else
        {
            `log("ParseScale Failed - Incorrect ScaleData Length: " $ ScaleData.Length);
            continue;
        }

        // Adjust PlaceLoc based on original mesh's relative position
        VecArray.AddItem(Vec);
        RotArray.AddItem(Rota);

        // Create and show preview
        PreviewComponent = new class'StaticMeshComponent';
        PreviewComponent.SetStaticMesh(StaticMesh(DynamicLoadObject(Mesh, class'StaticMesh')));
        // Calculate what the scale should be based on the bounds of the preview vs the bounds of the original
        Scale.X = Scale.X / PreviewComponent.Bounds.BoxExtent.X;
        Scale.Y = Scale.Y / PreviewComponent.Bounds.BoxExtent.Y;
        Scale.Z = Scale.Z / PreviewComponent.Bounds.BoxExtent.Z;
        PreviewComponent.SetScale3D(Scale);
        PreviewComponent.SetActorCollision(false, false);
   		PreviewComponent.SetNotifyRigidBodyCollision(false);
    	PreviewComponent.SetTraceBlocking(false, false);
        PreviewComponent.SetAbsolute(true, true, true);
        PreviewComponent.CastShadow = false;
        // PreviewComponent.SetMaterial(0, PreviewMeshMIC);
        // PreviewComponent.SetMaterial(1, PreviewMeshMIC);
        // PreviewComponent.SetMaterial(2, PreviewMeshMIC);
        // PreviewComponent.SetMaterial(3, PreviewMeshMIC);
        // PreviewComponent.SetMaterial(4, PreviewMeshMIC);
        // PreviewComponent.SetMaterial(5, PreviewMeshMIC);
		PC.Pawn.AttachComponent(PreviewComponent);
        PreviewComponent.SetHidden(false);

        PreviewStaticMesh.AddItem(PreviewComponent);
        
        `log("PreviewComponent: " $ PreviewComponent);
        `log("PreviewComponent.StaticMesh: " $ PreviewStaticMesh[i].StaticMesh);
    }
}

function SelectMesh()
{
    local StaticMeshActor SelectedActor;
    local int i;

    SelectedActor = StaticMeshActor(TracedActor);
    if (SelectedActor != none)
    {
        // Check if the mesh is already selected
        for (i = 0; i < SelectedActors.Length; i++)
        {
            if (SelectedActors[i] == SelectedActor)
            {
                MessageSelf("Mesh already selected: " $ PathName(SelectedActor.StaticMeshComponent.StaticMesh));
                return;
            }
        }

        if (SelectedActors.Length == 0)
        {
            SelectedActors[0] = SelectedActor;
            OriginalMaterials[0] = SelectedActor.StaticMeshComponent.GetMaterial(0);
        }
        else
        {
            SelectedActors.AddItem(SelectedActor);
            OriginalMaterials.AddItem(SelectedActor.StaticMeshComponent.GetMaterial(0));
        }

        SelectedActor.StaticMeshComponent.SetMaterial(0, Material'NodeBuddies.Materials.NodeBuddy_White1');

        /* for (i = 0; i < SelectedActor.StaticMeshComponent.Materials.Length; i++)
        {
            `log("SelectedActor.StaticMeshComponent.GetMaterial(i): " $ SelectedActor.StaticMeshComponent.GetMaterial(i));
            OriginalMaterials.AddItem(SelectedActor.StaticMeshComponent.GetMaterial(i));
            SelectedActor.StaticMeshComponent.SetMaterial(i, Material'NodeBuddies.Materials.NodeBuddy_White1');
        } */
        // SelectedActor.StaticMeshComponent.ForceUpdate(false);
        MessageSelf("Selected Mesh: " $ PathName(SelectedActors[SelectedActors.Length - 1].StaticMeshComponent.StaticMesh));
    }
    else
    {
        MessageSelf("No Mesh Found");
    }
}

function CopySelectedMeshesToClipboard()
{
    local string StructureData;
    local vector Origin, RelativeLocation, RelativeScale;
    local rotator OriginRot;
    local int i;

    // Get the origin and rotation of the first actor
    if (SelectedActors.Length > 0)
    {
        Origin = SelectedActors[0].Location;
        OriginRot = SelectedActors[0].Rotation;
    }

    for (i = 0; i < SelectedActors.Length; i++)
    {
        `log("SelectedActors[i]: " $ SelectedActors[i]);
        if (SelectedActors[i] != none)
        {
            // Adjust the translation and rotation based on the origin's rotation
            RelativeLocation = SelectedActors[i].Location - Origin;
            RelativeLocation = RelativeLocation >> OriginRot;

            // Calculate the relative scale based on the bounds
            RelativeScale = SelectedActors[i].StaticMeshComponent.Bounds.BoxExtent;

            StructureData $= "StaticMesh=" $ PathName(SelectedActors[i].StaticMeshComponent.StaticMesh) $ "&Translation=" $ RelativeLocation $ "&Rotation=" $ SelectedActors[i].Rotation $ "&Scale=" $ RelativeScale $ ";";
        }
    }

    PC.CopyToClipboard(StructureData);
    MessageSelf("Copied Selected Meshes To Clipboard");
    ClearSelectedMeshes();
}

function ClearSelectedMeshes()
{
    local StaticMeshActor SelectedActor;
    local int i;

    for (i = 0; i < SelectedActors.Length; i++)
    {
        SelectedActor = SelectedActors[i];
        SelectedActor.StaticMeshComponent.SetMaterial(0, OriginalMaterials[i]);
        OriginalMaterials.RemoveItem(SelectedActor.StaticMeshComponent.GetMaterial(0));
        /* for (j = 0; j < SelectedActor.StaticMeshComponent.Materials.Length; j++)
        {
            SelectedActor.StaticMeshComponent.SetMaterial(j, OriginalMaterials[i * SelectedActor.StaticMeshComponent.Materials.Length + j]);
        } */
        SelectedActor.StaticMeshComponent.ForceUpdate(false);
    }
    MessageSelf("Cleared Selected Meshes");

    GarbageCollection();
}

function RemoveLastSelectedMesh()
{
    local StaticMeshActor SelectedActor;
    // local int i;

    if (SelectedActors.Length > 0)
    {
        SelectedActor = SelectedActors[SelectedActors.Length - 1];
        SelectedActor.StaticMeshComponent.SetMaterial(0, OriginalMaterials[SelectedActors.Length - 1]);
        /* for (i = 0; i < SelectedActor.StaticMeshComponent.Materials.Length; i++)
        {
            SelectedActor.StaticMeshComponent.SetMaterial(i, OriginalMaterials[(SelectedActors.Length - 1) * SelectedActor.StaticMeshComponent.Materials.Length + i]);
        } */
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

defaultproperties
{
    MenuName="STRUCTURES"

    MenuText.add("Select Mesh")
    MenuText.add("Confirm Selection")
    MenuText.add("Remove Last Selected")
    MenuText.add("Clear Selected")
    MenuText.add("Paste Selection")
	MenuText.add("Copy Structure")
    MenuText.add("Clear All")
    // MenuText.add("Sandbag Crescent")

    MenuCommand.add("SELECTMESH")
    MenuCommand.add("STOPSELECT")
    MenuCommand.add("REMOVESELECTED")
    MenuCommand.add("CLEARSELECTED")
    MenuCommand.add("PASTESTRUCT")
	MenuCommand.add("COPYSTRUCT")
    MenuCommand.add("CLEARCMSM")
    // MenuCommand.add("PFSANDBAGCR")
}
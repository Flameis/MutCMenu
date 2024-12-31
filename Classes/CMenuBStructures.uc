class CMenuBStructures extends CMenuB;

var array<Vector> VecArray;
var array<Rotator> RotArray;
var array<StaticMeshActor> SelectedActors;
var array<MaterialInterface> OriginalMaterials;

simulated state menuVisible
{
    function EndState(name PreviousStateName)
    {
        MenuText.Remove(default.MenuCommand.Length, MenuText.Length-default.MenuCommand.Length);
        MenuCommand.Remove(default.MenuCommand.Length, MenuCommand.Length-default.MenuCommand.Length);
    }
}

function Initialize()
{
    if (bIsAuthorized)
    {
        MenuText.additem("Clear All Meshes");
        MenuCommand.additem("CLEARCMAStaticMesh");
    }

	super.Initialize();
}

simulated state ReadyToPlace
{
    // Overwritten
	function BeginState(name PreviousStateName)
	{
        ModifyRot = rot(0,0,0);
		ModifyScale = vect(1,1,1);
		ModifyTime = 0;
	}
}

function bool CheckExceptions(string Command)
{
    LastCmd = Command;

	PreviewMeshMIC = new class'MaterialInstanceConstant';
	PreviewMeshMIC.SetParent(MaterialInstanceConstant(PreviewStaticMesh[0].GetMaterial(0)));
	switch (Command)
	{
		case "COPYSTRUCT":
            ClearSelectedMeshes();
            GarbageCollection();
            GoToState('ReadyToPlace',, true);
            return true;

        case "PASTESTRUCT":
            GoToState('MenuVisible',, true);
            GarbageCollection();
            ClearSelectedMeshes();
            PasteStructure();
            GoToState('ReadyToPlace',, true);
            return true;

        case "CLEARCMAStaticMesh": 
            GarbageCollection();
            ClearSelectedMeshes();
            MyDA.ClearAllMeshes();
	        MessageSelf("All meshes have been cleared.");
            return true;

        case "SELECTMESH":
            if (IsInState('ReadyToPlace') == true)
                GoToState('MenuVisible',, true);
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
            GarbageCollection();
            MessageSelf("Cleared Selected Meshes");
            return true;
	}
    return false;
}

function DoPlace()
{
	local string Mesh;
	local int i;

    `log("DoPlace called. PreviewStaticMesh length: " $ PreviewStaticMesh.Length);

    if (LastCmd == "COPYSTRUCT")
    {
        CopyStructure();
        GoToState('MenuVisible',, true);
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
				// MyDA.SpawnActor(class'CMAStaticMesh',,'StaticMesh', PreviewStaticMesh[i].GetPosition(), PreviewStaticMesh[i].GetRotation(),, true, Mesh, ModifyScale.x);
                MyDA.SpawnActor(class'CMAStaticMesh',,'StaticMesh', PreviewStaticMesh[i].GetPosition(), PreviewStaticMesh[i].GetRotation(),, true, Mesh, ModifyScale.x, ModifyTime*10);

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
    `log("GarbageCollection completed. PreviewStaticMesh length: " $ PreviewStaticMesh.Length);
}

simulated function UpdatePreviewMesh() // Update the position of the Preview Mesh
{
    local Vector TranslatedVec;
    local Rotator TranslatedRot, OriginRot;
    local int i;

    if (LastCmd == "COPYSTRUCT")
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
            // Translate and rotate each mesh based on the first mesh's position and rotation
            TranslatedVec = VecArray[i] >> ModifyRot;
            TranslatedRot = OriginRot + RotArray[i] + ModifyRot;
            
            PreviewStaticMesh[i].SetTranslation(TranslatedVec + PlaceLoc);
            PreviewStaticMesh[i].SetRotation(TranslatedRot);
            PreviewStaticMesh[i].SetScale3D(ModifyScale);
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

    ClearSelectedMeshes();

    /* if (StaticMeshActor(TracedActor) != none)
    {
        NearbyActors.AddItem(StaticMeshActor(TracedActor));

        foreach TracedActor.CollidingActors(class'StaticMeshActor', Actor, ModifyScale.x*250,, True)
        {
            if (Actor != none && Actor.StaticMeshComponent.StaticMesh != none)
            {
                NearbyActors.AddItem(Actor);
            }
        }
    } */
    foreach MyDA.OverlappingActors(class'StaticMeshActor', Actor, ModifyScale.x*250, PlaceLoc)
    {
        `log("Actor: " $ Actor);
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

    for (i = 0; i < MeshData.Length; i++)
    {
        // `log("MeshData: " $ MeshData[i]);

        MeshLine = SplitString(MeshData[i], "&");
        foreach MeshLine(Line) {
            // `log("MeshLine: " $ Line);
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

        // 
        PreviewComponent.SetScale3D(Scale);
        PreviewComponent.SetActorCollision(false, false);
   		PreviewComponent.SetNotifyRigidBodyCollision(false);
    	PreviewComponent.SetTraceBlocking(false, false);
        PreviewComponent.SetAbsolute(true, true, true);
        PreviewComponent.CastShadow = false;

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
        // Check if the mesh is already selected
        for (i = 0; i < SelectedActors.Length; i++)
        {
            if (SelectedActors[i] == SelectedActor)
            {
                MessageSelf("Mesh already selected: " $ PathName(SelectedActor.StaticMeshComponent.StaticMesh));
                return;
            }
        }

        SelectedActors.AddItem(SelectedActor);
        OriginalMaterials.AddItem(SelectedActor.StaticMeshComponent.GetMaterial(0));
        `log(OriginalMaterials[OriginalMaterials.Length]);

        SelectedActor.StaticMeshComponent.SetMaterial(0, Material'NodeBuddies.Materials.NodeBuddy_White1');

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
    }

    SelectedActors.Remove(0, SelectedActors.Length);
    OriginalMaterials.Remove(0, OriginalMaterials.Length);
}

function RemoveLastSelectedMesh()
{
    local StaticMeshActor SelectedActor;
    // local int i;

    if (SelectedActors.Length > 0)
    {
        SelectedActor = SelectedActors[SelectedActors.Length - 1];
        SelectedActor.StaticMeshComponent.SetMaterial(0, OriginalMaterials[SelectedActors.Length - 1]);

        SelectedActors.Remove(SelectedActors.Length - 1, 1);
        OriginalMaterials.Remove(SelectedActors.Length - 1, 1);
        
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

    MenuCommand.add("SELECTMESH")
    MenuCommand.add("STOPSELECT")
    MenuCommand.add("REMOVESELECTED")
    MenuCommand.add("CLEARSELECTED")
    MenuCommand.add("PASTESTRUCT")
	MenuCommand.add("COPYSTRUCT")

    PreviewStaticMesh.Remove(PreviewStaticMeshComponent)
}
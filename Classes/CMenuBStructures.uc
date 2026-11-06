// The Builder's Structures menu: copy meshes (an area, or a selection) to the clipboard and paste them somewhere else.
// A copy keeps every piece relative to the first one, in that piece's facing: its offset, its own turn (relative to the
// first, as a quaternion so pitch and roll come out right) and its real scale. A paste builds the structure again with the
// first piece where you aim, facing the way you look (C turns it), and the mouse wheel making the whole thing bigger or
// smaller. Copies made before this format (which stored the wrong offsets, rotations and scales) are refused.
class CMenuBStructures extends CMenuB;

// The clipboard format: a header, then one piece per entry
const FORMAT_HEADER = "CMS2";

var array<Vector> VecArray;    // each pasted piece's offset from the first, in the first piece's facing
var array<Rotator> RotArray;   // and its turn relative to the first piece
var array<Vector> ScaleArray;  // and its own scale
var array<Actor> SelectedActors;
var array<MaterialInterface> OriginalMaterials;
var MaterialInstanceConstant SelectedLook; // a selected mesh is drawn with this (the placeable item look, in green)

function Initialize()
{
    MessageSelf("Welcome to the Structures Menu, login to scrim admin to see all the options.");

    if (bIsAuthorized)
    {
        MenuText.additem("Clear All Meshes");
        MenuCommand.additem("CLEARMESH");
    }

	super.Initialize();
}

// Overridden to allow for our own logic when pasting
function InitializePreview()
{
}

function bool CheckExceptions(string Command)
{
    LastCmd = Command;

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
            if (PasteStructure() > 0)
                GoToState('ReadyToPlace',, true);
            return true;

        case "CLEARMESH":
            GarbageCollection();
            ClearSelectedMeshes();
            MyDA.ClearAllMeshes();
            return true;

        case "SELECTMESH":
            if (IsInState('ReadyToPlace') == true)
                GoToState('MenuVisible',, true);
            SelectMesh();
            return true;

        case "COPYSELECT":
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

// ====================================================
// Placing a pasted structure
// ====================================================

// The way the pasted structure faces: where the player looks, turned by C (yaw only, so it stands level)
function rotator PasteFacing()
{
    local rotator R;

    R.Yaw = PlaceRot.Yaw;
    return R;
}

// Where piece i goes, how it is turned and how big it is
function PieceTransform(int i, out vector Loc, out rotator Rot, out vector Scale)
{
    local rotator Facing;

    Facing = PasteFacing();
    Loc = PlaceLoc + ((VecArray[i] * ModifyScale.X) >> Facing);
    Rot = QuatToRotator(QuatProduct(QuatFromRotator(Facing), QuatFromRotator(RotArray[i])));
    Scale = ScaleArray[i] * ModifyScale.X;
}

function DoPlace()
{
    local vector Loc, Scale;
    local rotator Rot;
	local int i;

    if (LastCmd == "COPYSTRUCT")
    {
        CopyStructure();
        GoToState('MenuVisible',, true);
        return;
    }

	for (i = 0; i < PreviewStaticMesh.Length; i++)
	{
		if (PreviewStaticMesh[i] == none || PreviewStaticMesh[i].StaticMesh == None)
			continue;
        PieceTransform(i, Loc, Rot, Scale);
        MyDA.SpawnActor(class'CMAStaticMesh',, 'StaticMesh', Loc, Rot,, true, PathName(PreviewStaticMesh[i].StaticMesh), 1.0, PieceHealth, Scale);
	}
}

function GarbageCollection()
{
    local StaticMeshComponent PSM;
    local Actor Host;

    Host = (PreviewHost != None) ? PreviewHost : GetPreviewHost();

    foreach PreviewStaticMesh(PSM)
    {
        PSM.SetHidden(true);
        if (Host != None)
            Host.DetachComponent(PSM);
    }
    PreviewStaticMesh.Remove(0, PreviewStaticMesh.Length);
    VecArray.Remove(0, VecArray.Length);
    RotArray.Remove(0, RotArray.Length);
    ScaleArray.Remove(0, ScaleArray.Length);
}

simulated function UpdatePreviewMesh() // Update the position of the Preview Mesh
{
    local vector Loc, Scale;
    local rotator Rot;
    local int i;

    if (LastCmd == "COPYSTRUCT")
    {
        MyDA.DrawDebugSphere(PlaceLoc, CopyRadius(), 50, 0, 0, 255, false);
        return;
    }

    for (i = 0; i < PreviewStaticMesh.Length; i++)
    {
        PieceTransform(i, Loc, Rot, Scale);
        PreviewStaticMesh[i].SetTranslation(Loc);
        PreviewStaticMesh[i].SetRotation(Rot);
        PreviewStaticMesh[i].SetScale3D(Scale);
    }
    PreviewLook().SetVectorParameterValue('color', CantPlaceWhy == "" ? GoodPlacementColour : BadPlacementColour);
}

// ====================================================
// Copying
// ====================================================

// Copy Area takes everything within this of where the player aims (5 meters, bigger or smaller with the mouse wheel)
function float CopyRadius()
{
    return ModifyScale.X * 250;
}

// A mesh's whole scale: the actor's and the mesh component's, both kinds
static function vector MeshScale(Actor A, StaticMeshComponent C)
{
    return A.DrawScale3D * A.DrawScale * C.Scale3D * C.Scale;
}

static function StaticMeshComponent MeshOf(Actor A)
{
    if (StaticMeshActor(A) != None)
        return StaticMeshActor(A).StaticMeshComponent;
    if (CMAStaticMesh(A) != None)
        return CMAStaticMesh(A).StaticMeshComponent;
    return None;
}

// The clipboard text for these meshes, the first one being where the others are measured from
static function string StructureText(array<Actor> Meshes)
{
    local string Data;
    local vector Origin, Offset, Scale;
    local rotator Facing, Turn;
    local StaticMeshComponent C;
    local int i;

    if (Meshes.Length == 0)
        return "";
    Origin = Meshes[0].Location;
    Facing.Yaw = Meshes[0].Rotation.Yaw;

    Data = FORMAT_HEADER$";";
    for (i = 0; i < Meshes.Length; i++)
    {
        C = MeshOf(Meshes[i]);
        if (C == None || C.StaticMesh == None)
            continue;
        // Into the first piece's facing: offsets with <<, turns relative to it
        Offset = (Meshes[i].Location - Origin) << Facing;
        Turn = QuatToRotator(QuatProduct(QuatInvert(QuatFromRotator(Facing)), QuatFromRotator(Meshes[i].Rotation)));
        Scale = MeshScale(Meshes[i], C);
        Data $= "StaticMesh=" $ PathName(C.StaticMesh) $ "&Translation=" $ Offset $ "&Rotation=" $ Turn $ "&Scale=" $ Scale $ ";";
    }
    return Data;
}

function CopyStructure()
{
    local array<Actor> Meshes;
    local StaticMeshActor SMA;
    local CMAStaticMesh CMA;

    ClearSelectedMeshes();

    // The map's own meshes first, then Builder pieces, as before
    foreach MyDA.OverlappingActors(class'StaticMeshActor', SMA, CopyRadius(), PlaceLoc)
    {
        if (SMA.StaticMeshComponent.StaticMesh != none)
            Meshes.AddItem(SMA);
    }
    foreach MyDA.OverlappingActors(class'CMAStaticMesh', CMA, CopyRadius(), PlaceLoc)
    {
        if (CMA.StaticMeshComponent.StaticMesh != none)
            Meshes.AddItem(CMA);
    }

    if (Meshes.Length == 0)
    {
        MessageSelf("No meshes within "$int(CopyRadius() / 50)$" meters to copy.");
        return;
    }
    PC.CopyToClipboard(StructureText(Meshes));
    MessageSelf("Copied "$Meshes.Length$" mesh"$(Meshes.Length == 1 ? "" : "es")$" within "$int(CopyRadius() / 50)$" meters to the clipboard.");
}

function CopySelectedMeshesToClipboard()
{
    if (SelectedActors.Length == 0)
    {
        MessageSelf("No Meshes Selected");
        return;
    }
    PC.CopyToClipboard(StructureText(SelectedActors));
    MessageSelf("Copied "$SelectedActors.Length$" selected mesh"$(SelectedActors.Length == 1 ? "" : "es")$" to the clipboard.");
}

// ====================================================
// Pasting
// ====================================================

static function bool ParseVector(string Text, out vector V)
{
    local array<string> P;

    P = SplitString(Text, ",");
    if (P.Length != 3)
        return false;
    V.X = float(P[0]);
    V.Y = float(P[1]);
    V.Z = float(P[2]);
    return true;
}

static function bool ParseRotator(string Text, out rotator R)
{
    local array<string> P;

    P = SplitString(Text, ",");
    if (P.Length != 3)
        return false;
    R.Pitch = int(P[0]);
    R.Yaw = int(P[1]);
    R.Roll = int(P[2]);
    return true;
}

// Reads one piece ("StaticMesh=...&Translation=...&Rotation=...&Scale=..."); false when it can't be read
static function bool ParsePiece(string Entry, out string Mesh, out vector Offset, out rotator Turn, out vector Scale)
{
    local array<string> Fields, KV;
    local int i;
    local bool bMesh, bOffset, bTurn, bScale;

    Fields = SplitString(Entry, "&");
    for (i = 0; i < Fields.Length; i++)
    {
        KV = SplitString(Fields[i], "=");
        if (KV.Length != 2)
            continue;
        // (A switch on the field's name never matched here, so plain comparisons)
        if (KV[0] ~= "StaticMesh")
        {
            Mesh = KV[1];
            bMesh = Mesh != "";
        }
        else if (KV[0] ~= "Translation")
            bOffset = ParseVector(KV[1], Offset);
        else if (KV[0] ~= "Rotation")
            bTurn = ParseRotator(KV[1], Turn);
        else if (KV[0] ~= "Scale")
            bScale = ParseVector(KV[1], Scale);
    }
    return bMesh && bOffset && bTurn && bScale;
}

// Builds the previews from the clipboard (or StructureData); returns how many pieces it read
function int PasteStructure(optional string StructureData)
{
    local string ClipboardData, Mesh;
    local array<string> Entries;
    local int i;
    local vector Offset, Scale;
    local rotator Turn;
    local StaticMesh SM;
    local StaticMeshComponent PreviewComponent;
    local int Missing;

    ClipboardData = (StructureData != "") ? StructureData : PC.PasteFromClipboard();
    Entries = SplitString(ClipboardData, ";", True);
    if (Entries.Length == 0 || Entries[0] != FORMAT_HEADER)
    {
        MessageSelf("The clipboard has no structure in it. (Structures copied before this version can't be pasted: copy them again.)");
        return 0;
    }

    for (i = 1; i < Entries.Length; i++)
    {
        if (!ParsePiece(Entries[i], Mesh, Offset, Turn, Scale))
            continue;
        SM = StaticMesh(DynamicLoadObject(Mesh, class'StaticMesh', true));
        if (SM == None)
        {
            Missing++;
            continue;
        }

        VecArray.AddItem(Offset);
        RotArray.AddItem(Turn);
        ScaleArray.AddItem(Scale);

        PreviewComponent = new class'StaticMeshComponent';
        PreviewComponent.SetStaticMesh(SM);
        PreviewComponent.SetActorCollision(false, false);
        PreviewComponent.SetNotifyRigidBodyCollision(false);
        PreviewComponent.SetTraceBlocking(false, false);
        PreviewComponent.SetAbsolute(true, true, true);
        PreviewComponent.CastShadow = false;
        SetPlaceableLook(PreviewComponent);
        PreviewStaticMesh.AddItem(PreviewComponent);
    }

    if (PreviewStaticMesh.Length == 0)
        MessageSelf("Nothing in the clipboard's structure could be loaded.");
    else
        MessageSelf("Pasting "$PreviewStaticMesh.Length$" mesh"$(PreviewStaticMesh.Length == 1 ? "" : "es")
            $(Missing > 0 ? " ("$Missing$" left out: this game doesn't have them)" : "")$". Click to place, C turns it, the mouse wheel sizes it.");
    return PreviewStaticMesh.Length;
}

// The green placeable look on every part of a pasted preview, so it can't be mistaken for the real thing
function SetPlaceableLook(StaticMeshComponent C)
{
    local int i;

    for (i = 0; i < Max(C.GetNumElements(), 1); i++)
        C.SetMaterial(i, PreviewLook());
}

function MaterialInstanceConstant GetSelectedLook()
{
    if (SelectedLook == None)
    {
        SelectedLook = new class'MaterialInstanceConstant';
        SelectedLook.SetParent(PlaceableMaterial);
        SelectedLook.SetVectorParameterValue('color', GoodPlacementColour);
    }
    return SelectedLook;
}

// ====================================================
// Selecting
// ====================================================

function SelectMesh()
{
    local StaticMeshComponent C;
    local int i;

    C = MeshOf(TracedActor);
    if (C == None)
    {
        MessageSelf("No Mesh Found");
        return;
    }
    for (i = 0; i < SelectedActors.Length; i++)
    {
        if (SelectedActors[i] == TracedActor)
        {
            MessageSelf("Mesh already selected: " $ PathName(C.StaticMesh));
            return;
        }
    }

    SelectedActors.AddItem(TracedActor);
    OriginalMaterials.AddItem(C.GetMaterial(0));
    C.SetMaterial(0, GetSelectedLook());
    MessageSelf("Selected Mesh: " $ PathName(C.StaticMesh));
}

// Each selected mesh gets back the material it had. (Entries used to be removed from the list while it was being read,
// so the wrong materials went back on the meshes after the first.)
function ClearSelectedMeshes()
{
    local int i;

    for (i = 0; i < SelectedActors.Length && i < OriginalMaterials.Length; i++)
        RestoreMaterial(SelectedActors[i], OriginalMaterials[i]);

    SelectedActors.Remove(0, SelectedActors.Length);
    OriginalMaterials.Remove(0, OriginalMaterials.Length);
}

function RestoreMaterial(Actor SelectedActor, MaterialInterface Original)
{
    if (MeshOf(SelectedActor) != None)
        MeshOf(SelectedActor).SetMaterial(0, Original);
}

function RemoveLastSelectedMesh()
{
    local int Last;

    if (SelectedActors.Length > 0)
    {
        // The same entry from both lists (the material list used to lose the one before it)
        Last = SelectedActors.Length - 1;
        if (Last < OriginalMaterials.Length)
        {
            RestoreMaterial(SelectedActors[Last], OriginalMaterials[Last]);
            OriginalMaterials.Remove(Last, 1);
        }
        SelectedActors.Remove(Last, 1);

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

    // The placeable item material, which is in the shipped game (the editor's highlight material may not be)
    bUsesHealth=true

    MenuText.add("Select Mesh")
    MenuText.add("Copy Selection To Clipboard")
    MenuText.add("Remove Last Selected")
    MenuText.add("Clear Selected")
    MenuText.add("Paste Clipboard Structure")
	MenuText.add("Copy Area To Clipboard")

    MenuCommand.add("SELECTMESH")
    MenuCommand.add("COPYSELECT")
    MenuCommand.add("REMOVESELECTED")
    MenuCommand.add("CLEARSELECTED")
    MenuCommand.add("PASTESTRUCT")
	MenuCommand.add("COPYSTRUCT")

    PreviewStaticMesh.Remove(PreviewStaticMeshComponent)
}

// The Builder's Static Meshes menu: the catalogue's pieces by category (Sandbags, Barbed Wire, ...), and copying,
// pasting and deleting a single mesh. The catalogue is the built-in one (CMBuilderCatalogue) or the server's own.
class CMenuBMeshes extends CMenuB
    dependson(CMBuilderCatalogue);

var string CurrentCategory; // the catalogue category on show; "" for the menu's first page
var bool bOpenCategory;     // set just before the menu is opened again to show CurrentCategory

function Initialize()
{
    local array<BuilderPiece> List;
    local array<string> Categories;
    local string Category;
    local int i;

    if (!bOpenCategory)
        CurrentCategory = "";
    bOpenCategory = false;
    if (MyDA != None)
        MyDA.GetBuilderPieces(List);

    // A category: its pieces
    if (CurrentCategory != "")
    {
        MenuName = Caps(CurrentCategory);
        MenuText.Length = 0;
        MenuCommand.Length = 0;
        for (i = 0; i < List.Length; i++)
        {
            if (List[i].Category ~= CurrentCategory)
            {
                MenuText.AddItem(List[i].Label);
                MenuCommand.AddItem("PIECE "$List[i].Mesh);
            }
        }
        super.Initialize();
        return;
    }

    MenuName = default.MenuName;
    MessageSelf("Welcome to the Static Meshes Menu, login to scrim admin to see all the options.");

    class'CMBuilderCatalogue'.static.GetCategories(List, Categories);
    foreach Categories(Category)
    {
        MenuText.AddItem(Category);
        MenuCommand.AddItem("CATEGORY "$Category);
    }

    if (bIsAuthorized)
    {
        MenuText.additem("Clear All Meshes");
        MenuCommand.additem("CLEARCMAStaticMesh");

        MenuText.additem("Toggle Collision (Builder Pieces)");
        MenuCommand.additem("TOGGLECOLLISION");

        MenuText.additem("Delete Any Placed Object");
        MenuCommand.additem("ADMINDELETE");
    }

    if (InStr(TargetName, "_",,true) != -1)
	{
        LastCmd = TargetName;
        if (bPreviewIsSkeletal)
            ReferenceSKeletalMesh[0] = SkeletalMesh(DynamicLoadObject(TargetName, class'SkeletalMesh'));
        else
            ReferenceStaticMesh[0] = StaticMesh(DynamicLoadObject(TargetName, class'StaticMesh'));
        PieceHealth = 0;
        GoToState('ReadyToPlace',, true);
	}

	super.Initialize();
}

// A category line opens that category in this menu, and 0 in a category goes back to the categories (the menu stays
// open either way)
function bool SelectLine(int NumKey)
{
    local int Line;

    if (CurrentCategory != "" && NumKey == 0 && MenuPage == 0)
    {
        ShowCategory("");
        return true;
    }
    Line = NumKey - 1 + MenuPage * ITEMS_PER_PAGE;
    if (NumKey >= 1 && NumKey <= ITEMS_PER_PAGE && Line < MenuCommand.Length && Left(MenuCommand[Line], 9) ~= "CATEGORY ")
    {
        ShowCategory(Mid(MenuCommand[Line], 9));
        return true;
    }
    return super.SelectLine(NumKey);
}

function ShowCategory(string Category)
{
    CurrentCategory = Category;
    bOpenCategory = (Category != "");
    TargetName = "";
    GoToState('MenuVisible',, true);
}

// A catalogue piece: its preview, starting with the health the catalogue gives it
function SelectPiece(string Mesh)
{
    local array<BuilderPiece> List;
    local int i;

    ReferenceSkeletalMesh[0] = None;
    bPreviewIsSkeletal = false;
    ReferenceStaticMesh[0] = StaticMesh(DynamicLoadObject(Mesh, class'StaticMesh', true));
    if (ReferenceStaticMesh[0] == None)
    {
        MessageSelf("This game has no mesh called "$Mesh$".");
        return;
    }
    LastCmd = Mesh;
    MyDA.GetBuilderPieces(List);
    i = class'CMBuilderCatalogue'.static.FindMesh(List, Mesh);
    PieceHealth = (i != INDEX_NONE) ? Max(List[i].Health, 0) : 0;
    GoToState('ReadyToPlace',, true);
}

function bool CheckExceptions(string Command)
{
    if (Left(Command, 6) ~= "PIECE ")
    {
        SelectPiece(Mid(Command, 6));
        return true;
    }

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
        PieceHealth = 0;
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
    {
        PieceHealth = 0;
        GoToState('ReadyToPlace',, true);
    }
    else
        MessageSelf("No Mesh Name In Clipboard");
}

// Red also when a soldier stands where it would go: it would trap them (the server refuses it too)
function string WhyCantPlace()
{
    local string Why;
    local Pawn P;

    Why = super.WhyCantPlace();
    if (Why != "" || bPreviewIsSkeletal || PreviewStaticMesh[0] == None || PreviewStaticMesh[0].StaticMesh == None || PC == None)
        return Why;
    foreach PC.WorldInfo.AllPawns(class'Pawn', P, PlaceLoc, PreviewStaticMesh[0].Bounds.SphereRadius + 300)
    {
        if (class'DummyActor'.static.PawnInPiece(PC, P, PreviewStaticMesh[0]))
            return "A soldier is in the way.";
    }
    return "";
}

function DoPlace()
{
	if (InStr(LastCmd, "_",, true) != -1)
	{
        MyDA.SpawnActor(class'CMAStaticMesh',,'StaticMesh', PlaceLoc, PlaceRot,, true, LastCmd, ModifyScale.x, PieceHealth);
        RememberPlacedPiece();
	}
}

defaultproperties
{
    MenuName="STATIC MESHES"
    bUsesHealth=true
    bCanChain=true

    MenuText.add("Copy Mesh")
    MenuText.add("Paste Mesh")
    MenuText.add("Delete Mesh")

    MenuCommand.add("COPY")
    MenuCommand.add("PASTE")
    MenuCommand.add("DELETE")
}

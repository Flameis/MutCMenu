// The Builder's catalogue: the pieces the Static Meshes menu offers, by category. The built-in list below uses meshes
// every Rising Storm 2 install has. A server can replace it with its own (BuilderCatalogue lines in
// MutCMenu_Server.ini); each player's game is sent that list when they join (DummyActor.ClientAddCataloguePiece).
class CMBuilderCatalogue extends Object;

struct BuilderPiece
{
    var string Category;    // the list it is in on the Static Meshes menu
    var string Label;       // its name on that list
    var string Mesh;        // the mesh's full path (package.group.name)
    var int Cost;           // build points it takes from the team (with team budgets on)
    var int Health;         // damage it takes before it is destroyed; 0: it can't be destroyed
};

var array<BuilderPiece> Pieces;

const MAX_PIECES = 120; // the most a server's list may have (each is sent to every player when they join)

// The piece with this mesh, or -1
static function int FindMesh(const out array<BuilderPiece> List, string Mesh)
{
    local int i;

    for (i = 0; i < List.Length; i++)
    {
        if (List[i].Mesh ~= Mesh)
            return i;
    }
    return -1;
}

// The categories, in the order they first appear
static function GetCategories(const out array<BuilderPiece> List, out array<string> Categories)
{
    local int i;

    Categories.Length = 0;
    for (i = 0; i < List.Length; i++)
    {
        if (List[i].Category != "" && Categories.Find(List[i].Category) == INDEX_NONE)
            Categories.AddItem(List[i].Category);
    }
}

defaultproperties
{
    Pieces.Add((Category="Sandbags",Label="Sandbag Wall",Mesh="ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_112uu",Cost=2))
    Pieces.Add((Category="Sandbags",Label="Sandbag Wall (Rough)",Mesh="ENV_VN_Sandbags.Mesh.S_ENV_Sandbags2_112uu",Cost=2))
    Pieces.Add((Category="Sandbags",Label="Sandbag Wall, Low",Mesh="ENV_VN_Sandbags.Mesh.S_ENV_Sandbags3_112uu",Cost=1))
    Pieces.Add((Category="Sandbags",Label="Sandbag Corner, Left",Mesh="ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_112uu_90deg_left",Cost=2))
    Pieces.Add((Category="Sandbags",Label="Sandbag Corner, Right",Mesh="ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_112uu_90deg_right",Cost=2))
    Pieces.Add((Category="Sandbags",Label="Sandbag Curve",Mesh="ENV_VN_Sandbags.Mesh.Sand_Bag_128UU_Curve",Cost=3))
    Pieces.Add((Category="Sandbags",Label="Sandbag Wall, Wide",Mesh="ENV_VN_Sandbags.Mesh.SandBags_128UU_Wide",Cost=2))
    Pieces.Add((Category="Sandbags",Label="Sandbag Wall, Wide and Long",Mesh="ENV_VN_Sandbags.Mesh.Sand_Bag_256UU_Wide",Cost=4))
    Pieces.Add((Category="Sandbags",Label="Sandbag Pyramid, Low",Mesh="ENV_VN_Sandbags.Mesh.SandBags_Pyramid_128UU_Wide",Cost=1))
    Pieces.Add((Category="Sandbags",Label="Sandbag Pile",Mesh="ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_2x2x2",Cost=1))

    Pieces.Add((Category="Barbed Wire",Label="Wire Fence",Mesh="ENV_VN_Barbwire.Meshes.S_VN_barbwire_fence_tile_1",Cost=1))
    Pieces.Add((Category="Barbed Wire",Label="Wire Fence, Long",Mesh="ENV_VN_Barbwire.Meshes.S_VN_barbwire_fence_tile_2",Cost=2))
    Pieces.Add((Category="Barbed Wire",Label="Wire Fence with Posts",Mesh="ENV_VN_Barbwire.Meshes.S_VN_Barbwire_fence",Cost=2))
    Pieces.Add((Category="Barbed Wire",Label="Wire Coil",Mesh="ENV_VN_Barbwire.Meshes.S_VN_Barbwire_Round",Cost=2))
    Pieces.Add((Category="Barbed Wire",Label="Wire Coil, Tall",Mesh="ENV_VN_Barbwire.Meshes.S_VN_Barbwire_Round_alt",Cost=3))
    Pieces.Add((Category="Barbed Wire",Label="Wire Post",Mesh="ENV_VN_Barbwire.Meshes.S_VN_Barbwire_Pole",Cost=1))

    Pieces.Add((Category="Bunkers",Label="Sandbag Bunker Wall, Long",Mesh="ENV_VN_Bunker.Mesh.S_ENV_Sandbag_Bunker_Long",Cost=4))
    Pieces.Add((Category="Bunkers",Label="Sandbag Bunker Wall, Short",Mesh="ENV_VN_Bunker.Mesh.S_ENV_Sandbag_Bunker_Short",Cost=2))
    Pieces.Add((Category="Bunkers",Label="Metal Matting",Mesh="ENV_VN_Bunker.Mesh.S_Metal_Matting",Cost=1))
    Pieces.Add((Category="Bunkers",Label="Bunker Roof",Mesh="ENV_VN_Wood_Bunker.Meshes.Extras.S_BunkerRoof_Cover_sml",Cost=4))
    Pieces.Add((Category="Bunkers",Label="Bunker Post",Mesh="ENV_VN_Wood_Bunker.Meshes.S_Bunker_Support",Cost=1))
    Pieces.Add((Category="Bunkers",Label="Wood Walkway",Mesh="ENV_VN_Wood_Bunker.Meshes.Walkways.S_Wood_Walkway",Cost=1))

    Pieces.Add((Category="Wood Walls",Label="Wood Wall",Mesh="ENV_VN_Wood_Bunker.Meshes.Bunkerwalls.S_Bunkerwall_closed",Cost=2))
    Pieces.Add((Category="Wood Walls",Label="Wood Wall, Long",Mesh="ENV_VN_Wood_Bunker.Meshes.Bunkerwalls.S_Bunkerwall_closed_long",Cost=4))
    Pieces.Add((Category="Wood Walls",Label="Wood Wall, Half Height",Mesh="ENV_VN_Wood_Bunker.Meshes.Bunkerwalls.S_Bunkerwall_closed_halfheight",Cost=1))
    Pieces.Add((Category="Wood Walls",Label="Wood Wall, Half Width",Mesh="ENV_VN_Wood_Bunker.Meshes.Bunkerwalls.S_Bunkerwall_closed_half",Cost=1))
    Pieces.Add((Category="Wood Walls",Label="Wood Wall with Window",Mesh="ENV_VN_Wood_Bunker.Meshes.Bunkerwalls.S_Bunkerwall_Window_A",Cost=2))
    Pieces.Add((Category="Wood Walls",Label="Wood Wall with Door",Mesh="ENV_VN_Wood_Bunker.Meshes.Bunkerwalls.S_Bunkerwall_Door",Cost=2))

    Pieces.Add((Category="Log Walls",Label="Log Wall",Mesh="ENV_VN_LogWalls.Meshes.S_Logwall_01",Cost=2))
    Pieces.Add((Category="Log Walls",Label="Log Wall, Long",Mesh="ENV_VN_LogWalls.Meshes.S_Logwall_07",Cost=5))
    Pieces.Add((Category="Log Walls",Label="Log Stack",Mesh="ENV_VN_LogWalls.Meshes.S_LogStack_128",Cost=2))
    Pieces.Add((Category="Log Walls",Label="Log Stack, Long",Mesh="ENV_VN_LogWalls.Meshes.S_LogStack_256",Cost=4))
    Pieces.Add((Category="Log Walls",Label="Single Log",Mesh="ENV_VN_LogWalls.Meshes.S_Logwall_Log_256",Cost=1))

    Pieces.Add((Category="Other",Label="F4 Phantom",Mesh="VH_VN_US_F4Phantom.Mesh.F4_Phantom_SM",Cost=10))
}

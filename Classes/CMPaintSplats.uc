// Paintball's paint splats, in each player's own game: a decal on the hit soldier where the shot hit, in the shooter's
// team colour, that moves with the soldier's body like the game's own wound decals (it goes through the soldier's
// wound decal manager, onto their body and their third person head and arms). The paint is the game's poster decal
// material (it greys out its texture and tints it), with one of the four splatters on the game's blood splatter sheet as
// the shape. The material, the texture and the colours can be changed in MutCMenu_Client.ini, section
// [MutCMenu.CMPaintSplats].
class CMPaintSplats extends Object
    config(MutCMenu_Client);

var config string SplatMaterial;    // the decal material, with a 'Texture' texture and a 'Color Overlay' colour
var config string SplatTexture;     // the shape: a sheet of four splats, one in each quarter
var config LinearColor TeamColours[2];
var config float SplatSize;         // across, in unreal units (0: 18, about 36 cm)

// Loaded on the first splat. Kept on an instance (DummyActor's PaintSplats): a static function can't keep them in the
// class defaults, which script may only change for config properties.
var MaterialInstanceConstant Paints[2];
var bool bLoaded, bNoPaint;

const SPLAT_LIFESPAN = 600.0;       // seconds; the splat also goes with the soldier's body

function Load()
{
    local MaterialInterface Parent;
    local Texture Shape;
    local LinearColor Colour;
    local int i;

    bLoaded = true;
    Parent = MaterialInterface(DynamicLoadObject(default.SplatMaterial != "" ? default.SplatMaterial : "ENV_VN_Posters.DecalMats.M_DecalMatMaster",
        class'MaterialInterface', true));
    if (Parent == None)
        Parent = MaterialInterface(DynamicLoadObject("ENV_VN_Posters.M_DecalMatMaster", class'MaterialInterface', true));
    Shape = Texture(DynamicLoadObject(default.SplatTexture != "" ? default.SplatTexture : "FX_VN_Impacts.Textures.T_BloodSplatter_D",
        class'Texture', true));
    bNoPaint = (Parent == None);
    if (bNoPaint)
    {
        `log("[MutCMenu] Paintball: the splat decal material could not be loaded, so no paint is shown");
        return;
    }
    for (i = 0; i < 2; i++)
    {
        Paints[i] = new class'MaterialInstanceConstant';
        Paints[i].SetParent(Parent);
        if (Shape != None)
            Paints[i].SetTextureParameterValue('Texture', Shape);
        Colour = TeamColour(i); // the parameter is an out variable, so it can't take the function's result directly
        Paints[i].SetVectorParameterValue(name("Color Overlay"), Colour);
    }
}

static function LinearColor TeamColour(int Team)
{
    local LinearColor C;

    C = default.TeamColours[Clamp(Team, 0, 1)];
    if (C.R + C.G + C.B > 0)
        return C;
    // Not set: orange for North / Axis, blue for South / Allies
    if (Team == 0)
    {
        C.R = 1.0; C.G = 0.35; C.B = 0.0;
    }
    else
    {
        C.R = 0.05; C.G = 0.45; C.B = 1.0;
    }
    C.A = 1.0;
    return C;
}

// Paint on Victim where a shot coming along Dir hit them at HitLocation, in Team's colour. Nothing on a dedicated server.
function Splat(Pawn Victim, vector HitLocation, vector Dir, byte Team)
{
    local ROPawn P;
    local vector ProjFrom;
    local rotator Facing;
    local float Size;
    local int Quarter;

    P = ROPawn(Victim);
    if (P == None || P.bDeleteMe || P.WorldInfo.NetMode == NM_DedicatedServer || P.PlayerWoundDecalManager == None)
        return;
    if (!bLoaded)
        Load();
    if (bNoPaint || Team > 1)
        return;

    Size = default.SplatSize > 0 ? default.SplatSize : 18.0;
    Dir = Normal(Dir);
    ProjFrom = HitLocation - Dir * 10;      // a little out from the body, as the game's wound decals are
    Facing = rotator(Dir);
    Quarter = Rand(4);                      // one of the four splats on the sheet
    PaintOn(P, P.Mesh, ProjFrom, Facing, Size, Quarter, Team, HitLocation);
    if (P.ThirdPersonHeadAndArmsMeshComponent != None)
        PaintOn(P, P.ThirdPersonHeadAndArmsMeshComponent, ProjFrom, Facing, Size, Quarter, Team, HitLocation);
}

function DecalComponent PaintOn(ROPawn P, SkeletalMeshComponent C, vector ProjFrom, rotator Facing, float Size, int Quarter,
    byte Team, vector HitLocation)
{
    local DecalComponent D;

    if (C == None || C.SkeletalMesh == None)
        return None;
    D = P.PlayerWoundDecalManager.SpawnDecal(Paints[Team], ProjFrom, Facing, Size, Size, 40.0, false, FRand() * 360.0,
        C, false, true, C.FindClosestBone(HitLocation),,, SPLAT_LIFESPAN,,,, P);
    if (D == None)
        return None;
    // The quarter of the sheet that holds the splat: taken off and put back so the new tiling is used
    P.PlayerWoundDecalManager.DetachComponent(D);
    D.TileX = 0.5;
    D.TileY = 0.5;
    D.OffsetX = (Quarter % 2) * 0.5;
    D.OffsetY = (Quarter / 2) * 0.5;
    P.PlayerWoundDecalManager.AttachComponent(D);
    return D;
}

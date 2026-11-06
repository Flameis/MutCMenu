// The movement restriction lines on the ground (CMMapInteraction's Restrict tool), painted as decals so they lie on the
// terrain and on small objects, and whatever stands in front of them hides them. Each player's game makes its own, for the
// restrictions it is sent; nothing is replicated. It is the game's decal manager for its ready made decal components, but
// its decals are never put on the manager's timer, so they stay until the restriction goes.
// The paint is the game's poster decal material (a texture with a colour over it), with a plain texture as the paint and
// the drawing's colour as the colour. Both can be changed in MutCMenu_Client.ini (ZoneDecalMaterial, ZoneDecalTexture).
class CMZoneDecals extends DecalManager;

const NUM_PAINTS = 8; // CMMapInfo's NUM_COLOURS

var MaterialInstanceConstant Paints[NUM_PAINTS];
var MaterialInterface PaintParent;
var Texture PaintTexture;
var bool bPaintLoaded, bNoPaint;

// The paint for one of the map drawing colours, None if the material couldn't be loaded
function MaterialInterface Paint(byte Colour, string MaterialPath, string TexturePath)
{
    local color C;
    local LinearColor L;

    if (Colour >= NUM_PAINTS)
        Colour = 0;
    if (!bPaintLoaded)
        LoadPaint(MaterialPath, TexturePath);
    if (bNoPaint)
        return None;

    if (Paints[Colour] == None)
    {
        C = class'CMMapInfo'.static.GetColour(Colour);
        L.R = C.R / 255.0;
        L.G = C.G / 255.0;
        L.B = C.B / 255.0;
        L.A = 1.0;
        Paints[Colour] = new(self) class'MaterialInstanceConstant';
        Paints[Colour].SetParent(PaintParent);
        if (PaintTexture != None)
            Paints[Colour].SetTextureParameterValue('Texture', PaintTexture);
        Paints[Colour].SetVectorParameterValue(name("Color Overlay"), L);
    }
    return Paints[Colour];
}

function LoadPaint(string MaterialPath, string TexturePath)
{
    bPaintLoaded = true;
    if (MaterialPath != "")
        PaintParent = MaterialInterface(DynamicLoadObject(MaterialPath, class'MaterialInterface', true));
    if (PaintParent == None)
        PaintParent = MaterialInterface(DynamicLoadObject("ENV_VN_Posters.DecalMats.M_DecalMatMaster", class'MaterialInterface', true));
    if (PaintParent == None)
        PaintParent = MaterialInterface(DynamicLoadObject("ENV_VN_Posters.M_DecalMatMaster", class'MaterialInterface', true));
    if (TexturePath != "")
        PaintTexture = Texture(DynamicLoadObject(TexturePath, class'Texture', true));
    if (PaintTexture == None)
        PaintTexture = Texture(DynamicLoadObject("EngineResources.WhiteSquareTexture", class'Texture', true));

    bNoPaint = PaintParent == None;
    if (bNoPaint)
        LogInternal("[MutCMenu] Movement restrictions: the decal material could not be loaded, so the lines are drawn over the view instead");
}

// A strip of paint Length long and Width wide along Facing (yaw only), centred on At, reaching Depth up and down from it
function DecalComponent AddStrip(MaterialInterface M, vector At, int Yaw, float Length, float Width, float Depth)
{
    local DecalComponent D;
    local rotator Down;

    // Straight down; with the decal's height along its up axis, which this turns to point along the strip
    Down.Pitch = -16384;
    Down.Yaw = Yaw;
    D = GetPooledComponent();
    SetDecalParameters(D, M, At, Down, Width, Length, Depth * 2, false, 0.0, None, true, false, '',
        INDEX_NONE, INDEX_NONE, INDEX_NONE, DecalDepthBias, DecalBlendRange);
    AttachComponent(D);
    return D;
}

function RemoveStrip(DecalComponent D)
{
    if (D == None)
        return;
    DetachComponent(D);
    DecalFinished(D); // back to the pool
}

defaultproperties
{
    RemoteRole=ROLE_None
}

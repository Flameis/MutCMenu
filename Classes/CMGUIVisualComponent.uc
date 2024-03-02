//=============================================================================
// GUIVisualComponent
//
// $wotgreal_dt: 26.10.2012 16:03:53$
//
// Base class for all components that draw Textures or Materials on the screen.
//
// Modified by Luke Scovel (AKA Flameis) for use in Rising Storm 2: Vietnam
//=============================================================================
class CMGUIVisualComponent extends GUIVisualComponent;

var float Scale;

// Dynamically determines the top left corner of the Component.
// Takes Canvas clipping, relative position and Anchor Components into account.
function vector2D GetComponentStartPos(Canvas C)
{
    local vector2d Result;

    Result.X = PosX;
    Result.Y = PosY;
    
    return Result;
}

event InitializeComponent()
{
    local GUITextureDrawInfo    CurInfo;

    Scale = (1250/Texture2D(DrawInfo[0].ComponentTexture).SizeY);

    foreach DrawInfo(CurInfo)
    {
        CurInfo.InitializeInfo();
    }

    if (DrawInfo[0] != None && !DrawInfo[0].bUseMaterial && bFitComponentToTexture)
    {
        if (Texture2D(DrawInfo[0].ComponentTexture) != None)
        {
            PosXEnd = PosX + (Texture2D(DrawInfo[0].ComponentTexture).SizeX * Scale);
            PosYEnd = PosY + (Texture2D(DrawInfo[0].ComponentTexture).SizeY * Scale);
        }
        else if (TextureRenderTarget2D(DrawInfo[0].ComponentTexture) != None)
        {
            PosXEnd = PosX + (TextureRenderTarget2D(DrawInfo[0].ComponentTexture).SizeX * Scale);
            PosYEnd = PosY + (TextureRenderTarget2D(DrawInfo[0].ComponentTexture).SizeY * Scale);
        }
    }

    super(GUIComponent).InitializeComponent();
}
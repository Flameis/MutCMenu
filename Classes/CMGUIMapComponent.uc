//=============================================================================
// CMGUIMapComponent
//
// Visual component for the map scene
//
// Modified by Luke Scovel (AKA Flameis) for use in Rising Storm 2: Vietnam
//=============================================================================
class CMGUIMapComponent extends CMGUIVisualComponent;

var int NumHUDComponents;
var array<Vector>   MouseClicks;
var Texture2D 		LineTexture;
var color           DrawColor;
var vector          MouseLocation;

var ROHUDWidgetOverheadMap   OverheadMap;

enum EDrawMode
{
    EDrawNone,
    EDrawLine,
    EDrawPoly,
}; 
var EDrawMode DrawMode;

event InitializeComponent()
{
    local GUITextureDrawInfo    CurInfo;

    DrawInfo[0].ComponentTexture = ROMapInfo(ParentScene.OwnerHUD.WorldInfo.GetMapInfo()).OverheadMapTexture;
    Scale = (1250/Texture2D(DrawInfo[0].ComponentTexture).SizeY);

    OverheadMap = ParentScene.OwnerHUD.OverheadMapWidget;

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

/* event MousePressed(optional byte ButtonNum)
{
    super.MousePressed(ButtonNum);
} */

event MouseReleased(optional byte ButtonNum)
{
    super.MouseReleased(ButtonNum);

    `log("MouseReleased at " $ MouseLocation.X $ ", " $ MouseLocation.Y);

    if (ButtonNum == 0 && DrawMode == EDrawPoly)
        MouseClicks.Additem(MouseLocation);
    else
        DrawMode = EDrawNone;
}

function DrawVisuals(Canvas C, optional byte DrawIndex)
{
    local int i;

    super.DrawVisuals(C, DrawIndex);

    MouseLocation.x = ParentScene.MousePos.X /* - ParentScene.OwnerHUD.SizeX/2 */;
    MouseLocation.y = ParentScene.MousePos.Y;

    if (MouseClicks.Length >= 2)
	{
		for (i = 0; i < MouseClicks.Length; i++)
		{
			if (I != MouseClicks.Length-1)
				ParentScene.OwnerHUD.Canvas.DrawTextureLine(MouseClicks[I], MouseClicks[I+1], 0, 4, DrawColor, LineTexture, 0, 0, 1, 1);
			else 
				ParentScene.OwnerHUD.Canvas.DrawTextureLine(MouseClicks[I], MouseClicks[0], 0, 4, DrawColor, LineTexture, 0, 0, 1, 1);
		}
	}
    if (IsEnclosedByMe(C, MouseLocation.X, MouseLocation.Y))
    {
        switch(DrawMode)
        {
            case EDrawLine:
                break;

            case EDrawPoly:
                if (MouseClicks[0].X != 0)
                {
                    ParentScene.OwnerHUD.Canvas.DrawTextureLine(MouseClicks[0], MouseLocation, 0, 4, DrawColor, LineTexture, 0, 0, 1, 1);
                    ParentScene.OwnerHUD.Canvas.DrawTextureLine(MouseClicks[MouseClicks.Length-1], MouseLocation, 0, 4, DrawColor, LineTexture, 0, 0, 1, 1);
                }
                break;
        }
    }
}

function DrawOnMap(Canvas C)
{
    local int i;
    local vector AdjustedVector;

    AdjustedVector.X = PosX - OverheadMap.CurrentX - OverheadMap.HUDComponents[OverheadMap.ROOMT_Map].X * 1.75;
    AdjustedVector.Y = PosY - OverheadMap.CurrentY - OverheadMap.HUDComponents[OverheadMap.ROOMT_Map].Y * 1.5;

    `log(OverheadMap.CurrentX);
    `log(OverheadMap.CurrentY);
    `log(OverheadMap.HUDComponents[OverheadMap.ROOMT_Map].X);
    `log(OverheadMap.HUDComponents[OverheadMap.ROOMT_Map].Y);
    `log(AdjustedVector.X);
    `log(AdjustedVector.Y);

    if (MouseClicks.Length >= 2)
	{
		for (i = 0; i < MouseClicks.Length; i++)
		{
			if (I != MouseClicks.Length-1)
				ParentScene.OwnerHUD.Canvas.DrawTextureLine(MouseClicks[I] - AdjustedVector, MouseClicks[I+1] - AdjustedVector, 0, 4, DrawColor, LineTexture, 0, 0, 1, 1);
			else 
				ParentScene.OwnerHUD.Canvas.DrawTextureLine(MouseClicks[I] - AdjustedVector, MouseClicks[0] - AdjustedVector, 0, 4, DrawColor, LineTexture, 0, 0, 1, 1);
		}
	}
}

DefaultProperties
{
    bCanHaveSelection = True
    DrawColor = (R=255,G=0,B=0,A=255);
    LineTexture = Texture2D'ui_textures.Textures.button_white';
    Scale = 1.0;
}
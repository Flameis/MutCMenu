//-----------------------------------------------------------
// NOTE: Replace 'SI_GUI.ButtonTest' in the DefaultProperties with references to
// a valid texture in one of your packages. SubUVEnd should be changed to the
// dimensions of the texture then.
//-----------------------------------------------------------
class CMGUISceneMap extends GUIMenuScene;

var CMGUIMapComponent       MapComponent;
var GUIVisualComponent      MapGrid;

var ROHUDWidgetOverheadMap   OverheadMap;

event InitMenuScene()
{
    if (bIsScriptedTextureMenuScene)
    {
        GUISTH = GUIScriptedTextureHandler(Outer);
    }
    else
    {
        OwnerHUD = GUICompatibleHUD(Outer);
    }

	DefaultInputComponent = FindComponentByTag("TitlePage");

	FindComponentByTag("TitlePage").OnInputKey = TitleInput;

	FindComponentByTag("ResumeButton").OnMouseReleased = ResumeReleased;
	FindComponentByTag("PolyButton").OnMouseReleased = PolyReleased;

    MapComponent = CMGUIMapComponent(FindComponentByTag("MapTexture"));
    MapGrid = GUIVisualComponent(FindComponentByTag("MapGrid"));
    OverheadMap = OwnerHUD.OverheadMapWidget;

	super.InitMenuScene();
}

event RenderScene(Canvas C)
{
    super.RenderScene(C);

    if (OverheadMap.IsVisible() && OverheadMap.CurrentZoom == OverheadMap.MIN_ZOOM)
    {
        CMGUIMapComponent(FindComponentByTag("MapTexture")).DrawOnMap(C);
    }
}

function vector ScreenVectorToWorldLocation(vector2d ScreenPos)
{
	local float fMapMinX, fMapMinY, fCompX, fCompY, fPercentX, fPercentY;
	local vector vWorldPos;
    local float WorldMinX, WorldMinY, WorldMaxX, WorldMaxY;
	local array<Actor> AllMapBounds;

    // Calculate the X and Y Unreal Units to Pixels Scale for the current map
	if ( OwnerHUD.FindActorsOfClass(class'ROVolumeMapBounds', AllMapBounds) )
	{
        ROVolumeMapBounds(AllMapBounds[0]).GetBounds(WorldMinX, WorldMinY, WorldMaxX, WorldMaxY);
    }

	if( MapComponent != none)
	{
		fMapMinX = MapComponent.PosX;
		fMapMinY = MapComponent.PosY;

		fCompX = ScreenPos.X;
		fCompY = ScreenPos.Y;

		fPercentX = (fCompX - fMapMinX) / MapComponent.Width;
		fPercentY = (fCompY - fMapMinY) / MapComponent.Height;

		vWorldPos.x = ((WorldMaxX - WorldMinX) * (1.0f - fPercentY)) + WorldMinX;
		vWorldPos.y = ((WorldMinY - WorldMaxY) * fPercentX) + WorldMinY;

		GetHighestPoint(vWorldPos);
	}
	return vWorldPos;
}

function GetHighestPoint(out vector WorldPos)
{
	local Actor		HitActor;
	local vector	HitNormal, HitLocation, TraceEnd;
	local TraceHitInfo HitInfo;
	local float fMapHeight;

	fMapHeight = ROGameReplicationInfo(OwnerHUD.WorldInfo.GRI).ArtySpawn.Z;

	WorldPos.Z = fMapHeight;

	TraceEnd = WorldPos;
	TraceEnd.Z = -fMapHeight;

	HitActor = OwnerHUD.Trace(HitLocation, HitNormal, TraceEnd, WorldPos, false,, HitInfo,);

	if( HitActor != none )
	{
		WorldPos = HitLocation;
	}
	else // If it didn't hit anything
	{
		WorldPos.Z = 0.0f;
	}
}

event MenuOpened()
{
    local Vector2D              NewPos;

    NewPos.X = OwnerHUD.SizeX/2;
    MapComponent.SetPos(NewPos);
    MapGrid.SetPos(NewPos);
}

event PoppedLastPage()
{
    GUICompatibleHUD(Outer).TogglePauseMenu();
}

// Function header matches the layout of the OnMousePressed delegate of the button.
function PolyReleased(optional GUIComponent Component, optional byte ButtonNum)
{
    if (MapComponent.DrawMode == EDrawPoly)
        MapComponent.DrawMode = EDrawNone;
    else
        MapComponent.DrawMode = EDrawPoly;
}

// Function header matches the layout of the OnMousePressed delegate of the button.
function ResumeReleased(optional GUIComponent Component, optional byte ButtonNum)
{
    GUICompatibleHUD(Outer).TogglePauseMenu();
}

function bool TitleInput(int ControllerId, name Key, EInputEvent Event, float AmountDepressed = 1.f, bool bGamepad = FALSE)
{
    if(Event == IE_Released)
    {
		if( Key == 'Escape')
		{
			GUICompatibleHUD(Outer).TogglePauseMenu();
			return True;
		}
    }
    return False;
}

DefaultProperties
{
    bDrawGUIComponents = False // We want to start without them and only draw them when TogglePauseMenu is called.
    bCaptureKeyInput=False // We want the components and the menu to use key input
    bCaptureMouseInput = False // We also want to be able to have a mouse
    LocalizationFileName = "GUIFramework"

//==============================================================================
// Define DrawInfos that we will use on multiple occasions up here.

  // Checkbox
    Begin Object class=GUITextureDrawInfo Name=CheckboxInfoDefault
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=13, Y=13)
        SubUVStart=(X=1, Y=23)
        bStretchHorizontally=true
        bStretchVertically=True
    End Object

    Begin Object class=GUITextureDrawInfo Name=CheckboxInfoHover
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=13, Y=13)
        SubUVStart=(X=15, Y=23)
        bStretchHorizontally=true
        bStretchVertically=True
    End Object

    Begin Object class=GUITextureDrawInfo Name=CheckboxInfoPressed
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=13, Y=13)
        SubUVStart=(X=29, Y=23)
        bStretchHorizontally=true
        bStretchVertically=True
    End Object

    Begin Object class=GUITextureDrawInfo Name=CheckboxInfoDefaultChecked
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=13, Y=13)
        SubUVStart=(X=43, Y=23)
        bStretchHorizontally=false
        bStretchVertically=False
    End Object

    Begin Object class=GUITextureDrawInfo Name=CheckboxInfoHoverChecked
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=13, Y=13) 
        SubUVStart=(X=57, Y=23)
        bStretchHorizontally=false
        bStretchVertically=False
    End Object

    Begin Object class=GUITextureDrawInfo Name=CheckboxInfoPressedChecked
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=13, Y=13)
        SubUVStart=(X=71, Y=23)
        bStretchHorizontally=false
        bStretchVertically=False
    End Object


  // Slider
    Begin Object class=GUITextureDrawInfo Name=SliderbuttonInfoDefault
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=14, Y=37)
        SubUVStart=(X=68, Y=100)
        bStretchHorizontally=false
        bStretchVertically=false
    End Object

    Begin Object class=GUITextureDrawInfo Name=SliderbuttonInfoHover
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=14, Y=37)
        SubUVStart=(X=87, Y=100)
        bStretchHorizontally=false
        bStretchVertically=false
    End Object

    Begin Object class=GUITextureDrawInfo Name=SliderbuttonInfoPressed
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=14, Y=37)
        SubUVStart=(X=106, Y=100)
        bStretchHorizontally=false
        bStretchVertically=false
    End Object


    Begin Object class=GUITextureDrawInfo Name=SliderBaseInfoDefault
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=1, Y=1)
        SubUVStart=(X=11, Y=4)
        DrawColor=(R=0,G=0,B=0,A=0)
    End Object


  // Scrollbox
    Begin Object class=GUITextureDrawInfo Name=ScrollboxPrevButtonInfoDefault
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=14, Y=16)
        SubUVStart=(X=68, Y=83)
        bStretchHorizontally=False
        bStretchVertically=False
    End Object

    Begin Object class=GUITextureDrawInfo Name=ScrollboxPrevButtonInfoHover
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=14, Y=16)
        SubUVStart=(X=87, Y=83)
        bStretchHorizontally=False
        bStretchVertically=False
    End Object

    Begin Object class=GUITextureDrawInfo Name=ScrollboxPrevButtonInfoPressed
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=14, Y=16)
        SubUVStart=(X=106, Y=83)
        bStretchHorizontally=False
        bStretchVertically=False
    End Object


    Begin Object class=GUITextureDrawInfo Name=ScrollboxNextButtonInfoDefault
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=14, Y=16)
        SubUVStart=(X=68, Y=138)
        bStretchHorizontally=False
        bStretchVertically=False
    End Object

    Begin Object class=GUITextureDrawInfo Name=ScrollboxNextButtonInfoHover
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=14, Y=16)
        SubUVStart=(X=87, Y=138)
        bStretchHorizontally=False
        bStretchVertically=False
    End Object

    Begin Object class=GUITextureDrawInfo Name=ScrollboxNextButtonInfoPressed
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=14, Y=16)
        SubUVStart=(X=106, Y=138)
        bStretchHorizontally=False
        bStretchVertically=False
    End Object


    Begin Object class=GUITextureDrawInfo Name=ScrollboxInfoDefault
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=100, Y=18)
        SubUVStart=(X=163, Y=24)
    End Object


  // Button
    Begin Object class=GUITextureDrawInfo Name=ButtonInfoDefault
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=74, Y=21)
        SubUVStart=(X=2, Y=164)
        bStretchHorizontally=True
        bStretchVertically=True
    End Object

    Begin Object class=GUITextureDrawInfo Name=ButtonInfoHover
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=74, Y=21)
        SubUVStart=(X=2, Y=186)
        bStretchHorizontally=True
        bStretchVertically=True
    End Object

    Begin Object class=GUITextureDrawInfo Name=ButtonInfoPressed
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=74, Y=21)
        SubUVStart=(X=2, Y=208)
        bStretchHorizontally=True
        bStretchVertically=True
    End Object

    Begin Object class=GUITextureDrawInfo Name=TextBoxInfo
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=100, Y=18)
        SubUVStart=(X=163, Y=24)
    End Object

    Begin Object class=GUITextureDrawInfo Name=Tex_Background_1
        ComponentTexture=Texture2D'GUI.GUI_Buttons_02'
        SubUVEnd=(X=1, Y=1)
        SubUVStart=(X=11, Y=4)
        DrawColor=(R=0,G=0,B=0,A=150)
    End Object

//------------------------------------------------------------------------------
// Map DrawInfos

    Begin Object class=GUITextureDrawInfo Name=MapTexture
        ComponentTexture=Texture2D'VN_UI_Textures.OverheadMap.ui_overheadmap_grid'
        SubUVEnd=(X=0.0, Y=0.0)
        SubUVStart=(X=0.0, Y=0.0)
    End Object

    Begin Object class=GUITextureDrawInfo Name=MapGrid
        ComponentTexture=Texture2D'VN_UI_Textures.OverheadMap.ui_overheadmap_grid'
        SubUVEnd=(X=0.0, Y=0.0)
        SubUVStart=(X=0.0, Y=0.0)
    End Object

    Begin Object class=GUITextureDrawInfo Name=MapLines
        bUseMaterial=True
        ComponentMaterial=Material'NodeBuddies.Materials.NodeBuddy_Red1'
        SubUVEnd=(X=1, Y=1)
        SubUVStart=(X=2, Y=2)
        DrawColor=(R=255,G=0,B=0,A=255)
    End Object

//------------------------------------------------------------------------------
// string DrawInfos

    Begin Object class=GUIStringDrawInfo Name=BackStringInfo
        DrawColor=(R=0,G=0,B=0,A=255)
    End Object


//==============================================================================
// Define the actual subobjects.

	// Main title screen, this is where we start
    Begin Object class=GUIPage Name=TitlePage
        Tag = "TitlePage"
        PosX = 0.0
        PosY = 0.0
        PosXEnd = 1.0
        PosYEnd = 1.0

		// Background image number 1
		Begin Object class=GUIVisualComponent Name=BackGround
	        Tag = "BackGround"
			PosX = 0
			PosY = 0
			PosXEnd = 1
			PosYEnd = 1
	 
			DrawInfo(0) = Tex_Background_1
		End Object
		ChildComponents.Add(BackGround)

        /* Begin Object class=GUIContainerComponent Name=MapContainer
	        Tag = "MapContainer"
			PosX = 0.5
			PosY = 0
			PosXEnd = 1
			PosYEnd = 1
            bConstrainDrawAreaToContainer = true */

        Begin Object class=CMGUIMapComponent Name=MapTexture
	        Tag = "MapTexture"
			PosX = 0
			PosY = 0
			PosXEnd = 0
			PosYEnd = 0
            bRelativePosX = false
            bRelativePosY = false
            bRelativeWidth = false 
			bRelativeHeight = false
            bFitComponentToTexture = true

			DrawInfo(0) = MapTexture 
		End Object
		ChildComponents.Add(MapTexture)

        Begin Object class=CMGUIVisualComponent Name=MapGrid
	        Tag = "MapGrid"
			PosX = 0
			PosY = 0
			PosXEnd = 0
			PosYEnd = 0
            bRelativePosX = false
            bRelativePosY = false
            bRelativeWidth = false 
			bRelativeHeight = false
            bFitComponentToTexture = true

			DrawInfo(0) = MapGrid
		End Object
		ChildComponents.Add(MapGrid)

		/* End Object
		ChildComponents.Add(MapContainer) */

        Begin Object class=GUIButtonComponent Name=ResumeButton
            Tag = "ResumeButton"
            PosX = 0.05
            PosY = 0.1
            PosXEnd = 0.2
            PosYEnd = 0.145
			bDrawCaption = True
			ForcedCaptionInfo = 0

			DrawInfo(0) = ButtonInfoDefault
			CaptionInfo(0) = BackStringInfo
			Caption(0) = "Resume"

			DrawInfo(1) = ButtonInfoHover

			DrawInfo(3) = ButtonInfoPressed
        End Object
        ChildComponents.Add(ResumeButton)

        Begin Object class=GUIButtonComponent Name=PolyButton
            Tag = "PolyButton"
            PosX = 0.05
            PosY = 0.15
            PosXEnd = 0.2
            PosYEnd = 0.195
			bDrawCaption = True
			ForcedCaptionInfo = 0

			DrawInfo(0) = ButtonInfoDefault
			CaptionInfo(0) = BackStringInfo
			Caption(0) = "New Polygon"

			DrawInfo(1) = ButtonInfoHover

			DrawInfo(3) = ButtonInfoPressed
        End Object
        ChildComponents.Add(PolyButton)
 
    End Object
    GUIComponents.Add(TitlePage)
}
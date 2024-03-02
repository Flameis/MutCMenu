class CMenuMap extends CMenuBase;

var Texture2D 		MouseTex, MapTex, MapGridTex;
var Vector2D 		MouseLocation, ViewportSize;
var array<Vector2D> MouseClicks;
var Color 			DrawColor;

simulated state MenuVisible
{
	function BeginState(name PreviousStateName)
	{
		Initialize();

		LocalPlayer(PC.Player).ViewportClient.GetViewportSize(ViewportSize);
		`log("Viewport size: "$ViewportSize.x@ViewportSize.y);
	}
	
	function bool InputKey( int ControllerId, name Key, EInputEvent EventType, float AmountDepressed = 1.f, bool bGamepad = FALSE )
	{
	    if(EventType == IE_Pressed )
	    {
			if (KeyToNumber(Key) != -1)
	        	return HandleInput(Key, MenuCommand);
			else if (Key == 'LeftMouseButton')
			{
				`log("Left mouse button pressed at" @ MouseLocation.X @ MouseLocation.Y);
				MouseClicks.Additem(MouseLocation);
				// MouseClicks.Sort(SortClicks);
				return true;
			}
			else
				return false;
	    }
	    return false;
	}

	function bool InputAxis( int ControllerId, name Key, float Delta, float DeltaTime, optional bool bGamepad )
	{
		// `log("Axis key:"@Key@"Delta:"@Delta);
		// if they moved the Mouse on the X Axis
		if ( Key == 'MouseX' )
		{
			if (MouseLocation.X+Delta < ViewportSize.X && MouseLocation.X+Delta > 0)
				MouseLocation.X += Delta;
			return true;
		}
		// If they moved the Mouse on the Y Axis
		else if ( Key == 'MouseY' )
		{
			if (MouseLocation.Y-Delta < ViewportSize.Y && MouseLocation.Y-Delta > 0)
				MouseLocation.Y -= Delta;
			return true;
		}
		return false;
	}

	function PostRender(Canvas HUDCanvas)
    {
	    DrawMenu(ROCanvas(HUDCanvas), 10, 200, MenuName, MenuText);
    }
}

// delegate int SortClicks(Vector2D A, Vector2D B) { return A.X > B.X ? -1 : 0; }

/* function bool ContainsPoint(vector2d Point)
{
	return Point.X >= CurX && Point.X <= CurX + CurWidth && Point.Y >= CurY && Point.Y <= CurY + CurHeight;
} */

// Displays the menu based on an input list
function DrawMenu(ROCanvas MenuCanvas, int MenuX, int MenuY, string title, array<string> LineText)
{
	local int i;

    MapTex = ROMapInfo(PC.WorldInfo.GetMapInfo()).OverheadMapTexture;

	// `log("Mouse Location: "$MouseLocation.x@MouseLocation.y);

	MenuCanvas.PushDepthSortPriority(DSP_Insane);
    
    MenuCanvas.SetPos(MenuX+400, MenuY);
    MenuCanvas.DrawTile(MapTex, 1024, 1024, 0, 0, MapTex.GetSurfaceWidth(), MapTex.GetSurfaceHeight(),,,BLEND_Masked);

    MenuCanvas.SetPos(MenuX+400, MenuY);
    MenuCanvas.DrawTile(MapGridTex, 1024, 1024, 0, 0, MapGridTex.GetSurfaceWidth(), MapGridTex.GetSurfaceHeight(),,,BLEND_Masked);

	if (MouseClicks.Length >= 2)
	{
		for (i = 0; i < MouseClicks.Length; i++)
		{
			if (I != MouseClicks.Length-1)
				MenuCanvas.Draw2DLine(MouseClicks[I].X, MouseClicks[I].Y, MouseClicks[I+1].X, MouseClicks[I+1].Y, DrawColor);
			else 
				MenuCanvas.Draw2DLine(MouseClicks[I].X, MouseClicks[I].Y, MouseClicks[0].X, MouseClicks[0].Y, DrawColor);
		}
		// if(MouseLocation.X != MapBounds or something like tha)
		MenuCanvas.Draw2DLine(MouseClicks[0].X, MouseClicks[0].Y, MouseLocation.X, MouseLocation.Y, DrawColor);
		MenuCanvas.Draw2DLine(MouseClicks[MouseClicks.Length-1].X, MouseClicks[MouseClicks.Length-1].Y, MouseLocation.X, MouseLocation.Y, DrawColor);
	}

	MenuCanvas.SetPos(MouseLocation.X, MouseLocation.Y);
	MenuCanvas.DrawTile(MouseTex, MouseTex.GetSurfaceWidth(), MouseTex.GetSurfaceHeight(), 0, 0, MouseTex.GetSurfaceWidth(), MouseTex.GetSurfaceHeight(),,,BLEND_Masked);

	super.DrawMenu(MenuCanvas, MenuX, MenuY, title, LineText);
}

defaultproperties
{
	MouseTex = Texture2D'VN_UI_Textures.OverheadMap.UI_OverheadMap_MouseCursor';
	MapGridTex = Texture2D'VN_UI_Textures.OverheadMap.UI_OverheadMap_Grid';

	DrawColor = (B=0,G=0,R=255,A=255)
}
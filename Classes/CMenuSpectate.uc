class CMenuSpectate extends CMenu
	config(MutCMenu_Client);

function Initialize()
{
	super.Initialize();
}

// Displays the menu based on an input list
function DrawMenu(ROCanvas MenuCanvas, int MenuX, int MenuY, string title, array<string> LineText)
{
	MenuCanvas.DrawTexture(ROHUD(PC.myHUD).OverheadMapWidget.HUDComponents[120].Tex, 1);
}

simulated state MenuVisible
{
    function PostRender(Canvas HUDCanvas)
    {
	    DrawMenu(ROCanvas(HUDCanvas), 10, 250, MenuName, MenuText);
    }
}

defaultproperties
{
    MenuName="SPECTATING"
}
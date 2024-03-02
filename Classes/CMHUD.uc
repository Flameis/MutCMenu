class CMHUD extends GUICompatibleHUD
	config(MutCMenu_Client);

var bool bPauseMenuIsOpen;

// Open menu with Esc key.
exec function CMShowMenu()
{
    TogglePauseMenu();
}

function TogglePauseMenu()
{
    if (bPauseMenuIsOpen) // stop pause
    {
        MenuScene.bDrawGUIComponents = False;
        MenuScene.bCaptureMouseInput = False;
		MenuScene.bCaptureKeyInput = False;
		MenuScene.MenuClosed();
        // PlayerOwner.SetPause(False);
        bPauseMenuIsOpen = False;
    }
    else // start pause
    {
        // PlayerOwner.SetPause(True);
        MenuScene.bDrawGUIComponents = True;
        MenuScene.bCaptureMouseInput = True;
		MenuScene.bCaptureKeyInput = True;
		MenuScene.MenuOpened();
        bPauseMenuIsOpen = True;
    }
}

DefaultProperties
{
    MenuSceneClass=class'CMGUISceneMap' // Use our own MenuScene with the buttons.
    DefaultOverheadMapWidget=class'CMHUDWidgetOverheadMap'
}

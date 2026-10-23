// Code-built UIScene providing a mouse-clickable hit-region per CMenu line, as an alternative to numpad selection.
class CMenuClickOverlayScene extends UIScene;

const MAX_BUTTONS = 10; // ITEMS_PER_PAGE(8) + Next + Previous/Exit

var UIButton Buttons[MAX_BUTTONS];
var CMenu OwnerMenus[MAX_BUTTONS];
var int ButtonNumKeys[MAX_BUTTONS];
var bool bWidgetsBuilt;
var bool bIsOpen;

function BuildWidgets()
{
	local int i;

	if (bWidgetsBuilt)
		return;

	for (i = 0; i < MAX_BUTTONS; i++)
	{
		Buttons[i] = UIButton(CreateWidget(Self, class'UIButton'));
		Buttons[i].OnClicked = OnButtonClicked;
		Buttons[i].SetVisibility(false);
	}

	bWidgetsBuilt = true;
}

function EnsureOpen(GameUISceneClient InSceneClient, LocalPlayer LP)
{
	local UIScene Opened;

	if (bIsOpen || InSceneClient == None)
		return;

	InSceneClient.OpenScene(Self, LP, Opened);
	bIsOpen = true;
}

function EnsureClosed(GameUISceneClient InSceneClient)
{
	if (!bIsOpen)
		return;

	HideAllButtons();
	if (InSceneClient != None)
		InSceneClient.CloseScene(Self);
	bIsOpen = false;
}

// X/Y/Width/Height are absolute viewport pixels; Owner+NumKey identify what a click should select
function PositionButton(int Index, float X, float Y, float Width, float Height, CMenu Owner, int NumKey)
{
	BuildWidgets();

	Buttons[Index].SetPosition(X, UIFACE_Left, EVALPOS_PixelViewport);
	Buttons[Index].SetPosition(Y, UIFACE_Top, EVALPOS_PixelViewport);
	Buttons[Index].SetPosition(X+Width, UIFACE_Right, EVALPOS_PixelViewport);
	Buttons[Index].SetPosition(Y+Height, UIFACE_Bottom, EVALPOS_PixelViewport);
	Buttons[Index].SetVisibility(true);

	OwnerMenus[Index] = Owner;
	ButtonNumKeys[Index] = NumKey;
}

function HideButton(int Index)
{
	BuildWidgets();
	Buttons[Index].SetVisibility(false);
	OwnerMenus[Index] = None;
}

function HideAllButtons()
{
	local int i;

	BuildWidgets();
	for (i = 0; i < MAX_BUTTONS; i++)
	{
		Buttons[i].SetVisibility(false);
		OwnerMenus[i] = None;
	}
}

function bool OnButtonClicked(UIScreenObject EventObject, int PlayerIndex)
{
	local int i;

	for (i = 0; i < MAX_BUTTONS; i++)
	{
		if (Buttons[i] == EventObject && OwnerMenus[i] != None)
		{
			OwnerMenus[i].SelectLine(ButtonNumKeys[i]);
			return true;
		}
	}
	return false;
}

defaultproperties
{
	bPauseGameWhileActive=false
	SceneInputMode=INPUTMODE_Selective
}

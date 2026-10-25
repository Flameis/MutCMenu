class CMenu extends Interaction
	config(MutCMenu_Client);

var PlayerController PC;
var DummyActor MyDA;
// Text-entry dialog (GameUIScene) disabled for now: commands are typed into the console instead
// var CMenuTextEntryScene TextEntryScene;
var Texture2D DefaultTexture_Black, DefaultTexture_White;
var string PendingCmdPrefix, PendingCmdSuffix;

const ITEMS_PER_PAGE = 8;
const TEXT_OFFSET = 10;
// The menu's sizes (font, line spacing, position, click areas) are made for a 1440 pixel high screen and scaled by
// MenuScale = screen height / REFERENCE_HEIGHT, so it takes up the same part of the screen at any resolution
const REFERENCE_HEIGHT = 1440.0;
const MENU_TOP = 240;
const LINE_HEIGHT = 50;
var string MenuName, TargetName, MenuBorderLengthString, LastCmd;
var bool bIsAuthorized;
var int MenuPage, MenuHeight;
var float MenuScale; // From the last frame drawn; 1 until then
// Mouse click mode: the menu keeps its own pointer, moved by the mouse and drawn by this interaction (no UI scene)
var vector2D CursorPos;
var float ScreenW, ScreenH; // From the last frame drawn
var bool bCursorPlaced, bClickPressOwned;
var array<string> MenuText, MenuCommand, PlayerList;
var name NumberKeys[20];

var config Color TextColor, BackgroundColor, BorderColor;
var config bool bKeepOpen, bDrawBackground, bCMenuDebug;

simulated state MenuVisible
{
	function BeginState(name PreviousStateName)
	{
		RestoreDefaultEntries(); // Whatever a previous opening added (admin entries, mod vehicles) is not carried over
		Initialize();
		bCursorPlaced = false;
		bClickPressOwned = false;
	}
	
	function bool InputKey( int ControllerId, name Key, EInputEvent EventType, float AmountDepressed = 1.f, bool bGamepad = FALSE )
	{
		local int Hit;

		// Mouse click mode: the left button picks the line under the pointer. The press and its release are both
		// taken, so the click never fires the player's weapon.
		if (ClickActive() && Key == 'LeftMouseButton')
		{
			if (EventType == IE_Pressed || EventType == IE_DoubleClick)
			{
				bClickPressOwned = true;
				Hit = LineAt(CursorPos.X, CursorPos.Y);
				if (Hit != -1)
					SelectLine(Hit);
				return true;
			}
			if (EventType == IE_Released && bClickPressOwned)
			{
				bClickPressOwned = false;
				return true;
			}
			return false;
		}

	    if(EventType == IE_Pressed )
	    {
			if (KeyToNumber(Key) != -1)
	        	return HandleInput(Key, MenuCommand);
			else
				return false;
	    }
	    return false;
	}

	// Mouse click mode: the mouse moves the menu's pointer instead of the view
	function bool InputAxis( int ControllerId, name Key, float Delta, float DeltaTime, optional bool bGamepad )
	{
		if (!ClickActive())
			return false;

		if (Key == 'MouseX')
			CursorPos.X += Delta;
		else if (Key == 'MouseY')
			CursorPos.Y -= Delta; // mouse up is positive, the screen's Y grows downwards
		else
			return false;

		KeepCursorOnScreen();
		return true;
	}

	function PostRender(Canvas HUDCanvas)
    {
		UpdateMenuScale(HUDCanvas.ClipY);
		ScreenW = HUDCanvas.ClipX;
		ScreenH = HUDCanvas.ClipY;
	    DrawMenu(ROCanvas(HUDCanvas), 0, MENU_TOP * MenuScale, MenuName, MenuText);
		if (ClickActive())
			DrawClickCursor(ROCanvas(HUDCanvas));
    }

	function EndState(name NextStateName)
	{
		bClickPressOwned = false;

		if (NextStateName != 'ReadyToPlace')
			RestoreDefaultEntries();
	}
}

// Puts the menu's lines back to the ones it is defined with. Initialize adds the lines that depend on who is looking
// (admin entries, mod content), so they have to be cleared whenever the menu opens or closes or they pile up.
// Trimming the end of the list is not enough: an entry inserted in the middle stays behind.
function RestoreDefaultEntries()
{
	MenuText = default.MenuText;
	MenuCommand = default.MenuCommand;
}

function Initialize()
{
	MenuPage = 0;

	if (TextColor.a == 0)
	{
		TextColor.r = 255;
		TextColor.g = 128;
		TextColor.b = 0;
		TextColor.a = 255;
	}

	FindCMenuLength(); // Do this here and in HandleInput() so we aren't spamming a loop every tick
}

function bool InputKey( int ControllerId, name Key, EInputEvent EventType, float AmountDepressed = 1.f, bool bGamepad = FALSE )
{
	return false;
}

function bool InputAxis( int ControllerId, name Key, float Delta, float DeltaTime, optional bool bGamepad )
{
	return false;
}

// Translates the enum value produced by KeyEvent() to a number
// Uses NumberKeys var defined in defaultproperties
function int KeyToNumber(name InKey)
{
	local int i;

	if (InStr(InKey, "NumPad",,true) != -1)
	{
		for(i=10; i<20; i++)
		{
			if(InKey == NumberKeys[i])
				return i-10;
		}
	}
	else
	{
		for(i=0; i<10; i++)
		{
			if(InKey == NumberKeys[i])
				return i;
		}
	}

	return -1;
}

// Takes the number pressed (via numpad key or a mouse click) and executes a command based on the selection list
function bool HandleInput(name Key, array<string> SelectionList)
{
	local int NumKey;

	NumKey = KeyToNumber(Key);
	if(NumKey == -1)
		return false;

	return SelectLine(NumKey);
}

// Shared by numpad input and mouse clicks once a 0-9 selection has been resolved
function bool SelectLine(int NumKey)
{
	local int IniLine;
	local string Command;

	IniLine = NumKey-1 + (MenuPage * ITEMS_PER_PAGE); // Adjust for line 1 being row 0 in array & page number

	if(NumKey == 9 && MenuCommand.Length > ((MenuPage+1)*ITEMS_PER_PAGE)) // next page
	{
		MenuPage++;
		FindCMenuLength(); // Do this here and in BeginState() so we aren't spamming a loop every tick
		return true;
	}
	else if(NumKey == 0)
	{
		if(MenuPage > 0) // previous page
		{
			MenuPage--;
			FindCMenuLength(); // Do this here and in BeginState() so we aren't spamming a loop every tick
		}
		else
		{
			GotoState('');
			OpenParentMenu();
		}
		return true;
	}
	else if(MenuCommand.Length >= IniLine)
	{
		Command = MenuCommand[IniLine];
		LastCmd	= Command;

		if (CheckExceptions(Command)) //Check for any exceptions in child classes
		{
			if (!bKeepOpen) GotoState(''); // Close Menu
			return true;
		}
		PC.ConsoleCommand("mutate "$Command); //Execute Command
		if (!bKeepOpen) GotoState(''); // Close Menu
		return true;
	}
	else
	{
		MessageSelf("Invalid Menu Selection");
		if (!bKeepOpen) GotoState(''); // Close Menu
		return true;
	}
}

function OpenParentMenu()
{
	local string ParentMenu;

	switch (Caps(MenuName))
	{
		case "GENERAL": ParentMenu = "CMENUMAIN"; break;
		case "BUILDER": ParentMenu = "CMENUMAIN"; break;
		case "WEAPONS": ParentMenu = "CMENUMAIN"; break;
		case "SETTINGS": ParentMenu = "CMENUMAIN"; break;
		case "REALISM MATCH": ParentMenu = "CMENUMAIN"; break;
		case "PARADROPS": ParentMenu = "CMENUMAIN"; break;
		case "PLAYERS": ParentMenu = "CMENUMAIN"; break;
		case "FIRE SUPPORT": ParentMenu = "CMENUMAIN"; break;
		case "MATCH CONTROL": ParentMenu = "CMENUREALISMMATCH"; break;
		case "ROUND SETTINGS": ParentMenu = "CMENUREALISMMATCH"; break;
		case "OBJECTIVES": ParentMenu = "CMENUREALISMMATCH"; break;
		case "TEAMS AND WEAPONS": ParentMenu = "CMENUREALISMMATCH"; break;
		case "ACTORS": ParentMenu = "CMENUBMAIN"; break;
		case "STATIC MESHES": ParentMenu = "CMENUBMAIN"; break;
		case "STRUCTURES": ParentMenu = "CMENUBMAIN"; break;
		case "VEHICLES": ParentMenu = "CMENUBMAIN"; break;
		case "WEAPON PICKUPS": ParentMenu = "CMENUBMAIN"; break;
	}

	if (ParentMenu != "")
		PC.ConsoleCommand("mutate cmenu "$ParentMenu);
}

// Find the longest string currently displayed on the menu
function FindCMenuLength()
{
	local int i, MenuTextMaxLength;

	for (i = MenuPage * ITEMS_PER_PAGE; i < (MenuPage+1)*ITEMS_PER_PAGE; i++)
	{
		if (Len(MenuText[i]) > MenuTextMaxLength)
		{
			MenuTextMaxLength = Len(MenuText[i]);
			MenuBorderLengthString = MenuText[i];
		}
	}
}

// Just here to provide a way to catch exceptions in children without redefining the entire HandleInput() function
function bool CheckExceptions(string Command) 
{
	return false;
}

function GameUISceneClient GetCMenuSceneClient()
{
	local LocalPlayer LP;

	LP = LocalPlayer(PC.Player);
	if (LP == None || LP.ViewportClient == None || LP.ViewportClient.UIController == None)
		return None;

	return LP.ViewportClient.UIController.SceneClient;
}

// Pre-types CommandPrefix in the console and shows the guidance for the command that needs a value.
// Prompt lines are separated by "|". The player finishes the command (CommandPrefix$<value>$CommandSuffix) and presses enter.
// The guidance is written into the console history and the large console is opened, because it is far longer than the chat
// window can show and stays readable (scrollable) while typing.
function PromptForText(string Prompt, string CommandPrefix, optional string CommandSuffix)
{
	PendingCmdPrefix = CommandPrefix;
	PendingCmdSuffix = CommandSuffix;

	// Short guidance goes to the chat and the mini console, long guidance to the large console (see DummyActor.ShowHelp)
	if (MyDA != None)
		MyDA.ShowHelp(Prompt, CommandPrefix, CommandSuffix, "[CMenu] ");
}

/* Text-entry dialog (GameUIScene), disabled for now. Re-enable together with CMenuTextEntryScene.uc,
// the TextEntryScene vars here and in DummyActor, and a function in DummyActor that creates the scene.

// Opens the shared text-entry dialog; on submit, runs Prefix$EnteredText$Suffix as a console command
function PromptForText(string Prompt, string CommandPrefix, optional string CommandSuffix)
{
	local GameUISceneClient SceneClient;
	local UIScene Opened;

	SceneClient = GetCMenuSceneClient();
	if (SceneClient == None || TextEntryScene == None)
		return;

	PendingCmdPrefix = CommandPrefix;
	PendingCmdSuffix = CommandSuffix;
	TextEntryScene.Configure(Prompt, "", OnPromptSubmitted);
	SceneClient.OpenScene(TextEntryScene, LocalPlayer(PC.Player), Opened);
}

function bool OnPromptSubmitted(string EnteredText, bool bCancelled)
{
	local GameUISceneClient SceneClient;

	SceneClient = GetCMenuSceneClient();
	if (SceneClient != None)
		SceneClient.CloseScene(TextEntryScene);

	if (!bCancelled && EnteredText != "")
		PC.ConsoleCommand(PendingCmdPrefix $ EnteredText $ PendingCmdSuffix);

	return true;
}
*/

// The menu's scale for a screen this many pixels high (1 at 1440p, 0.75 at 1080p, 1.5 at 4K)
static function float ScaleForScreenHeight(float ScreenHeight)
{
	return ScreenHeight > 0 ? ScreenHeight / REFERENCE_HEIGHT : 1.0;
}

// Picks up the screen size each frame; the pointer's click areas are worked out from it when they are needed
function UpdateMenuScale(float ScreenHeight)
{
	MenuScale = ScaleForScreenHeight(ScreenHeight);
}

// True while mouse click mode is on (the main menu's Toggle Mouse Click Mode)
function bool ClickActive()
{
	return MyDA != None && MyDA.bClickModeActive;
}

// True when this menu is open and has taken the mouse for its pointer; CMMapInputHook leaves the clicks to it then
function bool HasMousePointer()
{
	return ClickActive() && IsInState('MenuVisible');
}

function KeepCursorOnScreen()
{
	CursorPos.X = FClamp(CursorPos.X, 0, ScreenW > 0 ? ScreenW : 100000.0);
	CursorPos.Y = FClamp(CursorPos.Y, 0, ScreenH > 0 ? ScreenH : 100000.0);
}

// The click area of one line of the visible page: Slot 0 to ITEMS_PER_PAGE-1 are the menu lines, ITEMS_PER_PAGE is Next
// and ITEMS_PER_PAGE+1 is Previous/Exit. False when that slot is not shown. Laid out like DrawMenu, at the same scale.
function bool SlotRect(int Slot, out float X, out float Y, out float W, out float H)
{
	local int Count;
	local float LineY;
	local bool bNext;

	Count = Min((MenuPage+1)*ITEMS_PER_PAGE, MenuCommand.Length) - (MenuPage*ITEMS_PER_PAGE);
	bNext = MenuCommand.Length > ((MenuPage+1)*ITEMS_PER_PAGE);
	X = TEXT_OFFSET * MenuScale;
	H = LINE_HEIGHT * MenuScale;
	LineY = (MENU_TOP + TEXT_OFFSET + (MenuName != "" ? LINE_HEIGHT : 0)) * MenuScale;

	if (Slot < ITEMS_PER_PAGE)
	{
		if (Slot >= Count)
			return false;
		Y = LineY + Slot * H;
		W = 500.f * MenuScale;
		return true;
	}

	LineY += Max(Count, 0) * H;
	W = 200.f * MenuScale;
	if (Slot == ITEMS_PER_PAGE)
	{
		if (!bNext)
			return false;
		Y = LineY + 2 * H;
		return true;
	}

	if (bNext)
		LineY += 2 * H;
	Y = LineY + 2 * H;
	return true;
}

// The number a click at this screen position selects (1-8 lines, 9 Next, 0 Previous/Exit), or -1 for none
function int LineAt(float PX, float PY)
{
	local int Slot;
	local float X, Y, W, H;

	for (Slot = 0; Slot <= ITEMS_PER_PAGE+1; Slot++)
	{
		if (SlotRect(Slot, X, Y, W, H) && PX >= X && PX <= X + W && PY >= Y && PY <= Y + H)
		{
			if (Slot < ITEMS_PER_PAGE)
				return Slot + 1;
			return Slot == ITEMS_PER_PAGE ? 9 : 0;
		}
	}
	return -1;
}

// The pointer, and a light box on the line it is over. It is drawn by this interaction on top of the game, the way
// CMMapInteraction draws the map tools, so it works on every game the mutator runs on.
function DrawClickCursor(ROCanvas C)
{
	local int Hit, Slot;
	local float X, Y, W, H, Size;
	local ROHUD HUD;
	local ROHUDWidgetComponent Pointer;

	if (C == None)
		return;

	if (!bCursorPlaced)
	{
		// Starts on the first line, where the player is about to look
		if (!SlotRect(0, X, Y, W, H))
		{
			X = TEXT_OFFSET * MenuScale;
			Y = MENU_TOP * MenuScale;
			W = 200.f * MenuScale;
			H = LINE_HEIGHT * MenuScale;
		}
		CursorPos.X = X + W * 0.5;
		CursorPos.Y = Y + H * 0.5;
		bCursorPlaced = true;
	}
	KeepCursorOnScreen();

	Hit = LineAt(CursorPos.X, CursorPos.Y);
	if (Hit != -1)
	{
		Slot = (Hit == 9) ? ITEMS_PER_PAGE : (Hit == 0 ? ITEMS_PER_PAGE + 1 : Hit - 1);
		if (SlotRect(Slot, X, Y, W, H))
		{
			C.PushDepthSortPriority(DSP_SkyHigh);
			C.SetPos(X, Y);
			C.SetDrawColor(255, 255, 255, 60);
			C.DrawRect(W, H);
			C.PopDepthSortPriority();
		}
	}

	C.PushDepthSortPriority(DSP_Insane);
	HUD = (PC != None) ? ROHUD(PC.myHUD) : None;
	if (HUD != None && HUD.OverheadMapWidget != None && HUD.OverheadMapWidget.HUDComponents.Length > class'ROHUDWidgetOverheadMap'.const.ROOMT_MousePointer)
		Pointer = HUD.OverheadMapWidget.HUDComponents[class'ROHUDWidgetOverheadMap'.const.ROOMT_MousePointer];

	if (Pointer != None && Pointer.Tex != None)
	{
		// The game's own cursor, so it looks the same as on the map
		C.SetDrawColor(255, 255, 255, 255);
		C.SetPos(CursorPos.X, CursorPos.Y);
		C.DrawTile(Pointer.Tex, Pointer.CurWidth > 0 ? Pointer.CurWidth : 24 * MenuScale, Pointer.CurHeight > 0 ? Pointer.CurHeight : 24 * MenuScale,
			Pointer.UOffset, Pointer.VOffset,
			Pointer.TexWidth > 0 ? Pointer.TexWidth : float(Pointer.Tex.SizeX), Pointer.TexHeight > 0 ? Pointer.TexHeight : float(Pointer.Tex.SizeY));
	}
	else
	{
		// No game cursor to borrow: a white square with a dark edge
		Size = 12 * MenuScale;
		C.SetDrawColor(0, 0, 0, 255);
		C.SetPos(CursorPos.X - 2, CursorPos.Y - 2);
		C.DrawRect(Size + 4, Size + 4);
		C.SetDrawColor(255, 255, 255, 255);
		C.SetPos(CursorPos.X, CursorPos.Y);
		C.DrawRect(Size, Size);
	}
	C.PopDepthSortPriority();
}

// Displays the menu based on an input list
// Everything is drawn at MenuScale: the font, the line spacing, the margin and the background
function DrawMenu(ROCanvas MenuCanvas, int MenuX, int MenuY, string title, array<string> LineText)
{
	local int i, key;
	local float BL, BH, height, X, Y;

	height = LINE_HEIGHT * MenuScale;
	key = 1;

	MenuCanvas.Font = Font'VN_UI_Mega_Fonts.Font_VN_Mega_36';

	if (bDrawBackground)
	{
		MenuCanvas.PushDepthSortPriority(DSP_SkyHigh); // If we don't do this the text will disappear when hovering over a player due to the playername
		MenuCanvas.StrLen("-----"$MenuBorderLengthString, BL, BH);
		BL *= MenuScale;
		// draw the background, from the top down to 60 (scaled) below the last line
		MenuCanvas.SetPos(MenuX, MenuY);
		MenuCanvas.SetDrawColorStruct(BackgroundColor);
		MenuCanvas.DrawRect(BL, MenuHeight - MenuY + 60 * MenuScale);
		// draw the border
		MenuCanvas.SetPos(MenuX, MenuY);
		MenuCanvas.SetDrawColorStruct(BorderColor);
		MenuCanvas.DrawBox(BL, MenuHeight - MenuY + 60 * MenuScale);
	}

	MenuCanvas.PushDepthSortPriority(DSP_Insane); // If we don't do this the text will disappear when hovering over a player due to the playername
	MenuCanvas.SetDrawColorStruct(TextColor); //Orange by default in config (255,128,0,255)

	X = MenuX + TEXT_OFFSET * MenuScale;
	Y = MenuY + TEXT_OFFSET * MenuScale;

	// Title
	if(title != "")
	{
		MenuCanvas.SetPos(X, Y);
		MenuCanvas.DrawText(title, false, MenuScale, MenuScale);
		Y += height; // next line
	}

	for( i = MenuPage * ITEMS_PER_PAGE; i < Min((MenuPage+1)*ITEMS_PER_PAGE, LineText.Length); i++ )
	{
		MenuCanvas.SetPos(X, Y);
		MenuCanvas.DrawText(key $ ". " $ LineText[i], false, MenuScale, MenuScale);
		key++;
		Y += height; // next line
	}

	// 9. Next Page
	if(LineText.Length > ((MenuPage+1)*ITEMS_PER_PAGE))
	{
		Y += height*2; // skip a line
		MenuCanvas.SetPos(X, Y);
		MenuCanvas.DrawText("9. Next", false, MenuScale, MenuScale);
	}

	// 0. Exit Menu
	Y += height*2; // skip a line
	MenuCanvas.SetPos(X, Y);
	if(MenuPage > 0)
		MenuCanvas.DrawText("0. Previous", false, MenuScale, MenuScale);
	else
		MenuCanvas.DrawText("0. Exit", false, MenuScale, MenuScale);

	MenuHeight = Y;

	// Take off the layers pushed above, or everything drawn after the menu (the map tools, other menus) stays in them
	MenuCanvas.PopDepthSortPriority();
	if (bDrawBackground)
		MenuCanvas.PopDepthSortPriority();
}

function MessageSelf(string Message)
{
	if(Message != "")
	{
		PC.ClientMessage(Message);
	}
}

function bool CheckMutsLoaded(string StrToCheck)
{
	if (InStr(StrToCheck, "WinterWar",,true) != -1 && !MyDA.bLoadWW)
	{
		MessageSelf("Winter War is not loaded");
		return false;
	}
	else if (InStr(StrToCheck, "GOM3",,true) != -1 && !MyDA.bLoadGOM3)
	{
		MessageSelf("GOM3 is not loaded");
		return false;
	}
	else if (InStr(StrToCheck, "GOM4",,true) != -1 && !MyDA.bLoadGOM4)
	{
		MessageSelf("GOM4 is not loaded");
		return false;
	}
	else if (InStr(StrToCheck, "MutExtras",,true) != -1 && !MyDA.bLoadExtras)
	{
		MessageSelf("MutExtras is not loaded");
		return false;
	}
	else if (InStr(StrToCheck, "WW2",,true) != -1 && !MyDA.bLoadWW2)
	{
		MessageSelf("WW2 is not loaded");
		return false;
	}
	return true;
}

function ToggleCMenuBackground()
{
	local int i;

	if(!bDrawBackground) 
	{bDrawBackground = true;}
	else 
	{bDrawBackground = false;}

    for (i = 0; i < PC.Interactions.Length; i++)
    {
        if (InStr(PC.Interactions[i].name, "CMenu",,true) != -1)
        {
            CMenu(PC.Interactions[i]).bDrawBackground = bDrawBackground;
			CMenu(PC.Interactions[i]).SaveConfig();
        }
    }
}

function ToggleCMenuStay()
{
    local int i;

	if(!bKeepOpen) 
	{bKeepOpen = true;}
	else 
	{bKeepOpen = false;}

    for (i = 0; i < PC.Interactions.Length; i++)
    {
        if (InStr(PC.Interactions[i].name, "CMenu",,true) != -1)
        {
            CMenu(PC.Interactions[i]).bKeepOpen = bKeepOpen;
			CMenu(PC.Interactions[i]).SaveConfig();
        }
    }
}

function SetCMenuColor(color InColor, string Type)
{
	if (Type ~= "Text") TextColor = InColor;
	else if (Type ~= "Border") BorderColor = InColor;
	else if (Type ~= "Background") BackgroundColor = InColor;
	SaveConfig();
}

defaultproperties
{
    NumberKeys[0]=zero
    NumberKeys[1]=one
    NumberKeys[2]=two
    NumberKeys[3]=three
    NumberKeys[4]=four
    NumberKeys[5]=five
    NumberKeys[6]=six
    NumberKeys[7]=seven
    NumberKeys[8]=eight
    NumberKeys[9]=nine
	NumberKeys[10]=numpadzero
    NumberKeys[11]=numpadone
    NumberKeys[12]=numpadtwo
    NumberKeys[13]=numpadthree
    NumberKeys[14]=numpadfour
    NumberKeys[15]=numpadfive
    NumberKeys[16]=numpadsix
    NumberKeys[17]=numpadseven
    NumberKeys[18]=numpadeight
    NumberKeys[19]=numpadnine

	MenuScale=1.0

	DefaultTexture_Black=Texture2D'EngineResources.Black'
	DefaultTexture_White=Texture2D'EngineResources.WhiteSquareTexture'

	//Assigns the delegate to our Input function
	OnReceivedNativeInputKey=InputKey
	OnReceivedNativeInputAxis=InputAxis
}
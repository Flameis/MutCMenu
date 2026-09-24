class CMenu extends Interaction
	config(MutCMenu_Client);

var PlayerController PC;
var DummyActor MyDA;
var CMenuTextEntryScene TextEntryScene;
var CMenuClickOverlayScene ClickOverlay;
var Texture2D DefaultTexture_Black, DefaultTexture_White;
var string PendingCmdPrefix, PendingCmdSuffix;

const ITEMS_PER_PAGE = 8;
const TEXT_OFFSET = 10;
var string MenuName, TargetName, MenuBorderLengthString, LastCmd;
var bool bIsAuthorized;
var int MenuPage, MenuHeight;
var array<string> MenuText, MenuCommand, PlayerList;
var name NumberKeys[20];

var config Color TextColor, BackgroundColor, BorderColor;
var config bool bKeepOpen, bDrawBackground, bCMenuDebug;

simulated state MenuVisible
{
	function BeginState(name PreviousStateName)
	{
		Initialize();
		RebuildClickOverlay();
	}
	
	function bool InputKey( int ControllerId, name Key, EInputEvent EventType, float AmountDepressed = 1.f, bool bGamepad = FALSE )
	{
	    if(EventType == IE_Pressed )
	    {
			if (KeyToNumber(Key) != -1)
	        	return HandleInput(Key, MenuCommand);
			else
				return false;
	    }
	    return false;
	}

	function PostRender(Canvas HUDCanvas)
    {
	    DrawMenu(ROCanvas(HUDCanvas), 0, 240, MenuName, MenuText);
    }

	function EndState(name NextStateName)
	{
		if (ClickOverlay != None)
			ClickOverlay.EnsureClosed(GetCMenuSceneClient());

		if (NextStateName != 'ReadyToPlace')
		{
			if (MenuCommand.Length > default.MenuCommand.Length)
			{
        		MenuText.Remove(default.MenuCommand.Length, MenuText.Length-default.MenuCommand.Length);
				MenuCommand.Remove(default.MenuCommand.Length, MenuCommand.Length-default.MenuCommand.Length);
			}
		}
	}
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

// Takes the number pressed (via numpad key or a click-overlay button) and executes a command based on the selection list
function bool HandleInput(name Key, array<string> SelectionList)
{
	local int NumKey;

	NumKey = KeyToNumber(Key);
	if(NumKey == -1)
		return false;

	return SelectLine(NumKey);
}

// Shared by numpad input and click-overlay buttons once a 0-9 selection has been resolved
function bool SelectLine(int NumKey)
{
	local int IniLine;
	local string Command;

	IniLine = NumKey-1 + (MenuPage * ITEMS_PER_PAGE); // Adjust for line 1 being row 0 in array & page number

	if(NumKey == 9 && MenuCommand.Length > ((MenuPage+1)*ITEMS_PER_PAGE)) // next page
	{
		MenuPage++;
		FindCMenuLength(); // Do this here and in BeginState() so we aren't spamming a loop every tick
		RebuildClickOverlay();
		return true;
	}
	else if(NumKey == 0)
	{
		if(MenuPage > 0) // previous page
		{
			MenuPage--;
			FindCMenuLength(); // Do this here and in BeginState() so we aren't spamming a loop every tick
			RebuildClickOverlay();
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

// Mirrors the currently visible page as mouse-clickable hit-regions; no-op unless click mode is active
function RebuildClickOverlay()
{
	local int i, Count;
	local float LineX, LineY;
	local GameUISceneClient SceneClient;

	if (ClickOverlay == None || MyDA == None)
		return;

	SceneClient = GetCMenuSceneClient();

	if (!MyDA.bClickModeActive)
	{
		ClickOverlay.EnsureClosed(SceneClient);
		return;
	}

	ClickOverlay.EnsureOpen(SceneClient, LocalPlayer(PC.Player));

	LineX = TEXT_OFFSET;
	LineY = 240 + TEXT_OFFSET + (MenuName != "" ? 50 : 0);

	Count = Min((MenuPage+1)*ITEMS_PER_PAGE, MenuCommand.Length) - (MenuPage*ITEMS_PER_PAGE);
	for (i = 0; i < Count; i++)
	{
		ClickOverlay.PositionButton(i, LineX, LineY, 500.f, 50.f, Self, i+1);
		LineY += 50;
	}
	for (i = Count; i < ITEMS_PER_PAGE; i++)
	{
		ClickOverlay.HideButton(i);
	}

	if (MenuCommand.Length > ((MenuPage+1)*ITEMS_PER_PAGE)) // Next
	{
		LineY += 100;
		ClickOverlay.PositionButton(ITEMS_PER_PAGE, LineX, LineY, 200.f, 50.f, Self, 9);
	}
	else
	{
		ClickOverlay.HideButton(ITEMS_PER_PAGE);
	}

	LineY += 100;
	ClickOverlay.PositionButton(ITEMS_PER_PAGE+1, LineX, LineY, 200.f, 50.f, Self, 0);
}

// Displays the menu based on an input list
function DrawMenu(ROCanvas MenuCanvas, int MenuX, int MenuY, string title, array<string> LineText)
{
	local int height, i, key;
	local float BL, BH;

	height = 50; // line height
	key = 1;

	MenuCanvas.Font = Font'VN_UI_Mega_Fonts.Font_VN_Mega_36';

	if (bDrawBackground)
	{
		MenuCanvas.PushDepthSortPriority(DSP_SkyHigh); // If we don't do this the text will disappear when hovering over a player due to the playername
		MenuCanvas.StrLen("-----"$MenuBorderLengthString, BL, BH);
		// draw the background
		MenuCanvas.SetPos(MenuX, MenuY);
		MenuCanvas.SetDrawColorStruct(BackgroundColor);
		MenuCanvas.DrawRect(BL, MenuHeight-180);
		// draw the border
		MenuCanvas.SetPos(MenuX, MenuY);
		MenuCanvas.SetDrawColorStruct(BorderColor);
		MenuCanvas.DrawBox(BL, MenuHeight-180);
	}

	MenuCanvas.PushDepthSortPriority(DSP_Insane); // If we don't do this the text will disappear when hovering over a player due to the playername
	MenuCanvas.SetDrawColorStruct(TextColor); //Orange by default in config (255,128,0,255)

	MenuX+=TEXT_OFFSET;
	MenuY+=TEXT_OFFSET;

	// Title
	if(title != "")
	{
		MenuCanvas.SetPos(MenuX, MenuY);
		MenuCanvas.DrawText(title, false);
		MenuY += height; // next line
	}

	for( i = MenuPage * ITEMS_PER_PAGE; i < Min((MenuPage+1)*ITEMS_PER_PAGE, LineText.Length); i++ )
	{
		MenuCanvas.SetPos(MenuX, MenuY);
		MenuCanvas.DrawText(key $ ". " $ LineText[i], false);
		key++;
		MenuY += height; // next line
	}

	// 9. Next Page
	if(LineText.Length > ((MenuPage+1)*ITEMS_PER_PAGE))
	{
		MenuY += height*2; // skip a line
		MenuCanvas.SetPos(MenuX, MenuY);
		MenuCanvas.DrawText("9. Next", false);
	}

	// 0. Exit Menu
	MenuY += height*2; // skip a line
	MenuCanvas.SetPos(MenuX, MenuY);
	if(MenuPage > 0)
		MenuCanvas.DrawText("0. Previous", false);
	else
		MenuCanvas.DrawText("0. Exit", false);

	MenuHeight = MenuY;
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

	DefaultTexture_Black=Texture2D'EngineResources.Black'
	DefaultTexture_White=Texture2D'EngineResources.WhiteSquareTexture'

	//Assigns the delegate to our Input function
	OnReceivedNativeInputKey=InputKey
	OnReceivedNativeInputAxis=InputAxis
}
class CMenu extends Interaction
	config(MutCMenu_Client);

var PlayerController PC;
var DummyActor MyDA;
var Texture2D DefaultTexture_Black, DefaultTexture_White;

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

// Takes the number pressed and executes a command based on the selection list
function bool HandleInput(name Key, array<string> SelectionList)
{
	local int IniLine;
	local string Command;
	local int NumKey;

	NumKey = KeyToNumber(Key);
	if(NumKey == -1)
		return false;

	IniLine = NumKey-1 + (MenuPage * ITEMS_PER_PAGE); // Adjust for line 1 being row 0 in array & page number

	if(NumKey == 9 && SelectionList.Length > ((MenuPage+1)*ITEMS_PER_PAGE)) // next page
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
			GotoState(''); // Close Menu
		return true;
	}
	else if(SelectionList.Length >= IniLine)
	{
		Command = SelectionList[IniLine];
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
	else if (InStr(StrToCheck, "MutExtrasTB",,true) != -1 && !MyDA.bLoadExtras)
	{
		MessageSelf("MutExtrasTB is not loaded");
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
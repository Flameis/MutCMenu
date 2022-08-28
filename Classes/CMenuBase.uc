class CMenuBase extends Interaction
	config(MutCMenuClient);

var PlayerController PC;
var Texture2D DefaultTexture_Black, DefaultTexture_White;

var config Color TextColor, BackgroundColor, BorderColor;
var config bool bKeepOpen, bDrawBackground;

const ITEMS_PER_PAGE = 8;
var bool bCMenuDebug, bVisible, bIsAuthorized, bMutCommands, bMutExtras;
var array<string> MenuText, MenuCommand, PlayerList;
var string MenuName, TargetName, MenuBorderLengthString;
var name NumberKeys[10];
var int MenuPage, MenuHeight, PreviousMenuPage;

function MessageSelf(string Message)
{
	if(Message != "")
	{
		PC.ClientMessage(Message);
	}
}

simulated state MenuVisible
{
	function BeginState(name PreviousStateName)
	{
		local int i, MenuTextMaxLength;

		bVisible = true;
		PreviousMenuPage = -1;
		MenuPage = 0;

		for (i = 0; i < MenuText.Length; i++)
		{
			if (Len(MenuText[i]) > MenuTextMaxLength)
			{
				MenuTextMaxLength = Len(MenuText[i]);
				MenuBorderLengthString = MenuText[i];
			}
			if (i == ITEMS_PER_PAGE-1 )
			{
				MenuTextMaxLength = 0;
			}	
			if (i == MenuText.Length-1)
			{
				`log (MenuBorderLengthString);
			}	
		}

		UpdatePlayerList(); // Do this here because doing it in PostRender() repeats it over & over
	}

	function EndState(name PreviousStateName)
	{
		bVisible = false;
	}

	function bool InputKey( int ControllerId, name Key, EInputEvent EventType, float AmountDepressed = 1.f, bool bGamepad = FALSE )
	{
	    if(EventType == IE_Pressed)
	    {
	        return HandleInput(Key, MenuCommand);
	    }
	    return false;
	}

	function PostRender(Canvas HUDCanvas)
    {
	    DrawMenu(HUDCanvas, 10, 250, MenuName, MenuText);
    }
}

function bool InputKey( int ControllerId, name Key, EInputEvent EventType, float AmountDepressed = 1.f, bool bGamepad = FALSE )
{
	return false;
}

// Translates the enum value produced by KeyEvent() to a number
// Uses NumberKeys var defined in defaultproperties
function int KeyToNumber(name InKey)
{
	local int i;

	for(i=0; i<10; i++)
	{
		if(InKey == NumberKeys[i])
			return i;
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
		return true;
	}
	else if(NumKey == 0)
	{
		if(MenuPage > 0) // previous page
			MenuPage--;
		else
			GotoState(''); // Close Menu
		return true;
	}
	else if(SelectionList.Length >= IniLine)
	{
		Command = SelectionList[IniLine];

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

//Just here to provide a way to catch exceptions in children without redefining the entire HandleInput() function
function bool CheckExceptions(string Command) 
{
	return false;
}

// Displays the menu based on an input list
function DrawMenu(canvas MenuCanvas, int MenuX, int MenuY, string title, array<string> LineText)
{
	local int height, i, key;
	local float BL, BH;
	local int MenuTextMaxLength;

	if (MenuPage != PreviousMenuPage)
	{
		PreviousMenuPage = MenuPage;
		for (i = 0; i < MenuText.Length; i++)
		{
			if (Len(MenuText[i]) > MenuTextMaxLength)
			{
				MenuTextMaxLength = Len(MenuText[i]);
				MenuBorderLengthString = MenuText[i];
			}
			if (i == ITEMS_PER_PAGE-1 && MenuPage == 1)
			{
				MenuTextMaxLength = 0;
			}
			else if (i == ITEMS_PER_PAGE*2-1 && MenuPage == 2)
			{
				MenuTextMaxLength = 0;
			}
			else if (i == ITEMS_PER_PAGE*3-1 && MenuPage == 3)
			{
				MenuTextMaxLength = 0;
			}
			else if (i == ITEMS_PER_PAGE*4-1 && MenuPage == 4)
			{
				MenuTextMaxLength = 0;
			}
			if (i == MenuText.Length-1)
			{
				`log (MenuBorderLengthString);
			}
		}
	}

	height = 50; // line height
	key = 1;

	MenuCanvas.Font = Font'VN_UI_Mega_Fonts.Font_VN_Mega_36';
	MenuCanvas.StrLen("-----"$MenuBorderLengthString, BL, BH);

	if (bDrawBackground)
	{
		// draw the background
		MenuCanvas.SetPos(MenuX-10, MenuY-10);
		MenuCanvas.SetDrawColorStruct(BackgroundColor);
		MenuCanvas.DrawRect(BL, MenuHeight-180);
		// draw the border
		MenuCanvas.SetPos(MenuX-10, MenuY-10);
		MenuCanvas.SetDrawColorStruct(BorderColor);
		MenuCanvas.DrawBox(BL, MenuHeight-180);
	}

	MenuCanvas.SetDrawColorStruct(TextColor); //Orange by default in config (255,128,0,255)

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

// Updates a global array of playernames (used for player manager menu)
function UpdatePlayerList()
{
	local array<PlayerReplicationInfo> PRIArray;
	local ROPlayerReplicationInfo ROPRI;
    local ROGameReplicationInfo ROGRI;
    local int i;

	PlayerList.Length = 0;

	ROGRI = ROGameReplicationInfo(PC.WorldInfo.GRI);
	ROGRI.GetPRIArray(PRIArray, true);

    // Loops through all PRIs
	for ( i = 0; i < PRIArray.Length; i++ )
	{
		ROPRI = ROPlayerReplicationInfo(PRIArray[i]);
		
		// This check is to verify if we should be on the list & !ROPRI.bIsInactive if we're a legit player and not '<<TeamChatProx>>' or '<<WebAdmin>>' or 'Player'
		if (ROPRI != none && !ROPRI.bIsInactive)
		{
			PlayerList.AddItem(ROPRI.PlayerName);
		}
        if(bCMenuDebug) `Log("UpdatePlayerList()"$ROPRI.PlayerName);
	}
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
            CMenuBase(PC.Interactions[i]).bDrawBackground = bDrawBackground;
			CMenuBase(PC.Interactions[i]).SaveConfig();
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
            CMenuBase(PC.Interactions[i]).bKeepOpen = bKeepOpen;
			CMenuBase(PC.Interactions[i]).SaveConfig();
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
    bCMenuDebug=true
	MenuName="CMENUBASE"

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

	DefaultTexture_Black=Texture2D'EngineResources.Black'
	DefaultTexture_White=Texture2D'EngineResources.WhiteSquareTexture'

	//Assigns the delegate to our Input function
	OnReceivedNativeInputKey=InputKey
}
class CMenu extends Interaction
	config(MutCMenu_Client);

var PlayerController PC;
var DummyActor MyDA;
// Text-entry dialog (GameUIScene) disabled for now: commands are typed into the console instead
// var CMenuTextEntryScene TextEntryScene;
var Texture2D DefaultTexture_Black, DefaultTexture_White;
var string PendingCmdPrefix, PendingCmdSuffix;

const ITEMS_PER_PAGE = 8;
const FORM_MAX_VALUE = 80; // the longest value that can be typed in a form box
const FORM_MARGIN = 20;    // the least gap (at 1440p) the form keeps from the top and bottom of the screen
// Every menu is drawn the same size: this wide (the widest of the menu's own lines is used when one is wider still) and tall
// enough for a full page. A long entry is better shortened than left to widen the menu.
const MENU_WIDTH_TEXT = "8. Copy Held Weapon To Clipboard";
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
var bool bAltDown; // click mode: Alt is held, so the mouse looks around (and, placing, a click places) instead of moving the pointer
var array<string> MenuText, MenuCommand, PlayerList;

// Option forms (mouse click mode): a command that needs options opens a form instead of pre-typing it in the console
struct FormField
{
	var string Name;       // "grid" for --grid
	var string Desc;
	var string Value;      // what was typed; for an on/off option anything but "" means on
	var bool bSwitch;      // an on/off option: it has no value, only the option itself
	var float X, Y, W, H;  // the text box (or button), as last drawn
};
var array<FormField> FormFields;
var array<string> FormNotes, FormExamples;
var string FormTitle, FormPrefix, FormSuffix;
var int FormFocus;
var float RunX, RunY, RunW, RunH, CancelX, CancelY, CancelW, CancelH; // the two buttons, as last drawn
var bool bFormShift;
var name NumberKeys[20];

var config Color TextColor, BackgroundColor, BorderColor;
var config bool bKeepOpen, bDrawBackground, bCMenuDebug;

simulated state MenuVisible
{
	function BeginState(name PreviousStateName)
	{
		RestoreDefaultEntries(); // Whatever a previous opening added (admin entries, mod vehicles) is not carried over
		Initialize();
		bCursorPlaced = false; // placed again where the last menu left it (see DrawClickCursor)
		bClickPressOwned = false;
		bAltDown = false;
	}

	function bool InputKey( int ControllerId, name Key, EInputEvent EventType, float AmountDepressed = 1.f, bool bGamepad = FALSE )
	{
		// Mouse click mode: Alt held lets the mouse look around. The key is taken, so the game doesn't make the player go prone.
		if (ClickActive() && (Key == 'LeftAlt' || Key == 'RightAlt'))
		{
			if (EventType == IE_Pressed)
				bAltDown = true;
			else if (EventType == IE_Released)
				bAltDown = false;
			return true;
		}

		// Mouse click mode: the left button picks the line under the pointer. The press and its release are both
		// taken, so the click never fires the player's weapon.
		if (PointerActive() && Key == 'LeftMouseButton')
			return ClickPointer(EventType);

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
		if (!PointerActive())
			return false;

		if (Key == 'MouseX')
			CursorPos.X += Delta;
		else if (Key == 'MouseY')
			CursorPos.Y -= Delta; // mouse up is positive, the screen's Y grows downwards
		else
			return false;

		KeepCursorOnScreen();
		RememberCursor();
		return true;
	}

	function PostRender(Canvas HUDCanvas)
    {
		UpdateMenuScale(HUDCanvas.ClipY);
		ScreenW = HUDCanvas.ClipX;
		ScreenH = HUDCanvas.ClipY;
	    DrawMenu(ROCanvas(HUDCanvas), 0, MENU_TOP * MenuScale, MenuName, MenuText);
		if (ClickActive())
		{
			DrawClickCursor(ROCanvas(HUDCanvas));
			DrawClickHint(ROCanvas(HUDCanvas));
		}
    }

	function EndState(name NextStateName)
	{
		bClickPressOwned = false;
		bAltDown = false;

		if (NextStateName != 'ReadyToPlace')
			RestoreDefaultEntries();
	}
}

// The option form: rows of options with a text box each, and Run and Cancel. A blank option is left out of the command, so the
// command uses its default. The mouse moves the pointer as in the menu; typing goes into the box that was clicked.
simulated state FormVisible
{
	function BeginState(name PreviousStateName)
	{
		bCursorPlaced = false;
		bClickPressOwned = false;
		bFormShift = false;
	}

	function EndState(name NextStateName)
	{
		bClickPressOwned = false;
	}

	function bool InputKey( int ControllerId, name Key, EInputEvent EventType, float AmountDepressed = 1.f, bool bGamepad = FALSE )
	{
		local int Hit;

		if (Key == 'LeftShift' || Key == 'RightShift')
		{
			bFormShift = EventType != IE_Released;
			return false;
		}

		if (Key == 'LeftMouseButton')
		{
			if (EventType == IE_Pressed || EventType == IE_DoubleClick)
			{
				bClickPressOwned = true;
				ClickForm();
				return true;
			}
			if (EventType == IE_Released && bClickPressOwned)
			{
				bClickPressOwned = false;
				return true;
			}
			return false;
		}

		// Releases always go through, so a movement key held while the form opened doesn't get stuck
		if (EventType == IE_Released)
			return false;
		// The console key and the function keys (often bound to open menus) still work
		if (FormPassesKey(Key))
			return false;
		if (EventType != IE_Pressed && EventType != IE_Repeat)
			return true;

		if (Key == 'Enter')
		{
			RunForm();
			return true;
		}
		if (Key == 'Escape')
		{
			CancelForm();
			return true;
		}
		if (Key == 'Tab')
		{
			if (FormFields.Length > 0)
				FormFocus = (FormFocus + 1) % FormFields.Length;
			return true;
		}
		if (FormFocus >= 0 && FormFocus < FormFields.Length && !FormFields[FormFocus].bSwitch)
		{
			if (Key == 'BackSpace')
				FormFields[FormFocus].Value = Left(FormFields[FormFocus].Value, Len(FormFields[FormFocus].Value) - 1);
			else
			{
				Hit = Len(FormFields[FormFocus].Value);
				if (Hit < FORM_MAX_VALUE)
					FormFields[FormFocus].Value $= class'CMMapInteraction'.static.KeyChar(Key, bFormShift);
			}
		}
		return true;
	}

	function bool InputAxis( int ControllerId, name Key, float Delta, float DeltaTime, optional bool bGamepad )
	{
		if (Key == 'MouseX')
			CursorPos.X += Delta;
		else if (Key == 'MouseY')
			CursorPos.Y -= Delta;
		else
			return false;

		KeepCursorOnScreen();
		RememberCursor();
		return true;
	}

	function PostRender(Canvas HUDCanvas)
	{
		UpdateMenuScale(HUDCanvas.ClipY);
		ScreenW = HUDCanvas.ClipX;
		ScreenH = HUDCanvas.ClipY;
		DrawForm(ROCanvas(HUDCanvas));
		DrawClickCursor(ROCanvas(HUDCanvas), true);
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
			// Close Menu, unless the command is waiting for something: a form to be filled in, or a Builder item to be placed
			if (!bKeepOpen && !IsInState('FormVisible') && !IsInState('ReadyToPlace')) GotoState('');
			return true;
		}
		PC.ConsoleCommand("mutate "$Command); //Execute Command
		if (!bKeepOpen && !IsInState('ReadyToPlace')) GotoState(''); // Close Menu (a Builder item waits to be placed)
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

// Finds the longest string on the menu (every page, and the title), which only matters when it is wider than the standard
// menu width
function FindCMenuLength()
{
	local int i, MenuTextMaxLength;

	MenuBorderLengthString = MenuName;
	MenuTextMaxLength = Len(MenuName);
	for (i = 0; i < MenuText.Length; i++)
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
// FormOptions names the command's options for the form in mouse click mode, in order, separated by commas; a name ending in
// "!" is an on/off option (for example "team,flag,nobeam!"). Their descriptions come from the "--option : ..." lines of Prompt.
function PromptForText(string Prompt, string CommandPrefix, optional string CommandSuffix, optional string FormOptions)
{
	PendingCmdPrefix = CommandPrefix;
	PendingCmdSuffix = CommandSuffix;

	// Mouse click mode: a form with a box for each option, instead of typing the command in the console
	if (ClickActive() && OpenForm(Prompt, CommandPrefix, CommandSuffix, FormOptions))
		return;

	// Short guidance goes to the chat and the mini console, long guidance to the large console (see DummyActor.ShowHelp)
	if (MyDA != None)
		MyDA.ShowHelp(Prompt, CommandPrefix, CommandSuffix, "[CMenu] ");
}

// ====================================================
// Option forms
// ====================================================

function string TrimSpaces(string S)
{
	while (Left(S, 1) == " ")
		S = Mid(S, 1);
	while (Right(S, 1) == " ")
		S = Left(S, Len(S) - 1);
	return S;
}

function int FindFormField(string OptionName)
{
	local int i;

	for (i = 0; i < FormFields.Length; i++)
	{
		if (FormFields[i].Name ~= OptionName)
			return i;
	}
	return INDEX_NONE;
}

// Opens the form for a command: a row for each option in Options (see PromptForText), described by the guidance the console
// would show (lines separated by "|": a title, notes, "--option / -o : what it does" lines, examples). Without Options the
// rows are read from the guidance itself, as text boxes. False when there is no option, so the console is used.
function bool OpenForm(string Prompt, string Prefix, string Suffix, optional string Options)
{
	local array<string> Lines, Names;
	local array<FormField> Read;
	local FormField Field;
	local int i, Found;
	local string Line;

	FormFields.Length = 0;
	FormNotes.Length = 0;
	FormExamples.Length = 0;
	FormPrefix = Prefix;
	FormSuffix = Suffix;
	FormFocus = 0;

	Lines = SplitString(Prompt, "|", true);
	FormTitle = Lines.Length > 0 ? Lines[0] : "";
	for (i = 1; i < Lines.Length; i++)
	{
		Line = Lines[i];
		if (Left(Line, 7) ~= "Example")
		{
			if (FormExamples.Length < 2)
				FormExamples.AddItem(Line);
		}
		else if (Left(Line, 10) ~= "Older form" || Left(Line, 12) ~= "Full command")
		{
			// Only for the console
		}
		else if (Left(Line, 2) == "--" || Left(Line, 8) ~= "Options:" || InStr(Line, " --") != INDEX_NONE)
			AddFormFields(Line);
		else if (FormFields.Length == 0 && FormNotes.Length < 3)
			FormNotes.AddItem(Line);
	}

	// The options named by the menu decide the rows and which are on/off; the guidance only describes them
	if (Options != "")
	{
		Read = FormFields;
		FormFields.Length = 0;
		Names = SplitString(Options, ",", true);
		for (i = 0; i < Names.Length; i++)
		{
			Field.Name = TrimSpaces(Names[i]);
			Field.bSwitch = Right(Field.Name, 1) == "!";
			if (Field.bSwitch)
				Field.Name = Left(Field.Name, Len(Field.Name) - 1);
			Field.Desc = "";
			for (Found = 0; Found < Read.Length; Found++)
			{
				if (Read[Found].Name ~= Field.Name)
				{
					Field.Desc = Read[Found].Desc;
					break;
				}
			}
			if (Field.Name != "" && FindFormField(Field.Name) == INDEX_NONE)
				FormFields.AddItem(Field);
		}
	}

	if (FormFields.Length == 0)
		return false;

	GotoState('FormVisible');
	return true;
}

// Adds a row for every "--name" in the line. An option listed without a description of its own (several named in one line
// before the ":") takes the one the line ends with.
function AddFormFields(string Line)
{
	local int Pos, Next, First, i;
	local string Chunk, Rest;

	First = FormFields.Length;
	Pos = InStr(Line, "--");
	while (Pos != INDEX_NONE)
	{
		Rest = Mid(Line, Pos + 2);
		Next = InStr(Rest, " --");
		if (Next != INDEX_NONE)
		{
			Chunk = Left(Rest, Next);
			Line = Mid(Rest, Next + 1);
		}
		else
		{
			Chunk = Rest;
			Line = "";
		}
		AddFormField(Chunk);

		// "--text / -t, --background / -b, --border / -o : the colour": the ones named before the ":" share its description
		if (InStr(Chunk, " : ") != INDEX_NONE)
		{
			for (i = FormFields.Length - 2; i >= First && FormFields[i].Desc == ""; i--)
				FormFields[i].Desc = FormFields[FormFields.Length - 1].Desc;
		}
		Pos = InStr(Line, "--");
	}
}

// One option from the text after its "--": "grid / -g : what it does", "spread -r (meters)," and so on
function AddFormField(string Chunk)
{
	local FormField Field;
	local int i, Colon, Open;
	local string Ch, Rest, Desc;

	for (i = 0; i < Len(Chunk); i++)
	{
		Ch = Mid(Chunk, i, 1);
		if (Ch == " " || Ch == "/" || Ch == "," || Ch == ":" || Ch == ")")
			break;
	}
	Field.Name = Left(Chunk, i);
	if (Field.Name == "" || FindFormField(Field.Name) != INDEX_NONE)
		return;

	Rest = Mid(Chunk, i);
	Colon = InStr(Rest, " : ");
	if (Colon != INDEX_NONE)
		Desc = Mid(Rest, Colon + 3);
	else
	{
		// "-s (what it means)": the words in brackets
		Open = InStr(Rest, "(");
		if (Open != INDEX_NONE)
			Desc = Mid(Rest, Open + 1);
	}
	Colon = InStr(Desc, "   ");
	if (Colon != INDEX_NONE)
		Desc = Left(Desc, Colon);
	Desc = TrimSpaces(Desc);
	while (Right(Desc, 1) == "," || Right(Desc, 1) == ")" || Right(Desc, 1) == ":")
		Desc = Left(Desc, Len(Desc) - 1);

	Field.Desc = Desc;
	FormFields.AddItem(Field);
}

// The command to run: the prefix (without a trailing "--option " the form has a row for), then the options that were filled in
function string BuildFormCommand()
{
	local string Cmd, LastWord;
	local int Space, i;

	Cmd = TrimSpaces(FormPrefix);
	Space = InStr(Cmd, " ", true);
	LastWord = Space != INDEX_NONE ? Mid(Cmd, Space + 1) : Cmd;
	if (Left(LastWord, 2) == "--" && FindFormField(Mid(LastWord, 2)) != INDEX_NONE)
		Cmd = TrimSpaces(Left(Cmd, Space));

	for (i = 0; i < FormFields.Length; i++)
	{
		if (FormFields[i].bSwitch)
		{
			if (FormFields[i].Value != "")
				Cmd = Cmd $ " --" $ FormFields[i].Name;
		}
		else if (TrimSpaces(FormFields[i].Value) != "")
			Cmd = Cmd $ " --" $ FormFields[i].Name $ " " $ TrimSpaces(FormFields[i].Value);
	}
	return Cmd $ FormSuffix;
}

function RunForm()
{
	local string Cmd;

	Cmd = BuildFormCommand();
	// A command that opens a menu (the Builder's Custom items) toggles it: closed first, so it opens rather than closes
	if (bKeepOpen && Left(Locs(Cmd), 12) != "mutate cmenu")
		GotoState('MenuVisible');
	else
		GotoState('');
	PC.ConsoleCommand(Cmd);
}

function CancelForm()
{
	GotoState('MenuVisible');
}

// A left click on the form: a box takes the typing, a switch flips, and the buttons run or cancel
function ClickForm()
{
	local int i;

	for (i = 0; i < FormFields.Length; i++)
	{
		if (CursorPos.X >= FormFields[i].X && CursorPos.X <= FormFields[i].X + FormFields[i].W
			&& CursorPos.Y >= FormFields[i].Y && CursorPos.Y <= FormFields[i].Y + FormFields[i].H)
		{
			FormFocus = i;
			if (FormFields[i].bSwitch)
				FormFields[i].Value = (FormFields[i].Value == "") ? "1" : "";
			return;
		}
	}

	if (CursorPos.X >= RunX && CursorPos.X <= RunX + RunW && CursorPos.Y >= RunY && CursorPos.Y <= RunY + RunH)
		RunForm();
	else if (CursorPos.X >= CancelX && CursorPos.X <= CancelX + CancelW && CursorPos.Y >= CancelY && CursorPos.Y <= CancelY + CancelH)
		CancelForm();
}

// Keys the form leaves to the game: the console key, and F1 to F12
function bool FormPassesKey(name Key)
{
	local LocalPlayer LP;
	local string S;

	LP = (PC != None) ? LocalPlayer(PC.Player) : None;
	if (LP != None && LP.ViewportClient != None && LP.ViewportClient.ViewportConsole != None
		&& Key == LP.ViewportClient.ViewportConsole.ConsoleKey)
		return true;

	S = string(Key);
	return Left(S, 1) == "F" && Len(S) >= 2 && Len(S) <= 3 && int(Mid(S, 1)) >= 1 && int(Mid(S, 1)) <= 12;
}

// Text cut short with ... so it fits the width at the scale
function string FitText(ROCanvas C, string Text, float MaxW, float Scale)
{
	local float W, H;

	C.TextSize(Text, W, H);
	if (W * Scale <= MaxW)
		return Text;

	while (Len(Text) > 1)
	{
		Text = Left(Text, Len(Text) - 1);
		C.TextSize(Text $ "...", W, H);
		if (W * Scale <= MaxW)
			break;
	}
	return Text $ "...";
}

// Lays the form out for this screen and draws it: first the background and boxes, then the text on them (the same two
// layers DrawMenu uses, or the text can end up under the boxes)
function DrawForm(ROCanvas C)
{
	local float S, PanelX, PanelY, PanelW, PanelH, Pad, LineH, DescH, LabelW, BoxX, BoxW, Y, TW, TH, TitleScale, LabelScale, DescScale, ValueScale, ButtonW, Now;
	local float FullH, Margin;
	local int i;
	local bool bHover;
	local string Shown;

	if (C == None)
		return;

	// A form with many options (fire support has a dozen) would run off the bottom of the screen: it moves up first, and
	// is drawn smaller when it still doesn't fit. FullH is its height at a scale of 1, as the rows below lay it out.
	S = MenuScale;
	Margin = FORM_MARGIN * MenuScale;
	FullH = TEXT_OFFSET + LINE_HEIGHT + FormNotes.Length * 26 + FormFields.Length * (LINE_HEIGHT + 26 + 4) + FormExamples.Length * 26
		+ TEXT_OFFSET + LINE_HEIGHT * 0.9 + TEXT_OFFSET;
	if (FullH * S > C.ClipY - Margin * 2)
		S = FMax(0.1, (C.ClipY - Margin * 2) / FullH);
	Pad = TEXT_OFFSET * S;
	LineH = LINE_HEIGHT * S;
	DescH = 26 * S;
	TitleScale = S;
	LabelScale = S * 0.8;
	ValueScale = S * 0.8;
	DescScale = S * 0.5;
	PanelX = 0;
	PanelY = FMax(Margin, FMin(MENU_TOP * MenuScale, C.ClipY - FullH * S - Margin));
	PanelW = 1150 * S;
	LabelW = 280 * S;
	BoxX = PanelX + Pad + LabelW;
	BoxW = PanelW - Pad * 2 - LabelW;
	Now = PC.WorldInfo.RealTimeSeconds;

	C.Font = Font'VN_UI_Mega_Fonts.Font_VN_Mega_36';

	// Rows
	Y = PanelY + Pad + LineH + FormNotes.Length * DescH;
	for (i = 0; i < FormFields.Length; i++)
	{
		FormFields[i].X = FormFields[i].bSwitch ? PanelX + Pad : BoxX;
		FormFields[i].Y = Y;
		FormFields[i].W = FormFields[i].bSwitch ? 340 * S : BoxW;
		FormFields[i].H = LineH * 0.9;
		Y += LineH + DescH + 4 * S;
	}
	Y += FormExamples.Length * DescH;
	ButtonW = 200 * S;
	RunX = PanelX + Pad;
	RunY = Y + Pad;
	RunW = ButtonW;
	RunH = LineH * 0.9;
	CancelX = RunX + ButtonW + Pad * 2;
	CancelY = RunY;
	CancelW = ButtonW;
	CancelH = RunH;
	PanelH = RunY + RunH + Pad - PanelY;

	// Boxes
	C.PushDepthSortPriority(DSP_SkyHigh);
	C.SetPos(PanelX, PanelY);
	C.SetDrawColorStruct(BackgroundColor);
	C.DrawRect(PanelW, PanelH);
	C.SetPos(PanelX, PanelY);
	C.SetDrawColorStruct(BorderColor);
	C.DrawBox(PanelW, PanelH);
	for (i = 0; i < FormFields.Length; i++)
	{
		bHover = CursorPos.X >= FormFields[i].X && CursorPos.X <= FormFields[i].X + FormFields[i].W
			&& CursorPos.Y >= FormFields[i].Y && CursorPos.Y <= FormFields[i].Y + FormFields[i].H;
		if (FormFields[i].bSwitch && FormFields[i].Value != "")
			C.SetDrawColor(40, 130, 60, 235);
		else
			C.SetDrawColor(bHover ? 70 : 30, bHover ? 70 : 30, bHover ? 70 : 30, 235);
		C.SetPos(FormFields[i].X, FormFields[i].Y);
		C.DrawRect(FormFields[i].W, FormFields[i].H);
		if (i == FormFocus)
			C.SetDrawColor(255, 200, 40, 255);
		else
			C.SetDrawColor(120, 120, 120, 255);
		C.SetPos(FormFields[i].X, FormFields[i].Y);
		C.DrawBox(FormFields[i].W, FormFields[i].H);
	}
	bHover = CursorPos.X >= RunX && CursorPos.X <= RunX + RunW && CursorPos.Y >= RunY && CursorPos.Y <= RunY + RunH;
	C.SetDrawColor(bHover ? 60 : 35, bHover ? 170 : 130, bHover ? 80 : 55, 240);
	C.SetPos(RunX, RunY);
	C.DrawRect(RunW, RunH);
	bHover = CursorPos.X >= CancelX && CursorPos.X <= CancelX + CancelW && CursorPos.Y >= CancelY && CursorPos.Y <= CancelY + CancelH;
	C.SetDrawColor(bHover ? 190 : 140, bHover ? 50 : 35, bHover ? 45 : 30, 240);
	C.SetPos(CancelX, CancelY);
	C.DrawRect(CancelW, CancelH);
	C.PopDepthSortPriority();

	// Text
	C.PushDepthSortPriority(DSP_Insane);
	C.SetDrawColorStruct(TextColor);
	C.SetPos(PanelX + Pad, PanelY + Pad);
	C.DrawText(FormTitle, false, TitleScale, TitleScale);

	Y = PanelY + Pad + LineH;
	C.SetDrawColor(220, 220, 220, 255);
	for (i = 0; i < FormNotes.Length; i++)
	{
		C.SetPos(PanelX + Pad, Y);
		C.DrawText(FitText(C, FormNotes[i], PanelW - Pad * 2, DescScale), false, DescScale, DescScale);
		Y += DescH;
	}

	for (i = 0; i < FormFields.Length; i++)
	{
		// The option's name, or for an on/off option its button text
		if (FormFields[i].bSwitch)
		{
			C.SetDrawColor(255, 255, 255, 255);
			C.TextSize("--" $ FormFields[i].Name $ (FormFields[i].Value != "" ? "  (on)" : "  (off)"), TW, TH);
			C.SetPos(FormFields[i].X + 8 * S, FormFields[i].Y + (FormFields[i].H - TH * LabelScale) * 0.5);
			C.DrawText("--" $ FormFields[i].Name $ (FormFields[i].Value != "" ? "  (on)" : "  (off)"), false, LabelScale, LabelScale);
		}
		else
		{
			C.SetDrawColorStruct(TextColor);
			C.TextSize("--" $ FormFields[i].Name, TW, TH);
			C.SetPos(PanelX + Pad, FormFields[i].Y + (FormFields[i].H - TH * LabelScale) * 0.5);
			C.DrawText("--" $ FormFields[i].Name, false, LabelScale, LabelScale);

			Shown = FormFields[i].Value;
			if (i == FormFocus && int(Now * 2.0) % 2 == 0)
				Shown $= "_";
			C.SetDrawColor(255, 255, 255, 255);
			C.TextSize("Ag", TW, TH);
			// The end of what was typed, when it is too long for the box
			Shown = FitTail(C, Shown, FormFields[i].W - 16 * S, ValueScale);
			C.SetPos(FormFields[i].X + 8 * S, FormFields[i].Y + (FormFields[i].H - TH * ValueScale) * 0.5);
			C.DrawText(Shown, false, ValueScale, ValueScale);
		}

		// What it does, under the row
		C.SetDrawColor(180, 180, 180, 255);
		C.SetPos(PanelX + Pad, FormFields[i].Y + LineH);
		C.DrawText(FitText(C, FormFields[i].Desc != "" ? FormFields[i].Desc : "(leave blank for the default)", PanelW - Pad * 2, DescScale), false, DescScale, DescScale);
	}

	Y = FormFields[FormFields.Length - 1].Y + LineH + DescH + 4 * S;
	C.SetDrawColor(150, 200, 255, 255);
	for (i = 0; i < FormExamples.Length; i++)
	{
		C.SetPos(PanelX + Pad, Y);
		C.DrawText(FitText(C, FormExamples[i], PanelW - Pad * 2, DescScale), false, DescScale, DescScale);
		Y += DescH;
	}

	C.SetDrawColor(255, 255, 255, 255);
	C.TextSize("Run", TW, TH);
	C.SetPos(RunX + (RunW - TW * LabelScale) * 0.5, RunY + (RunH - TH * LabelScale) * 0.5);
	C.DrawText("Run", false, LabelScale, LabelScale);
	C.TextSize("Cancel", TW, TH);
	C.SetPos(CancelX + (CancelW - TW * LabelScale) * 0.5, CancelY + (CancelH - TH * LabelScale) * 0.5);
	C.DrawText("Cancel", false, LabelScale, LabelScale);
	C.PopDepthSortPriority();
}

// The end of the text when all of it is too wide for the width at the scale
function string FitTail(ROCanvas C, string Text, float MaxW, float Scale)
{
	local float W, H;

	C.TextSize(Text, W, H);
	while (W * Scale > MaxW && Len(Text) > 1)
	{
		Text = Mid(Text, 1);
		C.TextSize(Text, W, H);
	}
	return Text;
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

// True when this menu is open and has taken the mouse for its pointer; CMMapInputHook leaves the clicks to it then. Not
// while Alt is held: the mouse looks around then.
function bool HasMousePointer()
{
	return IsInState('FormVisible') || (PointerActive() && IsInState('MenuVisible'));
}

// Click mode, and Alt is not held: the mouse moves the pointer and a click picks a line
function bool PointerActive()
{
	return ClickActive() && !bAltDown;
}

// A press or release of the left button with the pointer: the press picks the line under it, and the release is taken too
function bool ClickPointer(EInputEvent EventType)
{
	local int Hit;

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

// Keeps the pointer's place for the next menu that opens
function RememberCursor()
{
	if (MyDA != None)
	{
		MyDA.ClickCursor = CursorPos;
		MyDA.bClickCursorKnown = true;
	}
}

// A line under the menu telling the player what Alt does, while a builder preview is up (the only time it also places)
function DrawClickHint(ROCanvas C)
{
	local float X, Y, XL, YL;
	local string Hint;

	if (C == None || !IsInState('ReadyToPlace'))
		return;

	Hint = bAltDown ? "Alt held: look around, click to place" : "Hold Alt: look around and place";
	C.Font = Font'VN_UI_Mega_Fonts.Font_VN_Mega_36';
	C.TextSize(Hint, XL, YL);
	X = TEXT_OFFSET * MenuScale;
	Y = MenuHeight + 80 * MenuScale;
	C.PushDepthSortPriority(DSP_Insane);
	C.SetDrawColor(255, 255, 255, 255);
	C.SetPos(X, Y);
	C.DrawText(Hint, false, MenuScale * 0.6, MenuScale * 0.6);
	C.PopDepthSortPriority();
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

	// Below a full page whatever this page holds, so Next and Exit are always in the same place
	LineY += ITEMS_PER_PAGE * H;
	W = 200.f * MenuScale;
	if (Slot == ITEMS_PER_PAGE)
	{
		if (!bNext)
			return false;
		Y = LineY + 2 * H;
		return true;
	}

	Y = LineY + 4 * H;
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
function DrawClickCursor(ROCanvas C, optional bool bNoHighlight)
{
	local int Hit, Slot;
	local float X, Y, W, H, Size;
	local ROHUD HUD;
	local ROHUDWidgetComponent Pointer;

	if (C == None)
		return;

	if (!bCursorPlaced && MyDA != None && MyDA.bClickCursorKnown)
	{
		// Where the last menu left it, so moving to another menu doesn't jump it
		CursorPos = MyDA.ClickCursor;
		bCursorPlaced = true;
	}
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
	RememberCursor();

	Hit = bNoHighlight ? -1 : LineAt(CursorPos.X, CursorPos.Y);
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
	local float BL, BH, StandardBL, height, X, Y, FirstLineY;

	height = LINE_HEIGHT * MenuScale;
	key = 1;

	// Where the Exit line will be: every menu is as tall as a full page, so this is known before anything is drawn
	MenuHeight = MenuY + TEXT_OFFSET * MenuScale + (title != "" ? height : 0.0) + (ITEMS_PER_PAGE + 4) * height;

	MenuCanvas.Font = Font'VN_UI_Mega_Fonts.Font_VN_Mega_36';

	if (bDrawBackground)
	{
		MenuCanvas.PushDepthSortPriority(DSP_SkyHigh); // If we don't do this the text will disappear when hovering over a player due to the playername
		// The same width for every menu: the standard one, or this menu's own widest line when that is wider
		MenuCanvas.StrLen("-----"$MENU_WIDTH_TEXT, StandardBL, BH);
		MenuCanvas.StrLen("-----"$MenuBorderLengthString, BL, BH);
		BL = FMax(BL, StandardBL) * MenuScale;
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

	FirstLineY = Y;
	for( i = MenuPage * ITEMS_PER_PAGE; i < Min((MenuPage+1)*ITEMS_PER_PAGE, LineText.Length); i++ )
	{
		MenuCanvas.SetPos(X, Y);
		MenuCanvas.DrawText(key $ ". " $ LineText[i], false, MenuScale, MenuScale);
		key++;
		Y += height; // next line
	}

	// Next and Exit sit below a full page whatever this one holds, so every menu is the same height
	Y = FirstLineY + ITEMS_PER_PAGE * height;

	// 9. Next Page
	if(LineText.Length > ((MenuPage+1)*ITEMS_PER_PAGE))
	{
		MenuCanvas.SetPos(X, Y + height*2);
		MenuCanvas.DrawText("9. Next", false, MenuScale, MenuScale);
	}

	// 0. Exit Menu
	Y += height*4;
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

// Mouse click mode on or off (CMenu Settings), and a message saying how it works
function ToggleClickMode()
{
	if (MyDA == None)
		return;

	MyDA.bClickModeActive = !MyDA.bClickModeActive;
	MyDA.bClickCursorKnown = false; // a fresh start on the first line
	if (!MyDA.bClickModeActive)
	{
		MessageSelf("[CMenu] Mouse click mode is off. Pick menu lines with the number keys again.");
		return;
	}
	MessageSelf("[CMenu] Mouse click mode is on. While a menu is open, the mouse moves a pointer: left click a line to pick it.");
	MessageSelf("[CMenu] Commands that need options open a form: click a box, type the value (leave it blank for the default), then click Run.");
	MessageSelf("[CMenu] Hold Alt to look around and use the map without picking menu lines. In the Builder, Alt + left click places what you are holding.");
	MessageSelf("[CMenu] Turn it off again in CMenu Settings.");
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
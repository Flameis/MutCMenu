// Code-built UIScene used as a reusable modal text-entry dialog for CMenu commands.
// DISABLED for now: CMenu prints guidance and the console command instead (see CMenu.PromptForText).
// The class declaration stays so the package still compiles; the body below is commented out.
class CMenuTextEntryScene extends UIScene;

/*
// The prompt may hold several lines separated by "|" (a title, option help, an example).

const MAX_PROMPT_LINES = 6;

var UILabel PromptLabels[6];
var UIEditBox InputField;
var UIButton OKButton, CancelButton;
var bool bWidgetsBuilt;

delegate bool OnTextEntered(string EnteredText, bool bCancelled);

function BuildWidgets()
{
	local int i;

	if (bWidgetsBuilt)
		return;

	for (i = 0; i < MAX_PROMPT_LINES; i++)
	{
		PromptLabels[i] = UILabel(CreateWidget(Self, class'UILabel'));
		PositionBox(PromptLabels[i], 300.f, 200.f + (i * 28.f), 1100.f, 226.f + (i * 28.f));
	}

	InputField = UIEditBox(CreateWidget(Self, class'UIEditBox'));
	PositionBox(InputField, 300.f, 376.f, 1100.f, 416.f);
	InputField.MaxCharacters = 200;
	InputField.OnSubmitText = OnInputFieldSubmit;

	OKButton = UIButton(CreateWidget(Self, class'UIButton'));
	PositionBox(OKButton, 300.f, 426.f, 430.f, 466.f);
	OKButton.OnClicked = OnOKClicked;

	CancelButton = UIButton(CreateWidget(Self, class'UIButton'));
	PositionBox(CancelButton, 440.f, 426.f, 570.f, 466.f);
	CancelButton.OnClicked = OnCancelClicked;

	bWidgetsBuilt = true;
}

// Absolute viewport-pixel positioning; runtime-created widgets have no docking/layout to inherit
function PositionBox(UIObject Widget, float Left, float Top, float Right, float Bottom)
{
	Widget.SetPosition(Left, UIFACE_Left, EVALPOS_PixelViewport);
	Widget.SetPosition(Top, UIFACE_Top, EVALPOS_PixelViewport);
	Widget.SetPosition(Right, UIFACE_Right, EVALPOS_PixelViewport);
	Widget.SetPosition(Bottom, UIFACE_Bottom, EVALPOS_PixelViewport);
}

function Configure(string Prompt, string InitialValue, delegate<OnTextEntered> Callback)
{
	local array<string> Lines;
	local int i;

	BuildWidgets();
	OnTextEntered = Callback;

	Lines = SplitString(Prompt, "|", false);
	for (i = 0; i < MAX_PROMPT_LINES; i++)
	{
		PromptLabels[i].SetValue(i < Lines.Length ? Lines[i] : "");
	}

	InputField.SetValue(InitialValue);
	SetFocusToChild(InputField);
}

function bool OnInputFieldSubmit(UIEditBox Sender, int PlayerIndex)
{
	OnTextEntered(Sender.GetValue(true), false);
	return true;
}

function bool OnOKClicked(UIScreenObject EventObject, int PlayerIndex)
{
	OnTextEntered(InputField.GetValue(true), false);
	return true;
}

function bool OnCancelClicked(UIScreenObject EventObject, int PlayerIndex)
{
	OnTextEntered("", true);
	return true;
}

defaultproperties
{
	bPauseGameWhileActive=false
}
*/

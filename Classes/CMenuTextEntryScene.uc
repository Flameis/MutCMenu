// Code-built UIScene used as a reusable modal text-entry dialog for CMenu commands.
class CMenuTextEntryScene extends UIScene;

var UILabel PromptLabel;
var UIEditBox InputField;
var UIButton OKButton, CancelButton;
var bool bWidgetsBuilt;

delegate bool OnTextEntered(string EnteredText, bool bCancelled);

function BuildWidgets()
{
	if (bWidgetsBuilt)
		return;

	PromptLabel = UILabel(CreateWidget(Self, class'UILabel'));
	PositionBox(PromptLabel, 300.f, 260.f, 724.f, 300.f);

	InputField = UIEditBox(CreateWidget(Self, class'UIEditBox'));
	PositionBox(InputField, 300.f, 310.f, 724.f, 350.f);
	InputField.MaxCharacters = 64;
	InputField.OnSubmitText = OnInputFieldSubmit;

	OKButton = UIButton(CreateWidget(Self, class'UIButton'));
	PositionBox(OKButton, 300.f, 360.f, 430.f, 400.f);
	OKButton.OnClicked = OnOKClicked;

	CancelButton = UIButton(CreateWidget(Self, class'UIButton'));
	PositionBox(CancelButton, 440.f, 360.f, 570.f, 400.f);
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
	BuildWidgets();
	OnTextEntered = Callback;
	PromptLabel.SetValue(Prompt);
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

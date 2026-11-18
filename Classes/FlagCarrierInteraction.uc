// For whoever carries a Capture the Flag flag (CMAFlag): a banner on their screen saying so, and a key that drops the flag
// at once. Like TankEntryInteraction it is an Interaction, so it draws and takes the key whatever HUD class the game (or
// WW2, Winter War, GOM) uses. The key is only taken while a flag is carried, so it does nothing else the rest of the time.
// Dropping goes through DummyActor.DropCarriedFlag(), which runs "mutate dropflag" on the server.
// A flag carried as an item (--place) is planted with the CTF Flag item (CMItem_CTFFlag); the banner says so.
// The key is X unless the player sets another with CMenu's Settings > Set Drop Flag Key, which takes the next key pressed.
// The game only hands keys to a script Interaction through OnReceivedNativeInputKey (set below): without it the banner
// showed but the key did nothing.
class FlagCarrierInteraction extends Interaction
    config(MutCMenu_Client);

var PlayerController PC;
var DummyActor MyDA;
var CMAFlag Carried;        // The flag the player carries, looked for a few times a second
var float NextCheckTime;
var float LastDropTime;

var config name DropFlagKey; // X when not set

var bool bCapturingKey;     // The next key pressed becomes the drop key

const CHECK_INTERVAL = 0.25;
const DROP_COOLDOWN = 0.5;
const TEXT_SCALE = 0.6;     // Banner size next to the full-size font, at 1080p

function name DropKey()
{
    return (DropFlagKey != '') ? DropFlagKey : 'X';
}

// Settings > Set Drop Flag Key: the next key pressed (not Escape, which cancels, or a mouse button) is the drop key
function StartKeyCapture()
{
    bCapturingKey = true;
    PC.ClientMessage("[CMenu] Press the key you want to drop a flag with (Escape to keep "$DropKey()$")");
}

function bool CaptureKey(name Key, EInputEvent EventType)
{
    if (EventType != IE_Pressed)
        return true;
    if (Key == 'LeftMouseButton' || Key == 'RightMouseButton' || Key == 'MiddleMouseButton'
        || Key == 'MouseScrollUp' || Key == 'MouseScrollDown' || Key == 'MouseX' || Key == 'MouseY')
        return false;
    bCapturingKey = false;
    if (Key == 'Escape')
    {
        PC.ClientMessage("[CMenu] The drop flag key stays "$DropKey());
        return true;
    }
    DropFlagKey = Key;
    SaveConfig();
    PC.ClientMessage("[CMenu] Flags are now dropped with "$DropKey());
    return true;
}

function UpdateCarried()
{
    local CMAFlag F;

    if (PC.WorldInfo.TimeSeconds < NextCheckTime)
    {
        // Between looks the flag is only kept while it is still carried by this player
        if (Carried != None && (Carried.bDeleteMe || !Carried.IsCarriedBy(PC.Pawn)))
            Carried = None;
        return;
    }
    NextCheckTime = PC.WorldInfo.TimeSeconds + CHECK_INTERVAL;
    Carried = None;
    if (PC.Pawn != None)
    {
        foreach PC.DynamicActors(class'CMAFlag', F)
        {
            if (F.IsCarriedBy(PC.Pawn)) // on foot, or the vehicle or seat they are in
            {
                Carried = F;
                break;
            }
        }
    }
}

function PostRender(Canvas HUDCanvas)
{
    local string Title, Prompt;
    local float XL, YL, PXL, Pulse, BoxW, BoxH, X, Y, TextScale, UIScale, Border;
    local int Faction;

    if (PC == None)
        return;
    UpdateCarried();
    if (Carried == None)
        return;

    Faction = Clamp(Carried.Faction, 0, class'CMAFlag'.default.Factions.Length - 1);
    Title = "YOU ARE CARRYING THE " $ Caps(class'CMAFlag'.default.Factions[Faction].Label) $ " FLAG";
    if (Carried.bPlaceable)
        Prompt = "Plant it with the CTF Flag item in your equipment, or press [" $ DropKey() $ "] to drop it";
    else
        Prompt = "Press [" $ DropKey() $ "] to drop it";

    // A slow pulse, so it is noticed without being a strobe
    Pulse = 0.5 + 0.5 * Sin(PC.WorldInfo.TimeSeconds * 3.0);

    // Sized for a 1080p screen and scaled with the screen height, so it looks the same at any resolution
    UIScale = HUDCanvas.ClipY / 1080.0;
    TextScale = TEXT_SCALE * UIScale;
    Border = FMax(1.0, 3.0 * UIScale);

    HUDCanvas.Font = Font'VN_UI_Mega_Fonts.Font_VN_Mega_36';
    HUDCanvas.StrLen(Title, XL, YL);
    HUDCanvas.StrLen(Prompt, PXL, YL);
    XL *= TextScale; // StrLen measures at full size
    PXL *= TextScale;
    YL *= TextScale;
    BoxW = FMax(FMax(XL, PXL), 400.0 * UIScale * TEXT_SCALE) + 40.0 * UIScale * TEXT_SCALE;
    BoxH = YL * 2.0 + 30.0 * UIScale * TEXT_SCALE;
    X = (HUDCanvas.ClipX - BoxW) * 0.5;
    Y = HUDCanvas.ClipY * 0.12;

    // A dark banner with a border that pulses gold
    HUDCanvas.SetDrawColor(0, 0, 0, 150);
    HUDCanvas.SetPos(X, Y);
    HUDCanvas.DrawRect(BoxW, BoxH);
    HUDCanvas.SetDrawColor(255, 200, 40, byte(110 + 145 * Pulse));
    HUDCanvas.SetPos(X, Y);
    HUDCanvas.DrawRect(BoxW, Border);
    HUDCanvas.SetPos(X, Y + BoxH - Border);
    HUDCanvas.DrawRect(BoxW, Border);
    HUDCanvas.SetPos(X, Y);
    HUDCanvas.DrawRect(Border, BoxH);
    HUDCanvas.SetPos(X + BoxW - Border, Y);
    HUDCanvas.DrawRect(Border, BoxH);

    HUDCanvas.SetDrawColor(255, 215, 80, 255);
    HUDCanvas.SetPos((HUDCanvas.ClipX - XL) * 0.5, Y + 10.0 * UIScale * TEXT_SCALE);
    HUDCanvas.DrawText(Title, false, TextScale, TextScale);

    HUDCanvas.SetDrawColor(255, 255, 255, 255);
    HUDCanvas.SetPos((HUDCanvas.ClipX - PXL) * 0.5, Y + 20.0 * UIScale * TEXT_SCALE + YL);
    HUDCanvas.DrawText(Prompt, false, TextScale, TextScale);
}

function bool InputKey(int ControllerId, name Key, EInputEvent EventType, float AmountDepressed = 1.f, bool bGamepad = FALSE)
{
    if (bCapturingKey && CaptureKey(Key, EventType))
        return true;

    if (Carried == None || MyDA == None || Key != DropKey())
        return false;

    if (EventType == IE_Pressed && PC.WorldInfo.TimeSeconds - LastDropTime > DROP_COOLDOWN)
    {
        LastDropTime = PC.WorldInfo.TimeSeconds;
        MyDA.DropCarriedFlag();
    }

    // Swallow the key (press and release) while a flag is carried, so the game's own use of it doesn't also happen
    return true;
}

defaultproperties
{
    OnReceivedNativeInputKey=InputKey
}

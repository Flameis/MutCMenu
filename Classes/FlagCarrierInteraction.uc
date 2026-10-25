// For whoever carries a Capture the Flag flag (CMAFlag): a banner on their screen saying so, and a key that drops the flag
// at once. Like TankEntryInteraction it is an Interaction, so it draws and takes the key whatever HUD class the game (or
// WW2, Winter War, GOM) uses. The key is only taken while a flag is carried, so it does nothing else the rest of the time.
// Dropping goes through DummyActor.DropCarriedFlag(), which runs "mutate dropflag" on the server.
class FlagCarrierInteraction extends Interaction
    config(MutCMenu_Client);

var PlayerController PC;
var DummyActor MyDA;
var CMAFlag Carried;        // The flag the player carries, looked for a few times a second
var float NextCheckTime;
var float LastDropTime;

var config name DropFlagKey; // X when not set

const CHECK_INTERVAL = 0.25;
const DROP_COOLDOWN = 0.5;

function name DropKey()
{
    return (DropFlagKey != '') ? DropFlagKey : 'X';
}

function UpdateCarried()
{
    local CMAFlag F;

    if (PC.WorldInfo.TimeSeconds < NextCheckTime)
    {
        // Between looks the flag is only kept while it is still carried by this player
        if (Carried != None && (Carried.bDeleteMe || Carried.Carrier != PC.Pawn))
            Carried = None;
        return;
    }
    NextCheckTime = PC.WorldInfo.TimeSeconds + CHECK_INTERVAL;
    Carried = None;
    if (PC.Pawn == None)
        return;

    foreach PC.DynamicActors(class'CMAFlag', F)
    {
        if (F.Carrier == PC.Pawn)
        {
            Carried = F;
            return;
        }
    }
}

function PostRender(Canvas HUDCanvas)
{
    local string Title, Prompt;
    local float XL, YL, Pulse, BoxW, BoxH, X, Y;
    local int Faction;

    if (PC == None)
        return;
    UpdateCarried();
    if (Carried == None)
        return;

    Faction = Clamp(Carried.Faction, 0, class'CMAFlag'.default.Factions.Length - 1);
    Title = "YOU ARE CARRYING THE " $ Caps(class'CMAFlag'.default.Factions[Faction].Label) $ " FLAG";
    Prompt = "Press [" $ DropKey() $ "] to drop it";

    // A slow pulse, so it is noticed without being a strobe
    Pulse = 0.5 + 0.5 * Sin(PC.WorldInfo.TimeSeconds * 3.0);

    HUDCanvas.Font = Font'VN_UI_Mega_Fonts.Font_VN_Mega_36';
    HUDCanvas.StrLen(Title, XL, YL);
    BoxW = FMax(XL, 400.0) + 40.0;
    BoxH = YL * 2.0 + 30.0;
    X = (HUDCanvas.ClipX - BoxW) * 0.5;
    Y = HUDCanvas.ClipY * 0.12;

    // A dark banner with a border that pulses gold
    HUDCanvas.SetDrawColor(0, 0, 0, 150);
    HUDCanvas.SetPos(X, Y);
    HUDCanvas.DrawRect(BoxW, BoxH);
    HUDCanvas.SetDrawColor(255, 200, 40, byte(110 + 145 * Pulse));
    HUDCanvas.SetPos(X, Y);
    HUDCanvas.DrawRect(BoxW, 3);
    HUDCanvas.SetPos(X, Y + BoxH - 3);
    HUDCanvas.DrawRect(BoxW, 3);
    HUDCanvas.SetPos(X, Y);
    HUDCanvas.DrawRect(3, BoxH);
    HUDCanvas.SetPos(X + BoxW - 3, Y);
    HUDCanvas.DrawRect(3, BoxH);

    HUDCanvas.SetDrawColor(255, 215, 80, 255);
    HUDCanvas.SetPos((HUDCanvas.ClipX - XL) * 0.5, Y + 10.0);
    HUDCanvas.DrawText(Title, false);

    HUDCanvas.SetDrawColor(255, 255, 255, 255);
    HUDCanvas.StrLen(Prompt, XL, YL);
    HUDCanvas.SetPos((HUDCanvas.ClipX - XL) * 0.5, Y + 20.0 + YL);
    HUDCanvas.DrawText(Prompt, false);
}

function bool InputKey(int ControllerId, name Key, EInputEvent EventType, float AmountDepressed = 1.f, bool bGamepad = FALSE)
{
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

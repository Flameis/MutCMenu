// What a game mode (CMGameMode) shows each player: its name, its state and the scores at the top of the screen, the
// player's own line under it (DummyActor.ModeLine), and the names of the mode's places (bomb sites, the convoy's
// destination) over their poles. In the bomb mode it also takes the plant and defuse key (F, the game's use key, unless
// set otherwise) while the player can plant or defuse. An Interaction, so it works with any HUD (WW2, Winter War, GOM).
class CMModeInteraction extends Interaction
    config(MutCMenu_Client);

var PlayerController PC;
var DummyActor MyDA;
var CMGameMode Mode;
var array<CMAModePoint> Points;
var float NextLookTime;
var bool bKeyHeld;

var config name BombKey;    // F when not set

const LOOK_INTERVAL = 1.0;
const LABEL_RANGE = 15000.0;    // 300 m
const DEFUSE_REACH = 150.0;     // as CMModeBomb.DEFUSE_RADIUS

function name PlantKey()
{
    return (BombKey != '') ? BombKey : 'F';
}

static function name DefaultPlantKey()
{
    return (default.BombKey != '') ? default.BombKey : 'F';
}

function LookForMode()
{
    local CMGameMode M;
    local CMAModePoint P;

    if (PC.WorldInfo.RealTimeSeconds < NextLookTime && (Mode == None || !Mode.bDeleteMe))
        return;
    NextLookTime = PC.WorldInfo.RealTimeSeconds + LOOK_INTERVAL;
    Mode = None;
    foreach PC.DynamicActors(class'CMGameMode', M)
    {
        if (!M.bDeleteMe)
            Mode = M;
    }
    Points.Length = 0;
    foreach PC.DynamicActors(class'CMAModePoint', P)
        Points.AddItem(P);
}

function PostRender(Canvas C)
{
    local float UIScale, S, Y, XL, YL;
    local string Line;

    if (PC == None)
        return;
    LookForMode();
    if (Mode == None)
        return;

    UIScale = C.ClipY / 1080.0;
    S = 0.5 * UIScale;
    C.Font = Font'VN_UI_Mega_Fonts.Font_VN_Mega_36';
    Y = C.ClipY * 0.035;

    DrawCentred(C, Mode.ModeTitle, Y, S * 1.1, MakeColor(255, 210, 80, 255));
    C.TextSize("A", XL, YL);
    Y += YL * S * 1.2;
    if (Mode.bShowScore)
    {
        Line = Mode.TeamName(0) $ "  " $ Mode.TeamScore[0] $ "  :  " $ Mode.TeamScore[1] $ "  " $ Mode.TeamName(1);
        DrawCentred(C, Line, Y, S, MakeColor(255, 255, 255, 255));
        Y += YL * S * 1.1;
    }
    if (Mode.StatusText != "")
    {
        DrawCentred(C, Mode.StatusText, Y, S * 0.85, MakeColor(230, 230, 230, 255));
        Y += YL * S * 0.95;
    }
    if (MyDA != None && MyDA.ModeLine != "")
        DrawCentred(C, MyDA.ModeLine, Y, S * 0.85, MakeColor(140, 230, 255, 255));

    DrawPointLabels(C, S * 0.8);
}

function DrawCentred(Canvas C, string Text, float Y, float Scale, color Col)
{
    local float XL, YL;

    C.TextSize(Text, XL, YL);
    class'CMenu'.static.DrawShadowText(C, Text, (C.ClipX - XL * Scale) * 0.5, Y, Scale, Col);
}

// Each mode place's name over its pole, with how far it is
function DrawPointLabels(Canvas C, float Scale)
{
    local CMAModePoint P;
    local vector ViewLoc, Screen, Above;
    local rotator ViewRot;
    local string Label;
    local float XL, YL, Dist;

    PC.GetPlayerViewPoint(ViewLoc, ViewRot);
    foreach Points(P)
    {
        if (P == None || P.bDeleteMe || P.PointLabel == "")
            continue;
        Above = P.Location + vect(0, 0, 160);
        Dist = VSize(Above - ViewLoc);
        if (Dist > LABEL_RANGE || (Normal(Above - ViewLoc) Dot vector(ViewRot)) < 0.2)
            continue;
        Screen = C.Project(Above);
        Label = P.PointLabel $ "  " $ int(Dist / 50.0) $ " m";
        C.TextSize(Label, XL, YL);
        class'CMenu'.static.DrawShadowText(C, Label, Screen.X - XL * Scale * 0.5, Screen.Y, Scale, MakeColor(255, 230, 120, 255));
    }
}

// The bomb mode: the key is the player's while they carry the bomb, or (a defender) stand by the planted bomb
function bool WantsBombKey()
{
    local CMModeBomb BM;
    local CMABomb B;

    BM = CMModeBomb(Mode);
    if (BM == None || PC.Pawn == None)
        return false;
    foreach PC.DynamicActors(class'CMABomb', B)
    {
        if (B.Carrier == PC.Pawn)
            return true;
        if (B.bPlanted && PC.GetTeamNum() != BM.AttackingTeam && VSize(B.Location - PC.Pawn.Location) <= DEFUSE_REACH * 1.3)
            return true;
    }
    return false;
}

function bool InputKey(int ControllerId, name Key, EInputEvent EventType, float AmountDepressed = 1.f, bool bGamepad = FALSE)
{
    if (Key != PlantKey() || MyDA == None)
        return false;
    if (EventType == IE_Released && bKeyHeld)
    {
        bKeyHeld = false;
        MyDA.ServerBombKey(false);
        return true;
    }
    if (EventType == IE_Pressed && WantsBombKey())
    {
        bKeyHeld = true;
        MyDA.ServerBombKey(true);
        return true;
    }
    return bKeyHeld;
}

defaultproperties
{
    OnReceivedNativeInputKey=InputKey
}

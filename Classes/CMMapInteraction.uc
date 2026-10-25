// Client side of everything MutCMenu adds to the overhead map, fed by CMMapInfo. Interactions are drawn after the HUD
// whatever HUD class the game (or WW2, Winter War, GOM) uses, so no HUD, widget or controller class is replaced:
//  - Spectator overlay: every living player on the map with the game's own player and vehicle icons in the team
//    colour; with the map closed, a team coloured triangle just above every player in view, and the player nearest the
//    crosshair gets their name in their team colour (and their role icon when close). The game's own player names are
//    switched off while it is on, so the two don't double up.
//  - Teammates the map leaves out (past 32 on a team): drawn like the game's own friendly icons, squad leaders with
//    their "SL" label, and for a few seconds after dying.
//  - CMenu's custom objectives: their borders, in the colour of the team holding them.
//  - Map drawings and the drawing toolbar (pen, line, arrow, circle, box, markers, text, eraser, ruler, colours, who it
//    is for, undo and clear). It works with the game's own map cursor (ActualMouseLocation), and only takes a mouse
//    click for itself when the click is on the toolbar or a drawing tool is picked; with the pointer tool the map works
//    as normal. With the map cursor hidden, a left click fires (the cursor comes with T, the tactical display key).
class CMMapInteraction extends Interaction
    config(MutCMenu_Client);

var CMMapInfo Info;

const TOOL_POINTER = 0;
const TOOL_PEN = 1;
const TOOL_LINE = 2;
const TOOL_ARROW = 3;
const TOOL_CIRCLE = 4;
const TOOL_BOX = 5;
const TOOL_MARKER = 6;
const TOOL_TEXT = 7;
const TOOL_ERASER = 8;
const TOOL_RULER = 9;
const NUM_TOOLS = 10;

// What a toolbar button does
const A_PANEL = 0;
const A_TOOL = 1;
const A_COLOUR = 2;
const A_ICON = 3;
const A_CHANNEL = 4;
const A_UNDO = 5;
const A_CLEAR_MINE = 6;
const A_CLEAR_CHANNEL = 7;
const A_CLEAR_ALL = 8;
const A_HIDE = 9;
const A_SPEC_TEAMS = 10;

const CONFIRM_TIME = 4.0;   // seconds a clear button waits for its second click
const FLASH_TIME = 2.5;     // seconds a spectator's marker over a player strobes white after they are hit
const STROBE_STEP = 0.12;   // seconds each white and each normal step of the strobe lasts

// Spectators: the paths projectiles fly (tracers), each segment fading over its kind's life
const BULLET_LIFE = 2.0;    // seconds a stretch of a bullet's path stays
const GRENADE_LIFE = 4.0;
const SHELL_LIFE = 5.0;
const TRACER_GLOW = 0.15;   // seconds a new stretch burns white before it takes its team's colour
const MAX_CLIENT_TRACERS = 600;
const NEAR_PLANE = 20.0;    // unreal units; a line is cut here where it passes behind the camera

// Which teams' drawings a spectator sees
const SPEC_BOTH = 0;
const SPEC_NORTH = 1;
const SPEC_SOUTH = 2;

const LINE_WIDTH = 3.0;     // pixels at 1080p
const ICON_SIZE = 26.0;     // marker size, pixels at 1080p
const PICK_RADIUS = 12.0;   // how close (pixels at 1080p) the cursor must be to a drawing to pick it
const SAMPLE_STEP = 5.0;    // pixels the mouse moves before the pen adds a point
const SENT_TIMEOUT = 4.0;   // seconds an own drawing is shown before the server has sent it back

// Spectator overlay
const NAME_SCALE = 1.4;
const ROLE_ICON_DIST = 2000.0; // how close (unreal units, 40 meters) a looked at player must be to get their role icon
const XRAY_NAME_DIST = 750.0;  // how close (15 meters) a looked at player's name and role show through walls
const NAME_RADIUS = 0.07; // how close to the screen centre (as a part of its width) a player must be to be read as "looked at"

// Why the map tools were or weren't drawn last frame, for the tests and the log
var string MapState;

// Left-out teammates: a squad leader's icon is a little smaller than the game's real one (TransportSize) so they stay
// distinct from a real one while standing out from the others
const LEFT_OUT_SL_SIZE = 2.5;

struct ToolButton
{
    var float X, Y, W, H;
    var byte Action, Arg;
    var string Label;
    var bool bSelected;
    var bool bDisabled; // greyed out: the player may not use it
    var bool bDanger;   // red: a clear waiting for its second click
};

// An own drawing on its way to the server, shown until it comes back
struct SentItem
{
    var int Token;
    var float Time;
    var CMMapInfo.ClientMapItem Item;
};

var config bool bToolsHidden; // the player folded the toolbar away
var config name ShowNamesKey; // spectators hold it to see every name on screen; LeftAlt when not set (prone, which spectators don't use)
var config byte SavedColour, SavedIcon;

var byte Tool, Colour, Icon, Channel;
var bool bChannelPicked;       // the player picked Channel themselves, so it is only changed when no longer allowed
var bool bHideDrawings;
var byte SpecTeams;            // spectators: SPEC_BOTH, SPEC_NORTH or SPEC_SOUTH
var byte ArmedAction;          // a clear button clicked once, waiting for the second click; 255 for none
var float ArmedTime;
var array<ToolButton> Buttons; // laid out every frame; clicks use the last frame's
var array<SentItem> Sent;
var int NextToken;

// The map as it was last seen (screen pixels and world units)
var ROHUDWidgetOverheadMap MapWidget;
var bool bCursor;
var float MapLeft, MapTop, MapW, MapH, MinWX, MaxWX, MinWY, MaxWY, ScaleX, ScaleY;
var float UIScale, TextScale;
var vector2D Mouse;
var float PanelX, PanelY, PanelW, PanelH;

var bool bPressOwned; // the left mouse press went to this tool, so its release does too
var bool bGameFiring; // a click with the map cursor hidden started firing, so its release stops it
var bool bDragging;
var array<vector2D> DragPoints;
var vector2D LastSample;

var bool bTyping, bShift;
var string TypeText;
var vector2D TypeAt;

// Spectator overlay
var bool bNamesHidden;     // the game's own player name display is switched off
var byte SavedNames;       // the player's own setting for it, put back afterwards
var byte SavedClassNames;  // the same for the HUD class's default, which the game may read instead
var byte SavedServerNames; // and the server's setting as this client was told it

// Players who have just died: when this client first saw them dead, for the fade
var array<PlayerReplicationInfo> DeadPRIs;
var array<float> DeadSince;

// Spectators: the stretches of projectile paths still on screen, and how far into the server's ring this client has read
struct ClientTracer
{
    var vector A, B;
    var byte Data;
    var float Born;
};
var array<ClientTracer> Tracers;
var int TraceSeen;
var bool bTraceSynced;

// Spectators: each player's hit count as last seen, and until when their marker flashes
var array<PlayerReplicationInfo> HurtPRIs;
var array<byte> HurtCounts;
var array<float> FlashUntil;

// ====================================================
// The map
// ====================================================

// The overhead map when it is open on this screen, with its position read into the variables above; none otherwise
function ROHUDWidgetOverheadMap ReadMap()
{
    local PlayerController PC;
    local ROHUD H;
    local ROHUDWidgetOverheadMap OM;
    local ROHUDWidgetComponent MapComp;

    MapWidget = None;
    PC = PlayerController(Outer);
    H = (PC != None) ? ROHUD(PC.myHUD) : None;
    if (Info == None || Info.bDeleteMe)
        return NoMap("no map info from the server");
    if (H == None)
        return NoMap("the HUD is not an ROHUD ("$((PC != None && PC.myHUD != None) ? string(PC.myHUD.Class) : "none")$")");
    if (!H.bShowHud)
        return NoMap("the HUD is hidden");

    OM = H.OverheadMapWidget;
    if (OM == None)
        return NoMap("the HUD has no overhead map");
    if (!OM.IsVisible() || OM.bHiddenTemporarily)
        return NoMap("map closed");
    if (OM.HUDComponents.Length <= class'ROHUDWidgetOverheadMap'.const.ROOMT_MousePointer)
        return NoMap("the overhead map has only "$OM.HUDComponents.Length$" parts");

    MapComp = OM.HUDComponents[class'ROHUDWidgetOverheadMap'.const.ROOMT_Map];
    if (MapComp == None)
        return NoMap("the overhead map has no map picture");
    if (OM.MaxVisibleWorldX <= OM.MinVisibleWorldX || OM.MaxVisibleWorldY <= OM.MinVisibleWorldY)
        return NoMap("the overhead map hasn't been laid out yet");

    // North is up and east is right. Component positions are relative to the widget, which the game adds when it draws them.
    MapLeft = OM.CurrentX + MapComp.CurX;
    MapTop = OM.CurrentY + MapComp.CurY;
    MapW = MapComp.CurWidth;
    MapH = MapComp.CurHeight;
    MinWX = OM.MinVisibleWorldX;
    MaxWX = OM.MaxVisibleWorldX;
    MinWY = OM.MinVisibleWorldY;
    MaxWY = OM.MaxVisibleWorldY;
    ScaleX = MapW / (MaxWY - MinWY);
    ScaleY = MapH / (MaxWX - MinWX);

    bCursor = !OM.bHideMousePointer;
    Mouse.X = OM.CurrentX + OM.ActualMouseLocation.X;
    Mouse.Y = OM.CurrentY + OM.ActualMouseLocation.Y;

    MapWidget = OM;
    return OM;
}

// Notes why the map can't be used. Anything but the map simply being closed goes to the log once when it starts.
function ROHUDWidgetOverheadMap NoMap(string Why)
{
    SetMapState(Why);
    return None;
}

function SetMapState(string NewState)
{
    if (NewState != MapState && NewState != "map closed" && NewState != "drawn")
        LogInternal("[MutCMenu] Map tools: "$NewState);
    MapState = NewState;
}

function vector2D WorldToScreen(vector2D W)
{
    local vector2D S;

    S.X = MapLeft + (W.Y - MinWY) * ScaleX;
    S.Y = MapTop + MapH - (W.X - MinWX) * ScaleY;
    return S;
}

function vector2D ScreenToWorld(vector2D S)
{
    local vector2D W;

    W.Y = MinWY + (S.X - MapLeft) / ScaleX;
    W.X = MinWX + (MapTop + MapH - S.Y) / ScaleY;
    return W;
}

function bool InMap(vector2D S)
{
    return S.X >= MapLeft && S.X <= MapLeft + MapW && S.Y >= MapTop && S.Y <= MapTop + MapH;
}

function vector2D ClampToMap(vector2D S)
{
    S.X = FClamp(S.X, MapLeft, MapLeft + MapW);
    S.Y = FClamp(S.Y, MapTop, MapTop + MapH);
    return S;
}

function vector2D V2(float X, float Y)
{
    local vector2D V;

    V.X = X;
    V.Y = Y;
    return V;
}

function float Dist(vector2D A, vector2D B)
{
    return Sqrt(Square(A.X - B.X) + Square(A.Y - B.Y));
}

function float DistToSegment(vector2D P, vector2D A, vector2D B)
{
    local float DX, DY, T, LenSq;

    DX = B.X - A.X;
    DY = B.Y - A.Y;
    LenSq = DX * DX + DY * DY;
    if (LenSq < 0.0001)
        return Dist(P, A);

    T = FClamp(((P.X - A.X) * DX + (P.Y - A.Y) * DY) / LenSq, 0.0, 1.0);
    return Dist(P, V2(A.X + T * DX, A.Y + T * DY));
}

// ====================================================
// Input
// ====================================================

// Called by CMMapInputHook before the game sees the key (or, if the hook couldn't be set up, as an Interaction)
function bool InputKey(int ControllerId, name Key, EInputEvent EventType, optional float AmountDepressed = 1.f, optional bool bGamepad)
{
    if (Key == 'LeftShift' || Key == 'RightShift')
        bShift = EventType != IE_Released;

    // A shot started with the map open ends here wherever the release happens
    if (bGameFiring && Key == 'LeftMouseButton' && EventType == IE_Released)
    {
        StopGameFire();
        return true;
    }

    // Map drawing is off on this server: the map works as the game's own
    if (Info == None || !Info.bDrawingEnabled)
        return false;

    if (ReadMap() == None)
    {
        Cancel();
        if (bPressOwned && Key == 'LeftMouseButton' && EventType == IE_Released)
        {
            bPressOwned = false;
            return true;
        }
        return false;
    }

    if (Key == 'LeftMouseButton')
    {
        if (EventType == IE_Pressed || EventType == IE_DoubleClick)
        {
            if (bTyping)
                FinishTyping();
            // With the cursor hidden the game's map would take the click to show its cursor. The cursor comes with
            // the tactical display key (T) instead, so the click fires as it would with the map closed.
            if (!bCursor)
                return StartGameFire();
            return MousePressed();
        }
        if (EventType == IE_Released && bPressOwned)
        {
            bPressOwned = false;
            if (bDragging)
                FinishDrag();
            return true;
        }
        return false;
    }

    if (bTyping)
        return TypeKey(Key, EventType);

    if (Key == 'Escape' && bDragging && EventType == IE_Pressed)
    {
        Cancel();
        return true;
    }
    return false;
}

// Does what the left mouse button's Fire binding does (Button bFire | StartFire | OnRelease StopFire). Only when left
// mouse really is bound to fire; otherwise the click goes to the game as before.
function bool StartGameFire()
{
    local PlayerController PC;
    local name Key;

    PC = PlayerController(Outer);
    if (PC == None || PC.PlayerInput == None)
        return false;

    Key = 'LeftMouseButton';
    if (InStr(PC.PlayerInput.GetBind(Key), "Fire",, true) == INDEX_NONE)
        return false;

    bGameFiring = true;
    PC.bFire = 1;
    PC.StartFire(0);
    return true;
}

function StopGameFire()
{
    local PlayerController PC;

    bGameFiring = false;
    PC = PlayerController(Outer);
    if (PC == None)
        return;
    PC.bFire = 0;
    PC.StopFire(0);
}

// The key that shows the map cursor (the tactical display key, T by default), for the hint
function string CursorKeyName()
{
    local PlayerController PC;
    local string KeyName;

    PC = PlayerController(Outer);
    if (PC != None && ROPlayerInput(PC.PlayerInput) != None)
        KeyName = ROPlayerInput(PC.PlayerInput).GetToggledOrHeldKeyFromCommand("OnToggleTacticalDisplay", "ShowTacticalDisplay");
    return KeyName != "" ? KeyName : "T";
}

// True when the click was for the toolbar or a drawing tool
function bool MousePressed()
{
    local int B;
    local vector2D W;

    if (!bCursor)
        return false;

    B = ButtonAt(Mouse);
    if (B != INDEX_NONE)
    {
        bPressOwned = true;
        PressButton(Buttons[B]);
        return true;
    }
    if (OverPanel(Mouse))
    {
        bPressOwned = true;
        return true;
    }
    if (Tool == TOOL_POINTER || !InMap(Mouse) || !CanDraw())
        return false;

    bPressOwned = true;
    W = ScreenToWorld(Mouse);
    switch (Tool)
    {
        case TOOL_MARKER:
            SendSingle(class'CMMapInfo'.const.KIND_MARKER, W, "");
            break;
        case TOOL_TEXT:
            bTyping = true;
            TypeText = "";
            TypeAt = W;
            break;
        case TOOL_ERASER:
            EraseAt(Mouse);
            break;
        default:
            bDragging = true;
            DragPoints.Length = 0;
            DragPoints.AddItem(W);
            if (Tool != TOOL_PEN)
                DragPoints.AddItem(W);
            LastSample = Mouse;
    }
    return true;
}

function bool OverPanel(vector2D S)
{
    return S.X >= PanelX && S.X <= PanelX + PanelW && S.Y >= PanelY && S.Y <= PanelY + PanelH;
}

function int ButtonAt(vector2D S)
{
    local int i;

    for (i = 0; i < Buttons.Length; i++)
    {
        if (S.X >= Buttons[i].X && S.X <= Buttons[i].X + Buttons[i].W && S.Y >= Buttons[i].Y && S.Y <= Buttons[i].Y + Buttons[i].H)
            return i;
    }
    return INDEX_NONE;
}

// A clear takes two clicks: the first turns the button red ("are you sure?"), the second within CONFIRM_TIME clears
function bool Confirmed(byte Action)
{
    local float Now;

    Now = PlayerController(Outer).WorldInfo.RealTimeSeconds;
    if (ArmedAction == Action && Now - ArmedTime <= CONFIRM_TIME)
    {
        ArmedAction = 255;
        return true;
    }
    ArmedAction = Action;
    ArmedTime = Now;
    return false;
}

function bool IsClearAction(byte Action)
{
    return Action == A_CLEAR_MINE || Action == A_CLEAR_CHANNEL || Action == A_CLEAR_ALL;
}

function PressButton(ToolButton B)
{
    if (B.bDisabled)
        return;

    if (IsClearAction(B.Action))
    {
        if (!Confirmed(B.Action))
            return;
    }
    else
        ArmedAction = 255;

    switch (B.Action)
    {
        case A_PANEL:
            bToolsHidden = !bToolsHidden;
            if (bToolsHidden)
                SelectTool(TOOL_POINTER);
            SaveConfig();
            break;
        case A_TOOL:
            SelectTool(B.Arg);
            break;
        case A_COLOUR:
            Colour = B.Arg;
            SavedColour = Colour;
            SaveConfig();
            break;
        case A_ICON:
            Icon = B.Arg;
            SavedIcon = Icon;
            SaveConfig();
            break;
        case A_CHANNEL:
            CycleChannel();
            break;
        case A_UNDO:
            Info.ServerUndo();
            break;
        case A_CLEAR_MINE:
            Info.ServerClear(0, Channel);
            break;
        case A_CLEAR_CHANNEL:
            Info.ServerClear(1, Channel);
            break;
        case A_CLEAR_ALL:
            Info.ServerClear(2, Channel);
            break;
        case A_HIDE:
            bHideDrawings = !bHideDrawings;
            break;
        case A_SPEC_TEAMS:
            SpecTeams = (SpecTeams + 1) % 3;
            break;
    }
}

// A spectator who picked one team doesn't see the other team's drawings; everything else is always shown
function bool ItemShown(CMMapInfo.ClientMapItem Item, PlayerReplicationInfo Viewer)
{
    if (Viewer == None || !Viewer.bOnlySpectator)
        return true;
    if (SpecTeams == SPEC_NORTH)
        return Item.Team != class'CMMapInfo'.const.TEAM_SOUTH;
    if (SpecTeams == SPEC_SOUTH)
        return Item.Team != class'CMMapInfo'.const.TEAM_NORTH;
    return true;
}

function SelectTool(byte NewTool)
{
    Cancel();
    Tool = NewTool;
}

// Stops whatever was being drawn or typed, without sending it
function Cancel()
{
    bDragging = false;
    bTyping = false;
    DragPoints.Length = 0;
    TypeText = "";
}

function bool TypeKey(name Key, EInputEvent EventType)
{
    local string Ch;

    // Releases always go through, so a movement key held while the typing started doesn't get stuck
    if (EventType == IE_Released)
        return false;

    // Zooming and dragging the map still work
    if (Key == 'RightMouseButton' || Key == 'MiddleMouseButton' || Key == 'MouseScrollUp' || Key == 'MouseScrollDown')
        return false;

    if (EventType != IE_Pressed && EventType != IE_Repeat)
        return true;

    if (Key == 'Enter')
        FinishTyping();
    else if (Key == 'Escape')
        Cancel();
    else if (Key == 'BackSpace')
        TypeText = Left(TypeText, Len(TypeText) - 1);
    else
    {
        Ch = KeyChar(Key, bShift);
        if (Ch != "" && Len(TypeText) < class'CMMapInfo'.const.MAX_TEXT)
            TypeText $= Ch;
    }
    return true;
}

function FinishTyping()
{
    if (bTyping && TypeText != "")
        SendSingle(class'CMMapInfo'.const.KIND_TEXT, TypeAt, TypeText);
    Cancel();
}

// The character a key types (US keyboard), or "" for keys that don't type
function string KeyChar(name Key, bool bShifted)
{
    local string S;
    local int Digit;

    S = string(Key);
    if (Len(S) == 1)
        return bShifted ? Caps(S) : Locs(S);

    Digit = INDEX_NONE;
    switch (Key)
    {
        case 'SpaceBar':    return " ";
        case 'Period':      return bShifted ? ">" : ".";
        case 'Comma':       return bShifted ? "<" : ",";
        case 'Hyphen':      return bShifted ? "_" : "-";
        case 'Equals':      return bShifted ? "+" : "=";
        case 'Slash':       return bShifted ? "?" : "/";
        case 'Semicolon':   return bShifted ? ":" : ";";
        case 'Apostrophe':  return bShifted ? "\"" : "'";
        case 'Add':         return "+";
        case 'Subtract':    return "-";
        case 'Multiply':    return "*";
        case 'Divide':      return "/";
        case 'Decimal':     return ".";
        case 'Zero':  case 'NumPadZero':  Digit = 0; break;
        case 'One':   case 'NumPadOne':   Digit = 1; break;
        case 'Two':   case 'NumPadTwo':   Digit = 2; break;
        case 'Three': case 'NumPadThree': Digit = 3; break;
        case 'Four':  case 'NumPadFour':  Digit = 4; break;
        case 'Five':  case 'NumPadFive':  Digit = 5; break;
        case 'Six':   case 'NumPadSix':   Digit = 6; break;
        case 'Seven': case 'NumPadSeven': Digit = 7; break;
        case 'Eight': case 'NumPadEight': Digit = 8; break;
        case 'Nine':  case 'NumPadNine':  Digit = 9; break;
    }

    if (Digit == INDEX_NONE)
        return "";
    if (bShifted && InStr(S, "NumPad") == INDEX_NONE)
        return Mid(")!@#$%^&*(", Digit, 1);
    return string(Digit);
}

// ====================================================
// Sending and erasing
// ====================================================

function bool CanDraw()
{
    local PlayerController PC;

    PC = PlayerController(Outer);
    return PC != None && class'CMMapInfo'.static.ChannelAllowed(PC.PlayerReplicationInfo, Channel, Info.bScrimAdmin, Info.bDrawingLocked);
}

function SendSingle(byte Kind, vector2D W, string Text)
{
    local array<vector2D> Points;

    Points.AddItem(W);
    Send(Kind, Points, Text);
}

function Send(byte Kind, array<vector2D> Points, string Text)
{
    local PlayerController PC;
    local SentItem Entry;
    local string S;
    local int i, Chunk;

    PC = PlayerController(Outer);
    if (Info == None || PC == None || !class'CMMapInfo'.static.PointCountOk(Kind, Points.Length))
        return;

    for (i = 0; i < Points.Length; i++)
        S $= class'CMMapInfo'.static.EncodePoint(Points[i]);

    NextToken++;
    Chunk = class'CMMapInfo'.const.CHUNK_POINTS * class'CMMapInfo'.const.POINT_CHARS;
    Info.ServerBeginItem(Kind, Colour, Channel, Icon, Text, Left(S, Chunk), NextToken, Len(S) > Chunk);
    for (i = Chunk; i < Len(S); i += Chunk)
        Info.ServerAddPoints(Mid(S, i, Chunk), i + Chunk < Len(S));

    // Shown straight away; the server's copy replaces it when it comes back
    Entry.Token = NextToken;
    Entry.Time = PC.WorldInfo.RealTimeSeconds;
    Entry.Item.Kind = Kind;
    Entry.Item.Colour = Colour;
    Entry.Item.Icon = Icon;
    Entry.Item.Text = Text;
    Entry.Item.Points = Points;
    Sent.AddItem(Entry);
}

// The server has sent back the drawing this client sent with Token
function ConfirmSent(int Token)
{
    local int i;

    for (i = Sent.Length - 1; i >= 0; i--)
    {
        if (Sent[i].Token == Token)
            Sent.Remove(i, 1);
    }
}

function FinishDrag()
{
    local byte Kind;

    bDragging = false;
    if (Tool == TOOL_PEN)
    {
        if (DragPoints.Length >= 2)
            Send(class'CMMapInfo'.const.KIND_PEN, DragPoints, "");
    }
    else if (Tool != TOOL_RULER && DragPoints.Length == 2 && Dist(WorldToScreen(DragPoints[0]), WorldToScreen(DragPoints[1])) >= 4.0 * UIScale)
    {
        Kind = Tool - TOOL_PEN; // the drag tools are in the same order as the kinds
        Send(Kind, DragPoints, "");
    }
    DragPoints.Length = 0;
}

// Follows the mouse while a drag is on
function UpdateDrag()
{
    local vector2D S, Last;

    S = ClampToMap(Mouse);
    if (Tool != TOOL_PEN)
    {
        DragPoints[1] = ScreenToWorld(S);
        return;
    }

    if (Dist(S, LastSample) < SAMPLE_STEP * UIScale)
        return;
    LastSample = S;
    DragPoints.AddItem(ScreenToWorld(S));

    // A long line goes in pieces, each starting where the last one ended
    if (DragPoints.Length >= class'CMMapInfo'.const.MAX_POINTS)
    {
        Last = DragPoints[DragPoints.Length - 1];
        Send(class'CMMapInfo'.const.KIND_PEN, DragPoints, "");
        DragPoints.Length = 0;
        DragPoints.AddItem(Last);
    }
}

function EraseAt(vector2D S)
{
    local int Index;

    Index = PickItem(S, true);
    if (Index == INDEX_NONE)
        return;

    Info.ServerErase(Info.Items[Index].ID);
    Info.Items.Remove(Index, 1);
}

// The drawing nearest S and close enough to it, optionally only ones the player may erase
function int PickItem(vector2D S, bool bErasable)
{
    local PlayerController PC;
    local int i, Best;
    local float D, BestD;

    PC = PlayerController(Outer);
    if (bHideDrawings || PC == None)
        return INDEX_NONE;

    Best = INDEX_NONE;
    BestD = PICK_RADIUS * UIScale;
    for (i = 0; i < Info.Items.Length; i++)
    {
        if (!ItemShown(Info.Items[i], PC.PlayerReplicationInfo))
            continue;
        if (bErasable && !class'CMMapInfo'.static.CanErase(PC.PlayerReplicationInfo, Info.bScrimAdmin, Info.Items[i].Team, Info.Items[i].Squad, Info.Items[i].OwnerID))
            continue;

        D = DistToItem(Info.Items[i], S);
        if (D < BestD)
        {
            Best = i;
            BestD = D;
        }
    }
    return Best;
}

function float DistToItem(CMMapInfo.ClientMapItem Item, vector2D S)
{
    local vector2D A, B;
    local float D, Best, R;
    local int i;

    if (Item.Points.Length == 0)
        return 100000.0;

    A = WorldToScreen(Item.Points[0]);
    switch (Item.Kind)
    {
        case class'CMMapInfo'.const.KIND_MARKER:
            return FMax(0.0, Dist(S, A) - ICON_SIZE * UIScale * 0.4);

        case class'CMMapInfo'.const.KIND_TEXT:
            return DistToSegment(S, A, V2(A.X + Len(Item.Text) * 8.0 * UIScale, A.Y));

        case class'CMMapInfo'.const.KIND_CIRCLE:
            if (Item.Points.Length < 2)
                return 100000.0;
            R = CircleRadius(Item);
            return Abs(Dist(S, A) - R);

        case class'CMMapInfo'.const.KIND_BOX:
            if (Item.Points.Length < 2)
                return 100000.0;
            B = WorldToScreen(Item.Points[1]);
            Best = DistToSegment(S, A, V2(B.X, A.Y));
            Best = FMin(Best, DistToSegment(S, V2(B.X, A.Y), B));
            Best = FMin(Best, DistToSegment(S, B, V2(A.X, B.Y)));
            return FMin(Best, DistToSegment(S, V2(A.X, B.Y), A));
    }

    // Lines: the nearest segment
    Best = 100000.0;
    for (i = 1; i < Item.Points.Length; i++)
    {
        B = WorldToScreen(Item.Points[i]);
        D = DistToSegment(S, A, B);
        if (D < Best)
            Best = D;
        A = B;
    }
    return Best;
}

// Screen radius of a circle (the map is drawn the same scale both ways, near enough)
function float CircleRadius(out CMMapInfo.ClientMapItem Item)
{
    local float WorldR;

    WorldR = Sqrt(Square(Item.Points[1].X - Item.Points[0].X) + Square(Item.Points[1].Y - Item.Points[0].Y));
    return WorldR * (ScaleX + ScaleY) * 0.5;
}

// ====================================================
// Channels
// ====================================================

// The order the channel button goes round in
function byte ChannelAt(int i)
{
    switch (i)
    {
        case 0: return class'CMMapInfo'.const.CH_PERSONAL;
        case 1: return class'CMMapInfo'.const.CH_SQUAD;
        case 2: return class'CMMapInfo'.const.CH_TEAM;
        case 3: return class'CMMapInfo'.const.CH_SPECTATORS;
        case 4: return class'CMMapInfo'.const.CH_NORTH;
        case 5: return class'CMMapInfo'.const.CH_SOUTH;
    }
    return class'CMMapInfo'.const.CH_EVERYONE;
}

function CycleChannel()
{
    local PlayerController PC;
    local int i, Start;

    PC = PlayerController(Outer);
    for (Start = 0; Start < class'CMMapInfo'.const.NUM_CHANNELS; Start++)
    {
        if (ChannelAt(Start) == Channel)
            break;
    }
    for (i = 1; i <= class'CMMapInfo'.const.NUM_CHANNELS; i++)
    {
        if (class'CMMapInfo'.static.ChannelAllowed(PC.PlayerReplicationInfo, ChannelAt((Start + i) % class'CMMapInfo'.const.NUM_CHANNELS), Info.bScrimAdmin, Info.bDrawingLocked))
        {
            Channel = ChannelAt((Start + i) % class'CMMapInfo'.const.NUM_CHANNELS);
            bChannelPicked = true;
            return;
        }
    }
}

// Players start on the whole team, spectators on the spectators; when that isn't allowed (no team or squad, or drawing
// stopped by an admin), whatever is left
function ValidateChannel(PlayerReplicationInfo PRI)
{
    local bool bAdmin, bLocked;

    bAdmin = Info.bScrimAdmin;
    bLocked = Info.bDrawingLocked;
    if (bChannelPicked && class'CMMapInfo'.static.ChannelAllowed(PRI, Channel, bAdmin, bLocked))
        return;

    bChannelPicked = false;
    if (class'CMMapInfo'.static.ChannelAllowed(PRI, class'CMMapInfo'.const.CH_TEAM, bAdmin, bLocked))
        Channel = class'CMMapInfo'.const.CH_TEAM;
    else if (PRI != None && PRI.bOnlySpectator && class'CMMapInfo'.static.ChannelAllowed(PRI, class'CMMapInfo'.const.CH_SPECTATORS, bAdmin, bLocked))
        Channel = class'CMMapInfo'.const.CH_SPECTATORS;
    else if (class'CMMapInfo'.static.ChannelAllowed(PRI, class'CMMapInfo'.const.CH_SQUAD, bAdmin, bLocked))
        Channel = class'CMMapInfo'.const.CH_SQUAD;
    else
        Channel = class'CMMapInfo'.const.CH_PERSONAL;
}

// ====================================================
// Drawing
// ====================================================

event PostRender(Canvas C)
{
    local PlayerController PC;
    local ROHUD H;
    local int i, Hover;
    local CMMapInfo.ClientMapItem Preview;
    local ROHUDWidgetComponent CursorComp;
    local bool bSpectatorView;

    PC = PlayerController(Outer);
    if (C == None || PC == None || Info == None || Info.bDeleteMe)
    {
        MapState = "no player or map info";
        return;
    }
    H = ROHUD(PC.myHUD);

    // The spectator overlay is on while the owner spectates and the server sends them everyone
    bSpectatorView = Info.bSpectating && H != None && PC.PlayerReplicationInfo != None && PC.PlayerReplicationInfo.bOnlySpectator;
    SetDefaultNames(H, bSpectatorView);
    CollectTracers(bSpectatorView, PC.WorldInfo.RealTimeSeconds);

    if (ReadMap() == None)
    {
        Cancel();
        // With the map closed, the spectator's names and triangles (with it open they would only clutter it)
        if (bSpectatorView && H.bShowHud)
            DrawWorld(C, PC, H);
        return;
    }

    UIScale = FMax(0.75, C.ClipY / 1080.0);
    C.Font = class'Engine'.static.GetSmallFont();

    DrawObjectiveBorders(C, PC);

    if (Info.bDrawingEnabled)
    {
        ValidateChannel(PC.PlayerReplicationInfo);

        for (i = Sent.Length - 1; i >= 0; i--)
        {
            if (PC.WorldInfo.RealTimeSeconds - Sent[i].Time > SENT_TIMEOUT)
                Sent.Remove(i, 1);
        }

        if (!bHideDrawings)
        {
            // A spectator sees every team's drawings, each with an edge in the colour of the team it is for. The edges
            // all go first, so none is drawn over a drawing.
            if (PC.PlayerReplicationInfo != None && PC.PlayerReplicationInfo.bOnlySpectator)
            {
                for (i = 0; i < Info.Items.Length; i++)
                {
                    if (Info.Items[i].Team < 2 && ItemShown(Info.Items[i], PC.PlayerReplicationInfo))
                        DrawGlow(C, Info.Items[i], TeamColour(H, Info.Items[i].Team));
                }
            }
            for (i = 0; i < Info.Items.Length; i++)
            {
                if (ItemShown(Info.Items[i], PC.PlayerReplicationInfo))
                    DrawItem(C, Info.Items[i], false);
            }
            for (i = 0; i < Sent.Length; i++)
                DrawItem(C, Sent[i].Item, false);
        }

        if (bDragging)
        {
            UpdateDrag();
            Preview.Kind = (Tool == TOOL_RULER) ? class'CMMapInfo'.const.KIND_LINE : Tool - TOOL_PEN;
            Preview.Colour = (Tool == TOOL_RULER) ? 6 : Colour;
            Preview.Points = DragPoints;
            DrawItem(C, Preview, false);
            DrawMeasure(C);
        }

        if (bTyping)
            DrawLabel(C, WorldToScreen(TypeAt), TypeText $ "_", class'CMMapInfo'.static.GetColour(Colour), false);
    }

    // Players over the drawings, so a drawing never hides one
    DrawSnapshotOnMap(C, H, bSpectatorView);
    if (bSpectatorView)
        DrawFlagsOnMap(C, H);

    if (!Info.bDrawingEnabled)
    {
        SetMapState("map drawing is off on this server");
        return;
    }

    DrawToolbar(C, PC);
    SetMapState("drawn");

    // Who drew what under the cursor; the eraser also shows what it would take
    if (bCursor && !bToolsHidden && !bDragging && !OverPanel(Mouse) && InMap(Mouse))
    {
        Hover = PickItem(Mouse, Tool == TOOL_ERASER);
        if (Hover != INDEX_NONE)
        {
            if (Tool == TOOL_ERASER)
                DrawItem(C, Info.Items[Hover], true);
            DrawLabel(C, V2(Mouse.X + 18 * UIScale, Mouse.Y + 22 * UIScale), Info.Items[Hover].OwnerName $ " ("
                $ class'CMMapInfo'.static.AudienceName(PC.PlayerReplicationInfo, Info.Items[Hover].Team, Info.Items[Hover].Squad) $ ")",
                MakeColor(255, 255, 255, 255), true);
        }
    }

    // The game drew its cursor before this; draw it again so it stays on top of the toolbar and the drawings. It goes in
    // the top layer, where the game draws its own cursor, above the toolbar's two.
    CursorComp = MapWidget.HUDComponents[class'ROHUDWidgetOverheadMap'.const.ROOMT_MousePointer];
    if (bCursor && CursorComp != None)
    {
        if (ROCanvas(C) != None)
            ROCanvas(C).PushDepthSortPriority(DSP_Insane);
        DrawCursor(C, CursorComp);
        PopLayer(C);
    }
}

// The canvas draws everything with the same texture together, in the order each texture was first used. So text drawn
// after a box could end up under it when the same font had been used earlier in the frame (a label typed on the map took
// the toolbar's text with it, a marker on the map the toolbar's marker icons). The toolbar and other boxes with text on
// them are drawn in two layers above the map (which draws in the layers up to DSP_AboveNormal): the boxes (bTop false),
// then what goes on them (bTop true). The top layer (DSP_Insane) is left to the cursor: the game draws its own cursor
// there, and anything else in it would be drawn over the cursor.
function PushLayer(Canvas C, bool bTop)
{
    if (ROCanvas(C) == None)
        return;
    if (bTop)
        ROCanvas(C).PushDepthSortPriority(DSP_SkyHigh);
    else
        ROCanvas(C).PushDepthSortPriority(DSP_Highest);
}

function PopLayer(Canvas C)
{
    if (ROCanvas(C) != None)
        ROCanvas(C).PopDepthSortPriority();
}

function DrawCursor(Canvas C, ROHUDWidgetComponent CursorComp)
{
    local Texture2D Tex;
    local float W, H;

    Tex = CursorComp.Tex;
    if (Tex == None)
        return;

    // Its size and texture area as the game last drew it, or the texture's own if it hasn't yet
    W = CursorComp.CurWidth > 0 ? CursorComp.CurWidth : 24 * UIScale;
    H = CursorComp.CurHeight > 0 ? CursorComp.CurHeight : 24 * UIScale;
    C.SetDrawColor(CursorComp.DrawColor.R, CursorComp.DrawColor.G, CursorComp.DrawColor.B, 255);
    C.SetPos(Mouse.X, Mouse.Y);
    C.DrawTile(Tex, W, H, CursorComp.UOffset, CursorComp.VOffset,
        CursorComp.TexWidth > 0 ? CursorComp.TexWidth : float(Tex.SizeX), CursorComp.TexHeight > 0 ? CursorComp.TexHeight : float(Tex.SizeY));
}

// One thick line, cut to the map
function DrawSegment(Canvas C, vector2D A, vector2D B, float Width, color Col)
{
    if (!ClipToMap(A, B))
        return;

    DrawScreenLine(C, A, B, Width, Col);
}

// One thick line between two points on the screen
function DrawScreenLine(Canvas C, vector2D A, vector2D B, float Width, color Col)
{
    local rotator Rot;
    local float Len2D;

    Len2D = Dist(A, B);
    if (Len2D < 0.5)
        return;

    Rot.Yaw = Atan2(B.Y - A.Y, B.X - A.X) * 32768.0 / Pi;
    C.SetDrawColor(Col.R, Col.G, Col.B, Col.A);
    // A little longer than the segment, so the joins in a freehand line don't show gaps
    C.SetPos((A.X + B.X) * 0.5 - (Len2D + Width) * 0.5, (A.Y + B.Y) * 0.5 - Width * 0.5);
    C.DrawRotatedTile(C.DefaultTexture, Rot, Len2D + Width, Width, 0, 0, C.DefaultTexture.SizeX, C.DefaultTexture.SizeY);
}

// Liang-Barsky: cuts the segment to the map rectangle, false when none of it is on the map
function bool ClipToMap(out vector2D A, out vector2D B)
{
    local float T0, T1, DX, DY, P[4], Q[4], R;
    local int i;

    T0 = 0.0;
    T1 = 1.0;
    DX = B.X - A.X;
    DY = B.Y - A.Y;
    P[0] = -DX; Q[0] = A.X - MapLeft;
    P[1] = DX;  Q[1] = MapLeft + MapW - A.X;
    P[2] = -DY; Q[2] = A.Y - MapTop;
    P[3] = DY;  Q[3] = MapTop + MapH - A.Y;

    for (i = 0; i < 4; i++)
    {
        if (Abs(P[i]) < 0.00001)
        {
            if (Q[i] < 0)
                return false;
            continue;
        }
        R = Q[i] / P[i];
        if (P[i] < 0)
        {
            if (R > T1)
                return false;
            T0 = FMax(T0, R);
        }
        else
        {
            if (R < T0)
                return false;
            T1 = FMin(T1, R);
        }
    }

    B = V2(A.X + T1 * DX, A.Y + T1 * DY);
    A = V2(A.X + T0 * DX, A.Y + T0 * DY);
    return true;
}

// With GlowWidth, a line, arrow, circle or box is drawn that wide in GlowCol instead (the team edge for spectators)
function DrawItem(Canvas C, CMMapInfo.ClientMapItem Item, bool bHighlight, optional float GlowWidth, optional color GlowCol)
{
    local vector2D A, B, Prev, Next, Dir;
    local float Width, R, HeadLen, Ang;
    local color Col;
    local int i;

    if (Item.Points.Length == 0)
        return;

    Col = bHighlight ? MakeColor(255, 255, 255, 200) : class'CMMapInfo'.static.GetColour(Item.Colour);
    Width = LINE_WIDTH * UIScale + (bHighlight ? 4.0 : 0.0);
    if (GlowWidth > 0)
    {
        Col = GlowCol;
        Width = GlowWidth;
    }
    A = WorldToScreen(Item.Points[0]);

    switch (Item.Kind)
    {
        case class'CMMapInfo'.const.KIND_MARKER:
            DrawMarker(C, A, Item.Icon, Col, bHighlight);
            if (Item.Text != "")
                DrawLabel(C, V2(A.X + ICON_SIZE * UIScale * 0.6, A.Y), Item.Text, Col, false);
            return;

        case class'CMMapInfo'.const.KIND_TEXT:
            if (InMap(A))
                DrawLabel(C, A, Item.Text, Col, bHighlight);
            return;
    }

    if (Item.Points.Length < 2)
        return;
    B = WorldToScreen(Item.Points[1]);

    switch (Item.Kind)
    {
        case class'CMMapInfo'.const.KIND_CIRCLE:
            R = CircleRadius(Item);
            Prev = V2(A.X + R, A.Y);
            for (i = 1; i <= 48; i++)
            {
                Next = V2(A.X + R * Cos(i * 2 * Pi / 48), A.Y + R * Sin(i * 2 * Pi / 48));
                DrawSegment(C, Prev, Next, Width, Col);
                Prev = Next;
            }
            return;

        case class'CMMapInfo'.const.KIND_BOX:
            DrawSegment(C, A, V2(B.X, A.Y), Width, Col);
            DrawSegment(C, V2(B.X, A.Y), B, Width, Col);
            DrawSegment(C, B, V2(A.X, B.Y), Width, Col);
            DrawSegment(C, V2(A.X, B.Y), A, Width, Col);
            return;

        case class'CMMapInfo'.const.KIND_ARROW:
            DrawSegment(C, A, B, Width, Col);
            if (Dist(A, B) < 1.0)
                return;
            // Two strokes back from the tip, 28 degrees either side of the line
            HeadLen = FMin(16.0 * UIScale, Dist(A, B) * 0.5);
            Dir = V2((A.X - B.X) / Dist(A, B), (A.Y - B.Y) / Dist(A, B));
            Ang = 28.0 * Pi / 180.0;
            DrawSegment(C, B, V2(B.X + HeadLen * (Dir.X * Cos(Ang) - Dir.Y * Sin(Ang)), B.Y + HeadLen * (Dir.X * Sin(Ang) + Dir.Y * Cos(Ang))), Width, Col);
            DrawSegment(C, B, V2(B.X + HeadLen * (Dir.X * Cos(-Ang) - Dir.Y * Sin(-Ang)), B.Y + HeadLen * (Dir.X * Sin(-Ang) + Dir.Y * Cos(-Ang))), Width, Col);
            return;
    }

    // Line or freehand
    for (i = 1; i < Item.Points.Length; i++)
    {
        B = WorldToScreen(Item.Points[i]);
        DrawSegment(C, A, B, Width, Col);
        A = B;
    }
}

// The edge in a team's colour behind a drawing, so a spectator can tell whose it is: a wider line under lines and
// shapes, a square under a marker, a box under text
function DrawGlow(Canvas C, CMMapInfo.ClientMapItem Item, color Col)
{
    local vector2D A;
    local float Size, XL, YL, S;

    if (Item.Points.Length == 0)
        return;

    Col.A = 150;
    A = WorldToScreen(Item.Points[0]);
    switch (Item.Kind)
    {
        case class'CMMapInfo'.const.KIND_MARKER:
            if (!InMap(A))
                return;
            Size = ICON_SIZE * UIScale * 1.35;
            C.SetDrawColor(Col.R, Col.G, Col.B, Col.A);
            C.SetPos(A.X - Size * 0.5, A.Y - Size * 0.5);
            C.DrawTile(C.DefaultTexture, Size, Size, 0, 0, C.DefaultTexture.SizeX, C.DefaultTexture.SizeY);
            return;

        case class'CMMapInfo'.const.KIND_TEXT:
            if (!InMap(A))
                return;
            S = UIScale * 1.1;
            C.Font = class'Engine'.static.GetSmallFont();
            C.TextSize(Item.Text, XL, YL);
            C.SetDrawColor(Col.R, Col.G, Col.B, Col.A);
            C.SetPos(A.X - 3 * UIScale, A.Y - YL * S * 0.5 - 2 * UIScale);
            C.DrawTile(C.DefaultTexture, XL * S + 6 * UIScale, YL * S + 4 * UIScale, 0, 0, C.DefaultTexture.SizeX, C.DefaultTexture.SizeY);
            return;
    }
    DrawItem(C, Item, false, LINE_WIDTH * UIScale + 5 * UIScale, Col);
}

// The game's own map icons where there is one, read from the running map so WW2, Winter War and GOM get theirs
function Texture2D IconTexture(byte Which)
{
    switch (Which)
    {
        case class'CMMapInfo'.const.ICON_ATTACK:        return MapWidget.AttackObjectiveOverlay;
        case class'CMMapInfo'.const.ICON_DEFEND:        return MapWidget.DefendObjectiveOverlay;
        case class'CMMapInfo'.const.ICON_RALLY:         return MapWidget.WaypointIcon;
        case class'CMMapInfo'.const.ICON_ENEMY:         return MapWidget.EnemyInfantrySpottedIcon;
        case class'CMMapInfo'.const.ICON_ENEMY_ARMOUR:  return MapWidget.EnemyVehicleSpottedIcon;
        case class'CMMapInfo'.const.ICON_ENEMY_VEHICLE: return MapWidget.EnemyTransportSpottedIcon;
        case class'CMMapInfo'.const.ICON_ENEMY_HELI:    return MapWidget.EnemyHelicopterSpottedIconHuey;
        case class'CMMapInfo'.const.ICON_ARTILLERY:
            if (MapWidget.HUDComponents[class'ROHUDWidgetOverheadMap'.const.ROOMT_KeyArtilleryTargetTexture] != None)
                return MapWidget.HUDComponents[class'ROHUDWidgetOverheadMap'.const.ROOMT_KeyArtilleryTargetTexture].Tex;
            break;
        case class'CMMapInfo'.const.ICON_LZ:
            if (MapWidget.HUDComponents[class'ROHUDWidgetOverheadMap'.const.ROOMT_KeyLZMarkerTexture] != None)
                return MapWidget.HUDComponents[class'ROHUDWidgetOverheadMap'.const.ROOMT_KeyLZMarkerTexture].Tex;
            break;
    }
    return None;
}

// bAnywhere for the toolbar, which is off the map
function DrawMarker(Canvas C, vector2D At, byte Which, color Col, bool bHighlight, optional bool bAnywhere)
{
    local Texture2D Tex;
    local float Size;
    local rotator Diamond;
    local color Black;

    if (!bAnywhere && !InMap(At))
        return;

    Size = ICON_SIZE * UIScale * (bHighlight ? 1.3 : 1.0);
    Black = MakeColor(0, 0, 0, 200);
    Tex = IconTexture(Which);

    if (Which == class'CMMapInfo'.const.ICON_CROSS)
    {
        DrawSegment(C, V2(At.X - Size * 0.4, At.Y - Size * 0.4), V2(At.X + Size * 0.4, At.Y + Size * 0.4), LINE_WIDTH * UIScale + 2, Black);
        DrawSegment(C, V2(At.X - Size * 0.4, At.Y + Size * 0.4), V2(At.X + Size * 0.4, At.Y - Size * 0.4), LINE_WIDTH * UIScale + 2, Black);
        DrawSegment(C, V2(At.X - Size * 0.4, At.Y - Size * 0.4), V2(At.X + Size * 0.4, At.Y + Size * 0.4), LINE_WIDTH * UIScale, Col);
        DrawSegment(C, V2(At.X - Size * 0.4, At.Y + Size * 0.4), V2(At.X + Size * 0.4, At.Y - Size * 0.4), LINE_WIDTH * UIScale, Col);
        return;
    }

    if (Tex == None)
    {
        // A diamond with a dark edge
        Diamond.Yaw = 8192;
        C.SetDrawColor(0, 0, 0, 200);
        C.SetPos(At.X - Size * 0.3, At.Y - Size * 0.3);
        C.DrawRotatedTile(C.DefaultTexture, Diamond, Size * 0.6, Size * 0.6, 0, 0, C.DefaultTexture.SizeX, C.DefaultTexture.SizeY);
        C.SetDrawColor(Col.R, Col.G, Col.B, Col.A);
        C.SetPos(At.X - Size * 0.22, At.Y - Size * 0.22);
        C.DrawRotatedTile(C.DefaultTexture, Diamond, Size * 0.44, Size * 0.44, 0, 0, C.DefaultTexture.SizeX, C.DefaultTexture.SizeY);
        return;
    }

    C.SetDrawColor(Col.R, Col.G, Col.B, Col.A);
    C.SetPos(At.X - Size * 0.5, At.Y - Size * 0.5);
    C.DrawTile(Tex, Size, Size, 0, 0, Tex.SizeX, Tex.SizeY);
}

// Text with a dark shadow, its left edge at At.X and its middle at At.Y. With bBox it sits on a dark box instead.
function DrawLabel(Canvas C, vector2D At, string Text, color Col, bool bBox)
{
    local float XL, YL, S;

    S = UIScale * 1.1;
    C.Font = class'Engine'.static.GetSmallFont();
    C.TextSize(Text, XL, YL);
    XL *= S;
    YL *= S;

    if (bBox)
    {
        // The box and its text in the layers above the map, or the text could end up under the box (see PushLayer)
        PushLayer(C, false);
        C.SetDrawColor(0, 0, 0, 180);
        C.SetPos(At.X - 4 * UIScale, At.Y - YL * 0.5 - 2 * UIScale);
        C.DrawTile(C.DefaultTexture, XL + 8 * UIScale, YL + 4 * UIScale, 0, 0, C.DefaultTexture.SizeX, C.DefaultTexture.SizeY);
        PopLayer(C);
        PushLayer(C, true);
    }
    else
    {
        C.SetDrawColor(0, 0, 0, 230);
        C.SetPos(At.X + 1, At.Y - YL * 0.5 + 1);
        C.DrawText(Text, false, S, S);
    }

    C.SetDrawColor(Col.R, Col.G, Col.B, 255);
    C.SetPos(At.X, At.Y - YL * 0.5);
    C.DrawText(Text, false, S, S);
    if (bBox)
        PopLayer(C);
}

// Length and direction of what is being dragged, next to the cursor. 50 unreal units = 1 meter.
function DrawMeasure(Canvas C)
{
    local float DX, DY, Meters, Bearing;
    local string S;

    if (DragPoints.Length < 2)
        return;

    DX = DragPoints[DragPoints.Length - 1].X - DragPoints[0].X; // north
    DY = DragPoints[DragPoints.Length - 1].Y - DragPoints[0].Y; // east
    Meters = Sqrt(DX * DX + DY * DY) / 50.0;

    switch (Tool)
    {
        case TOOL_PEN:
            return;
        case TOOL_CIRCLE:
            S = "Radius "$Round(Meters)$" m";
            break;
        case TOOL_BOX:
            S = Round(Abs(DY) / 50.0)$" x "$Round(Abs(DX) / 50.0)$" m";
            break;
        default:
            // Compass bearing: 0 is north, 90 east
            Bearing = Atan2(DY, DX) * 180.0 / Pi;
            if (Bearing < 0)
                Bearing += 360.0;
            S = Round(Meters)$" m, "$Right("00"$(Round(Bearing) % 360), 3)$" deg";
    }
    DrawLabel(C, V2(Mouse.X + 18 * UIScale, Mouse.Y + 22 * UIScale), S, MakeColor(255, 255, 255, 255), true);
}

// ====================================================
// Toolbar
// ====================================================

function AddButton(float X, float Y, float W, float H, byte Action, byte Arg, string Label, bool bSelected, optional bool bDisabled)
{
    local ToolButton B;

    B.X = X;
    B.Y = Y;
    B.W = W;
    B.H = H;
    B.Action = Action;
    B.Arg = Arg;
    B.Label = Label;
    B.bSelected = bSelected;
    B.bDisabled = bDisabled;
    Buttons.AddItem(B);
}

// What the spectators' team button says: which teams' drawings are shown, in the map's own team names
function string SpecTeamsLabel(PlayerController PC)
{
    switch (SpecTeams)
    {
        case SPEC_NORTH: return "Teams shown: "$class'CMAFlag'.static.TeamWord(PC.WorldInfo, 0);
        case SPEC_SOUTH: return "Teams shown: "$class'CMAFlag'.static.TeamWord(PC.WorldInfo, 1);
    }
    return "Teams shown: both";
}

// The clear button clicked once turns red and asks to be clicked again, until CONFIRM_TIME is up
function MarkArmedButton(PlayerController PC)
{
    local int i;

    if (ArmedAction == 255)
        return;
    if (PC.WorldInfo.RealTimeSeconds - ArmedTime > CONFIRM_TIME)
    {
        ArmedAction = 255;
        return;
    }

    for (i = 0; i < Buttons.Length; i++)
    {
        if (Buttons[i].Action != ArmedAction || Buttons[i].bDisabled)
            continue;
        Buttons[i].bDanger = true;
        Buttons[i].Label = (Buttons[i].W > PanelW * 0.6) ? "Are you sure? Click again" : "Are you sure?";
        return;
    }
    ArmedAction = 255; // the button isn't there any more (the channel changed to one they can't clear)
}

// The buttons' backgrounds in the lower layer, then their labels and icons in the upper one (see PushLayer)
function DrawButtonLayers(Canvas C)
{
    PushLayer(C, false);
    DrawButtons(C, false);
    PopLayer(C);
    PushLayer(C, true);
    DrawButtons(C, true);
    PopLayer(C);
}

function string ToolName(byte Which)
{
    switch (Which)
    {
        case TOOL_PEN:    return "Pen";
        case TOOL_LINE:   return "Line";
        case TOOL_ARROW:  return "Arrow";
        case TOOL_CIRCLE: return "Circle";
        case TOOL_BOX:    return "Box";
        case TOOL_MARKER: return "Marker";
        case TOOL_TEXT:   return "Text";
        case TOOL_ERASER: return "Eraser";
        case TOOL_RULER:  return "Ruler";
    }
    return "Pointer";
}

function string ToolHint(PlayerController PC)
{
    if (!bCursor)
        return "Press "$CursorKeyName()$" for the cursor";
    if (Tool != TOOL_POINTER && !CanDraw())
        return "You can't draw yet";

    switch (Tool)
    {
        case TOOL_POINTER: return "The map works as normal";
        case TOOL_PEN:     return "Hold left mouse and draw";
        case TOOL_MARKER:  return class'CMMapInfo'.static.IconName(Icon)$": click to place";
        case TOOL_TEXT:    return "Click, type, then Enter";
        case TOOL_ERASER:  return "Click a drawing to erase";
        case TOOL_RULER:   return "Drag to measure (only you see it)";
    }
    return "Hold left mouse and drag";
}

function DrawToolbar(Canvas C, PlayerController PC)
{
    local float BtnW, BtnH, Gap, Pad, Inner, X, Y, Cell, XL, YL;
    local int i, Cols;
    local PlayerReplicationInfo PRI;

    PRI = PC.PlayerReplicationInfo;
    Buttons.Length = 0;

    BtnW = 84 * UIScale;
    BtnH = 22 * UIScale;
    Gap = 3 * UIScale;
    Pad = 6 * UIScale;
    PanelW = Pad * 2 + BtnW * 2 + Gap;
    Inner = PanelW - Pad * 2;

    // Left of the map if there is room, otherwise inside its left edge
    PanelX = MapLeft - PanelW - 6 * UIScale;
    if (PanelX < 4)
        PanelX = MapLeft + 4 * UIScale;
    PanelY = MapTop;

    C.Font = class'Engine'.static.GetSmallFont();
    C.TextSize("Ag", XL, YL);
    TextScale = (BtnH * 0.72) / FMax(YL, 1.0);

    if (bToolsHidden)
    {
        PanelH = BtnH;
        AddButton(PanelX, PanelY, PanelW, BtnH, A_PANEL, 0, "Map drawing tools", false);
        DrawButtonLayers(C);
        return;
    }

    Y = PanelY + Pad;
    X = PanelX + Pad;
    AddButton(X, Y, Inner, BtnH, A_PANEL, 0, "Hide drawing tools", false);
    Y += BtnH + Gap * 3;

    for (i = 0; i < NUM_TOOLS; i++)
    {
        AddButton(X + (i % 2) * (BtnW + Gap), Y, BtnW, BtnH, A_TOOL, i, ToolName(i), Tool == i);
        if (i % 2 == 1)
            Y += BtnH + Gap;
    }
    Y += Gap * 2;

    Cell = (Inner - Gap * (class'CMMapInfo'.const.NUM_COLOURS - 1)) / class'CMMapInfo'.const.NUM_COLOURS;
    for (i = 0; i < class'CMMapInfo'.const.NUM_COLOURS; i++)
        AddButton(X + i * (Cell + Gap), Y, Cell, BtnH, A_COLOUR, i, "", Colour == i);
    Y += BtnH + Gap * 3;

    if (Tool == TOOL_MARKER)
    {
        Cols = 6;
        Cell = (Inner - Gap * (Cols - 1)) / Cols;
        for (i = 0; i < class'CMMapInfo'.const.NUM_ICONS; i++)
        {
            AddButton(X + (i % Cols) * (Cell + Gap), Y, Cell, Cell, A_ICON, i, "", Icon == i);
            if (i % Cols == Cols - 1)
                Y += Cell + Gap;
        }
        if (class'CMMapInfo'.const.NUM_ICONS % Cols != 0)
            Y += Cell + Gap;
        Y += Gap * 2;
    }

    AddButton(X, Y, Inner, BtnH, A_CHANNEL, 0, "Draw for: "$class'CMMapInfo'.static.ChannelName(Channel), false);
    Y += BtnH + Gap;
    AddButton(X, Y, BtnW, BtnH, A_UNDO, 0, "Undo", false);
    AddButton(X + BtnW + Gap, Y, BtnW, BtnH, A_CLEAR_MINE, 0, "Clear mine", false);
    Y += BtnH + Gap;
    // Shown to everyone, greyed out for those who may not clear the channel picked: squad leaders clear their squad,
    // the commander the team, scrim admins anything
    AddButton(X, Y, Inner, BtnH, A_CLEAR_CHANNEL, 0, "Clear all for "$class'CMMapInfo'.static.ChannelName(Channel), false,
        !class'CMMapInfo'.static.CanClearChannel(PRI, Channel, Info.bScrimAdmin));
    Y += BtnH + Gap;
    if (Info.bScrimAdmin)
    {
        AddButton(X, Y, Inner, BtnH, A_CLEAR_ALL, 0, "Clear every drawing", false);
        Y += BtnH + Gap;
    }
    AddButton(X, Y, Inner, BtnH, A_HIDE, 0, bHideDrawings ? "Show drawings" : "Hide drawings", bHideDrawings);
    Y += BtnH + Gap;
    if (PRI != None && PRI.bOnlySpectator)
    {
        AddButton(X, Y, Inner, BtnH, A_SPEC_TEAMS, 0, SpecTeamsLabel(PC), SpecTeams != SPEC_BOTH);
        Y += BtnH + Gap;
    }
    Y += Gap;
    MarkArmedButton(PC);

    // The hint line under the buttons
    Y += BtnH;
    PanelH = Y + Pad - PanelY;

    PushLayer(C, false);
    C.SetDrawColor(0, 0, 0, 170);
    C.SetPos(PanelX, PanelY);
    C.DrawTile(C.DefaultTexture, PanelW, PanelH, 0, 0, C.DefaultTexture.SizeX, C.DefaultTexture.SizeY);
    PopLayer(C);

    DrawButtonLayers(C);

    PushLayer(C, true);
    C.SetDrawColor(220, 220, 220, 255);
    C.TextSize(ToolHint(PC), XL, YL);
    C.SetPos(X, Y - BtnH * 0.5 - YL * TextScale * 0.5);
    C.DrawText(ToolHint(PC), false, TextScale * 0.9, TextScale * 0.9);
    PopLayer(C);
}

// bTop false: the frames and backgrounds; true: the icons and labels on them
function DrawButtons(Canvas C, bool bTop)
{
    local int i;
    local float XL, YL, Inset;
    local color Col;
    local bool bHover;
    local Texture2D Tex;

    for (i = 0; i < Buttons.Length; i++)
    {
        bHover = bCursor && !Buttons[i].bDisabled && Mouse.X >= Buttons[i].X && Mouse.X <= Buttons[i].X + Buttons[i].W
            && Mouse.Y >= Buttons[i].Y && Mouse.Y <= Buttons[i].Y + Buttons[i].H;

        if (!bTop)
        {
            // Selected: an amber frame. Hovered: a lighter background. Waiting for a second click: red. Greyed out: darker.
            if (Buttons[i].bSelected)
            {
                C.SetDrawColor(230, 170, 40, 255);
                C.SetPos(Buttons[i].X - 2, Buttons[i].Y - 2);
                C.DrawTile(C.DefaultTexture, Buttons[i].W + 4, Buttons[i].H + 4, 0, 0, C.DefaultTexture.SizeX, C.DefaultTexture.SizeY);
            }

            if (Buttons[i].Action == A_COLOUR)
                Col = class'CMMapInfo'.static.GetColour(Buttons[i].Arg);
            else if (Buttons[i].bDanger)
                Col = bHover ? MakeColor(230, 50, 40, 240) : MakeColor(190, 30, 25, 240);
            else if (Buttons[i].bDisabled)
                Col = MakeColor(30, 30, 30, 200);
            else if (bHover)
                Col = MakeColor(90, 90, 90, 230);
            else
                Col = MakeColor(45, 45, 45, 230);
            C.SetDrawColor(Col.R, Col.G, Col.B, Col.A);
            C.SetPos(Buttons[i].X, Buttons[i].Y);
            C.DrawTile(C.DefaultTexture, Buttons[i].W, Buttons[i].H, 0, 0, C.DefaultTexture.SizeX, C.DefaultTexture.SizeY);
            continue;
        }

        if (Buttons[i].Action == A_ICON)
        {
            Inset = Buttons[i].W * 0.12;
            Tex = IconTexture(Buttons[i].Arg);
            if (Tex != None)
            {
                Col = class'CMMapInfo'.static.GetColour(Colour);
                C.SetDrawColor(Col.R, Col.G, Col.B, 255);
                C.SetPos(Buttons[i].X + Inset, Buttons[i].Y + Inset);
                C.DrawTile(Tex, Buttons[i].W - Inset * 2, Buttons[i].H - Inset * 2, 0, 0, Tex.SizeX, Tex.SizeY);
            }
            else
                DrawMarker(C, V2(Buttons[i].X + Buttons[i].W * 0.5, Buttons[i].Y + Buttons[i].H * 0.5), Buttons[i].Arg,
                    class'CMMapInfo'.static.GetColour(Colour), false, true);
            continue;
        }

        if (Buttons[i].Label == "")
            continue;

        C.TextSize(Buttons[i].Label, XL, YL);
        if (Buttons[i].bDisabled)
            C.SetDrawColor(110, 110, 110, 255);
        else
            C.SetDrawColor(255, 255, 255, 255);
        C.SetPos(Buttons[i].X + (Buttons[i].W - XL * TextScale) * 0.5, Buttons[i].Y + (Buttons[i].H - YL * TextScale) * 0.5);
        C.DrawText(Buttons[i].Label, false, TextScale, TextScale);
    }
}

// ====================================================
// Spectator overlay, left-out teammates and objective borders
// ====================================================

// Colour for a team: whatever the running HUD uses (north is SideColors[0], south SideColors[1])
function color TeamColour(ROHUD H, byte Team)
{
    if (H != None && Team < 2)
        return H.SideColors[Team];
    return MakeColor(255, 255, 255, 255);
}

// The game's own name display (distance setting 0 = none) is turned off while the overlay is on and put back afterwards.
// Where the game reads the setting is not known, so all three places are set: the running HUD, its class default and the
// server's setting as this client was told it. None of them is saved to the player's settings.
function SetDefaultNames(ROHUD H, bool bHide)
{
    local ROGameReplicationInfo ROGRI;

    if (H == None)
        return;

    ROGRI = ROGameReplicationInfo(H.WorldInfo.GRI);

    if (bHide && !bNamesHidden)
    {
        SavedNames = H.MyFriendlyPlayerNames;
        SavedClassNames = H.Class.default.MyFriendlyPlayerNames;
        H.MyFriendlyPlayerNames = 0;
        H.Class.default.MyFriendlyPlayerNames = 0;
        if (ROGRI != None)
        {
            SavedServerNames = ROGRI.FriendlyPlayerNames;
            ROGRI.FriendlyPlayerNames = 0;
        }
        bNamesHidden = true;
    }
    else if (!bHide && bNamesHidden)
    {
        H.MyFriendlyPlayerNames = SavedNames;
        H.Class.default.MyFriendlyPlayerNames = SavedClassNames;
        if (ROGRI != None)
            ROGRI.FriendlyPlayerNames = SavedServerNames;
        bNamesHidden = false;
    }
    else if (bHide && bNamesHidden && ROGRI != None && ROGRI.FriendlyPlayerNames != 0)
    {
        // The server sent its setting again
        SavedServerNames = ROGRI.FriendlyPlayerNames;
        ROGRI.FriendlyPlayerNames = 0;
    }
}

// The game's own icon for what the player is in (infantry, a squad leader, tank, truck or one of the helicopters), and
// the size the game gives that kind of icon
function Texture2D MapIcon(ROHUDWidgetOverheadMap OM, byte Packed, PlayerReplicationInfo PRI, bool bSpectatorView, out float SizeModifier)
{
    local ROPlayerReplicationInfo ROPRI;

    // Squad leaders always show the squad leader icon on a team's map, whatever they are in, as the game does
    ROPRI = ROPlayerReplicationInfo(PRI);
    if (!bSpectatorView && ROPRI != None && ROPRI.bIsSquadLeader && OM.SquadLeaderIcon != None)
    {
        SizeModifier = LEFT_OUT_SL_SIZE;
        return OM.SquadLeaderIcon;
    }

    SizeModifier = bSpectatorView ? OM.InfantrySize : OM.TransportSize;
    switch (class'CMMapInfo'.static.KindOf(Packed))
    {
        case class'CMMapInfo'.const.KIND_TANK:
            SizeModifier = bSpectatorView ? OM.InfantrySize : OM.TankSize;
            return OM.FriendlyPlayerIconTank;
        case class'CMMapInfo'.const.KIND_TRANSPORT:
            return OM.FriendlyPlayerIconTransport;
        case class'CMMapInfo'.const.KIND_HUEY:
            return OM.FriendlyPlayerIconHelicopterHuey;
        case class'CMMapInfo'.const.KIND_COBRA:
            return OM.FriendlyPlayerIconHelicopterCobra;
        case class'CMMapInfo'.const.KIND_LOACH:
            return OM.FriendlyPlayerIconHelicopterLoach;
        case class'CMMapInfo'.const.KIND_GUNSHIP:
            return OM.FriendlyPlayerIconHelicopterGunship;
    }

    SizeModifier = OM.InfantrySize;
    if (bSpectatorView && (Packed & class'CMMapInfo'.const.FLAG_LEADER) != 0 && OM.SquadLeaderIcon != None)
        return OM.SquadLeaderIcon;
    return OM.FriendlyPlayerIconRifle;
}

// How opaque (0-255) a just-died left-out teammate is: full for 2 seconds after this client first saw them dead, then
// fading out over 3, as the game does for its own teammates
function byte DeadAlpha(PlayerReplicationInfo PRI, float Now)
{
    local int Index;
    local float Age;

    Index = DeadPRIs.Find(PRI);
    if (Index == INDEX_NONE)
    {
        Index = DeadPRIs.Length;
        DeadPRIs.AddItem(PRI);
        DeadSince.AddItem(Now);
    }

    Age = Now - DeadSince[Index];
    if (Age <= 2.0)
        return 255;
    if (Age >= 5.0)
        return 0;
    return byte(255 * (1.0 - (Age - 2.0) / 3.0));
}

// The map is open: spectators get every living player in their team colour; players on a team get the teammates the
// game's map leaves out, coloured like the game's own (their squad in the squad colour) with "SL" by squad leaders
function DrawSnapshotOnMap(Canvas C, ROHUD H, bool bSpectatorView)
{
    local ROHUDWidgetOverheadMap OM;
    local ROHUDWidgetComponent IconComp, LabelComp;
    local ROPlayerReplicationInfo ROPRI, MyPRI;
    local PlayerController PC;
    local Pawn P;
    local vector Loc;
    local vector2D S;
    local float BaseSize, Size, SizeModifier, XL, YL, LabelScale, Now;
    local int i;
    local byte Packed, Alpha;
    local Texture2D MapTex;
    local color Col;
    local string Label;

    OM = MapWidget;
    PC = PlayerController(Outer);
    if (OM == None || PC == None || OM.HUDComponents.Length <= class'ROHUDWidgetOverheadMap'.const.ROOMT_FriendlyPlayerStart)
        return;
    IconComp = OM.HUDComponents[class'ROHUDWidgetOverheadMap'.const.ROOMT_FriendlyPlayerStart];
    if (IconComp == None)
        return;

    // The size the game gives a player icon at this zoom, before its kind's size modifier
    BaseSize = (OM.CurrentZoom < 1.75 ? OM.PlayerSizeUnzoomed : OM.PlayerSizeZoomed) * IconComp.ScaleX;
    MyPRI = ROPlayerReplicationInfo(PC.PlayerReplicationInfo);
    Now = PC.WorldInfo.RealTimeSeconds;

    // Under the players, so a crew getting in is drawn on top
    if (bSpectatorView)
        DrawEmptyVehicles(C, H, OM, BaseSize);

    for (i = 0; i < class'CMMapInfo'.const.MAX_SNAPSHOT; i++)
    {
        ROPRI = Info.SnapPRI[i];
        if (ROPRI == None)
            continue;
        Packed = Info.SnapInfo[i];
        Loc = Info.SnapLoc[i];

        if ((Packed & class'CMMapInfo'.const.FLAG_DEAD) != 0)
        {
            Alpha = DeadAlpha(ROPRI, Now);
            if (Alpha == 0 || OM.DeadPlayerIcon == None)
                continue;
            MapTex = OM.DeadPlayerIcon;
            Size = OM.DeadPlayerIconSize * IconComp.ScaleX;
            Col = MakeColor(255, 255, 255, Alpha);
        }
        else
        {
            DeadPRIs.RemoveItem(ROPRI);
            // A teammate whose pawn this client can see is drawn where it really is, as the game does
            if (!bSpectatorView)
            {
                P = FindPawn(PC, ROPRI);
                if (P != None)
                    Loc = P.Location;
            }

            MapTex = MapIcon(OM, Packed, ROPRI, bSpectatorView, SizeModifier);
            Size = BaseSize * (bSpectatorView ? float(OM.InfantrySize) : SizeModifier);
            if (bSpectatorView)
                Col = TeamColour(H, Packed & class'CMMapInfo'.const.FLAG_SOUTH);
            else if (MyPRI != None && MyPRI.SquadIndex < `MAX_SQUADS && ROPRI.SquadIndex == MyPRI.SquadIndex)
                Col = OM.SquadDrawColor;
            else
                Col = OM.TeamDrawColor;
            Col.A = 255;
        }

        if (MapTex == None || Loc.X < MinWX || Loc.X > MaxWX || Loc.Y < MinWY || Loc.Y > MaxWY)
            continue;

        S = WorldToScreen(V2(Loc.X, Loc.Y));
        C.SetDrawColor(Col.R, Col.G, Col.B, Col.A);
        C.SetPos(S.X - Size * 0.5, S.Y - Size * 0.5);
        C.DrawTile(MapTex, Size, Size, 0, 0, MapTex.SizeX, MapTex.SizeY);

        // "SL1" and so on next to a left-out squad leader, as the game labels its own
        if (!bSpectatorView && (Packed & class'CMMapInfo'.const.FLAG_DEAD) == 0 && ROPRI.bIsSquadLeader && ROPRI.SquadIndex < `MAX_SQUADS)
        {
            Label = OM.SquadLeaderShortString $ (ROPRI.SquadIndex + 1);
            LabelComp = OM.HUDComponents[class'ROHUDWidgetOverheadMap'.const.ROOMT_ObjectiveLabelStart];
            if (LabelComp != None && LabelComp.TextFont != None)
                C.Font = LabelComp.TextFont;
            LabelScale = 1.0;
            if (LabelComp != None && LabelComp.TextScale > 0.0)
                LabelScale = LabelComp.TextScale;
            LabelScale *= IconComp.ScaleY;
            C.TextSize(Label, XL, YL);
            C.SetDrawColor(0, 0, 0, 255);
            C.SetPos(S.X + Size * 0.5 + 6 * IconComp.ScaleY + 1, S.Y - YL * LabelScale * 0.5 + 1);
            C.DrawText(Label, false, LabelScale, LabelScale);
            C.SetDrawColor(255, 255, 255, 255);
            C.SetPos(S.X + Size * 0.5 + 6 * IconComp.ScaleY, S.Y - YL * LabelScale * 0.5);
            C.DrawText(Label, false, LabelScale, LabelScale);
        }
    }

    ForgetOldDead(Now);
    C.Font = class'Engine'.static.GetSmallFont();
}

// Forget players who stayed dead long enough to have faded, and the hit counts of players who left
function ForgetOldDead(float Now)
{
    local int i;

    for (i = HurtPRIs.Length - 1; i >= 0; i--)
    {
        if (HurtPRIs[i] == None)
        {
            HurtPRIs.Remove(i, 1);
            HurtCounts.Remove(i, 1);
            FlashUntil.Remove(i, 1);
        }
    }

    for (i = DeadPRIs.Length - 1; i >= 0; i--)
    {
        if (DeadPRIs[i] == None || Now - DeadSince[i] > 10.0)
        {
            DeadPRIs.Remove(i, 1);
            DeadSince.Remove(i, 1);
        }
    }
}

// Spectators: the vehicles nobody is in, with the game's icon for the kind in the vehicle's team colour (grey when it
// has none), faded so they stand apart from vehicles with a crew
function DrawEmptyVehicles(Canvas C, ROHUD H, ROHUDWidgetOverheadMap OM, float BaseSize)
{
    local int i;
    local byte Data, Team;
    local float Size, SizeModifier;
    local Texture2D Tex;
    local color Col;
    local vector Loc;
    local vector2D S;

    Size = BaseSize * OM.InfantrySize;
    for (i = 0; i < class'CMMapInfo'.const.MAX_VEHICLES; i++)
    {
        Data = Info.VehInfo[i];
        if (Data < class'CMMapInfo'.const.VEH_PRESENT)
            continue;
        Loc = Info.VehLoc[i];
        if (Loc.X < MinWX || Loc.X > MaxWX || Loc.Y < MinWY || Loc.Y > MaxWY)
            continue;

        Tex = MapIcon(OM, class'CMMapInfo'.static.KindOf(Data) * class'CMMapInfo'.const.KIND_STEP, None, true, SizeModifier);
        if (Tex == None)
            continue;

        Team = Data & 3;
        Col = (Team < 2) ? TeamColour(H, Team) : MakeColor(190, 190, 190, 255);
        S = WorldToScreen(V2(Loc.X, Loc.Y));
        C.SetDrawColor(Col.R, Col.G, Col.B, 140);
        C.SetPos(S.X - Size * 0.5, S.Y - Size * 0.5);
        C.DrawTile(Tex, Size, Size, 0, 0, Tex.SizeX, Tex.SizeY);
    }
}

// The team whose flag this faction's is on this map, 255 for neither
static function int FlagTeam(WorldInfo WI, int Faction)
{
    if (class'CMAFlag'.static.FactionForTeam(WI, 0) == Faction)
        return 0;
    if (class'CMAFlag'.static.FactionForTeam(WI, 1) == Faction)
        return 1;
    return 255;
}

// What is happening to a flag, as a spectator's map says it
static function string FlagStatus(CMAFlag F)
{
    if (F.CarrierPRI != None)
        return "carried by "$F.CarrierPRI.PlayerName;
    if (F.bAtHome)
        return "at its spot";
    return "dropped";
}

// Spectators: every Capture the Flag flag, wherever it is and whoever's team could see it, with what is happening to it
function DrawFlagsOnMap(Canvas C, ROHUD H)
{
    local PlayerController PC;
    local CMAFlag F;
    local vector2D S;
    local color Col;
    local int Team;
    local float Size;
    local string FlagName;

    PC = PlayerController(Outer);
    Size = ICON_SIZE * UIScale;
    foreach PC.DynamicActors(class'CMAFlag', F)
    {
        if (F.bDeleteMe || F.Location.X < MinWX || F.Location.X > MaxWX || F.Location.Y < MinWY || F.Location.Y > MaxWY)
            continue;

        Team = FlagTeam(PC.WorldInfo, F.Faction);
        Col = (Team < 2) ? TeamColour(H, Team) : MakeColor(255, 255, 255, 255);
        S = WorldToScreen(V2(F.Location.X, F.Location.Y));
        DrawFlagIcon(C, S, Size, Col);

        FlagName = (F.Faction >= 0 && F.Faction < F.Factions.Length) ? F.Factions[F.Faction].Label$" flag" : "Flag";
        DrawLabel(C, V2(S.X + Size * 0.6, S.Y - Size * 0.2), FlagName$": "$FlagStatus(F), Col, false);
    }
}

// A small flag on a pole, the pole's foot at At
function DrawFlagIcon(Canvas C, vector2D At, float Size, color Col)
{
    local float PoleW, ClothW, ClothH, Top;

    PoleW = FMax(2.0, Size * 0.09);
    ClothW = Size * 0.6;
    ClothH = Size * 0.4;
    Top = At.Y - Size * 0.5;

    C.SetDrawColor(0, 0, 0, 220);
    C.SetPos(At.X - PoleW * 0.5 - 1, Top - 1);
    C.DrawTile(C.DefaultTexture, PoleW + 2, Size + 2, 0, 0, C.DefaultTexture.SizeX, C.DefaultTexture.SizeY);
    C.SetPos(At.X + PoleW * 0.5 - 1, Top - 1);
    C.DrawTile(C.DefaultTexture, ClothW + 2, ClothH + 2, 0, 0, C.DefaultTexture.SizeX, C.DefaultTexture.SizeY);

    C.SetDrawColor(230, 230, 230, 255);
    C.SetPos(At.X - PoleW * 0.5, Top);
    C.DrawTile(C.DefaultTexture, PoleW, Size, 0, 0, C.DefaultTexture.SizeX, C.DefaultTexture.SizeY);
    C.SetDrawColor(Col.R, Col.G, Col.B, 255);
    C.SetPos(At.X + PoleW * 0.5, Top);
    C.DrawTile(C.DefaultTexture, ClothW, ClothH, 0, 0, C.DefaultTexture.SizeX, C.DefaultTexture.SizeY);
}

// The icon the game puts where a player died, from the running map (WW2, Winter War and GOM may have their own)
function Texture2D DeathIcon(ROHUD H)
{
    if (H != None && H.OverheadMapWidget != None && H.OverheadMapWidget.DeadPlayerIcon != None)
        return H.OverheadMapWidget.DeadPlayerIcon;
    return class'ROHUDWidgetOverheadMap'.default.DeadPlayerIcon;
}

// Spectators: true while the player's marker flashes white after a hit. The server counts their hits; a new count is a
// new hit. The first count seen for a player is only remembered.
function bool Flashing(PlayerReplicationInfo PRI, byte Count, float Now)
{
    local int Index;

    Index = HurtPRIs.Find(PRI);
    if (Index == INDEX_NONE)
    {
        HurtPRIs.AddItem(PRI);
        HurtCounts.AddItem(Count);
        FlashUntil.AddItem(0);
        return false;
    }
    if (HurtCounts[Index] != Count)
    {
        HurtCounts[Index] = Count;
        FlashUntil[Index] = Now + FLASH_TIME;
    }
    return Now < FlashUntil[Index];
}

// While the player's marker flashes after a hit, whether it is white right now: white and the team colour take turns
// every STROBE_STEP, starting white
function bool StrobeWhite(PlayerReplicationInfo PRI, byte Count, float Now)
{
    local int Index;

    if (!Flashing(PRI, Count, Now))
        return false;
    Index = HurtPRIs.Find(PRI);
    return (int((Now - (FlashUntil[Index] - FLASH_TIME)) / STROBE_STEP) % 2) == 0;
}

// The warning strobe for a player bullets are passing close to: on for one step, off for the next
static function bool NearStrobeOn(float Now)
{
    return (int(Now / STROBE_STEP) % 2) == 0;
}

// Borders of the capture objectives built with CMenu, in the colour of the team that holds them (white while nobody does),
// fainter while the objective is closed. The shape is the one the objective captures in.
function DrawObjectiveBorders(Canvas C, PlayerController PC)
{
    local CMAObjective Objective;
    local ROGameReplicationInfo ROGRI;
    local int i;
    local color LineColor;

    ROGRI = ROGameReplicationInfo(PC.WorldInfo.GRI);
    if (ROGRI == None)
        return;

    foreach PC.DynamicActors(class'CMAObjective', Objective)
    {
        if (Objective.Corners.Length < 3 || !Objective.bObjectiveReady || Objective.bDeleteMe || Objective.ObjIndex >= `MAX_OBJECTIVES
            || !ROGRI.GetObjectiveEnabled(Objective.ObjIndex))
            continue;

        if (ROGRI.GetObjectiveOwner(Objective.ObjIndex) == `AXIS_TEAM_INDEX)
            LineColor = MakeColor(255, 80, 80, 255);
        else if (ROGRI.GetObjectiveOwner(Objective.ObjIndex) == `ALLIES_TEAM_INDEX)
            LineColor = MakeColor(80, 160, 255, 255);
        else
            LineColor = MakeColor(255, 255, 255, 220);
        if (!ROGRI.GetObjectiveActive(Objective.ObjIndex))
            LineColor.A = 110;

        for (i = 0; i < Objective.Corners.Length; i++)
        {
            DrawSegment(C, WorldToScreen(Objective.Corners[i]), WorldToScreen(Objective.Corners[(i + 1) % Objective.Corners.Length]),
                2.0 * UIScale, LineColor);
        }
    }
}

// Player on the screen, or false when they are behind the camera or off the edge
function bool ProjectToScreen(Canvas C, vector Loc, vector CamLoc, vector ViewDir, out vector Screen)
{
    if (((Loc - CamLoc) Dot ViewDir) <= 0)
        return false;

    Screen = C.Project(Loc);
    return Screen.X >= 0 && Screen.X <= C.ClipX && Screen.Y >= 0 && Screen.Y <= C.ClipY;
}

// A pawn the client can see for the player if there is one (exact position and size), none otherwise
function Pawn FindPawn(PlayerController PC, PlayerReplicationInfo PRI)
{
    local Pawn P;

    foreach PC.WorldInfo.AllPawns(class'Pawn', P)
    {
        if (P.PlayerReplicationInfo == PRI && P.Health > 0)
            return P;
    }
    return None;
}

function vector HeadLocation(Pawn P, vector Fallback)
{
    if (P == None)
        return Fallback + vect(0, 0, 40);

    return P.Location + vect(0, 0, 1) * (P.CylinderComponent.CollisionHeight - 4);
}

// The spectator's view with the map closed: triangles over players, the looked-at player's name and role icon
function DrawWorld(Canvas C, PlayerController PC, ROHUD H)
{
    local vector CamLoc, ViewDir, Head, Screen;
    local rotator CamRot;
    local Pawn P;
    local int i, Best;
    local float D, BestD, Scale, Size, Dist2D, Now;
    local color Col;
    local bool bAllNames;

    PC.GetPlayerViewPoint(CamLoc, CamRot);
    ViewDir = vector(CamRot);
    Scale = FMax(1.0, C.ClipY / 1080.0);
    Now = PC.WorldInfo.RealTimeSeconds;
    bAllNames = NamesKeyHeld(PC);

    // The player looked at: nearest the crosshair and close enough to it, and in sight unless within XRAY_NAME_DIST
    Best = -1;
    BestD = C.ClipX * NAME_RADIUS;
    for (i = 0; i < class'CMMapInfo'.const.MAX_SNAPSHOT; i++)
    {
        if (Info.SnapPRI[i] == None || (Info.SnapInfo[i] & class'CMMapInfo'.const.FLAG_DEAD) != 0)
            continue;
        P = FindPawn(PC, Info.SnapPRI[i]);
        if (P != None && P == PC.ViewTarget)
            continue;

        Head = HeadLocation(P, Info.SnapLoc[i]);
        if (!ProjectToScreen(C, Head, CamLoc, ViewDir, Screen))
            continue;

        // Within 15 meters the name and role show through walls; further away only for a player in sight
        D = Sqrt(Square(Screen.X - C.ClipX * 0.5) + Square(Screen.Y - C.ClipY * 0.5));
        if (D < BestD && (VSize(Head - CamLoc) <= XRAY_NAME_DIST || PC.FastTrace(Head, CamLoc)))
        {
            Best = i;
            BestD = D;
        }
    }

    for (i = 0; i < class'CMMapInfo'.const.MAX_SNAPSHOT; i++)
    {
        if (Info.SnapPRI[i] == None)
            continue;

        // Someone who has just died: the game's death icon over their body, fading as it does on the map
        if ((Info.SnapInfo[i] & class'CMMapInfo'.const.FLAG_DEAD) != 0)
        {
            DrawDeathInWorld(C, H, Info.SnapPRI[i], Info.SnapLoc[i], CamLoc, ViewDir, Scale, Now);
            continue;
        }
        DeadPRIs.RemoveItem(Info.SnapPRI[i]); // alive again, so their next death fades from the start

        P = FindPawn(PC, Info.SnapPRI[i]);
        if (P != None && P == PC.ViewTarget)
            continue;

        Head = HeadLocation(P, Info.SnapLoc[i]);
        if (!ProjectToScreen(C, Head, CamLoc, ViewDir, Screen))
            continue;

        // Strobing white for a couple of seconds after they are hit, like Arma's; strobing amber while bullets pass close
        // to them (a hit takes over from the warning)
        if (StrobeWhite(Info.SnapPRI[i], class'CMMapInfo'.static.HurtCountOf(Info.SnapInfo[i]), Now))
            Col = MakeColor(255, 255, 255, 255);
        else if (Info.SnapNear[i] != 0 && !Flashing(Info.SnapPRI[i], class'CMMapInfo'.static.HurtCountOf(Info.SnapInfo[i]), Now)
            && NearStrobeOn(Now))
            Col = MakeColor(255, 190, 0, 255);
        else
            Col = TeamColour(H, Info.SnapInfo[i] & class'CMMapInfo'.const.FLAG_SOUTH);
        Dist2D = VSize(Head - CamLoc);

        if (i == Best)
        {
            // Close up, the role they picked is shown under the name, as the game does for friendlies
            DrawNameTag(C, Info.SnapPRI[i], Screen, Col, Scale, Dist2D <= ROLE_ICON_DIST, 1.0);
        }
        else if (bAllNames)
        {
            // The names key held: everyone on screen, through walls, with their role, a little smaller than the one looked at
            DrawNameTag(C, Info.SnapPRI[i], Screen, Col, Scale, true, 0.75);
        }
        else
        {
            // Smaller the further away, down to a minimum that can still be seen, sitting just above their head
            Size = FClamp(22000.0 / FMax(Dist2D, 1.0), 12.0, 26.0) * Scale;
            DrawTriangle(C, Screen.X, Screen.Y, Size, Col);
        }
    }

    ForgetOldDead(Now);
    DrawTracers(C, H, CamLoc, ViewDir, Scale, Now);
    DrawCameraStrip(C, PC, H, Scale);
}

// ====================================================
// Tracers
// ====================================================

function float TracerLife(byte Data)
{
    switch (class'CMMapInfo'.static.TraceKindOf(Data))
    {
        case class'CMMapInfo'.const.TRACE_BULLET:  return BULLET_LIFE;
        case class'CMMapInfo'.const.TRACE_GRENADE: return GRENADE_LIFE;
    }
    return SHELL_LIFE;
}

// Takes the segments the server added since the last look and drops the ones that have faded. Called every frame, also
// with the map open, so a spectator who opens it doesn't get the last stretch of a firefight all at once.
function CollectTracers(bool bActive, float Now)
{
    local ClientTracer T;
    local int n, Head;

    if (!bActive)
    {
        Tracers.Length = 0;
        bTraceSynced = false;
        return;
    }

    // Starting to spectate, or a new map: what the ring holds is old, so begin from its head
    Head = Info.TraceHead;
    if (!bTraceSynced || Head < TraceSeen)
    {
        TraceSeen = Head;
        bTraceSynced = true;
    }

    for (n = Max(TraceSeen, Head - class'CMMapInfo'.const.MAX_TRACERS); n < Head; n++)
    {
        T.A = Info.TraceFrom[n % class'CMMapInfo'.const.MAX_TRACERS];
        T.B = Info.TraceTo[n % class'CMMapInfo'.const.MAX_TRACERS];
        T.Data = Info.TraceData[n % class'CMMapInfo'.const.MAX_TRACERS];
        T.Born = Now;
        Tracers.AddItem(T);
    }
    TraceSeen = Head;

    for (n = Tracers.Length - 1; n >= 0; n--)
    {
        if (Now - Tracers[n].Born >= TracerLife(Tracers[n].Data))
            Tracers.Remove(n, 1);
    }
    if (Tracers.Length > MAX_CLIENT_TRACERS)
        Tracers.Remove(0, Tracers.Length - MAX_CLIENT_TRACERS);
}

// Cuts a line to the part in front of the camera; false when none of it is
function bool ClipToView(vector CamLoc, vector ViewDir, out vector A, out vector B)
{
    local float DA, DB;

    DA = (A - CamLoc) Dot ViewDir;
    DB = (B - CamLoc) Dot ViewDir;
    if (DA < NEAR_PLANE && DB < NEAR_PLANE)
        return false;

    if (DA < NEAR_PLANE)
        A = A + (B - A) * ((NEAR_PLANE - DA) / (DB - DA));
    else if (DB < NEAR_PLANE)
        B = B + (A - B) * ((NEAR_PLANE - DB) / (DA - DB));
    return true;
}

// The paths of bullets, shells, rockets and grenades as lines in the world, in the colour of the team that fired them
// (white when not known). A new stretch burns white for a moment, then fades out over its kind's life. Bullets are thin,
// grenades a little thicker and shells and rockets thickest.
function DrawTracers(Canvas C, ROHUD H, vector CamLoc, vector ViewDir, float Scale, float Now)
{
    local vector A, B, SA, SB;
    local vector2D P1, P2;
    local color Col;
    local float Age, Life, Fade, Width, Glow;
    local byte Kind, Team;
    local int i;

    for (i = 0; i < Tracers.Length; i++)
    {
        Age = Now - Tracers[i].Born;
        Life = TracerLife(Tracers[i].Data);
        if (Age >= Life)
            continue;

        A = Tracers[i].A;
        B = Tracers[i].B;
        if (!ClipToView(CamLoc, ViewDir, A, B))
            continue;

        SA = C.Project(A);
        SB = C.Project(B);
        if ((SA.X < 0 && SB.X < 0) || (SA.X > C.ClipX && SB.X > C.ClipX) || (SA.Y < 0 && SB.Y < 0) || (SA.Y > C.ClipY && SB.Y > C.ClipY))
            continue;

        Kind = class'CMMapInfo'.static.TraceKindOf(Tracers[i].Data);
        Team = class'CMMapInfo'.static.TraceTeamOf(Tracers[i].Data);
        Col = TeamColour(H, Team);

        Glow = FClamp(1.0 - Age / TRACER_GLOW, 0.0, 1.0);
        Col.R = byte(Lerp(float(Col.R), 255.0, Glow));
        Col.G = byte(Lerp(float(Col.G), 255.0, Glow));
        Col.B = byte(Lerp(float(Col.B), 255.0, Glow));

        Fade = 1.0 - Age / Life;
        Col.A = byte(255.0 * FClamp(Fade * 1.5, 0.0, 1.0));

        Width = (Kind == class'CMMapInfo'.const.TRACE_BULLET ? 2.0 : (Kind == class'CMMapInfo'.const.TRACE_GRENADE ? 3.0 : 4.0)) * Scale;
        P1.X = SA.X;
        P1.Y = SA.Y;
        P2.X = SB.X;
        P2.Y = SB.Y;
        DrawScreenLine(C, P1, P2, Width, Col);
    }
}

// A player's name in Col with a dark shadow, its bottom just above Screen, and their role icon between the two when
// bRole. Size scales the whole tag.
function DrawNameTag(Canvas C, PlayerReplicationInfo PRI, vector Screen, color Col, float Scale, bool bRole, float Size)
{
    local Texture2D RoleIcon;
    local float W, TH, NameScale, IconSize, IconBottom;
    local string PlayerName;

    RoleIcon = None;
    if (bRole && ROPlayerReplicationInfo(PRI) != None && ROPlayerReplicationInfo(PRI).RoleInfo != None)
        RoleIcon = ROPlayerReplicationInfo(PRI).RoleInfo.ClassIcon;

    IconSize = (RoleIcon != None) ? 40.0 * Scale * Size : 0.0;
    IconBottom = Screen.Y - 1 * Scale;

    PlayerName = PRI.PlayerName;
    C.Font = class'Engine'.static.GetMediumFont();
    NameScale = NAME_SCALE * Scale * Size;
    C.TextSize(PlayerName, W, TH);
    W *= NameScale;
    TH *= NameScale;
    C.SetDrawColor(0, 0, 0, 255);
    C.SetPos(Screen.X - W * 0.5 + 2, IconBottom - IconSize - TH + 2);
    C.DrawText(PlayerName, true, NameScale, NameScale);
    C.SetPos(Screen.X - W * 0.5 - 1, IconBottom - IconSize - TH - 1);
    C.DrawText(PlayerName, true, NameScale, NameScale);
    C.SetDrawColor(Col.R, Col.G, Col.B, 255);
    C.SetPos(Screen.X - W * 0.5, IconBottom - IconSize - TH);
    C.DrawText(PlayerName, true, NameScale, NameScale);

    if (RoleIcon != None)
    {
        C.SetDrawColor(Col.R, Col.G, Col.B, 255);
        C.SetPos(Screen.X - IconSize * 0.5, IconBottom - IconSize);
        C.DrawTile(RoleIcon, IconSize, IconSize, 0, 0, RoleIcon.SizeX, RoleIcon.SizeY);
    }
}

// The key spectators hold to see every name, and whether it is down. It is read from the game's own list of held keys
// rather than caught here, so the game still gets it and a release missed (a menu opened while holding it) can't leave
// the names on.
function name NamesKey()
{
    return (ShowNamesKey != '') ? ShowNamesKey : 'LeftAlt';
}

function bool NamesKeyHeld(PlayerController PC)
{
    return PC != None && PC.PlayerInput != None && PC.PlayerInput.PressedKeys.Find(NamesKey()) != INDEX_NONE;
}

function DrawDeathInWorld(Canvas C, ROHUD H, PlayerReplicationInfo PRI, vector Loc, vector CamLoc, vector ViewDir, float Scale, float Now)
{
    local Texture2D Tex;
    local vector Screen;
    local float Size;
    local byte Alpha;

    Alpha = DeadAlpha(PRI, Now);
    Tex = DeathIcon(H);
    if (Alpha == 0 || Tex == None)
        return;

    Loc.Z += 30; // a little above the body
    if (!ProjectToScreen(C, Loc, CamLoc, ViewDir, Screen))
        return;

    Size = FClamp(26000.0 / FMax(VSize(Loc - CamLoc), 1.0), 16.0, 32.0) * Scale;
    C.SetDrawColor(255, 255, 255, Alpha);
    C.SetPos(Screen.X - Size * 0.5, Screen.Y - Size);
    C.DrawTile(Tex, Size, Size, 0, 0, Tex.SizeX, Tex.SizeY);
}

// ====================================================
// Spectator camera strip
// ====================================================

function string CameraModeName(PlayerController PC)
{
    local ROPlayerController ROPC;

    ROPC = ROPlayerController(PC);
    if (ROPC == None)
        return "";

    switch (ROPC.CurrentSpectateMode)
    {
        case SMODE_PawnFreeCam:     return "Third person, free camera";
        case SMODE_PawnThirdPerson: return "Third person";
        case SMODE_PawnFirstPerson: return "First person";
        case SMODE_Roaming:         return "Free roam";
        case SMODE_Viewpoint:       return "Map camera";
    }
    return "";
}

// Who (and what vehicle) the camera is on: "Smith", "Smith (M113 ACAV)", or "M113 ACAV" for a vehicle nobody is in
function string ViewedName(PlayerController PC, out PlayerReplicationInfo PRI)
{
    local Pawn P;
    local Vehicle V;
    local string VehicleName;

    PRI = None;
    P = Pawn(PC.ViewTarget);
    if (P == None || P == PC.Pawn)
        return "";

    PRI = P.PlayerReplicationInfo;
    V = Vehicle(P);
    if (ROWeaponPawn(P) != None)
        V = ROWeaponPawn(P).MyVehicle;
    if (PRI == None && V != None)
        PRI = V.PlayerReplicationInfo;
    if (ROVehicle(V) != None)
        VehicleName = ROVehicle(V).GetHumanReadableName();

    if (PRI == None)
        return VehicleName;
    if (VehicleName != "")
        return PRI.PlayerName$" ("$VehicleName$")";
    return PRI.PlayerName;
}

function color PRIColour(ROHUD H, PlayerReplicationInfo PRI)
{
    if (PRI != None && PRI.Team != None && PRI.Team.TeamIndex < 2)
        return TeamColour(H, PRI.Team.TeamIndex);
    return MakeColor(255, 255, 255, 255);
}

// Low in the middle of the screen: the camera mode, then the two players "previous" goes back to, the one watched now
// and the two "next" goes on to
function DrawCameraStrip(Canvas C, PlayerController PC, ROHUD H, float Scale)
{
    local array<string> Texts;
    local array<color> Cols;
    local array<float> Widths;
    local PlayerReplicationInfo Current;
    local string Mode, Watched;
    local float S, ModeS, XL, YL, ModeW, ModeH, Total, X, Y, BoxW, BoxH, Pad;
    local int i;
    local color Dim;

    Mode = CameraModeName(PC);
    Watched = ViewedName(PC, Current);
    if (Mode == "")
        Mode = "Spectating";
    // The hold key, after the camera mode
    if (NamesKeyHeld(PC))
        Mode $= "   |   Showing every name";
    else
        Mode $= "   |   Hold "$NamesKey()$": every name";

    if (Info.SpecPrev[1] != None) { Texts.AddItem(Info.SpecPrev[1].PlayerName); Cols.AddItem(PRIColour(H, Info.SpecPrev[1])); Texts.AddItem("  <  "); Cols.AddItem(MakeColor(160, 160, 160, 255)); }
    if (Info.SpecPrev[0] != None) { Texts.AddItem(Info.SpecPrev[0].PlayerName); Cols.AddItem(PRIColour(H, Info.SpecPrev[0])); Texts.AddItem("  <  "); Cols.AddItem(MakeColor(160, 160, 160, 255)); }
    if (Watched != "")            { Texts.AddItem(Watched); Cols.AddItem(MakeColor(255, 255, 255, 255)); }
    if (Info.SpecNext[0] != None) { Texts.AddItem("  >  "); Cols.AddItem(MakeColor(160, 160, 160, 255)); Texts.AddItem(Info.SpecNext[0].PlayerName); Cols.AddItem(PRIColour(H, Info.SpecNext[0])); }
    if (Info.SpecNext[1] != None) { Texts.AddItem("  >  "); Cols.AddItem(MakeColor(160, 160, 160, 255)); Texts.AddItem(Info.SpecNext[1].PlayerName); Cols.AddItem(PRIColour(H, Info.SpecNext[1])); }

    C.Font = class'Engine'.static.GetSmallFont();
    S = 1.25 * Scale;
    ModeS = 1.0 * Scale;
    Pad = 6 * Scale;
    for (i = 0; i < Texts.Length; i++)
    {
        C.TextSize(Texts[i], XL, YL);
        Widths.AddItem(XL * S);
        Total += XL * S;
    }
    C.TextSize("Ag", XL, YL);
    C.TextSize(Mode, ModeW, ModeH);
    ModeW *= ModeS;
    ModeH *= ModeS;

    BoxW = FMax(Total, ModeW) + Pad * 4;
    BoxH = ModeH + YL * S + Pad * 3;
    X = (C.ClipX - BoxW) * 0.5;
    Y = C.ClipY * 0.80;

    PushLayer(C, false);
    C.SetDrawColor(0, 0, 0, 150);
    C.SetPos(X, Y);
    C.DrawTile(C.DefaultTexture, BoxW, BoxH, 0, 0, C.DefaultTexture.SizeX, C.DefaultTexture.SizeY);
    PopLayer(C);

    PushLayer(C, true);
    C.SetDrawColor(200, 200, 200, 255);
    C.SetPos((C.ClipX - ModeW) * 0.5, Y + Pad);
    C.DrawText(Mode, false, ModeS, ModeS);

    X = (C.ClipX - Total) * 0.5;
    Y += Pad * 2 + ModeH;
    for (i = 0; i < Texts.Length; i++)
    {
        // The players either side a little dimmer than the one watched
        Dim = Cols[i];
        if (Texts[i] != Watched)
            Dim.A = 200;
        C.SetDrawColor(Dim.R, Dim.G, Dim.B, Dim.A);
        C.SetPos(X, Y);
        C.DrawText(Texts[i], false, S, S);
        X += Widths[i];
    }
    PopLayer(C);
}

// Filled triangle pointing down at (X, Y), with a black edge
function DrawTriangle(Canvas C, float X, float Y, float Size, color Col)
{
    local float Row, Half, Top;
    local color Black;

    Black.A = 255;
    Top = Y - Size;

    for (Row = 0; Row <= Size + 4; Row += 1.0)
    {
        Half = (Size + 4 - Row) * 0.5;
        C.Draw2DLine(X - Half - 2, Top - 2 + Row, X + Half + 2, Top - 2 + Row, Black);
    }
    for (Row = 0; Row <= Size; Row += 1.0)
    {
        Half = (Size - Row) * 0.5;
        C.Draw2DLine(X - Half, Top + Row, X + Half, Top + Row, Col);
    }
}

defaultproperties
{
    Colour=0
    Channel=1
}

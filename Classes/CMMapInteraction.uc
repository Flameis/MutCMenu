// Client side of everything MutCMenu adds to the overhead map, fed by CMMapInfo. Interactions are drawn after the HUD
// whatever HUD class the game (or WW2, Winter War, GOM) uses, so no HUD, widget or controller class is replaced:
//  - Spectator overlay: every living player on the map with the game's own player and vehicle icons in the team
//    colour; with the map closed, a team coloured triangle just above every player in view, and the player nearest the
//    crosshair gets their name in their team colour (and their role icon when close). The game's own player names are
//    switched off while it is on, so the two don't double up.
//  - Teammates the map leaves out (past 32 on a team): drawn like the game's own friendly icons, squad leaders with
//    their "SL" label, and for a few seconds after dying.
//  - CMenu's custom objectives: their borders, in the colour of the team holding them.
//  - Middle-click menus on the open map: on an empty spot, a quick menu to put a marker or label there; on a drawing,
//    move, erase, recolour or change its icon; on a player (scrim admins), the common Manage Players commands.
//  - Movement restrictions (the Restrict tool): lines, boxes and circles drawn on the map show dashed there, and in the
//    world as lines painted on the ground (decals, CMZoneDecals), for whoever the drawing is for.
//  - Enemies spotted with the spot key (Z): the game takes their mark off the map after 5 seconds; it is drawn on, in the
//    same place with the game's own icon, until SPOT_MAP_LIFE seconds after the spot. Only on the map: the mark in the
//    world and on the compass go when the game's does.
//  - Map drawings and the drawing toolbar (pointer, move, pen, line, arrow, circle, box, markers, text, eraser, ruler,
//    colours, who it is for, undo and clear), with the number keys picking the tools while the map cursor is up. It works with the game's own map cursor (ActualMouseLocation), and only takes a mouse
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
const TOOL_MOVE = 10;
const TOOL_ZONE = 11;   // movement restrictions, in the shape ZoneShape
const NUM_TOOLS = 12;

// The Restrict tool's shapes
const ZONE_LINES = 0;   // click point after point; clicking the first point again closes it
const ZONE_BOX = 1;
const ZONE_CIRCLE = 2;
const NUM_ZONE_SHAPES = 3;

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
const A_PLAYER_NAMES = 11;
const A_ICONS_MENU = 12;   // folds the Map icons menu open and shut
const A_MAP_ICON = 13;     // shows or hides one kind of map icon (Arg: a MAPICON_ value)
const A_ZONE_SHAPE = 14;   // picks the Restrict tool's shape (Arg: a ZONE_ value)
const A_CTX = 15;          // an entry of the middle-click menu (Arg: a CTX_ value)
const A_CTX_ICON = 16;     // a marker icon in the middle-click menu (Arg: the icon)
const A_CTX_COLOUR = 17;   // a colour in the middle-click menu on a drawing (Arg: the colour)

// The middle-click menus
const MENU_NONE = 0;
const MENU_QUICK = 1;      // on an empty spot: a marker or label there
const MENU_ITEM = 2;       // on a drawing
const MENU_PLAYER = 3;     // on a player (scrim admins)

const CTX_LABEL = 0;
const CTX_MOVE = 1;
const CTX_ERASE = 2;
const CTX_ICONS = 3;
const CTX_COLOURS = 4;
const CTX_TELEPORT = 5;
const CTX_DROP = 6;
const CTX_SWITCH = 7;
const CTX_RESPAWN = 8;
const CTX_KILL = 9;
const CTX_SAFETY_ON = 10;
const CTX_SAFETY_OFF = 11;
const CTX_WHOIS = 12;
const CTX_MORE = 13;

// The kinds of map icon the Map icons menu shows and hides
const MAPICON_PLAYERS = 0;  // spectators: every player
const MAPICON_VEHICLES = 1; // spectators: vehicles nobody is in
const MAPICON_FLAGS = 2;    // spectators: Capture the Flag flags
const MAPICON_DEATHS = 3;   // spectators: death icons
const MAPICON_BORDERS = 4;  // everyone: custom objective borders

const CONFIRM_TIME = 4.0;   // seconds a clear button waits for its second click
const FLASH_TIME = 2.5;     // seconds a spectator's marker over a player strobes white after they are hit
const STROBE_STEP = 0.12;   // seconds each white and each normal step of the strobe lasts

// Spectators: the paths projectiles fly (tracers), each segment fading over its kind's life
const BULLET_LIFE = 2.0;    // seconds a stretch of a bullet's path stays
const GRENADE_LIFE = 4.0;
const SHELL_LIFE = 5.0;
const TRACER_GLOW = 0.15;   // seconds a new stretch burns white before it takes its team's colour
const MAX_CLIENT_TRACERS = 600;
// Keeping a firefight from washing the screen out: lines are thinned as more are on screen, never reach full strength,
// and burn less white. A line right by the camera only fades a little: lines are cut at the screen's edge, so one passing
// close no longer smears, and fading them hard hid the shots of the player being watched.
const TRACER_NEAR_MIN = 25.0;    // unreal units (half a meter): a line this close is at its faintest
const TRACER_NEAR_MAX = 150.0;   // (3 meters): and from here out at full strength
const TRACER_NEAR_FLOOR = 0.6;   // how faint a line right beside the camera gets
const TRACER_COMFORT = 100.0;    // lines on screen before the rest start to be thinned
const TRACER_DENSITY_FLOOR = 0.3;
const TRACER_MAX_ALPHA = 0.85;
const TRACER_GLOW_MAX = 0.6;     // how much of the way to white a new line burns
const NEAR_PLANE = 20.0;    // unreal units; a line is cut here where it passes behind the camera

// Which teams' drawings a spectator sees
const SPEC_BOTH = 0;
const SPEC_NORTH = 1;
const SPEC_SOUTH = 2;

// Movement restrictions on the ground. Each shape is followed along the ground in steps of GROUND_STEP, the ground under
// each step found once with a trace from above (a few hundred a frame), and drawn as lines between them. Whether each
// point can be seen from the camera is checked a few hundred points a frame, so hills and walls hide the lines behind them.
const GROUND_STEP = 100.0;          // unreal units (2 meters) between points on the ground
const GROUND_MAX_POINTS = 4000;     // per shape; a longer one gets a longer step
const GROUND_TRACES_PER_FRAME = 300;
const GROUND_SIGHT_PER_FRAME = 250;
const GROUND_TRACE_HEIGHT = 40000.0; // the traces start this far above the shape and end this far below
const GROUND_LIFT = 20.0;           // the sight check aims this far above the ground point, so the ground itself doesn't block it
const ZONE_STRIP_WIDTH = 20.0;      // (40 cm) how wide the painted lines are
const ZONE_STRIP_MAX = 300.0;       // (6 meters) the longest piece of paint; the ground is followed point by point within it
const ZONE_STRIP_BUMP = 12.0;       // a piece goes on past a point only while the ground there is this close to its straight line
const ZONE_STRIP_DEPTH = 35.0;      // how far above and below its ends the paint reaches, so it lands on the ground and small things
const ZONE_STRIPS_PER_FRAME = 120;
const ZONE_VIEW_DIST = 15000.0;     // (300 meters) without decals, the lines are drawn this far out
const ZONE_FADE_DIST = 5000.0;      // and fade out over the last 100 meters of that
const ZONE_DASH = 10.0;             // pixels at 1080p: the dashes of a restriction on the map
const ZONE_GAP = 6.0;
const ZONE_CLOSE_RADIUS = 14.0;     // pixels at 1080p: a click this close to the first point closes the lines

const SPOT_MAP_LIFE = 30.0;  // seconds a spotted enemy's mark stays on the map, from the spot (the game's own goes after 5)
const SPOT_FADE = 3.0;       // the last seconds of that, which it fades out over

const BORDER_FILL_ALPHA = 0.12; // the fill inside a custom objective's border: this part of the border's strength
const BORDER_FILL_STEP = 2.0;   // pixels at 1080p: the height of each strip of that fill

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
const NAME_TRACES = 3;    // how many of the players nearest the crosshair are checked for being in sight, nearest first
const SNAP_PLACES = 128;  // CMMapInfo's MAX_SNAPSHOT (array sizes must be a constant of this class)
const PAWN_SLOTS = 256;   // the size of the player ID table that matches pawns to snapshot places (a power of two)

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
var config string ZoneDecalMaterial, ZoneDecalTexture; // the paint for movement restrictions (CMZoneDecals has the defaults)
var config bool bNoPlayerNames; // the player turned off the name shown when the cursor is over a player on the map (on when not set)
var config bool bIconsMenuOpen; // the Map icons menu in the toolbar is folded open
// Map icons turned off in the Map icons menu (all shown when not set)
var config bool bHideMapPlayers, bHideMapVehicles, bHideMapFlags, bHideMapDeaths, bHideObjectiveBorders;
var config name ShowNamesKey; // spectators hold it to see every name on screen; LeftAlt when not set (prone, which spectators don't use)
var config name TracersKey;   // spectators hold it to see the tracers, or tap it with Shift held to switch them on and off; RightControl when not set
var config byte SavedColour, SavedIcon;
var config byte ZoneShape;    // the Restrict tool's shape (ZONE_LINES when not set)

var byte Tool, Colour, Icon, Channel;
var bool bChannelPicked;       // the player picked Channel themselves, so it is only changed when no longer allowed
var bool bHideDrawings;
var byte SpecTeams;            // spectators: SPEC_BOTH, SPEC_NORTH or SPEC_SOUTH
var byte ArmedAction;          // a clear button clicked once, waiting for the second click; 255 for none
var float ArmedTime;
var array<ToolButton> Buttons; // laid out every frame; clicks use the last frame's
var bool bStyle;               // the player turned RS2 style on in CMenu Settings (read each frame)
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

var bool bMoving;    // the move tool is dragging the drawing MoveID, picked up at MoveFrom (world units)
var int MoveID;
var vector2D MoveFrom;

var byte CtxMenu;              // the middle-click menu that is open (MENU_NONE for none)
var vector2D CtxAt, CtxWorld;  // where it was opened: on the screen and in the world
var int CtxItemID;             // MENU_ITEM: the drawing
var string CtxPlayer;          // MENU_PLAYER: the player's name, as the commands take it
var bool bCtxBot;              // MENU_PLAYER: and they are a bot, which only some commands work on
var bool bCtxIcons, bCtxColours; // MENU_ITEM: the icon or colour choice is folded open
var byte CtxArmed;             // an entry clicked once that needs a second click (Kill, Switch Team); 255 for none
var float CtxArmedTime;
var float CtxX, CtxY, CtxW, CtxH; // where the menu was drawn last frame
var bool bCtxMove;             // the drawing CtxItemID follows the cursor until the next click puts it down
var bool bCtxDrop;             // the next click on the map is where the player CtxPlayer is dropped
var bool bMiddleOwned;         // the middle mouse press opened a menu, so its release is taken too

var bool bZoneLining;          // the Restrict tool's lines are being clicked out
var array<vector2D> ZonePoints; // and their points so far (world)
var bool bRightOwned;          // the right mouse press finished the lines, so its release is taken too

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

// The pawn shown for each snapshot player (as FindPawn gives it), found for all of them in one pass over the pawns once a
// frame. The pass looks each pawn's player up in a small table of player IDs to snapshot places.
var Pawn SnapPawn[SNAP_PLACES];
var int PawnSlotID[PAWN_SLOTS];      // the player ID + 1 held in that slot, 0 for an empty slot
var byte PawnSlotPlace[PAWN_SLOTS];  // and its snapshot place
var float PawnTableTime;             // when SnapPawn was last filled

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
var bool bTracerKeyDown;   // the tracers key was down last frame
var bool bTracerHold;      // the tracers key is held (without Shift): tracers show until it is let go
var bool bTracersLatched;  // Shift + the tracers key switched them on until the next time
var bool bNamesKeyDown;    // the names key was down last frame
var bool bNamesLatched;    // Shift + the names key switched every name on until the next time
var bool bTracersAsked;    // the server has been asked for tracers
var bool bWasSpectatorView; // the spectator overlay was on last frame

// Spectators: each player's hit count as last seen, and until when their marker flashes
var array<PlayerReplicationInfo> HurtPRIs;
var array<byte> HurtCounts;
var array<float> FlashUntil;

// Enemies the team spotted, kept on the map after the game takes its own mark off. A mark belongs to the team's spot slot
// it came from (Slot) until the game uses that slot for another spot, then stands alone (Slot 255) until it fades.
struct SpotMark
{
    var vector2D Loc;     // world X and Y
    var byte Type;        // the game's EnemyType for the slot: what kind of icon
    var byte Slot;
    var int GameFade;     // the game's fade time for the slot when this spot was made (game seconds)
    var float Until;      // RealTimeSeconds the mark goes
};
var array<SpotMark> SpotMarks;

// A movement restriction followed along the ground. Pts and Seen grow as the traces are done; Flat is the shape's path.
struct GroundZone
{
    var int ID;
    var string Sig;          // what the drawing was when this was made, so a moved one is made again
    var byte Colour;
    var array<vector2D> Flat;
    var array<vector> Pts;   // the ground under each point of Flat, as far as traced
    var array<byte> Seen;    // for each: 0 hidden from the camera, 1 in sight, 2 no ground found
    var array<DecalComponent> Strips; // the paint on the ground
    var int StripFrom;       // the point the paint goes on from (all painted when it reaches the last)
};
var array<GroundZone> GroundZones;
var CMZoneDecals ZoneDecals;   // the decals' owner on this player's game; made when first needed
var int SightZone, SightPoint; // where the sight checks go on from next frame
var int SeenSpotFade[`MAX_PLAYERS_PER_TEAM]; // the team's fade time for each slot, as last seen
var byte SpotTeam;                           // the team those are for; 255 for none

// ====================================================
// The map
// ====================================================

// When an objective is added or removed while the game runs (a custom objective), the game lays out every objective on
// its map again and gives the pieces the wrong sizes: the capture areas come out too big and out of place, and the names
// and letters the wrong size, until the screen is next resized (or the player changes team). The game's own resize puts
// them right, so it is run whenever a capture area has a size that resize would not give it. True when it ran.
static function bool KeepObjectiveSizes(ROHUDWidgetOverheadMap OM)
{
    local int i;

    if (OM == None || OM.Canvas == None || OM.PlayerOwner == None || OM.PlayerOwner.CurrentSpawnSelectScene != None
        || OM.HUDComponents.Length <= class'ROHUDWidgetOverheadMap'.const.ROOMT_Vingnette
        || OM.HUDComponents[class'ROHUDWidgetOverheadMap'.const.ROOMT_Vingnette] == None)
        return false;

    for (i = class'ROHUDWidgetOverheadMap'.const.ROOMT_ObjectiveZoneStart;
        i < class'ROHUDWidgetOverheadMap'.const.ROOMT_ObjectiveZoneStart + 16 && i < OM.HUDComponents.Length; i++)
    {
        if (OM.HUDComponents[i] != None && OM.HUDComponents[i].ScaleX != 1.0)
        {
            OM.ResetOverheadMapSize();
            return true;
        }
    }
    return false;
}

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

    if (Key == 'MiddleMouseButton')
    {
        if (EventType == IE_Pressed && bCursor)
        {
            if (bTyping)
                FinishTyping();
            bMiddleOwned = OpenContextMenu();
            return bMiddleOwned;
        }
        if (EventType == IE_Released && bMiddleOwned)
        {
            bMiddleOwned = false;
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
            // A move from the middle-click menu waits for the next click
            if (bMoving && !bCtxMove)
                FinishMove();
            return true;
        }
        return false;
    }

    if (bTyping)
        return TypeKey(Key, EventType);

    if (ZoneLineKey(Key, EventType))
        return true;

    // The number keys pick a tool while the map cursor is up (each button shows its key); otherwise they go to the game
    if (bCursor && !bToolsHidden && (EventType == IE_Pressed || EventType == IE_Repeat) && SlotForKey(Key) != INDEX_NONE && !CMenuOpen())
    {
        SelectTool(ToolInSlot(SlotForKey(Key)));
        return true;
    }

    if (Key == 'RightMouseButton' && CtxMenu != MENU_NONE && EventType == IE_Pressed)
    {
        CloseContextMenu();
        return true;
    }

    if (Key == 'Escape' && (bDragging || bMoving || bZoneLining || CtxMenu != MENU_NONE || bCtxDrop) && EventType == IE_Pressed)
    {
        Cancel();
        return true;
    }
    return false;
}

// The toolbar's order, which the number keys follow: 1 to 9, then 0 and - (the keys along the top of the keyboard)
static function byte ToolInSlot(int Slot)
{
    switch (Slot)
    {
        case 0:  return TOOL_POINTER;
        case 1:  return TOOL_MOVE;
        case 2:  return TOOL_PEN;
        case 3:  return TOOL_LINE;
        case 4:  return TOOL_ARROW;
        case 5:  return TOOL_CIRCLE;
        case 6:  return TOOL_BOX;
        case 7:  return TOOL_MARKER;
        case 8:  return TOOL_TEXT;
        case 9:  return TOOL_ERASER;
        case 10: return TOOL_RULER;
    }
    return TOOL_ZONE;
}

static function int SlotForKey(name Key)
{
    switch (Key)
    {
        case 'One':    return 0;
        case 'Two':    return 1;
        case 'Three':  return 2;
        case 'Four':   return 3;
        case 'Five':   return 4;
        case 'Six':    return 5;
        case 'Seven':  return 6;
        case 'Eight':  return 7;
        case 'Nine':   return 8;
        case 'Zero':   return 9;
        case 'Underscore': return 10; // the engine's name for the - key
        case 'Equals': return 11;
    }
    return INDEX_NONE;
}

static function string SlotKeyName(int Slot)
{
    if (Slot < 9)
        return string(Slot + 1);
    if (Slot == 11)
        return "=";
    return Slot == 9 ? "0" : "-";
}

// A CMenu is up and takes the number keys for its lines
function bool CMenuOpen()
{
    local PlayerController PC;
    local int i;

    PC = PlayerController(Outer);
    for (i = 0; PC != None && i < PC.Interactions.Length; i++)
    {
        if (CMenu(PC.Interactions[i]) != None && (PC.Interactions[i].IsInState('MenuVisible') || PC.Interactions[i].IsInState('FormVisible')))
            return true;
    }
    return false;
}

// Does what the left mouse button's Fire binding does (Button bFire | StartFire | OnRelease StopFire). Only when left
// mouse really is bound to fire; otherwise the click goes to the game as before. Nor while the player can't shoot (Realism
// Match's weapon safety, or the game holding fire): the click would do nothing at all, so it goes to the game's map, which
// shows its cursor for drawing.
function bool StartGameFire()
{
    local PlayerController PC;
    local name Key;

    PC = PlayerController(Outer);
    if (PC == None || PC.PlayerInput == None)
        return false;
    if (ROPlayerController(PC) != None && ROPlayerController(PC).IsFiringInputIgnored())
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
    // A click off the open menu closes it, and does nothing else
    if (CtxMenu != MENU_NONE)
    {
        bPressOwned = true;
        if (!InContextMenu(Mouse))
            CloseContextMenu();
        return true;
    }
    if (bCtxMove)
    {
        bPressOwned = true;
        bCtxMove = false;
        FinishMove();
        return true;
    }
    if (bCtxDrop)
    {
        bPressOwned = true;
        bCtxDrop = false;
        if (InMap(Mouse))
            DropPlayerAt(ScreenToWorld(Mouse));
        return true;
    }
    if (OverPanel(Mouse))
    {
        bPressOwned = true;
        return true;
    }
    if (Tool == TOOL_MOVE)
        return StartMove();
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
        case TOOL_ZONE:
            if (ZoneShape == ZONE_LINES)
            {
                ZoneClick(W);
                break;
            }
            // A box or circle is dragged out like the others
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

// The move tool picks up the drawing under the cursor, if it is one the player may erase (their own; their squad's for a
// squad leader, the team's for the commander, anyone's for a scrim admin). Elsewhere the click goes to the map.
function bool StartMove()
{
    local int Index;

    if (!InMap(Mouse) || (Info.bDrawingLocked && !Info.bScrimAdmin))
        return false;
    Index = PickItem(Mouse, true);
    if (Index == INDEX_NONE)
        return false;

    bPressOwned = true;
    bMoving = true;
    MoveID = Info.Items[Index].ID;
    MoveFrom = ScreenToWorld(Mouse);
    return true;
}

// How far (world units) the drawing being moved has been taken
function vector2D MoveOffset()
{
    local vector2D W;

    W = ScreenToWorld(ClampToMap(Mouse));
    return V2(W.X - MoveFrom.X, W.Y - MoveFrom.Y);
}

// A drawing as it is shown: the one being moved goes with the cursor
function MovedCopy(out CMMapInfo.ClientMapItem Item)
{
    local vector2D Offset;
    local int i;

    if (!bMoving || Item.ID != MoveID)
        return;
    Offset = MoveOffset();
    for (i = 0; i < Item.Points.Length; i++)
    {
        Item.Points[i].X += Offset.X;
        Item.Points[i].Y += Offset.Y;
    }
}

// Let go: the server moves it for everyone who sees it. It is moved here straight away; the server's copy replaces it.
function FinishMove()
{
    local vector2D Offset;
    local int Index;

    bMoving = false;
    Index = Info.FindItem(MoveID);
    if (Index == INDEX_NONE)
        return;
    Offset = MoveOffset();
    if (Sqrt(Square(Offset.X * ScaleY) + Square(Offset.Y * ScaleX)) < 3.0 * UIScale)
        return;

    Info.ServerMoveItem(MoveID, Round(Offset.X), Round(Offset.Y));
    MovedLocally(Index, Round(Offset.X), Round(Offset.Y));
}

function MovedLocally(int Index, int DX, int DY)
{
    local int i;

    for (i = 0; i < Info.Items[Index].Points.Length; i++)
    {
        Info.Items[Index].Points[i].X += DX;
        Info.Items[Index].Points[i].Y += DY;
    }
}

function bool OverPanel(vector2D S)
{
    return S.X >= PanelX && S.X <= PanelX + PanelW && S.Y >= PanelY && S.Y <= PanelY + PanelH;
}

// The newest button first: the middle-click menu is drawn over the toolbar
function int ButtonAt(vector2D S)
{
    local int i;

    for (i = Buttons.Length - 1; i >= 0; i--)
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
        case A_ZONE_SHAPE:
            Cancel();
            ZoneShape = B.Arg;
            SaveConfig();
            break;
        case A_CTX:
            ContextEntry(B.Arg);
            break;
        case A_CTX_ICON:
            ContextIcon(B.Arg);
            break;
        case A_CTX_COLOUR:
            Info.ServerRestyleItem(CtxItemID, B.Arg, 255);
            CloseContextMenu();
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
        case A_PLAYER_NAMES:
            bNoPlayerNames = !bNoPlayerNames;
            SaveConfig();
            break;
        case A_ICONS_MENU:
            bIconsMenuOpen = !bIconsMenuOpen;
            SaveConfig();
            break;
        case A_MAP_ICON:
            ToggleMapIcon(B.Arg);
            break;
    }
}

// The Map icons menu: whether one kind of map icon is shown
function bool MapIconShown(byte Which)
{
    switch (Which)
    {
        case MAPICON_PLAYERS:  return !bHideMapPlayers;
        case MAPICON_VEHICLES: return !bHideMapVehicles;
        case MAPICON_FLAGS:    return !bHideMapFlags;
        case MAPICON_DEATHS:   return !bHideMapDeaths;
        case MAPICON_BORDERS:  return !bHideObjectiveBorders;
    }
    return true;
}

function ToggleMapIcon(byte Which)
{
    switch (Which)
    {
        case MAPICON_PLAYERS:  bHideMapPlayers = !bHideMapPlayers; break;
        case MAPICON_VEHICLES: bHideMapVehicles = !bHideMapVehicles; break;
        case MAPICON_FLAGS:    bHideMapFlags = !bHideMapFlags; break;
        case MAPICON_DEATHS:   bHideMapDeaths = !bHideMapDeaths; break;
        case MAPICON_BORDERS:  bHideObjectiveBorders = !bHideObjectiveBorders; break;
        default: return;
    }
    SaveConfig();
}

static function string MapIconName(byte Which)
{
    switch (Which)
    {
        case MAPICON_PLAYERS:  return "Players";
        case MAPICON_VEHICLES: return "Vehicles";
        case MAPICON_FLAGS:    return "Flags";
        case MAPICON_DEATHS:   return "Deaths";
        case MAPICON_BORDERS:  return "Borders";
    }
    return "";
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
    if (!ToolAllowed(NewTool))
        return;
    Cancel();
    Tool = NewTool;
}

// The Restrict tool is for scrim admins only (the server refuses restrictions from anyone else too)
function bool ToolAllowed(byte Which)
{
    return Which != TOOL_ZONE || Info.bScrimAdmin;
}

// Stops whatever was being drawn or typed, without sending it
function Cancel()
{
    bDragging = false;
    bMoving = false;
    bTyping = false;
    bZoneLining = false;
    ZonePoints.Length = 0;
    DragPoints.Length = 0;
    CloseContextMenu();
    bCtxMove = false;
    bCtxDrop = false;
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
static function string KeyChar(name Key, bool bShifted)
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
        case 'Underscore':  return bShifted ? "_" : "-"; // the engine's name for the - key
        case 'Equals':      return bShifted ? "+" : "=";
        case 'Slash':       return bShifted ? "?" : "/";
        case 'Semicolon':   return bShifted ? ":" : ";";
        case 'Quote':       return bShifted ? "\"" : "'";
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
        Kind = DragKind();
        Send(Kind, DragPoints, "");
    }
    DragPoints.Length = 0;
}

// What the tool being dragged makes: the drag tools are in the same order as the kinds; the Restrict tool makes a box or
// circle restriction, and the ruler measures with a line
function byte DragKind()
{
    if (Tool == TOOL_RULER)
        return class'CMMapInfo'.const.KIND_LINE;
    if (Tool == TOOL_ZONE)
        return ZoneShape == ZONE_CIRCLE ? class'CMMapInfo'.const.KIND_ZONE_CIRCLE : class'CMMapInfo'.const.KIND_ZONE_BOX;
    return Tool - TOOL_PEN;
}

// The Restrict tool's lines: each click adds a point, joined to the last by a straight line. A click on the first point
// closes the shape; a double click, a right click or Enter ends it where it is.
function ZoneClick(vector2D W)
{
    local vector2D S;

    S = WorldToScreen(W);
    if (!bZoneLining)
    {
        bZoneLining = true;
        ZonePoints.Length = 0;
        ZonePoints.AddItem(W);
        return;
    }

    if (ZonePoints.Length >= 2 && Dist(S, WorldToScreen(ZonePoints[0])) <= ZONE_CLOSE_RADIUS * UIScale)
    {
        ZonePoints.AddItem(ZonePoints[0]);
        FinishZoneLines();
        return;
    }
    // The second click of a double click lands on the point just made: it ends the lines
    if (Dist(S, WorldToScreen(ZonePoints[ZonePoints.Length - 1])) < 4.0 * UIScale)
    {
        FinishZoneLines();
        return;
    }

    ZonePoints.AddItem(W);
    // Too many points for one drawing: it goes in pieces, each starting where the last ended
    if (ZonePoints.Length >= class'CMMapInfo'.const.MAX_POINTS)
    {
        Send(class'CMMapInfo'.const.KIND_ZONE_LINES, ZonePoints, "");
        ZonePoints.Remove(0, ZonePoints.Length - 1);
    }
}

function FinishZoneLines()
{
    if (ZonePoints.Length >= 2)
        Send(class'CMMapInfo'.const.KIND_ZONE_LINES, ZonePoints, "");
    bZoneLining = false;
    ZonePoints.Length = 0;
}

// Right click and Enter end the lines, Backspace takes the last point back. True when the key was taken.
function bool ZoneLineKey(name Key, EInputEvent EventType)
{
    if (Key == 'RightMouseButton' && EventType == IE_Released && bRightOwned)
    {
        bRightOwned = false;
        return true;
    }
    if (!bZoneLining || EventType != IE_Pressed)
        return false;

    switch (Key)
    {
        case 'RightMouseButton':
            bRightOwned = true;
            FinishZoneLines();
            return true;
        case 'Enter':
            FinishZoneLines();
            return true;
        case 'BackSpace':
            ZonePoints.Remove(ZonePoints.Length - 1, 1);
            if (ZonePoints.Length == 0)
                bZoneLining = false;
            return true;
    }
    return false;
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
        if (bErasable && !class'CMMapInfo'.static.CanEraseItem(PC.PlayerReplicationInfo, Info.bScrimAdmin, Info.Items[i].Kind, Info.Items[i].Team, Info.Items[i].Squad, Info.Items[i].OwnerID))
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
        case class'CMMapInfo'.const.KIND_ZONE_CIRCLE:
            if (Item.Points.Length < 2)
                return 100000.0;
            R = CircleRadius(Item);
            return Abs(Dist(S, A) - R);

        case class'CMMapInfo'.const.KIND_BOX:
        case class'CMMapInfo'.const.KIND_ZONE_BOX:
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
    local CMMapInfo.ClientMapItem Preview, Shown;
    local ROHUDWidgetComponent CursorComp;
    local bool bSpectatorView, bNameHover;

    PC = PlayerController(Outer);
    if (C == None || PC == None || Info == None || Info.bDeleteMe)
    {
        MapState = "no player or map info";
        return;
    }
    H = ROHUD(PC.myHUD);
    if (H != None)
        KeepObjectiveSizes(H.OverheadMapWidget);

    // The spectator overlay is on while the owner spectates and the server sends them everyone
    bSpectatorView = Info.bSpectating && H != None && PC.PlayerReplicationInfo != None && PC.PlayerReplicationInfo.bOnlySpectator;
    if (bWasSpectatorView && !bSpectatorView)
        LeaveSpectatorView();
    bWasSpectatorView = bSpectatorView;
    SetDefaultNames(H, bSpectatorView);
    UpdateTracerRequest(PC, bSpectatorView);
    UpdateNamesLatch(PC, bSpectatorView);
    CollectTracers(bSpectatorView && (bTracersAsked || Info.bTracersOn), PC.WorldInfo.RealTimeSeconds);
    TrackSpots(PC);
    UpdateGroundZones(PC);

    if (ReadMap() == None)
    {
        Cancel();
        // The movement restrictions on the ground, with the map closed (open, it covers the view)
        // The movement restrictions over the view, only when they can't be painted on the ground
        if (H != None && H.bShowHud && Info.bDrawingEnabled && !bHideDrawings && !UsePaint(PC))
            DrawZonesInWorld(C, PC);
        // With the map closed, the spectator's names and triangles (with it open they would only clutter it)
        if (bSpectatorView && H.bShowHud)
            DrawWorld(C, PC, H);
        return;
    }

    UIScale = FMax(0.75, C.ClipY / 1080.0);
    C.Font = class'Engine'.static.GetSmallFont();

    // Each kind of thing on the map in its own layer, so what must be on top always is (see PushLayer for the order)
    PushPriority(C, DSP_High);
    if (MapIconShown(MAPICON_BORDERS))
        DrawObjectiveBorders(C, PC);
    PopLayer(C);

    PushPriority(C, DSP_Highest);
    if (Info.bDrawingEnabled)
    {
        ValidateChannel(PC.PlayerReplicationInfo);
        // A scrim admin who logs out loses the Restrict tool
        if (!ToolAllowed(Tool))
            SelectTool(TOOL_POINTER);

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
                    {
                        Shown = Info.Items[i];
                        MovedCopy(Shown);
                        DrawGlow(C, Shown, TeamColour(H, Shown.Team));
                    }
                }
            }
            for (i = 0; i < Info.Items.Length; i++)
            {
                if (!ItemShown(Info.Items[i], PC.PlayerReplicationInfo))
                    continue;
                if (bMoving && Info.Items[i].ID == MoveID)
                {
                    // The one being moved: its outline where it was, and the drawing at the cursor
                    DrawItem(C, Info.Items[i], true);
                    Shown = Info.Items[i];
                    MovedCopy(Shown);
                    DrawItem(C, Shown, false);
                }
                else
                    DrawItem(C, Info.Items[i], false);
            }
            for (i = 0; i < Sent.Length; i++)
                DrawItem(C, Sent[i].Item, false);
        }

        if (bZoneLining)
        {
            Preview.Kind = class'CMMapInfo'.const.KIND_ZONE_LINES;
            Preview.Colour = Colour;
            Preview.Points = ZonePoints;
            Preview.Points.AddItem(ScreenToWorld(ClampToMap(Mouse)));
            DrawItem(C, Preview, false);
            // The first point, where a click closes the shape
            if (ZonePoints.Length >= 2)
                DrawCross(C, WorldToScreen(ZonePoints[0]), ZONE_CLOSE_RADIUS * UIScale * 0.5, 2.0 * UIScale, class'CMMapInfo'.static.GetColour(Colour), false);
        }

        if (bDragging)
        {
            UpdateDrag();
            Preview.Kind = DragKind();
            Preview.Colour = (Tool == TOOL_RULER) ? 6 : Colour;
            Preview.Points = DragPoints;
            DrawItem(C, Preview, false);
            DrawMeasure(C);
        }

        if (bTyping)
            DrawLabel(C, WorldToScreen(TypeAt), TypeText $ "_", class'CMMapInfo'.static.GetColour(Colour), false);
    }
    PopLayer(C);

    // Players in the game's own player layer, over the objectives and the drawings. A snapshot made for the other view
    // (just after joining a team from spectating, or the other way round, before the server's next one) is left alone:
    // drawn as teammates, a spectator's snapshot would show the whole server.
    PushPriority(C, DSP_SkyHigh);
    DrawSpotMarks(C, PC);
    if (Info.bSpectating == bSpectatorView)
        DrawSnapshotOnMap(C, H, bSpectatorView);
    if (bSpectatorView && MapIconShown(MAPICON_FLAGS))
        DrawFlagsOnMap(C, H);
    PopLayer(C);

    // The name of the player under the cursor, whether or not drawing is on
    bNameHover = DrawPlayerHover(C, PC, H, bSpectatorView);

    if (!Info.bDrawingEnabled)
    {
        SetMapState("map drawing is off on this server");
        return;
    }

    DrawToolbar(C, PC);
    DrawContextMenu(C, PC);
    SetMapState("drawn");

    // Who drew what under the cursor; the eraser also shows what it would take
    if (bCursor && !bNameHover && !bToolsHidden && !bDragging && !bMoving && CtxMenu == MENU_NONE && !OverPanel(Mouse) && InMap(Mouse))
    {
        Hover = PickItem(Mouse, Tool == TOOL_ERASER || Tool == TOOL_MOVE);
        if (Hover != INDEX_NONE)
        {
            if (Tool == TOOL_ERASER || Tool == TOOL_MOVE)
            {
                PushPriority(C, DSP_Highest);
                DrawItem(C, Info.Items[Hover], true);
                PopLayer(C);
            }
            // Up and to the right of the cursor, where a player's name goes, so the cursor never covers it
            DrawLabel(C, V2(Mouse.X + 14 * UIScale, Mouse.Y - 16 * UIScale), Info.Items[Hover].OwnerName $ " ("
                $ class'CMMapInfo'.static.AudienceName(PC.PlayerReplicationInfo, Info.Items[Hover].Team, Info.Items[Hover].Squad) $ ")",
                MakeColor(255, 255, 255, 255), true);
        }
    }

    // The game drew its cursor before this; draw it again so it stays on top of the toolbar and the drawings. It goes in
    // the top layer, where the game draws its own cursor, above the toolbar's two.
    CursorComp = MapWidget.HUDComponents[class'ROHUDWidgetOverheadMap'.const.ROOMT_MousePointer];
    if (bCursor && CursorComp != None)
    {
        PushPriority(C, DSP_Insane);
        DrawCursor(C, CursorComp);
        PopLayer(C);
    }
}

// The map is open and the cursor is over a player's icon: their name next to the cursor, in their team's colour. Players
// see the teammates the game draws on their map (and the ones it leaves out); spectators see everyone. Off when the player
// turned Names off in the toolbar's Map icons menu (and, for spectators, when Players is off there). Returns true when a name was shown.
function bool DrawPlayerHover(Canvas C, PlayerController PC, ROHUD H, bool bSpectatorView)
{
    local ROPlayerReplicationInfo Best;
    local byte BestTeam;
    local color Col;

    if (bNoPlayerNames || !bCursor || bDragging || bMoving || OverPanel(Mouse) || !InMap(Mouse))
        return false;
    // A spectator who hid the players gets no names for them either
    if (bSpectatorView && !MapIconShown(MAPICON_PLAYERS))
        return false;

    if (CtxMenu != MENU_NONE)
        return false;

    Best = PlayerAt(PC, Mouse, bSpectatorView, BestTeam);
    if (Best == None)
        return false;

    Col = bSpectatorView ? TeamColour(H, BestTeam) : MakeColor(255, 255, 255, 255);
    // Up and to the right of the cursor, so the cursor (which hangs down and right from its tip) never covers it
    DrawLabel(C, V2(Mouse.X + 14 * UIScale, Mouse.Y - 16 * UIScale), Best.PlayerName, Col, true);
    return true;
}

// The player whose map icon is nearest S and close enough to it: the living teammates the game's map shows, and the
// players the server sends (everyone to a spectator, teammates past 32), never the player themselves
function ROPlayerReplicationInfo PlayerAt(PlayerController PC, vector2D S0, bool bSpectatorView, out byte BestTeam)
{
    local ROPlayerReplicationInfo ROPRI, MyPRI, Best;
    local ROTeamInfo Team;
    local Pawn P;
    local array<ROPlayerReplicationInfo> SeenPRIs;
    local array<vector> SeenLocs;
    local vector2D S;
    local float X, Y, Z, BestDist, D;
    local int i, Seen;

    MyPRI = ROPlayerReplicationInfo(PC.PlayerReplicationInfo);
    BestDist = (PICK_RADIUS + 4.0) * UIScale;

    // The players the game's own map shows: living teammates, not the player
    if (!bSpectatorView && MyPRI != None)
    {
        Team = ROTeamInfo(MyPRI.Team);
        if (Team != None)
        {
            // Teammates this game can see are drawn by the game where their pawn is; the team's location list can lag
            foreach PC.WorldInfo.AllPawns(class'Pawn', P)
            {
                if (P.Health > 0 && ROPlayerReplicationInfo(P.PlayerReplicationInfo) != None && P.PlayerReplicationInfo.Team == Team)
                {
                    SeenPRIs.AddItem(ROPlayerReplicationInfo(P.PlayerReplicationInfo));
                    SeenLocs.AddItem(P.Location);
                }
            }

            for (i = 0; i < `MAX_PLAYERS_PER_TEAM; i++)
            {
                ROPRI = Team.TeamPRIArray[i];
                if (ROPRI == None || ROPRI == MyPRI || ROPRI.bDead || ROPRI.RoleInfo == None)
                    continue;
                Seen = SeenPRIs.Find(ROPRI);
                if (Seen != INDEX_NONE)
                {
                    X = SeenLocs[Seen].X;
                    Y = SeenLocs[Seen].Y;
                }
                else
                    Team.GetTeamLocationEntry(i, X, Y, Z);
                S = WorldToScreen(V2(X, Y));
                D = Dist(S, S0);
                if (D < BestDist)
                {
                    BestDist = D;
                    Best = ROPRI;
                    BestTeam = Team.GetTeamNum();
                }
            }
        }
    }

    // The ones sent by the server: everyone to a spectator, and the teammates past the game's 32
    for (i = 0; i < class'CMMapInfo'.const.MAX_SNAPSHOT; i++)
    {
        ROPRI = Info.SnapPRI[i];
        if (ROPRI == None || ROPRI == MyPRI || (Info.SnapInfo[i] & class'CMMapInfo'.const.FLAG_DEAD) != 0)
            continue;
        S = WorldToScreen(V2(Info.SnapLoc[i].X, Info.SnapLoc[i].Y));
        D = Dist(S, S0);
        if (D < BestDist)
        {
            BestDist = D;
            Best = ROPRI;
            BestTeam = Info.SnapInfo[i] & class'CMMapInfo'.const.FLAG_SOUTH;
        }
    }
    return Best;
}

// The canvas draws everything with the same texture together, in the order each texture was first used. So text drawn
// after a box could end up under it when the same font had been used earlier in the frame (a label typed on the map took
// the toolbar's text with it, a marker on the map the toolbar's marker icons), and an icon drawn after a line could end
// up under it. Whatever has to be on top of something else goes in a higher layer. From the bottom:
//  - DSP_AboveNormal: the game's map picture and grid.
//  - DSP_High: CMenu's objective borders, with the game's objective links and its own vehicle icons.
//  - DSP_Highest: the game's objective areas and icons; the map drawings; the toolbar's boxes (bTop false).
//  - DSP_SkyHigh: player, vehicle, death and flag icons, in the game's own player layer; the toolbar's text and icons
//    (bTop true); the boxes of the labels by the cursor (see DrawLabel).
//  - DSP_Insane: the text of the labels by the cursor, as CMenu draws its text, and the cursor (the game draws its own
//    cursor there and this one again last).
function PushLayer(Canvas C, bool bTop)
{
    if (ROCanvas(C) == None)
        return;
    if (bTop)
        ROCanvas(C).PushDepthSortPriority(DSP_SkyHigh);
    else
        ROCanvas(C).PushDepthSortPriority(DSP_Highest);
}

function PushPriority(Canvas C, DepthSortPriority Priority)
{
    if (ROCanvas(C) != None)
        ROCanvas(C).PushDepthSortPriority(Priority);
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
    // Where the game put its own: its tip at the mouse normally, but centred on it while the map is dragged (with the
    // right mouse button), so drawing it at the mouse showed a second dragging cursor half a cursor off
    C.SetPos(MapWidget.CurrentX + CursorComp.CurX, MapWidget.CurrentY + CursorComp.CurY);
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
    return ClipToRect(A, B, MapLeft, MapTop, MapW, MapH);
}

// Liang-Barsky: cuts the segment to a rectangle, false when none of it is inside
function bool ClipToRect(out vector2D A, out vector2D B, float Left, float Top, float W, float H)
{
    local float T0, T1, DX, DY, P[4], Q[4], R;
    local int i;

    T0 = 0.0;
    T1 = 1.0;
    DX = B.X - A.X;
    DY = B.Y - A.Y;
    P[0] = -DX; Q[0] = A.X - Left;
    P[1] = DX;  Q[1] = Left + W - A.X;
    P[2] = -DY; Q[2] = A.Y - Top;
    P[3] = DY;  Q[3] = Top + H - A.Y;

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

        // Movement restrictions are dashed, so they stand apart from the drawings
        case class'CMMapInfo'.const.KIND_ZONE_CIRCLE:
            R = CircleRadius(Item);
            Prev = V2(A.X + R, A.Y);
            for (i = 1; i <= 64; i++)
            {
                Next = V2(A.X + R * Cos(i * 2 * Pi / 64), A.Y + R * Sin(i * 2 * Pi / 64));
                if (i % 2 == 1)
                    DrawSegment(C, Prev, Next, Width, Col);
                Prev = Next;
            }
            return;

        case class'CMMapInfo'.const.KIND_ZONE_BOX:
            DrawDashed(C, A, V2(B.X, A.Y), Width, Col);
            DrawDashed(C, V2(B.X, A.Y), B, Width, Col);
            DrawDashed(C, B, V2(A.X, B.Y), Width, Col);
            DrawDashed(C, V2(A.X, B.Y), A, Width, Col);
            return;

        case class'CMMapInfo'.const.KIND_ZONE_LINES:
            for (i = 1; i < Item.Points.Length; i++)
            {
                B = WorldToScreen(Item.Points[i]);
                DrawDashed(C, A, B, Width, Col);
                A = B;
            }
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

// A dashed line on the map
function DrawDashed(Canvas C, vector2D A, vector2D B, float Width, color Col)
{
    local float Len2D, T, Dash, Step;
    local vector2D Dir;

    Len2D = Dist(A, B);
    if (Len2D < 0.5)
        return;
    Dir = V2((B.X - A.X) / Len2D, (B.Y - A.Y) / Len2D);
    Dash = ZONE_DASH * UIScale;
    Step = Dash + ZONE_GAP * UIScale;
    for (T = 0; T < Len2D; T += Step)
        DrawSegment(C, V2(A.X + Dir.X * T, A.Y + Dir.Y * T), V2(A.X + Dir.X * FMin(T + Dash, Len2D), A.Y + Dir.Y * FMin(T + Dash, Len2D)), Width, Col);
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
        DrawCross(C, At, Size * 0.4, LINE_WIDTH * UIScale + 2, Black, bAnywhere);
        DrawCross(C, At, Size * 0.4, LINE_WIDTH * UIScale, Col, bAnywhere);
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

// The X marker. On the map its strokes are cut to the map; the toolbar's button is off the map, where cutting them left
// nothing, so there (bAnywhere) they aren't.
function DrawCross(Canvas C, vector2D At, float R, float Width, color Col, bool bAnywhere)
{
    if (bAnywhere)
    {
        DrawScreenLine(C, V2(At.X - R, At.Y - R), V2(At.X + R, At.Y + R), Width, Col);
        DrawScreenLine(C, V2(At.X - R, At.Y + R), V2(At.X + R, At.Y - R), Width, Col);
        return;
    }
    DrawSegment(C, V2(At.X - R, At.Y - R), V2(At.X + R, At.Y + R), Width, Col);
    DrawSegment(C, V2(At.X - R, At.Y + R), V2(At.X + R, At.Y - R), Width, Col);
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
        // The box over the player icons and its text above that, or the text could end up under the box (see PushLayer)
        PushPriority(C, DSP_SkyHigh);
        C.SetDrawColor(0, 0, 0, 180);
        C.SetPos(At.X - 4 * UIScale, At.Y - YL * 0.5 - 2 * UIScale);
        C.DrawTile(C.DefaultTexture, XL + 8 * UIScale, YL + 4 * UIScale, 0, 0, C.DefaultTexture.SizeX, C.DefaultTexture.SizeY);
        PopLayer(C);
        PushPriority(C, DSP_Insane);
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
// From the button First on (the middle-click menu draws its own after the toolbar's)
function DrawButtonLayers(Canvas C, optional int First)
{
    PushLayer(C, false);
    DrawButtons(C, false, First);
    PopLayer(C);
    PushLayer(C, true);
    DrawButtons(C, true, First);
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
        case TOOL_MOVE:   return "Move";
        case TOOL_ZONE:   return "Restrict";
    }
    return "Pointer";
}

static function string ZoneShapeName(byte Which)
{
    switch (Which)
    {
        case ZONE_BOX:    return "Box";
        case ZONE_CIRCLE: return "Circle";
    }
    return "Lines";
}

function string ToolHint(PlayerController PC)
{
    if (!bCursor)
        return "Press "$CursorKeyName()$" for the cursor";
    if (CtxMenu != MENU_NONE)
        return "Pick one, or Escape";
    if (bCtxMove)
        return "Click where it goes";
    if (bCtxDrop)
        return "Click where they go";
    if (Tool != TOOL_POINTER && !CanDraw())
        return "You can't draw yet";

    switch (Tool)
    {
        case TOOL_POINTER: return "The map works as normal";
        case TOOL_PEN:     return "Hold left mouse and draw";
        case TOOL_MARKER:  return class'CMMapInfo'.static.IconName(Icon)$": click to place";
        case TOOL_TEXT:    return "Click, type, then Enter";
        case TOOL_ERASER:  return "Click a drawing to erase";
        case TOOL_MOVE:    return "Drag a drawing to move it";
        case TOOL_RULER:   return "Drag to measure (only you see it)";
        case TOOL_ZONE:
            if (ZoneShape != ZONE_LINES)
                return "Drag out the area";
            return bZoneLining ? "Right click or Enter to end" : "Click points for the lines";
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
    bStyle = class'CMenu'.static.StyleOn(PC);

    BtnW = 84 * UIScale;
    BtnH = 22 * UIScale;
    Gap = 3 * UIScale;
    Pad = 6 * UIScale;
    PanelW = Pad * 2 + BtnW * 2 + Gap;
    Inner = PanelW - Pad * 2;

    // Right of the map, out of the way of the grid letters down its left side; inside its right edge if there is no room
    PanelX = MapLeft + MapW + 6 * UIScale;
    if (PanelX + PanelW > C.ClipX - 4)
        PanelX = MapLeft + MapW - PanelW - 4 * UIScale;
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

    // In toolbar order, each with the number key that picks it
    for (i = 0; i < NUM_TOOLS; i++)
    {
        AddButton(X + (i % 2) * (BtnW + Gap), Y, BtnW, BtnH, A_TOOL, ToolInSlot(i), SlotKeyName(i)$"  "$ToolName(ToolInSlot(i)), Tool == ToolInSlot(i),
            !ToolAllowed(ToolInSlot(i)));
        if (i % 2 == 1)
            Y += BtnH + Gap;
    }
    if (NUM_TOOLS % 2 == 1)
        Y += BtnH + Gap;
    Y += Gap * 2;

    Cell = (Inner - Gap * (class'CMMapInfo'.const.NUM_COLOURS - 1)) / class'CMMapInfo'.const.NUM_COLOURS;
    for (i = 0; i < class'CMMapInfo'.const.NUM_COLOURS; i++)
        AddButton(X + i * (Cell + Gap), Y, Cell, BtnH, A_COLOUR, i, "", Colour == i);
    Y += BtnH + Gap * 3;

    if (Tool == TOOL_ZONE)
    {
        Cell = (Inner - Gap * (NUM_ZONE_SHAPES - 1)) / NUM_ZONE_SHAPES;
        for (i = 0; i < NUM_ZONE_SHAPES; i++)
            AddButton(X + i * (Cell + Gap), Y, Cell, BtnH, A_ZONE_SHAPE, i, ZoneShapeName(i), ZoneShape == i);
        Y += BtnH + Gap * 3;
    }

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

    // The Map icons menu: what the map shows besides the drawings. Each button is framed while that kind is shown.
    AddButton(X, Y, Inner, BtnH, A_ICONS_MENU, 0, bIconsMenuOpen ? "Map icons  (fold)" : "Map icons...", bIconsMenuOpen);
    Y += BtnH + Gap;
    if (bIconsMenuOpen)
    {
        if (PRI != None && PRI.bOnlySpectator)
        {
            for (i = MAPICON_PLAYERS; i <= MAPICON_DEATHS; i++)
            {
                AddButton(X + (i % 2) * (BtnW + Gap), Y, BtnW, BtnH, A_MAP_ICON, i, MapIconName(i), MapIconShown(i));
                if (i % 2 == 1)
                    Y += BtnH + Gap;
            }
            AddButton(X, Y, Inner, BtnH, A_SPEC_TEAMS, 0, SpecTeamsLabel(PC), SpecTeams != SPEC_BOTH);
            Y += BtnH + Gap;
        }
        AddButton(X, Y, BtnW, BtnH, A_PLAYER_NAMES, 0, "Names", !bNoPlayerNames);
        AddButton(X + BtnW + Gap, Y, BtnW, BtnH, A_MAP_ICON, MAPICON_BORDERS, MapIconName(MAPICON_BORDERS), MapIconShown(MAPICON_BORDERS));
        Y += BtnH + Gap;
    }
    Y += Gap;
    MarkArmedButton(PC);

    // The hint line under the buttons
    Y += BtnH;
    PanelH = Y + Pad - PanelY;

    if (bStyle)
    {
        // The steel frame a layer below the buttons: in theirs it could be drawn over them (see PushLayer)
        PushPriority(C, DSP_High);
        class'CMenu'.static.DrawStyledPanel(C, PanelX, PanelY, PanelW, PanelH, 220, UIScale);
        PopLayer(C);
    }
    else
    {
        PushLayer(C, false);
        C.SetDrawColor(0, 0, 0, 170);
        C.SetPos(PanelX, PanelY);
        C.DrawTile(C.DefaultTexture, PanelW, PanelH, 0, 0, C.DefaultTexture.SizeX, C.DefaultTexture.SizeY);
        PopLayer(C);
    }

    DrawButtonLayers(C);

    PushLayer(C, true);
    C.TextSize(ToolHint(PC), XL, YL);
    DrawBoldText(C, ToolHint(PC), X, Y - BtnH * 0.5 - YL * TextScale * 0.5, TextScale * 0.9, MakeColor(220, 220, 220, 255));
    PopLayer(C);
}

// bTop false: the frames and backgrounds; true: the icons and labels on them
function DrawButtons(Canvas C, bool bTop, optional int First)
{
    local int i;
    local float XL, YL, Inset;
    local color Col;
    local bool bHover;
    local Texture2D Tex;

    for (i = First; i < Buttons.Length; i++)
    {
        bHover = bCursor && !Buttons[i].bDisabled && Mouse.X >= Buttons[i].X && Mouse.X <= Buttons[i].X + Buttons[i].W
            && Mouse.Y >= Buttons[i].Y && Mouse.Y <= Buttons[i].Y + Buttons[i].H;

        if (!bTop && bStyle && Buttons[i].Action != A_COLOUR && Buttons[i].Action != A_CTX_COLOUR)
        {
            DrawStyledButton(C, Buttons[i], bHover);
            continue;
        }

        if (!bTop)
        {
            // Selected: an amber frame. Hovered: a lighter background. Waiting for a second click: red. Greyed out: darker.
            if (Buttons[i].bSelected)
            {
                C.SetDrawColor(230, 170, 40, 255);
                C.SetPos(Buttons[i].X - 2, Buttons[i].Y - 2);
                C.DrawTile(C.DefaultTexture, Buttons[i].W + 4, Buttons[i].H + 4, 0, 0, C.DefaultTexture.SizeX, C.DefaultTexture.SizeY);
            }

            if (Buttons[i].Action == A_COLOUR || Buttons[i].Action == A_CTX_COLOUR)
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

        if (Buttons[i].Action == A_ICON || Buttons[i].Action == A_CTX_ICON)
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
            Col = MakeColor(110, 110, 110, 255);
        else
            Col = bStyle ? MakeColor(235, 235, 235, 255) : MakeColor(255, 255, 255, 255);
        DrawBoldText(C, Buttons[i].Label, Buttons[i].X + (Buttons[i].W - XL * TextScale) * 0.5,
            Buttons[i].Y + (Buttons[i].H - YL * TextScale) * 0.5, TextScale, Col);
    }
}

// The toolbar's text, a little bold so it reads well over the map: drawn twice a pixel apart, over a drop shadow in
// RS2 style. All in the font's texture, so the canvas keeps the shadow under the text.
function DrawBoldText(Canvas C, string Text, float X, float Y, float Scale, color Col)
{
    local float Bold, Offset;

    Bold = FMax(1.0, Round(UIScale));
    X -= Bold * 0.5;
    if (bStyle)
    {
        Offset = FMax(1.0, Round(2.0 * Scale));
        C.SetDrawColor(0, 0, 0, Col.A);
        C.SetPos(X + Offset, Y + Offset);
        C.DrawText(Text, false, Scale, Scale);
        C.SetPos(X + Offset + Bold, Y + Offset);
        C.DrawText(Text, false, Scale, Scale);
    }
    C.SetDrawColor(Col.R, Col.G, Col.B, Col.A);
    C.SetPos(X, Y);
    C.DrawText(Text, false, Scale, Scale);
    C.SetPos(X + Bold, Y);
    C.DrawText(Text, false, Scale, Scale);
}

// A toolbar button in RS2 style, as one piece so nothing in its layer has to go over it: selected lit in amber from the
// left, waiting for a second click red, under the cursor lighter, greyed out faint, otherwise the game's soft black bar
function DrawStyledButton(Canvas C, ToolButton B, bool bHover)
{
    if (B.bDanger)
        class'CMenu'.static.DrawStyled(C, class'CMenu'.const.STYLE_SOLID, B.X, B.Y, B.W, B.H, bHover ? MakeColor(240, 70, 60, 255) : MakeColor(200, 40, 35, 255));
    else if (B.bSelected)
        class'CMenu'.static.DrawStyled(C, class'CMenu'.const.STYLE_GLOW, B.X, B.Y, B.W, B.H, MakeColor(230, 170, 40, bHover ? 255 : 210));
    else if (bHover)
        class'CMenu'.static.DrawStyled(C, class'CMenu'.const.STYLE_SOLID, B.X, B.Y, B.W, B.H, MakeColor(150, 150, 150, 255));
    else
        class'CMenu'.static.DrawStyled(C, class'CMenu'.const.STYLE_BAR, B.X, B.Y, B.W, B.H, MakeColor(255, 255, 255, B.bDisabled ? 110 : 255));
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
    if (bSpectatorView && MapIconShown(MAPICON_VEHICLES))
        DrawEmptyVehicles(C, H, OM, BaseSize);
    if (!bSpectatorView)
        MatchPawns(PC);

    for (i = 0; i < class'CMMapInfo'.const.MAX_SNAPSHOT; i++)
    {
        ROPRI = Info.SnapPRI[i];
        if (ROPRI == None)
            continue;
        Packed = Info.SnapInfo[i];
        Loc = Info.SnapLoc[i];

        if ((Packed & class'CMMapInfo'.const.FLAG_DEAD) != 0)
        {
            if (bSpectatorView && !MapIconShown(MAPICON_DEATHS))
                continue;
            Alpha = DeadAlpha(ROPRI, Now);
            if (Alpha == 0 || OM.DeadPlayerIcon == None)
                continue;
            MapTex = OM.DeadPlayerIcon;
            Size = OM.DeadPlayerIconSize * IconComp.ScaleX;
            // Spectators see it in the dead player's team colour; teammates see it white, as the game draws its own
            if (bSpectatorView)
                Col = TeamColour(H, Packed & class'CMMapInfo'.const.FLAG_SOUTH);
            else
                Col = MakeColor(255, 255, 255, 255);
            Col.A = Alpha;
        }
        else
        {
            DeadPRIs.RemoveItem(ROPRI);
            if (bSpectatorView && !MapIconShown(MAPICON_PLAYERS))
                continue;
            // A teammate whose pawn this client can see is drawn where it really is, as the game does
            if (!bSpectatorView)
            {
                P = SnapPawn[i];
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

// ====================================================
// Middle-click menus
// ====================================================

// Opens the menu for what is under the cursor: a player (scrim admins only), else a drawing, else the spot itself if the
// player may draw. False when there is nothing to open, so the click goes to the game. False when there is nothing to open, so the click goes to the game.
function bool OpenContextMenu()
{
    local PlayerController PC;
    local ROPlayerReplicationInfo PRI;
    local int Index;
    local byte Team;
    local bool bSpectatorView;

    PC = PlayerController(Outer);
    if (PC == None || !InMap(Mouse) || OverPanel(Mouse))
        return false;

    Cancel();
    bSpectatorView = Info.bSpectating && PC.PlayerReplicationInfo != None && PC.PlayerReplicationInfo.bOnlySpectator;
    PRI = Info.bScrimAdmin ? PlayerAt(PC, Mouse, bSpectatorView, Team) : None;
    Index = PickItem(Mouse, false);
    if (PRI != None)
    {
        CtxMenu = MENU_PLAYER;
        CtxPlayer = PRI.PlayerName;
        bCtxBot = PRI.bBot;
    }
    else if (Index != INDEX_NONE)
    {
        CtxMenu = MENU_ITEM;
        CtxItemID = Info.Items[Index].ID;
    }
    else if (CanDraw())
        CtxMenu = MENU_QUICK;
    else
        return false;

    CtxAt = Mouse;
    CtxWorld = ScreenToWorld(Mouse);
    bCtxIcons = false;
    bCtxColours = false;
    CtxArmed = 255;
    return true;
}

function CloseContextMenu()
{
    CtxMenu = MENU_NONE;
    CtxArmed = 255;
    CtxW = 0;
    CtxH = 0;
}

function bool InContextMenu(vector2D S)
{
    return S.X >= CtxX && S.X <= CtxX + CtxW && S.Y >= CtxY && S.Y <= CtxY + CtxH;
}

// May the player move, erase or change this drawing? The same rule the server uses.
function bool CanChangeItem(int Index)
{
    local PlayerController PC;

    PC = PlayerController(Outer);
    return Index != INDEX_NONE && PC != None && (!Info.bDrawingLocked || Info.bScrimAdmin)
        && class'CMMapInfo'.static.CanEraseItem(PC.PlayerReplicationInfo, Info.bScrimAdmin, Info.Items[Index].Kind, Info.Items[Index].Team, Info.Items[Index].Squad, Info.Items[Index].OwnerID);
}

static function string KindName(CMMapInfo.ClientMapItem Item)
{
    switch (Item.Kind)
    {
        case class'CMMapInfo'.const.KIND_PEN:    return "Line";
        case class'CMMapInfo'.const.KIND_LINE:   return "Line";
        case class'CMMapInfo'.const.KIND_ARROW:  return "Arrow";
        case class'CMMapInfo'.const.KIND_CIRCLE: return "Circle";
        case class'CMMapInfo'.const.KIND_BOX:    return "Box";
        case class'CMMapInfo'.const.KIND_MARKER: return class'CMMapInfo'.static.IconName(Item.Icon)$" marker";
        case class'CMMapInfo'.const.KIND_TEXT:   return "Label";
    }
    return "Restriction";
}

// Kill and Switch Team take two clicks: the first turns the entry red, the second within CONFIRM_TIME runs it
function bool ContextConfirmed(byte Entry)
{
    local float Now;

    Now = PlayerController(Outer).WorldInfo.RealTimeSeconds;
    if (CtxArmed == Entry && Now - CtxArmedTime <= CONFIRM_TIME)
        return true;
    CtxArmed = Entry;
    CtxArmedTime = Now;
    return false;
}

function bool ContextArmed(byte Entry)
{
    return CtxArmed == Entry && PlayerController(Outer).WorldInfo.RealTimeSeconds - CtxArmedTime <= CONFIRM_TIME;
}

function ContextEntry(byte Entry)
{
    local PlayerController PC;
    local int Index;

    PC = PlayerController(Outer);
    Index = Info.FindItem(CtxItemID);
    switch (Entry)
    {
        case CTX_LABEL:
            CloseContextMenu();
            bTyping = true;
            TypeText = "";
            TypeAt = CtxWorld;
            return;

        case CTX_MOVE:
            if (!CanChangeItem(Index))
                return;
            CloseContextMenu();
            bMoving = true;
            bCtxMove = true;
            MoveID = CtxItemID;
            MoveFrom = CtxWorld;
            return;

        case CTX_ERASE:
            if (!CanChangeItem(Index))
                return;
            Info.ServerErase(CtxItemID);
            Info.Items.Remove(Index, 1);
            CloseContextMenu();
            return;

        case CTX_ICONS:
            bCtxIcons = !bCtxIcons;
            return;

        case CTX_COLOURS:
            bCtxColours = !bCtxColours;
            return;

        case CTX_DROP:
            CloseContextMenu();
            bCtxDrop = true;
            return;

        case CTX_SWITCH:
            if (ContextConfirmed(Entry))
                PlayerCommand(PC, "forceswitchteam");
            return;

        case CTX_KILL:
            if (ContextConfirmed(Entry))
                PlayerCommand(PC, "killplayer");
            return;

        case CTX_TELEPORT:    PlayerCommand(PC, "teleporttome"); return;
        case CTX_RESPAWN:     PlayerCommand(PC, "forcerespawn"); return;
        case CTX_SAFETY_ON:   PlayerCommand(PC, "forcesafetyon"); return;
        case CTX_SAFETY_OFF:  PlayerCommand(PC, "forcesafetyoff"); return;
        case CTX_WHOIS:       PlayerCommand(PC, "whois"); return;
        case CTX_MORE:        PlayerCommand(PC, "cmenupcmanager"); return; // the whole Manage Players menu for them
    }
}

// A Manage Players command for the player the menu was opened on; the server checks the admin rights again
function PlayerCommand(PlayerController PC, string Command)
{
    CloseContextMenu();
    if (PC != None && CtxPlayer != "")
        PC.ConsoleCommand("mutate "$Command$" --player "$CtxPlayer);
}

// An icon in the menu: on an empty spot it puts that marker there (and becomes the marker tool's icon); on a marker it
// changes the marker's icon
function ContextIcon(byte Which)
{
    if (CtxMenu == MENU_ITEM)
        Info.ServerRestyleItem(CtxItemID, 255, Which);
    else if (CanDraw())
    {
        Icon = Which;
        SavedIcon = Icon;
        SaveConfig();
        SendSingle(class'CMMapInfo'.const.KIND_MARKER, CtxWorld, "");
    }
    CloseContextMenu();
}

// Drops the player the menu was opened on at a spot on the map, with the drop at grid command and the keypad there
function DropPlayerAt(vector2D W)
{
    local string Grid;

    Grid = WorldToGrid(PlayerController(Outer), W);
    if (Grid == "")
    {
        PlayerController(Outer).ClientMessage("[CMenu] This map has no grid to drop a player on.");
        return;
    }
    PlayerController(Outer).ConsoleCommand("mutate fdag --player "$CtxPlayer$" --grid "$Grid);
}

// The grid square and keypad a spot is in ("E 5 kp 3"), as the drop at grid command reads it (MutCMenu.GridToWorldLocation):
// A is the north row and 1 the west column, keypads laid out like a number pad with 7 to 9 at the north
static function string WorldToGrid(PlayerController PC, vector2D W)
{
    local ROVolumeMapBounds Bounds;
    local float MinX, MinY, MaxX, MaxY, SizeX, SizeY;
    local int Letter, Number, Row, Col;

    if (PC == None)
        return "";
    foreach PC.AllActors(class'ROVolumeMapBounds', Bounds)
        break;
    if (Bounds == None || !Bounds.GetBounds(MinX, MinY, MaxX, MaxY) || MaxX <= MinX || MaxY <= MinY)
        return "";

    SizeX = (MaxX - MinX) / 10;
    SizeY = (MaxY - MinY) / 10;
    Letter = Clamp(int((MaxX - W.X) / SizeX) + 1, 1, 10);
    Number = Clamp(int((W.Y - MinY) / SizeY) + 1, 1, 10);
    Row = Clamp(int((W.X - (MaxX - Letter * SizeX)) / (SizeX / 3)), 0, 2);
    Col = 2 - Clamp(int(((MinY + Number * SizeY) - W.Y) / (SizeY / 3)), 0, 2);
    return Chr(64 + Letter)$" "$Number$" kp "$(Row * 3 + Col + 1);
}

// The open menu, next to where it was opened (kept on the screen): a title, then its entries
function DrawContextMenu(Canvas C, PlayerController PC)
{
    local float BtnH, Gap, Pad, W, Inner, X, Y, H, Cell, XL, YL;
    local int i, Index, First, Rows, Cols;
    local bool bCan;
    local string Title;

    if (CtxMenu == MENU_NONE)
        return;
    Index = Info.FindItem(CtxItemID);
    if (CtxMenu == MENU_ITEM && Index == INDEX_NONE)
    {
        CloseContextMenu(); // erased by someone else meanwhile
        return;
    }

    BtnH = 22 * UIScale;
    Gap = 3 * UIScale;
    Pad = 6 * UIScale;
    W = 190 * UIScale;
    Inner = W - Pad * 2;
    Cols = 6;
    Cell = (Inner - Gap * (Cols - 1)) / Cols;

    // How tall it is, to keep it on the screen
    switch (CtxMenu)
    {
        case MENU_QUICK:
            Title = "Mark this spot";
            H = BtnH + Gap + 2 * (Cell + Gap) + Gap + BtnH + Gap * 3 + BtnH;
            break;
        case MENU_ITEM:
            Title = KindName(Info.Items[Index])$" by "$Info.Items[Index].OwnerName;
            bCan = CanChangeItem(Index);
            Rows = Info.Items[Index].Kind == class'CMMapInfo'.const.KIND_MARKER ? 4 : 3;
            H = BtnH + Gap + Rows * (BtnH + Gap);
            if (bCtxIcons)
                H += 2 * (Cell + Gap);
            if (bCtxColours)
                H += BtnH + Gap;
            break;
        case MENU_PLAYER:
            Title = bCtxBot ? CtxPlayer$" (bot)" : CtxPlayer;
            H = BtnH + Gap + 9 * (BtnH + Gap);
            break;
    }
    H += Pad * 2;

    CtxX = FClamp(CtxAt.X + 10 * UIScale, 4, C.ClipX - W - 4);
    CtxY = FClamp(CtxAt.Y + 10 * UIScale, 4, C.ClipY - H - 4);
    CtxW = W;
    CtxH = H;

    // All of it in the top layer, over the player icons (which share the toolbar's text layer). The canvas draws a
    // layer's textures in the order they are first used, so the frame and boxes go first, then the icons and text; the
    // cursor is drawn after the menu, so it stays on top. (No label by the cursor is drawn while the menu is open.)
    PushPriority(C, DSP_Insane);
    if (bStyle)
        class'CMenu'.static.DrawStyledPanel(C, CtxX, CtxY, CtxW, CtxH, 230, UIScale);
    else
    {
        C.SetDrawColor(0, 0, 0, 200);
        C.SetPos(CtxX, CtxY);
        C.DrawTile(C.DefaultTexture, CtxW, CtxH, 0, 0, C.DefaultTexture.SizeX, C.DefaultTexture.SizeY);
    }

    First = Buttons.Length;
    X = CtxX + Pad;
    Y = CtxY + Pad + BtnH + Gap;
    switch (CtxMenu)
    {
        case MENU_QUICK:
            for (i = 0; i < class'CMMapInfo'.const.NUM_ICONS; i++)
            {
                AddButton(X + (i % Cols) * (Cell + Gap), Y, Cell, Cell, A_CTX_ICON, i, "", false);
                if (i % Cols == Cols - 1)
                    Y += Cell + Gap;
            }
            if (class'CMMapInfo'.const.NUM_ICONS % Cols != 0)
                Y += Cell + Gap;
            Y += Gap;
            Cell = (Inner - Gap * (class'CMMapInfo'.const.NUM_COLOURS - 1)) / class'CMMapInfo'.const.NUM_COLOURS;
            for (i = 0; i < class'CMMapInfo'.const.NUM_COLOURS; i++)
                AddButton(X + i * (Cell + Gap), Y, Cell, BtnH, A_COLOUR, i, "", Colour == i);
            Y += BtnH + Gap * 3;
            AddButton(X, Y, Inner, BtnH, A_CTX, CTX_LABEL, "Text label here", false);
            break;

        case MENU_ITEM:
            AddButton(X, Y, Inner, BtnH, A_CTX, CTX_MOVE, "Move", false, !bCan);
            Y += BtnH + Gap;
            AddButton(X, Y, Inner, BtnH, A_CTX, CTX_ERASE, "Erase", false, !bCan);
            Y += BtnH + Gap;
            if (Info.Items[Index].Kind == class'CMMapInfo'.const.KIND_MARKER)
            {
                AddButton(X, Y, Inner, BtnH, A_CTX, CTX_ICONS, "Change icon", bCtxIcons, !bCan);
                Y += BtnH + Gap;
                if (bCtxIcons && bCan)
                {
                    for (i = 0; i < class'CMMapInfo'.const.NUM_ICONS; i++)
                    {
                        AddButton(X + (i % Cols) * (Cell + Gap), Y, Cell, Cell, A_CTX_ICON, i, "", Info.Items[Index].Icon == i);
                        if (i % Cols == Cols - 1)
                            Y += Cell + Gap;
                    }
                    if (class'CMMapInfo'.const.NUM_ICONS % Cols != 0)
                        Y += Cell + Gap;
                }
            }
            AddButton(X, Y, Inner, BtnH, A_CTX, CTX_COLOURS, "Change colour", bCtxColours, !bCan);
            Y += BtnH + Gap;
            if (bCtxColours && bCan)
            {
                Cell = (Inner - Gap * (class'CMMapInfo'.const.NUM_COLOURS - 1)) / class'CMMapInfo'.const.NUM_COLOURS;
                for (i = 0; i < class'CMMapInfo'.const.NUM_COLOURS; i++)
                    AddButton(X + i * (Cell + Gap), Y, Cell, BtnH, A_CTX_COLOUR, i, "", Info.Items[Index].Colour == i);
            }
            break;

        // Only opened for scrim admins; on a bot only teleport, drop and kill work (the rest are run by the player's own game)
        case MENU_PLAYER:
            AddButton(X, Y, Inner, BtnH, A_CTX, CTX_TELEPORT, "Teleport To Me", false);
            Y += BtnH + Gap;
            AddButton(X, Y, Inner, BtnH, A_CTX, CTX_DROP, "Drop At A Spot...", false);
            Y += BtnH + Gap;
            AddButton(X, Y, Inner, BtnH, A_CTX, CTX_SWITCH, ContextArmed(CTX_SWITCH) ? "Switch Team: sure?" : "Switch Team", false, bCtxBot);
            Buttons[Buttons.Length - 1].bDanger = ContextArmed(CTX_SWITCH);
            Y += BtnH + Gap;
            AddButton(X, Y, Inner, BtnH, A_CTX, CTX_RESPAWN, "Respawn", false, bCtxBot);
            Y += BtnH + Gap;
            AddButton(X, Y, Inner, BtnH, A_CTX, CTX_KILL, ContextArmed(CTX_KILL) ? "Kill: sure?" : "Kill", false);
            Buttons[Buttons.Length - 1].bDanger = ContextArmed(CTX_KILL);
            Y += BtnH + Gap;
            AddButton(X, Y, Inner, BtnH, A_CTX, CTX_SAFETY_ON, "Safety On", false, bCtxBot);
            Y += BtnH + Gap;
            AddButton(X, Y, Inner, BtnH, A_CTX, CTX_SAFETY_OFF, "Safety Off", false, bCtxBot);
            Y += BtnH + Gap;
            AddButton(X, Y, Inner, BtnH, A_CTX, CTX_WHOIS, "Find Original Name", false, bCtxBot);
            Y += BtnH + Gap;
            AddButton(X, Y, Inner, BtnH, A_CTX, CTX_MORE, "More...", false);
            break;
    }
    DrawButtons(C, false, First);
    DrawButtons(C, true, First);
    C.Font = class'Engine'.static.GetSmallFont();
    C.TextSize(Title, XL, YL);
    DrawBoldText(C, Title, CtxX + Pad, CtxY + Pad + (BtnH - YL * TextScale) * 0.5, TextScale, MakeColor(230, 170, 40, 255));
    PopLayer(C);
}

// ====================================================
// Movement restrictions on the ground
// ====================================================

// Keeps a ground path for every movement restriction this player sees, makes a moved one again, drops the ones that went,
// and carries on with the traces. Runs with the map open too, so the lines are ready when it closes.
function UpdateGroundZones(PlayerController PC)
{
    local int i, k, Index, Budget;
    local array<byte> Keep;
    local GroundZone Z;
    local string Sig;

    Keep.Length = GroundZones.Length;
    for (i = 0; i < Info.Items.Length; i++)
    {
        if (!class'CMMapInfo'.static.IsZone(Info.Items[i].Kind) || !ItemShown(Info.Items[i], PC.PlayerReplicationInfo))
            continue;
        Sig = ZoneSig(Info.Items[i]);
        Index = INDEX_NONE;
        for (k = 0; k < GroundZones.Length; k++)
        {
            if (GroundZones[k].ID == Info.Items[i].ID)
            {
                Index = k;
                break;
            }
        }
        if (Index != INDEX_NONE && GroundZones[Index].Sig == Sig)
        {
            Keep[Index] = 1;
            continue;
        }
        if (Index == INDEX_NONE)
        {
            Index = GroundZones.Length;
            GroundZones.AddItem(Z);
            Keep.AddItem(0);
        }
        RemovePaint(Index);
        GroundZones[Index].ID = Info.Items[i].ID;
        GroundZones[Index].Sig = Sig;
        GroundZones[Index].Colour = Info.Items[i].Colour;
        GroundZones[Index].Flat = GroundPath(Info.Items[i]);
        GroundZones[Index].Pts.Length = 0;
        GroundZones[Index].Seen.Length = 0;
        Keep[Index] = 1;
    }
    for (i = GroundZones.Length - 1; i >= 0; i--)
    {
        if (Keep[i] == 0)
        {
            RemovePaint(i);
            GroundZones.Remove(i, 1);
        }
    }

    Budget = GROUND_TRACES_PER_FRAME;
    for (i = 0; i < GroundZones.Length && Budget > 0; i++)
        Budget -= TraceGround(PC, i, Budget);

    // The paint: off while the drawings are hidden, otherwise made for what has been traced, a few pieces a frame
    if (!UsePaint(PC))
        return;
    Budget = ZONE_STRIPS_PER_FRAME;
    for (i = 0; i < GroundZones.Length; i++)
    {
        if (bHideDrawings || !Info.bDrawingEnabled)
            RemovePaint(i);
        else if (Budget > 0)
            Budget -= PaintZone(i, Budget);
    }
}

// Whether the lines are painted as decals: the game has decals on, and the paint could be loaded. Otherwise they are
// drawn over the view (DrawZonesInWorld). The decals' owner of an earlier level is gone with it, and its paint too.
function bool UsePaint(PlayerController PC)
{
    local int i;

    if (ZoneDecals != None && ZoneDecals.bDeleteMe)
    {
        ZoneDecals = None;
        for (i = 0; i < GroundZones.Length; i++)
        {
            GroundZones[i].Strips.Length = 0;
            GroundZones[i].StripFrom = 0;
        }
    }
    if (!class'DecalManager'.static.AreDynamicDecalsEnabled())
        return false;
    if (ZoneDecals == None)
        ZoneDecals = PC.Spawn(class'CMZoneDecals', PC,, vect(0, 0, 0), rot(0, 0, 0));
    return ZoneDecals != None && ZoneDecals.Paint(0, ZoneDecalMaterial, ZoneDecalTexture) != None;
}

function RemovePaint(int Index)
{
    local int k;

    if (ZoneDecals != None && !ZoneDecals.bDeleteMe)
    {
        for (k = 0; k < GroundZones[Index].Strips.Length; k++)
            ZoneDecals.RemoveStrip(GroundZones[Index].Strips[k]);
    }
    GroundZones[Index].Strips.Length = 0;
    GroundZones[Index].StripFrom = 0;
}

// Paints up to Budget more pieces of a restriction, going on along its traced points. A piece runs from one point as far
// as the ground stays near its straight line (up to ZONE_STRIP_MAX), so flat ground takes few pieces and rough ground
// more. Points with no ground under them are left out. Returns the pieces made.
function int PaintZone(int Index, int Budget)
{
    local MaterialInterface M;
    local vector A, B;
    local int k, e, j, Made;
    local float Bump, T;
    local bool bFits;

    M = ZoneDecals.Paint(GroundZones[Index].Colour, ZoneDecalMaterial, ZoneDecalTexture);
    k = GroundZones[Index].StripFrom;
    while (Made < Budget && k < GroundZones[Index].Pts.Length - 1)
    {
        if (GroundZones[Index].Seen[k] == 2)
        {
            k++;
            continue;
        }
        e = k + 1;
        if (GroundZones[Index].Seen[e] == 2)
        {
            k = e;
            continue;
        }
        // As far as it can go
        while (e + 1 < GroundZones[Index].Pts.Length && GroundZones[Index].Seen[e + 1] != 2
            && VSize2D(GroundZones[Index].Pts[e + 1] - GroundZones[Index].Pts[k]) <= ZONE_STRIP_MAX)
        {
            bFits = true;
            for (j = k + 1; j <= e && bFits; j++)
            {
                T = VSize2D(GroundZones[Index].Pts[j] - GroundZones[Index].Pts[k]) / FMax(1.0, VSize2D(GroundZones[Index].Pts[e + 1] - GroundZones[Index].Pts[k]));
                Bump = Abs(GroundZones[Index].Pts[j].Z - Lerp(GroundZones[Index].Pts[k].Z, GroundZones[Index].Pts[e + 1].Z, T));
                bFits = Bump <= ZONE_STRIP_BUMP;
            }
            if (!bFits)
                break;
            e++;
        }

        A = GroundZones[Index].Pts[k];
        B = GroundZones[Index].Pts[e];
        // A little longer than the piece, so the pieces meet without a gap at a bend
        GroundZones[Index].Strips.AddItem(ZoneDecals.AddStrip(M, (A + B) * 0.5, rotator(B - A).Yaw,
            VSize2D(B - A) + ZONE_STRIP_WIDTH, ZONE_STRIP_WIDTH, Abs(A.Z - B.Z) * 0.5 + ZONE_STRIP_DEPTH));
        Made++;
        k = e;
    }
    // Only once every point has been traced is the restriction finished; until then the paint waits for more points
    GroundZones[Index].StripFrom = k;
    return Made;
}

// What a drawing is, as far as its ground path goes: its kind, how many points and where it starts and ends (a moved
// drawing has every point moved)
static function string ZoneSig(CMMapInfo.ClientMapItem Item)
{
    local int Last;

    Last = Item.Points.Length - 1;
    if (Last < 0)
        return string(Item.Kind);
    return Item.Kind$":"$Item.Points.Length$":"$int(Item.Points[0].X)$","$int(Item.Points[0].Y)$":"$int(Item.Points[Last].X)$","$int(Item.Points[Last].Y);
}

// The path a movement restriction takes over the map, a point every GROUND_STEP or so (a longer step for a very long one).
// A box is its four sides, a circle its edge; both end where they start.
static function array<vector2D> GroundPath(CMMapInfo.ClientMapItem Item)
{
    local array<vector2D> Corners, Path;
    local vector2D A, B;
    local float Length, Step, R, T;
    local int i, n, Count;

    if (Item.Points.Length < 2)
        return Path;

    if (Item.Kind == class'CMMapInfo'.const.KIND_ZONE_CIRCLE)
    {
        R = Sqrt(Square(Item.Points[1].X - Item.Points[0].X) + Square(Item.Points[1].Y - Item.Points[0].Y));
        Count = Clamp(int(2 * Pi * R / GROUND_STEP), 24, GROUND_MAX_POINTS);
        for (i = 0; i <= Count; i++)
        {
            A.X = Item.Points[0].X + R * Cos(i * 2 * Pi / Count);
            A.Y = Item.Points[0].Y + R * Sin(i * 2 * Pi / Count);
            Path.AddItem(A);
        }
        return Path;
    }

    if (Item.Kind == class'CMMapInfo'.const.KIND_ZONE_BOX)
    {
        A = Item.Points[0];
        B = Item.Points[1];
        Corners.AddItem(A);
        A.Y = B.Y;
        Corners.AddItem(A);
        Corners.AddItem(B);
        A = Item.Points[0];
        A.X = B.X;
        Corners.AddItem(A);
        Corners.AddItem(Item.Points[0]);
    }
    else
        Corners = Item.Points;

    for (i = 1; i < Corners.Length; i++)
        Length += Sqrt(Square(Corners[i].X - Corners[i - 1].X) + Square(Corners[i].Y - Corners[i - 1].Y));
    Step = FMax(GROUND_STEP, Length / GROUND_MAX_POINTS);

    Path.AddItem(Corners[0]);
    for (i = 1; i < Corners.Length; i++)
    {
        A = Corners[i - 1];
        B = Corners[i];
        Length = Sqrt(Square(B.X - A.X) + Square(B.Y - A.Y));
        n = Max(1, int(Length / Step + 0.999));
        for (Count = 1; Count <= n; Count++)
        {
            T = float(Count) / n;
            Path.AddItem(Lerp2(A, B, T));
        }
    }
    return Path;
}

static function vector2D Lerp2(vector2D A, vector2D B, float T)
{
    local vector2D P;

    P.X = A.X + (B.X - A.X) * T;
    P.Y = A.Y + (B.Y - A.Y) * T;
    return P;
}

// Finds the ground under up to Budget more points of the path. Traced from above, as bullets go, so the lines lie on
// whatever is there (a roof too) and invisible walls that bullets pass are left out. Returns the traces it used.
function int TraceGround(PlayerController PC, int Index, int Budget)
{
    local vector Start, End, HitLoc, HitNorm;
    local int Used, k;

    for (k = GroundZones[Index].Pts.Length; Used < Budget && k < GroundZones[Index].Flat.Length; k++)
    {
        Start.X = GroundZones[Index].Flat[k].X;
        Start.Y = GroundZones[Index].Flat[k].Y;
        Start.Z = GROUND_TRACE_HEIGHT;
        End = Start;
        End.Z = -GROUND_TRACE_HEIGHT;
        Used++;
        if (PC.Trace(HitLoc, HitNorm, End, Start, false,,, class'Actor'.const.TRACEFLAG_Bullet) != None)
        {
            GroundZones[Index].Pts.AddItem(HitLoc);
            GroundZones[Index].Seen.AddItem(0);
        }
        else
        {
            GroundZones[Index].Pts.AddItem(Start);
            GroundZones[Index].Seen.AddItem(2);
        }
    }
    return Used;
}

// The lines on the ground: between each two points next to each other that are both in sight and close enough, in the
// drawing's colour with a dark edge, thinner and fainter further away. The sight checks go on a few hundred a frame.
function DrawZonesInWorld(Canvas C, PlayerController PC)
{
    local vector CamLoc, ViewDir, A, B, SA, SB;
    local vector2D P1, P2;
    local rotator CamRot;
    local float Scale, D, Fade, Width;
    local int i, k;
    local color Col, Edge;

    if (GroundZones.Length == 0)
        return;
    PC.GetPlayerViewPoint(CamLoc, CamRot);
    ViewDir = vector(CamRot);
    Scale = FMax(1.0, C.ClipY / 1080.0);
    CheckGroundSight(PC, CamLoc);

    for (i = 0; i < GroundZones.Length; i++)
    {
        Col = class'CMMapInfo'.static.GetColour(GroundZones[i].Colour);
        for (k = 1; k < GroundZones[i].Pts.Length; k++)
        {
            if (GroundZones[i].Seen[k] != 1 || GroundZones[i].Seen[k - 1] != 1)
                continue;
            A = GroundZones[i].Pts[k - 1];
            B = GroundZones[i].Pts[k];
            D = VSize((A + B) * 0.5 - CamLoc);
            if (D > ZONE_VIEW_DIST)
                continue;
            if (!ClipToView(CamLoc, ViewDir, A, B))
                continue;

            SA = C.Project(A);
            SB = C.Project(B);
            if ((SA.X < 0 && SB.X < 0) || (SA.X > C.ClipX && SB.X > C.ClipX) || (SA.Y < 0 && SB.Y < 0) || (SA.Y > C.ClipY && SB.Y > C.ClipY))
                continue;

            Fade = FClamp((ZONE_VIEW_DIST - D) / ZONE_FADE_DIST, 0.0, 1.0);
            Width = FClamp(3000.0 / FMax(D, 1.0), 1.0, 5.0) * Scale;
            P1.X = SA.X;
            P1.Y = SA.Y;
            P2.X = SB.X;
            P2.Y = SB.Y;
            if (!ClipToRect(P1, P2, -Width, -Width, C.ClipX + Width * 2, C.ClipY + Width * 2))
                continue;

            Edge = MakeColor(0, 0, 0, byte(140 * Fade));
            DrawScreenLine(C, P1, P2, Width + 2 * Scale, Edge);
            Col.A = byte(230 * Fade);
            DrawScreenLine(C, P1, P2, Width, Col);
        }
    }
}

// Whether the next GROUND_SIGHT_PER_FRAME ground points can be seen from the camera, going on from where the last frame
// stopped, at most once round all of them. Points too far away to be drawn are taken as hidden without a trace.
function CheckGroundSight(PlayerController PC, vector CamLoc)
{
    local int Done, Steps, Total, i;
    local vector P;

    for (i = 0; i < GroundZones.Length; i++)
        Total += GroundZones[i].Pts.Length;

    for (Steps = 0; Steps < Total && Done < GROUND_SIGHT_PER_FRAME; Steps++)
    {
        while (SightZone >= GroundZones.Length || SightPoint >= GroundZones[SightZone].Pts.Length)
        {
            SightPoint = 0;
            SightZone++;
            if (SightZone >= GroundZones.Length)
                SightZone = 0;
        }

        if (GroundZones[SightZone].Seen[SightPoint] != 2)
        {
            P = GroundZones[SightZone].Pts[SightPoint];
            P.Z += GROUND_LIFT;
            if (VSizeSq(P - CamLoc) > Square(ZONE_VIEW_DIST + GROUND_STEP))
                GroundZones[SightZone].Seen[SightPoint] = 0;
            else
            {
                GroundZones[SightZone].Seen[SightPoint] = PC.FastTrace(P, CamLoc) ? 1 : 0;
                Done++;
            }
        }
        SightPoint++;
    }
}

// ====================================================
// Spotted enemies
// ====================================================

// Notes each spot the player's team makes (a slot's fade time changing to one still to come) and drops marks that have
// had their time. Runs with the map closed too, so a spot made then still shows when it is opened.
function TrackSpots(PlayerController PC)
{
    local ROTeamInfo Team;
    local int i, Fade, Elapsed, Index;
    local float Now;
    local vector Where;
    local SpotMark Mark;

    Team = (PC.PlayerReplicationInfo != None) ? ROTeamInfo(PC.PlayerReplicationInfo.Team) : None;
    if (Team == None || PC.WorldInfo.GRI == None)
    {
        SpotMarks.Length = 0;
        SpotTeam = 255;
        return;
    }
    Now = PC.WorldInfo.RealTimeSeconds;
    Elapsed = PC.WorldInfo.GRI.ElapsedTime;

    // A new team: what it spotted before this player joined it is taken as already seen
    if (Team.TeamIndex != SpotTeam)
    {
        SpotMarks.Length = 0;
        SpotTeam = Team.TeamIndex;
        for (i = 0; i < `MAX_PLAYERS_PER_TEAM; i++)
            SeenSpotFade[i] = Team.EnemySpottedFadeTime[i];
    }

    for (i = 0; i < `MAX_PLAYERS_PER_TEAM; i++)
    {
        Fade = Team.EnemySpottedFadeTime[i];
        if (Fade == SeenSpotFade[i])
            continue;
        SeenSpotFade[i] = Fade;

        // The game clears every slot for a new round: so are the marks
        if (Fade < -1000)
        {
            SpotMarks.Length = 0;
            continue;
        }
        // Already over (an old value arriving late), or found by the recon plane, which keeps its own marks up
        if (Fade < Elapsed || Team.EnemyType[i] >= RORIT_SpottedByPlane)
            continue;

        // The slot's mark was still up: the same enemy spotted again, so its mark moves. Otherwise the slot was free
        // and this is a new spot; the mark it had before stays where it was.
        Index = SpotMarkFor(i);
        if (Index != INDEX_NONE && SpotMarks[Index].GameFade < Elapsed)
        {
            SpotMarks[Index].Slot = 255;
            Index = INDEX_NONE;
        }
        if (Index == INDEX_NONE)
        {
            Mark.Slot = i;
            Index = SpotMarks.Length;
            SpotMarks.AddItem(Mark);
        }
        SpotMarks[Index].GameFade = Fade;
        SpotMarks[Index].Until = Now + SPOT_MAP_LIFE;
    }

    for (i = SpotMarks.Length - 1; i >= 0; i--)
    {
        if (Now > SpotMarks[i].Until)
        {
            SpotMarks.Remove(i, 1);
            continue;
        }
        // While the game shows the slot, its place and kind are the game's (the spotter's own game sets them a moment
        // before the server's arrive)
        if (GameShowsSpot(SpotMarks[i], Team, Elapsed) && Team.GetEnemyLocationValid(SpotMarks[i].Slot))
        {
            Where = Team.GetEnemyLocationVector(SpotMarks[i].Slot);
            SpotMarks[i].Loc = V2(Where.X, Where.Y);
            SpotMarks[i].Type = Team.EnemyType[SpotMarks[i].Slot];
        }
    }
}

function int SpotMarkFor(byte Slot)
{
    local int i;

    for (i = 0; i < SpotMarks.Length; i++)
    {
        if (SpotMarks[i].Slot == Slot)
            return i;
    }
    return INDEX_NONE;
}

// True while the game still draws the mark itself
function bool GameShowsSpot(SpotMark Mark, ROTeamInfo Team, int Elapsed)
{
    return Mark.Slot != 255 && Team.EnemySpottedFadeTime[Mark.Slot] == Mark.GameFade && Mark.GameFade >= Elapsed;
}

// The map is open: the marks the game has taken off, with the game's icon for what was spotted, at the size and colour
// it draws its own, fading at the end
function DrawSpotMarks(Canvas C, PlayerController PC)
{
    local ROTeamInfo Team;
    local ROHUDWidgetComponent Comp;
    local Texture2D Tex;
    local vector2D S;
    local float Now, Size;
    local int i, Elapsed;
    local color Col;

    Team = (PC.PlayerReplicationInfo != None) ? ROTeamInfo(PC.PlayerReplicationInfo.Team) : None;
    if (Team == None || MapWidget == None || PC.WorldInfo.GRI == None || SpotMarks.Length == 0)
        return;
    Comp = MapWidget.EnemySpottedIcons[0];
    Now = PC.WorldInfo.RealTimeSeconds;
    Elapsed = PC.WorldInfo.GRI.ElapsedTime;

    for (i = 0; i < SpotMarks.Length; i++)
    {
        if (GameShowsSpot(SpotMarks[i], Team, Elapsed))
            continue;
        if (SpotMarks[i].Loc.X < MinWX || SpotMarks[i].Loc.X > MaxWX || SpotMarks[i].Loc.Y < MinWY || SpotMarks[i].Loc.Y > MaxWY)
            continue;
        Tex = SpotIcon(MapWidget, SpotMarks[i].Type, Size);
        if (Tex == None)
            continue;
        Col = MakeColor(255, 255, 255, 255);
        if (Comp != None)
        {
            Size *= Comp.ScaleX;
            Col = Comp.DrawColor;
        }
        Col.A = byte(float(Col.A) * FClamp((SpotMarks[i].Until - Now) / SPOT_FADE, 0.0, 1.0));

        S = WorldToScreen(SpotMarks[i].Loc);
        C.SetDrawColor(Col.R, Col.G, Col.B, Col.A);
        C.SetPos(S.X - Size * 0.5, S.Y - Size * 0.5);
        C.DrawTile(Tex, Size, Size, 0, 0, Tex.SizeX, Tex.SizeY);
    }
}

// The icon the game's map uses for a spotted enemy of this kind, and its size (before the map's scale)
static function Texture2D SpotIcon(ROHUDWidgetOverheadMap OM, byte Type, out float Size)
{
    Size = OM.EnemyVehicleSpottedSize;
    switch (Type)
    {
        case RORIT_Tank:
            return OM.EnemyVehicleSpottedIcon;
        case RORIT_Transport:
            return OM.EnemyTransportSpottedIcon;
        case RORIT_Huey:
            return OM.EnemyHelicopterSpottedIconHuey;
        case RORIT_Cobra:
            return OM.EnemyHelicopterSpottedIconCobra;
        case RORIT_Loach:
            return OM.EnemyHelicopterSpottedIconLoach;
        case RORIT_Gunship:
            return OM.EnemyHelicopterSpottedIconGunship;
    }
    Size = OM.EnemyInfantrySpottedSize;
    if (Type == RORIT_AntiTank)
        return OM.EnemyRPGSpottedIcon;
    return OM.EnemyInfantrySpottedIcon;
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
// fainter while the objective is closed, with a very faint fill of the same colour inside. The shape is the one the
// objective captures in.
function DrawObjectiveBorders(Canvas C, PlayerController PC)
{
    local CMAObjective Objective;
    local ROGameReplicationInfo ROGRI;
    local int i;
    local color LineColor, FillColor;
    local array<vector2D> Shape;

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

        Shape.Length = Objective.Corners.Length;
        for (i = 0; i < Objective.Corners.Length; i++)
            Shape[i] = WorldToScreen(Objective.Corners[i]);

        // The fill first, so the border is drawn over its edge
        FillColor = LineColor;
        FillColor.A = Round(LineColor.A * BORDER_FILL_ALPHA);
        FillShape(C, Shape, FillColor);

        for (i = 0; i < Shape.Length; i++)
            DrawSegment(C, Shape[i], Shape[(i + 1) % Shape.Length], 2.0 * UIScale, LineColor);
    }
}

// Fills a shape (screen points) a strip at a time, each strip between pairs of the places it crosses the edges, so a shape
// that curls round is filled only inside. Cut to the map.
function FillShape(Canvas C, array<vector2D> Shape, color Col)
{
    local array<float> Xs;
    local float Top, Bottom, Y, H, Left, Right, Step;
    local int i;

    if (Shape.Length < 3)
        return;
    Top = Shape[0].Y;
    Bottom = Top;
    for (i = 1; i < Shape.Length; i++)
    {
        Top = FMin(Top, Shape[i].Y);
        Bottom = FMax(Bottom, Shape[i].Y);
    }
    Top = Round(FMax(Top, MapTop));
    Bottom = FMin(Bottom, MapTop + MapH);
    Step = FMax(1.0, Round(BORDER_FILL_STEP * UIScale));

    C.SetDrawColor(Col.R, Col.G, Col.B, Col.A);
    for (Y = Top; Y < Bottom; Y += Step)
    {
        H = FMin(Step, Bottom - Y);
        Xs = RowCrossings(Shape, Y + H * 0.5);
        for (i = 0; i + 1 < Xs.Length; i += 2)
        {
            Left = FMax(Xs[i], MapLeft);
            Right = FMin(Xs[i + 1], MapLeft + MapW);
            if (Right > Left)
            {
                C.SetPos(Left, Y);
                C.DrawTile(C.DefaultTexture, Right - Left, H, 0, 0, C.DefaultTexture.SizeX, C.DefaultTexture.SizeY);
            }
        }
    }
}

// Where the line across the screen at height Y crosses the shape's edges, left to right
static function array<float> RowCrossings(array<vector2D> Shape, float Y)
{
    local array<float> Xs;
    local float X;
    local int i, j, k;

    j = Shape.Length - 1;
    for (i = 0; i < Shape.Length; i++)
    {
        if ((Shape[i].Y > Y) != (Shape[j].Y > Y))
        {
            X = Shape[i].X + (Y - Shape[i].Y) * (Shape[j].X - Shape[i].X) / (Shape[j].Y - Shape[i].Y);
            k = Xs.Length;
            while (k > 0 && Xs[k - 1] > X)
                k--;
            Xs.Insert(k, 1);
            Xs[k] = X;
        }
        j = i;
    }
    return Xs;
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
// Where a player is: the vehicle (or the vehicle's seat) they are in, else their own pawn. In a vehicle their own pawn is
// hidden and stops being updated where they got in, so a name tag on it was left behind there.
function Pawn FindPawn(PlayerController PC, PlayerReplicationInfo PRI)
{
    local Pawn P, Own;

    foreach PC.WorldInfo.AllPawns(class'Pawn', P)
    {
        if (P.PlayerReplicationInfo != PRI || P.Health <= 0)
            continue;
        if (Vehicle(P) != None)
            return P;
        if (P.DrivenVehicle != None && !P.DrivenVehicle.bDeleteMe)
            return P.DrivenVehicle;
        if (Own == None)
            Own = P;
    }
    return Own;
}

// Fills SnapPawn: for every snapshot player, the pawn FindPawn would give, in one pass over the pawns. Once a frame.
function MatchPawns(PlayerController PC)
{
    local Pawn P, Shown;
    local int i, Key, Slot;

    if (PawnTableTime == PC.WorldInfo.RealTimeSeconds)
        return;
    PawnTableTime = PC.WorldInfo.RealTimeSeconds;

    for (Slot = 0; Slot < PAWN_SLOTS; Slot++)
        PawnSlotID[Slot] = 0;
    for (i = 0; i < SNAP_PLACES; i++)
    {
        SnapPawn[i] = None;
        if (Info.SnapPRI[i] == None)
            continue;
        Key = Info.SnapPRI[i].PlayerID + 1;
        Slot = Key & (PAWN_SLOTS - 1);
        while (PawnSlotID[Slot] != 0)
            Slot = (Slot + 1) & (PAWN_SLOTS - 1);
        PawnSlotID[Slot] = Key;
        PawnSlotPlace[Slot] = byte(i);
    }

    foreach PC.WorldInfo.AllPawns(class'Pawn', P)
    {
        if (P.PlayerReplicationInfo == None || P.Health <= 0)
            continue;
        i = SnapPlaceOf(P.PlayerReplicationInfo);
        if (i == INDEX_NONE)
            continue;
        // As FindPawn: the vehicle (or the vehicle's seat) they are in, else their own pawn
        if (Vehicle(P) != None)
            Shown = P;
        else if (P.DrivenVehicle != None && !P.DrivenVehicle.bDeleteMe)
            Shown = P.DrivenVehicle;
        else
            Shown = None;
        if (Shown != None)
        {
            if (Vehicle(SnapPawn[i]) == None)
                SnapPawn[i] = Shown;
        }
        else if (SnapPawn[i] == None)
            SnapPawn[i] = P;
    }
}

// The snapshot place of a player, from the table MatchPawns fills; INDEX_NONE if they aren't in the snapshot
function int SnapPlaceOf(PlayerReplicationInfo PRI)
{
    local int Key, Slot, n;

    Key = PRI.PlayerID + 1;
    Slot = Key & (PAWN_SLOTS - 1);
    for (n = 0; n < PAWN_SLOTS && PawnSlotID[Slot] != 0; n++)
    {
        if (PawnSlotID[Slot] == Key && Info.SnapPRI[PawnSlotPlace[Slot]] == PRI)
            return PawnSlotPlace[Slot];
        Slot = (Slot + 1) & (PAWN_SLOTS - 1);
    }
    return INDEX_NONE;
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
    local int i, k, Best, NumCands;
    local int CandPlace[NAME_TRACES];
    local float CandD[NAME_TRACES];
    local float D, Scale, Size, Dist2D, Now;
    local color Col;
    local bool bAllNames;

    PC.GetPlayerViewPoint(CamLoc, CamRot);
    ViewDir = vector(CamRot);
    Scale = FMax(1.0, C.ClipY / 1080.0);
    Now = PC.WorldInfo.RealTimeSeconds;
    bAllNames = ShowingAllNames(PC);
    MatchPawns(PC);
    NumCands = 0;

    // The player looked at: nearest the crosshair and close enough to it, and in sight unless within XRAY_NAME_DIST. Only
    // the NAME_TRACES nearest the crosshair are checked for being in sight, nearest first, so a crowd costs few traces.
    for (i = 0; i < SNAP_PLACES; i++)
    {
        if (Info.SnapPRI[i] == None || (Info.SnapInfo[i] & class'CMMapInfo'.const.FLAG_DEAD) != 0)
            continue;
        P = SnapPawn[i];
        if (P != None && P == PC.ViewTarget)
            continue;

        Head = HeadLocation(P, Info.SnapLoc[i]);
        if (!ProjectToScreen(C, Head, CamLoc, ViewDir, Screen))
            continue;

        D = Sqrt(Square(Screen.X - C.ClipX * 0.5) + Square(Screen.Y - C.ClipY * 0.5));
        if (D >= C.ClipX * NAME_RADIUS || (NumCands == NAME_TRACES && D >= CandD[NAME_TRACES - 1]))
            continue;
        // Kept in order, nearest the crosshair first
        for (k = Min(NumCands, NAME_TRACES - 1); k > 0 && CandD[k - 1] > D; k--)
        {
            CandD[k] = CandD[k - 1];
            CandPlace[k] = CandPlace[k - 1];
        }
        CandD[k] = D;
        CandPlace[k] = i;
        NumCands = Min(NumCands + 1, NAME_TRACES);
    }

    // Within 15 meters the name and role show through walls; further away only for a player in sight
    Best = -1;
    for (k = 0; k < NumCands && Best < 0; k++)
    {
        Head = HeadLocation(SnapPawn[CandPlace[k]], Info.SnapLoc[CandPlace[k]]);
        if (VSize(Head - CamLoc) <= XRAY_NAME_DIST || PC.FastTrace(Head, CamLoc))
            Best = CandPlace[k];
    }

    for (i = 0; i < SNAP_PLACES; i++)
    {
        if (Info.SnapPRI[i] == None)
            continue;

        // Someone who has just died: the game's death icon over their body, fading as it does on the map
        if ((Info.SnapInfo[i] & class'CMMapInfo'.const.FLAG_DEAD) != 0)
        {
            DrawDeathInWorld(C, H, Info.SnapPRI[i], Info.SnapLoc[i], CamLoc, ViewDir, Scale, Now, TeamColour(H, Info.SnapInfo[i] & class'CMMapInfo'.const.FLAG_SOUTH));
            continue;
        }
        DeadPRIs.RemoveItem(Info.SnapPRI[i]); // alive again, so their next death fades from the start

        P = SnapPawn[i];
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
            // Close up, the role they picked is shown under the name, as the game does for friendlies. With the names key held
        // it is shown at any distance, as it is for everyone else then.
            DrawNameTag(C, Info.SnapPRI[i], Screen, Col, Scale, bAllNames || Dist2D <= ROLE_ICON_DIST, 1.0);
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
    local float Age, Life, Fade, Width, Glow, Density, Near;
    local byte Kind, Team;
    local int i;

    Density = FClamp(TRACER_COMFORT / FMax(1.0, float(Tracers.Length)), TRACER_DENSITY_FLOOR, 1.0);

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

        // A line that passes right by the camera fills the screen with its colour, so it fades the closer it gets
        Near = Sqrt(class'CMMapManager'.static.DistToSegmentSq(CamLoc, A, B));
        Near = FClamp((Near - TRACER_NEAR_MIN) / (TRACER_NEAR_MAX - TRACER_NEAR_MIN), TRACER_NEAR_FLOOR, 1.0);

        SA = C.Project(A);
        SB = C.Project(B);
        if ((SA.X < 0 && SB.X < 0) || (SA.X > C.ClipX && SB.X > C.ClipX) || (SA.Y < 0 && SB.Y < 0) || (SA.Y > C.ClipY && SB.Y > C.ClipY))
            continue;

        Kind = class'CMMapInfo'.static.TraceKindOf(Tracers[i].Data);
        Team = class'CMMapInfo'.static.TraceTeamOf(Tracers[i].Data);
        Col = TeamColour(H, Team);

        Glow = FClamp(1.0 - Age / TRACER_GLOW, 0.0, 1.0) * TRACER_GLOW_MAX;
        Col.R = byte(Lerp(float(Col.R), 255.0, Glow));
        Col.G = byte(Lerp(float(Col.G), 255.0, Glow));
        Col.B = byte(Lerp(float(Col.B), 255.0, Glow));

        Fade = 1.0 - Age / Life;
        Col.A = byte(255.0 * TRACER_MAX_ALPHA * FClamp(Fade * 1.5, 0.0, 1.0) * Density * Near);

        Width = (Kind == class'CMMapInfo'.const.TRACE_BULLET ? 2.0 : (Kind == class'CMMapInfo'.const.TRACE_GRENADE ? 3.0 : 4.0)) * Scale;
        P1.X = SA.X;
        P1.Y = SA.Y;
        P2.X = SB.X;
        P2.Y = SB.Y;
        // A line that runs off the screen (one end close to the camera projects thousands of pixels away) is cut at the
        // screen's edge first: drawn whole, the huge stretched tile smeared across the edge of the screen
        if (!ClipToRect(P1, P2, -Width, -Width, C.ClipX + Width * 2, C.ClipY + Width * 2))
            continue;
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

function bool KeyHeld(PlayerController PC, name Key)
{
    return PC != None && PC.PlayerInput != None && PC.PlayerInput.PressedKeys.Find(Key) != INDEX_NONE;
}

function bool NamesKeyHeld(PlayerController PC)
{
    return KeyHeld(PC, NamesKey());
}

// Like the tracers key: pressing the names key with Shift held switches every name on until it is pressed with Shift again
function UpdateNamesLatch(PlayerController PC, bool bSpectatorView)
{
    local bool bHeld;

    bHeld = bSpectatorView && NamesKeyHeld(PC);
    if (bHeld && !bNamesKeyDown && (KeyHeld(PC, 'LeftShift') || KeyHeld(PC, 'RightShift')))
        bNamesLatched = !bNamesLatched;
    bNamesKeyDown = bHeld;
    if (!bSpectatorView)
        bNamesLatched = false;
}

// Every name is shown while the names key is held, or while it is switched on with Shift
function bool ShowingAllNames(PlayerController PC)
{
    return bNamesLatched || NamesKeyHeld(PC);
}

// The player stopped spectating (joined a team): everything the spectator overlay keeps for itself is dropped at once, so
// nothing from it is drawn or kept once they play. The game's own names come back through SetDefaultNames.
function LeaveSpectatorView()
{
    Tracers.Length = 0;
    bTraceSynced = false;
    bTracerHold = false;
    bTracersLatched = false;
    bTracerKeyDown = false;
    bNamesLatched = false;
    bNamesKeyDown = false;
    DeadPRIs.Length = 0;
    DeadSince.Length = 0;
    HurtPRIs.Length = 0;
    HurtCounts.Length = 0;
    FlashUntil.Length = 0;
}

// The key spectators use for the tracers: hold it to see them, or hold Shift as well to switch them on and off
function name TracersKeyName()
{
    return (TracersKey != '') ? TracersKey : 'RightControl';
}

// Works out whether this spectator wants tracers and tells the server when that changes. Tracers are off until asked for,
// so a firefight is not covered in lines. Pressing the key on its own shows them for as long as it is held; pressing it
// with Shift held switches them on until the key is pressed with Shift again.
function UpdateTracerRequest(PlayerController PC, bool bSpectatorView)
{
    local bool bHeld, bWant;

    bHeld = bSpectatorView && KeyHeld(PC, TracersKeyName());
    if (bHeld && !bTracerKeyDown)
    {
        if (KeyHeld(PC, 'LeftShift') || KeyHeld(PC, 'RightShift'))
            bTracersLatched = !bTracersLatched;
        else
            bTracerHold = true;
    }
    if (!bHeld)
        bTracerHold = false;
    bTracerKeyDown = bHeld;
    if (!bSpectatorView)
        bTracersLatched = false;

    bWant = bSpectatorView && (bTracerHold || bTracersLatched);
    if (bWant == bTracersAsked)
        return;

    bTracersAsked = bWant;
    if (bWant)
        bTraceSynced = false; // start from what is sent now, not what the ring still holds from before
    else
        Tracers.Length = 0;
    Info.ServerSetTracers(bWant);
}

// The game's death icon over the body, in the colour of the dead player's team
function DrawDeathInWorld(Canvas C, ROHUD H, PlayerReplicationInfo PRI, vector Loc, vector CamLoc, vector ViewDir, float Scale, float Now, color Col)
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
    C.SetDrawColor(Col.R, Col.G, Col.B, Alpha);
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
    if (bNamesLatched)
        Mode $= "   |   Every name on (Shift+"$NamesKey()$" to switch off)";
    else if (NamesKeyHeld(PC))
        Mode $= "   |   Showing every name";
    else
        Mode $= "   |   Hold "$NamesKey()$": every name (with Shift: switch on)";
    if (bTracersLatched)
        Mode $= "   |   Tracers on (Shift+"$TracersKeyName()$" to switch off)";
    else if (bTracerHold)
        Mode $= "   |   Showing tracers";
    else if (Info.bTracersOn)
        Mode $= "   |   Tracers on";
    else
        Mode $= "   |   Hold "$TracersKeyName()$": tracers (with Shift: switch on)";

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
    SpotTeam=255
    CtxArmed=255
    Colour=0
    Channel=1
}

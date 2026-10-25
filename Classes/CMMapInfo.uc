// Per-player link for everything MutCMenu adds to the overhead map, replicated only to its owner. One client-side
// Interaction (CMMapInteraction) draws it all, so no HUD, widget or controller class is replaced and it works on top of
// WW2, Winter War and GOM (which have their own HUDs):
//  - The spectator overlay. The game only sends player positions to players on a team, so a spectator knows nothing
//    about players out of sight. While the owner spectates, the snapshot below holds every living player.
//  - Teammates the map leaves out. The game's map has 32 places per team, so with more players on a team (MaxPlayers
//    mutator) the 33rd and later never show. While the owner is on a team, the snapshot holds those teammates.
//  - Map drawings. The server keeps them all in CMMapManager and sends each player the ones they may see, through the
//    client functions here; the player's own come up through the server functions.
//  - For a spectator also: the vehicles nobody is in, the players their camera goes to next and before, and the paths
//    bullets, shells, rockets and grenades fly (tracers).
class CMMapInfo extends Info;

// ====================================================
// The snapshot
// ====================================================

// Packed into SnapInfo: bit 0 is the team (0 north, 1 south), bit 1 is set for squad and team leaders, bit 2 for a
// player who has just died (left on the map for a few seconds, as the game does), bits 3 to 5 are what the player is in
// (KIND * KIND_STEP), and bits 6 and 7 count the times they were hurt (0 to 3, then round again), so a spectator's
// client can see a new hit as the count changing
const FLAG_SOUTH = 1;
const FLAG_LEADER = 2;
const FLAG_DEAD = 4;
const KIND_STEP = 8;
const HURT_STEP = 64;
const KIND_INFANTRY = 0;
const KIND_TANK = 1;
const KIND_TRANSPORT = 2;
const KIND_HUEY = 3;
const KIND_COBRA = 4;
const KIND_LOACH = 5;
const KIND_GUNSHIP = 6;
const MAX_SNAPSHOT = 128;

// Vehicles nobody is in, for spectators. VehInfo is 0 for an empty slot, otherwise VEH_PRESENT + KIND * KIND_STEP + the
// team (0 north, 1 south, 2 neither).
const MAX_VEHICLES = 48;
const VEH_PRESENT = 128;
const VEH_NO_TEAM = 2;

struct SnapEntry
{
    var ROPlayerReplicationInfo PRI;
    var vector Loc;
    var byte Data;
};

// Fixed arrays because dynamic ones can't be replicated; only the slots that changed are sent. A slot with no PRI is empty.
var ROPlayerReplicationInfo SnapPRI[MAX_SNAPSHOT];
var vector SnapLoc[MAX_SNAPSHOT];
var byte SnapInfo[MAX_SNAPSHOT];
var bool bSpectating; // the snapshot is the spectator overlay (every living player); otherwise it is left-out teammates
var int SnapCount;    // server-side: slots in use, so only those past the end need clearing

var vector VehLoc[MAX_VEHICLES];
var byte VehInfo[MAX_VEHICLES];
var int VehCount;     // server-side, as SnapCount

// The players a spectator's camera goes to with "next" (SpecNext[0], then [1]) and "previous", worked out on the server
// the way the game picks them
var ROPlayerReplicationInfo SpecNext[2], SpecPrev[2];

// Tracers, for spectators. The server follows every projectile and sends the stretch each flew since the last look as a
// segment (TraceFrom to TraceTo); the segments go round a ring of MAX_TRACERS and TraceHead counts all that were ever
// added, so the client takes the ones past the count it has already seen. The server sends them often (TRACE_RATE a
// second) while the owner spectates, and otherwise leaves the actor at its usual slow rate.
const MAX_TRACERS = 192;
const TRACE_BULLET = 0;
const TRACE_SHELL = 1;   // rockets, tank shells, artillery, bombs and anything else that isn't a bullet or a grenade
const TRACE_GRENADE = 2; // thrown and launched grenades and charges
const TRACE_TEAM_STEP = 4;
const TRACE_NO_TEAM = 2;
const TRACE_RATE = 20;
const SLOW_RATE = 4;

struct TraceSegment
{
    var vector From, To;
    var byte Data;       // kind + team * TRACE_TEAM_STEP (team 0 north, 1 south, TRACE_NO_TEAM neither)
};

var vector TraceFrom[MAX_TRACERS];
var vector TraceTo[MAX_TRACERS];
var byte TraceData[MAX_TRACERS];
var int TraceHead;
var bool bTracersOff; // server-side: this spectator turned the tracers off (mutate tracers off)

// ====================================================
// Drawings
// ====================================================

// What a drawing is
const KIND_PEN = 0;    // freehand line, 2 to MAX_POINTS points
const KIND_LINE = 1;   // straight line, 2 points
const KIND_ARROW = 2;  // straight line with a head at the second point
const KIND_CIRCLE = 3; // centre and a point on the edge
const KIND_BOX = 4;    // two opposite corners
const KIND_MARKER = 5; // an icon at 1 point, optional text
const KIND_TEXT = 6;   // text at 1 point
const NUM_KINDS = 7;

// Who sees a drawing: a team (with a squad, or SQUAD_ALL for the whole team), everyone, only spectators, or only the
// player who drew it
const TEAM_NORTH = 0;
const TEAM_SOUTH = 1;
const TEAM_EVERYONE = 2;
const TEAM_SPECTATORS = 3;
const TEAM_PERSONAL = 4;
const SQUAD_ALL = 255;

// Who a player draws for, as picked on the toolbar
const CH_SQUAD = 0;
const CH_TEAM = 1;
const CH_SPECTATORS = 2;
const CH_NORTH = 3;
const CH_SOUTH = 4;
const CH_EVERYONE = 5;
const CH_PERSONAL = 6;
const NUM_CHANNELS = 7;

const ICON_ATTACK = 0;
const ICON_DEFEND = 1;
const ICON_RALLY = 2;
const ICON_ENEMY = 3;
const ICON_ENEMY_ARMOUR = 4;
const ICON_ENEMY_VEHICLE = 5;
const ICON_ENEMY_HELI = 6;
const ICON_ARTILLERY = 7;
const ICON_LZ = 8;
const ICON_CROSS = 9;
const ICON_DOT = 10;
const NUM_ICONS = 11;

const NUM_COLOURS = 8;

const MAX_POINTS = 200;    // points in one drawing
const MAX_TEXT = 40;       // characters of text on a marker or label
const POINT_CHARS = 6;     // characters per point when packed into a string
const CHUNK_POINTS = 40;   // points per function call (a long string in one call never arrives on a server)

// A point is packed as two coordinates of 3 characters each: (unreal units / COORD_STEP) + COORD_OFFSET in 18 bits,
// so 4 unreal unit (8 cm) steps over +-524288 unreal units (about 10 km), far more than any map
const COORD_STEP = 4.0;
const COORD_OFFSET = 131072;
const COORD_MAX = 262143;
const CODE_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

// A drawing as the client keeps it. Points are world X (north) and Y (east).
struct ClientMapItem
{
    var int ID;
    var byte Kind, Colour, Team, Squad, Icon;
    var int OwnerID;
    var string OwnerName, Text;
    var array<vector2D> Points;
};

// A drawing on its way up to the server, built from ServerBeginItem and ServerAddPoints
struct PendingMapItem
{
    var bool bActive;
    var byte Kind, Colour, Channel, Icon;
    var string Text, Points;
    var int Token;
};

// Set by the server
var bool bDrawingEnabled;    // map drawing is on for this server (bDisableMapDrawing is off)
var bool bSpectatorOverlay;  // the spectator overlay is on (bDisableEnhancedSpectator is off)
var bool bScrimAdmin;        // the owner is a scrim admin (a server admin, or logged in to MutCMenu as one)
var bool bDrawingLocked;     // a scrim admin has stopped players drawing

// Server-side
var CMMapManager Manager;
var array<int> AddQueue;    // drawings this player still has to be sent, oldest first
var array<int> RemoveQueue; // drawings this player has to be told are gone
var int LastViewerKey;      // who this player was (team, squad, commander, spectator) when last synced, -1 before the first
var PendingMapItem Pending;
var float Allowance;        // how many drawings the player may still send right now; refills over time
var float AllowanceTime;

// Client-side
var array<ClientMapItem> Items;
var CMMapInteraction Tool;
var PlayerController ToolOwner;
var bool bToolHooked;       // the tool gets its keys from CMMapInputHook (false: as an Interaction)

replication
{
    if (bNetDirty && Role == ROLE_Authority)
        bSpectating, SnapPRI, SnapLoc, SnapInfo, bScrimAdmin, bDrawingLocked, VehLoc, VehInfo, SpecNext, SpecPrev,
        TraceFrom, TraceTo, TraceData, TraceHead;
    if (bNetInitial && Role == ROLE_Authority)
        bDrawingEnabled, bSpectatorOverlay;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if (WorldInfo.NetMode != NM_DedicatedServer)
        SetTimer(0.5, true, 'InstallTool');
}

// Installs the map Interaction for the local player. On a server's player the info only goes to its owner, so when the
// owner isn't known yet the local player is the owner. Keep trying until that player exists.
simulated function InstallTool()
{
    local PlayerController PC;

    PC = PlayerController(Owner);
    if (PC == None && Role < ROLE_Authority)
        PC = GetALocalPlayerController();
    if (PC == None)
        return;

    ClearTimer('InstallTool');
    if (LocalPlayer(PC.Player) == None)
        return;

    ToolOwner = PC;
    Tool = new(PC) class'CMMapInteraction';
    Tool.Info = self;
    Tool.Colour = Min(Tool.SavedColour, NUM_COLOURS - 1);
    Tool.Icon = Min(Tool.SavedIcon, NUM_ICONS - 1);
    PC.Interactions.AddItem(Tool);

    // Keys come through the viewport hook, ahead of the game's map (which takes left clicks for itself). Only if
    // something else already holds the hook does the tool take them as an Interaction, in front of the game's input.
    bToolHooked = class'CMMapInputHook'.static.Install(LocalPlayer(PC.Player));
    if (!bToolHooked)
    {
        LogInternal("[MutCMenu] Map drawing: the viewport input hook is taken, using the Interaction instead");
        Tool.OnReceivedNativeInputKey = Tool.InputKey;
        KeepToolFirst();
        SetTimer(1.0, true, 'KeepToolFirst');
    }
}

// Without the hook, the tool has to see mouse clicks before the game's own input does, so it sits in front of
// PlayerInput. CMenu reorders the list when it sets up, so this is checked again now and then.
simulated function KeepToolFirst()
{
    local int ToolIndex, InputIndex;

    if (ToolOwner == None || Tool == None)
        return;

    ToolIndex = ToolOwner.Interactions.Find(Tool);
    InputIndex = ToolOwner.Interactions.Find(ToolOwner.PlayerInput);
    if (ToolIndex == INDEX_NONE || InputIndex == INDEX_NONE || ToolIndex < InputIndex)
        return;

    ToolOwner.Interactions.Remove(ToolIndex, 1);
    ToolOwner.Interactions.Insert(InputIndex, 1);
    ToolOwner.Interactions[InputIndex] = Tool;
}

simulated event Destroyed()
{
    if (ToolOwner != None && Tool != None)
    {
        Tool.Cancel();
        Tool.SetDefaultNames(ROHUD(ToolOwner.myHUD), false);
        ToolOwner.Interactions.RemoveItem(Tool);
    }
    Tool = None;

    super.Destroyed();
}

// ====================================================
// Snapshot (server)
// ====================================================

// What the pawn is, for the icon on the map
static function byte GetKind(Pawn P, ROTeamInfo ROTI)
{
    local ROVehicleHelicopter Heli;

    if (ROVehicleTank(P) != None)
        return KIND_TANK;

    if (ROVehicleTransport(P) != None)
        return KIND_TRANSPORT;

    Heli = ROVehicleHelicopter(P);
    if (Heli != None)
    {
        if (ROTI != None)
        {
            switch (ROTI.GetHeliType(Heli))
            {
                case VNHT_Cobra:
                    return KIND_COBRA;
                case VNHT_Loach:
                    return KIND_LOACH;
                case VNHT_Gunship:
                    return KIND_GUNSHIP;
            }
        }
        return KIND_HUEY;
    }

    return ROVehicle(P) != None ? KIND_TRANSPORT : KIND_INFANTRY;
}

static function byte KindOf(byte Data)
{
    return (Data / KIND_STEP) & 7;
}

static function byte HurtCountOf(byte Data)
{
    return Data / HURT_STEP;
}

// The empty vehicles, from Entries (Data packed as VehInfo)
function SetVehicles(out array<SnapEntry> Entries)
{
    local int i, Count;

    for (i = 0; i < Entries.Length && Count < MAX_VEHICLES; i++)
    {
        VehLoc[Count] = Entries[i].Loc;
        VehInfo[Count] = Entries[i].Data;
        Count++;
    }
    for (i = Count; i < VehCount; i++)
        VehInfo[i] = 0;
    VehCount = Count;
}

// Fills the snapshot from Entries, leaving out the owner themselves; returns how many went in
function int SetSnapshot(bool bSpec, out array<SnapEntry> Entries)
{
    local PlayerController PC;
    local int i, Count;

    PC = PlayerController(Owner);
    bSpectating = bSpec;

    for (i = 0; i < Entries.Length && Count < MAX_SNAPSHOT; i++)
    {
        if (PC != None && Entries[i].PRI == PC.PlayerReplicationInfo)
            continue;
        SnapPRI[Count] = Entries[i].PRI;
        SnapLoc[Count] = Entries[i].Loc;
        SnapInfo[Count] = Entries[i].Data;
        Count++;
    }

    for (i = Count; i < SnapCount; i++)
    {
        SnapPRI[i] = None;
        SnapInfo[i] = 0;
    }
    SnapCount = Count;
    return Count;
}

// ====================================================
// Tracers (server)
// ====================================================

static function byte TraceKindOf(byte Data)
{
    return Data % TRACE_TEAM_STEP;
}

static function byte TraceTeamOf(byte Data)
{
    return Data / TRACE_TEAM_STEP;
}

// Adds the first Count segments of Segs (the ones that matter most come first) to the ring
function AddTracers(out array<TraceSegment> Segs, int Count)
{
    local int i, Slot;

    for (i = 0; i < Count && i < Segs.Length; i++)
    {
        Slot = TraceHead % MAX_TRACERS;
        TraceFrom[Slot] = Segs[i].From;
        TraceTo[Slot] = Segs[i].To;
        TraceData[Slot] = Segs[i].Data;
        TraceHead++;
    }
}

// ====================================================
// Shared rules (used on the server to decide, and on the client to show the right buttons)
// ====================================================

static function bool IsCommander(PlayerReplicationInfo PRI)
{
    local ROPlayerReplicationInfo ROPRI;

    ROPRI = ROPlayerReplicationInfo(PRI);
    return ROPRI != None && ROPRI.RoleInfo != None && ROPRI.RoleInfo.bIsTeamLeader;
}

// Squad leaders, the commander and scrim admins, who get the "clear all for" button
static function bool IsLeader(PlayerReplicationInfo PRI, bool bAdmin)
{
    local ROPlayerReplicationInfo ROPRI;

    ROPRI = ROPlayerReplicationInfo(PRI);
    return ROPRI != None && (ROPRI.bIsSquadLeader || IsCommander(PRI) || bAdmin);
}

// The team a player is playing on, or 255 for a spectator or someone who hasn't picked a team yet
static function byte PlayingTeam(PlayerReplicationInfo PRI)
{
    if (PRI == None || PRI.bOnlySpectator || PRI.Team == None || PRI.Team.TeamIndex > 1)
        return 255;
    return PRI.Team.TeamIndex;
}

static function bool InSquad(PlayerReplicationInfo PRI)
{
    local ROPlayerReplicationInfo ROPRI;

    ROPRI = ROPlayerReplicationInfo(PRI);
    return ROPRI != None && PlayingTeam(PRI) != 255 && (ROPRI.SquadIndex < `MAX_SQUADS || ROPRI.SquadIndex == `SQUAD_INDEX_PILOT);
}

static function bool CanSee(PlayerReplicationInfo Viewer, byte Team, byte Squad, int OwnerID)
{
    local ROPlayerReplicationInfo ROPRI;

    if (Viewer == None)
        return false;
    if (Team == TEAM_PERSONAL)
        return OwnerID == Viewer.PlayerID;
    if (Team == TEAM_EVERYONE || Viewer.bOnlySpectator)
        return true;
    if (Team != PlayingTeam(Viewer))
        return false;
    if (Squad == SQUAD_ALL || IsCommander(Viewer))
        return true;

    ROPRI = ROPlayerReplicationInfo(Viewer);
    return ROPRI != None && ROPRI.SquadIndex == Squad;
}

// Players may erase their own drawings; squad leaders their squad's, commanders their team's, scrim admins anything
static function bool CanErase(PlayerReplicationInfo Viewer, bool bAdmin, byte Team, byte Squad, int OwnerID)
{
    local ROPlayerReplicationInfo ROPRI;

    if (!CanSee(Viewer, Team, Squad, OwnerID))
        return false;
    if (bAdmin || OwnerID == Viewer.PlayerID)
        return true;
    if (Team != PlayingTeam(Viewer))
        return false;
    if (IsCommander(Viewer))
        return true;

    ROPRI = ROPlayerReplicationInfo(Viewer);
    return Squad != SQUAD_ALL && ROPRI != None && ROPRI.bIsSquadLeader && ROPRI.SquadIndex == Squad;
}

// Who may clear everything on a channel: anyone their own drawings, squad leaders their squad, the commander their team,
// scrim admins any channel
static function bool CanClearChannel(PlayerReplicationInfo PRI, byte Channel, bool bAdmin)
{
    local ROPlayerReplicationInfo ROPRI;

    ROPRI = ROPlayerReplicationInfo(PRI);
    if (ROPRI == None)
        return false;
    if (bAdmin || Channel == CH_PERSONAL)
        return true;

    switch (Channel)
    {
        case CH_SQUAD:
            return InSquad(PRI) && (ROPRI.bIsSquadLeader || IsCommander(PRI));
        case CH_TEAM:
            return PlayingTeam(PRI) != 255 && IsCommander(PRI);
    }
    return false;
}

// Anyone may draw for themselves, their squad or their team (spectators: themselves and the spectators) unless a scrim
// admin has stopped players drawing. Only scrim admins draw for one named team or for everyone.
static function bool ChannelAllowed(PlayerReplicationInfo PRI, byte Channel, bool bAdmin, bool bLocked)
{
    local bool bMayDraw;

    if (PRI == None)
        return false;

    bMayDraw = bAdmin || !bLocked;
    switch (Channel)
    {
        case CH_PERSONAL:
            return bMayDraw;
        case CH_SQUAD:
            return bMayDraw && InSquad(PRI);
        case CH_TEAM:
            return bMayDraw && PlayingTeam(PRI) != 255;
        case CH_SPECTATORS:
            return bAdmin || (bMayDraw && PRI.bOnlySpectator);
        case CH_NORTH:
        case CH_SOUTH:
        case CH_EVERYONE:
            return bAdmin;
    }
    return false;
}

// Who sees a drawing made on Channel by PRI. False when the channel isn't one they can use.
static function bool ResolveChannel(PlayerReplicationInfo PRI, byte Channel, bool bAdmin, bool bLocked, out byte Team, out byte Squad)
{
    if (!ChannelAllowed(PRI, Channel, bAdmin, bLocked))
        return false;

    Squad = SQUAD_ALL;
    switch (Channel)
    {
        case CH_PERSONAL:
            Team = TEAM_PERSONAL;
            break;
        case CH_SQUAD:
            Team = PlayingTeam(PRI);
            Squad = ROPlayerReplicationInfo(PRI).SquadIndex;
            break;
        case CH_TEAM:
            Team = PlayingTeam(PRI);
            break;
        case CH_SPECTATORS:
            Team = TEAM_SPECTATORS;
            break;
        case CH_NORTH:
            Team = TEAM_NORTH;
            break;
        case CH_SOUTH:
            Team = TEAM_SOUTH;
            break;
        default:
            Team = TEAM_EVERYONE;
    }
    return true;
}

static function string ChannelName(byte Channel)
{
    switch (Channel)
    {
        case CH_PERSONAL:   return "Only me";
        case CH_SQUAD:      return "Squad";
        case CH_TEAM:       return "Team";
        case CH_SPECTATORS: return "Spectators";
        case CH_NORTH:      return "North";
        case CH_SOUTH:      return "South";
    }
    return "Everyone";
}

// Who a drawing is for, as the viewer would say it
static function string AudienceName(PlayerReplicationInfo Viewer, byte Team, byte Squad)
{
    local string S;

    switch (Team)
    {
        case TEAM_EVERYONE:   return "Everyone";
        case TEAM_SPECTATORS: return "Spectators";
        case TEAM_PERSONAL:   return "Only you";
    }

    if (Team == PlayingTeam(Viewer))
        S = "Team";
    else
        S = (Team == TEAM_NORTH) ? "North" : "South";

    if (Squad == `SQUAD_INDEX_PILOT)
        S $= ", pilots";
    else if (Squad != SQUAD_ALL)
        S $= ", squad "$(Squad + 1);
    return S;
}

static function color GetColour(byte Index)
{
    switch (Index)
    {
        case 0: return MakeColor(230, 40, 40, 255);   // red
        case 1: return MakeColor(40, 120, 255, 255);  // blue
        case 2: return MakeColor(40, 200, 60, 255);   // green
        case 3: return MakeColor(255, 220, 30, 255);  // yellow
        case 4: return MakeColor(255, 140, 0, 255);   // orange
        case 5: return MakeColor(180, 70, 230, 255);  // purple
        case 6: return MakeColor(255, 255, 255, 255); // white
    }
    return MakeColor(15, 15, 15, 255);                // black
}

static function string IconName(byte Icon)
{
    switch (Icon)
    {
        case ICON_ATTACK:        return "Attack";
        case ICON_DEFEND:        return "Defend";
        case ICON_RALLY:         return "Rally";
        case ICON_ENEMY:         return "Enemy";
        case ICON_ENEMY_ARMOUR:  return "Enemy armour";
        case ICON_ENEMY_VEHICLE: return "Enemy vehicle";
        case ICON_ENEMY_HELI:    return "Enemy helicopter";
        case ICON_ARTILLERY:     return "Artillery target";
        case ICON_LZ:            return "Landing zone";
        case ICON_CROSS:         return "X";
    }
    return "Point";
}

// How many points a drawing of this kind needs: exactly that many, or at least 2 for a freehand line
static function bool PointCountOk(byte Kind, int Count)
{
    switch (Kind)
    {
        case KIND_PEN:
            return Count >= 2 && Count <= MAX_POINTS;
        case KIND_MARKER:
        case KIND_TEXT:
            return Count == 1;
    }
    return Count == 2;
}

// ====================================================
// Packing points into strings
// ====================================================

static function string EncodeCoord(float V)
{
    local int Q;

    Q = Clamp(Round(V / COORD_STEP) + COORD_OFFSET, 0, COORD_MAX);
    return Mid(CODE_CHARS, (Q >> 12) & 63, 1) $ Mid(CODE_CHARS, (Q >> 6) & 63, 1) $ Mid(CODE_CHARS, Q & 63, 1);
}

static function int DecodeChar(string S, int i)
{
    local int A;

    A = Asc(Mid(S, i, 1));
    if (A >= 65 && A <= 90)
        return A - 65;
    if (A >= 97 && A <= 122)
        return A - 71;
    if (A >= 48 && A <= 57)
        return A + 4;
    if (A == 45)
        return 62;
    return 63;
}

static function float DecodeCoord(string S, int i)
{
    return float((DecodeChar(S, i) << 12) + (DecodeChar(S, i + 1) << 6) + DecodeChar(S, i + 2) - COORD_OFFSET) * COORD_STEP;
}

static function string EncodePoint(vector2D P)
{
    return EncodeCoord(P.X) $ EncodeCoord(P.Y);
}

static function DecodePoints(string S, out array<vector2D> Out)
{
    local int i;
    local vector2D P;

    for (i = 0; i + POINT_CHARS <= Len(S); i += POINT_CHARS)
    {
        P.X = DecodeCoord(S, i);
        P.Y = DecodeCoord(S, i + 3);
        Out.AddItem(P);
    }
}

// ====================================================
// Server side: drawings coming up from the player
// ====================================================

reliable server function ServerBeginItem(byte Kind, byte Colour, byte Channel, byte Icon, string Text, string Points, int Token, bool bMore)
{
    Pending.bActive = true;
    Pending.Kind = Kind;
    Pending.Colour = Colour;
    Pending.Channel = Channel;
    Pending.Icon = Icon;
    Pending.Text = Left(Text, MAX_TEXT);
    Pending.Points = "";
    Pending.Token = Token;
    ServerAddPoints(Points, bMore);
}

reliable server function ServerAddPoints(string Points, bool bMore)
{
    if (!Pending.bActive)
        return;

    if (Len(Pending.Points) < MAX_POINTS * POINT_CHARS)
        Pending.Points = Left(Pending.Points $ Points, MAX_POINTS * POINT_CHARS);

    if (!bMore)
    {
        Pending.bActive = false;
        if (Manager != None)
            Manager.CommitItem(self, Pending);
    }
}

reliable server function ServerErase(int ID)
{
    if (Manager != None)
        Manager.EraseItem(PlayerController(Owner), ID);
}

reliable server function ServerUndo()
{
    if (Manager != None)
        Manager.Undo(PlayerController(Owner));
}

// Mode 0 clears the player's own drawings, 1 everything they may erase on Channel, 2 everything (scrim admins)
reliable server function ServerClear(byte Mode, byte Channel)
{
    if (Manager != None)
        Manager.Clear(PlayerController(Owner), Mode, Channel);
}

// One more drawing allowed per half second, up to 20 at once, so nobody floods everyone else
function bool UseAllowance()
{
    Allowance = FMin(20.0, Allowance + (WorldInfo.TimeSeconds - AllowanceTime) * 2.0);
    AllowanceTime = WorldInfo.TimeSeconds;
    if (Allowance < 1.0)
        return false;
    Allowance -= 1.0;
    return true;
}

// ====================================================
// Client side: drawings coming down from the server
// ====================================================

simulated function int FindItem(int ID)
{
    local int i;

    for (i = Items.Length - 1; i >= 0; i--)
    {
        if (Items[i].ID == ID)
            return i;
    }
    return INDEX_NONE;
}

// Token is the number the owner gave the drawing when they sent it (0 for everyone else), so their own local copy can go
reliable client function ClientAddItem(int ID, byte Kind, byte Colour, byte Team, byte Squad, byte Icon, int OwnerID,
    string OwnerName, string Text, string Points, int Token)
{
    local ClientMapItem Item;

    if (FindItem(ID) != INDEX_NONE)
        return;

    Item.ID = ID;
    Item.Kind = Kind;
    Item.Colour = Colour;
    Item.Team = Team;
    Item.Squad = Squad;
    Item.Icon = Icon;
    Item.OwnerID = OwnerID;
    Item.OwnerName = OwnerName;
    Item.Text = Text;
    DecodePoints(Points, Item.Points);
    Items.AddItem(Item);

    if (Token != 0 && Tool != None)
        Tool.ConfirmSent(Token);
}

reliable client function ClientAddPoints(int ID, string Points)
{
    local array<vector2D> More;
    local int Index, i;

    Index = FindItem(ID);
    if (Index == INDEX_NONE)
        return;

    DecodePoints(Points, More);
    for (i = 0; i < More.Length; i++)
        Items[Index].Points[Items[Index].Points.Length] = More[i];
}

// IDs separated by spaces, so a big clear-up is one call and not hundreds
reliable client function ClientRemoveItems(string IDs)
{
    local array<string> Parts;
    local int i, Index;

    Parts = SplitString(IDs, " ", true);
    for (i = 0; i < Parts.Length; i++)
    {
        Index = FindItem(int(Parts[i]));
        if (Index != INDEX_NONE)
            Items.Remove(Index, 1);
    }
}

reliable client function ClientClearAll()
{
    Items.Length = 0;
}

defaultproperties
{
    RemoteRole=ROLE_SimulatedProxy
    bOnlyRelevantToOwner=true
    bReplicateMovement=false
    bSkipActorPropertyReplication=false // the owner has to reach the client, or its server functions can't be called
    NetUpdateFrequency=4
    LastViewerKey=-1
    Allowance=20
    bDrawingEnabled=true
    bSpectatorOverlay=true
}

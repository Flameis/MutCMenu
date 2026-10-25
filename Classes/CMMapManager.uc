// Server side of MutCMenu's overhead map additions. Each player has a CMMapInfo, and this fills them in:
//  - four times a second, the snapshot: every living player for a spectator (with how often each was hurt, those who
//    have just died, the vehicles nobody is in and who the camera goes to next), or for a player on a team the teammates
//    the game's map leaves out (it has 32 places per team), including for a few seconds after they die,
//  - map drawings: every drawing lives here; each player is sent the ones they may see, a few at a time, and is told
//    when one goes away. When a player's team, squad or role changes they are sent the whole set again for their new
//    view. Drawings are cleared at the start of each round unless the server keeps them.
class CMMapManager extends Info;

struct MapDrawItem
{
    var int ID;
    var byte Kind, Colour, Team, Squad, Icon;
    var int OwnerID;
    var string OwnerName, Text, Points; // Points packed as in CMMapInfo.EncodePoint
    var int OwnerToken;                 // the number the owner gave it, sent back to them only
};

// A teammate the game's map leaves out, remembered so they can still be shown for a moment after they die
struct LeftOutPlayer
{
    var ROPlayerReplicationInfo PRI;
    var vector Loc;
    var byte Data;
    var float SeenTime;  // when last seen alive
    var float DeathTime; // 0 while alive
};

const MAX_ITEMS = 600;         // drawings kept in all; the oldest goes first
const DEFAULT_PER_PLAYER = 60; // drawings one player may have at once, when the server doesn't say
const SEND_CHARS = 1500;       // roughly how much is sent to one player per tick (10 ticks a second)
const REMOVE_IDS = 100;        // removals per call
const DEAD_ICON_TIME = 5.0;    // seconds a left-out teammate (or, for spectators, anyone) stays on the map after dying, as the game does

// A living player as last seen, so a spectator can be shown when they are hurt and where they die
struct WatchedPlayer
{
    var ROPlayerReplicationInfo PRI;
    var Pawn LastPawn;   // health is only compared on the same pawn (getting into a vehicle changes it)
    var int LastHealth;
    var byte HurtCount;
    var vector Loc;
    var byte Data;
    var float SeenTime;
};

// Someone who has just died, shown to spectators for DEAD_ICON_TIME
struct DeadPlayer
{
    var ROPlayerReplicationInfo PRI;
    var vector Loc;
    var byte Data;
    var float DeathTime;
};

var MutCMenu Mut;
var array<MapDrawItem> Items; // in ID order, oldest first
var array<CMMapInfo> Infos;
var int NextID;
var bool bDrawingLocked;      // a scrim admin has stopped players drawing (until they allow it again or the map changes)
var array<LeftOutPlayer> LeftOut;
var array<WatchedPlayer> Watched;
var array<DeadPlayer> RecentDead;

function PostBeginPlay()
{
    super.PostBeginPlay();
    SetTimer(0.1, true, 'SendUpdates');
    SetTimer(0.25, true, 'RefreshSnapshots');
}

function bool DrawingEnabled()
{
    return Mut == None || !Mut.bDisableMapDrawing;
}

function bool SpectatorOverlay()
{
    return Mut == None || !Mut.bDisableEnhancedSpectator;
}

function bool IsAdmin(PlayerController PC)
{
    return PC != None && PC.PlayerReplicationInfo != None && Mut != None && Mut.IsAuthorized(PC);
}

function int PerPlayerLimit()
{
    // A missing ini entry loads as 0
    if (Mut == None || Mut.MaxMapDrawingsPerPlayer <= 0)
        return DEFAULT_PER_PLAYER;
    return Mut.MaxMapDrawingsPerPlayer;
}

function CMMapInfo AddPlayer(PlayerController PC)
{
    local CMMapInfo Info;

    Info = Spawn(class'CMMapInfo', PC);
    if (Info == None)
        return None;

    Info.Manager = self;
    Info.bDrawingEnabled = DrawingEnabled();
    Info.bSpectatorOverlay = SpectatorOverlay();
    Infos.AddItem(Info);
    return Info;
}

// The player's info goes, and so do the drawings only they could see
function RemovePlayer(Controller Exiting)
{
    local int i;

    if (Exiting != None && Exiting.PlayerReplicationInfo != None)
    {
        for (i = Items.Length - 1; i >= 0; i--)
        {
            if (Items[i].Team == class'CMMapInfo'.const.TEAM_PERSONAL && Items[i].OwnerID == Exiting.PlayerReplicationInfo.PlayerID)
                Items.Remove(i, 1);
        }
    }

    for (i = Infos.Length - 1; i >= 0; i--)
    {
        if (Infos[i] == None || Infos[i].bDeleteMe || Infos[i].Owner == Exiting)
        {
            if (Infos[i] != None && !Infos[i].bDeleteMe)
                Infos[i].Destroy();
            Infos.Remove(i, 1);
        }
    }
}

function CMMapInfo FindInfo(PlayerController PC)
{
    local CMMapInfo Info;

    foreach Infos(Info)
    {
        if (Info != None && Info.Owner == PC)
            return Info;
    }
    return None;
}

function int FindItem(int ID)
{
    local int Low, High, Middle;

    // Items are kept in ID order
    Low = 0;
    High = Items.Length - 1;
    while (Low <= High)
    {
        Middle = (Low + High) / 2;
        if (Items[Middle].ID == ID)
            return Middle;
        if (Items[Middle].ID < ID)
            Low = Middle + 1;
        else
            High = Middle - 1;
    }
    return INDEX_NONE;
}

function PrivateMessage(PlayerController PC, string Msg)
{
    if (PC != None)
        PC.TeamMessage(PC.PlayerReplicationInfo, "[Map] "$Msg, 'Event');
}

// ====================================================
// Snapshots
// ====================================================

// The game's map has a place for this player (TeamPRIArrayIndex is 0, not 255, when never given one, so it can't be
// trusted alone: only when that place points back at the player)
static function bool HasMapPlace(ROPlayerReplicationInfo ROPRI, ROTeamInfo ROTI)
{
    return ROTI != None && ROPRI.TeamPRIArrayIndex < ArrayCount(ROTI.TeamPRIArray) && ROTI.TeamPRIArray[ROPRI.TeamPRIArrayIndex] == ROPRI;
}

function int FindLeftOut(ROPlayerReplicationInfo PRI)
{
    local int i;

    for (i = 0; i < LeftOut.Length; i++)
    {
        if (LeftOut[i].PRI == PRI)
            return i;
    }
    return INDEX_NONE;
}

function RefreshSnapshots()
{
    local PlayerController PC;
    local array<CMMapInfo.SnapEntry> Everyone, TeamLeftOut0, TeamLeftOut1, Nobody, EmptyVehicles;
    local int i;
    local byte Team;
    local bool bOverlay;

    bOverlay = SpectatorOverlay();
    BuildSnapshots(Everyone, TeamLeftOut0, TeamLeftOut1);
    if (bOverlay)
        BuildEmptyVehicles(EmptyVehicles);

    for (i = Infos.Length - 1; i >= 0; i--)
    {
        if (Infos[i] == None || Infos[i].bDeleteMe)
            continue;

        PC = PlayerController(Infos[i].Owner);
        if (PC == None || PC.PlayerReplicationInfo == None)
            continue;

        Infos[i].bScrimAdmin = IsAdmin(PC);
        Infos[i].bDrawingLocked = bDrawingLocked;

        Team = class'CMMapInfo'.static.PlayingTeam(PC.PlayerReplicationInfo);
        if (PC.PlayerReplicationInfo.bOnlySpectator && bOverlay)
        {
            Infos[i].SetSnapshot(true, Everyone);
            Infos[i].SetVehicles(EmptyVehicles);
            SetCameraCycle(Infos[i], PC);
            continue;
        }

        if (Team == 0)
            Infos[i].SetSnapshot(false, TeamLeftOut0);
        else if (Team == 1)
            Infos[i].SetSnapshot(false, TeamLeftOut1);
        else
            Infos[i].SetSnapshot(false, Nobody);
        Infos[i].SetVehicles(Nobody);
        Infos[i].SpecNext[0] = None;
        Infos[i].SpecNext[1] = None;
        Infos[i].SpecPrev[0] = None;
        Infos[i].SpecPrev[1] = None;
    }
}

// Vehicles nobody sits in, which the game's map shows nobody. Their team is the vehicle's own (255: neither).
function BuildEmptyVehicles(out array<CMMapInfo.SnapEntry> Vehicles)
{
    local ROVehicle ROV;
    local CMMapInfo.SnapEntry Entry;
    local int i;
    local bool bManned;

    Vehicles.Length = 0;
    foreach WorldInfo.AllPawns(class'ROVehicle', ROV)
    {
        if (ROV.bDeleteMe || ROV.bDeadVehicle || ROV.Health <= 0)
            continue;

        bManned = ROV.Driver != None || ROV.PlayerReplicationInfo != None;
        for (i = 0; i < ROV.Seats.Length && !bManned; i++)
            bManned = ROV.GetSeatPRI(i) != None;
        if (bManned)
            continue;

        Entry.PRI = None;
        Entry.Loc = ROV.Location;
        Entry.Data = class'CMMapInfo'.const.VEH_PRESENT + class'CMMapInfo'.static.GetKind(ROV, None) * class'CMMapInfo'.const.KIND_STEP
            + (ROV.Team < 2 ? int(ROV.Team) : class'CMMapInfo'.const.VEH_NO_TEAM);
        Vehicles.AddItem(Entry);
    }
}

// The players the game would put the spectator's camera on with "next" and "previous", in the order it goes through
// them (ROPlayerController.GetCamPRIs): the players list without the spectator, the chat and WebAdmin stand-ins and
// anyone with no team; then only those with a pawn the spectator may watch, going round from the one they watch now.
// Only for the camera modes that follow a player; free roaming and the map cameras get none.
function SetCameraCycle(CMMapInfo Info, PlayerController PC)
{
    local ROPlayerController ROPC;
    local array<PlayerReplicationInfo> List;
    local PlayerReplicationInfo PRI;
    local int i, Current, Index, Found;
    local byte MyTeam;

    Info.SpecNext[0] = None;
    Info.SpecNext[1] = None;
    Info.SpecPrev[0] = None;
    Info.SpecPrev[1] = None;

    ROPC = ROPlayerController(PC);
    if (ROPC == None || WorldInfo.GRI == None || ROPC.CurrentSpectateMode == SMODE_Roaming || ROPC.CurrentSpectateMode == SMODE_Viewpoint)
        return;

    MyTeam = `NEUTRAL_TEAM_INDEX;
    if (PC.PlayerReplicationInfo.Team != None)
        MyTeam = PC.PlayerReplicationInfo.Team.TeamIndex;
    for (i = 0; i < WorldInfo.GRI.PRIArray.Length; i++)
    {
        PRI = WorldInfo.GRI.PRIArray[i];
        if (PRI == None || PRI == PC.PlayerReplicationInfo || PRI.PlayerName == "<<TeamChatProxy>>" || PRI.PlayerName == "<<WebAdmin>>"
            || PRI.Team == None || PRI.Team.TeamIndex == `NEUTRAL_TEAM_INDEX || (MyTeam != `NEUTRAL_TEAM_INDEX && PRI.Team.TeamIndex != MyTeam))
            continue;
        List.AddItem(PRI);
    }
    if (List.Length == 0)
        return;

    Current = Max(0, List.Find(PC.RealViewTarget));

    // Next twice, then previous twice, each step from the one found before; never the one being watched again
    Index = Current;
    for (Found = 0; Found < 2; Found++)
    {
        Index = NextWatchable(PC, List, Index, 1);
        if (Index == INDEX_NONE || Index == Current)
            break;
        Info.SpecNext[Found] = ROPlayerReplicationInfo(List[Index]);
    }
    Index = Current;
    for (Found = 0; Found < 2; Found++)
    {
        Index = NextWatchable(PC, List, Index, -1);
        if (Index == INDEX_NONE || Index == Current)
            break;
        Info.SpecPrev[Found] = ROPlayerReplicationInfo(List[Index]);
    }
}

// The next player in List after From (Dir 1, or -1 for before) that the camera can go to, or INDEX_NONE
function int NextWatchable(PlayerController PC, array<PlayerReplicationInfo> List, int From, int Dir)
{
    local int i, Index;
    local Controller C;

    Index = From;
    for (i = 0; i < List.Length; i++)
    {
        Index = (Index + Dir + List.Length) % List.Length;
        C = Controller(List[Index].Owner);
        if (C != None && C.Pawn != None && WorldInfo.Game.CanSpectate(PC, List[Index]))
            return Index;
    }
    return INDEX_NONE;
}

function int FindWatched(ROPlayerReplicationInfo PRI)
{
    local int i;

    for (i = 0; i < Watched.Length; i++)
    {
        if (Watched[i].PRI == PRI)
            return i;
    }
    return INDEX_NONE;
}

// Counts the player's hits: a drop in health on the same pawn since the last look. Returns the count, 0 to 3.
function byte WatchPlayer(ROPlayerReplicationInfo PRI, Pawn P, vector Loc, byte Data)
{
    local int Index;

    Index = FindWatched(PRI);
    if (Index == INDEX_NONE)
    {
        Index = Watched.Length;
        Watched.Length = Index + 1;
        Watched[Index].PRI = PRI;
    }

    if (Watched[Index].LastPawn == P && P.Health < Watched[Index].LastHealth)
        Watched[Index].HurtCount = (Watched[Index].HurtCount + 1) % 4;
    Watched[Index].LastPawn = P;
    Watched[Index].LastHealth = P.Health;
    Watched[Index].Loc = Loc;
    Watched[Index].Data = Data;
    Watched[Index].SeenTime = WorldInfo.TimeSeconds;
    return Watched[Index].HurtCount;
}

// Players watched before who weren't alive this time have died (or left, or stopped playing): spectators see them dead
// where their body is for a few seconds. Those still within that time go into Everyone.
function UpdateRecentDead(out array<CMMapInfo.SnapEntry> Everyone)
{
    local CMMapInfo.SnapEntry Entry;
    local DeadPlayer Dead;
    local int i;

    for (i = Watched.Length - 1; i >= 0; i--)
    {
        if (Watched[i].SeenTime == WorldInfo.TimeSeconds)
            continue;

        if (Watched[i].PRI != None && !Watched[i].PRI.bDeleteMe && class'CMMapInfo'.static.PlayingTeam(Watched[i].PRI) != 255)
        {
            Dead.PRI = Watched[i].PRI;
            Dead.Loc = (Watched[i].LastPawn != None && !Watched[i].LastPawn.bDeleteMe) ? Watched[i].LastPawn.Location : Watched[i].Loc;
            Dead.Data = (Watched[i].Data & class'CMMapInfo'.const.FLAG_SOUTH) + class'CMMapInfo'.const.FLAG_DEAD;
            Dead.DeathTime = WorldInfo.TimeSeconds;
            RecentDead.AddItem(Dead);
        }
        Watched.Remove(i, 1);
    }

    for (i = RecentDead.Length - 1; i >= 0; i--)
    {
        // Gone, alive again, or dead long enough
        if (RecentDead[i].PRI == None || RecentDead[i].PRI.bDeleteMe || FindWatched(RecentDead[i].PRI) != INDEX_NONE
            || WorldInfo.TimeSeconds - RecentDead[i].DeathTime > DEAD_ICON_TIME)
        {
            RecentDead.Remove(i, 1);
            continue;
        }

        Entry.PRI = RecentDead[i].PRI;
        Entry.Loc = RecentDead[i].Loc;
        Entry.Data = RecentDead[i].Data;
        Everyone.AddItem(Entry);
    }
}

// Every living player (for spectators, empty when the overlay is off), and for each team the teammates the game's map
// leaves out, with those who have just died
function BuildSnapshots(out array<CMMapInfo.SnapEntry> Everyone, out array<CMMapInfo.SnapEntry> TeamLeftOut0,
    out array<CMMapInfo.SnapEntry> TeamLeftOut1)
{
    local Controller C;
    local ROPlayerReplicationInfo ROPRI;
    local ROTeamInfo ROTI;
    local CMMapInfo.SnapEntry Entry;
    local ROGameReplicationInfo ROGRI;
    local int i, Index;
    local byte Team;
    local bool bOverlay;

    bOverlay = SpectatorOverlay();
    ROGRI = ROGameReplicationInfo(WorldInfo.GRI);
    Everyone.Length = 0;
    TeamLeftOut0.Length = 0;
    TeamLeftOut1.Length = 0;

    foreach WorldInfo.AllControllers(class'Controller', C)
    {
        ROPRI = ROPlayerReplicationInfo(C.PlayerReplicationInfo);
        if (ROPRI == None || ROPRI.bOnlySpectator || ROPRI.Team == None || ROPRI.Team.TeamIndex > 1
            || C.Pawn == None || C.Pawn.bDeleteMe || C.Pawn.Health <= 0)
            continue;

        ROTI = ROTeamInfo(ROPRI.Team);
        Entry.PRI = ROPRI;
        Entry.Loc = C.Pawn.Location;
        Entry.Data = ROPRI.Team.TeamIndex + class'CMMapInfo'.static.GetKind(C.Pawn, ROTI) * class'CMMapInfo'.const.KIND_STEP;
        if (ROPRI.bIsSquadLeader || class'CMMapInfo'.static.IsCommander(ROPRI))
            Entry.Data += class'CMMapInfo'.const.FLAG_LEADER;

        if (bOverlay)
        {
            Entry.Data += WatchPlayer(ROPRI, C.Pawn, Entry.Loc, Entry.Data) * class'CMMapInfo'.const.HURT_STEP;
            Everyone.AddItem(Entry);
            Entry.Data = Entry.Data % class'CMMapInfo'.const.HURT_STEP; // the teammates' maps don't use it
        }

        if (HasMapPlace(ROPRI, ROTI))
            continue;

        if (ROPRI.Team.TeamIndex == 0)
            TeamLeftOut0.AddItem(Entry);
        else
            TeamLeftOut1.AddItem(Entry);

        Index = FindLeftOut(ROPRI);
        if (Index == INDEX_NONE)
        {
            Index = LeftOut.Length;
            LeftOut.Length = Index + 1;
            LeftOut[Index].PRI = ROPRI;
        }
        LeftOut[Index].Loc = Entry.Loc;
        LeftOut[Index].Data = Entry.Data;
        LeftOut[Index].SeenTime = WorldInfo.TimeSeconds;
        LeftOut[Index].DeathTime = 0;
    }

    if (bOverlay)
        UpdateRecentDead(Everyone);

    // Left-out teammates who weren't alive this time: just died (shown dead for a moment), left, or got a place
    for (i = LeftOut.Length - 1; i >= 0; i--)
    {
        if (LeftOut[i].SeenTime == WorldInfo.TimeSeconds)
            continue;

        ROPRI = LeftOut[i].PRI;
        Team = class'CMMapInfo'.static.PlayingTeam(ROPRI);
        if (ROPRI == None || ROPRI.bDeleteMe || Team == 255 || HasMapPlace(ROPRI, ROTeamInfo(ROPRI.Team)))
        {
            LeftOut.Remove(i, 1);
            continue;
        }

        if (LeftOut[i].DeathTime == 0)
            LeftOut[i].DeathTime = WorldInfo.TimeSeconds;
        if (WorldInfo.TimeSeconds - LeftOut[i].DeathTime > DEAD_ICON_TIME)
        {
            LeftOut.Remove(i, 1);
            continue;
        }
        if (ROGRI != None && ROGRI.bDisableTeamDeathIcons)
            continue;

        Entry.PRI = ROPRI;
        Entry.Loc = LeftOut[i].Loc;
        Entry.Data = Team + class'CMMapInfo'.const.FLAG_DEAD;
        if (Team == 0)
            TeamLeftOut0.AddItem(Entry);
        else
            TeamLeftOut1.AddItem(Entry);
    }
}

// ====================================================
// Adding and removing drawings
// ====================================================

// A drawing has arrived from a player: check it, then pass it on to everyone who may see it
function bool CommitItem(CMMapInfo From, CMMapInfo.PendingMapItem P)
{
    local PlayerController PC;
    local MapDrawItem Item;
    local byte Team, Squad;
    local int i, Count, Oldest;
    local bool bAdmin;

    PC = PlayerController(From.Owner);
    if (PC == None || PC.PlayerReplicationInfo == None)
        return false;

    if (!DrawingEnabled())
    {
        PrivateMessage(PC, "Map drawing is turned off on this server.");
        return false;
    }

    if (P.Kind >= class'CMMapInfo'.const.NUM_KINDS || P.Colour >= class'CMMapInfo'.const.NUM_COLOURS
        || P.Icon >= class'CMMapInfo'.const.NUM_ICONS || (Len(P.Points) % class'CMMapInfo'.const.POINT_CHARS) != 0
        || !class'CMMapInfo'.static.PointCountOk(P.Kind, Len(P.Points) / class'CMMapInfo'.const.POINT_CHARS)
        || (P.Kind == class'CMMapInfo'.const.KIND_TEXT && P.Text == ""))
        return false;

    bAdmin = IsAdmin(PC);
    if (!class'CMMapInfo'.static.ResolveChannel(PC.PlayerReplicationInfo, P.Channel, bAdmin, bDrawingLocked, Team, Squad))
    {
        if (bDrawingLocked && !bAdmin)
            PrivateMessage(PC, "An admin has turned map drawing off for players.");
        else
            PrivateMessage(PC, "You can't draw for "$class'CMMapInfo'.static.ChannelName(P.Channel)$".");
        return false;
    }

    if (!From.UseAllowance())
    {
        PrivateMessage(PC, "You are drawing too fast. Wait a moment.");
        return false;
    }

    // Over their limit, their oldest drawing makes room
    Oldest = INDEX_NONE;
    for (i = 0; i < Items.Length; i++)
    {
        if (Items[i].OwnerID == PC.PlayerReplicationInfo.PlayerID)
        {
            if (Oldest == INDEX_NONE)
                Oldest = i;
            Count++;
        }
    }
    if (Count >= PerPlayerLimit() && Oldest != INDEX_NONE)
        RemoveItemAt(Oldest);
    if (Items.Length >= MAX_ITEMS)
        RemoveItemAt(0);

    Item.ID = ++NextID;
    Item.Kind = P.Kind;
    Item.Colour = P.Colour;
    Item.Team = Team;
    Item.Squad = Squad;
    Item.Icon = P.Icon;
    Item.OwnerID = PC.PlayerReplicationInfo.PlayerID;
    Item.OwnerName = PC.PlayerReplicationInfo.PlayerName;
    Item.Text = P.Text;
    Item.Points = P.Points;
    Item.OwnerToken = P.Token;
    Items.AddItem(Item);

    for (i = 0; i < Infos.Length; i++)
    {
        if (Infos[i] != None && Infos[i].LastViewerKey != -1 && CanInfoSee(Infos[i], Item.Team, Item.Squad, Item.OwnerID))
            Infos[i].AddQueue.AddItem(Item.ID);
    }
    return true;
}

function bool CanInfoSee(CMMapInfo Info, byte Team, byte Squad, int OwnerID)
{
    local PlayerController PC;

    PC = PlayerController(Info.Owner);
    return PC != None && class'CMMapInfo'.static.CanSee(PC.PlayerReplicationInfo, Team, Squad, OwnerID);
}

function RemoveItemAt(int Index)
{
    local int i, Queued;

    for (i = 0; i < Infos.Length; i++)
    {
        if (Infos[i] == None)
            continue;

        // Not sent yet: just don't send it. Otherwise the player is told it's gone.
        Queued = Infos[i].AddQueue.Find(Items[Index].ID);
        if (Queued != INDEX_NONE)
            Infos[i].AddQueue.Remove(Queued, 1);
        else if (Infos[i].LastViewerKey != -1 && CanInfoSee(Infos[i], Items[Index].Team, Items[Index].Squad, Items[Index].OwnerID))
            Infos[i].RemoveQueue.AddItem(Items[Index].ID);
    }
    Items.Remove(Index, 1);
}

function EraseItem(PlayerController PC, int ID)
{
    local int Index;

    Index = FindItem(ID);
    if (PC == None || Index == INDEX_NONE)
        return;

    if (class'CMMapInfo'.static.CanErase(PC.PlayerReplicationInfo, IsAdmin(PC), Items[Index].Team, Items[Index].Squad, Items[Index].OwnerID))
        RemoveItemAt(Index);
    else
        PrivateMessage(PC, "You can only erase your own drawings (squad leaders: your squad's, the commander: the team's).");
}

// Takes away the player's newest drawing
function Undo(PlayerController PC)
{
    local int i;

    if (PC == None || PC.PlayerReplicationInfo == None)
        return;

    for (i = Items.Length - 1; i >= 0; i--)
    {
        if (Items[i].OwnerID == PC.PlayerReplicationInfo.PlayerID)
        {
            RemoveItemAt(i);
            return;
        }
    }
}

// Mode 0: the player's own drawings. 1: everything on Channel that they may erase. 2: everything (scrim admins).
// Returns how many went.
function int Clear(PlayerController PC, byte Mode, byte Channel)
{
    local PlayerReplicationInfo PRI;
    local byte Team, Squad;
    local int i, Count;
    local bool bAdmin;

    if (PC == None || PC.PlayerReplicationInfo == None)
        return 0;
    PRI = PC.PlayerReplicationInfo;
    bAdmin = IsAdmin(PC);

    if (Mode == 2)
    {
        if (!bAdmin)
        {
            PrivateMessage(PC, "Only scrim admins can clear every drawing.");
            return 0;
        }
        Count = Items.Length;
        ClearAll();
        return Count;
    }

    if (Mode == 1)
    {
        // Only squad leaders clear their squad, the commander their team and scrim admins anything. Clearing isn't
        // drawing, so the lock doesn't stop it.
        if (!class'CMMapInfo'.static.CanClearChannel(PRI, Channel, bAdmin)
            || !class'CMMapInfo'.static.ResolveChannel(PRI, Channel, bAdmin, false, Team, Squad))
        {
            if (Channel == class'CMMapInfo'.const.CH_SQUAD)
                PrivateMessage(PC, "Only the squad leader can clear the squad's drawings.");
            else if (Channel == class'CMMapInfo'.const.CH_TEAM)
                PrivateMessage(PC, "Only the commander can clear the team's drawings.");
            else
                PrivateMessage(PC, "You can't clear "$class'CMMapInfo'.static.ChannelName(Channel)$".");
            return 0;
        }
    }

    for (i = Items.Length - 1; i >= 0; i--)
    {
        if (Mode == 0)
        {
            if (Items[i].OwnerID != PRI.PlayerID)
                continue;
        }
        else if (Items[i].Team != Team || Items[i].Squad != Squad
            || !class'CMMapInfo'.static.CanErase(PRI, bAdmin, Items[i].Team, Items[i].Squad, Items[i].OwnerID))
            continue;

        RemoveItemAt(i);
        Count++;
    }
    return Count;
}

function ClearAll()
{
    local int i;

    Items.Length = 0;
    for (i = 0; i < Infos.Length; i++)
    {
        if (Infos[i] == None)
            continue;
        Infos[i].AddQueue.Length = 0;
        Infos[i].RemoveQueue.Length = 0;
        if (Infos[i].LastViewerKey != -1)
            Infos[i].ClientClearAll();
    }
}

// A scrim admin stops (or lets) players draw. Drawings already made stay.
function SetLocked(PlayerController PC, bool bLock)
{
    local int i;

    if (!IsAdmin(PC))
    {
        PrivateMessage(PC, "Only scrim admins can turn map drawing on or off.");
        return;
    }

    bDrawingLocked = bLock;
    for (i = 0; i < Infos.Length; i++)
    {
        if (Infos[i] != None)
            Infos[i].bDrawingLocked = bLock;
    }

    if (bLock)
        WorldInfo.Game.Broadcast(self, "[Map] "$PC.PlayerReplicationInfo.PlayerName$" turned map drawing off for players.");
    else
        WorldInfo.Game.Broadcast(self, "[Map] "$PC.PlayerReplicationInfo.PlayerName$" turned map drawing back on.");
}

// A new round
function Reset()
{
    super.Reset();

    if (Mut == None || !Mut.bKeepMapDrawingsBetweenRounds)
        ClearAll();
}

// ====================================================
// Commands
// ====================================================

// mapundo, mapclear and mapdrawing; true when Args was one of them
function bool HandleCommand(PlayerController PC, array<string> Args)
{
    local string What;
    local int Count;

    if (Args.Length == 0)
        return false;

    switch (Caps(Args[0]))
    {
        case "MAPUNDO":
            Undo(PC);
            return true;

        case "MAPDRAWING":
            What = Args.Length > 1 ? Caps(Args[1]) : "";
            if (What == "ON")
                SetLocked(PC, false);
            else if (What == "OFF")
                SetLocked(PC, true);
            else
                PrivateMessage(PC, "Map drawing for players is "$(bDrawingLocked ? "off" : "on")$". Scrim admins: mutate mapdrawing on | off");
            return true;

        case "MAPCLEAR":
            What = Args.Length > 1 ? Caps(Args[1]) : "ALL";
            switch (What)
            {
                case "MINE":       Count = Clear(PC, 0, 0); break;
                case "SQUAD":      Count = Clear(PC, 1, class'CMMapInfo'.const.CH_SQUAD); break;
                case "TEAM":       Count = Clear(PC, 1, class'CMMapInfo'.const.CH_TEAM); break;
                case "NORTH":      Count = Clear(PC, 1, class'CMMapInfo'.const.CH_NORTH); break;
                case "SOUTH":      Count = Clear(PC, 1, class'CMMapInfo'.const.CH_SOUTH); break;
                case "SPECTATORS": Count = Clear(PC, 1, class'CMMapInfo'.const.CH_SPECTATORS); break;
                case "EVERYONE":   Count = Clear(PC, 1, class'CMMapInfo'.const.CH_EVERYONE); break;
                case "ALL":        Count = Clear(PC, 2, 0); break;
                default:
                    PrivateMessage(PC, "Use: mutate mapclear mine | squad | team | north | south | spectators | everyone | all");
                    return true;
            }
            PrivateMessage(PC, "Cleared "$Count$" drawing(s).");
            return true;
    }
    return false;
}

// ====================================================
// Sending drawings
// ====================================================

// Everything about a player that changes which drawings they see
function int ViewerKey(PlayerController PC)
{
    local ROPlayerReplicationInfo ROPRI;

    ROPRI = ROPlayerReplicationInfo(PC.PlayerReplicationInfo);
    if (ROPRI == None)
        return -2;
    if (ROPRI.bOnlySpectator)
        return 1;
    return 2 + class'CMMapInfo'.static.PlayingTeam(ROPRI) * 4 + ROPRI.SquadIndex * 2048
        + (class'CMMapInfo'.static.IsCommander(ROPRI) ? 2 : 0);
}

function SendUpdates()
{
    local int i;

    for (i = Infos.Length - 1; i >= 0; i--)
    {
        if (Infos[i] == None || Infos[i].bDeleteMe)
            Infos.Remove(i, 1);
        else
            SendTo(Infos[i]);
    }
}

function SendTo(CMMapInfo Info)
{
    local PlayerController PC;
    local int Key, i, Index, Sent, Chunk;
    local string IDs, Points;

    PC = PlayerController(Info.Owner);
    if (PC == None || PC.PlayerReplicationInfo == None)
        return;

    // A new view: start again from nothing
    Key = ViewerKey(PC);
    if (Key != Info.LastViewerKey)
    {
        Info.LastViewerKey = Key;
        Info.AddQueue.Length = 0;
        Info.RemoveQueue.Length = 0;
        Info.ClientClearAll();
        for (i = 0; i < Items.Length; i++)
        {
            if (CanInfoSee(Info, Items[i].Team, Items[i].Squad, Items[i].OwnerID))
                Info.AddQueue.AddItem(Items[i].ID);
        }
    }

    while (Info.RemoveQueue.Length > 0)
    {
        IDs = "";
        for (i = 0; i < Info.RemoveQueue.Length && i < REMOVE_IDS; i++)
            IDs $= Info.RemoveQueue[i]$" ";
        Info.RemoveQueue.Remove(0, i);
        Info.ClientRemoveItems(IDs);
    }

    Chunk = class'CMMapInfo'.const.CHUNK_POINTS * class'CMMapInfo'.const.POINT_CHARS;
    while (Info.AddQueue.Length > 0 && Sent < SEND_CHARS)
    {
        Index = FindItem(Info.AddQueue[0]);
        Info.AddQueue.Remove(0, 1);
        if (Index == INDEX_NONE)
            continue;

        Points = Items[Index].Points;
        Info.ClientAddItem(Items[Index].ID, Items[Index].Kind, Items[Index].Colour, Items[Index].Team, Items[Index].Squad,
            Items[Index].Icon, Items[Index].OwnerID, Items[Index].OwnerName, Items[Index].Text, Left(Points, Chunk),
            (Items[Index].OwnerID == PC.PlayerReplicationInfo.PlayerID) ? Items[Index].OwnerToken : 0);
        Sent += 60 + Len(Items[Index].Text) + Min(Len(Points), Chunk);

        for (i = Chunk; i < Len(Points); i += Chunk)
        {
            Info.ClientAddPoints(Items[Index].ID, Mid(Points, i, Chunk));
            Sent += 10 + Min(Len(Points) - i, Chunk);
        }
    }
}

defaultproperties
{
    RemoteRole=ROLE_None
}

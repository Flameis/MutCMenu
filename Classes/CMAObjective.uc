// A capture objective built with the Builder: a flat shape drawn from three or more corners.
// It captures by itself (its own timer on the server), so it works in every Territories-based game mode, not only in
// CMenu's own game modes. The game's own capture timer ignores it (it has no volume) apart from reporting its status,
// which is what keeps the map, the capture bar and Realism Match's open/close/owner commands working.
class CMAObjective extends ROObjective;

const MIN_CORNER_GAP = 25.0;    // Corners closer together than this (half a meter) are the same corner clicked twice
const MIN_CORNER_COUNT = 3;
const MAX_CORNER_COUNT = 32;    // What can be sent to clients

var array<Vector2D> Corners;
var ROGameInfoTerritories ROGIT;
var ROGameReplicationInfo ROGRI;
var string DisplayName;   // ObjName cannot be set while the game runs

var repnotify byte ReplicatedObjIndex;
var repnotify byte ReplicatedObjRepIndex;
var repnotify string ReplicatedObjName;
var repnotify string ReplicatedObjShortName;
var repnotify byte ReplicatedInitialObjState;
var repnotify bool ReplicatedEnabled;
var repnotify bool ReplicatedActive;
var repnotify byte ReplicatedCornerCount;
var Vector2D ReplicatedCorners[32];
var vector ReplicatedLocation;
var repnotify bool bObjectiveReady;

// Counted again every capture tick
var int NumCappers[2];
var float LeaderMultiplier[2];
var int AxisSquadCount[`MAX_SQUADS];
var int AlliesSquadCount[`MAX_SQUADS];
var array<ROPlayerController> PlayerCappers;
var array<Pawn> AllCappers;

replication
{
    if (Role == ROLE_Authority)
        ReplicatedObjIndex, ReplicatedObjRepIndex, ReplicatedObjName, ReplicatedObjShortName,
        ReplicatedInitialObjState, ReplicatedEnabled, ReplicatedActive, ReplicatedLocation,
        ReplicatedCornerCount, ReplicatedCorners, bObjectiveReady;
}

function string GetDisplayName()
{
    return DisplayName;
}

// ====================================================
// Setting up
// ====================================================

// Called once on the server right after it is spawned. The corners are the shape as the builder clicked it; the objective
// is left as it is (and goes away on its own) when it cannot be made.
function Init(array<Vector2D> InCorners)
{
    local Vector2D Middle;
    local vector Where;
    local int Slot, RepIndex, I;

    ROGIT = ROGameInfoTerritories(WorldInfo.Game);
    ROGRI = ROGameReplicationInfo(WorldInfo.GRI);
    Corners = CleanCorners(InCorners);

    if (ROGIT == none || ROGRI == none || Corners.Length < MIN_CORNER_COUNT)
    {
        Destroy();
        return;
    }

    if (!IsSimple(Corners))
    {
        // The corners were clicked in an order that crosses itself: go round them instead
        SortAroundMiddle(Corners);
    }

    Slot = FreeSlot();
    RepIndex = FreeRepIndex();
    if (Slot < 0 || RepIndex < 0)
    {
        `warn("CMAObjective: no free objective slot");
        Destroy();
        return;
    }

    // The objective sits in the middle of its shape: that is where the map puts its letter, and where dropping at it goes
    Middle = InsidePoint(Corners);
    Where = Location;
    Where.X = Middle.X;
    Where.Y = Middle.Y;
    SetLocation(Where);

    ObjIndex = Slot;
    ObjRepIndex = RepIndex;
    ObjShortName = IntToString(Slot);
    DisplayName = "Custom Objective " $ ObjShortName;
    MinimumCaptureTime = 30;
    InitialObjState = OBJ_Neutral;
    AppliedInitialObjState = InitialObjState;
    bEnabled = true;

    ROGIT.Objectives[ObjIndex] = self;
    ROGIT.EnabledObjectives++;
    Reset();
    SetEnabled(true);
    SetActive(true);
    ROGRI.AddObjective(self, true);
    ROGRI.ObjectiveNames[ObjIndex] = DisplayName;
    ROGRI.UpdateObjectiveStatus(self);

    ReplicatedObjIndex = ObjIndex;
    ReplicatedObjRepIndex = ObjRepIndex;
    ReplicatedObjName = DisplayName;
    ReplicatedObjShortName = ObjShortName;
    ReplicatedInitialObjState = InitialObjState;
    ReplicatedEnabled = bEnabled;
    ReplicatedActive = bActive;
    ReplicatedLocation = Location;
    ReplicatedCornerCount = Min(Corners.Length, MAX_CORNER_COUNT);
    for (I = 0; I < ReplicatedCornerCount; I++)
    {
        ReplicatedCorners[I] = Corners[I];
    }
    bObjectiveReady = true;
    bNetDirty = true;

    SetTimer(class'ROGameInfoTerritories'.const.CAPTURE_UPDATE_RATE, true, 'CaptureTick');
    for (I = 0; I < Corners.Length; I++)
    {
        `log(self $ ": corner " $ Corners[I].X @ Corners[I].Y);
    }
}

// Corners with the ones clicked twice taken out, and no more than can be sent
static function array<Vector2D> CleanCorners(array<Vector2D> In)
{
    local array<Vector2D> Result;
    local int I;

    for (I = 0; I < In.Length && Result.Length < MAX_CORNER_COUNT; I++)
    {
        if (Result.Length == 0 || V2Dist(Result[Result.Length - 1], In[I]) >= MIN_CORNER_GAP)
        {
            Result.AddItem(In[I]);
        }
    }

    // The last one back on the first
    while (Result.Length > 1 && V2Dist(Result[Result.Length - 1], Result[0]) < MIN_CORNER_GAP)
    {
        Result.Remove(Result.Length - 1, 1);
    }
    return Result;
}

// The lowest free place in the game's list of objectives, or -1. A place is free when the game has no objective there and
// nothing is announcing one there.
function int FreeSlot()
{
    local int Slot;

    for (Slot = 0; Slot < `MAX_OBJECTIVES; Slot++)
    {
        if ((Slot >= ROGIT.Objectives.Length || ROGIT.Objectives[Slot] == none) && !ROGRI.GetObjectiveEnabled(Slot)
            && (Slot >= ROGRI.Objectives.Length || ROGRI.Objectives[Slot] == none))
        {
            return Slot;
        }
    }
    return -1;
}

// A number no other objective in the map uses. Clients find an objective by it, and a map's objectives for the other player
// counts are in the map too, so it has to be higher than all of theirs, not just the ones in play.
function int FreeRepIndex()
{
    local ROObjective Other;
    local int Highest, I;

    Highest = -1;
    foreach AllActors(class'ROObjective', Other)
    {
        if (Other != self && Other.ObjRepIndex != `OBJECTIVE_REPINDEX_NONE && Other.ObjRepIndex > Highest)
        {
            Highest = Other.ObjRepIndex;
        }
    }
    for (I = 0; I < `MAX_OBJECTIVES; I++)
    {
        if (ROGRI.ObjectiveRepIndices[I] != `OBJECTIVE_REPINDEX_NONE && ROGRI.ObjectiveRepIndices[I] > Highest)
        {
            Highest = ROGRI.ObjectiveRepIndices[I];
        }
    }

    return (Highest + 1 < `OBJECTIVE_REPINDEX_NONE) ? Highest + 1 : -1;
}

function Reset()
{
    super.Reset();

    // The game's own capture timer must not also uncapture this objective: it sees nobody inside. This class does that
    // itself, from the capture time.
    UnCapRate = 0.0;
    MaxUnCapRate = 0.0;
}

event SetActive(bool bNewValue)
{
    super.SetActive(bNewValue);
    ReplicatedActive = bActive;
    bNetDirty = true;
}

event SetEnabled(bool bNewValue)
{
    super.SetEnabled(bNewValue);
    ReplicatedEnabled = bEnabled;
    bNetDirty = true;
}

// The game keeps a list of objectives and a status for each; a removed objective takes its place out of both
simulated event Destroyed()
{
    local ROPlayerController ROPC;
    local ROGameReplicationInfo GRI;
    local int I;

    GRI = ROGameReplicationInfo(WorldInfo.GRI);
    if (GRI != none && bObjectiveReady && ObjIndex < `MAX_OBJECTIVES)
    {
        if (Role == ROLE_Authority)
        {
            if (ROGIT != none && ObjIndex < ROGIT.Objectives.Length && ROGIT.Objectives[ObjIndex] == self)
            {
                ROGIT.Objectives[ObjIndex] = none;
                ROGIT.EnabledObjectives = Max(0, ROGIT.EnabledObjectives - 1);
            }

            GRI.ObjectiveStatus[ObjIndex] = 0;
            GRI.ObjectiveRepIndices[ObjIndex] = `OBJECTIVE_REPINDEX_NONE;
            GRI.ObjectiveCapProgress[ObjIndex] = 0;
            GRI.ObjectiveForceRatio[ObjIndex] = 0;
            if (ObjIndex < GRI.ObjectiveActive.Length)
            {
                GRI.ObjectiveActive[ObjIndex] = false;
            }

            // Players inside it are not inside anything any more
            for (I = 0; I < PlayerCappers.Length; I++)
            {
                if (PlayerCappers[I] != none && PlayerCappers[I].ObjectiveName == DisplayName)
                {
                    PlayerCappers[I].ObjectiveName = "";
                }
            }
        }

        if (ObjIndex < GRI.Objectives.Length && GRI.Objectives[ObjIndex] == self)
        {
            GRI.Objectives[ObjIndex] = none;
        }
        GRI.bNetDirty = true;

        if (WorldInfo.NetMode != NM_DedicatedServer)
        {
            foreach LocalPlayerControllers(class'ROPlayerController', ROPC)
            {
                ROPC.ObjectivesUpdated();
                ROPC.ObjectiveStatusChanged(GRI);
            }
        }
    }

    super.Destroyed();
}

simulated event ReplicatedEvent(name VarName)
{
    local ROPlayerController ROPC;
    local int I;

    if (VarName == 'bObjectiveReady' && bObjectiveReady)
    {
        ObjIndex = ReplicatedObjIndex;
        ObjRepIndex = ReplicatedObjRepIndex;
        DisplayName = ReplicatedObjName;
        ObjShortName = ReplicatedObjShortName;
        InitialObjState = EObjectiveState(ReplicatedInitialObjState);
        AppliedInitialObjState = InitialObjState;
        bEnabled = ReplicatedEnabled;
        bActive = ReplicatedActive;
        SetLocation(ReplicatedLocation);
        Corners.Remove(0, Corners.Length);
        for (I = 0; I < ReplicatedCornerCount; I++)
        {
            Corners.AddItem(ReplicatedCorners[I]);
        }

        ROGRI = ROGameReplicationInfo(WorldInfo.GRI);
        if (ROGRI != none)
        {
            ROGRI.AddObjective(self, true);
            ROGRI.ObjectiveNames[ObjIndex] = DisplayName;
            foreach LocalPlayerControllers(class'ROPlayerController', ROPC)
            {
                ROPC.ObjectivesUpdated();
                ROPC.ObjectiveStatusChanged(ROGRI);
            }
        }
    }
    else if (VarName == 'ReplicatedActive')
    {
        bActive = ReplicatedActive;
    }
    else if (VarName == 'ReplicatedEnabled')
    {
        bEnabled = ReplicatedEnabled;
    }
    else
    {
        super.ReplicatedEvent(VarName);
    }
}

// ====================================================
// Capturing (server)
// ====================================================

// Whether a place is inside the objective's shape. Height does not matter.
function bool ContainsLocation(vector Loc)
{
    local Vector2D P;

    P.X = Loc.X;
    P.Y = Loc.Y;
    return PolygonContains(Corners, P);
}

// One step of the capture, the same sums as the game's own timer does for an objective with a volume
function CaptureTick()
{
    local Pawn P;
    local ROVehicle ROV;
    local float CapRatio, UnCap, MaxUnCap, TeamCapValue[2];
    local int I, T, TotalCappers[2];
    local byte OldStatus, OldProgress, OldRatio;

    // Realism Match opens and closes objectives by setting bActive directly: clients are told that too
    if (ReplicatedActive != bActive)
    {
        ReplicatedActive = bActive;
        bNetDirty = true;
    }

    if (ROGIT == none || ROGRI == none || !ROGIT.bRoundActive || !bActive
        || ObjIndex >= ROGIT.Objectives.Length || ROGIT.Objectives[ObjIndex] != self)
    {
        return;
    }

    // Kept at nothing for the game's timer (see Reset). Realism Match's capture time sets them again.
    UnCapRate = 0.0;
    MaxUnCapRate = 0.0;
    UnCap = 0.333 / FMax(1.0, MinimumCaptureTime);
    MaxUnCap = 1.333 / FMax(1.0, MinimumCaptureTime);

    NumCappers[`AXIS_TEAM_INDEX] = 0;
    NumCappers[`ALLIES_TEAM_INDEX] = 0;
    LeaderMultiplier[`AXIS_TEAM_INDEX] = 1.0;
    LeaderMultiplier[`ALLIES_TEAM_INDEX] = 1.0;
    for (I = 0; I < `MAX_SQUADS; I++)
    {
        AxisSquadCount[I] = 0;
        AlliesSquadCount[I] = 0;
    }
    PlayerCappers.Remove(0, PlayerCappers.Length);
    AllCappers.Remove(0, AllCappers.Length);

    foreach WorldInfo.AllPawns(class'Pawn', P)
    {
        if (P.Health <= 0)
        {
            continue;
        }

        if (ROPawn(P) != none)
        {
            if (ContainsLocation(P.Location))
            {
                AddCapper(P, P.PlayerReplicationInfo);
            }
            else if (ROPlayerController(P.Controller) != none && ROPlayerController(P.Controller).ObjectiveName == DisplayName)
            {
                ROPlayerController(P.Controller).ObjectiveName = "";
            }
        }
        else if (ROVehicle(P) != none)
        {
            ROV = ROVehicle(P);
            if (ROVehicleHelicopter(P) == none && ContainsLocation(ROV.Location))
            {
                for (I = 0; I < ROV.Seats.Length; I++)
                {
                    if (!ROV.Seats[I].bNonEnterable && ROV.Seats[I].SeatPawn != none && ROV.GetSeatPRI(I) != none)
                    {
                        AddCapper(ROV.Seats[I].SeatPawn, ROV.GetSeatPRI(I));
                    }
                }
            }
            else
            {
                for (I = 0; I < ROV.Seats.Length; I++)
                {
                    if (ROV.Seats[I].SeatPawn != none && ROPlayerController(ROV.Seats[I].SeatPawn.Controller) != none
                        && ROPlayerController(ROV.Seats[I].SeatPawn.Controller).ObjectiveName == DisplayName)
                    {
                        ROPlayerController(ROV.Seats[I].SeatPawn.Controller).ObjectiveName = "";
                    }
                }
            }
        }
        else if (ROTurret(P) != none && ROTurret(P).Driver != none && P.PlayerReplicationInfo != none)
        {
            if (ContainsLocation(P.Location))
            {
                AddCapper(ROTurret(P).Driver, P.PlayerReplicationInfo);
            }
            else if (ROPlayerController(P.Controller) != none && ROPlayerController(P.Controller).ObjectiveName == DisplayName)
            {
                ROPlayerController(P.Controller).ObjectiveName = "";
            }
        }
    }

    // Squad mates in the zone count for more
    for (T = 0; T < 2; T++)
    {
        TeamCapValue[T] = NumCappers[T];
        for (I = 0; I < `MAX_SQUADS; I++)
        {
            if (SquadCount(T, I) > 1)
            {
                TeamCapValue[T] += (SquadCount(T, I) - 1) * class'ROGameInfoTerritories'.const.SQUAD_CAPTURE_BONUS_MULTIPLIER;
            }
        }
    }
    TotalCappers[`AXIS_TEAM_INDEX] = Max(1, ROGIT.TeamCount(ROGIT.AxisTeam));
    TotalCappers[`ALLIES_TEAM_INDEX] = Max(1, ROGIT.TeamCount(ROGIT.AlliesTeam));

    if (TeamCapValue[`AXIS_TEAM_INDEX] > TeamCapValue[`ALLIES_TEAM_INDEX])
    {
        CapRatio = FMin(NumCappers[`AXIS_TEAM_INDEX] * CapRate * LeaderMultiplier[`AXIS_TEAM_INDEX]
            * float(NumCappers[`AXIS_TEAM_INDEX]) / TotalCappers[`AXIS_TEAM_INDEX], MaxCapRate);
        PushCapture(`AXIS_TEAM_INDEX, CapRatio, UnCap, MaxUnCap);
    }
    else if (TeamCapValue[`AXIS_TEAM_INDEX] < TeamCapValue[`ALLIES_TEAM_INDEX])
    {
        CapRatio = FMin(NumCappers[`ALLIES_TEAM_INDEX] * CapRate * LeaderMultiplier[`ALLIES_TEAM_INDEX]
            * float(NumCappers[`ALLIES_TEAM_INDEX]) / TotalCappers[`ALLIES_TEAM_INDEX], MaxCapRate);
        PushCapture(`ALLIES_TEAM_INDEX, CapRatio, UnCap, MaxUnCap);
    }
    else if (CapProgress > 0.0)
    {
        // Nobody (or an even fight): whatever was gained drains away
        CapProgress -= class'ROGameInfoTerritories'.const.CAPTURE_UPDATE_RATE * UnCap;
        if (CapProgress <= 0.0)
        {
            CapProgress = 0.0;
            ROGIT.bAttackersCapping = false;
            bCapping = false;
        }
    }

    if (CapProgress < 0.0)
    {
        if (ObjState == OBJ_Neutral)
        {
            // The extra uncapturing flips into capturing for the other side
            CapProgress *= -1.0;
            CapTeamIndex = 1 - CapTeamIndex;
        }
        else
        {
            bCapping = false;
            CapTeamIndex = `NEUTRAL_TEAM_INDEX;
            CapProgress = 0.0;
            ROGIT.bAttackersCapping = false;
        }
    }
    else if (CapProgress >= 1.0)
    {
        Captured();
    }

    // Everybody inside is told which objective it is
    for (I = 0; I < PlayerCappers.Length; I++)
    {
        if (!bCapping)
        {
            PlayerCappers[I].ObjectiveEnterTime = -1;
        }
        else if (PlayerCappers[I].ObjectiveName != DisplayName)
        {
            PlayerCappers[I].ObjectiveEnterTime = WorldInfo.TimeSeconds;
        }
        else if (WorldInfo.TimeSeconds - PlayerCappers[I].ObjectiveEnterTime >= class'ROGameInfoTerritories'.const.CONTESTED_SCORE_INTERVAL)
        {
            ROGIT.AddDelayedKillMessage(ROKMT_ObjectiveContested, ROGIT.GameReplicationInfo.ElapsedTime, PlayerCappers[I].PlayerReplicationInfo);
            PlayerCappers[I].ObjectiveEnterTime = WorldInfo.TimeSeconds;
        }

        PlayerCappers[I].ObjectiveIndex = ObjIndex;
        PlayerCappers[I].ObjectiveName = DisplayName;
        PlayerCappers[I].ReplicatedEvent('ObjectiveName');
    }

    // The game's timer tells everyone the same thing; this keeps it from being a quarter of a second behind
    OldStatus = ROGRI.ObjectiveStatus[ObjIndex];
    OldProgress = ROGRI.ObjectiveCapProgress[ObjIndex];
    OldRatio = ROGRI.ObjectiveForceRatio[ObjIndex];
    ROGRI.UpdateObjectiveStatus(self);
    ROGRI.ObjectiveCapProgress[ObjIndex] = byte(CapProgress * 255.0);
    ROGRI.ObjCappers[ObjIndex].NumOfCappers[`AXIS_TEAM_INDEX] = NumCappers[`AXIS_TEAM_INDEX];
    ROGRI.ObjCappers[ObjIndex].NumOfCappers[`ALLIES_TEAM_INDEX] = NumCappers[`ALLIES_TEAM_INDEX];
    if (NumCappers[`AXIS_TEAM_INDEX] > 0 || NumCappers[`ALLIES_TEAM_INDEX] > 0)
    {
        ROGRI.ObjectiveForceRatio[ObjIndex] = byte((float(NumCappers[`AXIS_TEAM_INDEX])
            / (NumCappers[`AXIS_TEAM_INDEX] + NumCappers[`ALLIES_TEAM_INDEX])) * 254.0);
    }
    if (ROGRI.ObjectiveStatus[ObjIndex] != OldStatus || ROGRI.ObjectiveCapProgress[ObjIndex] != OldProgress
        || ROGRI.ObjectiveForceRatio[ObjIndex] != OldRatio)
    {
        ROGRI.bNetDirty = true;
    }
}

function int SquadCount(int Team, int Squad)
{
    return (Team == `AXIS_TEAM_INDEX) ? AxisSquadCount[Squad] : AlliesSquadCount[Squad];
}

// One player (or the crew member of a vehicle) standing in the zone
function AddCapper(Pawn CapPawn, PlayerReplicationInfo PRI)
{
    local ROPlayerReplicationInfo ROPRI;
    local int Team;

    if (PRI == none || PRI.Team == none || PRI.Team.TeamIndex > 1)
    {
        return;
    }

    Team = PRI.Team.TeamIndex;
    NumCappers[Team]++;
    AllCappers.AddItem(CapPawn);
    if (ROPlayerController(CapPawn.Controller) != none)
    {
        PlayerCappers.AddItem(ROPlayerController(CapPawn.Controller));
    }

    ROPRI = ROPlayerReplicationInfo(PRI);
    if (ROPRI != none)
    {
        if (ROPRI.RoleInfo != none && (ROPRI.bIsSquadLeader || ROPRI.RoleInfo.bIsTeamLeader))
        {
            LeaderMultiplier[Team] = class'ROGameInfoTerritories'.const.LEADER_CAPTURE_BONUS_MULTIPLIER;
        }
        if (ROPRI.SquadIndex < `MAX_SQUADS)
        {
            if (Team == `AXIS_TEAM_INDEX)
            {
                AxisSquadCount[ROPRI.SquadIndex]++;
            }
            else
            {
                AlliesSquadCount[ROPRI.SquadIndex]++;
            }
        }
    }

    if (ROAIController(CapPawn.Controller) != none)
    {
        ROAIController(CapPawn.Controller).NotifyActiveObjectiveIndex(ObjIndex);
    }
}

// The team with more people inside takes the objective if it is not theirs; if the other team had progress, it goes down first
function PushCapture(int Team, float CapRatio, float UnCap, float MaxUnCap)
{
    if (CapTeamIndex == 1 - Team)
    {
        CapProgress -= class'ROGameInfoTerritories'.const.CAPTURE_UPDATE_RATE * FMin(UnCap + CapRatio, MaxUnCap);
    }
    else if (ObjState != EObjectiveState(Team))
    {
        if (!bCapping || CapTeamIndex != Team)
        {
            if (!ROGIT.bSuppressCappingNotice && ROGIT.bLastObjective && ROGIT.DefendingTeam == 1 - Team)
            {
                ROGIT.BroadcastLocalizedMessage(class'ROLocalMessageGameRedAlert',
                    (Team == `AXIS_TEAM_INDEX) ? RORAMSG_DefendingFinalObjSouth : RORAMSG_DefendingFinalObj);
            }
            else
            {
                ROGIT.BroadcastLocalizedMessage(class'ROLocalMessageObjective',
                    (Team == `AXIS_TEAM_INDEX) ? ROOBJMSG_NorthCapturing : ROOBJMSG_SouthCapturing, , , self);
            }

            ROGIT.BroadcastShowObjectiveCapturedWorldWidget(true, 1 - Team);
            bCapping = true;
            CapTeamIndex = Team;

            if (ROGIT.DefendingTeam != DT_None && Team != ROGIT.DefendingTeam)
            {
                ROGIT.UpdateLastAttemptTime();
            }
        }

        ROGIT.HandleObjectiveBattleChatter(AllCappers, Team);
        CapProgress += class'ROGameInfoTerritories'.const.CAPTURE_UPDATE_RATE * CapRatio;
    }

    if (ROGIT.DefendingTeam != DT_None)
    {
        if (!ROGIT.bLockdownEnabled && ROGIT.bLastObjective)
        {
            if (ObjState != EObjectiveState(Team))
            {
                ROGIT.bAttackersCapping = true;
            }
        }
        else if (Team != ROGIT.DefendingTeam && ObjState == EObjectiveState(ROGIT.DefendingTeam))
        {
            ROGIT.bAttackersCapping = true;
        }
    }
}

// The capture is complete: it belongs to the team that took it
function Captured()
{
    local int I;

    bCapping = false;
    ObjState = EObjectiveState(CapTeamIndex);
    CapProgress = 0.0;

    BroadcastCaptured();

    // The cappers get the points for it (the game gives them to players inside its volume, which this one does not have)
    for (I = 0; I < AllCappers.Length; I++)
    {
        if (AllCappers[I].PlayerReplicationInfo != none && AllCappers[I].GetTeamNum() == CapTeamIndex)
        {
            ROGIT.AddDelayedKillMessage(ROKMT_ObjectiveCaptured, ROGIT.GameReplicationInfo.ElapsedTime, AllCappers[I].PlayerReplicationInfo);
        }
    }

    ROGIT.ObjectiveCaptured(ObjIndex);
}

// "Objective X has been captured", unless that was the last one and the game says so itself
function BroadcastCaptured()
{
    local int J;
    local bool bAllCapped;

    bAllCapped = ObjState != ROGIT.DefendingTeam;
    if (bAllCapped)
    {
        for (J = 0; J < ROGIT.Objectives.Length; J++)
        {
            if (ROGIT.Objectives[J] != none && ROGIT.Objectives[J].ObjState != ObjState)
            {
                bAllCapped = false;
                break;
            }
        }
    }

    if (!bAllCapped && (ROGIT.EnabledObjectives - ROGIT.TeamObjectiveCount(`ALLIES_TEAM_INDEX) > 1
        || ROGIT.EnabledObjectives - ROGIT.TeamObjectiveCount(`AXIS_TEAM_INDEX) > 1))
    {
        ROGIT.BroadcastLocalizedMessage(class'ROLocalMessageObjective', ROOBJMSG_Captured + CapTeamIndex, , , self);
    }
}

// ====================================================
// The shape
// ====================================================

static function float V2Dist(Vector2D A, Vector2D B)
{
    return Sqrt((A.X - B.X) * (A.X - B.X) + (A.Y - B.Y) * (A.Y - B.Y));
}

// Which side of the line P to Q the point R is on (positive: left)
static function float Side(Vector2D P, Vector2D Q, Vector2D R)
{
    return (Q.X - P.X) * (R.Y - P.Y) - (Q.Y - P.Y) * (R.X - P.X);
}

// Whether the point is inside the shape: a line from it going east crosses the edges an odd number of times. Plain decimal
// sums throughout (whole-number sums run out of room on a big map).
static function bool PolygonContains(array<Vector2D> Polygon, Vector2D P)
{
    local bool bInside;
    local int I, J;

    if (Polygon.Length < MIN_CORNER_COUNT)
    {
        return false;
    }

    J = Polygon.Length - 1;
    for (I = 0; I < Polygon.Length; I++)
    {
        if ((Polygon[I].Y > P.Y) != (Polygon[J].Y > P.Y)
            && P.X < (Polygon[J].X - Polygon[I].X) * (P.Y - Polygon[I].Y) / (Polygon[J].Y - Polygon[I].Y) + Polygon[I].X)
        {
            bInside = !bInside;
        }
        J = I;
    }
    return bInside;
}

// True when no two edges cross each other
static function bool IsSimple(array<Vector2D> Polygon)
{
    local int I, J, N;
    local float D1, D2, D3, D4;

    N = Polygon.Length;
    for (I = 0; I < N; I++)
    {
        for (J = I + 2; J < N; J++)
        {
            // The first and last edges meet at the first corner
            if (I == 0 && J == N - 1)
            {
                continue;
            }

            D1 = Side(Polygon[I], Polygon[(I + 1) % N], Polygon[J]);
            D2 = Side(Polygon[I], Polygon[(I + 1) % N], Polygon[(J + 1) % N]);
            D3 = Side(Polygon[J], Polygon[(J + 1) % N], Polygon[I]);
            D4 = Side(Polygon[J], Polygon[(J + 1) % N], Polygon[(I + 1) % N]);
            if (((D1 > 0 && D2 < 0) || (D1 < 0 && D2 > 0)) && ((D3 > 0 && D4 < 0) || (D3 < 0 && D4 > 0)))
            {
                return false;
            }
        }
    }
    return true;
}

// Puts the corners in order round their average, which turns a crossed shape into the outline it was meant to be
static function SortAroundMiddle(out array<Vector2D> Polygon)
{
    local array<float> Angles;
    local Vector2D Average, Tmp;
    local float TmpAngle;
    local int I, J;

    for (I = 0; I < Polygon.Length; I++)
    {
        Average.X += Polygon[I].X / Polygon.Length;
        Average.Y += Polygon[I].Y / Polygon.Length;
    }
    for (I = 0; I < Polygon.Length; I++)
    {
        Angles.AddItem(Atan2(Polygon[I].Y - Average.Y, Polygon[I].X - Average.X));
    }

    for (I = 1; I < Polygon.Length; I++)
    {
        for (J = I; J > 0 && Angles[J - 1] > Angles[J]; J--)
        {
            Tmp = Polygon[J];
            Polygon[J] = Polygon[J - 1];
            Polygon[J - 1] = Tmp;
            TmpAngle = Angles[J];
            Angles[J] = Angles[J - 1];
            Angles[J - 1] = TmpAngle;
        }
    }
}

// The middle of the shape; for a shape that curls round it (so the middle is outside it) the middle of the widest stretch of
// it at that height
static function Vector2D InsidePoint(array<Vector2D> Polygon)
{
    local array<float> Crossings;
    local Vector2D Origin, Middle, A, B;
    local float Area, Cross, Widest, Tmp;
    local int I, J, N;

    N = Polygon.Length;
    Origin = Polygon[0];

    // The area centre, measured from the first corner so the sums stay small
    for (I = 0; I < N; I++)
    {
        A.X = Polygon[I].X - Origin.X;
        A.Y = Polygon[I].Y - Origin.Y;
        B.X = Polygon[(I + 1) % N].X - Origin.X;
        B.Y = Polygon[(I + 1) % N].Y - Origin.Y;
        Cross = A.X * B.Y - B.X * A.Y;
        Area += Cross;
        Middle.X += (A.X + B.X) * Cross;
        Middle.Y += (A.Y + B.Y) * Cross;
    }
    if (Abs(Area) < 1.0)
    {
        for (I = 0; I < N; I++)
        {
            Middle.X += Polygon[I].X / N;
            Middle.Y += Polygon[I].Y / N;
        }
        return Middle;
    }
    Middle.X = Origin.X + Middle.X / (3.0 * Area);
    Middle.Y = Origin.Y + Middle.Y / (3.0 * Area);
    if (PolygonContains(Polygon, Middle))
    {
        return Middle;
    }

    // Where the line across the middle enters and leaves the shape
    J = N - 1;
    for (I = 0; I < N; I++)
    {
        if ((Polygon[I].Y > Middle.Y) != (Polygon[J].Y > Middle.Y))
        {
            Crossings.AddItem((Polygon[J].X - Polygon[I].X) * (Middle.Y - Polygon[I].Y) / (Polygon[J].Y - Polygon[I].Y) + Polygon[I].X);
        }
        J = I;
    }
    for (I = 1; I < Crossings.Length; I++)
    {
        for (J = I; J > 0 && Crossings[J - 1] > Crossings[J]; J--)
        {
            Tmp = Crossings[J];
            Crossings[J] = Crossings[J - 1];
            Crossings[J - 1] = Tmp;
        }
    }
    for (I = 0; I + 1 < Crossings.Length; I += 2)
    {
        if (Crossings[I + 1] - Crossings[I] > Widest)
        {
            Widest = Crossings[I + 1] - Crossings[I];
            Middle.X = (Crossings[I] + Crossings[I + 1]) * 0.5;
        }
    }
    return Middle;
}

function string IntToString(int Value)
{
    switch (Value)
    {
        case 0: return "A";
        case 1: return "B";
        case 2: return "C";
        case 3: return "D";
        case 4: return "E";
        case 5: return "F";
        case 6: return "G";
        case 7: return "H";
        case 8: return "I";
        case 9: return "J";
        case 10: return "K";
        case 11: return "L";
        case 12: return "M";
        case 13: return "N";
        case 14: return "O";
        case 15: return "P";
    }

    return "?";
}

defaultproperties
{
    MinimumCaptureTime=30
    InitialObjState=2
    ObjState=2
    ObjVolume=none
    bStatic=false
    bNoDelete=false
    bAlwaysRelevant=true
    bReplicateMovement=false
    RemoteRole=ROLE_SimulatedProxy

    // Until the real numbers arrive, a client must not mistake it for another objective
    ObjRepIndex=255
}

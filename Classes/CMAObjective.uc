class CMAObjective extends ROObjective;

const INF = 100000;
var array<Vector2D> Corners;
var ROGameInfoTerritories ROGIT;
var ROGameReplicationInfo ROGRI;

var repnotify byte ReplicatedObjIndex;
var repnotify byte ReplicatedObjRepIndex;
var repnotify string ReplicatedObjName;
var repnotify string ReplicatedObjShortName;
var repnotify byte ReplicatedInitialObjState;
var repnotify bool ReplicatedEnabled;
var repnotify bool ReplicatedActive;
var repnotify byte ReplicatedCornerCount;
var Vector2D ReplicatedCorners[32];
var repnotify bool bObjectiveReady;

function string GetDisplayName()
{
    return ReplicatedObjName;
}

replication
{
    if (Role == ROLE_Authority)
        ReplicatedObjIndex, ReplicatedObjRepIndex, ReplicatedObjName, ReplicatedObjShortName,
        ReplicatedInitialObjState, ReplicatedEnabled, ReplicatedActive,
        ReplicatedCornerCount, ReplicatedCorners, bObjectiveReady;
}

function Init(array<Vector2D> InCorners)
{
    local Vector2D Cornerp;
    local int ObjSlot;

    Corners = InCorners;
    ROGIT = ROGameInfoTerritories(WorldInfo.Game);
    ROGRI = ROGameReplicationInfo(WorldInfo.GRI);

    if (ROGIT == none || ROGRI == none || Corners.Length < 3)
    {
        return;
    }

    for (ObjSlot = 0; ObjSlot < `MAX_OBJECTIVES; ObjSlot++)
    {
        if (ObjSlot >= ROGIT.Objectives.Length || ROGIT.Objectives[ObjSlot] == none)
        {
            break;
        }
    }

    if (ObjSlot >= `MAX_OBJECTIVES)
    {
        `warn("CMAObjective: no free objective slot");
        return;
    }

    ObjIndex = ObjSlot;
    ObjRepIndex = ObjSlot;
    ObjShortName = IntToString(ObjSlot);
    ReplicatedObjName = "Custom Objective " $ ObjShortName;
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
    ROGRI.ObjectiveNames[ObjIndex] = ReplicatedObjName;

    ReplicatedObjIndex = ObjIndex;
    ReplicatedObjRepIndex = ObjRepIndex;
    ReplicatedObjShortName = ObjShortName;
    ReplicatedInitialObjState = InitialObjState;
    ReplicatedEnabled = bEnabled;
    ReplicatedActive = bActive;
    ReplicatedCornerCount = Min(Corners.Length, 32);
    for (ObjSlot = 0; ObjSlot < ReplicatedCornerCount; ObjSlot++)
    {
        ReplicatedCorners[ObjSlot] = Corners[ObjSlot];
    }
    bObjectiveReady = true;
    bNetDirty = true;

    foreach InCorners(Cornerp)
    {
        `log(self $ ": corner " $ Cornerp.X @ Cornerp.Y);
    }
}

simulated event ReplicatedEvent(name VarName)
{
    local ROPlayerController ROPC;
    local int I;

    if (VarName == 'bObjectiveReady' && bObjectiveReady)
    {
        ObjIndex = ReplicatedObjIndex;
        ObjRepIndex = ReplicatedObjRepIndex;
        ObjShortName = ReplicatedObjShortName;
        InitialObjState = EObjectiveState(ReplicatedInitialObjState);
        AppliedInitialObjState = InitialObjState;
        bEnabled = ReplicatedEnabled;
        bActive = ReplicatedActive;
        Corners.Remove(0, Corners.Length);
        for (I = 0; I < ReplicatedCornerCount; I++)
        {
            Corners.AddItem(ReplicatedCorners[I]);
        }

        ROGRI = ROGameReplicationInfo(WorldInfo.GRI);
        if (ROGRI != none)
        {
            ROGRI.AddObjective(self, true);
            ROGRI.ObjectiveNames[ObjIndex] = ReplicatedObjName;
            foreach LocalPlayerControllers(class'ROPlayerController', ROPC)
            {
                ROPC.ObjectivesUpdated();
                ROPC.ObjectiveStatusChanged(ROGRI);
            }
        }
    }
    else
    {
        super.ReplicatedEvent(VarName);
    }
}

function bool CheckForPlayers(vector PlayerLoc)
{
    local Vector2D P;

    P.X = PlayerLoc.X;
    P.Y = PlayerLoc.Y;
    return IsInside(Corners, Corners.Length, P);
}

function bool OnSegment(Vector2D P, Vector2D Q, Vector2D R)
{
    return Q.X <= Max(P.X, R.X) && Q.X >= Min(P.X, R.X)
        && Q.Y <= Max(P.Y, R.Y) && Q.Y >= Min(P.Y, R.Y);
}

function int Orientation(Vector2D P, Vector2D Q, Vector2D R)
{
    local int Value;

    Value = (Q.Y - P.Y) * (R.X - Q.X) - (Q.X - P.X) * (R.Y - Q.Y);
    if (Value == 0)
    {
        return 0;
    }

    return Value > 0 ? 1 : 2;
}

function bool DoIntersect(Vector2D P1, Vector2D Q1, Vector2D P2, Vector2D Q2)
{
    local int O1, O2, O3, O4;

    O1 = Orientation(P1, Q1, P2);
    O2 = Orientation(P1, Q1, Q2);
    O3 = Orientation(P2, Q2, P1);
    O4 = Orientation(P2, Q2, Q1);

    if (O1 != O2 && O3 != O4)
    {
        return true;
    }

    if (O1 == 0 && OnSegment(P1, P2, Q1)) return true;
    if (O2 == 0 && OnSegment(P1, Q2, Q1)) return true;
    if (O3 == 0 && OnSegment(P2, P1, Q2)) return true;
    if (O4 == 0 && OnSegment(P2, Q1, Q2)) return true;
    return false;
}

function bool IsInside(array<Vector2D> Polygon, int Count, Vector2D P)
{
    local Vector2D Extreme;
    local int DuplicateCount, Intersections, I, Next;

    if (Count < 3)
    {
        return false;
    }

    Extreme.X = INF;
    Extreme.Y = P.Y;
    DuplicateCount = 0;
    Intersections = 0;
    I = 0;

    while (true)
    {
        Next = (I + 1) % Count;
        if (Polygon[I].Y == P.Y)
        {
            DuplicateCount++;
        }

        if (DoIntersect(Polygon[I], Polygon[Next], P, Extreme))
        {
            if (Orientation(Polygon[I], P, Polygon[Next]) == 0)
            {
                return OnSegment(Polygon[I], P, Polygon[Next]);
            }
            Intersections++;
        }

        I = Next;
        if (I == 0)
        {
            break;
        }
    }

    return ((Intersections - DuplicateCount) % 2) == 1;
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
}

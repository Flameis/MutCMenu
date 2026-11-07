// A place a game mode uses, marked with a flagpole that everyone sees, and its name drawn above it
// (CMModeInteraction): a bomb site (A, B), where the bomb starts, or the convoy's destination. Placed by admins
// (mutate modepoint --kind ...). Each kind is kept once (site A, site B, the start and the destination): placing it again
// moves it.
class CMAModePoint extends CMAStaticMesh;

const KIND_SITE_A = 0;
const KIND_SITE_B = 1;
const KIND_BOMB_START = 2;
const KIND_CONVOY_END = 3;
const NUM_KINDS = 4;

const SITE_RADIUS = 300.0;      // 6 m round a bomb site's pole: inside it the bomb can be planted
const CONVOY_RADIUS = 500.0;    // 10 m round the convoy's destination: the vehicle has arrived

var repnotify byte PointKind;
var repnotify string PointLabel;

replication
{
    if (bNetDirty && Role == ROLE_Authority)
        PointKind, PointLabel;
}

static function string KindLabel(int Kind)
{
    switch (Kind)
    {
        case KIND_SITE_A:     return "Bomb site A";
        case KIND_SITE_B:     return "Bomb site B";
        case KIND_BOMB_START: return "Bomb start";
        case KIND_CONVOY_END: return "Convoy destination";
    }
    return "";
}

// The kind a word names (sitea, a, siteb, b, bombstart, start, convoy, destination), or -1
static function int ParseKind(string S)
{
    S = Caps(S);
    if (S == "SITEA" || S == "A" || S == "SITE_A")
        return KIND_SITE_A;
    if (S == "SITEB" || S == "B" || S == "SITE_B")
        return KIND_SITE_B;
    if (S == "BOMBSTART" || S == "START" || S == "BOMB")
        return KIND_BOMB_START;
    if (S == "CONVOY" || S == "DESTINATION" || S == "CONVOYEND" || S == "END")
        return KIND_CONVOY_END;
    return -1;
}

function bool IsSite()
{
    return PointKind == KIND_SITE_A || PointKind == KIND_SITE_B;
}

// Within Radius of the pole, seen from above, and not far above or below it
function bool Contains(vector Loc, float Radius)
{
    local vector D;

    D = Loc - Location;
    if (Abs(D.Z) > 400)
        return false;
    D.Z = 0;
    return VSize(D) <= Radius;
}

defaultproperties
{
    Health=0
    BuiltByTeam=255
}

// Convoy: one team (ConvoyTeam) escorts a vehicle to its destination (a pole placed by an admin, mutate modepoint --kind
// convoy); the other team ambushes it. The vehicle within 10 m of the destination: the escort wins the round. Destroyed,
// or ConvoyMinutes run out: the other team wins. An admin picks the vehicle (mutate convoyvehicle, the vehicle nearest
// to them); each new round a fresh one of the same kind stands where it was when picked.
class CMModeConvoy extends CMGameMode;

var byte EscortTeam;
var ROVehicle Convoy;
var class<ROVehicle> ConvoyClass;    // what is put back each round, and where
var vector ConvoyStart;
var rotator ConvoyStartRot;

function int RoundMinutes()
{
    return Mut.ConvoyMinutes > 0 ? Mut.ConvoyMinutes : 15;
}

function ModeStarted()
{
    EscortTeam = Clamp(Mut.ConvoyTeam, 0, 1);
    Announce(TeamName(EscortTeam) $ " escort the vehicle to its destination. " $ TeamName(1 - EscortTeam) $ " stop it.");
}

function NewRound()
{
    EscortTeam = Clamp(Mut.ConvoyTeam, 0, 1);
    SetTimer(1.0, false, 'RespawnConvoy');
}

// The vehicle nearest to Where (within 30 m) becomes the convoy; true when there was one
function bool PickVehicle(vector Where, PlayerController PC)
{
    local ROVehicle V, Best;
    local float D, BestD;

    BestD = 1500.0;
    foreach DynamicActors(class'ROVehicle', V)
    {
        if (V.bDeleteMe || V.Health <= 0)
            continue;
        D = VSize(V.Location - Where);
        if (D < BestD)
        {
            Best = V;
            BestD = D;
        }
    }
    if (Best == None)
        return false;
    Convoy = Best;
    ConvoyClass = Best.Class;
    ConvoyStart = Best.Location + vect(0, 0, 30);
    ConvoyStartRot = Best.Rotation;
    ConvoyStartRot.Pitch = 0;
    ConvoyStartRot.Roll = 0;
    return true;
}

// A new round: a fresh vehicle where the convoy started
function RespawnConvoy()
{
    local ROVehicle V;

    if (ConvoyClass == None)
        return;
    if (Convoy != None && !Convoy.bDeleteMe)
    {
        if (Convoy.Driver != None || Convoy.NumPassengers() > 0)
            Convoy.DriverLeave(true);
        Convoy.Destroy();
    }
    V = Spawn(ConvoyClass,, 'CMBuilderVehicle', ConvoyStart + vect(0, 0, 100), ConvoyStartRot,, true);
    if (V == None)
    {
        Announce("The convoy vehicle couldn't be put back at its start");
        return;
    }
    V.bTeamLocked = false;
    V.Mesh.AddImpulse(vect(0, 0, 1), V.Location);
    Convoy = V;
}

function CMAModePoint Destination()
{
    local CMAModePoint P;

    foreach DynamicActors(class'CMAModePoint', P)
    {
        if (!P.bDeleteMe && P.PointKind == class'CMAModePoint'.const.KIND_CONVOY_END)
            return P;
    }
    return None;
}

function TickMode(float DeltaTime)
{
    local CMAModePoint Dest;

    if (bRoundDecided || ConvoyClass == None)
        return;
    Dest = Destination();
    if (Dest == None)
        return;
    if (Convoy == None || Convoy.bDeleteMe || Convoy.Health <= 0 || Convoy.bDeadVehicle)
    {
        WinRound(1 - EscortTeam, "The convoy was destroyed: " $ TeamName(1 - EscortTeam) $ " win the round");
        return;
    }
    if (Dest.Contains(Convoy.Location, class'CMAModePoint'.const.CONVOY_RADIUS))
    {
        WinRound(EscortTeam, "The convoy reached its destination: " $ TeamName(EscortTeam) $ " win the round");
        return;
    }
    if (WorldInfo.TimeSeconds - RoundStartedAt >= RoundMinutes() * 60)
        WinRound(1 - EscortTeam, "Time is up: the convoy didn't make it. " $ TeamName(1 - EscortTeam) $ " win the round");
}

function UpdateStatus()
{
    local CMAModePoint Dest;

    Dest = Destination();
    if (ConvoyClass == None)
        StatusText = "Waiting for an admin to pick the convoy vehicle (mutate convoyvehicle)";
    else if (Dest == None)
        StatusText = "Waiting for the convoy's destination (mutate modepoint --kind convoy)";
    else if (Convoy != None && !Convoy.bDeleteMe)
        StatusText = TeamName(EscortTeam) $ " escort   " $ int(VSize((Convoy.Location - Dest.Location) * vect(1, 1, 0)) / 50.0) $ " m to go   "
            $ "vehicle " $ int(100.0 * Convoy.Health / Max(Convoy.HealthMax, 1)) $ "%   "
            $ ClockText(RoundMinutes() * 60 - (WorldInfo.TimeSeconds - RoundStartedAt)) $ " left";
}

function string PlayerLine(PlayerController PC)
{
    if (ConvoyClass == None || PC.PlayerReplicationInfo == None)
        return "";
    return (TeamOf(PC) == EscortTeam) ? "Get the vehicle to the destination" : "Stop the convoy";
}

defaultproperties
{
    ModeTitle="CONVOY"
}

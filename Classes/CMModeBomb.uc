// Bomb plant and defuse: the attackers (BombAttackers) carry the bomb, a satchel worn on the back, to a bomb site (a pole
// placed by an admin, mutate modepoint --kind sitea / siteb) and hold the bomb key (F) inside it for BombPlantSeconds to
// plant it. Then the defenders have BombFuseSeconds to hold the key beside it for BombDefuseSeconds and defuse it. Goes
// off: the attackers win the round. Defused, or the round's BombRoundMinutes run out before a plant: the defenders win.
// The bomb starts at the bomb start pole if there is one, otherwise on an attacker's back.
class CMModeBomb extends CMGameMode;

var byte AttackingTeam;
var CMABomb Bomb;
var PlayerController Planter, Defuser;   // who is holding the key at the bomb now
var float PlantProgress, DefuseProgress; // seconds held so far
var float DroppedSince;                  // when the bomb was last dropped (it goes back to the start after a while)

const DEFUSE_RADIUS = 150.0;            // 3 m from the planted bomb
const DROPPED_RETURN = 30.0;            // seconds a dropped bomb lies before it goes back to the start
const BLAST_DAMAGE = 1500;
const BLAST_RADIUS = 1500.0;            // 30 m

replication
{
    if (bNetDirty)
        AttackingTeam;
}

function int PlantSeconds()    { return Mut.BombPlantSeconds > 0 ? Mut.BombPlantSeconds : 5; }
function int DefuseSeconds()   { return Mut.BombDefuseSeconds > 0 ? Mut.BombDefuseSeconds : 7; }
function int FuseSeconds()     { return Mut.BombFuseSeconds > 0 ? Mut.BombFuseSeconds : 40; }
function int RoundMinutes()    { return Mut.BombRoundMinutes > 0 ? Mut.BombRoundMinutes : 10; }

function ModeStarted()
{
    AttackingTeam = Clamp(Mut.BombAttackers, 0, 1);
    SpawnBomb();
    Announce(TeamName(AttackingTeam) $ " attack: plant the bomb at a site (hold F inside it). " $ TeamName(1 - AttackingTeam)
        $ " defend: stop them, or defuse it (hold F beside it).");
}

function ModeStopped()
{
    if (Bomb != None)
        Bomb.Destroy();
}

function NewRound()
{
    AttackingTeam = Clamp(Mut.BombAttackers, 0, 1);
    PlantProgress = 0;
    DefuseProgress = 0;
    if (Bomb != None)
        Bomb.Destroy();
    SpawnBomb();
}

function CMAModePoint FindPoint(int Kind)
{
    local CMAModePoint P;

    foreach DynamicActors(class'CMAModePoint', P)
    {
        if (!P.bDeleteMe && P.PointKind == Kind)
            return P;
    }
    return None;
}

function vector BombStart()
{
    local CMAModePoint P;
    local Pawn A;

    P = FindPoint(class'CMAModePoint'.const.KIND_BOMB_START);
    if (P != None)
        return P.Location + vect(0, 0, 40);
    foreach WorldInfo.AllPawns(class'Pawn', A)
    {
        if (ROPawn(A) != None && A.Health > 0 && PawnTeam(A) == AttackingTeam)
            return A.Location;
    }
    return vect(0, 0, 0);
}

function SpawnBomb()
{
    local vector Start;

    Start = BombStart();
    if (Start == vect(0, 0, 0))
        return;     // no attacker yet: tried again every tick
    Bomb = Spawn(class'CMABomb',,, Start,,, true);
    if (Bomb == None)
        return;
    Bomb.Mode = self;
    Bomb.MyMut = Mut;
    Bomb.SetPhysics(PHYS_Falling);
}

// Only the attackers carry it
function bool FlagTouched(CMAFlag F, Pawn P)
{
    if (CMABomb(F) == None)
        return true;
    return PawnTeam(P) == AttackingTeam && !bRoundDecided;
}

function BombKey(PlayerController PC, bool bDown)
{
    if (!bDown)
    {
        if (PC == Planter)
        {
            Planter = None;
            PlantProgress = 0;
        }
        if (PC == Defuser)
        {
            Defuser = None;
            DefuseProgress = 0;
        }
    }
}

// The site Loc is in, or None
function CMAModePoint SiteAt(vector Loc)
{
    local CMAModePoint P;

    foreach DynamicActors(class'CMAModePoint', P)
    {
        if (!P.bDeleteMe && P.IsSite() && P.Contains(Loc, class'CMAModePoint'.const.SITE_RADIUS))
            return P;
    }
    return None;
}

function bool KeyHeld(PlayerController PC)
{
    local DummyActor DA;

    DA = Mut.FindDummyActor(PC);
    return DA != None && DA.bBombKeyDown;
}

function TickMode(float DeltaTime)
{
    local PlayerController PC;
    local CMAModePoint Site;

    if (bRoundDecided)
        return;
    if (Bomb == None || Bomb.bDeleteMe)
    {
        SpawnBomb();
        return;
    }

    if (!Bomb.bPlanted)
    {
        // Out of time before a plant
        if (WorldInfo.TimeSeconds - RoundStartedAt >= RoundMinutes() * 60)
        {
            WinRound(1 - AttackingTeam, "Time is up and the bomb wasn't planted: " $ TeamName(1 - AttackingTeam) $ " win the round");
            return;
        }

        // A dropped bomb lying too long goes back to the start
        if (Bomb.Carrier == None && !Bomb.bAtHome)
        {
            if (DroppedSince == 0)
                DroppedSince = WorldInfo.TimeSeconds;
            else if (WorldInfo.TimeSeconds - DroppedSince > DROPPED_RETURN)
            {
                Bomb.HomeLocation = BombStart();
                Bomb.ReturnHome();
                Announce("The bomb went back to the start");
                DroppedSince = 0;
            }
        }
        else
            DroppedSince = 0;

        // Planting: the carrier holds the key inside a site
        PC = (Bomb.Carrier != None) ? PlayerController(Bomb.Carrier.Controller) : None;
        Site = (PC != None) ? SiteAt(Bomb.Carrier.Location) : None;
        if (PC != None && Site != None && KeyHeld(PC))
        {
            Planter = PC;
            PlantProgress += DeltaTime;
            if (PlantProgress >= PlantSeconds())
            {
                Bomb.Plant(Bomb.Carrier.Location, Site.PointKind);
                Announce(PC.PlayerReplicationInfo.PlayerName $ " planted the bomb at " $ Site.PointLabel $ "! It goes off in "
                    $ FuseSeconds() $ " seconds");
                PlantProgress = 0;
                Planter = None;
            }
        }
        else
        {
            Planter = None;
            PlantProgress = 0;
        }
        return;
    }

    // Planted: defusing, or it goes off
    if (WorldInfo.TimeSeconds - Bomb.PlantedAt >= FuseSeconds())
    {
        Explode();
        return;
    }
    if (Defuser == None || Defuser.Pawn == None || Defuser.Pawn.Health <= 0 || !KeyHeld(Defuser)
        || VSize(Defuser.Pawn.Location - Bomb.Location) > DEFUSE_RADIUS || TeamOf(Defuser) == AttackingTeam)
    {
        Defuser = None;
        DefuseProgress = 0;
        foreach WorldInfo.AllControllers(class'PlayerController', PC)
        {
            if (PC.Pawn != None && PC.Pawn.Health > 0 && TeamOf(PC) == 1 - AttackingTeam && KeyHeld(PC)
                && VSize(PC.Pawn.Location - Bomb.Location) <= DEFUSE_RADIUS)
            {
                Defuser = PC;
                break;
            }
        }
    }
    if (Defuser != None)
    {
        DefuseProgress += DeltaTime;
        if (DefuseProgress >= DefuseSeconds())
        {
            Bomb.bPlanted = false;
            WinRound(1 - AttackingTeam, Defuser.PlayerReplicationInfo.PlayerName $ " defused the bomb: " $ TeamName(1 - AttackingTeam)
                $ " win the round");
            Bomb.Destroy();
        }
    }
}

function Explode()
{
    local ROSatchelChargeProjectile Blast;
    local vector Where;

    Where = Bomb.Location;
    Bomb.Destroy();
    Blast = Spawn(class'ROSatchelChargeProjectile',,, Where + vect(0, 0, 20),,, true);
    if (Blast != None)
    {
        Blast.Damage = BLAST_DAMAGE;
        Blast.DamageRadius = BLAST_RADIUS;
        Blast.Explode(Where, vect(0, 0, 1));
    }
    else
        HurtRadius(BLAST_DAMAGE, BLAST_RADIUS, class'RODmgType_Satchel', 100000, Where);
    WinRound(AttackingTeam, "The bomb went off: " $ TeamName(AttackingTeam) $ " win the round");
}

function UpdateStatus()
{
    local int Sites;
    local CMAModePoint P;

    foreach DynamicActors(class'CMAModePoint', P)
    {
        if (P.IsSite())
            Sites++;
    }
    if (Sites == 0)
        StatusText = "Waiting for a bomb site (mutate modepoint --kind sitea)";
    else if (Bomb != None && Bomb.bPlanted)
        StatusText = "Bomb planted: " $ ClockText(FuseSeconds() - (WorldInfo.TimeSeconds - Bomb.PlantedAt));
    else
        StatusText = TeamName(AttackingTeam) $ " attack   " $ ClockText(RoundMinutes() * 60 - (WorldInfo.TimeSeconds - RoundStartedAt)) $ " left";
}

function string PlayerLine(PlayerController PC)
{
    local byte Team;

    if (Bomb == None || PC.Pawn == None)
        return "";
    Team = TeamOf(PC);
    if (PC == Planter)
        return "Planting... " $ Max(0, int(PlantSeconds() - PlantProgress + 0.99)) $ " s";
    if (PC == Defuser)
        return "Defusing... " $ Max(0, int(DefuseSeconds() - DefuseProgress + 0.99)) $ " s";
    if (Bomb.Carrier == PC.Pawn)
        return SiteAt(PC.Pawn.Location) != None ? "Hold [F] to plant the bomb" : "Take the bomb to a bomb site";
    if (Bomb.bPlanted && Team == 1 - AttackingTeam)
        return VSize(PC.Pawn.Location - Bomb.Location) <= DEFUSE_RADIUS ? "Hold [F] to defuse" : "Find the bomb and defuse it";
    if (Team == AttackingTeam && Bomb.Carrier == None && !Bomb.bPlanted)
        return "Pick up the bomb";
    return "";
}

defaultproperties
{
    ModeTitle="BOMB"
}

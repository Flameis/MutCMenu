// Paintball: every weapon does only PaintballDamagePercent of its damage (10% by default), so it takes many hits to put
// someone down, and every hit on an enemy soldier is counted: each player sees their hits and how often they were hit,
// and the best shots are named at the end of each round. Everything else (respawns, tickets, objectives) is the map's own.
class CMModePaintball extends CMGameMode;

struct PaintballTally
{
    var PlayerReplicationInfo PRI;
    var int Hits, Taken;
};
var array<PaintballTally> Tallies;

function int DamagePercent()
{
    return (Mut.PaintballDamagePercent > 0) ? Clamp(Mut.PaintballDamagePercent, 1, 100) : 10;
}

function ModeStarted()
{
    Announce("Weapons do " $ DamagePercent() $ "% of their damage. Every hit counts.");
}

function ModeStopped()
{
    AnnounceBest();
}

function NewRound()
{
    AnnounceBest();
    Tallies.Length = 0;
}

function int TallyFor(PlayerReplicationInfo PRI)
{
    local int i;
    local PaintballTally T;

    for (i = 0; i < Tallies.Length; i++)
    {
        if (Tallies[i].PRI == PRI)
            return i;
    }
    T.PRI = PRI;
    Tallies.AddItem(T);
    return Tallies.Length - 1;
}

function NetDamage(int OriginalDamage, out int Damage, Pawn Injured, Controller InstigatedBy, vector HitLocation,
    out vector Momentum, class<DamageType> DamageType, Actor DamageCauser)
{
    if (Damage <= 0 || Injured == None || Vehicle(Injured) != None)
        return;
    Damage = Max(1, Round(Damage * DamagePercent() / 100.0));

    // A hit on an enemy soldier by a player
    if (InstigatedBy != None && InstigatedBy.PlayerReplicationInfo != None && Injured.PlayerReplicationInfo != None
        && InstigatedBy != Injured.Controller && TeamOf(InstigatedBy) != PawnTeam(Injured) && TeamOf(InstigatedBy) < 2)
    {
        Tallies[TallyFor(InstigatedBy.PlayerReplicationInfo)].Hits++;
        Tallies[TallyFor(Injured.PlayerReplicationInfo)].Taken++;
    }
}

// The three with the most hits
function string BestList()
{
    local array<PaintballTally> Sorted;
    local PaintballTally T;
    local string S;
    local int i, j;

    foreach Tallies(T)
    {
        if (T.PRI == None || T.Hits == 0)
            continue;
        j = 0;
        while (j < Sorted.Length && Sorted[j].Hits >= T.Hits)
            j++;
        Sorted.InsertItem(j, T);
    }
    for (i = 0; i < Sorted.Length && i < 3; i++)
        S $= (i > 0 ? ", " : "") $ Sorted[i].PRI.PlayerName $ " (" $ Sorted[i].Hits $ ")";
    return S;
}

function AnnounceBest()
{
    local string S;

    S = BestList();
    if (S != "")
        Announce("Most hits this round: " $ S);
}

function UpdateStatus()
{
    local string S;

    S = BestList();
    StatusText = "Damage " $ DamagePercent() $ "%" $ (S != "" ? "   Most hits: " $ S : "");
}

function string PlayerLine(PlayerController PC)
{
    local int i;

    if (PC.PlayerReplicationInfo == None)
        return "";
    for (i = 0; i < Tallies.Length; i++)
    {
        if (Tallies[i].PRI == PC.PlayerReplicationInfo)
            return "Your hits: " $ Tallies[i].Hits $ "   Hit: " $ Tallies[i].Taken;
    }
    return "Your hits: 0   Hit: 0";
}

defaultproperties
{
    ModeTitle="PAINTBALL"
}

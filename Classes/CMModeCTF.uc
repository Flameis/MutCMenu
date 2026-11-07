// Capture the Flag match: each team has a flag (placed with the Builder's CTF Flag entries or mutate spawnflag --team).
// Carry the enemy flag to your own flag, while yours is at home, to score; touching your own flag when it has been moved
// sends it home. The first team to CTFCapturesToWin captures wins the round.
class CMModeCTF extends CMGameMode;

const CAPTURE_RADIUS = 200.0;   // 4 m from your own flag's home
const CAPTURE_HEIGHT = 200.0;

function int CapturesToWin()
{
    return Mut.CTFCapturesToWin > 0 ? Mut.CTFCapturesToWin : 3;
}

function ModeStarted()
{
    bShowScore = true;
    ReturnAllFlags();
    Announce("Carry the enemy flag to your own flag to score. First to "$CapturesToWin()$" captures wins the round.");
}

function NewRound()
{
    ReturnAllFlags();
}

function ReturnAllFlags()
{
    local CMAFlag F;

    foreach DynamicActors(class'CMAFlag', F)
    {
        if (CMABomb(F) == None)
            F.ReturnHome();
    }
}

// The flag placed for Team (the first one, if there are several), or None
function CMAFlag TeamFlag(int Team)
{
    local CMAFlag F;

    foreach DynamicActors(class'CMAFlag', F)
    {
        if (CMABomb(F) == None && !F.bDeleteMe && F.FlagTeam == Team)
            return F;
    }
    return None;
}

// Your own team's flag is never picked up: touching it away from home sends it back
function bool FlagTouched(CMAFlag F, Pawn P)
{
    local byte Team;

    if (CMABomb(F) != None)
        return true;
    Team = PawnTeam(P);
    if (Team > 1 || F.FlagTeam < 0)
        return false;
    if (F.FlagTeam == Team)
    {
        if (!F.bAtHome && F.Carrier == None)
        {
            F.ReturnHome();
            Announce(P.PlayerReplicationInfo.PlayerName $ " returned the " $ TeamName(Team) $ " flag");
        }
        return false;
    }
    return true;
}

function TickMode(float DeltaTime)
{
    local int Team;
    local CMAFlag Own, Enemy;
    local vector D;

    if (bRoundDecided)
        return;
    for (Team = 0; Team < 2; Team++)
    {
        Own = TeamFlag(Team);
        Enemy = TeamFlag(1 - Team);
        if (Own == None || Enemy == None || Enemy.Carrier == None || !Own.bAtHome || PawnTeam(Enemy.Carrier) != Team)
            continue;
        D = Enemy.Carrier.Location - Own.HomeLocation;
        if (Abs(D.Z) > CAPTURE_HEIGHT)
            continue;
        D.Z = 0;
        if (VSize(D) > CAPTURE_RADIUS)
            continue;

        TeamScore[Team]++;
        Announce(Enemy.Carrier.PlayerReplicationInfo.PlayerName $ " captured the " $ TeamName(1 - Team) $ " flag! "
            $ TeamName(0) $ " " $ TeamScore[0] $ " - " $ TeamScore[1] $ " " $ TeamName(1));
        Enemy.ReturnHome();
        if (TeamScore[Team] >= CapturesToWin())
            WinRound(Team, TeamName(Team) $ " win the round with " $ TeamScore[Team] $ " captures");
    }
}

function UpdateStatus()
{
    if (TeamFlag(0) == None || TeamFlag(1) == None)
        StatusText = "Waiting for a flag for each team (Builder: Actors, CTF Flag)";
    else
        StatusText = "First to " $ CapturesToWin() $ " captures";
}

function string PlayerLine(PlayerController PC)
{
    local CMAFlag F;
    local byte Team;

    if (PC.Pawn == None)
        return "";
    Team = TeamOf(PC);
    foreach DynamicActors(class'CMAFlag', F)
    {
        if (F.Carrier == PC.Pawn)
            return "You have the enemy flag: bring it to your own flag";
    }
    F = TeamFlag(Team);
    if (F != None && !F.bAtHome)
        return (F.Carrier != None) ? "The enemy has your flag" : "Your flag is down: touch it to send it home";
    return "";
}

defaultproperties
{
    ModeTitle="CAPTURE THE FLAG"
}

// A game mode played inside whatever game mode the map has (Capture the Flag match, bomb, convoy, gun game, paintball).
// MutCMenu runs at most one at a time (ActiveMode), started by an admin (mutate gamemode) or at map start (the
// GameModeOnStart setting). The server side gets the mutator's events (damage, deaths, spawns, round resets); every
// player sees ModeTitle, StatusText and the scores at the top of the screen (CMModeInteraction), and their own line
// (DummyActor.ModeLine). A mode wins a round for a team with WinRound.
class CMGameMode extends ReplicationInfo
    dependson(ROGameInfo)
    abstract;

var MutCMenu Mut;

var string ModeTitle;               // "CAPTURE THE FLAG"
var string StatusText;              // the mode's state, for everyone ("North 1 - 0 South, first to 3")
var int TeamScore[2];
var bool bShowScore;

var bool bRoundDecided;             // Server: a winner was declared this round (until the next round starts)
var float RoundStartedAt;           // Server: when this round started (or the mode did)
var bool bDontEndRound;             // For the test harness: a winner is decided and told, but the game's round goes on
var int LastWinner;                 // Server: the team that won the round last (255: none yet)

const TICK_INTERVAL = 0.25;

replication
{
    if (bNetDirty)
        ModeTitle, StatusText, TeamScore, bShowScore;
}

// ---------------------------------------------------------------- the mode's life

function StartMode()
{
    RoundStartedAt = WorldInfo.TimeSeconds;
    SetTimer(TICK_INTERVAL, true, 'ModeTick');
    ModeStarted();
    UpdateStatus();
}

function StopMode()
{
    ClearTimer('ModeTick');
    ModeStopped();
    ClearPlayerLines();
    Destroy();
}

function ModeStarted();          // override
function ModeStopped();          // override

// A new round: the game's own reset is done (MutCMenu.Reset, then a moment later)
function RoundReset()
{
    bRoundDecided = false;
    RoundStartedAt = WorldInfo.TimeSeconds;
    TeamScore[0] = 0;
    TeamScore[1] = 0;
    NewRound();
    UpdateStatus();
}

function NewRound();             // override

function ModeTick()
{
    TickMode(TICK_INTERVAL);
    UpdateStatus();
    UpdatePlayerLines();
}

function TickMode(float DeltaTime);  // override

// ---------------------------------------------------------------- events from MutCMenu (override as needed)

function NetDamage(int OriginalDamage, out int Damage, Pawn Injured, Controller InstigatedBy, vector HitLocation,
    out vector Momentum, class<DamageType> DamageType, Actor DamageCauser);

function PlayerDied(Pawn Killed, Controller Killer, class<DamageType> DamageType);

function ModifyPlayer(Pawn P);

function PlayerLeft(Controller Exiting);

// A Capture the Flag flag (or the bomb) is touched by P: true lets them pick it up
function bool FlagTouched(CMAFlag F, Pawn P)
{
    return true;
}

// A player's bomb key (plant, defuse) went down or up
function BombKey(PlayerController PC, bool bDown);

// ---------------------------------------------------------------- what players see

function UpdateStatus();         // override: set StatusText (and TeamScore)

// The line for one player, under the mode's status ("" for none)
function string PlayerLine(PlayerController PC)
{
    return "";
}

function UpdatePlayerLines()
{
    local DummyActor DA;

    foreach Mut.DummyActors(DA)
    {
        if (DA != None && !DA.bDeleteMe && PlayerController(DA.Owner) != None)
            DA.ModeLine = PlayerLine(PlayerController(DA.Owner));
    }
}

function ClearPlayerLines()
{
    local DummyActor DA;

    foreach Mut.DummyActors(DA)
    {
        if (DA != None)
            DA.ModeLine = "";
    }
}

// ---------------------------------------------------------------- helpers

function Announce(string Msg)
{
    WorldInfo.Game.Broadcast(self, "[" $ ModeTitle $ "] " $ Msg);
}

static function byte TeamOf(Controller C)
{
    if (C == None || C.PlayerReplicationInfo == None)
        return 255;
    return class'CMMapInfo'.static.PlayingTeam(C.PlayerReplicationInfo);
}

static function byte PawnTeam(Pawn P)
{
    if (P == None)
        return 255;
    if (P.Controller != None)
        return TeamOf(P.Controller);
    if (P.PlayerReplicationInfo != None)
        return class'CMMapInfo'.static.PlayingTeam(P.PlayerReplicationInfo);
    return 255;
}

simulated function string TeamName(int Team)
{
    return class'CMAFlag'.static.TeamWord(WorldInfo, Team);
}

static function string ClockText(float Seconds)
{
    local int S;

    S = Max(0, int(Seconds + 0.99));
    return (S / 60) $ ":" $ (S % 60 < 10 ? "0" : "") $ (S % 60);
}

// The round goes to Team, with Why told to everyone. Once a round.
function WinRound(byte Team, string Why)
{
    if (bRoundDecided || Team > 1)
        return;
    bRoundDecided = true;
    LastWinner = Team;
    Announce(Why);
    if (!bDontEndRound && ROGameInfo(WorldInfo.Game) != None)
        ROGameInfo(WorldInfo.Game).RoundWon(Team, ROWC_ScoreLimit);
}

defaultproperties
{
    bAlwaysRelevant=true
    LastWinner=255
    RemoteRole=ROLE_SimulatedProxy
    NetUpdateFrequency=4
}

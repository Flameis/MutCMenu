// Gun game with lives: every player starts each life with the weapon of their step on the ladder, and each kill of an
// enemy moves them one step up (the new weapon straight away). The first player to make a kill with the last weapon wins
// the round for their team. Each player has GunGameLives lives a round (3 by default); a player who has used them all is
// out until the next round, and a team with nobody left loses it.
class CMModeGunGame extends CMGameMode;

struct GunGamePlayer
{
    var PlayerReplicationInfo PRI;
    var int Level;      // their step on the ladder, from 0
    var int Deaths;     // this round
    var bool bOut;      // no lives left this round
};
var array<GunGamePlayer> Players;

struct PendingEquip
{
    var Pawn P;
    var float At;       // when to give the weapon (a moment after spawning, once the role's own kit is there)
};
var array<PendingEquip> Pending;

var array<string> DefaultLadder;  // when the server has no GunGameLadder of its own

const EQUIP_DELAY = 0.5;
const OUT_RESPAWN_TIME = -10;     // a respawn time that never comes round (ROPlayerController.NextRespawnTime)

function GetLadder(out array<string> Ladder)
{
    if (Mut.GunGameLadder.Length > 0)
        Ladder = Mut.GunGameLadder;
    else
        Ladder = DefaultLadder;
}

function int LadderLength()
{
    return (Mut.GunGameLadder.Length > 0) ? Mut.GunGameLadder.Length : DefaultLadder.Length;
}

function string LadderWeapon(int Level)
{
    local array<string> Ladder;

    GetLadder(Ladder);
    if (Ladder.Length == 0)
        return "";
    return Ladder[Clamp(Level, 0, Ladder.Length - 1)];
}

function int Lives()
{
    return (Mut.GunGameLives > 0) ? Mut.GunGameLives : 3;
}

function ModeStarted()
{
    Announce("Every kill gives you the next weapon. Win with a kill using the last one (" $ LadderLength() $ " weapons). "
        $ Lives() $ " lives each.");
    EquipEveryone();
}

function NewRound()
{
    Players.Length = 0;
    Pending.Length = 0;
}

function ModeStopped()
{
    local int i;

    // Players who were out can spawn again
    for (i = 0; i < Players.Length; i++)
        Players[i].bOut = false;
}

function int PlayerIndex(PlayerReplicationInfo PRI)
{
    local int i;
    local GunGamePlayer G;

    if (PRI == None)
        return INDEX_NONE;
    for (i = 0; i < Players.Length; i++)
    {
        if (Players[i].PRI == PRI)
            return i;
    }
    G.PRI = PRI;
    Players.AddItem(G);
    return Players.Length - 1;
}

// A pawn's weapons swapped for the one of their step
function Equip(Pawn P)
{
    local ROInventoryManager ROIM;
    local array<ROWeapon> Weapons;
    local ROWeapon W;
    local Inventory Given;
    local int i;

    if (P == None || P.bDeleteMe || P.Health <= 0 || P.PlayerReplicationInfo == None)
        return;
    ROIM = ROInventoryManager(P.InvManager);
    if (ROIM == None)
        return;
    i = PlayerIndex(P.PlayerReplicationInfo);
    ROIM.GetWeaponList(Weapons);
    foreach Weapons(W)
        ROIM.RemoveFromInventory(W);
    Given = ROIM.LoadAndCreateInventory(LadderWeapon(Players[i].Level), false, true);
    if (Weapon(Given) != None)
        ROIM.SetCurrentWeapon(Weapon(Given));
}

function EquipEveryone()
{
    local Pawn P;

    foreach WorldInfo.AllPawns(class'Pawn', P)
    {
        if (ROPawn(P) != None && P.Health > 0 && P.PlayerReplicationInfo != None)
            Equip(P);
    }
}

function ModifyPlayer(Pawn P)
{
    local PendingEquip E;
    local int i;

    if (ROPawn(P) == None || P.PlayerReplicationInfo == None)
        return;
    i = PlayerIndex(P.PlayerReplicationInfo);
    // Out of lives: no more spawning this round (only reached if the game spawned them anyway)
    if (Players[i].bOut)
    {
        P.Destroy();
        return;
    }
    E.P = P;
    E.At = WorldInfo.TimeSeconds + EQUIP_DELAY;
    Pending.AddItem(E);
}

function PlayerDied(Pawn Killed, Controller Killer, class<DamageType> DamageType)
{
    local int k, v;
    local byte KillerTeam, VictimTeam;
    local string KillerName;

    if (bRoundDecided || Killed == None || Killed.PlayerReplicationInfo == None || ROPawn(Killed) == None)
        return;
    v = PlayerIndex(Killed.PlayerReplicationInfo);
    VictimTeam = PawnTeam(Killed);

    // The victim loses a life
    if (!Players[v].bOut)
    {
        Players[v].Deaths++;
        if (Players[v].Deaths >= Lives())
        {
            Players[v].bOut = true;
            if (PlayerController(Killed.Controller) != None)
                Mut.PrivateMessage(PlayerController(Killed.Controller), "[GUN GAME] You are out of lives until the next round.");
        }
    }

    // The killer steps up, for a kill of an enemy
    KillerTeam = TeamOf(Killer);
    if (Killer != None && Killer != Killed.Controller && KillerTeam < 2 && KillerTeam != VictimTeam && Killer.PlayerReplicationInfo != None)
    {
        k = PlayerIndex(Killer.PlayerReplicationInfo);
        KillerName = Killer.PlayerReplicationInfo.PlayerName;
        if (Players[k].Level >= LadderLength() - 1)
        {
            WinRound(KillerTeam, KillerName $ " made a kill with the last weapon: " $ TeamName(KillerTeam) $ " win the round");
            return;
        }
        Players[k].Level++;
        if (Killer.Pawn != None)
            Equip(Killer.Pawn);
    }
    CheckTeamsOut();
}

// A team whose players are all out of lives loses the round
function CheckTeamsOut()
{
    local PlayerReplicationInfo PRI;
    local int Team, i, Total[2], Out[2];

    foreach WorldInfo.GRI.PRIArray(PRI)
    {
        Team = class'CMMapInfo'.static.PlayingTeam(PRI);
        if (Team > 1)
            continue;
        Total[Team]++;
        i = PlayerIndex(PRI);
        if (Players[i].bOut)
            Out[Team]++;
    }
    for (Team = 0; Team < 2; Team++)
    {
        if (Total[Team] > 0 && Out[Team] == Total[Team] && Total[1 - Team] > Out[1 - Team])
        {
            WinRound(1 - Team, TeamName(Team) $ " are out of lives: " $ TeamName(1 - Team) $ " win the round");
            return;
        }
    }
}

function TickMode(float DeltaTime)
{
    local int i;
    local Controller C;

    // Weapons for the newly spawned
    for (i = Pending.Length - 1; i >= 0; i--)
    {
        if (Pending[i].P == None || Pending[i].P.bDeleteMe)
            Pending.Remove(i, 1);
        else if (WorldInfo.TimeSeconds >= Pending[i].At)
        {
            Equip(Pending[i].P);
            Pending.Remove(i, 1);
        }
    }

    // The out stay out: their respawn time never comes
    for (i = 0; i < Players.Length; i++)
    {
        if (!Players[i].bOut || Players[i].PRI == None)
            continue;
        C = Controller(Players[i].PRI.Owner);
        if (ROPlayerController(C) != None)
            ROPlayerController(C).NextRespawnTime = OUT_RESPAWN_TIME;
        else if (ROAIController(C) != None)
            ROAIController(C).NextRespawnTime = OUT_RESPAWN_TIME;
    }
}

function UpdateStatus()
{
    local int i, Best;

    Best = INDEX_NONE;
    for (i = 0; i < Players.Length; i++)
    {
        if (Players[i].PRI != None && (Best == INDEX_NONE || Players[i].Level > Players[Best].Level))
            Best = i;
    }
    StatusText = LadderLength() $ " weapons, " $ Lives() $ " lives";
    if (Best != INDEX_NONE && Players[Best].Level > 0)
        StatusText $= "   Leader: " $ Players[Best].PRI.PlayerName $ " (weapon " $ (Players[Best].Level + 1) $ ")";
}

function string WeaponName(int Level)
{
    local class<Inventory> IC;

    IC = class<Inventory>(DynamicLoadObject(LadderWeapon(Level), class'Class', true));
    return (IC != None && IC.default.ItemName != "") ? IC.default.ItemName : LadderWeapon(Level);
}

function string PlayerLine(PlayerController PC)
{
    local int i;

    if (PC.PlayerReplicationInfo == None || class'CMMapInfo'.static.PlayingTeam(PC.PlayerReplicationInfo) > 1)
        return "";
    i = PlayerIndex(PC.PlayerReplicationInfo);
    if (Players[i].bOut)
        return "You are out of lives until the next round";
    return "Weapon " $ (Players[i].Level + 1) $ " of " $ LadderLength() $ ": " $ WeaponName(Players[i].Level)
        $ "   Lives: " $ (Lives() - Players[i].Deaths);
}

defaultproperties
{
    ModeTitle="GUN GAME"

    DefaultLadder.Add("ROGameContent.ROWeap_M60_GPMG_Content")
    DefaultLadder.Add("ROGameContent.ROWeap_RPD_LMG_Content")
    DefaultLadder.Add("ROGameContent.ROWeap_M16A1_AssaultRifle_Content")
    DefaultLadder.Add("ROGameContent.ROWeap_XM177E1_Carbine_Content")
    DefaultLadder.Add("ROGameContent.ROWeap_M14_Rifle_Content")
    DefaultLadder.Add("ROGameContent.ROWeap_SKS_Rifle_Content")
    DefaultLadder.Add("ROGameContent.ROWeap_PPSH41_SMG_Content")
    DefaultLadder.Add("ROGameContent.ROWeap_M3A1_SMG_Content")
    DefaultLadder.Add("ROGameContent.ROWeap_M1_Carbine_Content")
    DefaultLadder.Add("ROGameContent.ROWeap_MN9130_Rifle_Content")
    DefaultLadder.Add("ROGameContent.ROWeap_IZH43_Shotgun_Content")
    DefaultLadder.Add("ROGameContent.ROWeap_M1911_Pistol_Content")
    DefaultLadder.Add("ROGameContent.ROWeap_TT33_Pistol_Content")
}

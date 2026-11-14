class CMAPlaceableSpawn extends ROPlaceableSpawn;

event TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
}

function SetTeam(ROTeamInfo NewTeam, ROSquadInfo NewSquad)
{
	Team = NewTeam;
	TeamNum = Team.TeamIndex;
}

// The team of the Builder spawn it belongs to (set by CMASpawn.SetSpawnTeam). The game's own placeable spawns answer
// 255 here, which made the game's spot search check the wrong team's protected area.
simulated event byte ScriptGetTeamNum()
{
	return TeamNum;
}

simulated function bool IsDestroyed()
{
	return false;
}

function UpdateSpawnStatus()
{
}

simulated function bool HasLineOfSight(vector PawnHeadLoc, rotator PawnViewRot)
{
}

simulated function bool CanDestroyTunnel(Pawn User)
{
	return false;
}

function bool UsedBy(Pawn User)
{
	return false;
}

DefaultProperties
{
	Health=10000
}

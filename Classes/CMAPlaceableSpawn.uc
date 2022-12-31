class CMAPlaceableSpawn extends ROPlaceableSpawn;

event TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
}

function SetTeam(ROTeamInfo NewTeam, ROSquadInfo NewSquad)
{
	Team = NewTeam;
	TeamNum = Team.TeamIndex;
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

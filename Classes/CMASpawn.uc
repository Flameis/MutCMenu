// A Builder spawn point for North or South: while one stands, its team spawns there (MutCMenu.FindPlayerStart). It is
// listed on the team's deploy map as a spawn of its own (CMSpawnLocation), so players can see it and pick it.
class CMASpawn extends CMAStaticMesh;

var array<NavigationPoint> MySpawns;
var CMAPlaceableSpawn PSP;
var repnotify int TeamIndex;
var CMSpawnLocation DeployEntry; // Server: its entry in the team's list of spawns, for the deploy map

replication
{
	if (bNetDirty && (Role == ROLE_Authority))
		TeamIndex;
}

function PostBeginPlay()
{
	PSP = Spawn(class'CMAPlaceableSpawn',,, self.location);
	PSP.DestructibleMeshComponent.SetHidden(True);
	PSP.bDestroyed = True;
}

// Sets the team it is for and lists it on that team's deploy map
function SetSpawnTeam(int NewTeam)
{
	RemoveFromDeployMap();
	TeamIndex = NewTeam;
	bNetDirty = true;

	if (WorldInfo.GRI == None || TeamIndex < 0 || TeamIndex >= WorldInfo.GRI.Teams.Length || ROTeamInfo(WorldInfo.GRI.Teams[TeamIndex]) == None)
		return;

	DeployEntry = Spawn(class'CMSpawnLocation',,, Location, Rotation);
	if (DeployEntry == None)
		return;
	DeployEntry.ForSpawn = self;
	ROTeamInfo(WorldInfo.GRI.Teams[TeamIndex]).AddSpawnLocation(DeployEntry);
	SpawnListChanged();
}

function RemoveFromDeployMap()
{
	if (DeployEntry == None)
		return;

	if (WorldInfo.GRI != None && TeamIndex >= 0 && TeamIndex < WorldInfo.GRI.Teams.Length && ROTeamInfo(WorldInfo.GRI.Teams[TeamIndex]) != None)
		ROTeamInfo(WorldInfo.GRI.Teams[TeamIndex]).RemoveSpawnLocation(DeployEntry);
	DeployEntry.Destroy();
	DeployEntry = None;
	SpawnListChanged();
}

// Joined players hear of it from the team's list when it reaches them; a player on this computer (the host, or single
// player) is told here
function SpawnListChanged()
{
	local ROPlayerController ROPC;

	if (WorldInfo.GRI != None && TeamIndex >= 0 && TeamIndex < WorldInfo.GRI.Teams.Length)
		WorldInfo.GRI.Teams[TeamIndex].bNetDirty = true;
	foreach LocalPlayerControllers(class'ROPlayerController', ROPC)
		ROPC.SpawnInfoChanged();
}

function Destroyed()
{
	local NavigationPoint SpawnP;

	RemoveFromDeployMap();
	foreach MySpawns(SpawnP)
	{
    	SpawnP.Destroy();
	}
	PSP.Destroy();

	super.Destroyed();
}

defaultproperties
{
    health=10000

    Begin Object Name=StaticMeshComponent0
        StaticMesh=StaticMesh'ENV_VN_Flags.Meshes.S_VN_Flagpole'
        CollideActors=true
		BlockActors=true
		BlockZeroExtent=true
		BlockNonZeroExtent=true
        CastShadow=true
        bCastDynamicShadow=true
    End Object
	StaticMeshComponent=StaticMeshComponent0
	Components.Add(StaticMeshComponent0)
}
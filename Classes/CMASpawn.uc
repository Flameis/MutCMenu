class CMASpawn extends CMSM;

var array<NavigationPoint> MySpawns;
var CMAPlaceableSpawn PSP;
var repnotify int TeamIndex;

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

function Destroyed()
{
	local NavigationPoint SpawnP;

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
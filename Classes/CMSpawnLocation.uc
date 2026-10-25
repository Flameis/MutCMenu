// A custom spawn's entry on the deploy map. The deploy map (and the spawn buttons beside it) list the team's spawn areas,
// which are map volumes, so a Builder spawn (CMASpawn) adds one of these to its team's list: it shows there as a numbered
// spawn, and picking it spawns the player at that custom spawn (MutCMenu.FindPlayerStart). It has no shape and holds no
// player starts of its own; it only says where the spawn is.
// It has no collision or brush component either. The game asks every listed spawn area whether a point is inside it (a
// molotov does), and that check answers "no" at once for an area without a collision component; with a brush component
// but no brush (a volume made while the game runs has none) it would go on into code that was never meant for that.
class CMSpawnLocation extends ROVolumePlayerStartGroup;

var CMASpawn ForSpawn; // Server: the Builder spawn it stands for

// The map's own spawn areas gather the player starts inside them here; this one has no shape to hold any
event PostBeginPlay()
{
}

defaultproperties
{
    bStatic=false
    bNoDelete=false
    bHidden=true
    bCollideActors=false
    RemoteRole=ROLE_SimulatedProxy
    bAlwaysRelevant=true
    bReplicateMovement=true

    Components.Remove(BrushComponent0)
    BrushComponent=None
    CollisionComponent=None
}

// A wind source the mutator adds to a map that has none, so smoke drifts on the wind. It is sent to every player, because
// the smoke is drawn on each player's own computer.
class CMWindSource extends WindDirectionalSource;

defaultproperties
{
	RemoteRole=ROLE_SimulatedProxy
	bAlwaysRelevant=true
	bReplicateMovement=true
	bNoDelete=false
}

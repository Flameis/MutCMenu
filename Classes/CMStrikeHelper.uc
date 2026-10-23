// Shared by the fire support aircraft (CMCarpetBomberAircraft, CMNapalmStrikeAircraft, CMNapalmStrikeAircraftARVN).
// The base game aircraft re-check the no-artillery volumes (which fence off everything outside the combat area) when they
// drop their payload and cancel the run. Admin called strikes switch those volumes off for the duration of that one call.
class CMStrikeHelper extends Object;

static function DisableNoArtyVolumes(Actor Context, out array<ROVolumeNoArtillery> Disabled)
{
    local ROVolumeNoArtillery V;

    foreach Context.AllActors(class'ROVolumeNoArtillery', V)
    {
        if (V.bEnabled)
        {
            V.bEnabled = false;
            Disabled.AddItem(V);
        }
    }
}

static function RestoreNoArtyVolumes(array<ROVolumeNoArtillery> Disabled)
{
    local int i;

    for (i = 0; i < Disabled.Length; i++)
    {
        if (Disabled[i] != None)
            Disabled[i].bEnabled = true;
    }
}

defaultproperties
{
}

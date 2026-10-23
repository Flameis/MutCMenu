// ARVN napalm aircraft used by fire support (see CMNapalmStrikeAircraft)
class CMNapalmStrikeAircraftARVN extends RONapalmStrikeAircraftARVN;

var bool bIgnoreNoArty;

function DropPayload()
{
    local array<ROVolumeNoArtillery> Disabled;

    if (bIgnoreNoArty)
        class'CMStrikeHelper'.static.DisableNoArtyVolumes(self, Disabled);

    super.DropPayload();

    class'CMStrikeHelper'.static.RestoreNoArtyVolumes(Disabled);
}

defaultproperties
{
}

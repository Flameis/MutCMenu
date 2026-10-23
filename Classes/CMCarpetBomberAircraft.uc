// Canberra bomber used by fire support. Identical to the base game's, except that an admin called run can bomb
// targets inside no-artillery volumes (such as the area outside the combat area)
class CMCarpetBomberAircraft extends ROCarpetBomberAircraft;

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

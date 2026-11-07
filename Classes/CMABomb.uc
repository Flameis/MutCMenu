// The bomb of the bomb mode (CMModeBomb): a satchel carried on the back like a Capture the Flag flag, by the attackers
// only. Planted at a site it stays put until it goes off or is defused.
class CMABomb extends CMAFlag;

var CMModeBomb Mode;
var repnotify bool bPlanted;
var float PlantedAt;          // Server: when it was planted
var byte PlantedSite;         // Server: the site's kind (CMAModePoint.KIND_SITE_A / B)

replication
{
    if (bNetDirty && Role == ROLE_Authority)
        bPlanted;
}

simulated event ReplicatedEvent(name VarName)
{
    if (VarName == 'bPlanted')
        UpdateVisibility();
    else
        super.ReplicatedEvent(VarName);
}

// The satchel needs no flag cloth or faction
simulated function ApplyStyle();

function string Label()
{
    return "bomb";
}

function bool CanPickUp(Pawn P)
{
    if (bPlanted || Mode == None)
        return false;
    return super.CanPickUp(P);
}

// Stays where it is planted
function Plant(vector Where, byte Site)
{
    if (Carrier != None)
    {
        Carrier = None;
        CarrierPRI = None;
        CarrierChanged();
    }
    bPlanted = true;
    PlantedAt = WorldInfo.TimeSeconds;
    PlantedSite = Site;
    SetLocation(Where);
    Velocity = vect(0, 0, 0);
    SetPhysics(PHYS_Falling);
}

function ReturnHome()
{
    bPlanted = false;
    super.ReturnHome();
}

// "picked up the bomb flag" reads "picked up the bomb", and goes out with the mode's name
function Announce(string Msg)
{
    Msg = Repl(Msg, "bomb flag", "bomb");
    if (Mode != None)
        Mode.Announce(Msg);
    else
        super.Announce(Msg);
}

defaultproperties
{
    bShowBeam=true
    DropperDelay=1.0

    Begin Object Name=FlagCloth
        SkeletalMesh=SkeletalMesh'WP_VN_3rd_Master.Mesh.Rus_Satchel_3rd_Master'
        Translation=(X=0,Y=0,Z=-34)
        Scale=1.0
        ForcedLodModel=0
    End Object

    Begin Object Name=FlagPole
        StaticMesh=None
    End Object
}

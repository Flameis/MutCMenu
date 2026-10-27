// Puts a player's body back as it was when they get out of a WW2 tank on a map that isn't WW2's.
// A WW2 tank sits anyone who gets in into its crew pose: the passenger animation tree, the crew animations, gear hidden
// and an arms-only head mesh (WW2VehicleTank.SitDriver). Getting out undoes that only for WW2's own pawn
// (DetachDriver and PassengerLeave check for WW2Pawn), so on any other map the player came out in the crew pose: the
// body bugged out and the footsteps stopped. This does what WW2's undo does, for every other pawn (as Winter War's own
// vehicles do). It runs on the server and on every player's game (each poses the bodies it sees), and looks a few
// times a second: who is in a WW2 tank, and who of them is out again.
class CMTankExitFix extends Info;

var array<ROPawn> InTank; // pawns (not WW2's) seen in a WW2 tank

simulated event PostBeginPlay()
{
    super.PostBeginPlay();
    SetTimer(0.2, true, 'CheckPawns');
}

simulated function CheckPawns()
{
    local ROPawn P;
    local int i;

    foreach WorldInfo.AllPawns(class'ROPawn', P)
    {
        if (P.DrivenVehicle != None && !P.IsA('WW2Pawn') && IsWW2Tank(P.DrivenVehicle) && InTank.Find(P) == INDEX_NONE)
            InTank.AddItem(P);
    }
    for (i = InTank.Length - 1; i >= 0; i--)
    {
        P = InTank[i];
        if (P == None || P.bDeleteMe || P.bTearOff)
        {
            InTank.Remove(i, 1);
            continue;
        }
        if (P.DrivenVehicle == None)
        {
            RestoreBody(P);
            InTank.Remove(i, 1);
        }
    }
}

// The tank itself, or one of its seats
static function bool IsWW2Tank(Vehicle V)
{
    if (ROWeaponPawn(V) != None)
        V = ROWeaponPawn(V).MyVehicle;
    return V != None && V.IsA('WW2VehicleTank');
}

// What WW2's own undo does for its pawn (WW2VehicleTank.DetachDriver)
static function RestoreBody(ROPawn P)
{
    if (P.Mesh != None)
    {
        P.Mesh.SetAnimTreeTemplate(P.Mesh.default.AnimTreeTemplate);
        if (ROSkeletalMeshComponent(P.Mesh) != None && ROSkeletalMeshComponent(P.Mesh).AnimSets.Length > 0)
            ROSkeletalMeshComponent(P.Mesh).AnimSets[0] = ROSkeletalMeshComponent(P.Mesh).default.AnimSets[0];
    }
    if (P.ThirdPersonHeadAndArmsMeshComponent != None && P.HeadAndArmsMesh != None)
        P.ThirdPersonHeadAndArmsMeshComponent.SetSkeletalMesh(P.HeadAndArmsMesh);
    if (P.ThirdPersonHeadgearMeshComponent != None)
        P.ThirdPersonHeadgearMeshComponent.SetHidden(false);
    if (P.FaceItemMeshComponent != None)
        P.FaceItemMeshComponent.SetHidden(false);
    if (P.FacialHairMeshComponent != None)
        P.FacialHairMeshComponent.SetHidden(false);
    if (P.ThirdPersonHeadphonesMeshComponent != None)
        P.ThirdPersonHeadphonesMeshComponent.SetOwnerNoSee(false);
    P.HideGear(false);
}

defaultproperties
{
    RemoteRole=ROLE_SimulatedProxy
    bAlwaysRelevant=true
    bOnlyDirtyReplication=true
    NetUpdateFrequency=1
}

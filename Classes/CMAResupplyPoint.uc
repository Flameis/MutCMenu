// The Builder's ammo resupply point: a stack of crates that resupplies players of both teams standing next to it, the way a
// map's own resupply area does (ammo, grenades and the like once a minute, a squad leader's equipment, bandages and spare
// ammo as it is used), and shows as a resupply area on everyone's map.
// It used to spawn a game resupply volume, but a volume made while the game runs has no shape, so nobody was ever inside
// it: the crates resupplied nobody. It now looks for the players near it itself, once a second.
// Explosives wait longer than at the map's resupply areas: grenades, satchels and the like come back once a minute (the
// game's own wait, which it skipped when bandages were given at the same time), and rounds for grenade launchers (the
// M79, a rifle's grenades such as the MAS-49's) and rocket launchers (the RPG) fill up, then not again for a minute.
class CMAResupplyPoint extends CMAStaticMesh
    dependson(ROVolumeAmmoResupply);

var array<StaticMeshComponent> StaticMeshComponents;
var array<ROPawn> InArea;   // Server: the players it is resupplying, so they can be told when they leave
var int GRIIndex;           // Its place in the game's list of resupply areas (the map's resupply icons), -1 when none

// Each player's wait for explosive rounds (grenade and rocket launchers)
struct ExplosiveWait
{
    var ROPawn P;
    var float Until;     // no explosive rounds before this time
    var bool bFilling;   // being filled now: the wait starts once they are full
};
var array<ExplosiveWait> Waits;

const RESUPPLY_RADIUS = 250.0;   // 5 meters round the crates
const RESUPPLY_HEIGHT = 150.0;   // 3 meters above or below them
const RESUPPLY_COOLDOWN = 60.0;  // seconds between full resupplies, as the game's own resupply areas
const EXPLOSIVE_COOLDOWN = 60.0; // seconds after grenade or rocket launcher rounds were filled before more are given

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if (Role == ROLE_Authority)
    {
        AddToMap();
        SetTimer(1.0, true, 'ResupplyTimer');
    }
}

// A place in the game's list of resupply areas, for both teams, so the map shows the resupply icon here
function AddToMap()
{
    local ROGameReplicationInfo ROGRI;
    local int i;

    GRIIndex = -1;
    ROGRI = ROGameReplicationInfo(WorldInfo.GRI);
    if (ROGRI == None)
        return;

    for (i = 0; i < `MAX_RESUPPLY_AREAS; i++)
    {
        if (ROGRI.ResupplyAreas[i].Team == 255)
        {
            ROGRI.ResupplyAreas[i].Location = Location;
            ROGRI.ResupplyAreas[i].Team = OWNER_Neutral;
            ROGRI.ResupplyAreas[i].Type = RT_Players;
            ROGRI.ResupplyAreas[i].bActive = true;
            ROGRI.bNetDirty = true;
            GRIIndex = i;
            return;
        }
    }
}

// Whether a player is close enough to be resupplied
function bool InReach(ROPawn ROP)
{
    return ROP != None && !ROP.bDeleteMe && ROP.Health > 0 && Abs(ROP.Location.Z - Location.Z) <= RESUPPLY_HEIGHT
        && VSize2D(ROP.Location - Location) <= RESUPPLY_RADIUS;
}

// As ROVolumeAmmoResupply.ResupplyTimer does for the players inside it
function ResupplyTimer()
{
    local array<ROPawn> Here;
    local ROPawn ROP;
    local ROPlayerReplicationInfo ROPRI;
    local float ResupplyTime;
    local bool bEligible, bResupplied;
    local byte GivenMags, ResuppliedType;
    local int i;

    // Blown up, it resupplies nobody (it stays a moment as wreckage)
    if (Health > 0)
    {
        foreach WorldInfo.AllPawns(class'ROPawn', ROP, Location, RESUPPLY_RADIUS + RESUPPLY_HEIGHT)
        {
            if (InReach(ROP))
                Here.AddItem(ROP);
        }
    }
    else
        RemoveFromMap();

    // Those who walked away are out of the resupply area again
    for (i = 0; i < InArea.Length; i++)
    {
        if (InArea[i] != None && !InArea[i].bDeleteMe && Here.Find(InArea[i]) == INDEX_NONE)
        {
            InArea[i].bTouchingResupply = false;
            InArea[i].bCurrentResupplyActive = false;
        }
    }
    InArea = Here;

    for (i = 0; i < Here.Length; i++)
    {
        ROP = Here[i];
        ROP.bTouchingResupply = true;
        ROPRI = (ROP.Controller != None) ? ROPlayerReplicationInfo(ROP.Controller.PlayerReplicationInfo) : None;
        if (ROPRI == None)
            continue;

        ResupplyTime = ROP.GetLastResupplyTime();
        bEligible = WorldInfo.TimeSeconds - ResupplyTime >= RESUPPLY_COOLDOWN || ResupplyTime == 0;
        bResupplied = false;
        GivenMags = 0;
        ResuppliedType = 0;

        if (bEligible && ROPRI.RoleIndex == `ROLE_INDEX_SQUADLEADER && ROPRI.RoleInfo != None)
            bResupplied = ROPRI.RoleInfo.GiveNewSLEquipment(ROP);

        bResupplied = ResupplyPlayer(ROP, GivenMags, bEligible, ResuppliedType) || bResupplied;

        // The minute's wait starts only once their equipment was filled, not for spare ammo or bandages alone
        if (ResuppliedType == 2)
        {
            ROP.UpdateLastResupplyTime();
            ROP.ClientResupplied(false);
        }
        else if (bResupplied)
            ROP.ClientResupplied(true);

        ROP.bCurrentResupplyActive = bResupplied;
    }
}

// Whether a weapon fires explosive rounds: grenade launchers and rocket launchers
static function bool IsExplosiveLauncher(ROWeapon W)
{
    return W != None && (W.WeaponClassType == ROWCT_Explosive || W.WeaponClassType == ROWCT_ATRocket || W.IsA('RORocketWeapon'));
}

// This player's place in the waits (made when missing); players who are gone are dropped
function int WaitIndex(ROPawn ROP)
{
    local int i;

    for (i = Waits.Length - 1; i >= 0; i--)
    {
        if (Waits[i].P == None || Waits[i].P.bDeleteMe)
            Waits.Remove(i, 1);
    }
    for (i = 0; i < Waits.Length; i++)
    {
        if (Waits[i].P == ROP)
            return i;
    }
    Waits.Add(1);
    Waits[i].P = ROP;
    return i;
}

// One magazine of a rifle's own ammo, never its grenades (for a rifle grenade weapon whose grenades are waiting)
function bool GiveRifleMagOnly(ROWeapon W)
{
    local bool bGave;

    if (!W.bUseAltFireMode)
        return W.GaveSingleMagAmmoActual();
    W.SwapAmmoTypes(false, true);
    bGave = W.GaveSingleMagAmmoActual();
    W.SwapAmmoTypes(true, true);
    return bGave;
}

// The game's ResupplyPlayer (ROVolumeAmmoResupply) with the explosives' wait. ItemType: 1 a magazine, 2 equipment
// (grenades and the like, which starts the minute's wait), 3 bandages, 4 carried ammo. Equipment wins over bandages and
// carried ammo given at the same time, so the wait always starts when grenades were given.
function bool ResupplyPlayer(ROPawn ROP, out byte GivenMags, bool bResupplyTimeOK, optional out byte ItemType)
{
    local ROPlayerController ROPC;
    local ROPlayerReplicationInfo ROPRI;
    local ROGameReplicationInfo ROGRI;
    local Inventory Inv, NewInv;
    local ROWeapon W;
    local bool bResupplied, bGaveEquipment, bWaiting, bGave;
    local int i, j, NumOtherItems, OtherItemStart, RoleItemsIdx, WI, Primary;
    local int Indexes[`MAX_RESUPPLY_INFOS];
    local byte Count;

    ROPRI = ROPlayerReplicationInfo(ROP.PlayerReplicationInfo);
    ROGRI = ROGameReplicationInfo(WorldInfo.GRI);
    ROPC = ROPlayerController(ROP.Controller);
    if (ROPRI == None || ROGRI == None || ROP.InvManager == None)
        return false;
    RoleItemsIdx = ROGRI.RoleInfoItemsIdx;
    for (i = 0; i < `MAX_RESUPPLY_INFOS; i++)
        Indexes[i] = -1;

    WI = WaitIndex(ROP);
    bWaiting = WorldInfo.TimeSeconds < Waits[WI].Until;

    // Weapons: one magazine a second, as the game does; explosive rounds only when not waiting
    for (Inv = ROP.InvManager.InventoryChain; Inv != None; Inv = Inv.Inventory)
    {
        W = ROWeapon(Inv);
        if (W == None || W.IsGrenade() || W.IsA('ROOneShotWeapon'))
            continue;

        if (IsExplosiveLauncher(W))
        {
            if (bWaiting)
                continue;
            bGave = W.GiveInitialAmmo(true);
            if (bGave)
                Waits[WI].bFilling = true;
        }
        else if (W.IsA('RORifleGrenadeWeapon'))
        {
            if (bWaiting)
                bGave = GiveRifleMagOnly(W);
            else
            {
                bGave = W.GiveInitialAmmo(true);
                if (bGave)
                    Waits[WI].bFilling = true;
            }
        }
        else
            bGave = W.GiveInitialAmmo(true);

        if (bGave)
        {
            GivenMags = 1;
            if (ROPC != None)
                ROPC.ClientReceiveResupplyInfoSingleViaWeapon(W, W.InvIndex, true);
            ItemType = 1;
            return true;
        }
    }

    // Nothing more to fill: explosive rounds that were being filled are full now, and their wait starts
    if (Waits[WI].bFilling)
    {
        Waits[WI].bFilling = false;
        Waits[WI].Until = WorldInfo.TimeSeconds + EXPLOSIVE_COOLDOWN;
    }

    // Grenades, satchels and the like, once the minute's wait is over (as the game)
    if (bResupplyTimeOK && ROPRI.RoleInfo != None && ROPRI.RoleInfo.ActiveWeaponLoadout.PrimaryWeaponIndex != 255)
    {
        Primary = ROPRI.RoleInfo.ActiveWeaponLoadout.PrimaryWeaponIndex;
        NumOtherItems = ROPRI.RoleInfo.Items[RoleItemsIdx].NumOtherItemsForPrimary[Primary];
        if (NumOtherItems != 255)
        {
            OtherItemStart = ROPRI.RoleInfo.Items[RoleItemsIdx].OtherItemsStartIndexForPrimary[Primary];
            for (i = OtherItemStart; i < ROPRI.RoleInfo.Items[RoleItemsIdx].OtherItems.Length && (NumOtherItems == 0 || j < NumOtherItems); i++)
            {
                j++;
                if (i < ROPRI.RoleInfo.GetOtherItemsStart(ROPRI.ClassRank))
                    continue;
                if (ROPRI.RoleInfo.Items[RoleItemsIdx].OtherItems[i].default.WeaponClassType == ROWCT_Melee)
                    continue;
                if (ROPRI.RoleInfo.Items[RoleItemsIdx].OtherItems[i].default.WeaponClassType == ROWCT_ATRocket)
                    continue;
                if (ROInventoryManager(ROP.InvManager).RS2FindInventoryType(ROPRI.RoleInfo.Items[RoleItemsIdx].OtherItems[i]))
                    continue;
                NewInv = ROP.LoadAndCreateInventory(ROPRI.RoleInfo.Items[RoleItemsIdx].OtherItems[i].default.WeaponContentClass[0], true);
                if (NewInv != None)
                {
                    bGaveEquipment = true;
                    bResupplied = true;
                    if (Count < `MAX_RESUPPLY_INFOS)
                        Indexes[Count++] = NewInv.InvIndex;
                }
            }
        }
    }

    if (ROP.NumBandages != ROP.default.NumBandages)
    {
        ROP.NumBandages = ROP.default.NumBandages;
        bResupplied = true;
        ItemType = 3;
        if (Count < `MAX_RESUPPLY_INFOS)
            Indexes[Count++] = `ROII_Bandage;
    }

    if (ROP.bUsedCarriedMGAmmo)
    {
        ROP.bUsedCarriedMGAmmo = false;
        bResupplied = true;
        ItemType = 4;
        if (Count < `MAX_RESUPPLY_INFOS)
            Indexes[Count++] = `ROII_CarriedAmmo;
    }

    if (bGaveEquipment)
        ItemType = 2;

    if (Count > 0 && ROPC != None)
    {
        if (Count > 1)
            ROPC.ClientReceiveResupplyInfo(Indexes);
        else
            ROPC.ClientReceiveResupplyInfoSingle(Indexes[0]);
    }
    return bResupplied;
}

simulated event Destroyed()
{
    local int i;

    if (Role == ROLE_Authority)
    {
        ClearTimer('ResupplyTimer');
        for (i = 0; i < InArea.Length; i++)
        {
            if (InArea[i] != None && !InArea[i].bDeleteMe)
            {
                InArea[i].bTouchingResupply = false;
                InArea[i].bCurrentResupplyActive = false;
            }
        }
        InArea.Length = 0;
        Waits.Length = 0;
        RemoveFromMap();
    }

    super.Destroyed();
}

// Gives its place in the game's list of resupply areas back
function RemoveFromMap()
{
    local ROGameReplicationInfo ROGRI;

    ROGRI = ROGameReplicationInfo(WorldInfo.GRI);
    if (ROGRI != None && GRIIndex >= 0 && GRIIndex < `MAX_RESUPPLY_AREAS)
    {
        ROGRI.ResupplyAreas[GRIIndex].Team = 255;
        ROGRI.ResupplyAreas[GRIIndex].bActive = false;
        ROGRI.bNetDirty = true;
    }
    GRIIndex = -1;
}

defaultproperties
{
    GRIIndex=-1

    Begin Object Name=StaticMeshComponent0
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Crate_001'
        Translation=(X=0.00,Y=0.00,Z=0.00)
        Rotation=(Pitch=0,Yaw=6912,Roll=0)
    End Object
    Components.Add(StaticMeshComponent0)
    StaticMeshComponents.Add(StaticMeshComponent0)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent2
        ForcedLodModel=1
        bForceMipStreaming=true
        StaticMesh=StaticMesh'ENV_VN_Barrels.Meshes.S_Pallet'
        Translation=(X=17.38,Y=-1.59,Z=-11.50)
        Rotation=(Pitch=0,Yaw=4864,Roll=0)
    End Object
    Components.Add(StaticMeshComponent2)
    StaticMeshComponents.Add(StaticMeshComponent2)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent3
        ForcedLodModel=1
        bForceMipStreaming=true
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_004'
        Translation=(X=18.41,Y=-45.84,Z=0.00)
        Rotation=(Pitch=0,Yaw=-9984,Roll=0)
    End Object
    Components.Add(StaticMeshComponent3)
    StaticMeshComponents.Add(StaticMeshComponent3)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent4
        ForcedLodModel=1
        bForceMipStreaming=true
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_002'
        Translation=(X=22.05,Y=-35.42,Z=0.00)
        Rotation=(Pitch=0,Yaw=20224,Roll=0)
    End Object
    Components.Add(StaticMeshComponent4)
    StaticMeshComponents.Add(StaticMeshComponent4)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent5
        ForcedLodModel=1
        bForceMipStreaming=true
        StaticMesh=StaticMesh'ENV_VN_US_HOW_Ammo.Meshes.Wood.S_HOW_AmmoCrate_cls'
        Translation=(X=41.36,Y=3.56,Z=0.00)
        Rotation=(Pitch=0,Yaw=-43776,Roll=0)
    End Object
    Components.Add(StaticMeshComponent5)
    StaticMeshComponents.Add(StaticMeshComponent5)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent6
        ForcedLodModel=1
        bForceMipStreaming=true
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_001'
        Translation=(X=42.68,Y=-6.57,Z=15.00)
        Rotation=(Pitch=0,Yaw=-9984,Roll=0)
    End Object
    Components.Add(StaticMeshComponent6)
    StaticMeshComponents.Add(StaticMeshComponent6)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent7
        ForcedLodModel=1
        bForceMipStreaming=true
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_001'
        Translation=(X=44.15,Y=28.11,Z=18.00)
        Rotation=(Pitch=0,Yaw=-42240,Roll=16384)
    End Object
    Components.Add(StaticMeshComponent7)
    StaticMeshComponents.Add(StaticMeshComponent7)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent8
        ForcedLodModel=1
        bForceMipStreaming=true
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_002'
        Translation=(X=23.43,Y=23.35,Z=28.00)
        Rotation=(Pitch=0,Yaw=3328,Roll=0)
    End Object
    Components.Add(StaticMeshComponent8)
    StaticMeshComponents.Add(StaticMeshComponent8)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent9
        ForcedLodModel=1
        bForceMipStreaming=true
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_006'
        Translation=(X=25.31,Y=32.41,Z=0.00)
        Rotation=(Pitch=0,Yaw=-11520,Roll=0)
    End Object
    Components.Add(StaticMeshComponent9)
    StaticMeshComponents.Add(StaticMeshComponent9)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent10
        ForcedLodModel=1
        bForceMipStreaming=true
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_004'
        Translation=(X=30.77,Y=40.65,Z=28.00)
        Rotation=(Pitch=0,Yaw=-11520,Roll=0)
    End Object
    Components.Add(StaticMeshComponent10)
    StaticMeshComponents.Add(StaticMeshComponent10)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent11
        ForcedLodModel=1
        bForceMipStreaming=true
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_003'
        Translation=(X=11.90,Y=35.16,Z=42.00)
        Rotation=(Pitch=0,Yaw=1792,Roll=0)
    End Object
    Components.Add(StaticMeshComponent11)
    StaticMeshComponents.Add(StaticMeshComponent11)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent12
        ForcedLodModel=1
        bForceMipStreaming=true
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Crate_004'
        Translation=(X=0.00,Y=0.00,Z=30.00)
        Rotation=(Pitch=0,Yaw=-11008,Roll=0)
    End Object
    Components.Add(StaticMeshComponent12)
    StaticMeshComponents.Add(StaticMeshComponent12)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent13
        ForcedLodModel=1
        bForceMipStreaming=true
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Crate_005'
        Translation=(X=-5.83,Y=-23.28,Z=20.00)
        Rotation=(Pitch=16384,Yaw=-255432,Roll=-262344)
    End Object
    Components.Add(StaticMeshComponent13)
    StaticMeshComponents.Add(StaticMeshComponent13)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent14
        ForcedLodModel=1
        bForceMipStreaming=true
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_002'
        Translation=(X=-4.14,Y=-32.98,Z=40.00)
        Rotation=(Pitch=0,Yaw=6912,Roll=0)
    End Object
    Components.Add(StaticMeshComponent14)
    StaticMeshComponents.Add(StaticMeshComponent14)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent15
        ForcedLodModel=1
        bForceMipStreaming=true
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_002'
        Translation=(X=-10.19,Y=-16.00,Z=65.00)
        Rotation=(Pitch=0,Yaw=-13568,Roll=16384)
    End Object
    Components.Add(StaticMeshComponent15)
    StaticMeshComponents.Add(StaticMeshComponent15)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent16
        ForcedLodModel=1
        bForceMipStreaming=true
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_002'
        Translation=(X=-3.39,Y=15.28,Z=65.00)
        Rotation=(Pitch=0,Yaw=-41216,Roll=16384)
    End Object
    Components.Add(StaticMeshComponent16)
    StaticMeshComponents.Add(StaticMeshComponent16)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent17
        ForcedLodModel=1
        bForceMipStreaming=true
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_005'
        Translation=(X=9.96,Y=39.77,Z=28.00)
        Rotation=(Pitch=0,Yaw=-42240,Roll=0)
    End Object
    Components.Add(StaticMeshComponent17)
    StaticMeshComponents.Add(StaticMeshComponent17)

    health=100
}

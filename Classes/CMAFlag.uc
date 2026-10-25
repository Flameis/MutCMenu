// Capture the Flag flag: a physical flag on a pole that anyone can pick up by walking over it. It rides on the carrier's
// back, is dropped on purpose with "mutate dropflag", and is dropped where its carrier dies, gets into a vehicle or leaves.
// It never despawns, goes back to where it was placed when the round restarts or it falls out of the map, and shows a beam
// so it can be found.
// Each flag belongs to one faction (Factions: US Army, USMC, DAK, ...), chosen when it is placed and kept whoever carries
// it. A team's faction comes from the map: its forces on a Vietnam map, its roles on a WW2 or Winter War map. Every flag
// material used here fits the game's own waving flag mesh (S_VN_Flag_*, the same mesh as WW2's S_Jap_flag), so only the
// material changes. WW2 and Winter War materials are loaded by name, so nothing here depends on those mods.
class CMAFlag extends Actor
    dependson(ROMapInfo);

// Indexes into Styles (the flag materials)
const STYLE_USA = 0;
const STYLE_SVN = 1;
const STYLE_PAVN = 2;
const STYLE_VC = 3;
const STYLE_AUS = 4;
const STYLE_SOVIET = 5;
const STYLE_WW2_USA = 6;
const STYLE_JAPAN = 7;
const STYLE_GERMANY = 8;
const STYLE_BRITAIN = 9;
const STYLE_ITALY = 10;
const STYLE_GERMANY_SWASTIKA = 11;
const STYLE_FINLAND = 12;
const STYLE_WW_USSR = 13;
const STYLE_FRANCE = 14;

// Indexes into Factions
const FAC_US_ARMY = 0;
const FAC_USMC = 1;
const FAC_AUS = 2;
const FAC_ARVN = 3;
const FAC_PAVN = 4;
const FAC_NLF = 5;
const FAC_WW2_US_ARMY = 6;
const FAC_WW2_USMC = 7;
const FAC_CW = 8;
const FAC_RED_ARMY = 9;
const FAC_NRA = 10;
const FAC_WEHRMACHT = 11;
const FAC_DAK = 12;
const FAC_FJ = 13;
const FAC_SS = 14;
const FAC_ITALY = 15;
const FAC_IJA = 16;
const FAC_SNLF = 17;
const FAC_FINLAND = 18;
const FAC_WW_RED_ARMY = 19;
const FAC_FRANCE = 20;

// Which game the map is from, by its roles
const MOD_VN = 0;
const MOD_WW2 = 1;
const MOD_WW = 2;

struct FlagStyleInfo
{
    var string MaterialPath;    // Loaded by name on every machine that draws the flag
    var string TexturePath;     // Optional: this texture is put on a copy of that material (the game's flag material, so
                                // WW2's own flag material, which doesn't draw on this mesh, isn't needed)
};

struct FactionInfo
{
    var string Label;           // In chat: "picked up the DAK flag"
    var string Keys;            // The names "--flag" accepts, separated by spaces
    var byte Style;
    var byte Mod;               // MOD_WW2 / MOD_WW: the flag's material is in that mod's packages (MutCMenu checks bLoad)
};

// A WW2 team's faction is the one most of its roles are tagged with (WW2RoleInfoAxis_DAK_Assault, ...)
struct RoleTag
{
    var string Tag;
    var int Faction;
};

var array<FlagStyleInfo>    Styles;
var array<FactionInfo>      Factions;
var array<RoleTag>          WW2AxisTags, WW2AlliesTags;

var repnotify Pawn          Carrier;
var repnotify byte          FlagStyle;
var repnotify bool          bShowBeam;

// For spectators' maps (MutCMenu's map Interaction), which show every flag and what is happening to it. The carrier's
// player info, because the carrier's pawn may be too far away for a spectator's game to know it.
var int                     Faction;
var PlayerReplicationInfo   CarrierPRI;
var bool                    bAtHome;        // Where it was placed (and not moved since)

// Server-side
var int                     PlacerID;       // The PlayerID of whoever placed it (-1 when not known), for the per-player flag limit
var MutCMenu                MyMut;          // Its bCTFSilent decides whether pickups and drops are announced
var vector                  HomeLocation;
var vector                  LastCarrierLocation;
var Pawn                    LastDropper;
var float                   NoPickupUntil, DropperNoPickupUntil;

var float                   PickupRadius, PickupHeight;     // Unreal units around the flag a player has to walk into
var float                   DropperDelay;                   // Seconds before whoever dropped it can take it back
var name                    CarryBone;
var float                   CarryBehind;                    // How far behind the carry bone the pole stands

var SkeletalMeshComponent   FlagMesh;
var StaticMeshComponent     PoleMesh, BeamMesh;

replication
{
    if (bNetDirty && Role == ROLE_Authority)
        Carrier, FlagStyle, bShowBeam, Faction, CarrierPRI, bAtHome;
}

simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if (Role == ROLE_Authority)
    {
        HomeLocation = Location;
        bAtHome = true;
        SetTimer(0.2, true, 'CheckPickup');
    }
}

simulated event ReplicatedEvent(name VarName)
{
    if (VarName == 'Carrier')
        CarrierChanged();
    else if (VarName == 'FlagStyle')
        ApplyStyle();
    else if (VarName == 'bShowBeam')
        BeamMesh.SetHidden(!bShowBeam);
    else
        super.ReplicatedEvent(VarName);
}

// ====================================================
// Looks
// ====================================================
simulated function ApplyStyle()
{
    local MaterialInterface M;
    local MaterialInstanceConstant FlagMIC;
    local Texture2D FlagTexture;

    if (WorldInfo.NetMode == NM_DedicatedServer || FlagStyle >= Styles.Length)
        return;

    M = MaterialInterface(DynamicLoadObject(Styles[FlagStyle].MaterialPath, class'MaterialInterface', true));
    if (M == None)
        `log("[CMenu] CTF flag: could not load "$Styles[FlagStyle].MaterialPath$", showing the default flag");

    // A flag that is only a texture: the game's flag material with that texture as its cloth
    if (M != None && Styles[FlagStyle].TexturePath != "")
    {
        FlagTexture = Texture2D(DynamicLoadObject(Styles[FlagStyle].TexturePath, class'Texture2D', true));
        if (FlagTexture != None)
        {
            FlagMIC = new class'MaterialInstanceConstant';
            FlagMIC.SetParent(M);
            FlagMIC.SetTextureParameterValue('DiffuseMap', FlagTexture);
            M = FlagMIC;
        }
        else
            `log("[CMenu] CTF flag: could not load "$Styles[FlagStyle].TexturePath$", showing the US flag");
    }
    FlagMesh.SetMaterial(0, M); // None puts the mesh's own material back
}

// The faction it is placed for decides the flag it shows for good
function SetFaction(int NewFaction)
{
    Faction = Clamp(NewFaction, 0, Factions.Length - 1);
    FlagStyle = Factions[Faction].Style;
    ApplyStyle();
}

function string Label()
{
    return Factions[Faction].Label;
}

function SetBeam(bool bShow)
{
    bShowBeam = bShow;
    BeamMesh.SetHidden(!bShowBeam);
}

// ====================================================
// Factions (static: the CMenu Builder uses them on the client to label its entries)
// ====================================================
// The faction "--flag Name" asks for, or -1
static function int FindFaction(string FlagName)
{
    local array<string> Keys;
    local int i, k;

    for (i = 0; i < default.Factions.Length; i++)
    {
        Keys = SplitString(default.Factions[i].Keys, " ", true);
        for (k = 0; k < Keys.Length; k++)
        {
            if (Keys[k] ~= FlagName)
                return i;
        }
    }
    return -1;
}

// Every name "--flag" accepts, for the usage message
static function string FactionNames()
{
    local array<string> Keys;
    local string S;
    local int i;

    for (i = 0; i < default.Factions.Length; i++)
    {
        Keys = SplitString(default.Factions[i].Keys, " ", true);
        S = S$(i > 0 ? ", " : "")$Keys[0];
    }
    return S;
}

// WW2 and Winter War maps carry those mods' roles, so a mod's flags are only picked for a team when the mod is running
static function int ModOfMap(WorldInfo WI)
{
    local ROMapInfo ROMI;
    local int i;

    ROMI = ROMapInfo(WI.GetMapInfo());
    if (ROMI == None)
        return MOD_VN;

    for (i = 0; i < ROMI.NorthernRoles.Length; i++)
    {
        if (ROMI.NorthernRoles[i].RoleInfoClass == None)
            continue;
        if (InStr(string(ROMI.NorthernRoles[i].RoleInfoClass.Name), "WW2RoleInfo",, true) == 0)
            return MOD_WW2;
        if (InStr(string(ROMI.NorthernRoles[i].RoleInfoClass.Name), "WWRoleInfo",, true) == 0)
            return MOD_WW;
    }
    return MOD_VN;
}

// What the teams are called: North/South, Axis/Allies on WW2 maps, Finnish/Soviet on Winter War maps
static function string TeamWord(WorldInfo WI, int Team)
{
    switch (ModOfMap(WI))
    {
        case MOD_WW2:
            return (Team == `AXIS_TEAM_INDEX) ? "Axis" : "Allies";
        case MOD_WW:
            return (Team == `AXIS_TEAM_INDEX) ? "Finnish" : "Soviet";
    }
    return (Team == `AXIS_TEAM_INDEX) ? "North" : "South";
}

static function int FactionForTeam(WorldInfo WI, int Team)
{
    local ROMapInfo ROMI;
    local bool bNorth;

    ROMI = ROMapInfo(WI.GetMapInfo());
    bNorth = (Team == `AXIS_TEAM_INDEX);

    switch (ModOfMap(WI))
    {
        case MOD_WW2:
            if (bNorth)
                return MostTagged(RoleNames(ROMI.NorthernRoles), default.WW2AxisTags, FAC_WEHRMACHT);
            return MostTagged(RoleNames(ROMI.SouthernRoles), default.WW2AlliesTags, FAC_WW2_US_ARMY);
        case MOD_WW:
            return bNorth ? FAC_FINLAND : FAC_WW_RED_ARMY;
    }

    if (ROMI == None)
        return bNorth ? FAC_PAVN : FAC_US_ARMY;
    if (bNorth)
        return (ROMI.NorthernForce == NFOR_NLF) ? FAC_NLF : FAC_PAVN;
    switch (ROMI.SouthernForce)
    {
        case SFOR_USMC:
            return FAC_USMC;
        case SFOR_AusArmy:
            return FAC_AUS;
        case SFOR_ARVN:
            return FAC_ARVN;
    }
    return FAC_US_ARMY;
}

static function array<string> RoleNames(array<RORoleCount> Roles)
{
    local array<string> Names;
    local int i;

    for (i = 0; i < Roles.Length; i++)
    {
        if (Roles[i].RoleInfoClass != None)
            Names.AddItem(string(Roles[i].RoleInfoClass.Name));
    }
    return Names;
}

// The faction whose tag the most roles carry. Maps share roles between factions (a DAK map uses Wehrmacht riflemen next
// to its DAK roles, and the tank crew roles are added to every map), so this goes by the most roles, ties to the first.
static function int MostTagged(array<string> Names, array<RoleTag> Tags, int Fallback)
{
    local int i, t, Best, BestCount;
    local array<int> Counts;

    Counts.Length = Tags.Length;
    for (i = 0; i < Names.Length; i++)
    {
        for (t = 0; t < Tags.Length; t++)
        {
            if (InStr(Names[i], Tags[t].Tag,, true) != -1)
                Counts[t]++;
        }
    }

    Best = Fallback;
    for (t = 0; t < Tags.Length; t++)
    {
        if (Counts[t] > BestCount)
        {
            BestCount = Counts[t];
            Best = Tags[t].Faction;
        }
    }
    return Best;
}

// ====================================================
// Picking up and carrying
// ====================================================
function CheckPickup()
{
    local Pawn P;

    if (Carrier != None || WorldInfo.TimeSeconds < NoPickupUntil)
        return;

    foreach WorldInfo.AllPawns(class'Pawn', P, Location, PickupRadius + PickupHeight)
    {
        if (CanPickUp(P))
        {
            PickUp(P);
            return;
        }
    }
}

function bool CanPickUp(Pawn P)
{
    local CMAFlag Other;
    local vector Offset;

    if (ROPawn(P) == None || !CanKeepCarrying(P))
        return false;
    if (P == LastDropper && WorldInfo.TimeSeconds < DropperNoPickupUntil)
        return false;

    Offset = P.Location - Location;
    if (Abs(Offset.Z) > PickupHeight)
        return false;
    Offset.Z = 0;
    if (VSize(Offset) > PickupRadius)
        return false;

    // One flag per player
    foreach DynamicActors(class'CMAFlag', Other)
    {
        if (Other.Carrier == P)
            return false;
    }
    return true;
}

// Alive, on foot and still controlled. A pawn that got into a vehicle has no controller and a DrivenVehicle
function bool CanKeepCarrying(Pawn P)
{
    return P != None && !P.bDeleteMe && P.Health > 0 && P.Controller != None && P.DrivenVehicle == None
        && P.PlayerReplicationInfo != None;
}

function PickUp(Pawn P)
{
    Carrier = P;
    CarrierPRI = P.PlayerReplicationInfo;
    bAtHome = false;
    LastCarrierLocation = P.Location;
    SetPhysics(PHYS_None);
    Velocity = vect(0, 0, 0);
    CarrierChanged();
    FollowCarrier();
    Announce(P.PlayerReplicationInfo.PlayerName$" picked up the "$Label()$" flag");
}

// Runs on the server and every client. The carrier owns the flag, so its owner-no-see parts are hidden from the carrier's
// own view. The render proxy caches the owner, so the parts are reattached to pick it up.
simulated function CarrierChanged()
{
    SetOwner(Carrier);
    bCollideWorld = (Carrier == None); // While carried it is placed every frame and must never get stuck on walls
    ReattachComponent(FlagMesh);
    ReattachComponent(PoleMesh);
    ReattachComponent(BeamMesh);
}

simulated event Tick(float DeltaTime)
{
    super.Tick(DeltaTime);

    if (Carrier == None)
        return;

    if (Role == ROLE_Authority && !CanKeepCarrying(Carrier))
    {
        Drop(false);
        return;
    }
    FollowCarrier();
}

// Upright behind the carrier's upper back, cloth trailing. Clients use the animated bone; a dedicated server doesn't
// animate meshes, so it uses the pawn's position (only the drop point depends on it there).
simulated function FollowCarrier()
{
    local vector Loc, X, Y, Z;
    local rotator Facing;

    if (Carrier == None || Carrier.bDeleteMe)
        return;

    Facing.Yaw = Carrier.Rotation.Yaw;
    GetAxes(Facing, X, Y, Z);

    Loc = Carrier.Location + vect(0, 0, 30);
    if (WorldInfo.NetMode != NM_DedicatedServer && Carrier.Mesh != None && Carrier.Mesh.MatchRefBone(CarryBone) != INDEX_NONE)
        Loc = Carrier.Mesh.GetBoneLocation(CarryBone);

    LastCarrierLocation = Carrier.Location;
    SetLocation(Loc - X * CarryBehind);
    Facing.Yaw += 32768;
    SetRotation(Facing);
}

// ====================================================
// Dropping
// ====================================================
// bThrow: dropped on purpose, so it is tossed forward. Otherwise it falls where the carrier was
function Drop(optional bool bThrow)
{
    local Pawn P;
    local vector X, Y, Z;
    local rotator Facing;
    local string Who;

    P = Carrier;
    if (P == None)
        return;

    if (!P.bDeleteMe)
    {
        LastCarrierLocation = P.Location;
        Facing.Yaw = P.Rotation.Yaw;
        if (P.PlayerReplicationInfo != None)
            Who = P.PlayerReplicationInfo.PlayerName;
    }

    Carrier = None;
    CarrierPRI = None;
    CarrierChanged();
    LastDropper = P;
    DropperNoPickupUntil = WorldInfo.TimeSeconds + DropperDelay;
    NoPickupUntil = WorldInfo.TimeSeconds + 0.5;

    SetLocation(LastCarrierLocation);
    SetRotation(Facing);
    GetAxes(Facing, X, Y, Z);
    Velocity = bThrow ? (X * 250 + vect(0, 0, 200)) : vect(0, 0, 100);
    SetPhysics(PHYS_Falling);

    Announce((Who != "" ? Who : "The carrier")$" dropped the "$Label()$" flag");
}

simulated event Landed(vector HitNormal, Actor FloorActor)
{
    SetPhysics(PHYS_None);
    Velocity = vect(0, 0, 0);
}

// Back to where it was placed. Used by "mutate resetflags" and when the round restarts.
function ReturnHome()
{
    if (Carrier != None)
    {
        Carrier = None;
        CarrierChanged();
    }
    CarrierPRI = None;
    bAtHome = true;
    LastDropper = None;
    NoPickupUntil = WorldInfo.TimeSeconds + 1.0;
    SetLocation(HomeLocation);
    Velocity = vect(0, 0, 0);
    SetPhysics(PHYS_Falling);
}

function Reset()
{
    ReturnHome();
}

// Never lost: falling out of the map or into a kill volume sends it home instead of destroying it
simulated event FellOutOfWorld(class<DamageType> dmgType)
{
    if (Role == ROLE_Authority)
        ReturnHome();
}

simulated event OutsideWorldBounds()
{
    if (Role == ROLE_Authority)
        ReturnHome();
}

simulated function VolumeBasedDestroy(PhysicsVolume PV)
{
    if (Role == ROLE_Authority)
        ReturnHome();
}

function Announce(string Msg)
{
    if (MyMut != None)
        MyMut.FlagAnnounce(Msg);
    else
        WorldInfo.Game.Broadcast(self, "[CMenu] "$Msg);
}

defaultproperties
{
    Styles(STYLE_USA)=(MaterialPath="ENV_VN_Flags.Materials.ActiveFlags.M_VN_Flag_USA")
    Styles(STYLE_SVN)=(MaterialPath="ENV_VN_Flags.Materials.ActiveFlags.M_VN_Flag_SVN")
    Styles(STYLE_PAVN)=(MaterialPath="ENV_VN_Flags.Materials.ActiveFlags.M_VN_Flag_PAVN")
    Styles(STYLE_VC)=(MaterialPath="ENV_VN_Flags.Materials.ActiveFlags.M_VN_Flag_VC")
    Styles(STYLE_AUS)=(MaterialPath="ENV_VN_Flags.Materials.ActiveFlags.M_VN_Flag_Aus")
    Styles(STYLE_SOVIET)=(MaterialPath="ENV_VN_Flags.Materials.ActiveFlags.M_VN_Flag_Soviet")
    Styles(STYLE_WW2_USA)=(MaterialPath="ENV_VN_Flags.Materials.ActiveFlags.M_VN_Flag_USA",TexturePath="ENV_RS_Japanese_Flag.Textures.T_USflag_D")
    Styles(STYLE_JAPAN)=(MaterialPath="ENV_VN_Flags.Materials.ActiveFlags.M_VN_Flag_USA",TexturePath="ENV_RS_Japanese_Flag.Textures.T_japflag_DOT_D")
    // The regular army: the Iron Cross war flag. Like the WW2 US and Japanese flags it is only a texture, put on the game's own flag
    Styles(STYLE_GERMANY)=(MaterialPath="ENV_VN_Flags.Materials.ActiveFlags.M_VN_Flag_USA",TexturePath="WFGameCustom.InGame.T_GERflag_D")
    Styles(STYLE_BRITAIN)=(MaterialPath="ENV_DF_Flag.MIC.M_DD_Flag_British")
    Styles(STYLE_ITALY)=(MaterialPath="ENV_DF_Apollonia.MIC.M_DF_Flag_Italy")
    // SS and Fallschirmjager: the swastika national flag from the DAK maps. The other swastika flags in ENV_DF_Flag
    // (M_Flag_GER, M_Flag_Ger_War, M_Flag_Ger_National) use the mask and wave map of WW2's static flag meshes, which
    // don't fit this mesh.
    Styles(STYLE_GERMANY_SWASTIKA)=(MaterialPath="ENV_DF_Flag.MIC.M_DF_Flag_DAK")
    Styles(STYLE_FINLAND)=(MaterialPath="WinterWar_ENV_Flags.MIC.Flag_Finland")
    Styles(STYLE_WW_USSR)=(MaterialPath="WinterWar_ENV_Flags.MIC.Flag_USSR")
    Styles(STYLE_FRANCE)=(MaterialPath="ENV_VN_Flags.Materials.ActiveFlags.M_VN_Flag_French")

    // The first name in Keys is the one listed in the usage message. Style, Mod and Faction are the numbers of the STYLE_,
    // MOD_ and FAC_ constants at the top (constants are not allowed inside struct values here).
    Factions(FAC_US_ARMY)=(Label="US Army",Keys="usarmy us usa",Style=0)
    Factions(FAC_USMC)=(Label="USMC",Keys="usmc marines",Style=0)
    Factions(FAC_AUS)=(Label="Australian Army",Keys="aus australia australian",Style=4)
    Factions(FAC_ARVN)=(Label="ARVN",Keys="arvn southvietnam svn",Style=1)
    Factions(FAC_PAVN)=(Label="PAVN",Keys="pavn nva northvietnam",Style=2)
    Factions(FAC_NLF)=(Label="NLF",Keys="nlf vc vietcong",Style=3)
    Factions(FAC_WW2_US_ARMY)=(Label="US Army",Keys="usarmy48 us48 ww2us",Style=6,Mod=1)
    Factions(FAC_WW2_USMC)=(Label="USMC",Keys="usmc48 ww2usmc",Style=6,Mod=1)
    Factions(FAC_CW)=(Label="Commonwealth",Keys="cw commonwealth british britain uk",Style=9,Mod=1)
    Factions(FAC_RED_ARMY)=(Label="Red Army",Keys="redarmy soviet sov ussr",Style=5)
    Factions(FAC_NRA)=(Label="NRA",Keys="nra chinese china",Style=6,Mod=1) // The game files have no Chinese flag
    Factions(FAC_WEHRMACHT)=(Label="Wehrmacht",Keys="wehrmacht wh heer german germany",Style=8,Mod=1)
    Factions(FAC_DAK)=(Label="DAK",Keys="dak afrikakorps",Style=8,Mod=1)
    Factions(FAC_FJ)=(Label="Fallschirmjaeger",Keys="fallschirmjaeger fallschirmjager fj fmj",Style=11,Mod=1)
    Factions(FAC_SS)=(Label="SS",Keys="ss",Style=11,Mod=1)
    Factions(FAC_ITALY)=(Label="Italian Army",Keys="italy italian ita",Style=10,Mod=1)
    Factions(FAC_IJA)=(Label="IJA",Keys="ija japan japanese",Style=7,Mod=1)
    Factions(FAC_SNLF)=(Label="SNLF",Keys="snlf",Style=7,Mod=1)
    Factions(FAC_FINLAND)=(Label="Finnish Army",Keys="finland finnish fin",Style=12,Mod=2)
    Factions(FAC_WW_RED_ARMY)=(Label="Red Army",Keys="wwredarmy wwsoviet wwussr",Style=13,Mod=2)
    Factions(FAC_FRANCE)=(Label="French Army",Keys="france french",Style=14)

    // WW2 role class names: WW2RoleInfoAxis_DAK_Assault, WW2RoleInfoAllies_USMC_Rifleman, ...
    WW2AxisTags(0)=(Tag="Axis_WH",Faction=11)
    WW2AxisTags(1)=(Tag="Axis_DAK",Faction=12)
    WW2AxisTags(2)=(Tag="Axis_FMJ",Faction=13)
    WW2AxisTags(3)=(Tag="Axis_SS",Faction=14)
    WW2AxisTags(4)=(Tag="Axis_ITA",Faction=15)
    WW2AxisTags(5)=(Tag="Axis_IJA",Faction=16)
    WW2AxisTags(6)=(Tag="Axis_SNLF",Faction=17)
    WW2AlliesTags(0)=(Tag="Allies_USA",Faction=6)
    WW2AlliesTags(1)=(Tag="Allies_USMC",Faction=7)
    WW2AlliesTags(2)=(Tag="Allies_CW",Faction=8)
    WW2AlliesTags(3)=(Tag="Allies_AUS",Faction=2)
    WW2AlliesTags(4)=(Tag="Allies_Sov",Faction=9)
    WW2AlliesTags(5)=(Tag="Allies_NRA",Faction=10)

    PickupRadius=60
    PickupHeight=100
    DropperDelay=3.0
    CarryBone=CHR_Spine3
    CarryBehind=14

    bShowBeam=true

    // Only world geometry stops it: players walk through it and it doesn't stop bullets
    Begin Object Class=CylinderComponent Name=CollisionCylinder
        CollisionRadius=10
        CollisionHeight=40
        CollideActors=false
        BlockActors=false
        BlockZeroExtent=false
        BlockNonZeroExtent=false
        BlockRigidBody=false
    End Object
    CollisionComponent=CollisionCylinder
    Components.Add(CollisionCylinder)

    Begin Object Class=DynamicLightEnvironmentComponent Name=FlagLightEnvironment
        bDynamic=true
    End Object
    Components.Add(FlagLightEnvironment)

    // The game's flagpole flag is 1024 x 680 units, with the pole edge at X=0 and the middle at Z=0. At 0.05 it is about
    // 1 m x 0.7 m, hung from near the top of the pole. The cloth runs along +X, which faces backwards while carried.
    Begin Object Class=SkeletalMeshComponent Name=FlagCloth
        SkeletalMesh=SkeletalMesh'ENV_VN_Flags.Meshes.S_VN_Flag_USA'
        ForcedLodModel=1
        bForceMipStreaming=true
        Translation=(X=1,Y=0,Z=40)
        Scale=0.05
        LightEnvironment=FlagLightEnvironment
        bOwnerNoSee=true
        CastShadow=false
        CollideActors=false
        BlockActors=false
        BlockZeroExtent=false
        BlockNonZeroExtent=false
        BlockRigidBody=false
        bAcceptsDynamicDecals=false
        bUpdateSkelWhenNotRendered=false
    End Object
    FlagMesh=FlagCloth
    Components.Add(FlagCloth)

    // The pole's origin is near its top: at 0.4 it runs from the bottom of the collision (Z=-40) to Z=60
    Begin Object Class=StaticMeshComponent Name=FlagPole
        StaticMesh=StaticMesh'ENV_VN_Flags.Meshes.S_VN_Flagpole'
        ForcedLodModel=1
        bForceMipStreaming=true
        Translation=(X=0,Y=0,Z=45)
        Scale=0.4
        LightEnvironment=FlagLightEnvironment
        bOwnerNoSee=true
        CastShadow=false
        CollideActors=false
        BlockActors=false
        BlockZeroExtent=false
        BlockNonZeroExtent=false
        BlockRigidBody=false
        bAcceptsDynamicDecals=false
    End Object
    PoleMesh=FlagPole
    Components.Add(FlagPole)

    // The commander's map-mark beam, standing on top of the pole
    Begin Object Class=StaticMeshComponent Name=FlagBeam
        StaticMesh=StaticMesh'FX_VN_Materials.Commander.S_ENV_CommanderMark_Beam'
        Translation=(X=0,Y=0,Z=60)
        bOwnerNoSee=true
        CastShadow=false
        CollideActors=false
        BlockActors=false
        BlockZeroExtent=false
        BlockNonZeroExtent=false
        BlockRigidBody=false
        TranslucencySortPriority=9999
    End Object
    BeamMesh=FlagBeam
    Components.Add(FlagBeam)

    RemoteRole=ROLE_SimulatedProxy
    bAlwaysRelevant=true
    bReplicateMovement=true
    bUpdateSimulatedPosition=true
    bGameRelevant=true
    bCollideActors=false
    bBlockActors=false
    bCollideWorld=true
    bNoDelete=false
    NetUpdateFrequency=10
    TickGroup=TG_PostAsyncWork
}

// The Capture the Flag flag as an inventory item, for a flag placed with Flag Item In Inventory (--place). Its carrier
// gets one when they pick the flag up: selected like an engineer's ammo crate, it shows a preview pole where the flag
// will stand (the game's own placing checks: flat ground, room, not prone), and a click plants the flag there
// (CMAFlag.Plant). Then the item is gone from the inventory, as a placed trap is. If the flag leaves the carrier any
// other way (thrown with the drop key, dropped on death, sent home) the flag takes the item away (CMAFlag.RemoveItem).
// Built like MutExtras' fortification kit (ACItem_FortificationKit), with the ammo crate item's arms and animations,
// copied here because MutCMenu is compiled before MutExtras.
class CMItem_CTFFlag extends ROItem_PlaceableAmmoCrate;

var CMAFlag Flag;                   // Server: the flag this item plants
var string IconPath;                // Its picture in the inventory and weapon boxes (MutCMenuContent, see Content\README.md)
var vector PoleOffset;              // From the flag's foot to the pole mesh's origin, so the preview stands on the ground
var float PoleScale;

// A static preview of the flag's pole, not the crate. (The crate's own PostBeginPlay destroys the item in the shipped game.)
simulated function PostBeginPlay()
{
    ReferenceSkeletalMesh = None;
    ReferenceStaticMesh = class'CMAFlag'.default.PoleMesh.StaticMesh;
    MinDistFromOtherAmmoCratesSq = 0;
    super(ROItemPlaceable).PostBeginPlay();
    if (PreviewStaticMesh != None)
        PreviewStaticMesh.SetScale(PoleScale);
    AddHUDIcon();
}

// The game's HUD finds an item's picture in its own list by class, first match wins, so without this the item would show
// the ammo crate's. The flag's picture goes at the front of the list on this player's HUD (once). Without the content
// package nothing is added and the slot shows the crate's picture.
simulated function AddHUDIcon()
{
    local ROPlayerController PC;
    local ROHUDWidget.ROWeaponUV UV;
    local Texture2D Icon;
    local int i;

    if (WorldInfo.NetMode == NM_DedicatedServer)
        return;
    foreach LocalPlayerControllers(class'ROPlayerController', PC)
    {
        if (PC.myROHUD == None)
            continue;
        for (i = 0; i < PC.myROHUD.WeaponUVs.Length; i++)
        {
            if (PC.myROHUD.WeaponUVs[i].WeaponClass == Class.Name)
                return;
        }
        if (Icon == None)
            Icon = Texture2D(DynamicLoadObject(IconPath, class'Texture2D', true));
        if (Icon == None)
            return;
        UV.WeaponClass = Class.Name;
        UV.WeaponTexture = Icon;
        UV.KillMessageWidth = 128;
        UV.KillMessageHeight = 64;
        PC.myROHUD.WeaponUVs.InsertItem(0, UV);
    }
}

// The ground under the placing spot (PlaceLoc is lifted by PlaceOffset for the game's checks)
simulated function vector FlagSpot()
{
    return PlaceLoc - vect(0, 0, 1) * PlaceOffset;
}

simulated function UpdatePreviewMesh()
{
    if (Instigator == None || PreviewStaticMesh == None)
        return;
    PreviewStaticMesh.SetTranslation(FlagSpot() + PoleOffset);
    PreviewStaticMesh.SetRotation(PlaceRot);
    if (PreviewMeshMIC != None)
        PreviewMeshMIC.SetVectorParameterValue('color', bLastCheckSuccessful ? GoodPlacementColour : BadPlacementColour);
}

simulated exec function IronSights(){}

simulated function BeginFire(byte FireModeNum)
{
    if (FireModeNum > DEFAULT_FIREMODE || Instigator == None || Instigator.Controller == None)
        return;
    TeamIdx = Min(Instigator.Controller.GetTeamNum(), 1);
    ArmsAnimSet = ArmsAnimSets[TeamIdx];
    super(ROItemPlaceable).BeginFire(FireModeNum);
}

// Only the game's own placing checks (ground, slope, room); none of the ammo crate's (one each, 30 m apart)
simulated function bool CanPlace(optional bool bIsInitialCheck = true)
{
    return super(ROItemPlaceable).CanPlace(bIsInitialCheck);
}

// No crate opening in the world while placing
simulated function StartPlacingItem()
{
    GotoState('PlacingItem');
}

// Plants the flag; the item is then taken out of the inventory by SpawnPlaceable
function bool DoActualSpawn()
{
    if (Flag == None || Flag.bDeleteMe || Instigator == None || !Flag.IsCarriedBy(Instigator))
        return false;
    // The flag must not take this item away itself while it is being placed
    Flag.FlagItem = None;
    if (Flag.Plant(FlagSpot()))
        return true;
    Flag.FlagItem = self;
    return false;
}

defaultproperties
{
    WeaponContentClass(0)="MutCMenu.CMItem_CTFFlag"
    RoleSelectionImage(0)=Texture2D'VN_UI_Textures.menu.ProfileStats.class_icon_large_mg'
    IconPath="MutCMenuContent.UI.UI_HUD_WeaponSelect_CTFFlag"
    // Its names and description are in MutCMenu.int ([CMItem_CTFFlag]): they are localized properties

    Category=ROIC_PlaceableEquipment
    Weight=0
    InventoryWeight=0
    bCanThrow=false
    DroppedPickupClass=None
    DroppedPickupMesh=None
    PickupFactoryMesh=None
    ClassConstructorProxy=None
    MinDistFromOtherAmmoCrates=0

    // The pole at the flag's own size: at 0.4 its origin is 85 units above the foot (see CMAFlag's FlagPole)
    PoleOffset=(X=0,Y=0,Z=85)
    PoleScale=0.4

    Begin Object Name=FirstPersonMesh
        DepthPriorityGroup=SDPG_Foreground
        SkeletalMesh=SkeletalMesh'WP_VN_VC_PunjiTrap.Mesh.VC_PunjiTrap'
        PhysicsAsset=PhysicsAsset'WP_VN_VC_PunjiTrap.Phys.VC_PunjiTrap_Physics'
        AnimSets(0)=AnimSet'WP_VN_Resupply_Crates.Animation.WP_VC_ResupplyHands'
        AnimSets(1)=AnimSet'WP_VN_Resupply_Crates.Animation.WP_US_ResupplyHands'
        AnimTreeTemplate=AnimTree'WP_VN_VC_PunjiTrap.Animation.VC_PunjiTrap_Tree'
        Scale=1.0
        FOV=70
    End Object

    AttachmentClass=class'ROGameContent.ROItemAttach_PlaceableAmmoCrate'

    ArmsAnimSets[0]=AnimSet'WP_VN_Resupply_Crates.Animation.WP_VC_ResupplyHands'
    ArmsAnimSets[1]=AnimSet'WP_VN_Resupply_Crates.Animation.WP_US_ResupplyHands'
    ArmsAnimSet=AnimSet'WP_VN_Resupply_Crates.Animation.WP_VC_ResupplyHands'
}

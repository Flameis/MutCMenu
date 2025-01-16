class CMAResupplyPoint extends CMAStaticMesh;

var ROVolumeAmmoResupply AmmoResupplyVolume;
var BrushComponent ColComp;

var array<StaticMeshComponent> StaticMeshComponents;

function PreBeginPlay()
{
    Super.PreBeginPlay();

    AmmoResupplyVolume = Spawn(class'ROVolumeAmmoResupply', self);
    AmmoResupplyVolume.SetLocation(self.Location);

	AmmoResupplyVolume.CollisionComponent = ColComp;
    AmmoResupplyVolume.Activate();
}

defaultproperties
{
    Begin Object class=BrushComponent Name=ColCompDefault
        Bounds=(Origin=(X=0.0,Y=0.0,Z=0.0),BoxExtent=(X=100.0,Y=100.0,Z=100.0),SphereRadius=0.0)
    End Object
    ColComp=ColCompDefault
    Components.Add(ColCompDefault)

    Begin Object Name=StaticMeshComponent0
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Crate_001'
        Translation=(X=0.00,Y=0.00,Z=0.00)
        Rotation=(Pitch=0,Yaw=6912,Roll=0)
    End Object
    Components.Add(StaticMeshComponent0)
    StaticMeshComponents.Add(StaticMeshComponent0)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent2
        StaticMesh=StaticMesh'ENV_VN_Barrels.Meshes.S_Pallet'
        Translation=(X=17.38,Y=-1.59,Z=-11.50)
        Rotation=(Pitch=0,Yaw=4864,Roll=0)
    End Object
    Components.Add(StaticMeshComponent2)
    StaticMeshComponents.Add(StaticMeshComponent2)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent3
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_004'
        Translation=(X=18.41,Y=-45.84,Z=0.00)
        Rotation=(Pitch=0,Yaw=-9984,Roll=0)
    End Object
    Components.Add(StaticMeshComponent3)
    StaticMeshComponents.Add(StaticMeshComponent3)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent4
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_002'
        Translation=(X=22.05,Y=-35.42,Z=0.00)
        Rotation=(Pitch=0,Yaw=20224,Roll=0)
    End Object
    Components.Add(StaticMeshComponent4)
    StaticMeshComponents.Add(StaticMeshComponent4)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent5
        StaticMesh=StaticMesh'ENV_VN_US_HOW_Ammo.Meshes.Wood.S_HOW_AmmoCrate_cls'
        Translation=(X=41.36,Y=3.56,Z=0.00)
        Rotation=(Pitch=0,Yaw=-43776,Roll=0)
    End Object
    Components.Add(StaticMeshComponent5)
    StaticMeshComponents.Add(StaticMeshComponent5)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent6
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_001'
        Translation=(X=42.68,Y=-6.57,Z=15.00)
        Rotation=(Pitch=0,Yaw=-9984,Roll=0)
    End Object
    Components.Add(StaticMeshComponent6)
    StaticMeshComponents.Add(StaticMeshComponent6)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent7
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_001'
        Translation=(X=44.15,Y=28.11,Z=18.00)
        Rotation=(Pitch=0,Yaw=-42240,Roll=16384)
    End Object
    Components.Add(StaticMeshComponent7)
    StaticMeshComponents.Add(StaticMeshComponent7)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent8
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_002'
        Translation=(X=23.43,Y=23.35,Z=28.00)
        Rotation=(Pitch=0,Yaw=3328,Roll=0)
    End Object
    Components.Add(StaticMeshComponent8)
    StaticMeshComponents.Add(StaticMeshComponent8)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent9
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_006'
        Translation=(X=25.31,Y=32.41,Z=0.00)
        Rotation=(Pitch=0,Yaw=-11520,Roll=0)
    End Object
    Components.Add(StaticMeshComponent9)
    StaticMeshComponents.Add(StaticMeshComponent9)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent10
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_004'
        Translation=(X=30.77,Y=40.65,Z=28.00)
        Rotation=(Pitch=0,Yaw=-11520,Roll=0)
    End Object
    Components.Add(StaticMeshComponent10)
    StaticMeshComponents.Add(StaticMeshComponent10)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent11
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_003'
        Translation=(X=11.90,Y=35.16,Z=42.00)
        Rotation=(Pitch=0,Yaw=1792,Roll=0)
    End Object
    Components.Add(StaticMeshComponent11)
    StaticMeshComponents.Add(StaticMeshComponent11)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent12
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Crate_004'
        Translation=(X=0.00,Y=0.00,Z=30.00)
        Rotation=(Pitch=0,Yaw=-11008,Roll=0)
    End Object
    Components.Add(StaticMeshComponent12)
    StaticMeshComponents.Add(StaticMeshComponent12)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent13
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Crate_005'
        Translation=(X=-5.83,Y=-23.28,Z=20.00)
        Rotation=(Pitch=16384,Yaw=-255432,Roll=-262344)
    End Object
    Components.Add(StaticMeshComponent13)
    StaticMeshComponents.Add(StaticMeshComponent13)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent14
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_002'
        Translation=(X=-4.14,Y=-32.98,Z=40.00)
        Rotation=(Pitch=0,Yaw=6912,Roll=0)
    End Object
    Components.Add(StaticMeshComponent14)
    StaticMeshComponents.Add(StaticMeshComponent14)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent15
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_002'
        Translation=(X=-10.19,Y=-16.00,Z=65.00)
        Rotation=(Pitch=0,Yaw=-13568,Roll=16384)
    End Object
    Components.Add(StaticMeshComponent15)
    StaticMeshComponents.Add(StaticMeshComponent15)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent16
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_002'
        Translation=(X=-3.39,Y=15.28,Z=65.00)
        Rotation=(Pitch=0,Yaw=-41216,Roll=16384)
    End Object
    Components.Add(StaticMeshComponent16)
    StaticMeshComponents.Add(StaticMeshComponent16)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent17
        StaticMesh=StaticMesh'ENV_VN_US_M60_Ammo.Meshes.S_M60_Ammo_Box_005'
        Translation=(X=9.96,Y=39.77,Z=28.00)
        Rotation=(Pitch=0,Yaw=-42240,Roll=0)
    End Object
    Components.Add(StaticMeshComponent17)
    StaticMeshComponents.Add(StaticMeshComponent17)

    health=100
}

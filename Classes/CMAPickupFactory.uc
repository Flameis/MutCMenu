class CMAPickupFactory extends ROPickupFactory;

var repnotify class<ROWeapon> WPClass;
var float Time;

replication
{
	if (bNetDirty && (Role == ROLE_Authority))
		WPClass, Time;
}

simulated event ReplicatedEvent(name VarName)
{
	if (VarName == 'WPClass')
	{
		InitializePickup();
	}
}

simulated function InitializePickup()
{
	WeaponPickupClass = WPClass;
	InventoryType = WPClass;
	RespawnTime = Time;
	SetPickupMesh();

	if( WorldInfo.NetMode != NM_DedicatedServer )
	{
		PickupMesh.SetLightEnvironment( MyLightEnvironment );
	}

	if( WorldInfo.NetMode == NM_DedicatedServer )
	{
		DetachComponent(MyLightEnvironment);
	}

    SetCollision(true,true);
    EnablePickup();
	SetPickupVisible();

    `log(WeaponPickupClass);
    `log(InventoryType);
    `log(PreviewMesh);
    `log(bIsEnabled);
    `log(bPickupHidden);
    `log(bIsSleeping);
}

// Enable/Disable areas is whether this pickup has been enabled by Kismet (which it must to work!)
simulated function EnablePickup()
{
	if( CanEnable() )
	{
		bIsEnabled = true;
		WakeUp();
	}
}

/* // RS2PR-4967 - Cache our preview skeletal mesh for highlighting.
simulated function SetPickupMesh()
{
	if ( InventoryType.Default.PickupFactoryMesh != None )
	{
		if (PickupMesh != None)
		{
			DetachComponent(PickupMesh);
			PickupMesh = None;
		}
		PickupMesh = new(self) InventoryType.default.PickupFactoryMesh.Class(InventoryType.default.PickupFactoryMesh);

		AttachComponent(PickupMesh);

		if (bPickupHidden)
		{
			SetPickupHidden();
		}
		else
		{
			SetPickupVisible();
		}
	}

	if(PickupMesh != None)
	{
		HihglightPreviewMesh = SkeletalMeshComponent(PickupMesh);
	}
} */

defaultproperties
{
    RespawnTime = 5
    bNoDelete=False
}
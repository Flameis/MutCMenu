class CMAPickupFactory extends ROPickupFactory;

simulated event Init(class<ROWeapon> WPClass, int Time)
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

    /* `log(WeaponPickupClass);
    `log(InventoryType);
    `log(PreviewMesh);
    `log(bIsEnabled);
    `log(bPickupHidden);
    `log(bIsSleeping); */
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
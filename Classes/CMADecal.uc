class CMADecal extends Actor;

var DecalComponent MyDecal;

var vector 							DecalLocation;
var rotator 						DecalOrientation;
var float 							DecalLength;
var repnotify MaterialInterface 	DecalMaterial;

replication
{
	if (bNetDirty && Role == ROLE_Authority)
		DecalLocation, DecalOrientation, DecalLength, DecalMaterial;
}

simulated event ReplicatedEvent(name VarName)
{
	if (VarName == 'DecalMaterial')
	{
		Initialize(DecalMaterial, DecalLocation, DecalOrientation, DecalLength);
		// `log(VarName);
	}
	else
		super.ReplicatedEvent(VarName);
}

simulated function Initialize(MaterialInterface DecalMat, vector Loc, Rotator rota, float Length)
{
	DecalMaterial = DecalMat;
	DecalLocation = Loc;
	DecalOrientation = rota;
	DecalLength = Length;

	DetachComponent(MyDecal);
	MyDecal.TileX = 0.2;
	MyDecal.TileY = 0.2;
    MyDecal.Location = DecalLocation;
	MyDecal.Orientation = DecalOrientation;
	MyDecal.Width = 10;
	MyDecal.Height = DecalLength;
    MyDecal.FarPlane = 5000;
	MyDecal.NearPlane = -5000;
	MyDecal.SetDecalMaterial(DecalMaterial);
    MyDecal.bProjectOnTerrain = true;
	MyDecal.bProjectOnSkeletalMeshes = true;
	AttachComponent(MyDecal);
	// WorldInfo.MyDecalManager.AttachComponent(MyDecal);

	// `log(MyDecal.GetDecalMaterial());
	// `log(MyDecal.Location);
	// `log(MyDecal.Orientation);
	// `log(MyDecal.Height);
}

DefaultProperties
{
    Begin Object Class=DecalComponent Name=Decal
		bIgnoreOwnerHidden=TRUE
	End Object
	MyDecal=Decal

	RemoteRole=ROLE_SimulatedProxy
}
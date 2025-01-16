//===============================================================================
// CMATurret_M2_HMG_Destroyable
//===============================================================================
// Destroyable (and dynamically placed) version of DShK HMG deployed on a Tripod
//===============================================================================
class CMATurret_M2_HMG_Destroyable extends ROTurret_M2_HMG
	placeable;

var repnotify bool bIsDestroyed;

var PhysicsAsset PhysAssetDestroyed;
var SkeletalMesh DestroyedMesh;
var ParticleSystem DestroyedParticles;
var name DestroyedParticlesSocketName;

var MaterialInstanceConstant DestroyedMIC;

replication
{
	if ( Role == ROLE_Authority )
		bIsDestroyed;
}

simulated event ReplicatedEvent(name VarName)
{
	if ( VarName == 'bIsDestroyed' )
	{
		DoDestroyEffects();
	}

	Super.ReplicatedEvent(VarName);
}

simulated function bool CanEnterVehicle(Pawn P)
{
	if ( bIsDestroyed )
	{
		return false;
	}

	return Super.CanEnterVehicle(P);
}

event TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	if( Health <= 0 || bIsDestroyed )
		return;

	if( class<RODamageType>(DamageType) != none )
	{
		// Force napalm to insta-kill tunnels
		if( ClassIsChildOf(DamageType, class'RODmgType_Napalm') )
			Health = 0;
		else if( class<RODamageType>(DamageType).default.bCanDamageTunnels )
			Health -= DamageAmount;
	}

	if( Health <= 0 )
	{
		if ( Driver != none )
		{
			DriverLeave(true);
		}

		bIsDestroyed = true;

		if ( FactoryOwner != none )
		{
			FactoryOwner.PlaceableHMGDestroyed();
		}

		LifeSpan = 60.0f;

		DoDestroyEffects();
	}
}

simulated function DoDestroyEffects()
{		
	local Vector ParticlesLoc;
	local rotator ParticlesRot;
	local MaterialInstanceConstant tempMIC;

	// Destroy the entry actor because it's trying to get bones that don't exist and throwning a logging fit, you can't use it anymore anyway
	if ( EntryActor != none )
	{
		EntryActor.Destroy();
	}

	if ( WorldInfo != none && WorldInfo.MyEmitterPool != none )
	{
		Mesh.GetSocketWorldLocationAndRotation(DestroyedParticlesSocketName, ParticlesLoc, ParticlesRot);
		WorldInfo.MyEmitterPool.SpawnEmitter(DestroyedParticles, ParticlesLoc, ParticlesRot, self);
	}

	if ( PhysAssetDestroyed != none )
	{
		Mesh.SetPhysicsAsset(PhysAssetDestroyed, TRUE);
	}

	if ( DestroyedMesh != none )
	{
		Mesh.SetSkeletalMesh(DestroyedMesh);

		// RS2PR-5511 - Apply our damaged texture so it doesn't look like it came straight from the factory. -Nate
		tempMIC = new class 'MaterialInstanceConstant';
		tempMIC.SetParent(DestroyedMIC);
		Mesh.SetMaterial(0, tempMIC);
	}

	if ( CylinderComponent != none )
	{
		CylinderComponent.SetActorCollision(FALSE,FALSE);
	}
}

defaultproperties
{
	PitchLimit=(X=-3000,Y=4000)

	bCanBePickedUp = false
	bHasYawLimit = false // Dynamic Turrets Have Dynamic Limits

	PhysAssetDestroyed=PhysicsAsset'WP_VN_VC_DshK_Portable.Phys.DshK_Destroyed_Bounds_Physics'
	DestroyedMesh=SkeletalMesh'WP_VN_VC_DshK_Portable.Mesh.DshK_Destroyed_3rd_Master_v02'
	DestroyedParticles=ParticleSystem'FX_RS_Fire.HMG.PS_HMG_Destroy'
	DestroyedParticlesSocketName=FireFX
	DestroyedMIC=MaterialInstanceConstant'WP_VN_VC_DshK_Portable.Materials.M_VC_DshK_Destoyed_3rd_MIC'


	Health=200
}
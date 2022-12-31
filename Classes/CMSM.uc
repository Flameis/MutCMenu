class CMSM extends Actor;

var StaticMeshComponent	StaticMeshComponent;
var DynamicLightEnvironmentComponent LightEnvironment;
/** Used to replicate mesh to clients */
var repnotify transient StaticMesh ReplicatedMesh;
/** used to replicate the material in index 0 */
var repnotify MaterialInterface ReplicatedMaterial;
/** used to replicate StaticMeshComponent.bForceStaticDecals */
var repnotify bool bForceStaticDecals;

/** Extra component properties to replicate */
var repnotify vector ReplicatedMeshTranslation;
var repnotify rotator ReplicatedMeshRotation;
var repnotify vector ReplicatedMeshScale3D;

var 	AkBaseSoundObject					DestructionSound;
var 	StaticMesh 							DestroyedMesh;
var 	ParticleSystemComponent 			DestroyedPFX;

var()	array<class<DamageType> >			AcceptedDamageTypes;	// Types of Damage that harm this Destructible
var		int									Health;					// Current Health of this Destructible

var 	vector								ConfigLoc, Bounds;
var 	rotator								ConfigRot;
var		float								DrawSphereRadius;

enum ECrateMeshDisplayStatus
{
	CMDS_Default,
	CMDS_Destroyed,
};
var repnotify ECrateMeshDisplayStatus 		CrateDisplayStatus;

replication
{
	if (bNetDirty)
		CrateDisplayStatus, ReplicatedMesh, ReplicatedMaterial, ReplicatedMeshTranslation, ReplicatedMeshRotation, ReplicatedMeshScale3D, bForceStaticDecals;
}

event PostBeginPlay()
{
	Super.PostBeginPlay();

	if( StaticMeshComponent != none )
	{
		ReplicatedMesh = StaticMeshComponent.StaticMesh;
		bForceStaticDecals = StaticMeshComponent.bForceStaticDecals;
	}
	ForceNetRelevant();
}

simulated event ReplicatedEvent( name VarName )
{
	if (VarName == 'CrateDisplayStatus')
	{
		UpdateMeshStatus(CrateDisplayStatus);
	}
	else if (VarName == 'ReplicatedMesh')
	{
		// Enable the light environment if it is not already
		LightEnvironment.bCastShadows = false;
		LightEnvironment.SetEnabled(TRUE);

		StaticMeshComponent.SetStaticMesh(ReplicatedMesh);
	}
	else if (VarName == 'ReplicatedMaterial')
	{
		StaticMeshComponent.SetMaterial(0, ReplicatedMaterial);
	}
	else if (VarName == 'ReplicatedMeshTranslation')
	{
		StaticMeshComponent.SetTranslation(ReplicatedMeshTranslation);
	}
	else if (VarName == 'ReplicatedMeshRotation')
	{
		StaticMeshComponent.SetRotation(ReplicatedMeshRotation);
	}
	else if (VarName == 'ReplicatedMeshScale3D')
	{
		StaticmeshComponent.SetScale3D(ReplicatedMeshScale3D);
	}
	else if (VarName == nameof(bForceStaticDecals))
	{
		StaticMeshComponent.SetForceStaticDecals(bForceStaticDecals);
	}
	else
	{
		Super.ReplicatedEvent(VarName);
	}
}

event TakeDamage(int DamageAmount, Controller EventInstigator, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	local int i;

	`log(DamageAmount);
	`log(DamageType);

	if (ClassIsChildOf(DamageType, class'RODamageType_CannonShell') || ClassIsChildOf(DamageType, class'RODmgType_Satchel'))
	{
		AcceptedDamageTypes.additem(DamageType);
	}
	// If we're already dead, bail.
	if( Health <= 0 )
		return;

	for ( i = 0; i < AcceptedDamageTypes.Length; i++ )
	{
		if ( ClassIsChildOf(DamageType, AcceptedDamageTypes[i]) )
		{
			Health -= DamageAmount;
			break;
		}
	}

	if( Health <= 0 )
	{
		// Update our lifespan.
		Lifespan = 20;

		Shutdown();
		SetTimer(Lifespan, false, 'Destroy');
	}
	super.TakeDamage(DamageAmount, EventInstigator, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
}

simulated function TakeRadiusDamage(Controller InstigatedBy,
	float				BaseDamage,
	float				DamageRadius,
	class<DamageType>	DamageType,
	float				Momentum,
	vector				HurtOrigin,
	bool				bFullDamage,
	Actor               DamageCauser,
	optional float      DamageFalloffExponent=1.f)
{
	if (ClassIsChildOf(DamageType, class'RODamageType_CannonShell') || ClassIsChildOf(DamageType, class'RODmgType_Satchel'))
	{
		bFullDamage = true;
	}
	super.TakeRadiusDamage(InstigatedBy, BaseDamage, DamageRadius, DamageType, Momentum, HurtOrigin, bFullDamage, DamageCauser, DamageFalloffExponent);
}

simulated event UpdateMeshStatus(ECrateMeshDisplayStatus newStatus )
{
	CrateDisplayStatus = newStatus;

	if( WorldInfo.NetMode != NM_DedicatedServer )
	{
		if( CrateDisplayStatus == CMDS_Destroyed )
			PlayDestructionEffects();
	}
}

// Overridden so we can hang around for 60 seconds and then get destroyed.
simulated event ShutDown()
{
	if(Health <= 0)
	{
		UpdateMeshStatus(CMDS_Destroyed);
	}

	SetPhysics(PHYS_None);

	// shut down collision
	SetCollision(false, false);
	if (CollisionComponent != None)
	{
		CollisionComponent.SetBlockRigidBody(false);
	}

	// So joining clients see me.
	ForceNetRelevant();

	if (RemoteRole != ROLE_None)
	{
		// force replicate flags if necessary
		SetForcedInitialReplicatedProperty(Property'Engine.Actor.bCollideActors', (bCollideActors == default.bCollideActors));
		SetForcedInitialReplicatedProperty(Property'Engine.Actor.bBlockActors', (bBlockActors == default.bBlockActors));
		SetForcedInitialReplicatedProperty(Property'Engine.Actor.bHidden', (bHidden == default.bHidden));
		SetForcedInitialReplicatedProperty(Property'Engine.Actor.Physics', (Physics == default.Physics));
	}

	// force immediate network update of these changes
	bForceNetUpdate = TRUE;
}

simulated function PlayDestructionEffects()
{
	//local vector HitLoc, HitNorm, StartLoc, EndLoc;
	if ( WorldInfo.NetMode != NM_DedicatedServer )
	{
		StaticMeshComponent.SetStaticMesh(DestroyedMesh);
		
		//StartLoc = self.Location + StaticMeshComponent.Translation;
		//EndLoc = StartLoc;
		//EndLoc.Z = EndLoc.Z - 2000;
		//Trace(HitLoc, HitNorm, EndLoc, StartLoc);
		//StaticMeshComponent.StaticMesh.SetLocation(HitLoc);
		
		DestroyedPFX.SetActive(true);

		if ( DestructionSound != none )
		{
			PlaySoundBase(DestructionSound, true);
		}
	}
}

function SetStaticMesh(StaticMesh NewMesh, optional vector NewTranslation, optional rotator NewRotation, optional vector NewScale3D)
{
	StaticMeshComponent.SetStaticMesh(NewMesh);
	StaticMeshComponent.SetTranslation(NewTranslation);
	StaticMeshComponent.SetRotation(NewRotation);
	if (!IsZero(NewScale3D))
	{
		StaticMeshComponent.SetScale3D(NewScale3D);
		ReplicatedMeshScale3D = NewScale3D;
	}
	ReplicatedMesh = NewMesh;
	ReplicatedMeshTranslation = NewTranslation;
	ReplicatedMeshRotation = NewRotation;
	ForceNetRelevant();
}

defaultproperties
{
    health=100
	AcceptedDamageTypes(0)=Class'ROGame.RODmgType_RPG7Rocket'
    AcceptedDamageTypes(1)=Class'ROGame.RODmgType_RPG7RocketGeneral'
    AcceptedDamageTypes(2)=Class'ROGame.RODmgType_RPG7RocketImpact'
	AcceptedDamageTypes(3)=Class'ROGame.RODmgType_AC47Gunship'
	AcceptedDamageTypes(4)=Class'ROGame.RODmgType_C4_Explosive'
	AcceptedDamageTypes(5)=Class'ROGame.RODmgType_AntiVehicleGeneral'
	AcceptedDamageTypes(6)=Class'ROGame.RODmgType_Satchel'
	AcceptedDamageTypes(7)=Class'ROGame.RODmgTypeArtillery'

    RemoteRole=ROLE_SimulatedProxy 
	NetPriority = 3
	bAlwaysRelevant = true

    bCollideActors=true
	bBlockActors=true
	CollisionType=COLLIDE_BlockAll
	bProjTarget=true
	bWorldGeometry=true
	bCollideWorld=false
	bStatic=false
	bNoDelete=false
	bHidden=false
	bCanBeDamaged=true

	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=TRUE
	End Object
	LightEnvironment=MyLightEnvironment
	Components.Add(MyLightEnvironment)

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent0
        StaticMesh=StaticMesh'ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_112uu'
	    CollideActors=true
		BlockActors=true
		BlockZeroExtent=true
		BlockNonZeroExtent=true
		BlockRigidBody=false
		bNotifyRigidBodyCollision=false
		CastShadow=true
		bCastDynamicShadow=true
		LightEnvironment=MyLightEnvironment
    End Object
	StaticMeshComponent=StaticMeshComponent0
	Components.Add(StaticMeshComponent0)
	CollisionComponent=StaticMeshComponent0

	Begin Object Class=ParticleSystemComponent Name=DestroyedPFXComp
		Template=ParticleSystem'FX_VEH_Tank_Three.FX_VEH_Tank_B_TankShell_Penetrate'
		bAutoActivate=false
		Translation=(X=0,Y=0,Z=2)
		TranslucencySortPriority=1
	End Object
	DestroyedPFX=DestroyedPFXComp
	Components.Add(DestroyedPFXComp)

	DestructionSound=AkEvent'WW_Global.Play_GLO_Spawn_Tunnel_Destroyed'
	DestroyedMesh=StaticMesh'ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_scatter'
}
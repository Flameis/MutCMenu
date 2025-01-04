class CMAStaticMesh extends Actor;

var StaticMeshComponent	StaticMeshComponent;
var DynamicLightEnvironmentComponent LightEnvironment;
/** Used to replicate mesh to clients */
var repnotify StaticMesh ReplicatedMesh;
/** used to replicate the material in index 0 */
var repnotify MaterialInterface ReplicatedMaterial;

/** Extra component properties to replicate */
var repnotify vector 	ReplicatedMeshTranslation;
var repnotify rotator 	ReplicatedMeshRotation;
var repnotify vector 	ReplicatedMeshScale3D;

var 	AkBaseSoundObject					DestructionSound;
var 	StaticMesh 							DestroyedMesh;
var 	ParticleSystemComponent 			DestroyedPFX;

var()	array<class<DamageType> >			AcceptedDamageTypes;	// Types of Damage that harm this Destructible
var 	int									Health;

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
	if (bNetDirty && (Role == ROLE_Authority))
		CrateDisplayStatus, ReplicatedMesh, ReplicatedMaterial, ReplicatedMeshTranslation, ReplicatedMeshRotation, ReplicatedMeshScale3D, Health;
}

simulated event ReplicatedEvent( name VarName )
{
	if (VarName == 'CrateDisplayStatus')
	{
		UpdateMeshStatus(CrateDisplayStatus);
	}
	else if (VarName == 'ReplicatedMesh')
	{
		SetStaticMesh(ReplicatedMesh);
	}
	else if (VarName == 'ReplicatedMaterial')
	{
		SetMaterial(ReplicatedMaterial);
	}
	else if (VarName == 'ReplicatedMeshTranslation')
	{
		SetTranslation(ReplicatedMeshTranslation);
	}
	else if (VarName == 'ReplicatedMeshRotation')
	{
		SetRotation(ReplicatedMeshRotation);
	}
	else if (VarName == 'ReplicatedMeshScale3D')
	{
		SetScale3D(ReplicatedMeshScale3D);
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
		SetStaticMesh(DestroyedMesh);
		
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

reliable server function ServerSetStaticMesh(StaticMesh NewMesh)
{
	StaticMeshComponent.SetStaticMesh(NewMesh);
	ReplicatedMesh = NewMesh;

	ForceNetRelevant();
}

reliable server function ServerSetMaterial(MaterialInterface NewMaterial)
{
	StaticMeshComponent.SetMaterial(0, NewMaterial);
	ReplicatedMaterial = NewMaterial;

	ForceNetRelevant();
}

reliable server function ServerSetTranslation(vector NewTranslation)
{
	StaticMeshComponent.SetTranslation(NewTranslation);
	ReplicatedMeshTranslation = NewTranslation;

	ForceNetRelevant();
}

reliable server function ServerSetMeshRotation(rotator NewRotation)
{
	StaticMeshComponent.SetRotation(NewRotation);
	ReplicatedMeshRotation = NewRotation;

	ForceNetRelevant();
}

reliable server function ServerSetScale3D(vector NewScale3D)
{
	StaticMeshComponent.SetScale3D(NewScale3D);
	ReplicatedMeshScale3D = NewScale3D;

	ForceNetRelevant();
}

simulated function SetStaticMesh(StaticMesh NewMesh)
{
	StaticMeshComponent.SetStaticMesh(NewMesh);
}

simulated function SetMaterial(MaterialInterface NewMaterial)
{
	StaticMeshComponent.SetMaterial(0, NewMaterial);
}

simulated function SetTranslation(vector NewTranslation)
{
	StaticMeshComponent.SetTranslation(NewTranslation);
}

simulated function SetMeshRotation(rotator NewRotation)
{
	StaticMeshComponent.SetRotation(NewRotation);
}

simulated function SetScale3D(vector NewScale3D)
{
	StaticMeshComponent.SetScale3D(NewScale3D);
}

/* event Tick(float DeltaTime)
{
	LightEnvironment.ForceUpdate(false);
	Super.Tick(DeltaTime);
} */

defaultproperties
{
    health=100
	AcceptedDamageTypes.add(Class'ROGame.RODmgType_RPG7Rocket')
    AcceptedDamageTypes.add(Class'ROGame.RODmgType_RPG7RocketGeneral')
    AcceptedDamageTypes.add(Class'ROGame.RODmgType_RPG7RocketImpact')
	AcceptedDamageTypes.add(Class'ROGame.RODmgType_AC47Gunship')
	AcceptedDamageTypes.add(Class'ROGame.RODmgType_C4_Explosive')
	AcceptedDamageTypes.add(Class'ROGame.RODmgType_AntiVehicleGeneral')
	AcceptedDamageTypes.add(Class'ROGame.RODmgType_Satchel')
	AcceptedDamageTypes.add(Class'ROGame.RODmgTypeArtillery')

	RemoteRole=ROLE_SimulatedProxy
	NetPriority = 2.7
	bAlwaysRelevant = true

	CollisionType=COLLIDE_BlockAll
    bCollideActors=true
	bCollideWorld=true
	bBlockActors=true
	bWorldGeometry=true

	bStatic=false
	bNoDelete=false
	bHidden=false
	bCanBeDamaged=true

	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=TRUE
	End Object
	LightEnvironment=MyLightEnvironment
	Components.Add(MyLightEnvironment)

	/* Begin Object class=StaticMesh Name=StaticMesh0
		UseSimpleRigidBodyCollision=true
        bCanBecomeDynamic=true
    End Object */

    Begin Object class=StaticMeshComponent Name=StaticMeshComponent0
	    CollideActors=true
		BlockActors=true
		BlockZeroExtent=true
		BlockNonZeroExtent=true
		// BlockRigidBody=false
		// bNotifyRigidBodyCollision=false
		bUseAsOccluder=false
		CastShadow=true
		bUsePrecomputedShadows=false
		bCastDynamicShadow=true
		bSelfShadowOnly=false
		bNeverBecomeDynamic=false
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
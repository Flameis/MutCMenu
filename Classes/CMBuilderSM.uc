class CMBuilderSM extends DynamicSMActor_Spawnable;

simulated function tick(float DeltaTime)
{
	super.Tick(DeltaTime);
	bAlwaysRelevant=true;
}

defaultproperties
{
    Begin Object Name=StaticMeshComponent0
        StaticMesh=StaticMesh'ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_112uu'
    End Object

	bAlwaysRelevant=true
	bCanStepUpOn=true
	bStatic=false
    Physics=2
    bCollideWorld=true
	bSkipActorPropertyReplication=false

    /* Begin Object class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bEnabled=true
        bCastShadows=true
	   	/* bAffectedBySmallDynamicLights=FALSE
	   	MinTimeBetweenFullUpdates=0.15
		bShadowFromEnvironment=true
		bForceCompositeAllLights=true
		bDynamic=true
		bIsCharacterLightEnvironment=true */
	End Object
	Components.Add(MyLightEnvironment)

	Begin Object class=StaticMeshComponent Name=StaticMeshComponent1
		StaticMesh=StaticMesh'ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_112uu'
		LightingChannels=(Dynamic=TRUE,Unnamed_1=FALSE,bInitialized=TRUE)
		LightEnvironment = MyLightEnvironment
        bCastDynamicShadow=true
		CastShadow=true
        bCastHiddenShadow=true
		DepthPriorityGroup=SDPG_World
		CollideActors=true
		BlockActors=true
		BlockZeroExtent=true
		BlockNonZeroExtent=true
        bUsePrecomputedShadows=false
	End Object
	StaticMeshComponent=StaticMeshComponent1
	Components.Add(StaticMeshComponent1)
	CollisionComponent=StaticMeshComponent1

    bStatic=false
    Physics=2
    bCollideWorld=true */
}

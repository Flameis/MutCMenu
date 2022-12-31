class CMSMPrefab extends CMSM;

var() 	array<StaticMeshComponent>			PFStaticMeshComponent;
var 	array<StaticMesh>					PFDestroyedMesh;

simulated function PlayDestructionEffects()
{
	local vector HitLoc, HitNorm, StartLoc, EndLoc;
	local rotator RandYaw;
	local int I;
	if ( WorldInfo.NetMode != NM_DedicatedServer )
	{
		for (I=0; I<PFStaticMeshComponent.Length; I++)
		{
			PFStaticMeshComponent[I].SetStaticMesh(PFDestroyedMesh[I]);
			
			StartLoc = self.Location + PFStaticMeshComponent[I].Translation;
			EndLoc = StartLoc;
			EndLoc.Z = EndLoc.Z - 1000;
			Trace(HitLoc, HitNorm, EndLoc, StartLoc);
			PFStaticMeshComponent[I].SetTranslation(HitLoc);

			RandYaw.Yaw = Rand(360);
			PFStaticMeshComponent[I].SetRotation(RandYaw);
		}

		DestroyedPFX.SetActive(true);

		if ( DestructionSound != none )
		{
			PlaySoundBase(DestructionSound, true);
		}
	}
}

defaultproperties
{
	Health=500

	Begin Object Name=StaticMeshComponent0
		StaticMesh=StaticMesh'ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_112uu'
		Translation=(X=-96,Y=128,Z=-0.1)
		Rotation=(Pitch=0,Yaw=0,Roll=0)
		LightEnvironment=MyLightEnvironment
	End Object

	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent1
		StaticMesh=StaticMesh'ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_112uu_90deg_left'
		Translation=(X=16,Y=128,Z=-0.1)
		Rotation=(Pitch=0,Yaw=0,Roll=0)
		LightEnvironment=MyLightEnvironment
	End Object

	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent2
		StaticMesh=StaticMesh'ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_112uu'
		Translation=(X=96,Y=64,Z=-16.1)
		Rotation=(Pitch=0,Yaw=-16384,Roll=0)
		LightEnvironment=MyLightEnvironment
	End Object

	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent3
		StaticMesh=StaticMesh'ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_112uu_90deg_left'
		Translation=(X=96,Y=-48,Z=-0.1)
		Rotation=(Pitch=0,Yaw=-16384,Roll=0)
		LightEnvironment=MyLightEnvironment
	End Object

	Begin Object Class=StaticMeshComponent Name=StaticMeshComponent4
		StaticMesh=StaticMesh'ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_112uu'
		Translation=(X=32,Y=-128,Z=-0.1)
		Rotation=(Pitch=0,Yaw=-32768,Roll=0)
		LightEnvironment=MyLightEnvironment
	End Object

	Components.Add(StaticMeshComponent0)
	Components.Add(StaticMeshComponent1)
	Components.Add(StaticMeshComponent2)
	Components.Add(StaticMeshComponent3)
	Components.Add(StaticMeshComponent4)

	PFStaticMeshComponent.Add(StaticMeshComponent0);
	PFStaticMeshComponent.Add(StaticMeshComponent1);
	PFStaticMeshComponent.Add(StaticMeshComponent2);
	PFStaticMeshComponent.Add(StaticMeshComponent3);
	PFStaticMeshComponent.Add(StaticMeshComponent4);

	PFDestroyedMesh.Add(StaticMesh'ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_scatter')
	PFDestroyedMesh.Add(StaticMesh'ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_scatter')
	PFDestroyedMesh.Add(StaticMesh'ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_scatter')
	PFDestroyedMesh.Add(StaticMesh'ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_scatter')
	PFDestroyedMesh.Add(StaticMesh'ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_scatter')

	DestructionSound=AkEvent'WW_EXP_C4.Play_EXP_C4_Explosion'
}
// The artillery spawner CMenu's fire support uses. The game's own ROArtillerySpawner destroys itself on its next timer when
// no round is active (a leftover guard against a strike spilling into the next round). Fire support from CMenu is meant to
// work between rounds, in the briefing and for spectators, so this is the same Timer without that check.
class CMArtillerySpawner extends ROArtillerySpawner;

simulated function Timer()
{
	local vector AimVec, MyGravity;
	local ROVolumeTest RVT;
	local ROPlayerController ROPC;
	local class<ROArtilleryShell> ArtilleryShellClass;
	local int ShellIndex;

	MyGravity.X = 0;
	MyGravity.Y = 0;
	MyGravity.Z = PhysicsVolume.GetGravityZ();

	RVT = Spawn(class'ROVolumeTest',self,,OriginalArtyLocation);

	// If the place this arty is falling has become a NoArtyVolume after the
	// strike was called, cancel the strike.
	if ( !bValuesPreConfigured && RVT != none && RVT.IsInNoArtyVolume() )
	{
		ROPC = ROPlayerController(InstigatorController);

		if ( ROPC != none )
		{
			ROPC.ReceiveLocalizedMessage(class'ROLocalMessageArtillery', 5,,,ROPC.Pawn);
		}

		RVT.Destroy();

		if( LastSpawnedShell != none && !LastSpawnedShell.bDeleteMe )
		{
			LastSpawnedShell.Destroy();
		}

		if ( AvoidMarker != None )
		{
			AvoidMarker.Destroy();
		}

		Destroy();
		return;
	}

	if ( RVT != none )
	{
		RVT.Destroy();
	}

	if ( SpawnCounter < BatterySize )
	{
	    AimVec = vect(0,0,0);
	    AimVec.X += Rand(SpreadAmount);

	    if ( Frand() > 0.5 )
	    {
		   AimVec.X *= -1;
	    }

	    AimVec.Y += Rand(SpreadAmount);

		if ( Frand() > 0.5 )
	    {
		   AimVec.Y *= -1;
	    }

		if( OwningTeam == `AXIS_TEAM_INDEX )
		{
			ShellIndex = Rand( ArtilleryShellClassesAvailNorth.length );
			ArtilleryShellClass = ArtilleryShellClassesAvailNorth[ShellIndex];
		}
		else
		{
			ShellIndex = Rand( ArtilleryShellClassesAvailSouth.length );
			ArtilleryShellClass = ArtilleryShellClassesAvailSouth[ShellIndex];
		}

		LastSpawnedShell = Spawn(ArtilleryShellClass, InstigatorController,, Location + AimVec, rotator(MyGravity));
		LastSpawnedShell.MyArtySpawner = self;
		if ( bNoDamage )
		{
			LastSpawnedShell.Damage = 0;
			LastSpawnedShell.DamageRadius = 0;
		}
		SpawnCounter++;

		if ( OwningTeam == `AXIS_TEAM_INDEX )
		{
			SetTimer(FRand() * 0.5, false);
		}
		else
		{
			SetTimer(FRand() * 0.25, false);
		}
		return;
	}

	if ( SalvoCounter < SalvoAmount )
	{
		SalvoCounter++;
		SpawnCounter = 0;
		if( SalvoInterval > 0 )
		{
			SetTimer(SalvoInterval, false);// Time between salvos
		}
		else
		{
			if ( AvoidMarker != None )
			{
				AvoidMarker.Destroy();
			}
			Destroy();
		}
	}
	else
	{
		if ( AvoidMarker != None )
		{
			AvoidMarker.Destroy();
		}
		Destroy();
	}
}

defaultproperties
{
}

class CMenuB extends CMenu;

var	array<StaticMeshComponent>		PreviewStaticMesh;
var array<StaticMesh> 				ReferenceStaticMesh;
var	array<SkeletalMeshComponent>	PreviewSkeletalMesh;
var array<SkeletalMesh> 			ReferenceSkeletalMesh; 
var MaterialInstanceConstant    	PreviewMeshMIC;
var LinearColor		            	GoodPlacementColour;
var bool                        	bShowPreviewMesh, bPreviewIsSkeletal;

var Vector  				    	PlaceLoc, ModifyLoc;
var	rotator					    	PlaceRot, ModifyRot;
var Vector							ModifyScale;
var int 							ModifyTime;	
var Actor							TracedActor;

var array<Vector2D> 				Corners;
var string                     		SMToPlace;
var int 							SpawnTeamIndex, NumObjs;

const ROT_MODIFIER = 2048; // 11.25 degrees
const LOC_MODIFIER = 20; // 20 units

function bool CheckExceptions(string Command)
{
    GoToState('ReadyToPlace',, true);
    return false;
}

simulated state ReadyToPlace extends MenuVisible
{
	function BeginState(name PreviousStateName)
	{
		local int i;

		// ModifyLoc = vect(0,0,0);
        ModifyRot = rot(0,0,0);
		ModifyScale = vect(1,1,1);
		ModifyTime = 0;

		if (ReferenceSkeletalMesh[0] != none)
		{
			bPreviewIsSkeletal = true;

	    	PreviewMeshMIC = new class'MaterialInstanceConstant';
	    	PreviewMeshMIC.SetParent(MaterialInstanceConstant(PreviewSkeletalMesh[0].GetMaterial(0)));
	    	for ( i = 0; i < PreviewStaticMesh[0].Materials.Length; i++ )
	    	{
	    		PreviewSkeletalMesh[0].SetMaterial(i, PreviewMeshMIC);
	    	}

			PreviewSkeletalMesh[0].SetSkeletalMesh(ReferenceSkeletalMesh[0]);
	    	PreviewSkeletalMesh[0].SetHidden(false);
		}
		else 
		{
	    	PreviewMeshMIC = new class'MaterialInstanceConstant';
	    	PreviewMeshMIC.SetParent(MaterialInstanceConstant(PreviewStaticMesh[0].GetMaterial(0)));
	    	for ( i = 0; i < PreviewStaticMesh[0].Materials.Length; i++ )
	    	{
	    		PreviewStaticMesh[0].SetMaterial(i, PreviewMeshMIC);
	    	}

			PreviewStaticMesh[0].SetStaticMesh(ReferenceStaticMesh[0]);
	    	PreviewStaticMesh[0].SetHidden(false);
		}
	}

	function bool InputKey( int ControllerId, name Key, EInputEvent EventType, float AmountDepressed = 1.f, bool bGamepad = FALSE )
	{
        if (EventType == IE_Pressed)
        {
			switch (Key)
			{
	        	case 'LeftMouseButton':
	        	    DoPlace();
            	    return true;
				
				case 'Z':
            	    ModifyRot.roll = ModifyRot.roll - ROT_MODIFIER;
					MessageSelf("Roll: " $ string(-ModifyRot.roll * UnrRotToDeg)); 
					return true;

            	case 'X':
            	    ModifyRot.pitch = ModifyRot.pitch - ROT_MODIFIER;
					MessageSelf("Pitch: " $ string(-ModifyRot.pitch * UnrRotToDeg));
					return true;

            	case 'C':
            	    ModifyRot.Yaw = ModifyRot.Yaw - ROT_MODIFIER;
					MessageSelf("Yaw: " $ string(-ModifyRot.Yaw * UnrRotToDeg));
					return true;

				case 'Up':
            	    ModifyLoc.z = ModifyLoc.z + LOC_MODIFIER;
					MessageSelf("Z: " $ string(ModifyLoc.z));
					return true;

				case 'Down':
            	    ModifyLoc.z = ModifyLoc.z - LOC_MODIFIER;
					MessageSelf("Z: " $ string(ModifyLoc.z));
					return true;

				case 'Left':
				    ModifyLoc = ModifyLoc - (Vector(PC.Pawn.GetViewRotation()) >> rot(0, 16384, 0)) * LOC_MODIFIER;
					MessageSelf("Left: " $ string(ModifyLoc));
					return true;

				case 'Right':
				    ModifyLoc = ModifyLoc + (Vector(PC.Pawn.GetViewRotation()) >> rot(0, 16384, 0)) * LOC_MODIFIER;
					MessageSelf("Right: " $ string(ModifyLoc));
					return true;

				case 'MouseScrollUp':
            	    ModifyScale += vect(0.1,0.1,0.1);
					MessageSelf("Scale: " $ string(ModifyScale));
					return true;

				case 'MouseScrollDown':
				 	if (ModifyScale.x > 0.15)
					{
            	    	ModifyScale -= vect(0.1,0.1,0.1);;
						MessageSelf("Scale: "$string(ModifyScale));
					}
					return true;

				case 'Add':
					if (ModifyTime == -1)
            	    	ModifyTime = 0;
					else
						ModifyTime += 5;
					MessageSelf("Time: "$string(ModifyTime));
					return true;

				case 'Subtract':
				 	if (ModifyTime > 0)
            	    	ModifyTime -= 5;
					else
						ModifyTime = -1;
					MessageSelf("Time: "$string(ModifyTime));
					return true;

				default:
            	    return HandleInput(Key, MenuCommand);
			}
        }
	    return false;
	}
}

simulated function CanPhysicallyPlace()
{
    local rotator PRot;
	local vector HitLocation, HitNormal, StartTrace, EndTrace, ViewDirection, RightVector;
	
    local float     TraceLength;

	PC.GetPlayerViewPoint(StartTrace, PRot);
    ViewDirection = Vector(PC.Pawn.GetViewRotation());
    RightVector = ViewDirection >> rot(0, 16384, 0); // Calculate the right vector based on the player's view direction
    TraceLength = 40000;
    EndTrace = StartTrace + ViewDirection * TraceLength;
	TracedActor = PC.trace(HitLocation, HitNormal, EndTrace, StartTrace, true);
    PlaceLoc = HitLocation + ModifyLoc.X * RightVector + ModifyLoc.Y * ViewDirection + ModifyLoc.Z * vect(0, 0, 1);
    PlaceRot = PC.Pawn.GetViewRotation();
    PlaceRot.Yaw = PlaceRot.Yaw + ModifyRot.Yaw;
    PlaceRot.Roll = ModifyRot.Roll;
    PlaceRot.Pitch = ModifyRot.Pitch;
}

simulated function actor TraceActors()
{
    local rotator PRot;
	local vector HitLocation, HitNormal, StartTrace, EndTrace, ViewDirection;
	
    local float     TraceLength;

	PC.GetPlayerViewPoint(StartTrace, PRot);
    ViewDirection = Vector(PC.Pawn.GetViewRotation());
    TraceLength = 40000;
    EndTrace = StartTrace + ViewDirection * TraceLength;
	foreach PC.TraceActors(class'Actor', TracedActor, HitLocation, HitNormal, EndTrace, StartTrace,,, PC.TRACEFLAG_Blocking | PC.TRACEFLAG_PhysicsVolumes)
	{
		return TracedActor;
	}
}

function DoPlace() //Override in child class
{
}

simulated event Tick(float DeltaTime)
{
	CanPhysicallyPlace();

	if (IsInState('ReadyToPlace'))
	{
		if (bShowPreviewMesh)
			UpdatePreviewMesh();
		else
			ShowPreviewMesh();
		//DrawDebugBox(Location2, DestructibleClass.default.Bounds, 255, 20, 147);
		//DrawDebugSphere(PlaceLoc2 , DestructibleClass.default.DrawSphereRadius, 10, 255, 20, 147);
	}
	else
	{
		HidePreviewMesh();
    }

	Super.Tick(DeltaTime);
}

simulated function UpdatePreviewMesh() // Update the postion of the Preview Mesh
{
	if (bPreviewIsSkeletal)
	{
		PreviewSkeletalMesh[0].SetTranslation(PlaceLoc);
		PreviewSkeletalMesh[0].SetRotation(PlaceRot);
		PreviewSkeletalMesh[0].SetScale3D(ModifyScale);
	}
	else 
	{
		PreviewStaticMesh[0].SetTranslation(PlaceLoc);
		PreviewStaticMesh[0].SetRotation(PlaceRot);
		PreviewStaticMesh[0].SetScale3D(ModifyScale);
	}
}

simulated function ShowPreviewMesh()
{
	local StaticMeshComponent PSM;
	local SkeletalMeshComponent PSkM;

	if (bPreviewIsSkeletal)
	{
		foreach PreviewSkeletalMesh(PSkM)
		{
			PC.Pawn.AttachComponent(PSkM);
			PSkM.SetHidden(false);
		}
	}
	else 
	{
		foreach PreviewStaticMesh(PSM)
		{
			PC.Pawn.AttachComponent(PSM);
			PSM.SetHidden(false);
		}
	}

	bShowPreviewMesh = true;
}

simulated function HidePreviewMesh()
{
	local StaticMeshComponent PSM;
	local SkeletalMeshComponent PSkM;

	if (bShowPreviewMesh)
	{
		if ( bPreviewIsSkeletal )
		{
			foreach PreviewSkeletalMesh(PSkM)
			{
				PSkM.SetHidden(true);
				PC.Pawn.DetachComponent(PSkM);
			}
		}
		else 
		{
			foreach PreviewStaticMesh(PSM)
			{
				PSM.SetHidden(true);
				PC.Pawn.DetachComponent(PSM);
			}
		}
		bShowPreviewMesh = false;
	}
}

defaultproperties
{
    GoodPlacementColour=(R=0.3,G=0.3,B=0.3,A=1.0)

    Begin Object Class=StaticMeshComponent Name=PreviewStaticMeshComponent
		Materials(0)=MaterialInstanceConstant'FX_VN_Materials.Materials.M_PlaceableItem'
		Materials(1)=MaterialInstanceConstant'FX_VN_Materials.Materials.M_PlaceableItem'
		Materials(2)=MaterialInstanceConstant'FX_VN_Materials.Materials.M_PlaceableItem'
		Materials(3)=MaterialInstanceConstant'FX_VN_Materials.Materials.M_PlaceableItem'
		Materials(4)=MaterialInstanceConstant'FX_VN_Materials.Materials.M_PlaceableItem'
		Materials(5)=MaterialInstanceConstant'FX_VN_Materials.Materials.M_PlaceableItem'
		CollideActors=false
		BlockActors=false
		BlockZeroExtent=false
		BlockNonZeroExtent=false
		BlockRigidBody=false
		RBChannel=RBCC_Nothing
		DepthPriorityGroup=SDPG_World
		AbsoluteTranslation=true
		AbsoluteRotation=true
		AbsoluteScale=true
		Translation=(X=0,Y=0,Z=0)
		TranslucencySortPriority=9999
	End Object
	PreviewStaticMesh[0]=PreviewStaticMeshComponent

	Begin Object Class=SkeletalMeshComponent Name=PreviewSkeletalMeshComponent
		Materials(0)=MaterialInstanceConstant'FX_VN_Materials.Materials.M_PlaceableItem'
		Materials(1)=MaterialInstanceConstant'FX_VN_Materials.Materials.M_PlaceableItem'
		Materials(2)=MaterialInstanceConstant'FX_VN_Materials.Materials.M_PlaceableItem'
		Materials(3)=MaterialInstanceConstant'FX_VN_Materials.Materials.M_PlaceableItem'
		Materials(4)=MaterialInstanceConstant'FX_VN_Materials.Materials.M_PlaceableItem'
		Materials(5)=MaterialInstanceConstant'FX_VN_Materials.Materials.M_PlaceableItem'
		CollideActors=false
		BlockActors=false
		BlockZeroExtent=false
		BlockNonZeroExtent=false
		BlockRigidBody=false
		RBChannel=RBCC_Nothing
		DepthPriorityGroup=SDPG_World
		AbsoluteTranslation=true
		AbsoluteRotation=true
		AbsoluteScale=true
		Translation=(X=0,Y=0,Z=0)
		TranslucencySortPriority=9999
		ForcedLodModel=2
	End Object
	PreviewSkeletalMesh[0]=PreviewSkeletalMeshComponent
}
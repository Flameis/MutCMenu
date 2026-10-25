class CMenuB extends CMenu;

var	array<StaticMeshComponent>		PreviewStaticMesh;
var array<StaticMesh> 				ReferenceStaticMesh;
var	array<SkeletalMeshComponent>	PreviewSkeletalMesh;
var array<SkeletalMesh> 			ReferenceSkeletalMesh; 
var MaterialInstanceConstant    	PreviewMeshMIC;
var LinearColor		            	GoodPlacementColour;
var bool                        	bShowPreviewMesh, bPreviewIsSkeletal;
var Actor							PreviewHost; // What the preview components are attached to: the player's pawn, or the DummyActor for a spectator

var Vector  				    	PlaceLoc, ModifyLoc;
var	rotator					    	PlaceRot, ModifyRot;
var Vector							ModifyScale;
var bool							bCanScale;	// Things can be made bigger or smaller with the mouse wheel; vehicles cannot
var int 							ModifyTime;	
var bool 							SwitchRotDir;
var Actor							TracedActor;

var array<Vector2D> 				Corners;
var string                     		SMToPlace;
var int 							SpawnTeamIndex, NumObjs;
var bool							bPlacingStarted;	// An entry just picked put the menu into ReadyToPlace (see SelectLine)

// How far one key press moves or turns what is being placed. Page Up and Page Down pick a bigger or smaller step; the
// middle one (index 3, 20 units and 11.25 degrees) is where every menu starts.
const STEP_COUNT = 6;
const DEFAULT_STEP = 3;
var int StepLevel;

function bool CheckExceptions(string Command)
{
    GoToState('ReadyToPlace',, true);
    return false;
}

// Units one move key press moves the item: 1, 5, 10, 20, 50 or 100
static function int LocStepFor(int Level)
{
	switch (Clamp(Level, 0, STEP_COUNT - 1))
	{
		case 0: return 1;
		case 1: return 5;
		case 2: return 10;
		case 3: return 20;
		case 4: return 50;
	}
	return 100;
}

// Unreal rotation units one turn key press turns the item: 1, 2.8, 5.6, 11.25, 22.5 or 45 degrees
static function int RotStepFor(int Level)
{
	switch (Clamp(Level, 0, STEP_COUNT - 1))
	{
		case 0: return 182;
		case 1: return 512;
		case 2: return 1024;
		case 3: return 2048;
		case 4: return 4096;
	}
	return 8192;
}

// Page Up / Page Down: a bigger or smaller step for moving, raising and turning
function ChangeStep(int Direction)
{
	local int NewLevel;

	NewLevel = Clamp(StepLevel + Direction, 0, STEP_COUNT - 1);
	if (NewLevel == StepLevel)
	{
		MessageSelf(Direction > 0 ? "Already at the biggest step: " : "Already at the smallest step: "$StepText());
		return;
	}
	StepLevel = NewLevel;
	MessageSelf("Step: "$StepText());
}

function string StepText()
{
	return "move "$LocStepFor(StepLevel)$" units, turn "$(RotStepFor(StepLevel) * UnrRotToDeg)$" degrees ("$(StepLevel + 1)$" of "$STEP_COUNT$")";
}

function InitializePreview()
{
	local int i;

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

		bPreviewIsSkeletal = false;

		PreviewStaticMesh[0].SetStaticMesh(ReferenceStaticMesh[0]);
		PreviewStaticMesh[0].SetHidden(false);
	}
}

simulated state ReadyToPlace extends MenuVisible
{
	function BeginState(name PreviousStateName)
	{
		bPlacingStarted = true;
        ModifyRot = rot(0,0,0);
		ModifyScale = vect(1,1,1);
		ModifyTime = 0;

		// Picking another entry while already placing re-enters this state with the old preview still attached. Detach it
		// first (HidePreviewMesh uses the old mesh type), so Tick attaches the new one: otherwise a switch between a static
		// and a skeletal mesh left the old preview behind and never showed the new one.
		HidePreviewMesh();
		InitializePreview();
	}

	function bool InputKey(int ControllerId, name Key, EInputEvent EventType, float AmountDepressed = 1.f, bool bGamepad = FALSE)
	{
		// Mouse click mode: Alt held lets the mouse look around, and a click then places; otherwise the mouse is the menu's pointer
		if (ClickActive())
		{
			if (Key == 'LeftAlt' || Key == 'RightAlt')
			{
				if (EventType == IE_Pressed)
					bAltDown = true;
				else if (EventType == IE_Released)
					bAltDown = false;
				return true;
			}
			if (Key == 'LeftMouseButton' && !bAltDown)
				return ClickPointer(EventType);
		}

        if (EventType == IE_Pressed)
        {
			switch (Key)
			{
	        	case 'LeftMouseButton':
	        	    DoPlace();
            	    return true;

				// If tab reverse the direction of the rotation
				case 'Tab':
					SwitchRotDir = !SwitchRotDir;
					MessageSelf("Rotation Direction Reversed: " $ string(SwitchRotDir));
					return true;

				case 'Z':
					if (SwitchRotDir)
				    	ModifyRot.roll = ModifyRot.roll + RotStepFor(StepLevel);
					else
            	    	ModifyRot.roll = ModifyRot.roll - RotStepFor(StepLevel);
					
					MessageSelf("Roll: " $ string(-ModifyRot.roll * UnrRotToDeg)); 
					return true;

            	case 'X':
					if (SwitchRotDir)
				    	ModifyRot.pitch = ModifyRot.pitch + RotStepFor(StepLevel);
					else
            	    	ModifyRot.pitch = ModifyRot.pitch - RotStepFor(StepLevel);
					MessageSelf("Pitch: " $ string(-ModifyRot.pitch * UnrRotToDeg));
					return true;

            	case 'C':
					if (SwitchRotDir)
						ModifyRot.Yaw = ModifyRot.Yaw + RotStepFor(StepLevel);
					else
            	    	ModifyRot.Yaw = ModifyRot.Yaw - RotStepFor(StepLevel);
					MessageSelf("Yaw: " $ string(-ModifyRot.Yaw * UnrRotToDeg));
					return true;

				case 'Up':
            	    ModifyLoc.z = ModifyLoc.z + LocStepFor(StepLevel);
					MessageSelf("Z: " $ string(ModifyLoc.z));
					return true;

				case 'Down':
            	    ModifyLoc.z = ModifyLoc.z - LocStepFor(StepLevel);
					MessageSelf("Z: " $ string(ModifyLoc.z));
					return true;

				case 'Left':
				    ModifyLoc = ModifyLoc - (Vector(GetAimRotation()) >> rot(0, 16384, 0)) * LocStepFor(StepLevel);
					MessageSelf("Left: " $ string(ModifyLoc));
					return true;

				case 'Right':
				    ModifyLoc = ModifyLoc + (Vector(GetAimRotation()) >> rot(0, 16384, 0)) * LocStepFor(StepLevel);
					MessageSelf("Right: " $ string(ModifyLoc));
					return true;

				case 'PageUp':
					ChangeStep(1);
					return true;

				case 'PageDown':
					ChangeStep(-1);
					return true;

				case 'MouseScrollUp':
					if (!bCanScale)
					{
						MessageSelf("This cannot be scaled.");
						return true;
					}
            	    ModifyScale += vect(0.1,0.1,0.1);
					MessageSelf("Scale: " $ string(ModifyScale));
					return true;

				case 'MouseScrollDown':
					if (!bCanScale)
					{
						MessageSelf("This cannot be scaled.");
						return true;
					}
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
						ModifyTime += 10;
					MessageSelf("Time: "$string(ModifyTime)$" Health: "$string(ModifyTime*10));
					return true;

				case 'Subtract':
				 	if (ModifyTime > 0)
            	    	ModifyTime -= 10;
					else
						ModifyTime = -1;
					MessageSelf("Time: "$string(ModifyTime)$" Health: "$string(ModifyTime*10));
					return true;

				default:
            	    return HandleInput(Key, MenuCommand);
			}
        }
	    return false;
	}
}

// Picking an entry that is not a placeable (Clear All, Delete, Reset Flags, ...) ends placing. Without this, a menu that
// is kept open (bKeepOpen) stayed in ReadyToPlace: the preview kept showing, a click placed the last item and the placing
// keys stayed captured. The entries that are placeables enter ReadyToPlace themselves, which bPlacingStarted notices.
// Turning the page keeps the preview, and the menu is rebuilt afterwards the same way the sub-menus already do it.
function bool SelectLine(int NumKey)
{
	local bool bWasPlacing, bPaging, bResult;

	bWasPlacing = IsInState('ReadyToPlace');
	bPaging = (NumKey == 0) || (NumKey == 9 && MenuCommand.Length > ((MenuPage + 1) * ITEMS_PER_PAGE));
	bPlacingStarted = false;

	bResult = Super.SelectLine(NumKey);

	if (bWasPlacing && !bPaging && !bPlacingStarted && IsInState('ReadyToPlace'))
	{
		TargetName = ""; // Initialize puts a menu opened for one item straight back into placing it
		GoToState('MenuVisible',, true);
	}
	return bResult;
}

// A spectator has no pawn: the builder aims from their camera and hangs the preview off their DummyActor
function bool IsPawnlessSpectator()
{
	return PC != None && PC.Pawn == None && PC.PlayerReplicationInfo != None && PC.PlayerReplicationInfo.bOnlySpectator && MyDA != None;
}

// What the preview is attached to, or none when the menu cannot be used right now (a dead or respawning player)
function Actor GetPreviewHost()
{
	if (PC == None)
		return None;
	if (PC.Pawn != None)
		return (PC.Pawn.Health > 0) ? PC.Pawn : None;
	if (IsPawnlessSpectator())
		return MyDA;
	return None;
}

// Where the player is looking: the pawn's view, or the camera for a spectator
simulated function rotator GetAimRotation()
{
	local vector ViewLoc;
	local rotator ViewRot;

	if (PC.Pawn != None)
		return PC.Pawn.GetViewRotation();

	PC.GetPlayerViewPoint(ViewLoc, ViewRot);
	return ViewRot;
}

simulated function CanPhysicallyPlace()
{
    local rotator PRot;
	local vector HitLocation, HitNormal, StartTrace, EndTrace, ViewDirection, RightVector;
    local float TraceLength;

	PC.GetPlayerViewPoint(StartTrace, PRot);
    ViewDirection = Vector(GetAimRotation());
    RightVector = ViewDirection >> rot(0, 16384, 0); // Calculate the right vector based on the player's view direction
    TraceLength = 40000;
    EndTrace = StartTrace + ViewDirection * TraceLength;
	TracedActor = PC.trace(HitLocation, HitNormal, EndTrace, StartTrace, true);
    PlaceLoc = HitLocation + ModifyLoc.X * RightVector + ModifyLoc.Y * ViewDirection + ModifyLoc.Z * vect(0, 0, 1);
    PlaceRot = GetAimRotation();
    PlaceRot.Yaw = PlaceRot.Yaw + ModifyRot.Yaw;
    PlaceRot.Roll = ModifyRot.Roll;
    PlaceRot.Pitch = ModifyRot.Pitch;
}

simulated function actor TraceActors()
{
    local rotator PRot;
	local vector HitLocation, HitNormal, StartTrace, EndTrace, ViewDirection;
    local float TraceLength;

	PC.GetPlayerViewPoint(StartTrace, PRot);
    ViewDirection = Vector(GetAimRotation());
    TraceLength = 40000;
    EndTrace = StartTrace + ViewDirection * TraceLength;
	TracedActor = PC.trace(HitLocation, HitNormal, EndTrace, StartTrace, true);
	return TracedActor;
}

function DoPlace() //Override in child class
{
}

simulated event Tick(float DeltaTime)
{
	// If the player died or respawned, the preview is attached to a dead pawn and input would still be swallowed.
	// Drop the preview and close the menu so respawning works normally. A spectator has no pawn and keeps the menu.
	if (GetPreviewHost() == None || (bShowPreviewMesh && PreviewHost != GetPreviewHost()))
	{
		HidePreviewMesh();
		if (IsInState('MenuVisible'))
			GoToState('');

		Super.Tick(DeltaTime);
		return;
	}

	if (IsInState('MenuVisible')) // Also true for the ReadyToPlace sub-state
		CanPhysicallyPlace();

	if (IsInState('ReadyToPlace'))
	{
		if (bShowPreviewMesh)
			UpdatePreviewMesh();
		else
			ShowPreviewMesh();
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

// Hides a preview component and takes it off everything it could be on: the host it was put on, the player's pawn and
// the DummyActor (a spectator's host). Detaching from something it isn't on does nothing.
simulated function DetachPreview(PrimitiveComponent C)
{
	if (C == None)
		return;

	C.SetHidden(true);
	if (PreviewHost != None)
		PreviewHost.DetachComponent(C);
	if (PC != None && PC.Pawn != None && PC.Pawn != PreviewHost)
		PC.Pawn.DetachComponent(C);
	if (MyDA != None && MyDA != PreviewHost)
		MyDA.DetachComponent(C);
}

simulated function ShowPreviewMesh()
{
	local StaticMeshComponent PSM;
	local SkeletalMeshComponent PSkM;
	local Actor Host;

	Host = GetPreviewHost();
	if (Host == None)
		return;

	// Only one kind of preview at a time: the other kind is taken off first, wherever it was left
	if (bPreviewIsSkeletal)
	{
		foreach PreviewStaticMesh(PSM)
			DetachPreview(PSM);
		foreach PreviewSkeletalMesh(PSkM)
		{
			Host.AttachComponent(PSkM);
			PSkM.SetHidden(false);
		}
	}
	else
	{
		foreach PreviewSkeletalMesh(PSkM)
			DetachPreview(PSkM);
		foreach PreviewStaticMesh(PSM)
		{
			Host.AttachComponent(PSM);
			PSM.SetHidden(false);
		}
	}

	PreviewHost = Host;
	bShowPreviewMesh = true;
}

simulated function HidePreviewMesh()
{
	local StaticMeshComponent PSM;
	local SkeletalMeshComponent PSkM;

	if (bShowPreviewMesh)
	{
		// Both kinds, whichever was showing, from the pawn the preview was attached to (which may no longer be the
		// player's current pawn) and anything else it could be on
		foreach PreviewSkeletalMesh(PSkM)
			DetachPreview(PSkM);
		foreach PreviewStaticMesh(PSM)
			DetachPreview(PSM);
		PreviewHost = None;
		bShowPreviewMesh = false;
	}
}

defaultproperties
{
	bCanScale=true
	StepLevel=3
	ModifyTime=10
	ModifyScale=(X=1.000000,Y=1.000000,Z=1.000000)
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
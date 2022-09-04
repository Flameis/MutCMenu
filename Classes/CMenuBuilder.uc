class CMenuBuilder extends CMenuBase;

var	StaticMeshComponent		    PreviewStaticMesh;			// Static Mesh for preview
var StaticMesh 				    ReferenceStaticMesh;  		// Static Mesh Reference

var MaterialInstanceConstant    PreviewMeshMIC;
var LinearColor		            GoodPlacementColour;

var Vector  				    PlaceLoc, ModifyLoc;   				// The location to place the
var	rotator					    PlaceRot, ModifyRot;					// The rotation to give the on spawn

var string                      SMToPlace;
var bool                        bShowPreviewMesh;

function bool CheckExceptions(string Command)
{
    ReferenceStaticMesh = StaticMesh(DynamicLoadObject(Command, class'StaticMesh'));
    GoToState('MenuVisible');
    GoToState('ReadyToPlace');

    return true;
}

simulated state ReadyToPlace
{
	function BeginState(name PreviousStateName)
	{
		local int i;

        ModifyRot = rot(0,0,0);

	    PreviewStaticMesh.SetStaticMesh(ReferenceStaticMesh);

	    PreviewMeshMIC = new class'MaterialInstanceConstant';
	    PreviewMeshMIC.SetParent(MaterialInstanceConstant(PreviewStaticMesh.GetMaterial(0)));

	    for ( i = 0; i < PreviewStaticMesh.Materials.Length; i++ )
	    {
	    	PreviewStaticMesh.SetMaterial(i, PreviewMeshMIC);
	    }

	    PreviewStaticMesh.SetHidden(false);
	}

	function bool InputKey( int ControllerId, name Key, EInputEvent EventType, float AmountDepressed = 1.f, bool bGamepad = FALSE )
	{
        if (EventType == IE_Pressed)
        {
	        if(Key == 'LeftMouseButton')
	        {
	            DoPlace();
                return true;
	        }
            else if (Key == 'Z')
            {
                ModifyRot.roll = ModifyRot.roll + 8192; //45 Degrees
            }
            else if (Key == 'X')
            {
                ModifyRot.pitch = ModifyRot.pitch + 8192; //45 Degrees
            }
            else if (Key == 'C')
            {
                ModifyRot.Yaw = ModifyRot.Yaw + 8192; //45 Degrees
            }
            else
            {
                return HandleInput(Key, MenuCommand);
            }
        }
	    return false;
	}

	function PostRender(Canvas HUDCanvas)
    {
	    DrawMenu(ROCanvas(HUDCanvas), 10, 250, MenuName, MenuText);
    }
}

reliable server function DoPlace()
{
    local DynamicSMActor_Spawnable SMA;

    SMA = PC.Spawn(class'CMBuilderSM', PC,,PlaceLoc, PlaceRot);
    SMA.StaticMeshComponent.SetStaticMesh(ReferenceStaticMesh);
}


simulated function CanPhysicallyPlace()
{
    local rotator PRot;
	local vector HitLocation, HitNormal, StartTrace, EndTrace, ViewDirection;
	
    local float     TraceLength;

	PC.GetPlayerViewPoint(StartTrace, PRot);
    ViewDirection = Vector(PC.Pawn.GetViewRotation());
    TraceLength = 40000;
    EndTrace = StartTrace + ViewDirection * TraceLength;
	PC.trace(HitLocation, HitNormal, EndTrace, StartTrace, false);
    PlaceLoc = HitLocation + ModifyLoc;
    PlaceRot = PC.Pawn.GetViewRotation();
    PlaceRot.Yaw = PlaceRot.Yaw + ModifyRot.Yaw;
    PlaceRot.Roll = ModifyRot.Roll;
    PlaceRot.Pitch = ModifyRot.Pitch;
}

simulated event Tick(float DeltaTime)
{
	CanPhysicallyPlace();

	if (IsInState('ReadyToPlace'))
	{
		ShowPreviewMesh();
		UpdatePreviewMesh();
		//DrawDebugBox(Location2, DestructibleClass.default.Bounds, 255, 20, 147);
		//DrawDebugSphere(PlaceLoc2 , DestructibleClass.default.DrawSphereRadius, 10, 255, 20, 147);
	}
	else
	{
		HidePreviewMesh();
    }

	Super.Tick(DeltaTime);
}

// Update the postion of the Preview Mesh
simulated function UpdatePreviewMesh()
{
	PreviewStaticMesh.SetTranslation(PlaceLoc);
	PreviewStaticMesh.SetRotation(PlaceRot);
	PreviewMeshMIC.SetVectorParameterValue('color', GoodPlacementColour);
}

simulated function ShowPreviewMesh()
{
	PC.Pawn.AttachComponent(PreviewStaticMesh);
	PreviewStaticMesh.SetHidden(false);

	bShowPreviewMesh = true;
}

simulated function HidePreviewMesh()
{
	if (bShowPreviewMesh)
	{
		PreviewStaticMesh.SetHidden(true);
		PC.Pawn.DetachComponent(PreviewStaticMesh);

	    bShowPreviewMesh = false;
	}
}

defaultproperties
{
    bCMenuDebug=true
    GoodPlacementColour=(R=0.3,G=0.3,B=0.3,A=1.0)
    MenuName="BUILDER"

    MenuText(0)="Sandbags Straight"
    MenuText(1)="F4 Phantom"
    
    MenuCommand(0)="ENV_VN_Sandbags.Mesh.S_ENV_Sandbags_112uu"
    MenuCommand(1)="VH_VN_US_F4Phantom.Mesh.F4_Phantom_SM"

    Begin Object Class=StaticMeshComponent Name=PreviewStaticMeshComponent
		Materials(0)=MaterialInstanceConstant'FX_VN_Materials.Materials.M_PlaceableItem'
		Materials(1)=MaterialInstanceConstant'FX_VN_Materials.Materials.M_PlaceableItem'
		Materials(2)=MaterialInstanceConstant'FX_VN_Materials.Materials.M_PlaceableItem'
		Materials(3)=MaterialInstanceConstant'FX_VN_Materials.Materials.M_PlaceableItem'
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
	PreviewStaticMesh=PreviewStaticMeshComponent
}
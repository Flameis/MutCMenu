class CMenuB extends CMenu;

var	array<StaticMeshComponent>		PreviewStaticMesh;
var array<StaticMesh> 				ReferenceStaticMesh;
var	array<SkeletalMeshComponent>	PreviewSkeletalMesh;
var array<SkeletalMesh> 			ReferenceSkeletalMesh; 
var MaterialInstanceConstant    	PreviewMeshMIC;
var MaterialInterface				PlaceableMaterial;	// the game's placeable item look, which the preview is drawn with
var LinearColor		            	GoodPlacementColour, BadPlacementColour; // the preview's colour: it can go there, or it can't
var bool                        	bShowPreviewMesh, bPreviewIsSkeletal;
var Actor							PreviewHost; // What the preview components are attached to: the player's pawn, or the DummyActor for a spectator

var Vector  				    	PlaceLoc, ModifyLoc;	// ModifyLoc: the nudges, X to the right, Y forward, Z up (in units)
var vector							LastHitLocation;		// where the view last hit something, for aiming at the sky
var bool							bHadHit;
var bool							bShiftHeld;				// with Shift, Up and Down move the item forward and back
var	rotator					    	PlaceRot, ModifyRot;
var Vector							ModifyScale;
var bool							bCanScale;	// Things can be made bigger or smaller with the mouse wheel; vehicles cannot
var int 							ModifyTime;	// Pickups: seconds before a taken weapon comes back (keypad + and -)
var bool							bUsesTime;	// keypad + and - set ModifyTime (pickups)
var bool							bUsesHealth;// keypad + and - set PieceHealth (meshes and structures)
var int								PieceHealth;// the damage a placed mesh takes before it is destroyed; 0: it can't be destroyed

// Placing aids (see the hints panel drawn while placing)
var int								GridLevel;		// G: snap to a grid on the ground (off, 25, 50 or 100 units)
var int								AngleLevel;		// K: snap the facing (off, 15, 45 or 90 degrees)
var bool							bLockFacing;	// L: keep the facing it had, wherever the player looks
var int								LockedYaw;
var string							CantPlaceWhy;	// why it can't be placed where it is now ("" when it can): the preview is red
var string							StatusText;		// what the last key did, on the hints panel for a few seconds
var float							StatusTime;
var bool							bCanChain;		// P: the next piece lines up beside the last one (single meshes)
var bool							bChain;
var int								ChainSide;		// 1: past the last piece's far end, -1: before its near end
var bool							bHasLastPiece;	// the last piece placed, for P
var vector							LastPieceLoc, LastPieceMin, LastPieceMax; // where, and its size (in its own facing, scaled)
var rotator							LastPieceRot;
var float							LastPieceGap;	// how far above the ground it was
var StaticMeshComponent				MeasureMesh;	// the selected mesh at no turn and its own size, to measure it
var StaticMesh						MeasuredMesh;
var vector							MeasuredMin, MeasuredMax; // its size, in its own facing at scale 1
var bool							bMeasured;
var name							BuildWhat;		// what this menu places, for the server's match rules (MutCMenu.MayBuild); none: not checked here
var bool 							SwitchRotDir;
var Actor							TracedActor;

var string                     		SMToPlace;
var int 							SpawnTeamIndex, NumObjs;
var bool							bPlacingStarted;	// An entry just picked put the menu into ReadyToPlace (see SelectLine)

// How far one key press moves or turns what is being placed. Page Up and Page Down pick a bigger or smaller step; the
// middle one (index 3, 20 units and 11.25 degrees) is where every menu starts.
const STEP_COUNT = 6;
const DEFAULT_STEP = 3;
const NO_HIT_DISTANCE = 1000.0;	// aiming at nothing (the sky) before anything was hit: the item goes this far out
const LEVEL_COUNT = 4;			// grid and angle snapping: off and three sizes
const HEALTH_STEP = 100;		// keypad + and - change a mesh's health by this
const MAX_HEALTH = 5000;
const STATUS_SECONDS = 4.0;		// how long what a key did stays on the hints panel
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
		Status(Direction > 0 ? "Already at the biggest step: " : "Already at the smallest step: "$StepText());
		return;
	}
	StepLevel = NewLevel;
	Status("Step: "$StepText());
}

// What a key did: shown on the hints panel while placing, instead of a chat line for every key
function Status(string Text)
{
	StatusText = Text;
	StatusTime = (PC != None && PC.WorldInfo != None) ? PC.WorldInfo.RealTimeSeconds : 0.0;
}

// Grid snapping: off, 25, 50 or 100 units (half a meter, a meter, two meters)
static function int GridFor(int Level)
{
	switch (Clamp(Level, 0, LEVEL_COUNT - 1))
	{
		case 1: return 25;
		case 2: return 50;
		case 3: return 100;
	}
	return 0;
}

// Angle snapping: off, 15, 45 or 90 degrees
static function int AngleFor(int Level)
{
	switch (Clamp(Level, 0, LEVEL_COUNT - 1))
	{
		case 1: return 15;
		case 2: return 45;
		case 3: return 90;
	}
	return 0;
}

// A yaw rounded to the nearest whole step of Degrees
static function int SnapYaw(int Yaw, int Degrees)
{
	local float StepURU;

	if (Degrees <= 0)
		return Yaw;
	StepURU = Degrees * 65536.0 / 360.0;
	return Round(Round(float(Yaw) / StepURU) * StepURU);
}

// One snap step in Unreal rotation units (a whole quarter turn for 90 degrees, which DegToUnrRot misses by one)
static function int AngleURU(int Degrees)
{
	return Round(Degrees * 65536.0 / 360.0);
}

static function float SnapToGrid(float V, int Grid)
{
	if (Grid <= 0)
		return V;
	return Round(V / Grid) * Grid;
}

function string OnOff(bool b)
{
	return b ? "on" : "off";
}

function string HealthText(int Health)
{
	return Health > 0 ? string(Health) : "can't be destroyed";
}

function string NudgeText()
{
	return "Moved: "$int(ModifyLoc.X)$" right, "$int(ModifyLoc.Y)$" forward, "$int(ModifyLoc.Z)$" up";
}

// The look the preview is drawn with (the game's placeable item material, tinted green or red)
function MaterialInstanceConstant PreviewLook()
{
	if (PreviewMeshMIC == None || PreviewMeshMIC.Parent == None)
	{
		PreviewMeshMIC = new class'MaterialInstanceConstant';
		PreviewMeshMIC.SetParent(PlaceableMaterial);
		PreviewMeshMIC.SetVectorParameterValue('color', GoodPlacementColour);
	}
	return PreviewMeshMIC;
}

// Measures the selected mesh: its size in its own facing, at scale 1 (for P, place next). The measuring copy is put on
// the preview's host at no turn and read back once its bounds are known.
function MeasurePreviewMesh(StaticMesh M)
{
	local Actor Host;

	bMeasured = false;
	MeasuredMesh = M;
	Host = GetPreviewHost();
	if (M == None || Host == None || MeasureMesh == None)
		return;
	MeasureMesh.SetStaticMesh(M);
	Host.AttachComponent(MeasureMesh);
	MeasureMesh.SetTranslation(vect(0, 0, 0));
	MeasureMesh.SetRotation(rot(0, 0, 0));
	MeasureMesh.SetScale3D(vect(1, 1, 1));
	Host.ForceUpdateComponents(false, true);
	if (MeasureMesh.Bounds.SphereRadius > 0)
	{
		MeasuredMin = MeasureMesh.Bounds.Origin - MeasureMesh.Bounds.BoxExtent;
		MeasuredMax = MeasureMesh.Bounds.Origin + MeasureMesh.Bounds.BoxExtent;
		bMeasured = true;
	}
	Host.DetachComponent(MeasureMesh);
}

// The ground under a spot (a trace down from a little above it), or false when there is none or a Builder piece is there
function bool GroundBelow(vector Spot, out float GroundZ)
{
	local vector HitLocation, HitNormal;
	local Actor A;

	if (PC == None)
		return false;
	A = PC.Trace(HitLocation, HitNormal, Spot - vect(0, 0, 400), Spot + vect(0, 0, 200), false);
	if (A == None || CMAStaticMesh(A) != None)
		return false;
	GroundZ = HitLocation.Z;
	return true;
}

// The piece just placed, for P (place next): where it is, how it faces, its size and how far above the ground it stands
function RememberPlacedPiece()
{
	local float GroundZ;

	if (!bCanChain || !bMeasured)
	{
		bHasLastPiece = false;
		return;
	}
	bHasLastPiece = true;
	LastPieceLoc = PlaceLoc;
	LastPieceRot = PlaceRot;
	LastPieceMin = MeasuredMin * ModifyScale.X;
	LastPieceMax = MeasuredMax * ModifyScale.X;
	LastPieceGap = GroundBelow(PieceCentre(PlaceLoc, PlaceRot, LastPieceMin, LastPieceMax), GroundZ) ? PlaceLoc.Z - GroundZ : 0.0;
}

// The middle of a piece's footprint, on the level of its origin
static function vector PieceCentre(vector Loc, rotator Rot, vector Min, vector Max)
{
	return Loc + ((((Min + Max) * 0.5) * vect(1, 1, 0)) >> Rot);
}

// P: where the next piece goes, beside the last one along its long side (the far end, or the near end with Shift), facing
// the same way and standing as high above the ground as the last one did
function ChainPlace()
{
	local vector Offset, NewMin, NewMax;
	local float GroundZ;

	NewMin = MeasuredMin * ModifyScale.X;
	NewMax = MeasuredMax * ModifyScale.X;
	if (LastPieceMax.X - LastPieceMin.X >= LastPieceMax.Y - LastPieceMin.Y)
		Offset.X = (ChainSide > 0) ? LastPieceMax.X - NewMin.X : LastPieceMin.X - NewMax.X;
	else
		Offset.Y = (ChainSide > 0) ? LastPieceMax.Y - NewMin.Y : LastPieceMin.Y - NewMax.Y;

	PlaceRot = LastPieceRot;
	PlaceLoc = LastPieceLoc + (Offset >> LastPieceRot);
	if (GroundBelow(PieceCentre(PlaceLoc, PlaceRot, NewMin, NewMax), GroundZ))
		PlaceLoc.Z = GroundZ + LastPieceGap;
}

// P and Shift+P: start (or stop) putting each piece beside the last one
function ToggleChain(int Side)
{
	if (!bCanChain)
	{
		Status("Place next only works for single meshes.");
		return;
	}
	if (bChain && ChainSide == Side)
	{
		bChain = false;
		Status("Place next: off");
		return;
	}
	if (!bHasLastPiece)
	{
		Status("Place a piece first: P then puts the next one beside it.");
		return;
	}
	if (!bMeasured)
	{
		Status("This mesh can't be measured, so it can't be lined up.");
		return;
	}
	bChain = true;
	ChainSide = Side;
	Status("Place next: on, each piece goes "$(Side > 0 ? "past the far end" : "before the near end")$" of the last one (P again: off)");
}

// Why it can't be placed where it is now, or "" when it can (the preview is red when it can't). Menus add their own.
function string WhyCantPlace()
{
	local string Why;

	Why = RuleWhyCantPlace();
	if (Why != "")
		return Why;
	if (TracedActor == None && !bChain)
		return "Aim at the ground or a wall to place it there.";
	return "";
}

// The server's match rules, as it sent them (MutCMenu.MayBuild checks them again): why this player can't build this here
function string RuleWhyCantPlace()
{
	local CMMapInfo MapInfo;
	local byte Team;
	local int Zones;

	if (MyDA == None || BuildWhat == '')
		return "";
	if (MyDA.BuilderMode == class'MutCMenu'.const.BUILDER_OFF)
		return "The Builder is turned off on this server.";
	if (bIsAuthorized)
		return "";
	if (MyDA.BuilderMode == class'MutCMenu'.const.BUILDER_ADMINS)
		return "Only admins can build on this server.";
	if (MyDA.BuilderMode == class'MutCMenu'.const.BUILDER_BUILD_PHASE && !MyDA.bBuildPhaseOpen)
		return "Players can only build during the match briefing, before LIVE.";
	if (MyDA.bBuilderPiecesOnly && BuildWhat != 'Mesh')
		return "Players can only place pieces from the Builder's lists here.";
	Team = class'CMMapInfo'.static.PlayingTeam(PC.PlayerReplicationInfo);
	if ((MyDA.bBuilderBudgets || MyDA.bBuilderZones) && Team == 255)
		return "Join a team to build.";
	if (MyDA.bBuilderZones)
	{
		MapInfo = PlayerMapInfo();
		if (MapInfo != None && !MapInfo.ClientInBuildZone(Team, PlaceLoc, Zones))
			return (Zones == 0) ? "No build zone has been drawn for your team yet." : "You can only build inside your team's build zones (see the map).";
	}
	return "";
}

// This player's map drawings (the build zones are among them)
function CMMapInfo PlayerMapInfo()
{
	local int i;

	for (i = 0; i < PC.Interactions.Length; i++)
	{
		if (CMMapInteraction(PC.Interactions[i]) != None)
			return CMMapInteraction(PC.Interactions[i]).Info;
	}
	return None;
}

// The hints panel's line about the match rules, or ""
function string RulesHint()
{
	local string S;

	if (MyDA == None)
		return "";
	if (MyDA.bBuilderBudgets)
		S = "Team points: "$MyDA.BuildPointsLeft$" of "$MyDA.BuildPointsTotal$" left"$(bIsAuthorized ? " (admins build for free)" : "");
	if (MyDA.BuilderMode == class'MutCMenu'.const.BUILDER_BUILD_PHASE && MyDA.bBuildPhaseOpen)
		S $= (S != "" ? "   " : "")$"Building closes when the match goes LIVE";
	if (MyDA.bBuilderZones && !bIsAuthorized)
		S $= (S != "" ? "   " : "")$"Build inside your team's build zones";
	return S;
}

// While placing: the keys, how they are set, what the last key did and why it can't be placed (if it can't)
function DrawPlacingHints(ROCanvas C)
{
	local array<string> Lines;
	local float X, Y, XL, YL, W, H, S;
	local int i;
	local string L;

	if (C == None)
		return;

	Lines.AddItem("Click: place   C: turn   X: tilt   Z: roll   Tab: turn the other way");
	Lines.AddItem("Arrows: move (Shift + Up/Down: forward and back)   PgUp/PgDn: step size");
	L = "";
	if (bCanScale)
		L = "Mouse wheel: size   ";
	if (bUsesHealth)
		L $= "Num + / -: health   ";
	else if (bUsesTime)
		L $= "Num + / -: respawn time   ";
	if (L != "")
		Lines.AddItem(L);
	L = "G: grid ("$(GridLevel > 0 ? GridFor(GridLevel)$" units" : "off")$")   K: angle snap ("$(AngleLevel > 0 ? AngleFor(AngleLevel)$" degrees" : "off")$")   L: lock facing ("$OnOff(bLockFacing)$")";
	Lines.AddItem(L);
	if (bCanChain)
		Lines.AddItem("P / Shift+P: place the next one beside the last ("$(bChain ? (ChainSide > 0 ? "far end" : "near end") : "off")$")");
	L = RulesHint();
	if (L != "")
		Lines.AddItem(L);
	L = "Step: "$LocStepFor(StepLevel)$" units, "$(RotStepFor(StepLevel) * UnrRotToDeg)$" degrees";
	if (bCanScale)
		L $= "   Size: "$ModifyScale.X;
	if (bUsesHealth)
		L $= "   Health: "$HealthText(PieceHealth);
	else if (bUsesTime)
		L $= "   Respawn: "$ModifyTime$" s";
	Lines.AddItem(L);
	if (StatusText != "" && PC != None && PC.WorldInfo.RealTimeSeconds - StatusTime < STATUS_SECONDS)
		Lines.AddItem(StatusText);

	S = MenuScale * 0.5;
	C.Font = Font'VN_UI_Mega_Fonts.Font_VN_Mega_36';
	W = 0;
	for (i = 0; i < Lines.Length; i++)
	{
		C.TextSize(Lines[i], XL, YL);
		W = FMax(W, XL * S);
	}
	C.TextSize(CantPlaceWhy != "" ? CantPlaceWhy : "A", XL, YL);
	W = FMax(W, XL * S);
	H = YL * S;
	X = TEXT_OFFSET * MenuScale;
	Y = MenuHeight + (ClickActive() ? 130 : 80) * MenuScale;

	C.PushDepthSortPriority(DSP_Insane);
	if (bDrawBackground)
	{
		C.SetPos(X - 6 * MenuScale, Y - 6 * MenuScale);
		C.SetDrawColorStruct(BackgroundColor);
		C.DrawRect(W + 12 * MenuScale, H * (Lines.Length + (CantPlaceWhy != "" ? 1 : 0)) + 12 * MenuScale);
	}
	for (i = 0; i < Lines.Length; i++)
	{
		DrawShadowText(C, Lines[i], X, Y, S, (i == Lines.Length - 1 && StatusText == Lines[i]) ? MakeColor(255, 255, 255, 255) : TextColor);
		Y += H;
	}
	if (CantPlaceWhy != "")
		DrawShadowText(C, CantPlaceWhy, X, Y, S, MakeColor(255, 70, 60, 255));
	C.PopDepthSortPriority();
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

		for ( i = 0; i < PreviewSkeletalMesh[0].Materials.Length; i++ )
		{
			PreviewSkeletalMesh[0].SetMaterial(i, PreviewLook());
		}

		PreviewSkeletalMesh[0].SetSkeletalMesh(ReferenceSkeletalMesh[0]);
		PreviewSkeletalMesh[0].SetHidden(false);
	}
	else 
	{
		for ( i = 0; i < PreviewStaticMesh[0].Materials.Length; i++ )
		{
			PreviewStaticMesh[0].SetMaterial(i, PreviewLook());
		}

		bPreviewIsSkeletal = false;

		PreviewStaticMesh[0].SetStaticMesh(ReferenceStaticMesh[0]);
		PreviewStaticMesh[0].SetHidden(false);
		if (ReferenceStaticMesh[0] != MeasuredMesh || !bMeasured)
			MeasurePreviewMesh(ReferenceStaticMesh[0]);
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
		bChain = false;
		CantPlaceWhy = "";

		// Picking another entry while already placing re-enters this state with the old preview still attached. Detach it
		// first (HidePreviewMesh uses the old mesh type), so Tick attaches the new one: otherwise a switch between a static
		// and a skeletal mesh left the old preview behind and never showed the new one.
		HidePreviewMesh();
		InitializePreview();
	}

	function PostRender(Canvas HUDCanvas)
	{
		super.PostRender(HUDCanvas);
		DrawPlacingHints(ROCanvas(HUDCanvas));
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

		// Shift is left to the game (it is sprint); it only changes what Up and Down do
		if (Key == 'LeftShift' || Key == 'RightShift')
		{
			if (EventType == IE_Pressed)
				bShiftHeld = true;
			else if (EventType == IE_Released)
				bShiftHeld = false;
			return false;
		}

        if (EventType == IE_Pressed)
        {
			switch (Key)
			{
	        	case 'LeftMouseButton':
					// Red: it can't go there, and the panel says why
					if (CantPlaceWhy != "")
					{
						Status(CantPlaceWhy);
						return true;
					}
	        	    DoPlace();
					// With the menu not kept open, placing the item is what closes it
					if (!bKeepOpen)
						GoToState('');
            	    return true;

				// If tab reverse the direction of the rotation
				case 'Tab':
					SwitchRotDir = !SwitchRotDir;
					Status("C, X and Z now turn it "$(SwitchRotDir ? "the other way" : "the usual way"));
					return true;

				case 'G':
					GridLevel = (GridLevel + 1) % LEVEL_COUNT;
					Status(GridLevel > 0 ? "Grid: snaps to every "$GridFor(GridLevel)$" units ("$(GridFor(GridLevel) / 50.0)$" m)" : "Grid: off");
					return true;

				case 'K':
					AngleLevel = (AngleLevel + 1) % LEVEL_COUNT;
					Status(AngleLevel > 0 ? "Angle snap: faces in steps of "$AngleFor(AngleLevel)$" degrees" : "Angle snap: off");
					return true;

				case 'L':
					bLockFacing = !bLockFacing;
					if (bLockFacing)
						LockedYaw = PlaceRot.Yaw - ModifyRot.Yaw;
					Status(bLockFacing ? "Facing locked: it keeps facing this way wherever you look" : "Facing follows your view again");
					return true;

				case 'P':
					ToggleChain(bShiftHeld ? -1 : 1);
					return true;

				case 'Z':
					if (SwitchRotDir)
				    	ModifyRot.roll = ModifyRot.roll + RotStepFor(StepLevel);
					else
            	    	ModifyRot.roll = ModifyRot.roll - RotStepFor(StepLevel);
					
					Status("Roll: " $ string(-ModifyRot.roll * UnrRotToDeg));
					return true;

            	case 'X':
					if (SwitchRotDir)
				    	ModifyRot.pitch = ModifyRot.pitch + RotStepFor(StepLevel);
					else
            	    	ModifyRot.pitch = ModifyRot.pitch - RotStepFor(StepLevel);
					Status("Tilt: " $ string(-ModifyRot.pitch * UnrRotToDeg));
					return true;

            	case 'C':
					// With angle snapping on, one press turns it by one snap step
					if (SwitchRotDir)
						ModifyRot.Yaw = ModifyRot.Yaw + (AngleLevel > 0 ? AngleURU(AngleFor(AngleLevel)) : RotStepFor(StepLevel));
					else
            	    	ModifyRot.Yaw = ModifyRot.Yaw - (AngleLevel > 0 ? AngleURU(AngleFor(AngleLevel)) : RotStepFor(StepLevel));
					Status("Turn: " $ string(-ModifyRot.Yaw * UnrRotToDeg));
					return true;

				// The nudges are kept as distances (X to the right, Y forward, Z up) and turned with the view when placing
				// (CanPhysicallyPlace). Left and Right used to add a world direction into them, so they went a different
				// way depending on where the player faced.
				case 'Up':
					if (bShiftHeld)
						ModifyLoc.Y += LocStepFor(StepLevel);
					else
						ModifyLoc.Z += LocStepFor(StepLevel);
					Status(NudgeText());
					return true;

				case 'Down':
					if (bShiftHeld)
						ModifyLoc.Y -= LocStepFor(StepLevel);
					else
						ModifyLoc.Z -= LocStepFor(StepLevel);
					Status(NudgeText());
					return true;

				case 'Left':
					ModifyLoc.X -= LocStepFor(StepLevel);
					Status(NudgeText());
					return true;

				case 'Right':
					ModifyLoc.X += LocStepFor(StepLevel);
					Status(NudgeText());
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
						Status("This cannot be scaled.");
						return true;
					}
            	    ModifyScale += vect(0.1,0.1,0.1);
					Status("Size: " $ ModifyScale.X);
					return true;

				case 'MouseScrollDown':
					if (!bCanScale)
					{
						Status("This cannot be scaled.");
						return true;
					}
				 	if (ModifyScale.x > 0.15)
					{
            	    	ModifyScale -= vect(0.1,0.1,0.1);
						Status("Size: " $ ModifyScale.X);
					}
					return true;

				// A mesh's health (0: it can't be destroyed), or a pickup's respawn time. The health used to be "Time" times 10,
				// and going below 0 made a mesh that can't be destroyed by accident.
				case 'Add':
					if (bUsesHealth)
					{
						PieceHealth = Min(PieceHealth + HEALTH_STEP, MAX_HEALTH);
						Status("Health: "$HealthText(PieceHealth));
					}
					else if (bUsesTime)
					{
						ModifyTime = (ModifyTime == -1) ? 0 : ModifyTime + 10;
						Status("Respawn time: "$ModifyTime$" seconds");
					}
					return true;

				case 'Subtract':
					if (bUsesHealth)
					{
						PieceHealth = Max(PieceHealth - HEALTH_STEP, 0);
						Status("Health: "$HealthText(PieceHealth));
					}
					else if (bUsesTime)
					{
						ModifyTime = (ModifyTime > 0) ? ModifyTime - 10 : -1;
						Status("Respawn time: "$ModifyTime$" seconds");
					}
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
	// The world only (map geometry and Builder pieces): with actors too, the item could land on the player's own
	// soldier or a teammate's head
	TracedActor = PC.Trace(HitLocation, HitNormal, EndTrace, StartTrace, false);
	// Nothing hit (the sky): the last spot that was hit, or a short way out. It used to go to the middle of the map.
	if (TracedActor == None)
		HitLocation = bHadHit ? LastHitLocation : StartTrace + ViewDirection * NO_HIT_DISTANCE;
	else
	{
		LastHitLocation = HitLocation;
		bHadHit = true;
	}
    // Level right and forward, whatever the view's pitch: the view turned 90 degrees tilted with it, so looking up or
    // down a nudge to the right went a little up or down and came out short
    RightVector = Normal(RightVector * vect(1, 1, 0));
    PlaceLoc = HitLocation + ModifyLoc.X * RightVector + ModifyLoc.Y * Normal(ViewDirection * vect(1, 1, 0)) + ModifyLoc.Z * vect(0, 0, 1);
    PlaceRot = GetAimRotation();
    PlaceRot.Yaw = (bLockFacing ? LockedYaw : PlaceRot.Yaw) + ModifyRot.Yaw;
    PlaceRot.Roll = ModifyRot.Roll;
    PlaceRot.Pitch = ModifyRot.Pitch;
    PlaceRot.Yaw = SnapYaw(PlaceRot.Yaw, AngleFor(AngleLevel));
    PlaceLoc.X = SnapToGrid(PlaceLoc.X, GridFor(GridLevel));
    PlaceLoc.Y = SnapToGrid(PlaceLoc.Y, GridFor(GridLevel));

    if (bChain && bHasLastPiece && bMeasured)
    	ChainPlace();

    if (IsInState('ReadyToPlace'))
    	CantPlaceWhy = WhyCantPlace();
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
	PreviewLook().SetVectorParameterValue('color', CantPlaceWhy == "" ? GoodPlacementColour : BadPlacementColour);
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
    GoodPlacementColour=(R=0.03,G=0.35,B=0.03,A=1.0)
    BadPlacementColour=(R=0.3,G=0.005,B=0.005,A=1.0)
    PlaceableMaterial=MaterialInstanceConstant'FX_VN_Materials.Materials.M_PlaceableItem'

	Begin Object Class=StaticMeshComponent Name=MeasureMeshComponent
		HiddenGame=true
		CastShadow=false
		CollideActors=false
		BlockActors=false
		BlockZeroExtent=false
		BlockNonZeroExtent=false
		BlockRigidBody=false
		RBChannel=RBCC_Nothing
		AbsoluteTranslation=true
		AbsoluteRotation=true
		AbsoluteScale=true
	End Object
	MeasureMesh=MeasureMeshComponent

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
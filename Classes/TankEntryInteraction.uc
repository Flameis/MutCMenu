// Vanilla blocks infantry from tanks because ROVehicle.bInfantryCanUse is false on them, so ROVehicle.PlayerLookingAtMe never
// raises the enter prompt and ROPlayerController.ServerUse ignores them. This replaces that gate: shows an enter prompt on any friendly tank for non-crew players
// and routes the Use keybind to DummyActor.EnterVehicle(), which enters the seat server-side.
class TankEntryInteraction extends Interaction;

var PlayerController PC;
var DummyActor MyDA;
var bool bPromptActive;
var float LastUseTime;
var ROVehicle PromptVehicle; // The tank the prompt is currently shown for

const MAX_ENTER_DIST = 400.0;
const MAX_CONE_DIST = 550.0;  // Tanks within this range can be entered without aiming exactly at the hull
const MIN_CONE_DOT = 0.6;
const USE_COOLDOWN = 0.5;

function ROVehicle FindEnterableTank()
{
    local ROPawn ROP;
    local ROVehicle ROV, Best;
    local ROVehicleTreaded Candidate;
    local vector ViewLocation, HitLocation, HitNormal, ToTank;
    local rotator ViewRotation;
    local float BestDist, Dist;

    ROP = ROPawn(PC.Pawn);
    if (ROP == none || ROP.Health <= 0 || ROP.bIsProning || ROP.IsProneTransitioning())
        return none;

    PC.GetPlayerViewPoint(ViewLocation, ViewRotation);
    ROV = ROVehicleTreaded(PC.Trace(HitLocation, HitNormal, ViewLocation + Vector(ViewRotation) * MAX_ENTER_DIST, ViewLocation, true));

    if (IsEnterable(ROV))
        return ROV;

    // Nothing directly under the crosshair: fall back to the closest friendly tank in front of the player
    BestDist = MAX_CONE_DIST;
    foreach PC.WorldInfo.AllPawns(class'ROVehicleTreaded', Candidate, ROP.Location, MAX_CONE_DIST)
    {
        if (!IsEnterable(Candidate))
            continue;

        ToTank = Candidate.Location - ViewLocation;
        Dist = VSize(ToTank);
        if (Dist < BestDist && Normal(ToTank) dot Vector(ViewRotation) >= MIN_CONE_DOT)
        {
            BestDist = Dist;
            Best = Candidate;
        }
    }

    return Best;
}

function bool IsEnterable(ROVehicle ROV)
{
    return ROV != none && !ROV.bInfantryCanUse && !ROV.bDeadVehicle && ROV.AnySeatAvailable()
        && VSizeSq(ROV.Velocity) < class'ROVehicle'.const.MAX_SPEED_FOR_ENTRY_SQ && ROV.Team == PC.GetTeamNum();
}

function name GetUseKey()
{
    local int i;
    local string Cmd;

    if (PC == none || PC.PlayerInput == none)
        return '';

    for (i = 0; i < PC.PlayerInput.Bindings.Length; i++)
    {
        Cmd = PC.PlayerInput.Bindings[i].Command;
        if (Cmd ~= "GBA_Use" || Cmd ~= "Use")
            return PC.PlayerInput.Bindings[i].Name;
    }
    return 'E';
}

function PostRender(Canvas HUDCanvas)
{
    local string Prompt;
    local float XL, YL;

    PromptVehicle = FindEnterableTank();
    bPromptActive = PromptVehicle != none;
    if (!bPromptActive)
        return;

    Prompt = "[" $ GetUseKey() $ "] Enter Tank";
    HUDCanvas.Font = Font'VN_UI_Mega_Fonts.Font_VN_Mega_36';
    HUDCanvas.SetDrawColor(255, 255, 255, 255);
    HUDCanvas.StrLen(Prompt, XL, YL);
    HUDCanvas.SetPos((HUDCanvas.ClipX - XL) * 0.5, HUDCanvas.ClipY * 0.65);
    HUDCanvas.DrawText(Prompt, false);
}

function bool InputKey(int ControllerId, name Key, EInputEvent EventType, float AmountDepressed = 1.f, bool bGamepad = FALSE)
{
    if (!bPromptActive || MyDA == none || Key != GetUseKey())
        return false;

    if (EventType == IE_Pressed && PC.WorldInfo.TimeSeconds - LastUseTime > USE_COOLDOWN)
    {
        LastUseTime = PC.WorldInfo.TimeSeconds;
        MyDA.EnterVehicle(PromptVehicle);
    }

    // Swallow the key so vanilla doesn't show its crew-only rejection
    return true;
}


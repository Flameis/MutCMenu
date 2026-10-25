// Lets anyone into a tank. The game keeps players out in two ways: RS2's own tanks have bInfantryCanUse off, so the game
// never offers them; WW2 and Winter War tanks (WW2VehicleTank, WWVehicleTank) let only one role class in (CanEnterVehicle
// wants ClassIndex 9 for WW2, which no role here has, and 8 for Winter War). This shows an enter prompt on any tank the
// player couldn't otherwise get into, and sends the use key to DummyActor.EnterVehicle(), which gets them in on the server.
// Only tank crew roles get the prompt, unless the server setting bTankPromptForAll is on.
// The game only hands keys to a script Interaction through OnReceivedNativeInputKey (set below): without it the prompt
// showed but pressing the key did nothing.
class TankEntryInteraction extends Interaction;

var PlayerController PC;
var DummyActor MyDA;
var bool bPromptActive;
var float LastUseTime;
var ROVehicle PromptVehicle; // The tank the prompt is currently shown for
var name UseKey;             // The player's use key, looked up when the prompt appears

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
    if (!AllowedToUse(PC.PlayerReplicationInfo, MyDA != none && MyDA.bTankPromptForAll))
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

// A tank with a free seat, standing still, that is the player's team's or nobody's, and that the game itself wouldn't let
// this player into (transports the game already lets them use get no second prompt). The seat check is HasEmptySeat, which
// reads the seat state sent to clients: AnySeatAvailable is a server-only function, so on a player's own computer it never
// ran and the prompt never showed (single player and the host were not affected).
function bool IsEnterable(ROVehicle ROV)
{
    if (ROV == none || ROV.bDeadVehicle || !ROV.HasEmptySeat() || VSizeSq(ROV.Velocity) >= class'ROVehicle'.const.MAX_SPEED_FOR_ENTRY_SQ)
        return false;
    if (ROV.Team != PC.GetTeamNum() && !IsEmpty(ROV))
        return false;
    return !ROV.bInfantryCanUse || !ROV.CanEnterVehicle(PC.Pawn);
}

// A tank crew role: MutExtras', WW2's and Winter War's tank crew all have the tank role type
static function bool IsTankCrew(PlayerReplicationInfo PRI)
{
    local ROPlayerReplicationInfo ROPRI;

    ROPRI = ROPlayerReplicationInfo(PRI);
    return ROPRI != None && ROPRI.RoleInfo != None && (ROPRI.RoleInfo.RoleType == RORIT_Tank || ROPRI.RoleInfo.bCanBeTankCrew);
}

// Who may use the prompt: tank crew, or anyone when the server allows it
static function bool AllowedToUse(PlayerReplicationInfo PRI, bool bForAll)
{
    return bForAll || IsTankCrew(PRI);
}

static function bool IsEmpty(ROVehicle ROV)
{
    local int i;

    for (i = 0; i < ROV.Seats.Length; i++)
    {
        if (ROV.GetSeatPRI(i) != None)
            return false;
    }
    return true;
}

// The first command of a binding: "Use | OnRelease useReleasePlayer" -> "Use"
static function string FirstCommand(string Cmd)
{
    local int Bar;

    Bar = InStr(Cmd, "|");
    if (Bar != INDEX_NONE)
        Cmd = Left(Cmd, Bar);
    while (Left(Cmd, 1) == " ")
        Cmd = Mid(Cmd, 1);
    while (Right(Cmd, 1) == " ")
        Cmd = Left(Cmd, Len(Cmd) - 1);
    return Cmd;
}

// The key the player uses things with. The game binds it through an alias ("F" -> "Interact" -> "Use | OnRelease ..."),
// so the aliases are followed back from the Use command to the key. Looking only for a binding that is exactly "Use"
// found nothing, and the prompt then said E and waited for a key the player never pressed.
function name GetUseKey()
{
    local array<name> Names, Found;
    local int i, j, Depth;
    local string Cmd;

    if (PC == none || PC.PlayerInput == none)
        return '';

    for (i = 0; i < PC.PlayerInput.Bindings.Length; i++)
    {
        Cmd = FirstCommand(PC.PlayerInput.Bindings[i].Command);
        if (Cmd ~= "Use" || Cmd ~= "GBA_Use")
            Names.AddItem(PC.PlayerInput.Bindings[i].Name);
    }

    // Each round goes one alias closer to the key; a name nothing points at is the key itself
    for (Depth = 0; Depth < 4 && Names.Length > 0; Depth++)
    {
        Found.Length = 0;
        for (i = 0; i < PC.PlayerInput.Bindings.Length; i++)
        {
            Cmd = FirstCommand(PC.PlayerInput.Bindings[i].Command);
            for (j = 0; j < Names.Length; j++)
            {
                if (Cmd ~= string(Names[j]))
                {
                    Found.AddItem(PC.PlayerInput.Bindings[i].Name);
                    break;
                }
            }
        }
        if (Found.Length == 0)
            break;
        Names = Found;
    }

    return Names.Length > 0 ? Names[0] : 'E';
}

function PostRender(Canvas HUDCanvas)
{
    local string Prompt;
    local float XL, YL;

    PromptVehicle = FindEnterableTank();
    if (PromptVehicle != none && !bPromptActive)
        UseKey = GetUseKey(); // Looked up when the prompt appears, so a key rebound since is picked up
    bPromptActive = PromptVehicle != none;
    if (!bPromptActive)
        return;

    Prompt = "[" $ UseKey $ "] Enter Tank";
    HUDCanvas.Font = Font'VN_UI_Mega_Fonts.Font_VN_Mega_36';
    HUDCanvas.SetDrawColor(255, 255, 255, 255);
    HUDCanvas.StrLen(Prompt, XL, YL);
    HUDCanvas.SetPos((HUDCanvas.ClipX - XL) * 0.5, HUDCanvas.ClipY * 0.65);
    HUDCanvas.DrawText(Prompt, false);
}

function bool InputKey(int ControllerId, name Key, EInputEvent EventType, float AmountDepressed = 1.f, bool bGamepad = FALSE)
{
    if (!bPromptActive || MyDA == none || Key != UseKey)
        return false;

    if (EventType == IE_Pressed && PC.WorldInfo.TimeSeconds - LastUseTime > USE_COOLDOWN)
    {
        LastUseTime = PC.WorldInfo.TimeSeconds;
        MyDA.EnterVehicle(PromptVehicle);
    }

    // Swallow the key so vanilla doesn't show its crew-only rejection
    return true;
}

defaultproperties
{
    OnReceivedNativeInputKey=InputKey
}

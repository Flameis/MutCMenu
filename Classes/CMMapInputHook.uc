// Gives MutCMenu's map tool (CMMapInteraction) the keyboard and mouse before anything else sees them. The game's
// overhead map takes left clicks for itself inside the game's own input, so an Interaction never got them. The viewport's
// HandleInputKey delegate runs before the console, menus, the HUD and every Interaction; nothing in the game uses it.
// This object belongs to the viewport, which lasts the whole session, and keeps no reference to anything in the level
// (that would keep the old level alive after a map change). It finds the local player's tool again on every key.
class CMMapInputHook extends Object;

// A made-up key name the hook answers true to, so a new level can tell the viewport already has this hook
const PING_KEY = 'CMMapHookPing';

var GameViewportClient Viewport;
var array<name> ReportedScenes;  // menus already logged as taking input, so each is logged once

// True when the hook is in place, false when something else already uses the viewport's delegate
static function bool Install(LocalPlayer LP)
{
    local CMMapInputHook Hook;

    if (LP == None || LP.ViewportClient == None)
        return false;

    // Set up on an earlier level: the viewport keeps it for the whole session
    if (IsInstalled(LP))
        return true;
    if (LP.ViewportClient.HandleInputKey != None)
        return false;

    Hook = new(LP.ViewportClient) class'CMMapInputHook';
    Hook.Viewport = LP.ViewportClient;
    LP.ViewportClient.HandleInputKey = Hook.InputKey;
    return true;
}

static function bool IsInstalled(LocalPlayer LP)
{
    return LP != None && LP.ViewportClient != None && LP.ViewportClient.HandleInputKey != None
        && LP.ViewportClient.HandleInputKey(0, PING_KEY, IE_Released, 0.0);
}

function bool InputKey(int ControllerId, name Key, EInputEvent EventType, float AmountDepressed, optional bool bGamepad)
{
    local PlayerController PC;
    local CMMapInteraction Tool;
    local int i;

    if (Key == PING_KEY)
        return true;

    // The players are kept by the engine, which owns the viewport
    if (Viewport == None || Viewport.Outer.GamePlayers.Length == 0 || Viewport.Outer.GamePlayers[0] == None)
        return false;
    PC = Viewport.Outer.GamePlayers[0].Actor;
    if (PC == None || PC.bDeleteMe)
        return false;

    // Typing in the console, or a menu is open: leave the keys to them
    if (Viewport.ViewportConsole != None && (Viewport.ViewportConsole.IsInState('Typing') || Viewport.ViewportConsole.IsInState('Open')))
        return false;
    if (MenuOpen())
        return false;

    // A CMenu in mouse click mode has the mouse: its clicks are for its lines, even with the map open
    for (i = 0; i < PC.Interactions.Length; i++)
    {
        if (CMenu(PC.Interactions[i]) != None && CMenu(PC.Interactions[i]).HasMousePointer())
            return false;
    }

    for (i = 0; i < PC.Interactions.Length; i++)
    {
        Tool = CMMapInteraction(PC.Interactions[i]);
        if (Tool != None)
            return Tool.InputKey(ControllerId, Key, EventType, AmountDepressed, bGamepad);
    }
    return false;
}

// Any open menu (UI scene) other than CMenu's own: CMenu is an Interaction, so a CMenu scene is never expected, but the
// check is kept for a scene named like it
function bool MenuOpen()
{
    local UIScene Scene;
    local GameUISceneClient SceneClient;

    if (Viewport.UIController == None)
        return false;
    SceneClient = Viewport.UIController.SceneClient;
    if (SceneClient == None)
        return false;

    foreach SceneClient.AllActiveScenes(class'UIScene', Scene)
    {
        if (Scene == None || InStr(string(Scene.Class.Name), "CMenu") != INDEX_NONE)
            continue;

        if (ReportedScenes.Find(Scene.Class.Name) == INDEX_NONE)
        {
            ReportedScenes.AddItem(Scene.Class.Name);
            LogInternal("[MutCMenu] Map drawing leaves input alone while this menu is open: "$Scene.Class.Name);
        }
        return true;
    }
    return false;
}

defaultproperties
{
}

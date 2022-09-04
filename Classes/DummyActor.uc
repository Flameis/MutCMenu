class DummyActor extends actor;

//TODO: make an array of cmenus to put in?
//var array<CMenuBase> CMenus;
var bool bIsAuthorized, bMutCommands, bMutExtras;
var string TargetName;

simulated function CMenuSetup(bool bCommands, bool bExtras)
{
    local PlayerController PC;
    local int i;

    PC = PlayerController(Owner);

    pc.Interactions.Insert(0, 11);
	pc.Interactions[0] = new(pc) class'CMenuBase';
    pc.Interactions[1] = new(pc) class'CMenuMain';
    pc.Interactions[2] = new(pc) class'CMenuGeneral';
    pc.Interactions[3] = new(pc) class'CMenuPlayer';
    pc.Interactions[4] = new(pc) class'CMenuParadrops';
    pc.Interactions[5] = new(pc) class'CMenuRealismMatch';
    pc.Interactions[6] = new(pc) class'CMenuVehicles';
    pc.Interactions[7] = new(pc) class'CMenuPCManager';
    pc.Interactions[8] = new(pc) class'CMenuWeapons';
    pc.Interactions[9] = new(pc) class'CMenuSettings';
    pc.Interactions[10] = new(pc) class'CMenuBuilder';
    //pc.Interactions[10] = new(pc) class'CMenuVehicles';
    //pc.Interactions[11] = new(pc) class'CMenuPCManager';

    for (i = 0; i < PC.Interactions.Length; i++)
    {
        if (InStr(PC.Interactions[i].name, "CMenu",,true) != -1)
        {
            CMenuBase(PC.Interactions[i]).PC = PC;
            CMenuBase(PC.Interactions[i]).bMutCommands = bCommands;
            CMenuBase(PC.Interactions[i]).bMutExtras = bExtras;
        }
    }
}

reliable client function ClientCMenuSetup(bool bCommands, bool bExtras)
{
    CMenuSetup(bCommands, bExtras);
}

simulated function ToggleCMenuVisiblity(string CMenu, bool bAuthorized, string TName)
{
    local PlayerController PC;
    local int i;

    PC = PlayerController(Owner);

    for (i = 0; i < PC.Interactions.Length; i++)
    {
        if (InStr(PC.Interactions[i].name, CMenu,,true) != -1)
        {
            if (CMenuBase(PC.Interactions[i]).IsInState('MenuVisible'))
            {
                CMenuBase(PC.Interactions[i]).GoToState('');
                CMenuBase(PC.Interactions[i]).bIsAuthorized = bAuthorized;
            }
            else 
            {
                CMenuBase(PC.Interactions[i]).bIsAuthorized = bAuthorized;
                CMenuBase(PC.Interactions[i]).TargetName = TName;
                CMenuBase(PC.Interactions[i]).GoToState('MenuVisible');
            }    
        }
        else if (InStr(PC.Interactions[i].name, "CMenu",,true) != -1)
        {
            PC.Interactions[i].GoToState('');
        }
    }
}

reliable client function ClientToggleCMenuVisiblity(string CMenu, bool bAuthorized, string TName)
{
    ToggleCMenuVisiblity(CMenu, bAuthorized, TName);
}

simulated function CMConsoleCommand(string Command)
{
    local PlayerController PC;
    PC = PlayerController(Owner);

    PC.ConsoleCommand(Command);
    `log (Command);
}

reliable client function ClientCMConsoleCommand(string Command)
{
    CMConsoleCommand(Command);
}

reliable client function SetCMenuColor(string InColor, string type)
{
    local PlayerController PC;
    local Color CMenuColor;
    local array<string> Colors;
    local int i;

    Colors = SplitString(InColor, " ", true);
    PC = PlayerController(Owner);

    if (Colors[3] == "")
    {
        Colors[3] = "255";
    }

    CMenuColor.r = int(Colors[0]);
    CMenuColor.g = int(Colors[1]);
    CMenuColor.b = int(Colors[2]);
    CMenuColor.a = int(Colors[3]);

    for (i = 0; i < PC.Interactions.Length; i++)
    {
        if (InStr(PC.Interactions[i].name, "CMenu",,true) != -1)
        {
            CMenuBase(PC.Interactions[i]).SetCMenuColor(CMenuColor, Type);
        }
    }
}
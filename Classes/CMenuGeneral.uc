class CMenuGeneral extends CMenu;

function Initialize()
{
    if (bIsAuthorized)
    {
        MenuText.AddItem("Admin Toggle Fly");
        MenuCommand.AddItem("FLY");
    }

    super.Initialize();
}

function bool CheckExceptions(string Command)
{
    switch (Caps(Command))
    {
        case "DROPATGRID":
            if(bCMenuDebug) `Log("DropAtGrid");
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr="Mutate "$Command$" ";
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStrPos=Len(LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr); // set the value high in case name is quite long
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.GoToState('Typing');
            LocalPlayer(PC.Player).ViewportClient.ClearProgressMessages();
            LocalPlayer(PC.Player).ViewportClient.SetProgressTime(6);
            MessageSelf("Please Specify a Grid Location (Example: E 5 kp 5)");
            return true;
            
        case "DROPATOBJ":
            if(bCMenuDebug) `Log("DropAtObj");
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr="Mutate "$Command$" ";
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStrPos=Len(LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr); // set the value high in case name is quite long
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.GoToState('Typing');
            LocalPlayer(PC.Player).ViewportClient.ClearProgressMessages();
            LocalPlayer(PC.Player).ViewportClient.SetProgressTime(6);
            MessageSelf("Please Specify an Objective (Example: A)");
            return true;

        case "CHANGENAME":
            if(bCMenuDebug) `Log("CHANGENAME");
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr="Mutate "$Command$" ";
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStrPos=Len(LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr); // set the value high in case name is quite long
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.GoToState('Typing');
            LocalPlayer(PC.Player).ViewportClient.ClearProgressMessages();
            LocalPlayer(PC.Player).ViewportClient.SetProgressTime(6);
            MessageSelf("Please Type Your Desired Name (Example: T/5 Scovel [29ID])");
            return true;

        case "SUICIDE":
        case "SAY /NOTREADY":
        case "SAY /READY":
            PC.ConsoleCommand(Command);
            return true;

        case "TOGGLESPECTATOR":
            if (!ROPlayerController(PC).PlayerReplicationInfo.bOnlySpectator)
            {
                ROPlayerController(PC).PlayerReplicationInfo.bOnlySpectator = true;
                ROPlayerController(PC).bForcedSpectating = false;
                ROPlayerController(PC).ServerSpectatorReset();
                ROPlayerController(PC).ServerViewSelf();
                //ROPlayerController(PC).myHUD = PC.Spawn(class'CMHUD', PC);
                /* ROPlayerController(PC).GotoState('Spectating');
			    ROPlayerController(PC).ClientGotoState('Spectating');
                ROPlayerController(PC).SetCameraMode('FreeCam'); */
            }
            else
            {
                ROPlayerController(PC).PlayerReplicationInfo.bOnlySpectator = false;
                ROPlayerController(PC).Reset();
            }
            return true;

        case "FLY":
            if (ROPlayerController(PC.CheatManager.Outer).bCheatFlying != true)
            {
                if ( (PC.Pawn != None) && PC.Pawn.CheatFly() )
	            {
	            	MessageSelf("You feel much lighter");
	            	ROPlayerController(PC.CheatManager.Outer).bCheatFlying = true;
	            	ROPlayerController(PC.CheatManager.Outer).GotoState('PlayerFlying');
                    PC.Pawn.AirSpeed = PC.Pawn.Default.AirSpeed * 20;
	            }
            }
            else
            {
                if ( (PC.Pawn != None) && PC.Pawn.CheatWalk() )
                {
                	MessageSelf("You feel much heavier");
                	ROPlayerController(PC.CheatManager.Outer).bCheatFlying = false;
                	ROPlayerController(PC.CheatManager.Outer).GotoState('PlayerWalking');
                    PC.Pawn.AirSpeed = PC.Pawn.Default.AirSpeed;
                }
            }
            return true;

        default:
            return false;
    }
}



defaultproperties
{
    MenuName="GENERAL"

    MenuText(0)="Respawn"
    MenuText(1)="Kill Self"
    MenuText(2)="Drop At Objective"
    MenuText(3)="Drop At Grid"
    MenuText(4)="Change Name"
    MenuText(5)="Safety On"
    MenuText(6)="Safety Off"
    MenuText(7)="Check AITs"

    MenuText(8)="Switch Team"
    MenuText(9)="Set Team Not Ready"
    MenuText(10)="Set Team Ready"
    // MenuText(11)="Toggle Spectator"
    
    MenuCommand(0)="RESPAWN"
    MenuCommand(1)="SUICIDE"
    MenuCommand(2)="DROPATOBJ"
    MenuCommand(3)="DROPATGRID"
    MenuCommand(4)="CHANGENAME"
    MenuCommand(5)="SAFETYON"
    MenuCommand(6)="SAFETYOFF"
    MenuCommand(7)="CHECKAITS"

    MenuCommand(8)="SWITCHTEAM"
    MenuCommand(9)="SAY /NOTREADY"
    MenuCommand(10)="SAY /READY"
    // MenuCommand(11)="TOGGLESPECTATOR"
}
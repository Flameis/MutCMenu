class CMenuGeneral extends CMenu;

function Initialize()
{
    if (bIsAuthorized)
    {
        MenuText.AddItem("Admin Toggle Fly");
        MenuCommand.AddItem("FLY");
        MenuText.AddItem("Admin Stop Players Drawing On The Map");
        MenuCommand.AddItem("MAPDRAWING OFF");
        MenuText.AddItem("Admin Let Players Draw On The Map");
        MenuCommand.AddItem("MAPDRAWING ON");
        MenuText.AddItem("Admin Clear Every Map Drawing");
        MenuCommand.AddItem("MAPCLEAR ALL");
    }

    super.Initialize();
}

function bool CheckExceptions(string Command)
{
    switch (Caps(Command))
    {
        case "DROPATGRID":
            if(bCMenuDebug) `Log("DropAtGrid");
            PromptForText("Drop At Grid|Grid letter A-J, number 1-10 and an optional keypad 1-9|Example: E 5 kp 5   (or: --grid E 5 kp 5, short -g)", "Mutate "$Command$" ");
            return true;
            
        case "DROPATOBJ":
            if(bCMenuDebug) `Log("DropAtObj");
            PromptForText("Drop At Objective|The objective letter|Example: A   (or: --obj A, short -o)", "Mutate "$Command$" ");
            return true;

        case "CHANGENAME":
            if(bCMenuDebug) `Log("CHANGENAME");
            PromptForText("Change Name|Type your desired name|Example: T/4 Scovel [29ID]   (or: --name T/4 Scovel [29ID], short -n)", "Mutate "$Command$" ");
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
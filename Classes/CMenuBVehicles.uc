class CMenuBVehicles extends CMenuBBase;

simulated state MenuVisible
{
	function BeginState(name PreviousStateName)
	{
        local class<ROVehicle>          VehicleClass;

        super.BeginState(PreviousStateName);

		if (InStr(TargetName, "Heli",,true) != -1 || InStr(TargetName, "Vehicle",,true) != -1)
		{
            LastCmd = TargetName;
            VehicleClass = class<ROVehicle>(DynamicLoadObject(LastCmd, class'Class'));
            ReferenceSkeletalMesh[0] = VehicleClass.default.Mesh.SkeletalMesh;
            ModifyLoc.z = 140;
            GoToState('ReadyToPlace',, true);
		}
	}
}

function bool CheckExceptions(string Command)
{
    local class<ROVehicle>          VehicleClass;

    if (Command == "CUSTOM")
    {
        LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr="mutate CMenuBuilder ";
        LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStrPos=Len(LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr); // set the value high in case name is quite long
        LocalPlayer(PC.Player).ViewportClient.ViewportConsole.GoToState('Typing');
        LocalPlayer(PC.Player).ViewportClient.ClearProgressMessages();
        LocalPlayer(PC.Player).ViewportClient.SetProgressTime(6);
        MessageSelf("Please Type Your Desired Vehicle (Example: ROGameContent.ROHeli_AH1G_Content)");
        return true;
    }

    VehicleClass = class<ROVehicle>(DynamicLoadObject(Command, class'Class'));
    ReferenceSkeletalMesh[0] = VehicleClass.default.Mesh.SkeletalMesh;
    ModifyLoc.z = 140;

    GoToState('ReadyToPlace',, true);
    return true;
}

function DoPlace()
{
	MyDA.SpawnVehicle(LastCmd, PlaceLoc, PlaceRot);
}

defaultproperties
{
    MenuName="VEHICLES"

    MenuText.add("Custom")
    MenuText.add("Cobra")
    MenuText.add("Loach")
    MenuText.add("Huey")
    MenuText.add("Bushranger")
    MenuText.add("ACCobra")
    MenuText.add("ACLoach")
    MenuText.add("ACHuey")
    MenuText.add("ACBushranger")

    MenuText.add("BlueHuey")
    MenuText.add("GreenHuey")
    MenuText.add("GreenBushranger")
    MenuText.add("M113 ACAV")
    MenuText.add("MUTT")
    MenuText.add("T34")
    MenuText.add("M113 ARVN")
    MenuText.add("T54")

    MenuText.add("T20")
    MenuText.add("T26")
    MenuText.add("T28")
    MenuText.add("HT130")
    MenuText.add("ATGun")
    MenuText.add("Vickers")
    MenuText.add("Skis")
    
    MenuCommand.add("CUSTOM")
    MenuCommand.add("ROGameContent.ROHeli_AH1G_Content")
    MenuCommand.add("ROGameContent.ROHeli_OH6_Content")
    MenuCommand.add("ROGameContent.ROHeli_UH1H_Content")
    MenuCommand.add("ROGameContent.ROHeli_UH1H_Gunship_Content")
    MenuCommand.add("MutExtrasTB.ACHeli_AH1G_Content")
    MenuCommand.add("MutExtrasTB.ACHeli_OH6_Content")
    MenuCommand.add("MutExtrasTB.ACHeli_UH1H_Content")
    MenuCommand.add("MutExtrasTB.ACHeli_UH1H_Gunship_Content")

    MenuCommand.add("GreenMenMod.GMHeli_Blue_UH1H")
    MenuCommand.add("GreenMenMod.GMHeli_Green_UH1H")
    MenuCommand.add("GreenMenMod.GMHeli_Green_UH1H_Gunship_Content")
    MenuCommand.add("GOM3.GOMVehicle_M113_ACAV_ActualContent")
    MenuCommand.add("GOM4.GOMVehicle_M151_MUTT_US")
    MenuCommand.add("GOM4.GOMVehicle_T34_ActualContent")
    MenuCommand.add("GOM4.GOMVehicle_M113_APC_ARVN")
    MenuCommand.add("GOM4.GOMVehicle_T54_ActualContent")
    
    MenuCommand.add("WinterWar.WWVehicle_T20_ActualContent")
    MenuCommand.add("WinterWar.WWVehicle_T26_EarlyWar_ActualContent")
    MenuCommand.add("WinterWar.WWVehicle_T28_ActualContent")
    MenuCommand.add("WinterWar.WWVehicle_HT130_ActualContent")
    MenuCommand.add("WinterWar.WWVehicle_53K_ActualContent")
    MenuCommand.add("WinterWar.WWVehicle_Vickers_ActualContent")
    MenuCommand.add("WinterWar.WWVehicle_Skis_ActualContent")
}
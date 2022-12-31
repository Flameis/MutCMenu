class CMenuBVehicles extends CMenuBBase;

function bool CheckExceptions(string Command)
{
    local class<ROVehicle>          VehicleClass;

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
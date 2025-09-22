class CMenuBVehicles extends CMenuB;

function Initialize()
{
    local class<ROVehicle>          VehicleClass;

    super.Initialize();

    LastCmd = TargetName;
	if (InStr(TargetName, "Heli",,true) != -1 || InStr(TargetName, "Vehicle",,true) != -1)
	{
        if (CheckMutsLoaded(TargetName) == false)
            return;
        VehicleClass = class<ROVehicle>(DynamicLoadObject(LastCmd, class'Class'));
        ReferenceSkeletalMesh[0] = VehicleClass.default.Mesh.SkeletalMesh;
        ModifyLoc.z = 140;
        GoToState('ReadyToPlace',, true);
	}
}

function bool CheckExceptions(string Command)
{
    local class<ROVehicle>          VehicleClass;

    switch (Command)
    {
        case "CUSTOM":
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr="mutate CMENU CMenuBVehicles to ";
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStrPos=Len(LocalPlayer(PC.Player).ViewportClient.ViewportConsole.TypedStr); // set the value high in case name is quite long
            LocalPlayer(PC.Player).ViewportClient.ViewportConsole.GoToState('Typing');
            LocalPlayer(PC.Player).ViewportClient.ClearProgressMessages();
            LocalPlayer(PC.Player).ViewportClient.SetProgressTime(6);
            MessageSelf("Please Type Your Desired Vehicle (Example: ROGameContent.ROHeli_AH1G_Content)");
            GoToState('ReadyToPlace',, true);
            return true;

        case "CLEARALLVICS":
            MyDa.ClearAllVehicles();
            MessageSelf("All vehicles have been cleared.");
            return true;
    }
    if (InStr(Command, "Heli",,true) != -1 || InStr(Command, "Vehicle",,true) != -1)
    {
        if (CheckMutsLoaded(Command) == false)
            return true;
        LastCmd = Command;
        VehicleClass = class<ROVehicle>(DynamicLoadObject(Command, class'Class'));
        ReferenceSkeletalMesh[0] = VehicleClass.default.Mesh.SkeletalMesh;
        ModifyLoc.z = 140;

        GoToState('ReadyToPlace',, true);
        return true;
    }
    return false;
}

function DoPlace()
{
    if (CheckMutsLoaded(LastCmd) == false)
        return;
	MyDA.SpawnVehicle(LastCmd, PlaceLoc, PlaceRot);
}

defaultproperties
{
    MenuName="VEHICLES"

    MenuText.add("Custom")
    MenuText.add("Clear All Vehicles")
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
    MenuText.add("GOM3 M113 ACAV")
    MenuText.add("GOM4 MUTT")
    MenuText.add("GOM4 T34")

    MenuText.add("GOM4 M113 ARVN")
    MenuText.add("GOM4 T54")
    MenuText.add("WW T20")
    MenuText.add("WW T26")
    MenuText.add("WW T28")
    MenuText.add("WW HT130")
    MenuText.add("WW ATGun")
    MenuText.add("WW Vickers")

    MenuText.add("WW2 WW Skis")
    MenuText.add("WW2 Churchill Mk VII")
    MenuText.add("WW2 Crusader Mk III")
    MenuText.add("WW2 Ha-Go")
    MenuText.add("WW2 Kubelwagen")
    MenuText.add("WW2 Panzer III")
    MenuText.add("WW2 Panzer IV F2")
    MenuText.add("WW2 SdKfz 222 Recon")

    MenuText.add("WW2 SdKfz 251 Halftrack")
    MenuText.add("WW2 Semovente")
    MenuText.add("WW2 Sherman III")
    MenuText.add("WW2 Stuart M3")
    MenuText.add("WW2 Stug III G")
    MenuText.add("WW2 T-34")
    MenuText.add("WW2 T-70")
    MenuText.add("WW2 UC Bren")

    MenuText.add("WW2 UC")
    MenuText.add("WW2 Valentine")
    MenuText.add("WW2 Willys")

    MenuCommand.add("CUSTOM")
    MenuCommand.add("CLEARALLVICS")
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
    MenuCommand.add("WW2.WW2Vehicle_ChurchillMkVII_Content")
    MenuCommand.add("WW2.WW2Vehicle_CrusaderMkIII_Content")
    MenuCommand.add("WW2.WW2Vehicle_HaGo_Content")
    MenuCommand.add("WW2.WW2Vehicle_Kubelwagen_Content")
    MenuCommand.add("WW2.WW2Vehicle_PanzerIII_Content")
    MenuCommand.add("WW2.WW2Vehicle_PanzerIVF_Content")
    MenuCommand.add("WW2.WW2Vehicle_SdKfz_222_Recon_Content")

    MenuCommand.add("WW2.WW2Vehicle_SdKfz_251_Halftrack_Content")
    MenuCommand.add("WW2.WW2Vehicle_Semovente_Content")
    MenuCommand.add("WW2.WW2Vehicle_ShermanIII_Content")
    MenuCommand.add("WW2.WW2Vehicle_StuartM3_Content")
    MenuCommand.add("WW2.WW2Vehicle_StugIIIG_Content")
    MenuCommand.add("WW2.WW2Vehicle_T34_Content")
    MenuCommand.add("WW2.WW2Vehicle_T70_Content")
    MenuCommand.add("WW2.WW2Vehicle_UC_Bren_Content")

    MenuCommand.add("WW2.WW2Vehicle_UC_Content")
    MenuCommand.add("WW2.WW2Vehicle_Valentine_Content")
    MenuCommand.add("WW2.WW2Vehicle_Willys_Content")

}
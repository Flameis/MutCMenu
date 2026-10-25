class CMenuBVehicles extends CMenuB;

function Initialize()
{
    local class<ROVehicle>          VehicleClass;

    MessageSelf("Mods enabled: " $
        (MyDA.bLoadGOM3 ? "GOM3 " : "") $
        (MyDA.bLoadGOM4 ? "GOM4 " : "") $
        (MyDA.bLoadExtras ? "MutExtras " : "") $
        (MyDA.bLoadWW ? "WW " : "") $
        (MyDA.bLoadWW2 ? "WW2 " : "")
    );
    MessageSelf("Enable the desired mod in the CMenu webadmin mutator settings to spawn vehicles.");

    if (bIsAuthorized)
    {
        MenuText.InsertItem(1, "Clear All Vehicles");
        MenuCommand.InsertItem(1, "CLEARVICS");
    }

    AddModOptions();

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
            PromptForText("Custom Vehicle|--item / -i : the full name of the vehicle to place (already typed for you, add the name)|Example: --item ROGameContent.ROHeli_AH1G_Content|Older form: mutate cmenu CMenuBVehicles to ROGameContent.ROHeli_AH1G_Content", "mutate cmenu --menu CMenuBVehicles --item ");
            GoToState('ReadyToPlace',, true);
            return true;

        case "DELETEVEHICLE":
            MyDA.DeleteActor(ROVehicle(TraceActors()));
            MessageSelf("The vehicle has been deleted.");
            return true;

        case "CLEARVICS":
            MyDA.ClearAllVehicles();
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

function AddModOptions()
{
    // Every vehicle WW2.u has that can be placed. Its Churchill (_Content) is abstract, so it can't be.
    if (MyDA.bLoadWW2)
    {
        MenuText.additem("WW2 Crusader Mk III");
        MenuText.additem("WW2 Ha-Go");
        MenuText.additem("WW2 LVT");
        MenuText.additem("WW2 M13");
        MenuText.additem("WW2 Panzer III");
        MenuText.additem("WW2 Panzer IV F");
        MenuText.additem("WW2 SdKfz 251 Halftrack");
        MenuText.additem("WW2 Semovente");

        MenuText.additem("WW2 Sherman II");
        MenuText.additem("WW2 Sherman III");
        MenuText.additem("WW2 Stuart");
        MenuText.additem("WW2 Stug III G");
        MenuText.additem("WW2 T-34");
        MenuText.additem("WW2 T-70");
        MenuText.additem("WW2 UC Bren");
        MenuText.additem("WW2 UC");

        MenuCommand.additem("WW2.WW2Vehicle_CrusaderMkIII_Content");
        MenuCommand.additem("WW2.WW2Vehicle_HaGo_Content");
        MenuCommand.additem("WW2.WW2Vehicle_LVT_Content");
        MenuCommand.additem("WW2.WW2Vehicle_M13_Content");
        MenuCommand.additem("WW2.WW2Vehicle_PanzerIII_Content");
        MenuCommand.additem("WW2.WW2Vehicle_PanzerIVF_Content");
        MenuCommand.additem("WW2.WW2Vehicle_SdKfz_251_Halftrack_Content");
        MenuCommand.additem("WW2.WW2Vehicle_Semovente_Content");

        MenuCommand.additem("WW2.WW2Vehicle_ShermanII_Content");
        MenuCommand.additem("WW2.WW2Vehicle_ShermanIII_Content");
        MenuCommand.additem("WW2.WW2Vehicle_Stuart_Content");
        MenuCommand.additem("WW2.WW2Vehicle_StugIIIG_Content");
        MenuCommand.additem("WW2.WW2Vehicle_T34_Content");
        MenuCommand.additem("WW2.WW2Vehicle_T70_Content");
        MenuCommand.additem("WW2.WW2Vehicle_UC_Bren_Content");
        MenuCommand.additem("WW2.WW2Vehicle_UC_Content");
    }

    if (MyDA.bLoadWW)
    {
        MenuText.additem("WW T20");
        MenuText.additem("WW T26");
        MenuText.additem("WW T28");
        MenuText.additem("WW HT130");
        MenuText.additem("WW ATGun");
        MenuText.additem("WW Vickers");
        MenuText.additem("WW Skis");

        MenuCommand.additem("WinterWar.WWVehicle_T20_ActualContent");
        MenuCommand.additem("WinterWar.WWVehicle_T26_EarlyWar_ActualContent");
        MenuCommand.additem("WinterWar.WWVehicle_T28_ActualContent");
        MenuCommand.additem("WinterWar.WWVehicle_HT130_ActualContent");
        MenuCommand.additem("WinterWar.WWVehicle_53K_ActualContent");
        MenuCommand.additem("WinterWar.WWVehicle_Vickers_ActualContent");
        MenuCommand.additem("WinterWar.WWVehicle_Skis_ActualContent");
    }

    if (MyDA.bLoadGOM3)
    {
        MenuText.additem("GOM3 M113 ACAV");

        MenuCommand.additem("GOM3.GOMVehicle_M113_ACAV_ActualContent");
    }

    if (MyDA.bLoadGOM4)
    {
        MenuText.additem("GOM4 MUTT");
        MenuText.additem("GOM4 T34");

        MenuText.additem("GOM4 M113 ARVN");
        MenuText.additem("GOM4 T54");

        MenuCommand.additem("GOM4.GOMVehicle_M151_MUTT_US");
        MenuCommand.additem("GOM4.GOMVehicle_T34_ActualContent");

        MenuCommand.additem("GOM4.GOMVehicle_M113_APC_ARVN");
        MenuCommand.additem("GOM4.GOMVehicle_T54_ActualContent");
    }

    if (MyDA.bLoadExtras)
    {
        MenuText.additem("MutExtras AC Cobra");
        MenuText.additem("MutExtras AC Loach");
        MenuText.additem("MutExtras AC Huey");
        MenuText.additem("MutExtras AC Bushranger");

        MenuCommand.additem("MutExtras.ACHeli_AH1G_Content");
        MenuCommand.additem("MutExtras.ACHeli_OH6_Content");
        MenuCommand.additem("MutExtras.ACHeli_UH1H_Content");
        MenuCommand.additem("MutExtras.ACHeli_UH1H_Gunship_Content");
    }
}

defaultproperties
{
    MenuName="VEHICLES"

    bCanScale=false // A vehicle is always placed at its own size

    MenuText.add("Delete Vehicle")
    MenuText.add("Custom")
    MenuText.add("Cobra")
    MenuText.add("Loach")
    MenuText.add("Huey")
    MenuText.add("Bushranger")

    MenuText.add("BlueHuey")
    MenuText.add("GreenHuey")
    MenuText.add("GreenBushranger")

    MenuCommand.add("DELETEVEHICLE")
    MenuCommand.add("CUSTOM")
    MenuCommand.add("ROGameContent.ROHeli_AH1G_Content")
    MenuCommand.add("ROGameContent.ROHeli_OH6_Content")
    MenuCommand.add("ROGameContent.ROHeli_UH1H_Content")
    MenuCommand.add("ROGameContent.ROHeli_UH1H_Gunship_Content")

    MenuCommand.add("GreenMenMod.GMHeli_Blue_UH1H")
    MenuCommand.add("GreenMenMod.GMHeli_Green_UH1H")
    MenuCommand.add("GreenMenMod.GMHeli_Green_UH1H_Gunship_Content")
}

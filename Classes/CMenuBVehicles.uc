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
            PromptForText("Custom Vehicle|--item / -i : the full name of the vehicle to place (already typed for you, add the name)|Example: --item ROGameContent.ROHeli_AH1G_Content|Older form: mutate cmenu CMenuBVehicles to ROGameContent.ROHeli_AH1G_Content", "mutate cmenu --menu CMenuBVehicles --item ", , "item");
            // In mouse click mode a form asks for the item; running it opens this menu for that item
            if (!IsInState('FormVisible'))
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
    local array<string> Names, Paths;
    local int i;

    GetModVehicles(MyDA.bLoadWW2, MyDA.bLoadWW, MyDA.bLoadGOM3, MyDA.bLoadGOM4, MyDA.bLoadExtras, Names, Paths);
    for (i = 0; i < Paths.Length; i++)
    {
        MenuText.AddItem(Names[i]);
        MenuCommand.AddItem(Paths[i]);
    }
}

// The vehicles of the mods that are on, with their menu names
static function GetModVehicles(bool bWW2, bool bWW, bool bGOM3, bool bGOM4, bool bExtras, out array<string> Names, out array<string> Paths)
{
    // Every vehicle WW2.u has that can be placed. Its Churchill (_Content) is abstract, so it can't be.
    if (bWW2)
    {
        Names.AddItem("WW2 Crusader Mk III");
        Names.AddItem("WW2 Ha-Go");
        Names.AddItem("WW2 LVT");
        Names.AddItem("WW2 M13");
        Names.AddItem("WW2 Panzer III");
        Names.AddItem("WW2 Panzer IV F");
        Names.AddItem("WW2 SdKfz 251 Halftrack");
        Names.AddItem("WW2 Semovente");

        Names.AddItem("WW2 Sherman II");
        Names.AddItem("WW2 Sherman III");
        Names.AddItem("WW2 Stuart");
        Names.AddItem("WW2 Stug III G");
        Names.AddItem("WW2 T-34");
        Names.AddItem("WW2 T-70");
        Names.AddItem("WW2 UC Bren");
        Names.AddItem("WW2 UC");

        Paths.AddItem("WW2.WW2Vehicle_CrusaderMkIII_Content");
        Paths.AddItem("WW2.WW2Vehicle_HaGo_Content");
        Paths.AddItem("WW2.WW2Vehicle_LVT_Content");
        Paths.AddItem("WW2.WW2Vehicle_M13_Content");
        Paths.AddItem("WW2.WW2Vehicle_PanzerIII_Content");
        Paths.AddItem("WW2.WW2Vehicle_PanzerIVF_Content");
        Paths.AddItem("WW2.WW2Vehicle_SdKfz_251_Halftrack_Content");
        Paths.AddItem("WW2.WW2Vehicle_Semovente_Content");

        Paths.AddItem("WW2.WW2Vehicle_ShermanII_Content");
        Paths.AddItem("WW2.WW2Vehicle_ShermanIII_Content");
        Paths.AddItem("WW2.WW2Vehicle_Stuart_Content");
        Paths.AddItem("WW2.WW2Vehicle_StugIIIG_Content");
        Paths.AddItem("WW2.WW2Vehicle_T34_Content");
        Paths.AddItem("WW2.WW2Vehicle_T70_Content");
        Paths.AddItem("WW2.WW2Vehicle_UC_Bren_Content");
        Paths.AddItem("WW2.WW2Vehicle_UC_Content");
    }

    if (bWW)
    {
        Names.AddItem("WW T20");
        Names.AddItem("WW T26");
        Names.AddItem("WW T28");
        Names.AddItem("WW HT130");
        Names.AddItem("WW ATGun");
        Names.AddItem("WW Vickers");
        Names.AddItem("WW Skis");

        Paths.AddItem("WinterWar.WWVehicle_T20_ActualContent");
        Paths.AddItem("WinterWar.WWVehicle_T26_EarlyWar_ActualContent");
        Paths.AddItem("WinterWar.WWVehicle_T28_ActualContent");
        Paths.AddItem("WinterWar.WWVehicle_HT130_ActualContent");
        Paths.AddItem("WinterWar.WWVehicle_53K_ActualContent");
        Paths.AddItem("WinterWar.WWVehicle_Vickers_ActualContent");
        Paths.AddItem("WinterWar.WWVehicle_Skis_ActualContent");
    }

    if (bGOM3)
    {
        Names.AddItem("GOM3 M113 ACAV");

        Paths.AddItem("GOM3.GOMVehicle_M113_ACAV_ActualContent");
    }

    if (bGOM4)
    {
        Names.AddItem("GOM4 MUTT");
        Names.AddItem("GOM4 T34");

        Names.AddItem("GOM4 M113 ARVN");
        Names.AddItem("GOM4 T54");

        Paths.AddItem("GOM4.GOMVehicle_M151_MUTT_US");
        Paths.AddItem("GOM4.GOMVehicle_T34_ActualContent");

        Paths.AddItem("GOM4.GOMVehicle_M113_APC_ARVN");
        Paths.AddItem("GOM4.GOMVehicle_T54_ActualContent");
    }

    if (bExtras)
    {
        Names.AddItem("MutExtras AC Cobra");
        Names.AddItem("MutExtras AC Loach");
        Names.AddItem("MutExtras AC Huey");
        Names.AddItem("MutExtras AC Bushranger");

        Paths.AddItem("MutExtras.ACHeli_AH1G_Content");
        Paths.AddItem("MutExtras.ACHeli_OH6_Content");
        Paths.AddItem("MutExtras.ACHeli_UH1H_Content");
        Paths.AddItem("MutExtras.ACHeli_UH1H_Gunship_Content");
    }
}

defaultproperties
{
    MenuName="VEHICLES"

    bCanScale=false // A vehicle is always placed at its own size
    BuildWhat=Vehicle

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

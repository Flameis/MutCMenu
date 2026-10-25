class MutCMenuSettings extends MutatorSettings
	config(MutCMenu_Server);

/**
 * @brief Initializes the settings screen for this mutator
 */
function InitMutSettings()
{
	//Bool
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bLoadExtras", ".", "_")), int(class'MutCMenu'.default.bLoadExtras)); }
	else { self.SetIntPropertyByName(name(Repl("bLoadExtras", ".", "_")), int(MutCMenu(myMut).bLoadExtras)); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bLoadGOM3", ".", "_")), int(class'MutCMenu'.default.bLoadGOM3)); }
	else { self.SetIntPropertyByName(name(Repl("bLoadGOM3", ".", "_")), int(MutCMenu(myMut).bLoadGOM3)); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bLoadGOM4", ".", "_")), int(class'MutCMenu'.default.bLoadGOM4)); }
	else { self.SetIntPropertyByName(name(Repl("bLoadGOM4", ".", "_")), int(MutCMenu(myMut).bLoadGOM4)); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bLoadWW", ".", "_")), int(class'MutCMenu'.default.bLoadWW)); }
	else { self.SetIntPropertyByName(name(Repl("bLoadWW", ".", "_")), int(MutCMenu(myMut).bLoadWW)); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bLoadWW2", ".", "_")), int(class'MutCMenu'.default.bLoadWW2)); }
	else { self.SetIntPropertyByName(name(Repl("bLoadWW2", ".", "_")), int(MutCMenu(myMut).bLoadWW2)); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bNewTankPhys", ".", "_")), int(class'MutCMenu'.default.bNewTankPhys)); }
	else { self.SetIntPropertyByName(name(Repl("bNewTankPhys", ".", "_")), int(MutCMenu(myMut).bNewTankPhys)); }

	// Match settings
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bDebugStandalone", ".", "_")), int(class'MutCMenu'.default.bDebugStandalone)); }
	else { self.SetIntPropertyByName(name(Repl("bDebugStandalone", ".", "_")), int(MutCMenu(myMut).bDebugStandalone)); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bFSPlayersCanCall", ".", "_")), int(class'MutCMenu'.default.bFSPlayersCanCall)); }
	else { self.SetIntPropertyByName(name(Repl("bFSPlayersCanCall", ".", "_")), int(MutCMenu(myMut).bFSPlayersCanCall)); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bFSNoFriendlyFire", ".", "_")), int(class'MutCMenu'.default.bFSNoFriendlyFire)); }
	else { self.SetIntPropertyByName(name(Repl("bFSNoFriendlyFire", ".", "_")), int(MutCMenu(myMut).bFSNoFriendlyFire)); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bFSSilent", ".", "_")), int(class'MutCMenu'.default.bFSSilent)); }
	else { self.SetIntPropertyByName(name(Repl("bFSSilent", ".", "_")), int(MutCMenu(myMut).bFSSilent)); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bCTFSilent", ".", "_")), int(class'MutCMenu'.default.bCTFSilent)); }
	else { self.SetIntPropertyByName(name(Repl("bCTFSilent", ".", "_")), int(MutCMenu(myMut).bCTFSilent)); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("FSPlayerCooldown", ".", "_")), class'MutCMenu'.default.FSPlayerCooldown); }
	else { self.SetIntPropertyByName(name(Repl("FSPlayerCooldown", ".", "_")), MutCMenu(myMut).FSPlayerCooldown); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("FSBomberCount", ".", "_")), class'MutCMenu'.default.FSBomberCount); }
	else { self.SetIntPropertyByName(name(Repl("FSBomberCount", ".", "_")), MutCMenu(myMut).FSBomberCount); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("FSGunshipDuration", ".", "_")), class'MutCMenu'.default.FSGunshipDuration); }
	else { self.SetIntPropertyByName(name(Repl("FSGunshipDuration", ".", "_")), MutCMenu(myMut).FSGunshipDuration); }

	// Overhead map
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bDisableEnhancedSpectator", ".", "_")), int(class'MutCMenu'.default.bDisableEnhancedSpectator)); }
	else { self.SetIntPropertyByName(name(Repl("bDisableEnhancedSpectator", ".", "_")), int(MutCMenu(myMut).bDisableEnhancedSpectator)); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bDisableMapDrawing", ".", "_")), int(class'MutCMenu'.default.bDisableMapDrawing)); }
	else { self.SetIntPropertyByName(name(Repl("bDisableMapDrawing", ".", "_")), int(MutCMenu(myMut).bDisableMapDrawing)); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bKeepMapDrawingsBetweenRounds", ".", "_")), int(class'MutCMenu'.default.bKeepMapDrawingsBetweenRounds)); }
	else { self.SetIntPropertyByName(name(Repl("bKeepMapDrawingsBetweenRounds", ".", "_")), int(MutCMenu(myMut).bKeepMapDrawingsBetweenRounds)); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("MaxMapDrawingsPerPlayer", ".", "_")), class'MutCMenu'.default.MaxMapDrawingsPerPlayer); }
	else { self.SetIntPropertyByName(name(Repl("MaxMapDrawingsPerPlayer", ".", "_")), MutCMenu(myMut).MaxMapDrawingsPerPlayer); }

}

/**
 * @brief Saves the settings for this mutator
 */
function SaveMutSettings()
{
	//Bool
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bLoadExtras", ".", "_")), tempValue); class'MutCMenu'.default.bLoadExtras = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bLoadExtras", ".", "_")), tempValue); MutCMenu(self.myMut).bLoadExtras = (self.tempValue != 0); }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bLoadGOM3", ".", "_")), tempValue); class'MutCMenu'.default.bLoadGOM3 = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bLoadGOM3", ".", "_")), tempValue); MutCMenu(self.myMut).bLoadGOM3 = (self.tempValue != 0); }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bLoadGOM4", ".", "_")), tempValue); class'MutCMenu'.default.bLoadGOM4 = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bLoadGOM4", ".", "_")), tempValue); MutCMenu(self.myMut).bLoadGOM4 = (self.tempValue != 0); }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bLoadWW", ".", "_")), tempValue); class'MutCMenu'.default.bLoadWW = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bLoadWW", ".", "_")), tempValue); MutCMenu(self.myMut).bLoadWW = (self.tempValue != 0); }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bLoadWW2", ".", "_")), tempValue); class'MutCMenu'.default.bLoadWW2 = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bLoadWW2", ".", "_")), tempValue); MutCMenu(self.myMut).bLoadWW2 = (self.tempValue != 0); }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bNewTankPhys", ".", "_")), tempValue); class'MutCMenu'.default.bNewTankPhys = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bNewTankPhys", ".", "_")), tempValue); MutCMenu(self.myMut).bNewTankPhys = (self.tempValue != 0); }

	// Match settings
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bDebugStandalone", ".", "_")), tempValue); class'MutCMenu'.default.bDebugStandalone = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bDebugStandalone", ".", "_")), tempValue); MutCMenu(self.myMut).bDebugStandalone = (self.tempValue != 0); }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bFSPlayersCanCall", ".", "_")), tempValue); class'MutCMenu'.default.bFSPlayersCanCall = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bFSPlayersCanCall", ".", "_")), tempValue); MutCMenu(self.myMut).bFSPlayersCanCall = (self.tempValue != 0); }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bFSNoFriendlyFire", ".", "_")), tempValue); class'MutCMenu'.default.bFSNoFriendlyFire = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bFSNoFriendlyFire", ".", "_")), tempValue); MutCMenu(self.myMut).bFSNoFriendlyFire = (self.tempValue != 0); }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bFSSilent", ".", "_")), tempValue); class'MutCMenu'.default.bFSSilent = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bFSSilent", ".", "_")), tempValue); MutCMenu(self.myMut).bFSSilent = (self.tempValue != 0); }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bCTFSilent", ".", "_")), tempValue); class'MutCMenu'.default.bCTFSilent = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bCTFSilent", ".", "_")), tempValue); MutCMenu(self.myMut).bCTFSilent = (self.tempValue != 0); }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("FSPlayerCooldown", ".", "_")), tempValue); class'MutCMenu'.default.FSPlayerCooldown = self.tempValue; }
	else { self.GetIntPropertyByName(name(Repl("FSPlayerCooldown", ".", "_")), tempValue); MutCMenu(self.myMut).FSPlayerCooldown = self.tempValue; }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("FSBomberCount", ".", "_")), tempValue); class'MutCMenu'.default.FSBomberCount = self.tempValue; }
	else { self.GetIntPropertyByName(name(Repl("FSBomberCount", ".", "_")), tempValue); MutCMenu(self.myMut).FSBomberCount = self.tempValue; }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("FSGunshipDuration", ".", "_")), tempValue); class'MutCMenu'.default.FSGunshipDuration = self.tempValue; }
	else { self.GetIntPropertyByName(name(Repl("FSGunshipDuration", ".", "_")), tempValue); MutCMenu(self.myMut).FSGunshipDuration = self.tempValue; }


	// Overhead map
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bDisableEnhancedSpectator", ".", "_")), tempValue); class'MutCMenu'.default.bDisableEnhancedSpectator = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bDisableEnhancedSpectator", ".", "_")), tempValue); MutCMenu(myMut).bDisableEnhancedSpectator = (self.tempValue != 0); }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bDisableMapDrawing", ".", "_")), tempValue); class'MutCMenu'.default.bDisableMapDrawing = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bDisableMapDrawing", ".", "_")), tempValue); MutCMenu(myMut).bDisableMapDrawing = (self.tempValue != 0); }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bKeepMapDrawingsBetweenRounds", ".", "_")), tempValue); class'MutCMenu'.default.bKeepMapDrawingsBetweenRounds = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bKeepMapDrawingsBetweenRounds", ".", "_")), tempValue); MutCMenu(myMut).bKeepMapDrawingsBetweenRounds = (self.tempValue != 0); }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("MaxMapDrawingsPerPlayer", ".", "_")), tempValue); class'MutCMenu'.default.MaxMapDrawingsPerPlayer = Max(self.tempValue, 0); }
	else { self.GetIntPropertyByName(name(Repl("MaxMapDrawingsPerPlayer", ".", "_")), tempValue); MutCMenu(myMut).MaxMapDrawingsPerPlayer = Max(self.tempValue, 0); }

    if (self.myMut != None)
		self.myMut.SaveConfig();
	else
		class'MutCMenu'.static.StaticSaveConfig();
}


// The WebAdmin page: one tab per group, a plain label for each setting, and every on/off setting as On / Off
// buttons (a value mapping of 0 and 1). Settings with a few fixed values get them as choices; four or more show
// as a drop-down list. The group names, labels and choice names are localized, so they are in the .int file
// (Localization\INT, section [<this class>]), in the same order as below.
defaultproperties
{
    SettingsGroups.Add((GroupID="Content",pMin=600,pMax=610,lMin=0,lMax=0))
    SettingsGroups.Add((GroupID="FireSupport",pMin=610,pMax=620,lMin=0,lMax=0))
    SettingsGroups.Add((GroupID="Map",pMin=620,pMax=630,lMin=0,lMax=0))
    SettingsGroups.Add((GroupID="CTF",pMin=630,pMax=640,lMin=0,lMax=0))

    // Mod content
    Properties.Add((PropertyId=600,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=600,Name="bLoadExtras",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
    Properties.Add((PropertyId=601,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=601,Name="bLoadGOM3",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
    Properties.Add((PropertyId=602,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=602,Name="bLoadGOM4",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
    Properties.Add((PropertyId=603,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=603,Name="bLoadWW",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
    Properties.Add((PropertyId=604,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=604,Name="bLoadWW2",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
    Properties.Add((PropertyId=605,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=605,Name="bDebugStandalone",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
    Properties.Add((PropertyId=606,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=606,Name="bNewTankPhys",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))

    // Fire support
    Properties.Add((PropertyId=610,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=610,Name="bFSPlayersCanCall",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
    Properties.Add((PropertyId=611,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=611,Name="bFSNoFriendlyFire",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
    Properties.Add((PropertyId=612,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=612,Name="bFSSilent",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
    Properties.Add((PropertyId=613,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=613,Name="FSPlayerCooldown"))
    Properties.Add((PropertyId=614,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=614,Name="FSBomberCount",MappingType=PVMT_IdMapped,ValueMappings=((Id=1),(Id=2))))
    Properties.Add((PropertyId=615,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=615,Name="FSGunshipDuration"))

    // Overhead map
    Properties.Add((PropertyId=620,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=620,Name="bDisableEnhancedSpectator",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
    Properties.Add((PropertyId=621,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=621,Name="bDisableMapDrawing",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
    Properties.Add((PropertyId=622,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=622,Name="bKeepMapDrawingsBetweenRounds",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
    Properties.Add((PropertyId=623,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=623,Name="MaxMapDrawingsPerPlayer"))

    // Capture the Flag
    Properties.Add((PropertyId=630,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=630,Name="bCTFSilent",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
}

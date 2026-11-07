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

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bTankPromptForAll", ".", "_")), int(class'MutCMenu'.default.bTankPromptForAll)); }
	else { self.SetIntPropertyByName(name(Repl("bTankPromptForAll", ".", "_")), int(MutCMenu(myMut).bTankPromptForAll)); }

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

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bDisableSpectatorTracers", ".", "_")), int(class'MutCMenu'.default.bDisableSpectatorTracers)); }
	else { self.SetIntPropertyByName(name(Repl("bDisableSpectatorTracers", ".", "_")), int(MutCMenu(myMut).bDisableSpectatorTracers)); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bDisableMapDrawing", ".", "_")), int(class'MutCMenu'.default.bDisableMapDrawing)); }
	else { self.SetIntPropertyByName(name(Repl("bDisableMapDrawing", ".", "_")), int(MutCMenu(myMut).bDisableMapDrawing)); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bKeepMapDrawingsBetweenRounds", ".", "_")), int(class'MutCMenu'.default.bKeepMapDrawingsBetweenRounds)); }
	else { self.SetIntPropertyByName(name(Repl("bKeepMapDrawingsBetweenRounds", ".", "_")), int(MutCMenu(myMut).bKeepMapDrawingsBetweenRounds)); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("MaxMapDrawingsPerPlayer", ".", "_")), class'MutCMenu'.default.MaxMapDrawingsPerPlayer); }
	else { self.SetIntPropertyByName(name(Repl("MaxMapDrawingsPerPlayer", ".", "_")), MutCMenu(myMut).MaxMapDrawingsPerPlayer); }

	// Capture the Flag
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("CTFMaxFlagsPerPlayer", ".", "_")), class'MutCMenu'.default.CTFMaxFlagsPerPlayer); }
	else { self.SetIntPropertyByName(name(Repl("CTFMaxFlagsPerPlayer", ".", "_")), MutCMenu(myMut).CTFMaxFlagsPerPlayer); }
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("CTFPlaceCooldown", ".", "_")), class'MutCMenu'.default.CTFPlaceCooldown); }
	else { self.SetIntPropertyByName(name(Repl("CTFPlaceCooldown", ".", "_")), MutCMenu(myMut).CTFPlaceCooldown); }

	// Builder match rules
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("BuilderMode", ".", "_")), class'MutCMenu'.default.BuilderMode); }
	else { self.SetIntPropertyByName(name(Repl("BuilderMode", ".", "_")), MutCMenu(myMut).BuilderMode); }
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bBuilderPiecesOnly", ".", "_")), int(class'MutCMenu'.default.bBuilderPiecesOnly)); }
	else { self.SetIntPropertyByName(name(Repl("bBuilderPiecesOnly", ".", "_")), int(MutCMenu(myMut).bBuilderPiecesOnly)); }
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bBuilderBudgets", ".", "_")), int(class'MutCMenu'.default.bBuilderBudgets)); }
	else { self.SetIntPropertyByName(name(Repl("bBuilderBudgets", ".", "_")), int(MutCMenu(myMut).bBuilderBudgets)); }
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("BuilderTeamPoints", ".", "_")), class'MutCMenu'.default.BuilderTeamPoints); }
	else { self.SetIntPropertyByName(name(Repl("BuilderTeamPoints", ".", "_")), MutCMenu(myMut).BuilderTeamPoints); }
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bBuilderZones", ".", "_")), int(class'MutCMenu'.default.bBuilderZones)); }
	else { self.SetIntPropertyByName(name(Repl("bBuilderZones", ".", "_")), int(MutCMenu(myMut).bBuilderZones)); }
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bRebuildLayoutEachRound", ".", "_")), int(class'MutCMenu'.default.bRebuildLayoutEachRound)); }
	else { self.SetIntPropertyByName(name(Repl("bRebuildLayoutEachRound", ".", "_")), int(MutCMenu(myMut).bRebuildLayoutEachRound)); }

	// Game modes
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("GameModeOnStart", ".", "_")), class'MutCMenu'.default.GameModeOnStart); }
	else { self.SetIntPropertyByName(name(Repl("GameModeOnStart", ".", "_")), MutCMenu(myMut).GameModeOnStart); }
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("CTFCapturesToWin", ".", "_")), class'MutCMenu'.default.CTFCapturesToWin); }
	else { self.SetIntPropertyByName(name(Repl("CTFCapturesToWin", ".", "_")), MutCMenu(myMut).CTFCapturesToWin); }
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("BombAttackers", ".", "_")), class'MutCMenu'.default.BombAttackers); }
	else { self.SetIntPropertyByName(name(Repl("BombAttackers", ".", "_")), MutCMenu(myMut).BombAttackers); }
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("BombPlantSeconds", ".", "_")), class'MutCMenu'.default.BombPlantSeconds); }
	else { self.SetIntPropertyByName(name(Repl("BombPlantSeconds", ".", "_")), MutCMenu(myMut).BombPlantSeconds); }
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("BombDefuseSeconds", ".", "_")), class'MutCMenu'.default.BombDefuseSeconds); }
	else { self.SetIntPropertyByName(name(Repl("BombDefuseSeconds", ".", "_")), MutCMenu(myMut).BombDefuseSeconds); }
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("BombFuseSeconds", ".", "_")), class'MutCMenu'.default.BombFuseSeconds); }
	else { self.SetIntPropertyByName(name(Repl("BombFuseSeconds", ".", "_")), MutCMenu(myMut).BombFuseSeconds); }
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("BombRoundMinutes", ".", "_")), class'MutCMenu'.default.BombRoundMinutes); }
	else { self.SetIntPropertyByName(name(Repl("BombRoundMinutes", ".", "_")), MutCMenu(myMut).BombRoundMinutes); }
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("ConvoyTeam", ".", "_")), class'MutCMenu'.default.ConvoyTeam); }
	else { self.SetIntPropertyByName(name(Repl("ConvoyTeam", ".", "_")), MutCMenu(myMut).ConvoyTeam); }
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("ConvoyMinutes", ".", "_")), class'MutCMenu'.default.ConvoyMinutes); }
	else { self.SetIntPropertyByName(name(Repl("ConvoyMinutes", ".", "_")), MutCMenu(myMut).ConvoyMinutes); }
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("GunGameLives", ".", "_")), class'MutCMenu'.default.GunGameLives); }
	else { self.SetIntPropertyByName(name(Repl("GunGameLives", ".", "_")), MutCMenu(myMut).GunGameLives); }
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("PaintballDamagePercent", ".", "_")), class'MutCMenu'.default.PaintballDamagePercent); }
	else { self.SetIntPropertyByName(name(Repl("PaintballDamagePercent", ".", "_")), MutCMenu(myMut).PaintballDamagePercent); }


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

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bTankPromptForAll", ".", "_")), tempValue); class'MutCMenu'.default.bTankPromptForAll = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bTankPromptForAll", ".", "_")), tempValue); MutCMenu(self.myMut).bTankPromptForAll = (self.tempValue != 0); }

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

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bDisableSpectatorTracers", ".", "_")), tempValue); class'MutCMenu'.default.bDisableSpectatorTracers = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bDisableSpectatorTracers", ".", "_")), tempValue); MutCMenu(myMut).bDisableSpectatorTracers = (self.tempValue != 0); }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bDisableMapDrawing", ".", "_")), tempValue); class'MutCMenu'.default.bDisableMapDrawing = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bDisableMapDrawing", ".", "_")), tempValue); MutCMenu(myMut).bDisableMapDrawing = (self.tempValue != 0); }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bKeepMapDrawingsBetweenRounds", ".", "_")), tempValue); class'MutCMenu'.default.bKeepMapDrawingsBetweenRounds = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bKeepMapDrawingsBetweenRounds", ".", "_")), tempValue); MutCMenu(myMut).bKeepMapDrawingsBetweenRounds = (self.tempValue != 0); }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("MaxMapDrawingsPerPlayer", ".", "_")), tempValue); class'MutCMenu'.default.MaxMapDrawingsPerPlayer = Max(self.tempValue, 0); }
	else { self.GetIntPropertyByName(name(Repl("MaxMapDrawingsPerPlayer", ".", "_")), tempValue); MutCMenu(myMut).MaxMapDrawingsPerPlayer = Max(self.tempValue, 0); }

	// Capture the Flag
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("CTFMaxFlagsPerPlayer", ".", "_")), tempValue); class'MutCMenu'.default.CTFMaxFlagsPerPlayer = Max(self.tempValue, 0); }
	else { self.GetIntPropertyByName(name(Repl("CTFMaxFlagsPerPlayer", ".", "_")), tempValue); MutCMenu(myMut).CTFMaxFlagsPerPlayer = Max(self.tempValue, 0); }
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("CTFPlaceCooldown", ".", "_")), tempValue); class'MutCMenu'.default.CTFPlaceCooldown = Max(self.tempValue, 0); }
	else { self.GetIntPropertyByName(name(Repl("CTFPlaceCooldown", ".", "_")), tempValue); MutCMenu(myMut).CTFPlaceCooldown = Max(self.tempValue, 0); }

	// Builder match rules
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("BuilderMode", ".", "_")), tempValue); class'MutCMenu'.default.BuilderMode = Clamp(self.tempValue, 0, 3); }
	else { self.GetIntPropertyByName(name(Repl("BuilderMode", ".", "_")), tempValue); MutCMenu(myMut).BuilderMode = Clamp(self.tempValue, 0, 3); }
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bBuilderPiecesOnly", ".", "_")), tempValue); class'MutCMenu'.default.bBuilderPiecesOnly = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bBuilderPiecesOnly", ".", "_")), tempValue); MutCMenu(myMut).bBuilderPiecesOnly = (self.tempValue != 0); }
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bBuilderBudgets", ".", "_")), tempValue); class'MutCMenu'.default.bBuilderBudgets = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bBuilderBudgets", ".", "_")), tempValue); MutCMenu(myMut).bBuilderBudgets = (self.tempValue != 0); }
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("BuilderTeamPoints", ".", "_")), tempValue); class'MutCMenu'.default.BuilderTeamPoints = Max(self.tempValue, 0); }
	else { self.GetIntPropertyByName(name(Repl("BuilderTeamPoints", ".", "_")), tempValue); MutCMenu(myMut).BuilderTeamPoints = Max(self.tempValue, 0); }
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bBuilderZones", ".", "_")), tempValue); class'MutCMenu'.default.bBuilderZones = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bBuilderZones", ".", "_")), tempValue); MutCMenu(myMut).bBuilderZones = (self.tempValue != 0); }
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bRebuildLayoutEachRound", ".", "_")), tempValue); class'MutCMenu'.default.bRebuildLayoutEachRound = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bRebuildLayoutEachRound", ".", "_")), tempValue); MutCMenu(myMut).bRebuildLayoutEachRound = (self.tempValue != 0); }

	// Game modes
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("GameModeOnStart", ".", "_")), tempValue); class'MutCMenu'.default.GameModeOnStart = Clamp(self.tempValue, 0, 5); }
	else { self.GetIntPropertyByName(name(Repl("GameModeOnStart", ".", "_")), tempValue); MutCMenu(myMut).GameModeOnStart = Clamp(self.tempValue, 0, 5); }
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("CTFCapturesToWin", ".", "_")), tempValue); class'MutCMenu'.default.CTFCapturesToWin = Max(self.tempValue, 0); }
	else { self.GetIntPropertyByName(name(Repl("CTFCapturesToWin", ".", "_")), tempValue); MutCMenu(myMut).CTFCapturesToWin = Max(self.tempValue, 0); }
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("BombAttackers", ".", "_")), tempValue); class'MutCMenu'.default.BombAttackers = Clamp(self.tempValue, 0, 1); }
	else { self.GetIntPropertyByName(name(Repl("BombAttackers", ".", "_")), tempValue); MutCMenu(myMut).BombAttackers = Clamp(self.tempValue, 0, 1); }
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("BombPlantSeconds", ".", "_")), tempValue); class'MutCMenu'.default.BombPlantSeconds = Max(self.tempValue, 0); }
	else { self.GetIntPropertyByName(name(Repl("BombPlantSeconds", ".", "_")), tempValue); MutCMenu(myMut).BombPlantSeconds = Max(self.tempValue, 0); }
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("BombDefuseSeconds", ".", "_")), tempValue); class'MutCMenu'.default.BombDefuseSeconds = Max(self.tempValue, 0); }
	else { self.GetIntPropertyByName(name(Repl("BombDefuseSeconds", ".", "_")), tempValue); MutCMenu(myMut).BombDefuseSeconds = Max(self.tempValue, 0); }
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("BombFuseSeconds", ".", "_")), tempValue); class'MutCMenu'.default.BombFuseSeconds = Max(self.tempValue, 0); }
	else { self.GetIntPropertyByName(name(Repl("BombFuseSeconds", ".", "_")), tempValue); MutCMenu(myMut).BombFuseSeconds = Max(self.tempValue, 0); }
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("BombRoundMinutes", ".", "_")), tempValue); class'MutCMenu'.default.BombRoundMinutes = Max(self.tempValue, 0); }
	else { self.GetIntPropertyByName(name(Repl("BombRoundMinutes", ".", "_")), tempValue); MutCMenu(myMut).BombRoundMinutes = Max(self.tempValue, 0); }
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("ConvoyTeam", ".", "_")), tempValue); class'MutCMenu'.default.ConvoyTeam = Clamp(self.tempValue, 0, 1); }
	else { self.GetIntPropertyByName(name(Repl("ConvoyTeam", ".", "_")), tempValue); MutCMenu(myMut).ConvoyTeam = Clamp(self.tempValue, 0, 1); }
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("ConvoyMinutes", ".", "_")), tempValue); class'MutCMenu'.default.ConvoyMinutes = Max(self.tempValue, 0); }
	else { self.GetIntPropertyByName(name(Repl("ConvoyMinutes", ".", "_")), tempValue); MutCMenu(myMut).ConvoyMinutes = Max(self.tempValue, 0); }
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("GunGameLives", ".", "_")), tempValue); class'MutCMenu'.default.GunGameLives = Max(self.tempValue, 0); }
	else { self.GetIntPropertyByName(name(Repl("GunGameLives", ".", "_")), tempValue); MutCMenu(myMut).GunGameLives = Max(self.tempValue, 0); }
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("PaintballDamagePercent", ".", "_")), tempValue); class'MutCMenu'.default.PaintballDamagePercent = Clamp(self.tempValue, 0, 100); }
	else { self.GetIntPropertyByName(name(Repl("PaintballDamagePercent", ".", "_")), tempValue); MutCMenu(myMut).PaintballDamagePercent = Clamp(self.tempValue, 0, 100); }


    if (self.myMut != None)
	{
		MutCMenu(self.myMut).SendClientSettings();
		self.myMut.SaveConfig();
	}
	else
		class'MutCMenu'.static.StaticSaveConfig();
}


// The WebAdmin page: one tab per group, a plain label for each setting, and every on/off setting as On / Off
// buttons (a value mapping of 0 and 1). Settings with a few fixed values get them as choices; four or more show
// as a drop-down list. The group names, labels and choice names are localized, so they are in the .int file
// (Localization\INT, section [<this class>]), in the same order as below.
defaultproperties
{
    // Tab ids are numbers: the game's WebAdmin checks a named tab against the admin's rights with a broken address on
    // the Mutators page, so with multi-admin logins (the 29th's servers) every named tab was hidden. The titles come
    // from the .int file.
    SettingsGroups.Add((GroupID="0",pMin=600,pMax=610,lMin=0,lMax=0))
    SettingsGroups.Add((GroupID="1",pMin=610,pMax=620,lMin=0,lMax=0))
    SettingsGroups.Add((GroupID="2",pMin=620,pMax=630,lMin=0,lMax=0))
    SettingsGroups.Add((GroupID="3",pMin=630,pMax=640,lMin=0,lMax=0))
    SettingsGroups.Add((GroupID="4",pMin=640,pMax=650,lMin=0,lMax=0))
    SettingsGroups.Add((GroupID="5",pMin=650,pMax=670,lMin=0,lMax=0))

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
    Properties.Add((PropertyId=607,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=607,Name="bTankPromptForAll",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))

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
    Properties.Add((PropertyId=624,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=624,Name="bDisableSpectatorTracers",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))

    // Capture the Flag
    Properties.Add((PropertyId=630,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=630,Name="bCTFSilent",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
    Properties.Add((PropertyId=631,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=631,Name="CTFMaxFlagsPerPlayer"))
    Properties.Add((PropertyId=632,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=632,Name="CTFPlaceCooldown"))

    // Builder match rules (all as the Builder always was when left alone)
    Properties.Add((PropertyId=640,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=640,Name="BuilderMode",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1),(Id=2),(Id=3))))
    Properties.Add((PropertyId=641,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=641,Name="bBuilderPiecesOnly",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
    Properties.Add((PropertyId=642,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=642,Name="bBuilderBudgets",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
    Properties.Add((PropertyId=643,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=643,Name="BuilderTeamPoints"))
    Properties.Add((PropertyId=644,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=644,Name="bBuilderZones",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
    Properties.Add((PropertyId=645,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=645,Name="bRebuildLayoutEachRound",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))

    // Game modes
    Properties.Add((PropertyId=650,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=650,Name="GameModeOnStart",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1),(Id=2),(Id=3),(Id=4),(Id=5))))
    Properties.Add((PropertyId=651,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=651,Name="CTFCapturesToWin"))
    Properties.Add((PropertyId=652,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=652,Name="BombAttackers",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
    Properties.Add((PropertyId=653,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=653,Name="BombPlantSeconds"))
    Properties.Add((PropertyId=654,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=654,Name="BombDefuseSeconds"))
    Properties.Add((PropertyId=655,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=655,Name="BombFuseSeconds"))
    Properties.Add((PropertyId=656,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=656,Name="BombRoundMinutes"))
    Properties.Add((PropertyId=657,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=657,Name="ConvoyTeam",MappingType=PVMT_IdMapped,ValueMappings=((Id=0),(Id=1))))
    Properties.Add((PropertyId=658,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=658,Name="ConvoyMinutes"))
    Properties.Add((PropertyId=659,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=659,Name="GunGameLives"))
    Properties.Add((PropertyId=660,Data=(Type=SDT_Int32,Value1=0)))
    PropertyMappings.Add((Id=660,Name="PaintballDamagePercent"))
}

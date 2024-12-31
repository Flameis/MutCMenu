class MutCMenuSettings extends MutatorSettings
	config(MutCMenu_Server);

/**
 * @brief Initializes the settings screen for this mutator
 */
function InitMutSettings()
{
	//Bool
	if (self.myMut == None){self.SetIntPropertyByName(name(Repl("bUseDefaultFactions (Must be enabled for bAITRoles to work)", ".", "_")), int(class'MutCMenu'.default.bUseDefaultFactions));}
	else{self.SetIntPropertyByName(name(Repl("bUseDefaultFactions (Must be enabled for bAITRoles to work)", ".", "_")), int(MutCMenu(myMut).bUseDefaultFactions));};

	//Enum
	if (self.myMut == None){self.SetIntPropertyByName(name(Repl("MySouthForce (USA = 0, USMC = 1, AUS = 2, ARVN = 3)", ".", "_")), int(class'MutCMenu'.default.MySouthForce));}
	else{self.SetIntPropertyByName(name(Repl("MySouthForce (USA = 0, USMC = 1, AUS = 2, ARVN = 3)", ".", "_")), int(MutCMenu(myMut).MySouthForce));};

	if (self.myMut == None){self.SetIntPropertyByName(name(Repl("MyNorthForce (PAVN = 0, NLF = 1)", ".", "_")), int(class'MutCMenu'.default.MyNorthForce));}
	else{self.SetIntPropertyByName(name(Repl("MyNorthForce (PAVN = 0, NLF = 1)", ".", "_")), int(MutCMenu(myMut).MyNorthForce));};

	//Bool
	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bLoadExtras", ".", "_")), int(class'MutCMenu'.default.bLoadExtras)); }
	else { self.SetIntPropertyByName(name(Repl("bLoadExtras", ".", "_")), int(MutCMenu(myMut).bLoadExtras)); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bLoadGOM3", ".", "_")), int(class'MutCMenu'.default.bLoadGOM3)); }
	else { self.SetIntPropertyByName(name(Repl("bLoadGOM3", ".", "_")), int(MutCMenu(myMut).bLoadGOM3)); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bLoadGOM4", ".", "_")), int(class'MutCMenu'.default.bLoadGOM4)); }
	else { self.SetIntPropertyByName(name(Repl("bLoadGOM4", ".", "_")), int(MutCMenu(myMut).bLoadGOM4)); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bLoadWW", ".", "_")), int(class'MutCMenu'.default.bLoadWW)); }
	else { self.SetIntPropertyByName(name(Repl("bLoadWW", ".", "_")), int(MutCMenu(myMut).bLoadWW)); }

	if (self.myMut == None) { self.SetIntPropertyByName(name(Repl("bNewTankPhys", ".", "_")), int(class'MutCMenu'.default.bNewTankPhys)); }
	else { self.SetIntPropertyByName(name(Repl("bNewTankPhys", ".", "_")), int(MutCMenu(myMut).bNewTankPhys)); }
}

/**
 * @brief Saves the settings for this mutator
 */
function SaveMutSettings()
{
	local ENorthernForces MyNorthForce;
	local ESouthernForces MySouthForce;

	//Bool
	if (self.myMut == None) {self.GetIntPropertyByName(name(Repl("bUseDefaultFactions (Must be enabled for bAITRoles to work)", ".", "_")), tempValue); class'MutCMenu'.default.bUseDefaultFactions = (self.tempValue != 0);}
	else {self.GetIntPropertyByName(name(Repl("bUseDefaultFactions (Must be enabled for bAITRoles to work)", ".", "_")), tempValue); MutCMenu(self.myMut).bUseDefaultFactions  = (self.tempValue != 0);}

	//Enum
	if (self.myMut == None) {self.GetIntPropertyByName(name(Repl("MyNorthForce (PAVN = 0, NLF = 1)", ".", "_")), tempValue);
		if (self.tempValue == 0)
			MyNorthForce = NFOR_NVA;
		else
			MyNorthForce = NFOR_NLF;
		class'MutCMenu'.default.MyNorthForce = MyNorthForce;}
	else {self.GetIntPropertyByName(name(Repl("MyNorthForce (PAVN = 0, NLF = 1)", ".", "_")), tempValue);
		if (self.tempValue == 0)
			MyNorthForce = NFOR_NVA;
		else
			MyNorthForce = NFOR_NLF;
		MutCMenu(myMut).MyNorthForce = MyNorthForce;}

	if (self.myMut == None) {self.GetIntPropertyByName(name(Repl("MySouthForce (USA = 0, USMC = 1, AUS = 2, ARVN = 3)", ".", "_")), tempValue);
		if (self.tempValue < 4)
			MySouthForce = ESouthernForces(tempValue);
		else
			MySouthForce = SFOR_USarmy;
		class'MutCMenu'.default.MySouthForce = MySouthForce;}
	else {self.GetIntPropertyByName(name(Repl("MySouthForce (USA = 0, USMC = 1, AUS = 2, ARVN = 3)", ".", "_")), tempValue); 
		if (self.tempValue < 4)
			MySouthForce = ESouthernForces(tempValue);
		else
			MySouthForce = SFOR_USarmy;
		MutCMenu(myMut).MySouthForce = MySouthForce;}

	//Bool
	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bLoadExtras", ".", "_")), tempValue); class'MutCMenu'.default.bLoadExtras = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bLoadExtras", ".", "_")), tempValue); MutCMenu(self.myMut).bLoadExtras = (self.tempValue != 0); }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bLoadGOM3", ".", "_")), tempValue); class'MutCMenu'.default.bLoadGOM3 = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bLoadGOM3", ".", "_")), tempValue); MutCMenu(self.myMut).bLoadGOM3 = (self.tempValue != 0); }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bLoadGOM4", ".", "_")), tempValue); class'MutCMenu'.default.bLoadGOM4 = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bLoadGOM4", ".", "_")), tempValue); MutCMenu(self.myMut).bLoadGOM4 = (self.tempValue != 0); }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bLoadWW", ".", "_")), tempValue); class'MutCMenu'.default.bLoadWW = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bLoadWW", ".", "_")), tempValue); MutCMenu(self.myMut).bLoadWW = (self.tempValue != 0); }

	if (self.myMut == None) { self.GetIntPropertyByName(name(Repl("bNewTankPhys", ".", "_")), tempValue); class'MutCMenu'.default.bNewTankPhys = (self.tempValue != 0); }
	else { self.GetIntPropertyByName(name(Repl("bNewTankPhys", ".", "_")), tempValue); MutCMenu(self.myMut).bNewTankPhys = (self.tempValue != 0); }
	

    if (self.myMut != None)
		self.myMut.SaveConfig();
	else
		class'MutCMenu'.static.StaticSaveConfig();
}


defaultproperties
{
    SettingsGroups(0)=(GroupID="Settings",pMin=600,pMax=700,lMin=0,lMax=0)

	Properties.Add((PropertyId=600,Data=(Type=SDT_Bool,Value1=0)))
	PropertyMappings.Add((Id=600,Name="bUseDefaultFactions (Must be enabled for bAITRoles to work)"))

	Properties.Add((PropertyId=601,Data=(Type=SDT_Int32,Value1=0)))
	PropertyMappings.Add((Id=601,Name="MyNorthForce (PAVN = 0, NLF = 1)"))
	
	Properties.Add((PropertyId=600,Data=(Type=SDT_Int32,Value1=0)))
	PropertyMappings.Add((Id=600,Name="MySouthForce (USA = 0, USMC = 1, AUS = 2, ARVN = 3)"))

	Properties.Add((PropertyId=602, Data=(Type=SDT_Int32, Value1=0)))
	PropertyMappings.Add((Id=602, Name="bLoadExtras"))

	Properties.Add((PropertyId=603, Data=(Type=SDT_Int32, Value1=0)))
	PropertyMappings.Add((Id=603, Name="bLoadGOM3"))

	Properties.Add((PropertyId=604, Data=(Type=SDT_Int32, Value1=0)))
	PropertyMappings.Add((Id=604, Name="bLoadGOM4"))

	Properties.Add((PropertyId=605, Data=(Type=SDT_Int32, Value1=0)))
	PropertyMappings.Add((Id=605, Name="bLoadWW"))

	Properties.Add((PropertyId=606, Data=(Type=SDT_Int32, Value1=0)))
	PropertyMappings.Add((Id=606, Name="bNewTankPhys"))
}
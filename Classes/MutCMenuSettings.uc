class MutCMenuSettings extends MutatorSettings
	config(MutCMenu_Server);
	
var ENorthernForces MyNorthForce;
var ESouthernForces MySouthForce;

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
}

/**
 * @brief Saves the settings for this mutator
 */
function SaveMutSettings()
{
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
		class'MutCMenu'.default.MySouthForce = MySouthForce;
		}
	else {self.GetIntPropertyByName(name(Repl("MySouthForce (USA = 0, USMC = 1, AUS = 2, ARVN = 3)", ".", "_")), tempValue); 
		if (self.tempValue < 4)
			MySouthForce = ESouthernForces(tempValue);
		else
			MySouthForce = SFOR_USarmy;
		MutCMenu(myMut).MySouthForce = MySouthForce;
		}

    if (self.myMut != None)
		self.myMut.SaveConfig();
	else
		class'MutCMenu'.static.StaticSaveConfig();
}


defaultproperties
{
    SettingsGroups(0)=(GroupID="Settings",pMin=600,pMax=700,lMin=0,lMax=0)

	Properties.Add((PropertyId=601,Data=(Type=SDT_Int32,Value1=0)))
	PropertyMappings.Add((Id=601,Name="MyNorthForce (PAVN = 0, NLF = 1)"))
	
	Properties.Add((PropertyId=600,Data=(Type=SDT_Int32,Value1=0)))
	PropertyMappings.Add((Id=600,Name="MySouthForce (USA = 0, USMC = 1, AUS = 2, ARVN = 3)"))
}
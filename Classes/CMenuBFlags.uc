// The Builder's CTF Flags menu: Capture the Flag flags for either team or a neutral one, placed with a preview like the
// Actors menu's (whose preview code it shares). Switches in the menu set the options the next flags placed from it get,
// all off until switched on and remembered between games: a beam above the flag, pickups and drops announced to the
// server, which team's players see the flag on their map, a timer from the match going live before they do, and whether
// they see it there while it is carried. The command line entry makes any other flag. Anyone can place a flag; resetting
// and removing them is for admins (the server checks again).
class CMenuBFlags extends CMenuBActors
	config(MutCMenu_Client);

var config bool bFlagBeam, bFlagAnnounce, bFlagMapCarried;
var config byte FlagMapTeams;   // CMAFlag's MAP_ bits: whose players see the flags on their map
var config int FlagMapTimer;    // seconds after the match goes live before they do

var array<int> TimerSteps;      // what the Map Timer switch steps through
var string PlacingCmd;          // the flag being placed, so a switch picked while placing doesn't lose it

const TEAM_NEUTRAL = 2;

function Initialize()
{
	MenuText.Length = 0;
	MenuCommand.Length = 0;

	if (PC != None)
	{
		AddEntry("CTF Flag: "$FlagEntry(`AXIS_TEAM_INDEX), "CTFFLAGNORTH");
		AddEntry("CTF Flag: "$FlagEntry(`ALLIES_TEAM_INDEX), "CTFFLAGSOUTH");
		AddEntry("CTF Flag: Neutral", "CTFFLAGNEUTRAL");
		AddEntry(BeamLabel(), "FLAGOPT_BEAM");
		AddEntry(AnnounceLabel(), "FLAGOPT_ANNOUNCE");
		AddEntry(MapLabel(), "FLAGOPT_MAP");
		AddEntry(TimerLabel(), "FLAGOPT_TIMER");
		AddEntry(CarriedLabel(), "FLAGOPT_CARRIED");
		// No preview: types the command in the console with the options explained, for flags the entries above can't make
		AddEntry("CTF Flag: Command Line", "CTFFLAGCMD");
	}
	if (bIsAuthorized && PC != None)
	{
		AddEntry("Reset Flags", "RESETFLAGS");
		AddEntry("Remove Flags", "REMOVEFLAGS");
	}

	super.Initialize();
}

function AddEntry(string Text, string Command)
{
	MenuText.AddItem(Text);
	MenuCommand.AddItem(Command);
}

function string FlagEntry(int Team)
{
	return class'CMAFlag'.default.Factions[class'CMAFlag'.static.FactionForTeam(PC.WorldInfo, Team)].Label
		$" ("$class'CMAFlag'.static.TeamWord(PC.WorldInfo, Team)$")";
}

// ====================================================
// The switches
// ====================================================

static function string SwitchText(bool bOn)
{
	return bOn ? "On" : "Off";
}

function string BeamLabel()
{
	return "Beam: "$SwitchText(bFlagBeam);
}

function string AnnounceLabel()
{
	return "Announce Pickups: "$SwitchText(bFlagAnnounce);
}

function string MapLabel()
{
	return "On Map For: "$MapTeamsName(FlagMapTeams);
}

function string MapTeamsName(byte Teams)
{
	switch (Teams & class'CMAFlag'.const.MAP_BOTH)
	{
		case class'CMAFlag'.const.MAP_NORTH: return class'CMAFlag'.static.TeamWord(PC.WorldInfo, `AXIS_TEAM_INDEX);
		case class'CMAFlag'.const.MAP_SOUTH: return class'CMAFlag'.static.TeamWord(PC.WorldInfo, `ALLIES_TEAM_INDEX);
		case class'CMAFlag'.const.MAP_BOTH:  return "Both Teams";
	}
	return "Nobody";
}

function string TimerLabel()
{
	return "Map Timer: "$TimerText(FlagMapTimer);
}

static function string TimerText(int Seconds)
{
	if (Seconds <= 0)
		return "None";
	if (Seconds % 60 == 0)
		return (Seconds / 60)$" min after LIVE";
	return Seconds$" s after LIVE";
}

function string CarriedLabel()
{
	return "On Map While Carried: "$SwitchText(bFlagMapCarried);
}

// The next step of the Map Timer switch after the current value (back to None after the last)
function int NextTimer(int Current)
{
	local int i;

	for (i = 0; i < TimerSteps.Length; i++)
	{
		if (TimerSteps[i] > Current)
			return TimerSteps[i];
	}
	return 0;
}

// A switch was changed: saved, shown in the menu, which stays open. Picked while a flag is being placed, the flag is
// still placed afterwards (the menu would otherwise end placing).
function SwitchChanged(string What)
{
	SaveConfig();
	bStayOpen = true;
	if (IsInState('ReadyToPlace') && PlacingCmd != "")
	{
		LastCmd = PlacingCmd;
		bPlacingStarted = true;
	}
	RefreshLabels();
	MessageSelf(What$" (for the next flags you place from this menu)");
}

function RefreshLabels()
{
	SetLabel("FLAGOPT_BEAM", BeamLabel());
	SetLabel("FLAGOPT_ANNOUNCE", AnnounceLabel());
	SetLabel("FLAGOPT_MAP", MapLabel());
	SetLabel("FLAGOPT_TIMER", TimerLabel());
	SetLabel("FLAGOPT_CARRIED", CarriedLabel());
	FindCMenuLength();
}

function SetLabel(string Command, string Text)
{
	local int i;

	i = MenuCommand.Find(Command);
	if (i != INDEX_NONE)
		MenuText[i] = Text;
}

function bool CheckExceptions(string Command)
{
	switch (Command)
	{
		case "FLAGOPT_BEAM":
			bFlagBeam = !bFlagBeam;
			SwitchChanged(BeamLabel());
			return true;

		case "FLAGOPT_ANNOUNCE":
			bFlagAnnounce = !bFlagAnnounce;
			SwitchChanged(AnnounceLabel());
			return true;

		case "FLAGOPT_MAP":
			// Nobody, north, south, both, then nobody again
			FlagMapTeams = (FlagMapTeams + 1) % (class'CMAFlag'.const.MAP_BOTH + 1);
			SwitchChanged(MapLabel());
			return true;

		case "FLAGOPT_TIMER":
			FlagMapTimer = NextTimer(FlagMapTimer);
			SwitchChanged(TimerLabel());
			return true;

		case "FLAGOPT_CARRIED":
			bFlagMapCarried = !bFlagMapCarried;
			SwitchChanged(CarriedLabel());
			return true;

		case "CTFFLAGCMD":
			PlacingCmd = "";
			PromptForText("CTF Flag|Places a flag where you are looking. Add options after the command, or just press Enter for your own team's flag. Leave a box blank for its default (off).|"
				$"--team / -t : whose flag it is: north, south, axis, allies, finnish, soviet, 0, 1 or neutral (spectators must give --team or --flag)|"
				$"--flag / -f : exactly one flag by name, even if no team on the map has it. Names: "$class'CMAFlag'.static.FactionNames()$"|"
				$"--beam / -b : a beam above the flag so it can be found|"
				$"--announce / -a : tell the server when it is picked up or dropped|"
				$"--map / -m : whose players see it on their map: north, south, both or none|"
				$"--timer / -d : seconds after the match goes LIVE before they see it there|"
				$"--carried / -c : they see it on the map while it is carried too (otherwise only on the ground)|"
				$"Example: --team south --beam|Example: --flag dak --announce|Example: --team neutral --map both --timer 120|"
				$"WW2 and Winter War flags on a map from another game need bLoadWW2 / bLoadWW.", "mutate spawnflag ", ,
				"team,flag,beam!,announce!,map,timer,carried!");
			return true;

		case "CTFFLAGNORTH":
		case "CTFFLAGSOUTH":
		case "CTFFLAGNEUTRAL":
			// The flag drops onto the ground, so it stands on the bottom of its collision, and is placed facing north
			StartParts();
			bFixedRotation = true;
			AddComponentPart(class'CMAFlag'.default.PoleMesh, CylinderComponent(class'CMAFlag'.default.CollisionComponent).CollisionHeight);
			AddComponentPart(class'CMAFlag'.default.FlagMesh, CylinderComponent(class'CMAFlag'.default.CollisionComponent).CollisionHeight);
			if (Command == "CTFFLAGNORTH")
				SpawnTeamIndex = `AXIS_TEAM_INDEX;
			else if (Command == "CTFFLAGSOUTH")
				SpawnTeamIndex = `ALLIES_TEAM_INDEX;
			else
				SpawnTeamIndex = TEAM_NEUTRAL;
			PlacingCmd = Command;
			GoToState('ReadyToPlace',, true);
			return true;
	}
	PlacingCmd = "";
	return false;
}

function DoPlace()
{
	switch (LastCmd)
	{
		case "CTFFLAGNORTH":
		case "CTFFLAGSOUTH":
		case "CTFFLAGNEUTRAL":
			MyDA.ServerPlaceFlag(PlaceLoc, SpawnTeamIndex, bFlagBeam, bFlagAnnounce, FlagMapTeams, FlagMapTimer, bFlagMapCarried);
			return;
	}
}

defaultproperties
{
	MenuName="CTF FLAGS"

	// Made in Initialize, with the switches showing their settings
	MenuText.Empty
	MenuCommand.Empty

	TimerSteps(0)=30
	TimerSteps(1)=60
	TimerSteps(2)=120
	TimerSteps(3)=300
	TimerSteps(4)=600
}

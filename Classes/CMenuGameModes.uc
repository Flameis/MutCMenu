// Admins: start and stop the game modes (CMGameMode), and place the bomb sites, the bomb start and the convoy's
// destination where you stand. Each line runs the matching mutate command (gamemode, modepoint, convoyvehicle).
class CMenuGameModes extends CMenu;

defaultproperties
{
    MenuName="GAME MODES"

    MenuText.add("Capture the Flag Match")
    MenuText.add("Bomb Plant and Defuse")
    MenuText.add("Convoy")
    MenuText.add("Gun Game")
    MenuText.add("Paintball")
    MenuText.add("Stop the Game Mode")
    MenuText.add("Bomb Site A Here")
    MenuText.add("Bomb Site B Here")
    MenuText.add("Bomb Start Here")
    MenuText.add("Convoy Destination Here")
    MenuText.add("Convoy Vehicle: Nearest Me")
    MenuText.add("Clear Sites and Destination")

    MenuCommand.add("GAMEMODE CTF")
    MenuCommand.add("GAMEMODE BOMB")
    MenuCommand.add("GAMEMODE CONVOY")
    MenuCommand.add("GAMEMODE GUNGAME")
    MenuCommand.add("GAMEMODE PAINTBALL")
    MenuCommand.add("GAMEMODE OFF")
    MenuCommand.add("MODEPOINT SITEA")
    MenuCommand.add("MODEPOINT SITEB")
    MenuCommand.add("MODEPOINT BOMBSTART")
    MenuCommand.add("MODEPOINT CONVOY")
    MenuCommand.add("CONVOYVEHICLE")
    MenuCommand.add("CLEARMODEPOINTS")
}

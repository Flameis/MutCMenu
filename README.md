# MutCMenu

CMenu is an on-screen menu for drill leaders and admins. It lets you run a drill without memorising console commands: you open the menu, press a number, and things happen. It can also place vehicles, walls, spawn points and even whole objectives, give weapons, move players around, and call in fire support.

## Contents

1. Getting started
2. Who can do what
3. The menus
4. Fire support
5. Building things (the Builder menu)
6. Other features
7. Typing commands instead of using the menu
8. Settings
9. Works with other mods

---

## 1. Getting started

1. Open the game console (the `~` key).
2. Bind a key to the menu: `setbind F1 mutate cmenu` (use any key you like instead of F1).
3. Press that key in game to open the menu.
4. Press the **number keys** (top row or number pad) to pick an entry. **1 to 8** pick an entry, **9** goes to the next page and **0** goes back.
5. Prefer the mouse? Choose **Toggle Mouse Click Mode** in the main menu and each line becomes a clickable button.

Some entries need a value from you (a player name, a grid square, a time). When you pick one, the menu closes and the large console opens with the command already typed and short instructions above it. Add your value and press Enter. A mistyped fire support command tells you what was wrong and puts the command back so you can fix it.

Long help text (for example `mutate firesupporthelp`) opens in the large console so it does not flood the chat. This works on a server too: long help is sent to you in pieces and shown in one go. Short messages arrive as private chat messages that only you see.

## 2. Who can do what

- **Server admins** (logged in to the server's WebAdmin or admin list) can use everything.
- **Scrim admins** can use everything too. A scrim admin is a name on the Realism Match admin list who has logged in with `mutate scrimadminlogin`, or someone an admin has given **temporary** admin powers.
- **Spectators** can use the Builder too, even without a character: they aim with the camera and place things where it points.
- **Everyone else** sees a smaller menu: General Commands, the Builder, the Weapon menu (for themselves only), CMenu Settings and, if the server allows it, Fire Support.

Anything marked "admin only" below is hidden or refused for everyone else.

## 3. The menus

### Main menu
The starting point. It lists General Commands, Builder, Weapons, CMenu Settings, Toggle Mouse Click Mode and, for admins, the Realism Match, Paradrop and Manage Players menus. Fire Support appears for admins, and for players when the server allows it.

### General Commands (everyone)
| Entry | What it does |
| :--- | :--- |
| Respawn | Puts you back in the game after you die |
| Kill Self | Kills your character |
| Drop At Objective / Drop At Grid | Moves you to an objective or a map grid square |
| Change Name | Changes the name shown for you (the server remembers the original) |
| Safety On / Safety Off | Turns your own weapon safety on or off |
| Check AITs | Shows how many of the special AIT roles each team is using |
| Switch Team | Moves you to the other team |
| Set Team Ready / Not Ready | Tells the match system your team is ready |
| Admin Toggle Fly | (Admins) fly around freely |

### Manage Players (admin only)
Pick a player, then choose what to do to them:

| Entry | What it does |
| :--- | :--- |
| Drop At Objective / Drop At Grid | Moves that player to an objective or grid square |
| Teleport To Me | Brings that player to where you are |
| Change Name / Find Original Name | Renames them, or looks up the name they had before |
| Switch Team | Moves them to the other team |
| Change Unit Patch / Change Rank Patch | Changes the unit and rank patch on their helmet (for example `DP2S4`, `cpl`) |
| Safety On / Safety Off | Forces their weapon safety |
| Respawn / Kill | Respawns them or kills them |
| Give / Revoke Temporary Scrimmage Admin Powers | Lets someone use the admin menus until you take it back |

### Weapon menu
| Entry | What it does |
| :--- | :--- |
| Give Weapon (Self) | Gives you a weapon. Type a short name such as `BHP` or `L1A1`, or a full weapon path |
| Give Weapon North / South / All | (Admin) gives a weapon to the whole North team, South team or everyone |
| Clear Weapons (Self) | Removes your weapons |
| Clear Weapons North / South / All | (Admin) removes weapons from a team or everyone |
| Copy Held Weapon To Clipboard | Remembers the weapon you are holding so you can give it or turn it into a pickup |

### CMenu Settings (everyone)
Changes how the menu looks for you: text colour, background colour, border colour, whether the background shows, and whether the menu **stays open** after you pick something.

### Realism Match menu (admin only)
Controls the match system from the menu. It splits into:

| Submenu | What is in it |
| :--- | :--- |
| Match Control | Enable or disable match mode, go live, countdown to live, cancel the countdown, reset live, restart the round, end the round, respawn all dead players |
| Round Settings | Round timer, **respawn deployment time**, friendly fire, automatic respawns, reinforcement tickets for each team. (The round length is not here: it is the `RoundDuration` mutator setting in WebAdmin, and `mutate setroundduration` still works for admins.) |
| Objectives | Open or close an objective, open one **at random**, set who owns an objective (or all), set minimum capture time |
| Teams and Weapons | Swap the teams, swap just one team, weapons hold (safeties on) and weapons free (safeties off) |
| Scrimmage Admin Help | Shows the list of admin commands |

### Paradrop menu (admin only)
Moves players instantly to an objective or a grid square: everyone, only the North team, or only the South team. The menu uses the Paradrops mutator.

## 4. Fire support

Fire support lets an admin (or any player, if the server allows it) call in artillery, mortars, rockets, napalm and more on any spot, without the commander's normal limits.

**Types you can call**

| Type | What you get |
| :--- | :--- |
| Mortar Barrage | Mortar shells |
| Artillery Barrage | Heavy artillery shells |
| Airburst Artillery | Shells that burst in the air |
| Rocket Barrage | Rockets |
| White Phosphorus Barrage | WP mortar shells |
| Mixed Barrage | Like the NLF's barrage: each shell is picked at random from artillery, rockets, mortars and white phosphorus |
| Napalm Strike | A napalm bombing run |
| Canberra Bombing Run | A bomber run (one or two planes) |
| AC-47 Gunship | A gunship circling the target |
| Cancel Fire Support (My Team) | Stops your team's fire support (see below) |
| Cancel All Fire Support | (Admin) stops every team's fire support |

**Choosing the target:** a map grid square such as `E 5 kp 5` (or `E5`), the spot you are **looking at** (`--look`), or a **mark**. With `--mark` a squad leader's call uses their own squad's mark and the commander's call uses the mark they selected on their map. `--mark SL3` (or `--SL 3`) picks squad 3's mark and `--mark CMD` picks the commander's. Squad leaders can only pick their own squad; admins and the commander can pick any.

**Options** (everyone who can call fire support can use all of these, except `--persist`):

| Option | Short | What it does |
| :--- | :--- | :--- |
| `--salvos` | `-s` | How many salvos a barrage fires (1-20). For napalm, Canberra and gunship runs, how many times the run is repeated (1-10) |
| `--shells` | `-n` | Shells per salvo (1-100). Barrages only |
| `--spread` | `-r` | How far the shells scatter, in meters (0-200). Barrages only |
| `--interval` | `-i` | The time between strikes **after the first**: seconds between salvos for a barrage (1-120), or seconds between repeated runs for aircraft (1-300, 30 if left out) |
| `--delay` | `-d` | Waits 10-300 seconds before the first strike |
| `--direction` | `-b` | Napalm and Canberra only: the way the aircraft flies, as a compass point (`N`, `SW`, `ESE`...) or a bearing from 0 to 360 |
| `--suppress` | `-q` | Skips the server-wide announcement for this call. You still get a private confirmation |
| `--look` | `-k` | Targets the spot you are looking at, instead of a grid or mark. This is how a spectator marks a target |
| `--team` | | Which side the call is for: `--team north` or `--team south`. Spectators have no side, so they must give one. Admins can use it to call for the other team. Everyone else's call is for their own team |
| `--persist` | `-p` | **Admins only.** Saves the settings you used as the new default for that barrage type |

Examples:
- `mutate firesupport --type mortar --grid E 5 kp 5`
- `mutate firesupport --type mixed --grid D 4 --salvos 4 --interval 8`
- `mutate firesupport --type napalm --grid E 5 --direction SW --salvos 3 --interval 45`

**Cancelling fire support**
- `mutate cancelfiresupport` stops your team's fire support: barrages (and the shells already in the air), aircraft in flight, and strikes still waiting for their delay or their turn. Anyone who can call fire support can do this for their own team. The Fire Support menu has **Cancel Fire Support (My Team)**.
- `mutate cancelfiresupport --all` (short `-a`) stops **every team's** fire support. Admins only. The menu has **Cancel All Fire Support** for admins.
- It only stops fire support started with this command. A commander's own strike from the game is left alone, and the commander's ability timers are not changed.
- The cancel is announced to everyone (unless the server is set to silent), and tells you if there was nothing to cancel.

**Spectators and map**
- **Spectators can call fire support:** when the server allows players to (`bFSPlayersCanCall`) or for admins. A spectator picks the side with `--team` and the target with `--grid` or `--look`, for example `mutate firesupport --type mortar --look --team north`. Their strikes have no owner, so nobody gets kill credit.
- **It shows on the map like the commander's:** the target, the salvos left, the heading and the aircraft appear on the overhead map of the team the strike is for, or of **both teams** when a spectator called it. It disappears when the strike is over or cancelled. A commander's own strike is never overwritten.
- **Always available:** fire support works at any time, including between rounds and in the briefing. (The game's own artillery is thrown away when no round is active; CMenu uses its own version that is not.)

**Rules**
- Players can only call fire support if the server turns it on (`bFSPlayersCanCall`). When they can, they can use every option above except `--persist`.
- Player calls have a cooldown per team (`FSPlayerCooldown`). Admins ignore the cooldown.
- Players cannot target "no artillery" zones. Admin strikes can, including the area outside the combat area. Admin aircraft are not removed for flying outside the map.
- Friendly fire from strikes is off unless the server turns it on (`bFSFriendlyFire`).
- Calls are announced to the whole server unless the server is set to silent (`bFSSilent`) or the caller uses `--suppress`.
- Warnings (wrong grid, cooldown, no permission) come back to the caller as private messages.

## 5. Building things (the Builder menu)

Open **Builder Menu** from the main menu. You aim at the spot you want, and confirm to place the item.

| Builder section | What you can do |
| :--- | :--- |
| Vehicles | Place vehicles: Cobra, Loach, Huey, Bushranger, plus lists for WW2, Winter War and GOM (Gameplay Overhaul Mutator) vehicles and the GreenMen (GM) helicopters when those mods are loaded, plus the 29th's own helicopters. **Custom** lets you type any vehicle path. **Delete Vehicle** removes the one you aim at |
| Structures | Copy buildings or whole areas you are aiming at and paste them somewhere else. Select several meshes, copy the selection, remove the last one, or clear the selection |
| Static Meshes | Copy, paste and delete single objects. Presets: straight sandbags and an F4 Phantom. Admins also get **Toggle Collision** and **Delete Any Object** |
| Pickups | Turn a weapon into a pickup on the ground: **Custom** (type the weapon path) or **Copy Held Weapon** (the one in your hands) |
| Actors | Place team spawn points (North and South), an M2 turret, a DShK turret and an ammo resupply point. **Mark Corner** and **Spawn Obj** let you draw and place a brand new capture objective of your own. Admins also get a **CTF Flag** entry for each team's flag (for example "CTF Flag: PAVN (North)"), **CTF Flag: Command Line**, **Reset Flags** and **Remove Flags** (see below). **Clear All** removes everything you placed, flags included |

Admins also get "Clear All Vehicles / Meshes / Pickups / Actors" entries to wipe what has been placed. Custom objectives you create appear on the map, and with MutExtras their borders are drawn on the overhead map. Placed spawn points are used for the team that owns them.

### Capture the Flag flags

Admins can place real flags on a pole for capture the flag drills, from the Builder's Actors menu or with `mutate spawnflag`.

- **Picking it up:** any player of either team picks a flag up by walking onto it. They carry it on their back, and everyone else sees it there. One flag per player.
- **Dropping it:** the carrier drops it on purpose with `mutate dropflag` (bind it to a key, for example `setbind G mutate dropflag`). It is thrown a short way forward. Whoever dropped it has to wait 3 seconds before they can pick it up again.
- **It drops by itself** where the carrier dies (teamkills too), gets into a vehicle or leaves the server.
- **It never disappears.** A flag that falls out of the map goes back to where it was placed. Every flag also goes back there when the round restarts, or when an admin uses **Reset Flags** (`mutate resetflags`).
- **Whose flag it is:** every flag belongs to one faction, chosen when it is placed, and keeps it whoever carries it. Admins on either team can place either team's flag.
  - `mutate spawnflag` places your own team's flag.
  - `--team` places a team's flag: `north`/`south`, `axis`/`allies`, `finnish`/`soviet` or `0`/`1`. A spectator has no team, so they must use `--team` or `--flag`.
  - `--flag` places exactly the flag you name, even if no team on the map has it (for example `mutate spawnflag --flag dak`). The names are in the table below.
- **A team's flag** comes from the map. On Vietnam maps it is the map's forces: US Army, USMC, Australian Army, ARVN, PAVN or NLF. On WW2 maps it is the faction most of the team's roles belong to, so a DAK map gives the DAK flag even though it uses Wehrmacht riflemen. On Winter War maps it is the Finnish Army and the Red Army.
- **Team names follow the game:** North and South on Vietnam maps, Axis and Allies on WW2 maps, Finnish and Soviet on Winter War maps. The Builder's entries show the faction and the team, for example "CTF Flag: DAK (Axis)".
- **Command line entry:** the Builder's **CTF Flag: Command Line** entry skips the preview. It types `mutate spawnflag ` in the console and lists the options (`--team`, `--flag` with every flag name, `--nobeam`) with examples, so you can add them and press Enter. The flag lands where you are looking when you press Enter. Use it for any flag the two team entries can't make, or for a flag without a beam.
- **WW2 and Winter War flags on other maps:** placing a WW2 flag needs `bLoadWW2`, and a Winter War flag needs `bLoadWW`, unless the map is from that mod (then its content is already loaded). Vietnam flags never need a setting.
- **A beam** stands above each flag so it can be found from a distance, whether it is carried or lying on the ground. Place a flag with `--nobeam` to leave it off.
- **Chat:** placing, pickups, drops, resets and removals are announced with the faction's name, for example "Smith picked up the DAK flag". Turn `bCTFSilent` on (settings page) to stop these announcements.

| `--flag` name (other names that work) | Chat name | Flag |
| :--- | :--- | :--- |
| `usarmy` (`us`, `usa`) | US Army | US (50 stars) |
| `usmc` (`marines`) | USMC | US (50 stars) |
| `aus` (`australia`, `australian`) | Australian Army | Australian |
| `arvn` (`southvietnam`, `svn`) | ARVN | South Vietnamese |
| `pavn` (`nva`, `northvietnam`) | PAVN | North Vietnamese |
| `nlf` (`vc`, `vietcong`) | NLF | Viet Cong |
| `france` (`french`) | French Army | French |
| `redarmy` (`soviet`, `sov`, `ussr`) | Red Army | Soviet |
| `usarmy48` (`us48`, `ww2us`) | US Army | US (48 stars), WW2 |
| `usmc48` (`ww2usmc`) | USMC | US (48 stars), WW2 |
| `cw` (`commonwealth`, `british`, `britain`, `uk`) | Commonwealth | British, WW2 |
| `nra` (`chinese`, `china`) | NRA | US (48 stars), WW2: the game has no Chinese flag |
| `wehrmacht` (`wh`, `heer`, `german`, `germany`) | Wehrmacht | Iron Cross war flag, WW2 |
| `dak` (`afrikakorps`) | DAK | Iron Cross war flag, WW2 |
| `fallschirmjaeger` (`fallschirmjager`, `fj`, `fmj`) | Fallschirmjaeger | Swastika national flag, WW2 |
| `ss` | SS | Swastika national flag, WW2 |
| `italy` (`italian`, `ita`) | Italian Army | Italian, WW2 |
| `ija` (`japan`, `japanese`) | IJA | Japanese, WW2 |
| `snlf` | SNLF | Japanese, WW2 |
| `finland` (`finnish`, `fin`) | Finnish Army | Finnish, Winter War |
| `wwredarmy` (`wwsoviet`, `wwussr`) | Red Army | Soviet, Winter War |

*Still to be checked in a real game:* how the flag looks on a player's back and on the ground (its size and position), and whether the cloth waves. These cannot be checked by the automatic tests.

## 6. Other features

- **Tank entry prompt:** a player who is not tank crew can still climb into a friendly tank. Stand close to it and face it, and an enter prompt appears.
- **Mouse click mode:** every menu line becomes a clickable button.
- **Private messages and help in the console:** short replies go to you only; long help opens in the large console.
- **Loading mod content:** if the server turns it on, CMenu loads extra content packages (MutExtras, GOM 3 and 4, Winter War, WW2) so their weapons and vehicles can be used in the Builder and weapon menu. It switches on Winter War content by itself on Winter War maps and WW2 content on WW2 maps (it goes by the map name).
- **Spawn points from the Builder:** custom spawn points are respected when players spawn.
- **Its own game modes:** CMenu adds its own Territories and Supremacy game mode entries (needed for custom objectives and spawn points to work properly). A server has to pick them as its game mode.
- **Experimental tank physics:** an optional setting (`bNewTankPhys`).
- **Vehicles keep their size:** the mouse wheel still scales walls and objects in the Builder, but not vehicles, which are always placed at their own size.
- **Spectators can build:** the Builder works for spectators, who have no character. The preview and the placing follow the spectator camera. (Copying a held weapon needs a weapon, so it is refused for a spectator.)
- **No duplicate menu entries:** a menu used to keep the admin entries it had added and add them again every time it opened, so "Clear All Vehicles" could appear several times (and menu entries could go missing) after opening the menu repeatedly or logging in as scrim admin more than once. Every menu now starts from its own list each time it opens. Setting the menus up a second time no longer stacks a second copy of every menu either.
- **Builder preview stops when you pick something else:** choosing an entry that is not an item to place (Clear All, a Delete entry, Reset Flags, ...) ends placing and hides the preview, even with the menu kept open. Before, the preview stayed, a click still placed the last item and the placing keys stayed captured. Turning the page keeps the preview.
- **Fixes:** the Builder no longer breaks after you respawn, and the tank entry prompt is fixed.

## 7. Typing commands instead of using the menu

Commands can be typed in the console as `mutate <command> --option value` (short form `-o value`, like Linux commands). A value runs until the next option, so names and grid squares can contain spaces. `--option=value` also works. The older spellings still work too (for example `mutate giveweaponnorth L1A1`).

| Command | What it does | Options |
| :--- | :--- | :--- |
| `cmenu` | Opens the menu (or a submenu) | `--menu/-m`, `--player/-p` |
| `giveweapon` | Gives a weapon | `--weapon/-w`, `--team/-t` (north, south, all; leave out for yourself) |
| `clearweapons` | Removes weapons | `--team/-t` |
| `setcmenucolor` | Menu colours | `--text/-t R G B A`, `--background/-b R G B A`, `--border/-o R G B A` |
| `firesupport` | Calls fire support (see section 4) | `--type/-t`, `--grid/-g`, `--mark/-m`, `--SL/-l`, and the options in section 4 |
| `firesupporthelp` | Shows the fire support help | none |
| `cancelfiresupport` | Stops your team's fire support, or every team's with `--all` (admins) | `--all/-a`, `--team` (spectators and admins) |
| `killplayer`, `teleporttome`, `forceswitchteam`, `forcerespawn`, `forcesafetyon`, `forcesafetyoff`, `tempadminlogin`, `tempadminlogout` | Admin actions on a player | `--player/-p` |
| `fdao` | Move a player to an objective | `--player/-p`, `--obj/-o` |
| `fdag` | Move a player to a grid square | `--player/-p`, `--grid/-g` |
| `forceunitpatch` | Change a player's unit patch | `--player/-p`, `--unit/-u` |
| `forcerankpatch` | Change a player's rank patch | `--player/-p`, `--rank/-r` |
| `scrimadminlogin` / `scrimadminlogout` | Log in or out as a scrim admin | `--user/-u`, `--password/-p` |
| `clearobjs`, `clearcorners`, `delnorthspawns`, `delsouthspawns` | Remove custom objectives, marked corners or custom spawn points | none |
| `spawnflag` | (Admin) Places a Capture the Flag flag where you are looking: your team's flag, a team's flag with `--team`, or exactly one flag with `--flag` (see the flag table in section 5). Spectators must use `--team` or `--flag` | `--team/-t` (north, south, axis, allies, finnish, soviet, 0, 1), `--flag/-f <name>`, `--nobeam/-n` |
| `dropflag` | Drops the flag you are carrying | none |
| `resetflags` | (Admin) Sends every flag back to where it was placed | none |
| `removeflags` | (Admin) Removes every flag | none |

Commands shared with the Realism Match and Paradrops mutators (`scrimadminlogin`, `changename`, `whois`, the match commands and the paradrop commands) work through CMenu too.

## 8. Settings

Set in WebAdmin under **Mutators > MutCMenu Settings**, or in `MutCMenu_Server.ini`.

| Setting | What it does |
| :--- | :--- |
| `bLoadExtras`, `bLoadGOM3`, `bLoadGOM4`, `bLoadWW`, `bLoadWW2` | Load the content of MutExtras, GOM 3/4 (Gameplay Overhaul Mutator), Winter War or WW2. `bLoadWW2` and `bLoadWW` also allow placing WW2 and Winter War Capture the Flag flags on maps that aren't from those mods |
| `bNewTankPhys` | Experimental tank physics |
| `bDebugStandalone` | For testing: in a standalone (single player) game every `bLoad` option above counts as on, so all the mods' content is loaded. It does nothing on a server and does not change the saved `bLoad` settings |
| `bFSPlayersCanCall` | Let players (not only admins) call fire support |
| `bFSFriendlyFire` | Let strikes hurt the caller's own team |
| `bFSSilent` | Never announce fire support calls to everyone |
| `bCTFSilent` | Never announce Capture the Flag flags being placed, picked up, dropped, reset or removed (they are announced when this is off) |
| `FSPlayerCooldown` | Seconds between player-called strikes for a team (0 = no cooldown). Admins ignore it |
| `FSBomberCount` | Planes in a Canberra run (1-2) |
| `FSGunshipDuration` | How long the gunship circles, in seconds (0 = the map's own time) |
| `FSProfiles` (ini only) | The default size of each barrage type: salvos, shells per salvo, spread, time between salvos and delay before the first. The defaults are written the first time the server runs. A type added later (like `MIXED`) is added automatically without touching your values |

## 9. Works with other mods

- **WW2 (Black Orchestra):** vehicles and weapons can be placed and given, tank crews are added, tank entry works.
- **Winter War:** Finnish and Soviet forces, tank crews added, tank entry works.
- **GOM (Gameplay Overhaul Mutator):** custom factions work; tank crews are added; its vehicles can be placed.
- **GreenMen (GM):** its Blue Huey, Green Huey and Green Bushranger helicopters can be placed from the Builder.
- Vehicles from all of these mods can be placed from the Builder.

---

*Part of the 29th Infantry Division Mutator Suite*

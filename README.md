# MutCMenu

CMenu is an on-screen menu for drill leaders and admins. It lets you run a drill without memorising console commands: you open the menu, press a number, and things happen. It can also place vehicles, walls, spawn points and even whole objectives, give weapons, move players around, and call in fire support. It also adds to the overhead map: a better view for spectators, players past 32 on a team, and drawing on the map for everyone.

## Contents

1. Getting started
2. Who can do what
3. The menus
4. Fire support
5. Building things (the Builder menu)
6. The overhead map
7. Other features
8. Typing commands instead of using the menu
9. Settings
10. Works with other mods

---

## 1. Getting started

1. Open the game console (the `~` key).
2. Bind a key to the menu: `setbind F1 mutate cmenu` (use any key you like instead of F1).
3. Press that key in game to open the menu.
4. Press the **number keys** (top row or number pad) to pick an entry. **1 to 8** pick an entry, **9** goes to the next page and **0** goes back.
5. Prefer the mouse? Choose **Toggle Mouse Click Mode** in **CMenu Settings**. A message tells you how it works. While a menu is open, a pointer appears and the mouse moves it instead of turning your view; the line under it lights up, and a left click picks it. Commands that need options (a grid, a team, a number) open a small form with a box for each option; leave a box blank to use the default. Hold **Alt** to look around with the mouse again (and, when you are placing something with the Builder, click to place it).

Some entries need a value from you (a player name, a grid square, a time). When you pick one, the menu closes and the console opens with the command already typed and short instructions above it. The instructions name the option to type (for example `--grid E 5 kp 5`), and where the option is already typed for you, you only add the value. The older short form (for example just `E 5 kp 5`) still works and is mentioned too. Press Enter when done. A mistyped fire support command tells you what was wrong and puts the command back so you can fix it.

Long help text (for example `mutate firesupporthelp`) opens in the large console so it does not flood the chat. This works on a server too: long help is sent to you in pieces and shown in one go. Short messages arrive as private chat messages that only you see.

## 2. Who can do what

- **Server admins** (logged in to the server's WebAdmin or admin list) can use everything.
- **Scrim admins** can use everything too. A scrim admin is a name on the Realism Match admin list who has logged in with `mutate scrimadminlogin`, or someone an admin has given **temporary** admin powers.
- **Spectators** can use the Builder too, even without a character: they aim with the camera and place things where it points.
- **Everyone else** sees a smaller menu: General Commands, the Builder, the Weapon menu (for themselves only), CMenu Settings and, if the server allows it, Fire Support.

Anything marked "admin only" below is hidden or refused for everyone else.

## 3. The menus

### Main menu
The starting point. It lists General Commands, Builder, Weapons, CMenu Settings and, for admins, the Realism Match, Paradrop and Manage Players menus. Fire Support appears for admins, and for players when the server allows it.

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
| Admin Stop Players Drawing On The Map / Admin Let Players Draw On The Map | (Admins) turns map drawing off or back on for players (see section 6) |
| Admin Clear Every Map Drawing | (Admins) clears every drawing on the map for everyone. It asks first: pick it again within 5 seconds to clear |

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
Changes how the menu looks for you: text colour, background colour, border colour, whether the background shows, and whether the menu **stays open** after you pick something. **Toggle Mouse Click Mode** is here too (see section 7); turning it on sends you a message saying how to use it: point and click lines, fill in forms, and hold Alt to look around or use the map without picking menu lines.

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
| `--look` | `-k` | Targets the spot you are looking at, instead of a grid or mark: the first bit of ground or building your view line hits (players and vehicles in the way don't count). This is how a spectator marks a target. Your own game works out the spot and sends it, because the server only knows where a spectator's camera is roughly: before, a spectator watching someone got the strike on that player |
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
- Players cannot target "no artillery" zones (there are none while Realism Match mode is on). Admin strikes can, including the area outside the combat area. Admin aircraft are not removed for flying outside the map.
- Strikes follow the server's friendly fire, like any weapon: they hurt the caller's team when friendly fire is on (for example after Realism Match goes LIVE) and not when it is off (for example in the briefing). The caller is always hurt by their own strike. A server can make strikes never hurt the caller's team with `bFSNoFriendlyFire`.
- Calls are announced to the whole server unless the server is set to silent (`bFSSilent`) or the caller uses `--suppress`.
- Warnings (wrong grid, cooldown, no permission) come back to the caller as private messages.

## 5. Building things (the Builder menu)

Open **Builder Menu** from the main menu. You aim at the spot you want, and confirm to place the item.

| Builder section | What you can do |
| :--- | :--- |
| Vehicles | Place vehicles: Cobra, Loach, Huey, Bushranger, plus lists for WW2, Winter War and GOM (Gameplay Overhaul Mutator) vehicles and the GreenMen (GM) helicopters when those mods are loaded, plus the 29th's own helicopters. The WW2 list is every vehicle WW2 has that can be placed: Crusader Mk III, Ha-Go, LVT, M13, Panzer III, Panzer IV F, SdKfz 251 halftrack, Semovente, Sherman II and III, Stuart, StuG III G, T-34, T-70, and the Universal Carrier with and without its Bren. (Its Churchill can't be placed, and the Kubelwagen, SdKfz 222, Valentine and Willys entries are gone: WW2 doesn't have them.) **Custom** types `mutate cmenu --menu CMenuBVehicles --item ` for you to add any vehicle path. **Delete Vehicle** removes the one you aim at |
| Structures | Copy buildings or whole areas you are aiming at and paste them somewhere else. Select several meshes, copy the selection, remove the last one, or clear the selection |
| Static Meshes | Copy, paste and delete single objects. Presets: straight sandbags and an F4 Phantom. Admins also get **Toggle Collision** and **Delete Any Object** |
| Pickups | Turn a weapon into a pickup on the ground: **Custom** (types `--item ` for you to add the weapon path) or **Copy Held Weapon** (the one in your hands) |
| Actors | Place team spawn points (North and South), an M2 turret, a DShK turret and an ammo resupply point. **Mark Corner** and **Spawn Obj** let you draw and place a brand new capture objective of your own. Everyone gets a **CTF Flag** entry for each team's flag (for example "CTF Flag: PAVN (North)") and **CTF Flag: Command Line**; admins also get **Reset Flags** and **Remove Flags** (see below). **Clear All** removes everything you placed, flags included |

**Placing keys** (while a preview is showing; click to place it, or Alt-click in mouse click mode)

| Key | What it does |
| :--- | :--- |
| Up / Down arrows | Raise or lower the item |
| Left / Right arrows | Slide it sideways |
| Z, X, C | Roll, pitch and turn (yaw) it. **Tab** reverses the direction of all three |
| Mouse wheel | Make it bigger or smaller (not vehicles or actors) |
| Keypad + and - | Change how long it lasts, and so its health |
| **Page Up / Page Down** | Make each key press move and turn it by more or less. The steps are 1, 5, 10, 20 (where it starts), 50 and 100 units for moving and raising, and 1, 2.8, 5.6, 11.25 (where it starts), 22.5 and 45 degrees for turning. You are told the step each time you change it, and it is kept for the next item |

**Actors in the Builder**
- **The preview looks like what you place:** a flag shows its small pole and cloth where it will land, the resupply point shows all its crates, a turret shows that turret. Spawn points and corners are flagpoles in the game, so they preview as one.
- **Turrets start raised:** the DShK starts 60 units (about 1.2 m) up and the M2 20 units up, preview included, so their legs are not in the ground. The Up and Down arrow keys still move them from there. The next item starts back on the ground.
- **No scaling:** actors are always placed at their own size; the mouse wheel says "This cannot be scaled."
- **Resupply points for everyone:** a resupply point is now placed by the server, so every player gets it. Before, only the person who placed it could see it. *Not yet tried in a game.*

Admins also get "Clear All Vehicles / Meshes / Pickups / Actors" entries to wipe what has been placed. Custom objectives you create appear on the map with their borders drawn (see Custom objectives). Placed spawn points are used for the team that owns them.

### Capture the Flag flags

Anyone can place real flags on a pole for capture the flag drills, from the Builder's Actors menu or with `mutate spawnflag`. Only admins can reset or remove them. Players who are not admins can have up to 4 flags out at once and wait 5 seconds between flags (the settings `CTFMaxFlagsPerPlayer` and `CTFPlaceCooldown` change this). Admins have no limit.

- **Picking it up:** any player of either team picks a flag up by walking onto it. They carry it on their back, and everyone else sees it there. One flag per player.
- **Carrier banner and drop key:** while you carry a flag, a gold banner at the top of your screen says "You are carrying the DAK flag" and which key drops it. The banner is a modest size and scales with your screen resolution. Press **X** to drop it at once. The key does nothing else while you carry no flag. *Fixed:* the banner showed but pressing X did nothing, because the game never passed the key on to it. To use another key, set `DropFlagKey` under `[MutCMenu.FlagCarrierInteraction]` in `MutCMenu_Client.ini` (for example `DropFlagKey=G`).
- **Dropping it:** the carrier drops it on purpose with the drop key above or with `mutate dropflag` (you can also bind that to a key, for example `setbind G mutate dropflag`). It is thrown a short way forward. Whoever dropped it has to wait 3 seconds before they can pick it up again.
- **It drops by itself** where the carrier dies (teamkills too), gets into a vehicle or leaves the server.
- **It never disappears.** A flag that falls out of the map goes back to where it was placed. Every flag also goes back there when the round restarts, or when an admin uses **Reset Flags** (`mutate resetflags`).
- **Whose flag it is:** every flag belongs to one faction, chosen when it is placed, and keeps it whoever carries it. Anyone can place either team's flag, whichever team they are on.
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

*Still to be checked in a real game:* how the flag looks on a player's back and on the ground (its size and position), whether the cloth waves, and how the carrier banner looks and reads on screen (the automatic tests only check what it knows and that the key drops the flag). These cannot be checked by the automatic tests.

## 6. The overhead map

CMenu adds these to the overhead map. None of them replaces the game's screen (its HUD), so they work with WW2, Winter War and GOM (Gameplay Overhaul Mutator), which bring their own. *They moved here from MutExtras. Map drawing is being tried in game; how the toolbar, drawings and icons look can only be checked by playing.*

### Spectator view

Spectators normally only see players near them. With CMenu, spectators get:

- **Everyone on the overhead map:** a marker for every living player, using the game's own player and vehicle icons (tank, truck, each helicopter) in the team colour. Squad and team leaders get the leader icon.
- **Empty vehicles on the map:** vehicles nobody is in are shown too, with the game's icon for that kind of vehicle in its team's colour (grey if it has no team), a little faded so they stand apart from vehicles with a crew.
- **Deaths on the map:** someone who dies shows the game's death icon where they fell, in their team's colour, like the base game does for teammates. It stays for 2 seconds, then fades out over 3.
- **Capture the Flag flags on the map:** every flag is shown, whichever team could normally see it, as a small flag in the colour of the team it belongs to, labelled with what is happening to it: "PAVN flag: at its spot", "PAVN flag: carried by Smith" or "PAVN flag: dropped".
- **Triangles over players:** a small triangle in the team colour sitting just above the head of every player in view. When that player is hit, the triangle **strobes white** for about two and a half seconds, like in Arma.
- **Warning strobe for near misses:** when bullets fly close to a player (within about 3 meters, other than their own), their triangle **strobes amber** for as long as the shots keep coming, plus a moment after, so you can see who is under fire before anyone is hurt. When they are actually hit it strobes white instead, so amber means "shots nearby" and white means "damaged". It is part of the spectator view, so `bDisableEnhancedSpectator` turns it off. Only bullets count, not shells or grenades.
- **Death icon over the body:** someone who dies gets the game's death icon over their body instead of the triangle, in their team's colour, fading out after a few seconds.
- **Names when you look at someone:** the player nearest the middle of your screen shows their **name in their team colour** instead of the triangle. When that player is close (within about 40 meters), the **role icon they picked** is shown under the name in the team colour, like the base game does for friendlies. Within **15 meters** the name and role icon show **through walls and objects** too; further away, only for a player you can actually see. While you hold the show-every-name key (below), the player you look at always shows their role too, however far away they are.
- **Hold to see every name:** hold **Left Alt** to show the name and role icon of every player on your screen at once, through walls, at any distance. Let go and it goes back to the one you look at. **Hold Shift and press Left Alt** to leave every name on; do the same again to switch it off, like the tracers key. The one you look at keeps its bigger name and role icon, at any distance. The camera strip at the bottom names the key and says when every name is left on. Left Alt is prone for players, which a spectator doesn't use, and the game still gets the key as normal. To use another key, set `ShowNamesKey` under `[MutCMenu.CMMapInteraction]` in `MutCMenu_Client.ini` (for example `ShowNamesKey=G`).
- **Camera strip:** low in the middle of the screen, a strip shows your camera mode (first person, third person, third person with a free camera, free roam or map camera), who you are watching (with their vehicle, if they are in one), and the two players "previous" goes back to and the two "next" goes on to, in their team colours. Next and previous are worked out on the server the same way the game picks them. They are left out in free roam and the map cameras, where next and previous do not go to players.
- **The game's own name display is turned off** while you spectate, so the two do not double up, and put back when you stop spectating. Your saved setting is never changed.
- **Bullet and shell paths (tracers):** hold the tracers key to see the path of every bullet, rocket, tank shell, artillery shell, bomb and grenade, drawn in the world as a line in the colour of the team that fired it (white if it is not known), live as it happens. A new stretch burns white for a moment, then fades: bullets after about 2 seconds, grenades after 4 and shells and rockets after 5. Bullets are thin, grenades a little thicker, shells and rockets thickest. When a projectile hits something, its line runs on to the spot it hit. In a very big firefight some bullets are left out so shells and grenades always get through. Tracers are **off until you ask for them**, so a firefight does not cover the screen in lines.
  - **Hold Right Control** to see them for as long as you hold it. **Hold Shift and press Right Control** to switch them on and leave them on; do the same again to switch them off. The camera strip says which key to use, and when they are on.
  - To use another key, set `TracersKey` under `[MutCMenu.CMMapInteraction]` in `MutCMenu_Client.ini` (for example `TracersKey=G`).
  - `mutate tracers on` and `mutate tracers off` do the same from the console.
  - **Shots from other players' computers are shown too.** The server does not see those bullets fly (it only hears where they hit), so their paths are drawn from the gun to the first thing in the way, up to 400 meters. They do not bend for bullet drop or go through what they penetrate.
  - **Shots up close are shown.** A bot's bullet (or the host's) that hits something within about 40 meters is gone before the server looks again, so it used to get no line. Those shots now get one the same way as other players' shots.
  - **They do not wash the screen out:** lines thin out when there are a lot at once, never reach full strength and glow less white when new. A line that runs off the screen is cut at the edge, so it no longer smears along the edge of the screen. A line right next to the camera only fades a little, so the shots of the player you watch in first person still show (they used to fade almost away).
  - **Light on the server:** the server only works out other players' shot paths for spectators who have tracers on, or where a shot could have passed close to someone (for the warning strobe), and at most 64 shots each twentieth of a second. The line follows where the gun pointed; the real shot's random spread is not known to the server.
  - Servers can turn them off for everyone with `bDisableSpectatorTracers`.
- **A clean map:** while the map is open, the names, triangles, tracers and the camera strip are hidden.
- **Joining a team from spectating:** everything the spectator view keeps (tracers, hit flashes, death icons, the tracer key) is dropped the moment you join a team, the server stops your tracers, and a map snapshot meant for spectators is never drawn as your teammates.
- **No stuck map camera:** when a round ends the game swings every camera onto its panning map view, and spectators could not get out of it when the next round began. Spectators now keep their own camera through the end of a round. This works even with the spectator view turned off.

*How the flash, the warning strobe, death icons, empty vehicles, flags, the camera strip and the tracers look can only be checked by playing. The same goes for how the tracers fade.*

Turn it off with `bDisableEnhancedSpectator`.

### Players past 32 on a team

The game's map has room for 32 players per team. With more on a team (MaxPlayersMutator), the 33rd and later never show on their teammates' maps. CMenu shows them with the game's own icons, in the squad colour for your own squad and the team colour for the rest. Squad leaders get the squad leader icon and their "SL" label, and a player who dies stays on the map as a dead marker for a few seconds, as the game does for everyone else.

### Custom objectives

Admins can build their own capture objectives in the Builder's **Actors** menu: stand at each corner of the area and pick **Mark Corner**, then pick **Spawn Obj** (you need at least three corners). Only admins can mark corners. Each **Mark Corner** stands a flagpole on the spot for everyone to see, and you are told which corner it was ("Corner 2 marked") and how many more you need. Marking the same spot twice counts once. The poles are taken away when the objective is built. An objective can have up to 32 corners. **Clear Corners** (or `mutate clearcorners`) takes your poles away so you can start again. The area can be any shape, a square, an L or a triangle. The new objective gets the next free letter, and:

- **It captures by itself, on any server.** It works in every Territories game mode, including WW2, Winter War and GOM, not only in CMenu's own game modes. Players, vehicle crews and turret gunners standing inside the area capture it, with the same rules as the map's own objectives: more people capture faster, squad mates and leaders count for more, it drains when nobody is inside, and the capturing team gets the points. Height does not matter.
- **It matches its border.** The area you marked is the area that captures, and the border drawn on the map is that same area. Corners clicked in a crossing order (a "bow tie") are put in outline order. A corner clicked twice counts once.
- **It sits in the middle of its area.** The map's letter, "drop at objective" and the paradrops go to the middle of the area (to the widest part inside it for a curved shape), not to wherever you stood when you picked Spawn Obj.
- **Everyone sees it.** The objective, its letter and its capture progress show on every player's map and HUD, and players who join later get it too. The border is drawn on the overhead map in the colour of the team that holds it (white while nobody does), and fainter while the objective is closed.
- **Realism Match works on it.** `openobj`, `closeobj`, `setobjnorth`, `setobjsouth`, `setobjneutral` and the capture time apply to it by its letter, like the map's own objectives.
- **Admins only.** The server checks that you are an admin, and tells you if the objective could not be built (too few corners, corners too close together, or all 16 objective slots in use). `clearobjs` (or **Clear All**) removes them and frees their letters.

*Tested by the test harness with the objective built in the same game; what a joined player sees (the border on their map) has not been tried in a network game.*

### Names on the map

Point the map cursor at a player's icon and their **name** appears next to it. Players see this for their teammates, and spectators for everyone (in the team colour). A **Player names: on/off** button in the drawing toolbar turns it off for you; the game remembers your choice. It works whether or not map drawing is on.

### Drawing on the map

Anyone can draw on the overhead map, like the map tools in Arma or Squad. Whatever you draw is sent to the players it is for, and they see it on their own map straight away. Players who join later get everything that is already drawn.

**Opening the tools:** open the overhead map and press **T** (the game's tactical display key, or whatever you bound it to) to show the map cursor; press it again to hide it. A **toolbar** appears to the left of the map. "Hide drawing tools" folds it away to one small button; the game remembers which you chose.

**Shooting with the map open:** while the map cursor is hidden, the left mouse button fires as normal. (Without CMenu, a click with the map open only shows the cursor.)

**Tools**

| Tool | How to use it |
| :--- | :--- |
| Pointer | The map works as normal (squad leader orders, the commander's map clicks). Pick this when you are not drawing |
| Pen | Hold the left mouse button and draw freehand |
| Line | Hold and drag a straight line |
| Arrow | Hold and drag a line with an arrow head where you let go, for movement and attacks |
| Circle | Hold on the centre and drag out to the edge |
| Box | Hold on one corner and drag to the other |
| Marker | Click to place the marker picked below the colours: attack, defend, rally, enemy, enemy armour, enemy vehicle, enemy helicopter, artillery target, landing zone, X or a point. They use the game's own map icons |
| Text | Click where the label goes, type it (up to 40 characters), press Enter. Escape cancels |
| Eraser | Click a drawing to erase it. The drawing it would take is highlighted first |
| Ruler | Drag to measure distance in meters and the compass bearing. Only you see it |

While you drag a line, arrow, circle or box, its length, bearing or size in meters is shown next to the cursor. Right mouse still drags the map and the mouse wheel still zooms.

**The rest of the toolbar**

| Button | What it does |
| :--- | :--- |
| Colour row | Picks the colour: red, blue, green, yellow, orange, purple, white or black |
| Player names | Turns the name shown when the cursor is over a player on or off |
| Draw for | Who sees what you draw next. Click to change (see below) |
| Undo | Takes away your newest drawing |
| Clear mine | Takes away all of your drawings |
| Clear all for ... | Clears every drawing in the group picked under "Draw for". Squad: only the squad leader. Team: only the commander. Scrim admins: any group. Everyone sees the button, but it is greyed out and does nothing for those who may not use it |
| Clear every drawing | Scrim admins only: clears the map for everyone |
| Hide drawings | Hides all drawings on your own map (nothing changes for anyone else) |
| Teams shown | Spectators only: show both teams' drawings, or only North's or only South's (the button uses the map's own team names). Drawings for everyone, for spectators and your own always show |

**Clearing asks first:** every clear button (Clear mine, Clear all for, Clear every drawing) turns red and asks "Are you sure?" on the first click. Click it again within 4 seconds to clear. Clicking anything else, or waiting, cancels it.

**Spectators can tell the teams apart:** a spectator sees both teams' drawings, each with a soft edge in the colour of the team it was drawn for (a wider line under lines and shapes, a square under markers, a box under text).

**Toolbar text and markers no longer vanish:** typing a label on the map, or placing a marker, used to make the toolbar's text or its marker icons disappear, because the game drew them under the buttons. The toolbar is now drawn in its own layers above the map, and the map cursor above the toolbar, its text and its marker icons. *This can only be checked by playing.*

**If the toolbar doesn't appear:** the game's log (`ROGame\Logs\Launch.log`) gets a line starting `[MutCMenu] Map tools:` saying why, for example that map drawing is off on this server or that the map wasn't ready.

Holding the mouse over a drawing shows who drew it and who it is for.

**Who sees a drawing, and who can draw it**

| Draw for | Who sees it | Who can draw for it |
| :--- | :--- | :--- |
| Only me | Only you | Everyone |
| Squad | Your squad, and your team's commander | Everyone in a squad |
| Team | Your whole team | Everyone on a team |
| Spectators | Spectators only | Spectators and scrim admins |
| North / South | One team, wherever the admin is | Scrim admins |
| Everyone | Both teams and spectators | Scrim admins |

The other team never sees your team's drawings. Spectators see every drawing except what someone drew only for themselves. A scrim admin is a server admin or someone logged in with `scrimadminlogin` (see section 2).

**Stopping players drawing:** a scrim admin can turn drawing off for players with `mutate mapdrawing off`, or **Admin Stop Players Drawing On The Map** in General Commands. Everyone is told. Players then cannot draw anything, not even for themselves, until a scrim admin turns it back on (`mutate mapdrawing on` or **Admin Let Players Draw On The Map**). Drawings already on the map stay, and players can still undo and clear their own. Scrim admins can always draw. It is back on after a map change.

**Who can erase what:** everyone can erase their own drawings. Squad leaders can also erase their squad's, the commander the whole team's, and scrim admins anything. Clearing a whole group follows the same rule: only the squad leader clears the squad's drawings, only the commander the team's.

**Limits:** each player can have 60 drawings at once (the server can change this); when you go over, your oldest one goes. A freehand line holds up to 200 points; a longer one carries on as a new line. Drawing very fast is slowed down so nobody floods the map. Drawings are cleared when a new round starts, unless the server keeps them, and what you drew only for yourself goes when you leave.

The map on the spawn selection screen does not show the drawings. Turn the feature off with `bDisableMapDrawing`.

## 7. Other features

- **Tank entry for tank crew (or everyone):** tank crew can climb into any tank of their team (or one nobody is in): Vietnam's tanks, GOM's, and WW2 and Winter War tanks. Other roles get no prompt unless the server turns on `bTankPromptForAll`, and then anyone can. Stand close to it and face it, and an enter prompt appears with your use key (F unless you changed it); press it to get in. All the normal rules still apply: a free seat, no enemies inside, not lying down, the tank standing still. WW2 tanks only let in a role the game's own crew roles have, which no 29th role has, so even tank crew couldn't get in; Winter War tanks let in only tank crew. CMenu gets you past that for the moment of getting in only, and your role is left as it was. *Fixed:* the prompt used to show E and wait for E (the game binds the use key through a second name, "Interact"), and it never offered WW2 tanks at all. The prompt now shows on servers too: it used to check for a free seat in a way that only worked in single player, so on a server players never saw it (WW2 tanks with MutExtras tank crew included). The prompt also showed but pressing the key did nothing: the game never passed the key on to it. Now it does.
- **Scales with your screen:** the menu takes up the same part of the screen at any resolution. Its size is set for 1440p; at 1080p it is three quarters of that, at 4K half as big again. The clickable lines in mouse click mode scale with it.
- **Same size menus:** every menu is the same width and height, so they line up and Next and Exit are always in the same place. A few long entries were shortened to fit (for example "Give Temp Scrim Admin" and "Admin Stop Map Drawing").
- **Mouse click mode:** while a menu is open the mouse moves a pointer (the same arrow the map uses) instead of the view, the line under the pointer lights up, and a left click picks it, including Next and Previous/Exit. The pointer stays where you left it when you move to another menu. The click does not fire your weapon.
  - **Alt to look and place:** hold **Alt** and the mouse looks around again; while you have a Builder preview up, a click with Alt held places it, and a click without Alt picks a menu line as usual. Alt does not make you go prone while the menu is open. The menu tells you when a preview is up.
  - **Option forms:** a command that needs options (for example **Drop At Grid**, **Set Friendly Fire Modifier** or **CTF Flag: Command Line**) opens a small form instead of typing in the console. Each option has a box: click it and type. Switch options (like `--nobeam`) are buttons you click on and off. Anything left blank uses the command's default. **Run** (or Enter) sends the command, **Cancel** (or Escape) goes back, and Tab moves to the next box. The command that is sent is the same one you would have typed. Every menu's commands use it, the Builder's **Custom** pickup and vehicle included. A form with many options (fire support) moves up, and gets smaller if it has to, so it always fits on the screen. The console key and the F keys still work while a form is open.
  Turn it off from the main menu to get the normal mouse back. The menu draws the pointer itself, like the map tools do, so it works on Winter War, WW2 and GOM too. How it looks and feels can only be checked by playing.
- **Private messages and help in the console:** short replies go to you only; long help opens in the large console.
- **Loading mod content:** if the server turns it on, CMenu loads extra content packages (MutExtras, GOM 3 and 4, Winter War, WW2) so their weapons and vehicles can be used in the Builder and weapon menu. It switches on Winter War content by itself on Winter War maps and WW2 content on WW2 maps (it goes by the start of the map name: `WWTE`/`WWSU` for Winter War, `RRTE`/`RRSU`/`RRSK`/`DRTE`/`DRSU` for WW2).
- **Wind for smoke:** every map gets a wind direction. If the map has none, CMenu adds one facing a random direction each time the map loads, so smoke drifts. (How the smoke looks can only be checked by playing.)
- **Spawn points from the Builder:** custom spawn points are respected when players spawn.
- **Its own game modes:** CMenu still lists its own Territories and Supremacy game mode entries for servers that already use them, but nothing needs them any more: custom objectives and spawn points work in whatever game mode the server runs.
- **Experimental tank physics:** an optional setting (`bNewTankPhys`).
- **Vehicles and actors keep their size:** the mouse wheel still scales walls and objects in the Builder, but not vehicles or actors (spawns, turrets, flags, resupply points), which are always placed at their own size.
- **Spectators can build:** the Builder works for spectators, who have no character. The preview and the placing follow the spectator camera. (Copying a held weapon needs a weapon, so it is refused for a spectator.)
- **No duplicate menu entries:** a menu used to keep the admin entries it had added and add them again every time it opened, so "Clear All Vehicles" could appear several times (and menu entries could go missing) after opening the menu repeatedly or logging in as scrim admin more than once. Every menu now starts from its own list each time it opens. Setting the menus up a second time no longer stacks a second copy of every menu either.
- **Placing with Keep Open off:** picking an item to place keeps the menu up until you place it; placing it closes the menu. Before, the menu closed straight away and the item could not be placed unless Keep Open was on.
- **Builder preview stops when you pick something else:** choosing an entry that is not an item to place (Clear All, a Delete entry, Reset Flags, ...) ends placing and hides the preview, even with the menu kept open. Before, the preview stayed, a click still placed the last item and the placing keys stayed captured. Turning the page keeps the preview.
- **Fixes:** the Builder no longer breaks after you respawn, and the tank entry prompt is fixed.

## 8. Typing commands instead of using the menu

Commands can be typed in the console as `mutate <command> --option value` (short form `-o value`, like Linux commands). A value runs until the next option, so names and grid squares can contain spaces. `--option=value` also works. The older spellings still work too (for example `mutate giveweaponnorth L1A1`).

| Command | What it does | Options |
| :--- | :--- | :--- |
| `cmenu` | Opens the menu (or a submenu). For the Builder's vehicles and pickups, `--item` starts placing that vehicle or weapon (`mutate cmenu --menu CMenuBVehicles --item ROGameContent.ROHeli_OH6_Content`; the older `cmenu CMenuBVehicles to ...` still works) | `--menu/-m`, `--player/-p`, `--item/-i` |
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
| `spawnflag` | Places a Capture the Flag flag where you are looking: your team's flag, a team's flag with `--team`, or exactly one flag with `--flag` (see the flag table in section 5). Spectators must use `--team` or `--flag` | `--team/-t` (north, south, axis, allies, finnish, soviet, 0, 1), `--flag/-f <name>`, `--nobeam/-n` |
| `dropflag` | Drops the flag you are carrying | none |
| `resetflags` | (Admin) Sends every flag back to where it was placed | none |
| `removeflags` | (Admin) Removes every flag | none |
| `mapundo` | Takes away your newest map drawing | none |
| `mapclear` | Clears map drawings: `mine` (anyone), `squad` (the squad leader), `team` (the commander), `north`, `south`, `spectators` or `everyone` (scrim admins), `all` or nothing (every drawing; scrim admins). Scrim admins can clear any of them. Typed commands do not ask "are you sure?" | `mine`, `squad`, `team`, `north`, `south`, `spectators`, `everyone`, `all` |
| `tracers` | Spectators: `off` hides the bullet and shell paths for you, `on` shows them again. On its own it says which it is | `on`, `off` |
| `mapdrawing` | `off` stops players drawing on the map, `on` lets them again (scrim admins). On its own it says whether players can draw | `on`, `off` |

Commands shared with the Realism Match and Paradrops mutators (`scrimadminlogin`, `changename`, `whois`, the match commands and the paradrop commands) work through CMenu too.

## 9. Settings

Set in WebAdmin under **Mutators > MutCMenu Settings**, or in `MutCMenu_Server.ini`. The page has a tab for each group of settings. Each setting has a plain label, on/off settings are **On** and **Off** buttons, and settings with a few fixed values (such as the number of Canberra planes) offer just those. The labels and button names come from the mod's text file in `Localization\INT` (`MutCMenu.int`), which a server needs next to the mod; without it the page shows the setting names below and the buttons have no text. The tabs are **Mod content** (the `bLoad` settings, `bDebugStandalone`, `bNewTankPhys`, `bTankPromptForAll`), **Fire support**, **Overhead map** (spectator view and map drawing, shown as On / Off rather than as the `bDisable` settings) and **Capture the Flag**.

| Setting | What it does |
| :--- | :--- |
| `bLoadExtras`, `bLoadGOM3`, `bLoadGOM4`, `bLoadWW`, `bLoadWW2` | Load the content of MutExtras, GOM 3/4 (Gameplay Overhaul Mutator), Winter War or WW2. `bLoadWW2` and `bLoadWW` also allow placing WW2 and Winter War Capture the Flag flags on maps that aren't from those mods |
| `bNewTankPhys` | Experimental tank physics |
| `bTankPromptForAll` | Anyone gets the enter tank prompt. Off (the default): only tank crew roles get it |
| `bDebugStandalone` | For testing: in a standalone (single player) game every `bLoad` option above counts as on, so all the mods' content is loaded. It does nothing on a server and does not change the saved `bLoad` settings |
| `bFSPlayersCanCall` | Let players (not only admins) call fire support |
| `bFSNoFriendlyFire` | Strikes never hurt the caller's own team. Off by default: the server's friendly fire setting decides |
| `bFSSilent` | Never announce fire support calls to everyone |
| `bCTFSilent` | Never announce Capture the Flag flags being placed, picked up, dropped, reset or removed (they are announced when this is off) |
| `CTFMaxFlagsPerPlayer` | How many flags a player who is not an admin can have placed at once. 0 means the default, 4 |
| `CTFPlaceCooldown` | Seconds a player who is not an admin waits between placing flags. 0 means the default, 5 |
| `FSPlayerCooldown` | Seconds between player-called strikes for a team (0 = no cooldown). Admins ignore it |
| `FSBomberCount` | Planes in a Canberra run (1-2) |
| `FSGunshipDuration` | How long the gunship circles, in seconds (0 = the map's own time) |
| `bDisableEnhancedSpectator` | Turn the spectator view off (it is on by default) |
| `bDisableSpectatorTracers` | Turn off the bullet and shell paths spectators see (they are on by default) |
| `bDisableMapDrawing` | Turn drawing on the map off (it is on by default) |
| `bKeepMapDrawingsBetweenRounds` | Keep drawings when a new round starts (they are cleared when off) |
| `MaxMapDrawingsPerPlayer` | How many drawings one player can have at once before their oldest goes. 0 means the default, 60 |
| `FSProfiles` (ini only) | The default size of each barrage type: salvos, shells per salvo, spread, time between salvos and delay before the first. The defaults are written the first time the server runs. A type added later (like `MIXED`) is added automatically without touching your values |

## 10. Works with other mods

- **WW2 (Black Orchestra):** vehicles and weapons can be placed and given, tank crews are added, tank entry works.
- **Winter War:** Finnish and Soviet forces, tank crews added, tank entry works.
- **GOM (Gameplay Overhaul Mutator):** custom factions work; tank crews are added; its vehicles can be placed.
- **GreenMen (GM):** its Blue Huey, Green Huey and Green Bushranger helicopters can be placed from the Builder.
- Vehicles from all of these mods can be placed from the Builder.
- The spectator view, players past 32, objective borders and map drawing work with all of them: CMenu draws them on top of whatever map the mod uses and replaces no HUD.

---

*Part of the 29th Infantry Division Mutator Suite*

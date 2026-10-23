# MutCMenu

Console-based menu system for server administration and drill management.

## Setup

1. Open console (~ key)
2. Type: `setbind <key> mutate cmenu` (replace `<key>` with your chosen key, e.g., `F1`)
3. Example: `setbind F1 mutate cmenu`
4. Press your CMenu bind key to open the menu
5. Navigate with arrow keys, select with enter

## Command Syntax

Commands take options as `--long value` or the short `-o value`, like Linux commands. A value runs until the next option, so it can contain spaces (player names, grids). `--option=value` also works.

```
mutate firesupport --type mortar --grid E 5 kp 5
mutate giveweapon --weapon L1A1 --team north       (short: -w -t)
mutate killplayer --player Some Name               (short: -p)
mutate randomobj --obj a,b,c --time 60 --live      (short: -o -t -l; --live starts the countdown at LIVE)
```

Commands that are also provided by another mutator (the Realism Match and Paradrops commands, `scrimadminlogin`, `changename`, `whois`) accept both the options and the older `command value` form. Commands only MutCMenu provides use the options form; the older spellings (`giveweaponnorth`, `clearweaponsall`, `setcmenutextcolor`, `killplayer Name`, `forceunitpatch Name to DP2S4`, ...) are still accepted.

| Command | Options |
| :--- | :--- |
| `giveweapon` | `--weapon/-w`, `--team/-t` (north, south or all; leave out for yourself) |
| `clearweapons` | `--team/-t` (north, south or all; leave out for yourself) |
| `setcmenucolor` | `--text/-t R G B A`, `--background/-b R G B A`, `--border/-o R G B A` |
| `cmenu` | `--menu/-m`, `--player/-p` |
| `firesupport` | `--type/-t`, `--grid/-g` or `--mark/-m`; `--SL/-l [n]` or `--mark SL3` (squad marks); `--direction/-b` (napalm/canberra heading); admin barrage settings `--salvos/-s`, `--shells/-n`, `--spread/-r` (meters), `--interval/-i`, `--persist/-p`; admin `--delay/-d` (first strike delay, 10-300 s) and `--suppress/-q` |
| `killplayer`, `teleporttome`, `forceswitchteam`, `forcerespawn`, `forcesafetyon`, `forcesafetyoff`, `tempadminlogin`, `tempadminlogout` | `--player/-p` |
| `fdao` | `--player/-p`, `--obj/-o` |
| `fdag` | `--player/-p`, `--grid/-g` |
| `forceunitpatch` | `--player/-p`, `--unit/-u` |
| `forcerankpatch` | `--player/-p`, `--rank/-r` |
| `scrimadminlogin` | `--user/-u`, `--password/-p` |

When you pick an entry that needs a value, CMenu closes, writes the help for that command into the console history, and opens the large console with the command pre-typed, e.g. `Mutate FIRESUPPORT --type mortar --grid ` with the cursor at the end. Read the options and examples in the history above, finish the command with your value and press enter.

A text-entry dialog was tried and is disabled for now (commented out in `CMenuTextEntryScene.uc`, `CMenu.uc` and `DummyActor.uc`).

## CMenu Navigation

All features accessed through: **Main Menu > [Category]**

### Player Management (Admin Only)

Access: Main Menu > Manage Players > Select Player

| Action | Description |
| :--- | :--- |
| `Drop At Objective/Grid` | Teleport player to objective letter or grid coordinates |
| `Teleport To Me` | Bring player to your location |
| `Switch Team` | Force player to switch teams |
| `Respawn` | Force player to respawn |
| `Kill` | Force suicide player |
| `Safety On/Off` | Force weapon safety state |
| `Change Patch Unit/Rank` | Change player insignia (e.g., DP2S4, cpl) |
| `Change Name` | Force change player's name |
| `Find Original Name` | Look up original name (tracks name changes) |
| `Give Temporary Admin` | Grant temporary scrimmage admin powers |
| `Revoke Temporary Admin` | Remove temporary admin powers |

### Weapon Distribution

Access: Main Menu > Weapon Menu

| Action | Description |
| :--- | :--- |
| `Give Weapon SELF` | Give yourself a weapon |
| `Give Weapon NORTH` | Give weapon to Northern team (admin only) |
| `Give Weapon SOUTH` | Give weapon to Southern team (admin only) |
| `Give Weapon All` | Give weapon to all players (admin only) |
| `Clear Weapons SELF` | Clear your weapons |
| `Clear Weapons NORTH/SOUTH/All` | Clear team/all weapons (admin only) |

### Vehicle Spawning

Access: Main Menu > Builder Menu > VEHICLES

| Action | Description |
| :--- | :--- |
| `Select Vehicle` | Choose vehicle (Cobra, Loach, Huey, etc.), aim, confirm placement |
| `Delete Vehicle` | Remove the vehicle you're aiming at |
| `Clear All Vehicles` | Remove all spawned vehicles (admin only) |

Supports: Vanilla, GAM, GOM, Black Orchestra, Winter War vehicles

### Structure Placement

Access: Main Menu > Builder Menu > STRUCTURES

| Action | Description |
| :--- | :--- |
| `Copy Area To Clipboard` | Copy structures you're aiming at |
| `Paste Structure` | Place copied structures at target location |
| `Select Mesh` | Aim and select meshes (multiple selection supported) |
| `Copy Selection` | Copy all selected meshes to clipboard |
| `Remove Last Selected` | Remove last selected mesh from selection |
| `Clear Selected` | Deselect all meshes |
| `Clear All Meshes` | Remove all placed structures (admin only) |

### Static Mesh Placement

Access: Main Menu > Builder Menu > STATIC MESHES

| Action | Description |
| :--- | :--- |
| `Copy Mesh` | Copy mesh you're looking at |
| `Paste Mesh` | Paste mesh from clipboard |
| `Delete Mesh` | Remove mesh you're aiming at |
| `Preset Meshes` | Sandbags, F4 Phantom, etc. |
| `Clear All Meshes` | Remove all placed meshes (admin only) |
| `Toggle Collision` | Toggle collision on aimed mesh (admin only) |
| `Delete Any Object` | Delete any object aimed at (admin only) |

### Weapon Pickup Spawning

Access: Main Menu > Builder Menu > PICKUPS

| Action | Description |
| :--- | :--- |
| `Custom` | Enter custom weapon path |
| `Copy Held Weapon` | Create pickup for weapon you're holding |
| `Clear All Pickups` | Remove all weapon pickups (admin only) |

### Actor Placement

Access: Main Menu > Builder Menu > ACTORS

| Action | Description |
| :--- | :--- |
| `Set North Spawn` | Place Northern team spawn point |
| `Set South Spawn` | Place Southern team spawn point |
| `Delete North/South Spawns` | Remove team spawn points |
| `M2 Turret` | Place M2 machine gun turret |
| `DShK Turret` | Place DShK machine gun turret |
| `Resupply Point` | Place ammo resupply point |
| `Clear All` | Remove all placed actors (admin only) |

### CMenu Settings

Access: Main Menu > CMenu Settings

| Action | Description |
| :--- | :--- |
| `Set CMenu Text Color` | RGBA format (e.g., 255 128 0 255) |
| `Set CMenu Background Color` | RGBA format |
| `Set CMenu Border Color` | RGBA format |
| `Toggle CMenu Background` | Show/hide background |
| `Toggle CMenu Stay` | Keep menu open or close after selection |

### General Commands

Access: Main Menu > General Commands

| Action | Description |
| :--- | :--- |
| `Switch Team` | Switch your team |
| `Set Team Ready/Not Ready` | Team ready system for matches |
| `Respawn` | Respawn yourself |
| `Kill Self` | Suicide command |
| `Drop At Objective/Grid` | Teleport yourself to location |
| `Change Name` | Change your displayed name |
| `Safety On/Off` | Toggle weapon safety |
| `Check AITs` | See AIT role usage |

### Fire Support

Access: Main Menu > Fire Support Menu (admins always; other players only when `bFSPlayersCanCall` is enabled)

Each action asks for a target: a grid such as `E 5 kp 5` (or `E5`), or `MARK` to use the team's base game marked arty position. Strikes fire for the caller's team and do not use the commander's ability cooldowns. Command form: `mutate firesupport --type <type> --grid <grid>` or `--mark` (short `-t -g -m`).

| Action | Description |
| :--- | :--- |
| `Mortar Barrage` | Mortar shells |
| `Artillery Barrage` | Heavy artillery |
| `Airburst Artillery` | Airburst artillery |
| `Rocket Barrage` | Rocket barrage |
| `White Phosphorus Barrage` | WP mortar rounds |
| `Napalm Strike` | Napalm aircraft run |
| `Canberra Bombing Run` | Carpet bomber run |
| `AC-47 Gunship` | Gunship orbit over the target |

Server settings (`MutCMenu_Server.ini`, section `[MutCMenu.MutCMenu]`):

| Setting | Description |
| :--- | :--- |
| `bFSPlayersCanCall` | Let non-admin players use fire support |
| `FSPlayerCooldown` | Seconds between player-called strikes per team (0 = none). Admins ignore it |
| `bFSFriendlyFire` | Strikes can damage the caller's own team. When off, friendly strike damage is zeroed (and so is never punished) |
| `bFSSilent` | Don't broadcast strike calls to everyone |
| `FSBomberCount` | Aircraft per Canberra run (1-2, 0 = 2) |
| `FSGunshipDuration` | Gunship orbit seconds (0 = map default) |
| `FSProfiles` | Per strike type shell settings: `Salvos`, `Shells` per salvo, `Spread` (unreal units), `Interval` between salvos and `Delay` before the first salvo. Defaults are written on first run |

Players cannot call fire support onto no-artillery volumes (admins can).

**Changing a profile in the command (admins only).** Barrage types (mortar, artillery, airburst, rocket, wp) accept per-call overrides of their `FSProfiles` entry:

| Option | Short | Range | Meaning |
| :--- | :--- | :--- | :--- |
| `--salvos` | `-s` | 1-20 | Number of salvos |
| `--shells` | `-n` | 1-100 | Shells per salvo |
| `--spread` | `-r` | 0-200 | Scatter radius in meters (decimals allowed) |
| `--interval` | `-i` | 1-120 | Seconds between salvos |
| `--persist` | `-p` | | Save the resulting values as the new profile for that type |

Anything you leave out uses the saved profile. Out-of-range values are clamped. Example: `mutate firesupport --type mortar --grid E 5 kp 5 --salvos 6 --shells 8 --spread 8 --persist`. Non-admins cannot use these options, and they do not apply to napalm, canberra or spooky.

**First strike delay (admins only, every type).** `--delay` (`-d`) holds the first strike back for 10-300 seconds (smaller or larger values are clamped, with a note). Barrages wait that long before their first salvo (and `--persist` saves it into the profile); aircraft wait that long before taking off, so the strike arrives after the delay plus their flight time. The announcement says when the first strike is due. Without it, barrages use the profile's `Delay` and aircraft launch at once.

**Choosing the mark.** With `--mark` (or no target at all) a squad leader uses their own squad's arty mark, the commander uses the mark selected on their map, and anyone else uses the team's saved mark. `--mark SL3` (also `--SL 3`, `-l 3`; `--SL` alone is your own squad) picks squad 3's mark and `--mark CMD` the commander's. Squad leaders can only pick their own squad; admins and the commander can pick any.

**Outside the combat area.** Admin strikes ignore the no-artillery zones, including the ones that fence off the area outside the combat area: the Canberra and napalm aircraft are the mod's own `CMCarpetBomberAircraft` / `CMNapalmStrikeAircraft(ARVN)`, which skip the base game's check for admin calls, and they are no longer despawned for being outside the map bounds. Players are still blocked from no-artillery zones.

**Flight direction (napalm and canberra, anyone who can call them).** `--direction` (`-b`, or `--dir`) sets the heading the aircraft flies on, as a compass point (`N`, `NE`, `ESE`, ... all 16, or the full names) or a bearing from 0 to 360 clockwise from north, where north is the top of the map grid. The aircraft starts at the map edge behind the target and flies over it on that heading, e.g. `mutate firesupport --type napalm --grid E 5 --direction SW` flies from the north-east toward the south-west. Without it the game picks the direction as before (or the marked one with `--mark`).

**Suppressing the announcement (admins only).** `--suppress` (`-q`) skips the server-wide "called in" message for that call; the caller still gets a private confirmation. `bFSSilent` does the same for every call.

`FSProfiles` `Spread` stays stored in unreal units (50 = 1 meter) so existing configs are unchanged; only commands and messages use meters.

### Round Start Voice

The round-start commander speech is muted by default. Turn on `bAllowIntroVO` on the mutator settings page (or set `bAllowIntroVO=True` in `MutCMenu_Server.ini`) to keep it.

### Mutator settings page

Besides the content loading options, the MutCMenu page of the mutator settings now holds the options that differ from match to match: `bAllowIntroVO`, `bFSPlayersCanCall` (off = only admins can call fire support), `bFSFriendlyFire`, `bFSSilent`, `FSPlayerCooldown`, `FSBomberCount` and `FSGunshipDuration`. `FSProfiles` stays in the ini.

### Help output

Short guidance (a few lines) is sent to you as private chat messages and the one-line console opens with the command already typed. Long guidance (more than 4 lines, e.g. `mutate firesupport` help, `realismhelp`, `scrimadminhelp`) is written to the console history and shown in the large console instead of flooding the chat. A mistyped fire support argument tells you what is wrong in the chat and puts your command back in the one-line console to edit.

### Paradrop Menu

Access: Main Menu > Paradrop Menu (admin only)

| Action | Description |
| :--- | :--- |
| `Drop All At Obj` | Teleport all players to objective (e.g., "A", "B") |
| `Drop North At Obj` | Teleport Northern team to objective |
| `Drop South At Obj` | Teleport Southern team to objective |
| `Drop All At Grid` | Teleport all players to grid (e.g., "E 5 kp 5") |
| `Drop North At Grid` | Teleport Northern team to grid |
| `Drop South At Grid` | Teleport Southern team to grid |

## Configuration

### WebAdmin Settings

Access: WebAdmin > Mutators > MutCMenu Settings

| `Setting` | Description |
| :--- | :--- |
| ``bUseDefaultFactions`` | Must be enabled for bAITRoles to work. Controls faction selection |
| ``MyNorthForce`` | Northern force faction (PAVN = 0, NLF = 1) |
| ``MySouthForce`` | Southern force faction (USA = 0, USMC = 1, AUS = 2, ARVN = 3) |
| ``bLoadExtras`` | Enable MutExtras mod content |
| ``bLoadGOM3`` | Enable GOM3 mod content |
| ``bLoadGOM4`` | Enable GOM4 mod content |
| ``bLoadWW`` | Enable Winter War mod content |
| ``bLoadWW2`` | Enable Black Orchestra (WW2) mod content |
| ``bNewTankPhys`` | Enable new tank physics |

## Realism Match Integration

MutCMenu includes direct integration with MutRealismMatch for match control. The commands are grouped into submenus:

Access: Main Menu > Realism Match Menu (admin only)

| Submenu | Contents |
| :--- | :--- |
| `Match Control Menu` | Enable/Disable Match, Force Match Live, Countdown To Live, Cancel Live Countdown, Reset Match Live, Restart Round, Suicide All / End Round, Respawn All Dead Players |
| `Round Settings Menu` | Round Timer, Cancel Round Timer, Set Round Duration, Set Friendly Fire Modifier, Toggle Auto Respawns, Set North/South Reinforcements |
| `Objectives Menu` | Open/Close Objective, Random Objective (`--obj a,b,c --time 60`), Cancel Random Objective, Set Objective Neutral/North/South, Set All Objectives Neutral/North/South, Set Obj Minimum Capture Time |
| `Teams and Weapons Menu` | Swap Teams, Swap North to South, Swap South to North, Weapons Hold, Weapons Free |
| `Scrimmage Admin Help` | Display admin commands help |

Choosing 0 in a submenu returns to the Realism Match Menu. The matching console commands and their options are listed in the MutRealismMatch README.

## Mod Compatibility

**Supported mods:**
- **WW2 (Black Orchestra)** - Full vehicle and weapon spawning, automatic tank crew role injection with faction-aware tankers (Wehrmacht, Commonwealth, Soviet, US, IJA, etc.), fixes tank entry compatibility
- **Winter War** - Finnish forces support, automatic Finnish/Soviet tank crew role injection, fixes tank entry compatibility
- **Green Army Men** - Complete compatibility with custom factions, automatic tank crew role injection
- Vehicles from all mods can be spawned through Builder Menu
- Tank crew roles automatically fixed to prevent conflicts with pilot flags

---

*Part of the 29th Infantry Division Mutator Suite*

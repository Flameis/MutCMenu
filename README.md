# MutCMenu

Console-based menu system for server administration and drill management.

## Setup

1. Open console (~ key)
2. Type: `setbind <key> mutate cmenu` (replace `<key>` with your chosen key, e.g., `F1`)
3. Example: `setbind F1 mutate cmenu`
4. Press your CMenu bind key to open the menu
5. Navigate with arrow keys, select with enter

## CMenu Navigation

All features accessed through: **Main Menu > [Category]**

### Player Management (Admin Only)

Access: Main Menu > Manage Players > Select Player

| Action | Description |
| :--- | :--- |
| Drop At Objective/Grid | Teleport player to objective letter or grid coordinates |
| Teleport To Me | Bring player to your location |
| Switch Team | Force player to switch teams |
| Respawn | Force player to respawn |
| Kill | Force suicide player |
| Safety On/Off | Force weapon safety state |
| Change Patch Unit/Rank | Change player insignia (e.g., DP2S4, cpl) |
| Change Name | Force change player's name |
| Find Original Name | Look up original name (tracks name changes) |
| Give Temporary Admin | Grant temporary scrimmage admin powers |
| Revoke Temporary Admin | Remove temporary admin powers |

### Weapon Distribution

Access: Main Menu > Weapon Menu

| Action | Description |
| :--- | :--- |
| Give Weapon SELF | Give yourself a weapon |
| Give Weapon NORTH | Give weapon to Northern team (admin only) |
| Give Weapon SOUTH | Give weapon to Southern team (admin only) |
| Give Weapon All | Give weapon to all players (admin only) |
| Clear Weapons SELF | Clear your weapons |
| Clear Weapons NORTH/SOUTH/All | Clear team/all weapons (admin only) |

### Vehicle Spawning

Access: Main Menu > Builder Menu > VEHICLES

| Action | Description |
| :--- | :--- |
| Select Vehicle | Choose vehicle (Cobra, Loach, Huey, etc.), aim, confirm placement |
| Enter Vehicle | Instantly enter vehicle you're aiming at |
| Clear All Vehicles | Remove all spawned vehicles (admin only) |

Supports: Vanilla, GAM, GOM, Black Orchestra, Winter War vehicles

### Structure Placement

Access: Main Menu > Builder Menu > STRUCTURES

| Action | Description |
| :--- | :--- |
| Copy Area To Clipboard | Copy structures you're aiming at |
| Paste Structure | Place copied structures at target location |
| Select Mesh | Aim and select meshes (multiple selection supported) |
| Copy Selection | Copy all selected meshes to clipboard |
| Remove Last Selected | Remove last selected mesh from selection |
| Clear Selected | Deselect all meshes |
| Clear All Meshes | Remove all placed structures (admin only) |

### Static Mesh Placement

Access: Main Menu > Builder Menu > STATIC MESHES

| Action | Description |
| :--- | :--- |
| Copy Mesh | Copy mesh you're looking at |
| Paste Mesh | Paste mesh from clipboard |
| Delete Mesh | Remove mesh you're aiming at |
| Preset Meshes | Sandbags, F4 Phantom, etc. |
| Clear All Meshes | Remove all placed meshes (admin only) |
| Toggle Collision | Toggle collision on aimed mesh (admin only) |
| Delete Any Object | Delete any object aimed at (admin only) |

### Weapon Pickup Spawning

Access: Main Menu > Builder Menu > PICKUPS

| Action | Description |
| :--- | :--- |
| Custom | Enter custom weapon path |
| Copy Held Weapon | Create pickup for weapon you're holding |
| Clear All Pickups | Remove all weapon pickups (admin only) |

### Actor Placement

Access: Main Menu > Builder Menu > ACTORS

| Action | Description |
| :--- | :--- |
| Set North Spawn | Place Northern team spawn point |
| Set South Spawn | Place Southern team spawn point |
| Delete North/South Spawns | Remove team spawn points |
| M2 Turret | Place M2 machine gun turret |
| DShK Turret | Place DShK machine gun turret |
| Resupply Point | Place ammo resupply point |
| Clear All | Remove all placed actors (admin only) |

### CMenu Settings

Access: Main Menu > CMenu Settings

| Action | Description |
| :--- | :--- |
| Set CMenu Text Color | RGBA format (e.g., 255 128 0 255) |
| Set CMenu Background Color | RGBA format |
| Set CMenu Border Color | RGBA format |
| Toggle CMenu Background | Show/hide background |
| Toggle CMenu Stay | Keep menu open or close after selection |

### General Commands

Access: Main Menu > General Commands

| Action | Description |
| :--- | :--- |
| Switch Team | Switch your team |
| Set Team Ready/Not Ready | Team ready system for matches |
| Respawn | Respawn yourself |
| Kill Self | Suicide command |
| Drop At Objective/Grid | Teleport yourself to location |
| Change Name | Change your displayed name |
| Safety On/Off | Toggle weapon safety |
| Check AITs | See AIT role usage |

### Fire Support (In Development)

Access: Main Menu > Fire Support Menu (admin only)

| Action | Description |
| :--- | :--- |
| Call Artillery | Artillery barrage at your position |
| Call Mortar | Mortar strike at your position |
| Call Airstrike | Air support at your position |

Bypasses normal commander ability system.

### Paradrop Menu

Access: Main Menu > Paradrop Menu (admin only)

| Action | Description |
| :--- | :--- |
| Drop All At Obj | Teleport all players to objective (e.g., "A", "B") |
| Drop North At Obj | Teleport Northern team to objective |
| Drop South At Obj | Teleport Southern team to objective |
| Drop All At Grid | Teleport all players to grid (e.g., "E 5 kp 5") |
| Drop North At Grid | Teleport Northern team to grid |
| Drop South At Grid | Teleport Southern team to grid |

## Mod Compatibility

**Supported mods:**
- **WW2 (Black Orchestra)** - Full vehicle and weapon spawning, automatic tank crew role injection with faction-aware tankers (Wehrmacht, Commonwealth, Soviet, US, IJA, etc.), fixes tank entry compatibility
- **Winter War** - Finnish forces support, automatic Finnish/Soviet tank crew role injection, fixes tank entry compatibility
- **Green Army Men** - Complete compatibility with custom factions, automatic tank crew role injection
- Vehicles from all mods can be spawned through Builder Menu
- Tank crew roles automatically fixed to prevent conflicts with pilot flags

---

*Part of the 29th Infantry Division Mutator Suite*

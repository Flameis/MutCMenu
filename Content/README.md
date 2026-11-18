# MutCMenu content

Pictures for CMenu that the game has none of. They go in a content package, `MutCMenuContent`, which ships in the CMenu
workshop item next to `MutCMenu.u`. CMenu loads them when they are there and does without them when they are not.

| File | Goes in the package as | Used for |
|---|---|---|
| `UI_HUD_WeaponSelect_CTFFlag.png` | `MutCMenuContent.UI.UI_HUD_WeaponSelect_CTFFlag` | The CTF Flag item's picture in the inventory and weapon boxes |

## Making the package

The editor can't import a texture from the command line, so this is done once by hand:

1. Open the SDK editor (`VNEditor.exe editor -useunpublished`), go to the Content Browser and press **Import**.
2. Pick `UI_HUD_WeaponSelect_CTFFlag.png`. Package `MutCMenuContent`, Grouping `UI`, Name `UI_HUD_WeaponSelect_CTFFlag`.
3. Set **LOD Group** to `TEXTUREGROUP_UI`, **Compression Settings** to `TC_Default`, and leave **SRGB** on (the game's
   own weapon pictures are set the same way). Untick **Defer Compression**.
4. Save it as `Documents\My Games\Rising Storm 2\ROGame\Unpublished\CookedPC\Packages\MutCMenuContent\MutCMenuContent.upk`.
5. Add `MutCMenuContent\MutCMenuContent.upk` to the MutCMenu line's `Content` list in
   `.claude\skills\workshop-push\Publish-Workshop.ps1`, so it is cooked and uploaded with CMenu.

`Draw-FlagIcon.py` in this folder draws the flag picture again (plain Python, no extra modules):
`python Draw-FlagIcon.py UI_HUD_WeaponSelect_CTFFlag.png`.

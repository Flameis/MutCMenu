class CMenuBMain extends CMenu;

defaultproperties
{
    MenuName="BUILDER"

    MenuText.add("STATIC MESHES")
    MenuText.add("STRUCTURES")
    MenuText.add("VEHICLES")
    MenuText.add("PICKUPS")
    MenuText.add("ACTORS")
    MenuText.add("CTF FLAGS")
    
    MenuCommand.add("CMENU CMENUBMESHES")
    MenuCommand.add("CMENU CMenuBStructures")
    MenuCommand.add("CMENU CMENUBVEHICLES")
    MenuCommand.add("CMENU CMenuBPickups")
    MenuCommand.add("CMENU CMENUBACTORS")
    MenuCommand.add("CMENU CMENUBFLAGS")
}
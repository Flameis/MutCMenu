class CMenuBuilder extends CMenuBase;

defaultproperties
{
    MenuName="BUILDER"

    MenuText.Add("ACTORS")
    MenuText.Add("STATIC MESHES")
    MenuText.Add("PREFABS")
    MenuText.Add("VEHICLES")
    MenuText.Add("WEAPONS")
    
    MenuCommand.Add("CMENU CMENUBACTORS")
    MenuCommand.Add("CMENU CMENUBMESHES")
    MenuCommand.Add("CMENU CMENUBPREFABS")
    MenuCommand.Add("CMENU CMENUBVEHICLES")
    MenuCommand.Add("CMENU CMENUBWEAPONS")
}
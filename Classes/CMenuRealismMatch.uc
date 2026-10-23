// Hub for the Realism Match admin commands. Each group lives in its own submenu.
class CMenuRealismMatch extends CMenuRMBase;

defaultproperties
{
    MenuName="REALISM MATCH"

    MenuText.add("Match Control Menu")
    MenuText.add("Round Settings Menu")
    MenuText.add("Objectives Menu")
    MenuText.add("Teams and Weapons Menu")
    MenuText.add("Scrimmage Admin Help")

    MenuCommand.add("CMENU CMENURMCONTROL")
    MenuCommand.add("CMENU CMENURMROUND")
    MenuCommand.add("CMENU CMENURMOBJECTIVES")
    MenuCommand.add("CMENU CMENURMTEAMS")
    MenuCommand.add("SCRIMADMINHELP")
}

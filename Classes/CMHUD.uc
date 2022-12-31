class CMHUD extends ROHUD
	config(MutCMenu_Client);

defaultproperties
{
	SideColors(0)=(R=229,G=73,B=39,A=255) //(R=240,G=32,B=32,A=255)
	SideColors(1)=(R=80,G=160,B=240,A=255)
	SideDeadColors(0)=(R=100,G=46,B=35,A=255) //(R=171,G=47,B=20,A=255) //(R=190,G=24,B=24,A=255)
	SideDeadColors(1)=(R=50,G=70,B=120,A=255) //(R=50,G=110,B=190,A=255)
	NeutralColor=(R=255,G=255,B=255,A=210)
	//SquadColors(0)=(R=235,G=61,B=235,A=210)//(R=203,G=89,B=206,A=210)
	//SquadColors(1)=(R=235,G=61,B=235,A=210)//(R=203,G=89,B=206,A=210)
	//SquadDeadColors(0)=(R=173,G=18,B=173,A=210)//(R=164,G=255,B=164,A=210)
	//SquadDeadColors(1)=(R=173,G=18,B=173,A=210)//(R=164,G=255,B=164,A=210)
	//AttachedSquadColors(0)=(R=173,G=18,B=173,A=210)//(R=164,G=255,B=164,A=210)
	//AttachedSquadColors(1)=(R=173,G=18,B=173,A=210)//(R=164,G=255,B=164,A=210)
	TeamLeaderColor=(R=255,G=128,B=0,A=255)
	SquadLeaderColor=(R=149,G=108,B=199,A=255)//(R=173,G=18,B=173,A=210)//(R=204,G=153,B=0,A=255)
	PlayerTagFont=Font'VN_UI_Mega_Fonts.Font_VN_Mega_36'//Font'VN_UI_Fonts.Font_VN_Clean'

	SquadColourPresets(0)=(SquadColour=(R=253,G=162,B=0,A=210),SquadDeadColour=(R=180,G=129,B=46,A=210),AttachedSquadColour=(R=180,G=129,B=46,A=210))
	SquadColourPresets(1)=(SquadColour=(R=50,G=200,B=60,A=210),SquadDeadColour=(R=15,G=100,B=33,A=210),AttachedSquadColour=(R=15,G=100,B=33,A=210))
	SquadColourPresets(2)=(SquadColour=(R=235,G=61,B=235,A=210),SquadDeadColour=(R=173,G=18,B=173,A=210),AttachedSquadColour=(R=173,G=18,B=173,A=210))
	SquadColourPresets(3)=(SquadColour=(R=150,G=45,B=255,A=210),SquadDeadColour=(R=94,G=0,B=187,A=210),AttachedSquadColour=(R=94,G=0,B=187,A=210))

	DefaultStatusWidget=class'ROHUDWidgetStatus'
	DefaultWeaponWidget=class'ROHUDWidgetWeapon'
	DefaultInventoryWidget=class'ROHUDWidgetInventory'
	DefaultObjectiveWidget=class'ROHUDWidgetObjective'
	DefaultScoreboardWidgetTE=class'ROGame.ROHUDWidgetScoreboardTE'
	DefaultScoreboardWidgetFF=class'ROGame.ROHUDWidgetScoreboardFF'
	DefaultScoreboardWidgetSK=class'ROGame.ROHUDWidgetScoreboardSK'
	DefaultScoreboardWidgetSU=class'ROHUDWidgetScoreboardSU'
	DefaultOverheadMapWidget=class'CMHUDWidgetOverheadMap'
	DefaultCommunicationWidget=class'ROHUDWidgetComCommunication'
	DefaultOrdersWidget=class'ROHUDWidgetComOrders'
	DefaultCompactVoiceCommsWidget=class'ROHUDWidgetCompactVoiceComms'
	DefaultMessagesChatWidget=class'ROHUDWidgetMessagesColoredChat'
	DefaultMessagesAlertsWidget=class'ROHUDWidgetMessagesAlerts'
	DefaultMessagesRedAlertsWidget=class'ROHUDWidgetMessagesRedAlerts'
	DefaultMessageBleedingWidget=class'ROHUDWidgetMessageBleeding'
	DefaultMessagesPickupsWidget=class'ROHUDWidgetMessagesPickups'
	DefaultMessagesOrdersSLWidget=class'ROHUDWidgetMessagesOrdersSL'
	DefaultMessagesReloadWidget=class'ROHUDWidgetMessagesReload'
	DefaultMessagesPromptsWidget=class'ROHUDWidgetMessagesPrompts'
	DefaultIndicatorWidget=class'ROHUDWidgetIndicator'
	DefaultIndicatorRightWidget=class'ROHUDWidgetIndicatorRight'
	DefaultKillMessageWidget=class'ROHUDWidgetKillMessages'
	DefaultCompassWidget=class'ROHUDWidgetSimpleCompass'
	DefaultObjectiveOverviewWidget=class'ROHUDWidgetObjectiveOverview'
	DefaultWorldWidget=class'ROHUDWidgetWorld'
	DefaultPeripheralWhips=class'ROHUDWidgetPeripheralWhips'
	DefaultPeripheralDamage=class'ROHUDWidgetPeripheralDamage'
	DefaultPeripheralPawns=class'ROHUDWidgetPeripheralPawns'
	DefaultCutOffTimerWidget=class'ROHUDWidgetCutOffTimer'
	DefaultMapBoundaryTimer=class'ROHUDWidgetMapBoundaryTimer'
	//DefaultMiniStrengthPointsWidget=class'ROHUDWidgetMiniStrengthPoints'
	DefaultSpawnQueueWidget=class'ROHUDWidgetSpawnQueue'
	DefaultCommanderWidget=class'ROHUDWidgetCommander'
	DefaultCommanderAbilitiesWidgetNorth=class'ROHUDWidgetCommanderAbilitiesNorth'
	DefaultCommanderAbilitiesWidgetSouth=class'ROHUDWidgetCommanderAbilitiesSouth'
	/*DefaultTimerWidgetTE=class'ROHUDWidgetLockDownTimer'
	DefaultTimerWidgetFF=class'ROHUDWidgetRoundEndTimer'
	DefaultTimerWidgetSP=class'ROHUDWidgetSPDefendTimer'
	DefaultTimerWidgetSU=class'ROHUDWidgetOvertimeTimer'*/
	DefaultGameStartWidget=class'ROHUDWidgetTerritoryStartTimer'
	DefaultVOIPMeterWidget=class'ROHUDWidgetVOIPMeter'
	DefaultSpecatorWidget=class'CMHUDWidgetSpectator'
	DefaultTrainingWidget=class'ROHUDWidgetTraining'
	DefaultVOIPTalkersWidget=class'ROHUDWidgetVOIPTalkers'
	DefaultInviteMessageWidget=class'ROHUDWidgetInviteMessage'
	DefaultLevelUpWidget=class'ROHUDWidgetLevelUpMessage'
	DefaultSquadListWidget=class'ROHUDWidgetSquadList'
	DefaultVehicleListWidget=class'ROHUDWidgetVehicleList'
	DefaultHintsWidget=class'ROHUDWidgetHints'
	DefaultVehicleInfoWidget=class'ROHUDWidgetVehicleInfo'
	DefaultFadeWidget=class'ROHUDWidgetFadeScreen'
	DefaultGForceFadeWidget=class'ROHUDWidgetGForceFade'
	DefaultCamoIndicatorWidget=class'ROHUDWidgetCamoIndicator'
	DefaultHelicopterInfoWidget=class'ROHUDWidgetHelicopterInfo'
	DefaultHelicopterInstrumentWidget=class'ROHUDWidgetHelicopterInstruments'
	DefaultMessagesTrapsWidget=class'ROHUDWidgetMessagesTraps'
	DefaultGameStatusWidgetSK=class'ROHUDWidgetGameStatusSK'
	DefaultGameStatusWidgetTE=class'ROHUDWidgetGameStatusTE'
	DefaultGameStatusWidgetSU=class'ROHUDWidgetGameStatusSU'
	DefaultPromptBoxWidget=class'ROHUDWidgetPromptBox'
	DefaultWatermarkWidget=class'ROHUDWidgetWatermark'
	DefaultAmmoCheckWidget=class'ROHUDWidgetAmmoCheckIcon'
	DefaultSLNoticeWidget=class'ROHUDWidgetSLNotice'
	DefaultBandagingBarWidget=class'ROHUDWidgetProgressBar'
	DefaultHeloTrainingRespawnWidget=class'ROHUDWidgetHeloTrainRespawnTimer'
	DefaultRadiomanHelperWidget=class'ROHUDWidgetRadiomanHelper'

	SquadMemberWorldTexture=Texture2D'VN_UI_Textures.HUD.World.ui_world_icons_squad'
	SquadLeaderWorldTexture=Texture2D'VN_UI_Textures.HUD.World.ui_world_icons_squadleader'
	SquadHelicopterWorldTexture=Texture2D'VN_UI_Textures.HUD.World.ui_world_icons_squadhelo'
	TeamLeaderWorldTexture=Texture2D'VN_UI_Textures.HUD.World.ui_world_icons_teamleader'
	VOIPWorldTexture=Texture2D'VN_UI_Textures.HUD.World.ui_world_icons_voiptalker'

	Begin Object Class=ROHUDWidgetComponent Name=Reticle
		X=448
		Y=320
		Width=128
		Height=128
		TexWidth=256
		TexHeight=256
		Tex=Texture2D'ui_textures_two.EnemySpotted.EnemySpottedHud'
		DrawColor=(R=255,G=255,B=255,A=80)
		FullAlpha=80
	End Object
	EnemySpottedReticle=Reticle
}

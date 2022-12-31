class CMGameInfo extends ROGameInfoTerritories;

static event class<GameInfo> SetGameType(string MapName, string Options, string Portal)
{
	local class<GameInfo> NewGameType;
	local array<ROUIResourceDataProvider> ProviderList;
	local ROUIDataProvider_GameModeInfo Provider;
	local string ThisMapPrefix;
	local int i, MapPrefixPos;

	// Remove the Play In Editor tag from the MapName so we can find the proper gametype when using PIE
	ReplaceText(MapName, "UEDPIE", "");

	if ( Left(MapName, InStr(MapName, "-")) ~= "TE" || Left(MapName, InStr(MapName, "-")) ~= "VNTE" )
	{
		return class'CMGameInfoTE';
	}
	else if ( Left(MapName, InStr(MapName, "-")) ~= "SU" || Left(MapName, InStr(MapName, "-")) ~= "VNSU" || Left(MapName, InStr(MapName, "-")) ~= "VNTM" )
	{
		return class'CMGameInfoSU';
	}

	// Get the prefix for this map
	MapPrefixPos = InStr(MapName,"-");
	ThisMapPrefix = left(MapName,MapPrefixPos);

	// change game type
	class'ROUIDataStore_MenuItems'.static.GetAllResourceDataProviders(class'ROUIDataProvider_GameModeInfo', ProviderList);
	for (i = 0; i < ProviderList.Length; i++)
	{
		Provider = ROUIDataProvider_GameModeInfo(ProviderList[i]);
		if ( Provider.Prefixes ~= ThisMapPrefix )
		{
			NewGameType = class<GameInfo>(DynamicLoadObject(Provider.GameMode,class'Class'));
			if ( NewGameType != None )
			{
				return NewGameType;
			}
		}
	}

	// If all else fails, let the parent handle it
	return super.SetGameType(MapName, Options, Portal);
}